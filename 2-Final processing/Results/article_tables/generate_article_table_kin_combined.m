% =========================================================================
% generate_article_table_kin_combined.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   July 2026
% -------------------------------------------------------------------------
% Description :  Merges generate_article_table_kin.m (group) and
%                generate_article_table_kin_individual.m (individual) into
%                ONE master table : for every DOF x comparison that showed
%                significance at EITHER level, prints the group row (N=10,
%                if the pair was group-significant) immediately followed by
%                one row per patient who was ALSO individually significant
%                for that exact pair -- mirroring how Figure 3
%                (plotAllCompFigure.m, "labelled" mode) stacks a group bar
%                with individual patient bars underneath it. Comparisons
%                that were significant for a patient but NOT at group level
%                still get listed (patient rows only, no group row) --
%                nothing from either sub-table is dropped. Reads
%                cache_scapulothoracic_all_comp.mat only, no statistics rerun.
% -------------------------------------------------------------------------
% Parameters :   none
% Outputs    :   Markdown table printed to the console
% -------------------------------------------------------------------------
% Dependencies : cache_scapulothoracic_all_comp.mat (produced by
%                extract_scapular_kinematics_all_comp.m), spm1dmatlab-master/
% =========================================================================

clear; clc;

% -------------------------------------------------------------------------
% CHARGEMENT DU CACHE
% -------------------------------------------------------------------------
HERE = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(HERE, 'helpers'));  % dataDir() : dossier des donnees privees (caches, Excel)
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end

CACHE_FILE = fullfile(dataDir(), 'cache_scapulothoracic_all_comp.mat');
if ~isfile(CACHE_FILE)
    error('Cache introuvable : %s (lance d''abord extract_scapular_kinematics_all_comp.m)', CACHE_FILE);
end
load(CACHE_FILE, 'CONDITIONS_ORDERED', 'COND_LABELS', 'DOF_LABELS', 'spmResults', 'ALL_PAIRS', ...
     'indivSigClusters', 'PATIENT_IDS', 'patientMeans');

DOF_SHORT = DOF_LABELS;  % deja en anglais, sans prefixe X/Y/Z
nDOF   = length(DOF_LABELS);
nPairs = size(ALL_PAIRS, 1);
nPat   = length(PATIENT_IDS);

