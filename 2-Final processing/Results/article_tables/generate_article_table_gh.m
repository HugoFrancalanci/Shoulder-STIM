% =========================================================================
% generate_article_table_gh.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   August 2026
% -------------------------------------------------------------------------
% Description :  Glenohumeral counterpart of generate_article_table_kin.m --
%                builds a compact, publication-ready summary table (group +
%                individual results combined in one row per comparison)
%                from cache_glenohumeral_all_comp.mat, WITHOUT rerunning any
%                statistics — reads the same cache used by
%                extract_glenohumeral_kinematics_all_comp.m to redraw the
%                final figure. One row per pairwise comparison : DOF,
%                comparison label, significant cycle window, group p-value,
%                mean angular value (°) of each condition over that window
%                (mean ± SD across the 10 patients of each patient's own
%                window-averaged angle), their paired difference (B - A,
%                mean ± SD), and how many patients (of 10) were ALSO
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
% Dependencies : cache_glenohumeral_all_comp.mat (produced by
%                extract_glenohumeral_kinematics_all_comp.m), spm1dmatlab-master/
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
addpath(fullfile(HERE, 'helpers'));  % dataDir() : dossier des donnees privees (caches, Excel)
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end

CACHE_FILE = fullfile(dataDir(), 'cache_glenohumeral_all_comp.mat');
if ~isfile(CACHE_FILE)
    error('Cache introuvable : %s (lance d''abord extract_glenohumeral_kinematics_all_comp.m)', CACHE_FILE);
end
load(CACHE_FILE, 'CONDITIONS_ORDERED', 'COND_LABELS', 'DOF_LABELS', 'spmResults', 'ALL_PAIRS', 'indivSigClusters', 'PATIENT_IDS', 'patientMeans');

DOF_SHORT = DOF_LABELS;  % deja en anglais, sans prefixe X/Y/Z (voir extract_glenohumeral_kinematics_all_comp.m)
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

                    [sA, sB, sD] = groupWindowStats(patientMeans, condA, condB, idof, ep);

                    window = sprintf('%.1f-%.1f', startPct, endPct);
                    pStr = formatP(pv);

                    rows(end+1,:) = {DOF_SHORT{idof}, compLabel, window, pStr, ...
                                      sA, sB, sD, patStr}; %#ok<AGROW>
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
colNames = {'DOF', 'Comparison', 'Window_pct', 'p', 'Mean_A_deg (mean ± SD)', 'Mean_B_deg (mean ± SD)', 'Diff_B-A_deg (mean ± SD)', 'Patients_sig'};

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
