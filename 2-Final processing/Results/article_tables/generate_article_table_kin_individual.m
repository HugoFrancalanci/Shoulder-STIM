% =========================================================================
% generate_article_table_kin_individual.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   July 2026
% -------------------------------------------------------------------------
% Description :  Companion to generate_article_table_kin.m -- instead of one
%                row per GROUP-significant comparison, this one lists every
%                INDIVIDUAL significant cluster (N=3 blocks, exploratory),
%                across all 21 pairwise comparisons and all 3 DOF,
%                regardless of whether that pair was significant at group
%                level (individual tests run independently -- see README).
%                One row per patient x significant cluster (tidy/long
%                format), including that PATIENT's own mean angular value
%                (deg) for each compared condition over the cluster window --
%                indivSigClusters only stores the cluster's timing/p-value,
%                not the angle, so this is recomputed here directly from
%                the patient's own curve in patientMeans (also cached), no
%                statistics rerun needed.
% -------------------------------------------------------------------------
% Parameters :   SORT_BY           -- 'patient' or 'dof' : primary sort key
%                                    for the output table
% Outputs    :   Markdown table printed to the console
% -------------------------------------------------------------------------
% Dependencies : cache_scapulothoracic_all_comp.mat (produced by
%                extract_scapular_kinematics_all_comp.m), spm1dmatlab-master/
% =========================================================================

clear; clc;

% -------------------------------------------------------------------------
% OPTIONS D'AFFICHAGE (a ajuster ensemble)
% -------------------------------------------------------------------------
SORT_BY = 'patient';  % 'patient' ou 'dof'

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
load(CACHE_FILE, 'CONDITIONS_ORDERED', 'COND_LABELS', 'DOF_LABELS', 'ALL_PAIRS', 'indivSigClusters', 'PATIENT_IDS', 'patientMeans');

DOF_SHORT = DOF_LABELS;  % deja en anglais, sans prefixe X/Y/Z
nDOF   = length(DOF_LABELS);
nPairs = size(ALL_PAIRS, 1);
nPat   = length(PATIENT_IDS);

% -------------------------------------------------------------------------
% CONSTRUCTION DU TABLEAU (une ligne par patient x cluster individuel
% significatif, toutes paires et tous DOF confondus)
% -------------------------------------------------------------------------
rows = {};        % {Patient, DOF, Comparaison, Fenetre, p, MeanA, MeanB, Diff}
sortKeyPat = [];  % index patient, pour le tri
sortKeyDof = [];  % index DOF, pour le tri

for idof = 1:nDOF
    for kp = 1:nPairs
        condA = ALL_PAIRS{kp,1};
        condB = ALL_PAIRS{kp,2};
        fld   = pairFieldName(condA, condB);
        fldA  = matlab.lang.makeValidName(condA);
        fldB  = matlab.lang.makeValidName(condB);

        if isempty(indivSigClusters) || ~isfield(indivSigClusters{idof}, fld), continue; end
        patClusters = indivSigClusters{idof}.(fld);

        compLabel = sprintf('%s vs %s', condLabel(condA, CONDITIONS_ORDERED, COND_LABELS), ...
                                        condLabel(condB, CONDITIONS_ORDERED, COND_LABELS));

        for ip = 1:min(nPat, length(patClusters))
            clusters_ip = patClusters{ip};
            if isempty(clusters_ip), continue; end

            % Courbes propres a CE patient (patientMeans.(cond){ip} = (3,101))
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
                startPct = max(ep(1)-1, 0);
                endPct   = ep(2)-1;
                window = sprintf('%.1f-%.1f', startPct, endPct);

                idx1 = max(1, round(ep(1)));
                idx2 = min(101, round(ep(2)));
                if ~isempty(curveA) && ~isempty(curveB) && idx2 >= idx1
                    meanA = mean(curveA(idx1:idx2));
                    meanB = mean(curveB(idx1:idx2));
                    diffAB = meanB - meanA;
                else
                    meanA = NaN; meanB = NaN; diffAB = NaN;
                end

                rows(end+1,:) = {PATIENT_IDS{ip}, DOF_SHORT{idof}, compLabel, window, formatP(pv), ...
                                  sprintf('%.1f', meanA), sprintf('%.1f', meanB), sprintf('%+.1f', diffAB)}; %#ok<AGROW>
                sortKeyPat(end+1) = ip; %#ok<AGROW>
                sortKeyDof(end+1) = idof; %#ok<AGROW>
            end
        end
    end
end

% -------------------------------------------------------------------------
% TRI
% -------------------------------------------------------------------------
if ~isempty(rows)
    if strcmpi(SORT_BY, 'patient')
        [~, ord] = sortrows([sortKeyPat', sortKeyDof']);
    else
        [~, ord] = sortrows([sortKeyDof', sortKeyPat']);
    end
    rows = rows(ord, :);
end

% -------------------------------------------------------------------------
% COLONNES
% -------------------------------------------------------------------------
colNames = {'Patient', 'DOF', 'Comparison', 'Window_pct', 'p', 'Mean_A_deg', 'Mean_B_deg', 'Diff_deg'};

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