% -------------------------------------------------------------------------
% CONSTRUCTION DU TABLEAU : pour chaque DOF x paire montrant une
% significativite (groupe ET/OU individuelle), la ligne groupe (si sig.)
% puis une ligne par patient individuellement significatif pour CETTE MEME
% paire (union des deux sous-tableaux -- rien n'est perdu).
% -------------------------------------------------------------------------
rows = {};  % {DOF, Comparison, Level, Window, p, Mean_A, Mean_B, Diff}

for idof = 1:nDOF
    for kp = 1:nPairs
        condA = ALL_PAIRS{kp,1};
        condB = ALL_PAIRS{kp,2};
        fld   = pairFieldName(condA, condB);
        fldA  = matlab.lang.makeValidName(condA);
        fldB  = matlab.lang.makeValidName(condB);

        % --- Niveau groupe (N=10) ---
        groupSig = false;
        if isfield(spmResults(idof).posthoc, fld)
            ph = spmResults(idof).posthoc.(fld);
            groupSig = isfield(ph, 'sig') && ph.sig && ~isempty(ph.clusters);
        end

        % --- Niveau individuel : patients significatifs pour cette meme paire ---
        patRows = {};
        if ~isempty(indivSigClusters) && isfield(indivSigClusters{idof}, fld)
            patClusters = indivSigClusters{idof}.(fld);
            for ip = 1:min(nPat, length(patClusters))
                clusters_ip = patClusters{ip};
                if isempty(clusters_ip), continue; end

                curveA = []; curveB = [];
                if isfield(patientMeans, fldA) && ip <= length(patientMeans.(fldA))
                    curveA = patientMeans.(fldA){ip}(idof, :);
                end
                if isfield(patientMeans, fldB) && ip <= length(patientMeans.(fldB))
                    curveB = patientMeans.(fldB){ip}(idof, :);
                end

                for cl = 1:length(clusters_ip)
                    ep = clusters_ip{cl}.endpoints;
                    pv = clusters_ip{cl}.P;
                    idx1 = max(1, round(ep(1))); idx2 = min(101, round(ep(2)));
                    if ~isempty(curveA) && ~isempty(curveB) && idx2 >= idx1
                        meanA = mean(curveA(idx1:idx2));
                        meanB = mean(curveB(idx1:idx2));
                        diffAB = meanB - meanA;
                    else
                        meanA = NaN; meanB = NaN; diffAB = NaN;
                    end
                    window = sprintf('%.1f-%.1f', max(ep(1)-1,0), ep(2)-1);
                    patRows(end+1,:) = {PATIENT_IDS{ip}, window, formatP(pv), ...
                                         sprintf('%.1f', meanA), sprintf('%.1f', meanB), sprintf('%+.1f', diffAB)}; %#ok<AGROW>
                end
            end
        end

        if ~groupSig && isempty(patRows), continue; end  % rien a signaler pour cette paire

        compLabel = sprintf('%s vs %s', condLabel(condA, CONDITIONS_ORDERED, COND_LABELS), ...
                                        condLabel(condB, CONDITIONS_ORDERED, COND_LABELS));

        if groupSig
            for cl = 1:length(ph.clusters)
                ep = ph.clusters{cl}.endpoints;
                pv = ph.clusters{cl}.P;
                window = sprintf('%.1f-%.1f', max(ep(1)-1,0), ep(2)-1);
                % Groupe : moyenne ± ET inter-patients ; lignes patient : valeur du patient seul
                [sA, sB, sD] = groupWindowStats(patientMeans, condA, condB, idof, ep);
                rows(end+1,:) = {DOF_SHORT{idof}, compLabel, 'Group (N=10)', window, formatP(pv), ...
                                  sA, sB, sD}; %#ok<AGROW>
            end
        end

        for r = 1:size(patRows, 1)
            rows(end+1,:) = [{DOF_SHORT{idof}, compLabel, patRows{r,1}}, patRows(r,2:end)]; %#ok<AGROW>
        end
    end
end

% -------------------------------------------------------------------------
% COLONNES
% -------------------------------------------------------------------------
colNames = {'DOF', 'Comparison', 'Level', 'Window_pct', 'p', 'Mean_A_deg', 'Mean_B_deg', 'Diff_deg'};

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


function [sA, sB, sD] = groupWindowStats(patientMeans, condA, condB, idof, ep)
    % Angle moyen sur la fenetre significative, calcule PAR PATIENT (moyenne
    % des points de la fenetre sur sa courbe patientMeans), puis moyenne +- ET
    % inter-patients (N=10) ; difference = B - A appariee patient par patient.
    % Memes indices de fenetre que les tableaux individuels (round(ep)).
    idx1 = max(1, round(ep(1)));
    idx2 = min(101, round(ep(2)));
    stackA = cat(3, patientMeans.(matlab.lang.makeValidName(condA)){:});  % (nDOF,101,N)
    stackB = cat(3, patientMeans.(matlab.lang.makeValidName(condB)){:});
    wA = squeeze(mean(stackA(idof, idx1:idx2, :), 2));  % (N,1)
    wB = squeeze(mean(stackB(idof, idx1:idx2, :), 2));
    d  = wB - wA;
    sA = sprintf('%.1f ± %.1f', mean(wA, 'omitnan'), std(wA, 'omitnan'));
    sB = sprintf('%.1f ± %.1f', mean(wB, 'omitnan'), std(wB, 'omitnan'));
    sD = sprintf('%+.1f ± %.1f', mean(d, 'omitnan'), std(d, 'omitnan'));
end
