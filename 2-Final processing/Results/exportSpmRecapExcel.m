function exportSpmRecapExcel(outFile, dimLabel, rowLabels, refCond, fesConds, spmResults, indivSigClusters, patientIDs, valueField, valueUnit)
% =========================================================================
% exportSpmRecapExcel.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   July 2026
% -------------------------------------------------------------------------
% Description :  Writes a 2-sheet Excel recap of the SPM1D group and
%                individual post-hoc results, meant as a publication-ready
%                supplementary table. Shared by the kinematics and EMG
%                scripts (noSEF and rehab variants) — only the row
%                dimension differs (DOF vs muscle).
%                Sheet "Group_PostHoc"      : one row per (dim, condition),
%                  ALWAYS present (even when non-significant), with the
%                  ANOVA/post-hoc p-values, cluster timing, mean values
%                  (if valueField is supplied), and the % of individual
%                  patients significant in that comparison — computed
%                  independently of the group-level ANOVA outcome, since
%                  each patient's own post-hoc runs on their own N=3-block
%                  ANOVA regardless of the N=10 group result.
%                Sheet "Individual_PostHoc" : one row per patient x
%                  significant individual cluster (tidy/long format — only
%                  actual findings, no empty rows), for per-subject detail.
% -------------------------------------------------------------------------
% Parameters :   outFile           — full path of the .xlsx file to write
%                dimLabel          — 'DOF' or 'Muscle' (row-dimension column
%                                    header)
%                rowLabels         — cell array of DOF/muscle display names
%                refCond           — reference condition name (string)
%                fesConds          — cell array of compared condition names
%                spmResults        — struct array (1 x length(rowLabels)) :
%                                    .anova_sig, .anova_clusters,
%                                    .posthoc.(fld).clusters/.sig/.(valueField)
%                indivSigClusters  — cell array (1 x length(rowLabels)) :
%                                    indivSigClusters{i}.(fld){ip} = clusters
%                patientIDs        — cell array of patient ID strings
%                valueField        — name of the optional per-cluster mean-
%                                    value struct field ('angleInfo' for
%                                    kinematics, 'ampInfo' for EMG), or ''
%                                    if not available
%                valueUnit         — unit suffix for the mean-value columns
%                                    (e.g. 'deg', 'pctBaseline')
% Outputs    :   writes outFile with 2 sheets, overwriting any existing file
% -------------------------------------------------------------------------
% Dependencies : none
% =========================================================================

nDim = length(rowLabels);
nFes = length(fesConds);
nPat = length(patientIDs);
hasValue = ~isempty(valueField);

% -------------------------------------------------------------------------
% Sheet 1 : Group_PostHoc
% -------------------------------------------------------------------------
G_dim = {}; G_cond = {}; G_anovaP = []; G_anovaSig = {}; G_phSig = {};
G_p = []; G_start = []; G_end = []; G_dur = [];
G_meanRef = []; G_meanCond = []; G_meanDiff = [];
G_nSig = []; G_pctSig = [];

for id = 1:nDim
    res = spmResults(id);
    anovaP = NaN;
    if isfield(res, 'anova_clusters') && ~isempty(res.anova_clusters)
        anovaP = res.anova_clusters{1}.P;
    end

    for fc = 1:nFes
        fld = matlab.lang.makeValidName(fesConds{fc});

        % % de patients significatifs (independant du resultat ANOVA groupe)
        nSig = 0;
        if ~isempty(indivSigClusters) && isfield(indivSigClusters{id}, fld)
            patClusters = indivSigClusters{id}.(fld);
            for ip = 1:min(nPat, length(patClusters))
                if ~isempty(patClusters{ip}), nSig = nSig + 1; end
            end
        end
        pctSig = 100 * nSig / nPat;

        phSig = false; clusters = {}; ph = struct();
        if res.anova_sig && isfield(res.posthoc, fld)
            ph = res.posthoc.(fld);
            phSig = isfield(ph, 'sig') && ph.sig;
            if phSig, clusters = ph.clusters; end
        end

        if isempty(clusters)
            G_dim{end+1}      = rowLabels{id};
            G_cond{end+1}     = strrep(fesConds{fc}, '_', ' ');
            G_anovaP(end+1)   = anovaP;
            G_anovaSig{end+1} = yesNo(res.anova_sig);
            G_phSig{end+1}    = yesNo(phSig);
            G_p(end+1)        = NaN;
            G_start(end+1)    = NaN;
            G_end(end+1)      = NaN;
            G_dur(end+1)      = NaN;
            G_meanRef(end+1)  = NaN;
            G_meanCond(end+1) = NaN;
            G_meanDiff(end+1) = NaN;
            G_nSig(end+1)     = nSig;
            G_pctSig(end+1)   = pctSig;
        else
            for cl = 1:length(clusters)
                ep = clusters{cl}.endpoints;
                G_dim{end+1}      = rowLabels{id};
                G_cond{end+1}     = strrep(fesConds{fc}, '_', ' ');
                G_anovaP(end+1)   = anovaP;
                G_anovaSig{end+1} = 'Yes';
                G_phSig{end+1}    = 'Yes';
                G_p(end+1)        = clusters{cl}.P;
                G_start(end+1)    = ep(1) - 1;
                G_end(end+1)      = ep(2) - 1;
                G_dur(end+1)      = ep(2) - ep(1);
                if hasValue && isfield(ph, valueField) && cl <= length(ph.(valueField))
                    vi = ph.(valueField)(cl);
                    G_meanRef(end+1)  = mean(vi.range_ref);
                    G_meanCond(end+1) = mean(vi.range_fes);
                    G_meanDiff(end+1) = vi.diff_mean;
                else
                    G_meanRef(end+1)  = NaN;
                    G_meanCond(end+1) = NaN;
                    G_meanDiff(end+1) = NaN;
                end
                G_nSig(end+1)     = nSig;
                G_pctSig(end+1)   = pctSig;
            end
        end
    end
