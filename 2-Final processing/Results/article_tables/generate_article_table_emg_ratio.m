% =========================================================================
% generate_article_table_emg_ratio.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   August 2026
% -------------------------------------------------------------------------
% Description :  Ratio counterpart of generate_article_table_emg.m -- builds
%                a compact, publication-ready summary table (group results,
%                N=10) from cache_emg_ratio_all_comp.mat, WITHOUT rerunning
%                any statistics. One row per pairwise comparison that was
%                significant at group level : ratio, comparison label,
%                significant cycle window, p-value, mean ratio of each
%                condition over that window, and their difference.
%                No "patients individually significant" column here --
%                unlike generate_article_table_emg.m, the ratio cache has
%                no individual-level (N=3 blocks) data to draw from (see
%                extract_emg_ratio_all_comp.m header for why).
%                Prints a Markdown table to the console (paste-ready for
%                Word/most editors).
% Dependencies : cache_emg_ratio_all_comp.mat (produced by
%                extract_emg_ratio_all_comp.m), spm1dmatlab-master/
% =========================================================================

clear; clc;

% -------------------------------------------------------------------------
% OPTIONS D'AFFICHAGE (a ajuster ensemble)
% -------------------------------------------------------------------------
INCLUDE_NONSIG      = false;
CLIP_NEGATIVE_START = true;

% -------------------------------------------------------------------------
% CHARGEMENT DU CACHE
% -------------------------------------------------------------------------
HERE = fileparts(fileparts(mfilename('fullpath')));
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end

CACHE_FILE = fullfile(HERE, 'cache_emg_ratio_all_comp.mat');
if ~isfile(CACHE_FILE)
    error('Cache introuvable : %s (lance d''abord extract_emg_ratio_all_comp.m)', CACHE_FILE);
end
load(CACHE_FILE, 'CONDITIONS_ORDERED', 'COND_LABELS', 'RATIO_LABELS', 'RATIO_DISPLAY', 'spmResults', 'ALL_PAIRS');

nRatios = length(RATIO_LABELS);
nPairs  = size(ALL_PAIRS, 1);

% -------------------------------------------------------------------------
% CONSTRUCTION DU TABLEAU (une ligne par comparaison, ratio x paire)
% -------------------------------------------------------------------------
rows = {};  % {Ratio, Comparaison, Fenetre, p, MeanA, MeanB, Diff}

for ir = 1:nRatios
    for kp = 1:nPairs
        condA = ALL_PAIRS{kp,1};
        condB = ALL_PAIRS{kp,2};
        fld   = pairFieldName(condA, condB);

        compLabel = sprintf('%s vs %s', condLabel(condA, CONDITIONS_ORDERED, COND_LABELS), ...
                                        condLabel(condB, CONDITIONS_ORDERED, COND_LABELS));

        sigFound = false;
        if isfield(spmResults(ir).posthoc, fld)
            ph = spmResults(ir).posthoc.(fld);
            if isfield(ph, 'sig') && ph.sig && ~isempty(ph.clusters)
                sigFound = true;
                for cl = 1:length(ph.clusters)
                    ep = ph.clusters{cl}.endpoints;
                    pv = ph.clusters{cl}.P;
                    startPct = ep(1) - 1;
                    endPct   = ep(2) - 1;
                    if CLIP_NEGATIVE_START, startPct = max(startPct, 0); end

                    if isfield(ph, 'ampInfo') && cl <= length(ph.ampInfo)
                        vi = ph.ampInfo(cl);
                        meanA = mean(vi.range_ref);
                        meanB = mean(vi.range_fes);
                        diffAB = vi.diff_mean;
                    else
                        meanA = NaN; meanB = NaN; diffAB = NaN;
                    end

                    window = sprintf('%.1f-%.1f', startPct, endPct);
                    pStr = formatP(pv);

                    rows(end+1,:) = {RATIO_DISPLAY{ir}, compLabel, window, pStr, ...
                                      sprintf('%.2f', meanA), sprintf('%.2f', meanB), ...
                                      sprintf('%+.2f', diffAB)}; %#ok<AGROW>
                end
            end
        end

        if INCLUDE_NONSIG && ~sigFound
            rows(end+1,:) = {RATIO_DISPLAY{ir}, compLabel, '-', 'n.s.', '-', '-', '-'}; %#ok<AGROW>
        end
    end
end

% -------------------------------------------------------------------------
% COLONNES
% -------------------------------------------------------------------------
colNames = {'Ratio', 'Comparison', 'Window_pct', 'p', 'Mean_A', 'Mean_B', 'Diff'};
if isempty(rows)
    fprintf('Aucune paire significative au niveau groupe pour les ratios EMG.\n');
end

% -------------------------------------------------------------------------
% AFFICHAGE MARKDOWN
% -------------------------------------------------------------------------
fprintf('| %s | %s | %s | %s | %s | %s | %s |\n', colNames{:});
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
