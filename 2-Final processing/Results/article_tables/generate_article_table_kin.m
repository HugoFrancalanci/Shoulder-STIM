% =========================================================================
% generate_article_table_kin.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   July 2026
% -------------------------------------------------------------------------
% Description :  Builds a compact, publication-ready summary table (group +
%                individual results combined in one row per comparison)
%                from cache_scapulothoracic_all_comp.mat, WITHOUT rerunning any
%                statistics — reads the same cache used by
%                extract_scapular_kinematics_all_comp.m to redraw the final
%                figure. One row per pairwise comparison : DOF, comparison
%                label, significant cycle window, group p-value, mean
%                angular value (°) of each condition over that window, their
%                difference, and how many patients (of 10) were ALSO
%                individually significant for that same pair.
%                Prints a Markdown table to the console (paste-ready for
%                Word/most editors).
% -------------------------------------------------------------------------
% Parameters :   INCLUDE_NONSIG    — if true, also list the pairs that were
%                                    NOT significant at group level (with
%                                    "n.s." in place of the numeric columns)
%                SHOW_PATIENT_IDS  — if true, list the significant patient
%                                    IDs (e.g. "P006, P010") instead of just
%                                    the count
%                CLIP_NEGATIVE_START — SPM1D cluster interpolation can give a
%                                    slightly negative start (e.g. -1.0%)
%                                    when the effect starts right at cycle
%                                    0% ; clip to 0 for display if true
% Outputs    :   Markdown table printed to the console
% -------------------------------------------------------------------------
% Dependencies : cache_scapulothoracic_all_comp.mat (produced by
%                extract_scapular_kinematics_all_comp.m), spm1dmatlab-master/
% =========================================================================

clear; clc;

% -------------------------------------------------------------------------
% OPTIONS D'AFFICHAGE (a ajuster ensemble)
% -------------------------------------------------------------------------
INCLUDE_NONSIG      = false;
SHOW_PATIENT_IDS    = true;
CLIP_NEGATIVE_START = true;

% -------------------------------------------------------------------------
% CHARGEMENT DU CACHE
% -------------------------------------------------------------------------
HERE = fileparts(fileparts(mfilename('fullpath')));
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end

CACHE_FILE = fullfile(HERE, 'cache_scapulothoracic_all_comp.mat');
if ~isfile(CACHE_FILE)
    error('Cache introuvable : %s (lance d''abord extract_scapular_kinematics_all_comp.m)', CACHE_FILE);
end
load(CACHE_FILE, 'CONDITIONS_ORDERED', 'COND_LABELS', 'DOF_LABELS', 'spmResults', 'ALL_PAIRS', 'indivSigClusters', 'PATIENT_IDS');

DOF_SHORT = DOF_LABELS;  % deja en anglais, sans prefixe X/Y/Z (voir extract_scapular_kinematics_all_comp.m)
nDOF   = length(DOF_LABELS);
nPairs = size(ALL_PAIRS, 1);
nPat   = length(PATIENT_IDS);

% -------------------------------------------------------------------------
% CONSTRUCTION DU TABLEAU (une ligne par comparaison, DOF x paire)
% -------------------------------------------------------------------------
rows = {};  % chaque ligne : {DOF, Comparaison, Fenetre, p, MeanA, MeanB, Diff, NSig, PctSig, PatientsStr}

for idof = 1:nDOF
    for kp = 1:nPairs
        condA = ALL_PAIRS{kp,1};
        condB = ALL_PAIRS{kp,2};
        fld   = pairFieldName(condA, condB);

        % --- % de patients individuellement significatifs (independant du groupe) ---
        nSig = 0;
        sigPatList = {};
        if ~isempty(indivSigClusters) && isfield(indivSigClusters{idof}, fld)
            patClusters = indivSigClusters{idof}.(fld);
            for ip = 1:min(nPat, length(patClusters))
                if ~isempty(patClusters{ip})
                    nSig = nSig + 1;
                    sigPatList{end+1} = PATIENT_IDS{ip}; %#ok<AGROW>
                end
            end
        end
        pctSig = 100 * nSig / nPat;
        if SHOW_PATIENT_IDS && ~isempty(sigPatList)
            patStr = strjoin(sigPatList, ', ');
        else
            patStr = sprintf('%d/%d', nSig, nPat);
        end

        compLabel = sprintf('%s vs %s', condLabel(condA, CONDITIONS_ORDERED, COND_LABELS), ...
                                        condLabel(condB, CONDITIONS_ORDERED, COND_LABELS));

        sigFound = false;
        if isfield(spmResults(idof).posthoc, fld)
            ph = spmResults(idof).posthoc.(fld);
            if isfield(ph, 'sig') && ph.sig && ~isempty(ph.clusters)
                sigFound = true;
                for cl = 1:length(ph.clusters)
                    ep = ph.clusters{cl}.endpoints;
                    pv = ph.clusters{cl}.P;
                    startPct = ep(1) - 1;
                    endPct   = ep(2) - 1;
                    if CLIP_NEGATIVE_START, startPct = max(startPct, 0); end

                    if isfield(ph, 'angleInfo') && cl <= length(ph.angleInfo)
                        vi = ph.angleInfo(cl);
                        meanA = mean(vi.range_ref);
                        meanB = mean(vi.range_fes);
                        diffAB = vi.diff_mean;
                    else
                        meanA = NaN; meanB = NaN; diffAB = NaN;
                    end

                    window = sprintf('%.1f-%.1f', startPct, endPct);
                    pStr = formatP(pv);

                    rows(end+1,:) = {DOF_SHORT{idof}, compLabel, window, pStr, ...
                                      sprintf('%.1f', meanA), sprintf('%.1f', meanB), ...
                                      sprintf('%+.1f', diffAB), patStr}; %#ok<AGROW>
                end
            end
        end

        if INCLUDE_NONSIG && ~sigFound
            rows(end+1,:) = {DOF_SHORT{idof}, compLabel, '—', 'n.s.', '—', '—', '—', patStr}; %#ok<AGROW>
        end
    end
end

% -------------------------------------------------------------------------
% COLONNES
% -------------------------------------------------------------------------
colNames = {'DOF', 'Comparison', 'Window_pct', 'p', 'Mean_A_deg', 'Mean_B_deg', 'Diff_deg', 'Patients_sig'};

% -------------------------------------------------------------------------
% AFFICHAGE MARKDOWN (copier-coller Word)
% -------------------------------------------------------------------------
fprintf('| %s | %s | %s | %s | %s | %s | %s | %s |\n', colNames{:});
fprintf('|%s\n', repmat('---|', 1, numel(colNames)));
for r = 1:size(rows,1)
    fprintf('| %s |\n', strjoin(rows(r,:), ' | '));
end


% =========================================================================
% FONCTIONS LOCALES
% =========================================================================

function fld = pairFieldName(condA, condB)
    fld = matlab.lang.makeValidName(sprintf('%s_vs_%s', condA, condB));
end

function lbl = condLabel(condRaw, CONDITIONS_ORDERED, COND_LABELS)
    idx = find(strcmp(CONDITIONS_ORDERED, condRaw), 1);
    if isempty(idx)
        lbl = strrep(condRaw, '_', ' ');
    else
        lbl = COND_LABELS{idx};
    end
end

function s = formatP(pv)
    if pv < 0.001
        s = '<0.001';
    else
        s = sprintf('%.3f', pv);
    end
end