end

meanRefName  = ['Mean_Reference'];
meanCondName = ['Mean_Condition'];
if hasValue
    meanRefName  = [meanRefName '_' valueUnit];
    meanCondName = [meanCondName '_' valueUnit];
end
meanDiffName = 'Mean_Diff';
if hasValue, meanDiffName = [meanDiffName '_' valueUnit]; end

groupTable = table(G_dim', G_cond', repmat({refCond}, length(G_dim), 1), G_anovaP', G_anovaSig', G_phSig', ...
                   G_p', G_start', G_end', G_dur', G_meanRef', G_meanCond', G_meanDiff', G_nSig', G_pctSig', ...
                   'VariableNames', {dimLabel, 'Condition', 'Reference', 'ANOVA_p', 'ANOVA_sig', 'PostHoc_sig', ...
                                      'PostHoc_p', 'Start_pct', 'End_pct', 'Duration_pct', ...
                                      meanRefName, meanCondName, meanDiffName, 'N_Patients_Sig', 'Pct_Patients_Sig'});

% -------------------------------------------------------------------------
% Sheet 2 : Individual_PostHoc
% -------------------------------------------------------------------------
I_pat = {}; I_dim = {}; I_cond = {}; I_start = []; I_end = []; I_dur = []; I_p = [];

for id = 1:nDim
    for fc = 1:nFes
        fld = matlab.lang.makeValidName(fesConds{fc});
        if isempty(indivSigClusters) || ~isfield(indivSigClusters{id}, fld), continue; end
        patClusters = indivSigClusters{id}.(fld);
        for ip = 1:min(nPat, length(patClusters))
            clusters_ip = patClusters{ip};
            for cl = 1:length(clusters_ip)
                ep = clusters_ip{cl}.endpoints;
                I_pat{end+1}   = patientIDs{ip};
                I_dim{end+1}   = rowLabels{id};
                I_cond{end+1}  = strrep(fesConds{fc}, '_', ' ');
                I_start(end+1) = ep(1) - 1;
                I_end(end+1)   = ep(2) - 1;
                I_dur(end+1)   = ep(2) - ep(1);
                I_p(end+1)     = clusters_ip{cl}.P;
            end
        end
    end
end

if isempty(I_pat)
    indivTable = table(cell(0,1), cell(0,1), cell(0,1), zeros(0,1), zeros(0,1), zeros(0,1), zeros(0,1), ...
                       'VariableNames', {'Patient', dimLabel, 'Condition', 'Start_pct', 'End_pct', 'Duration_pct', 'PostHoc_p'});
else
    indivTable = table(I_pat', I_dim', I_cond', I_start', I_end', I_dur', I_p', ...
                       'VariableNames', {'Patient', dimLabel, 'Condition', 'Start_pct', 'End_pct', 'Duration_pct', 'PostHoc_p'});
end

writetable(groupTable, outFile, 'Sheet', 'Group_PostHoc');
writetable(indivTable, outFile, 'Sheet', 'Individual_PostHoc');
fprintf('  Recap Excel ecrit : %s\n', outFile);

end


function s = yesNo(tf)
    if tf, s = 'Yes'; else, s = 'No'; end
end
