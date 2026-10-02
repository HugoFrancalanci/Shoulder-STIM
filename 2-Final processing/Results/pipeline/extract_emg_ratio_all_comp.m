% =========================================================================
% extract_emg_ratio_all_comp.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
%                https://www.unige.ch/medecine/chiru/en/research-groups/nicolas-holzer-et-florent-moissenet
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   August 2026
% -------------------------------------------------------------------------
% Description:   Inter-muscle EMG amplitude ratio analysis, ALL C(n,2)
%                muscle pairs (n = numel(EMG_LABELS), currently 4 -> 6
%                ratios : UT/MT, UT/LT, UT/SA, MT/LT, MT/SA, LT/SA),
%                computed directly from cache_emg_all_comp.mat produced by
%                extract_emg_cycles_all_comp.m 
%                For each ratio and each condition, the per-patient mean
%                cycle of the numerator muscle is divided point-by-point
%                (101 pts) by the denominator muscle's mean cycle
%                (patientMeans.(cond).(muscle){patient}. Same statistical
%                design as the amplitude pipeline : SPM1D non-parametric
%                ANOVA RM (7 conditions, N=10 patients), Holm-
%                Bonferroni-corrected paired t-test post-hoc on all 21 condition pairs.
%
% -------------------------------------------------------------------------
% Parameters :   RATIO_DEFS -- struct array, one entry per ratio, generated
%                automatically from EMG_LABELS (every numerator/denominator
%                pair, i<j so each pair appears once) :
%                  .label   valid MATLAB field name (e.g. 'UT_LT')
%                  .display printable label (e.g. 'TRAPS / TRAPI (UT/LT)')
%                  .num     numerator muscle
%                  .den     denominator muscle
%                MUSCLE_SHORT -- containers.Map, muscle name -> short code
%                              used to build .label/.display (falls back to
%                              the raw muscle name if not listed)
%                DENOM_EPS  -- |denominator| below this (% baseline) is
%                              treated as undefined (-> NaN) instead of
%                              blowing up the ratio numerically
% Outputs    :   2 figures (see plotAllCompFigureEMGRatio.m); console SPM1D
%                recap table; console recap of the ratio VALUES themselves
%                (mean +/- SD across N patients, per ratio x condition,
%                averaged over the cycle -- independent of significance);
%                cache_emg_ratio_all_comp.mat
% -------------------------------------------------------------------------
% Dependencies : cache_emg_all_comp.mat (produced by
%                extract_emg_cycles_all_comp.m -- run that first),
%                plotAllCompFigureEMGRatio.m (plotting/ subfolder),
%                spm1dmatlab-master/ (Pataky 2010)
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution -
% NonCommercial 4.0 International License. To view a copy of this license,
% visit http://creativecommons.org/licenses/by-nc/4.0/
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' extract_emg_ratio_all_comp.m');
disp('=========================================');

HERE = fileparts(fileparts(mfilename('fullpath')));
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end
addpath(fullfile(HERE, 'plotting'));
addpath(fullfile(HERE, 'helpers'));

DENOM_EPS = 1e-6;  % % baseline -- garde-fou division par (quasi) zero

% -------------------------------------------------------------------------
% CACHE : regeneration rapide de la figure finale seule, sans tout
% recalculer. True pour ignorer le cache et tout refaire.
% -------------------------------------------------------------------------
FORCE_RECOMPUTE = false;
CACHE_FILE = fullfile(HERE, 'cache_emg_ratio_all_comp.mat');

% Methode de correction post-hoc : un cache calcule avec une autre
% correction (ex. ancien Bonferroni) est ignore et tout est recalcule.
POSTHOC_CORRECTION = 'holm';

cacheValid = false;
cachedCorrection = '';
if isfile(CACHE_FILE) && ~FORCE_RECOMPUTE
    try
        cacheInfo = whos('-file', CACHE_FILE);
        if ismember('POSTHOC_CORRECTION', {cacheInfo.name})
            S_check = load(CACHE_FILE, 'POSTHOC_CORRECTION');
            cachedCorrection = S_check.POSTHOC_CORRECTION;
        end
    catch
    end
    cacheValid = strcmp(cachedCorrection, POSTHOC_CORRECTION);
end

if cacheValid
    fprintf('Cache trouve : %s\n', CACHE_FILE);
    fprintf('-> Regeneration rapide de la figure finale (pas de re-calcul SPM1D).\n');
    fprintf('  (mettre FORCE_RECOMPUTE=true dans le script pour tout recalculer)\n\n');
    load(CACHE_FILE, 'ratioPatientMeans', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', ...
                      'RATIO_LABELS', 'RATIO_DISPLAY', 'X_CYCLE', 'spmResults', 'ALL_PAIRS');

    plotAllCompFigureEMGRatio(ratioPatientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS, ...
                               RATIO_LABELS, RATIO_DISPLAY, X_CYCLE, spmResults, ALL_PAIRS);
    return;
elseif isfile(CACHE_FILE) && ~FORCE_RECOMPUTE
    fprintf('Cache trouve mais obsolete (correction "%s" -> "%s") : recalcul complet.\n\n', cachedCorrection, POSTHOC_CORRECTION);
end

% -------------------------------------------------------------------------
% SOURCE : cache_emg_all_comp.mat (amplitude par muscle, deja calculee)
% -------------------------------------------------------------------------
SOURCE_CACHE = fullfile(HERE, 'cache_emg_all_comp.mat');
if ~isfile(SOURCE_CACHE)
    error('Cache source introuvable : %s (lance d''abord extract_emg_cycles_all_comp.m)', SOURCE_CACHE);
end
load(SOURCE_CACHE, 'patientMeans', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', 'EMG_LABELS', 'X_CYCLE', 'ALL_PAIRS', 'PATIENT_IDS');

% -------------------------------------------------------------------------
% RATIOS A CALCULER : toutes les paires de muscles (C(n,2)), generees
% automatiquement depuis EMG_LABELS
% -------------------------------------------------------------------------
MUSCLE_SHORT = containers.Map( ...
    {'TRAPS', 'TRAPM', 'TRAPI', 'SERRA'}, ...
    {'UT', 'MT', 'LT', 'SA'});

RATIO_DEFS = struct('label', {}, 'display', {}, 'num', {}, 'den', {});
for i = 1:length(EMG_LABELS)-1
    for j = i+1:length(EMG_LABELS)
        numM = EMG_LABELS{i};
        denM = EMG_LABELS{j};
        if isKey(MUSCLE_SHORT, numM), shortN = MUSCLE_SHORT(numM); else, shortN = numM; end
        if isKey(MUSCLE_SHORT, denM), shortD = MUSCLE_SHORT(denM); else, shortD = denM; end
        k = numel(RATIO_DEFS) + 1;
        RATIO_DEFS(k).label   = sprintf('%s_%s', shortN, shortD);
        RATIO_DEFS(k).display = sprintf('%s / %s (%s/%s)', numM, denM, shortN, shortD);
        RATIO_DEFS(k).num     = numM;
        RATIO_DEFS(k).den     = denM;
    end
end

RATIO_LABELS  = {RATIO_DEFS.label};
RATIO_DISPLAY = {RATIO_DEFS.display};
nRatios       = length(RATIO_DEFS);

rng(0);  % reproductibilite des tests non parametriques (permutation Monte Carlo)
N_PAIRS        = size(ALL_PAIRS, 1);
ALPHA_FWER     = 0.05;  % Holm-Bonferroni : seuil alpha/(m-k+1) par paire (helpers/holmAlphaSPM1D.m)
PAIR_BAR_COLOR = [0.35 0.35 0.35];

% -------------------------------------------------------------------------
% CALCUL DES RATIOS : ratioPatientMeans.(cond).(ratioLabel){patient} =
% patientMeans.(cond).(num){patient} ./ patientMeans.(cond).(den){patient}
% -------------------------------------------------------------------------
ratioPatientMeans = struct();
for ic = 1:length(CONDITIONS_ORDERED)
    fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
    ratioPatientMeans.(fld) = struct();
    for ir = 1:nRatios
        rl       = RATIO_DEFS(ir).label;
        numCells = patientMeans.(fld).(RATIO_DEFS(ir).num);
        denCells = patientMeans.(fld).(RATIO_DEFS(ir).den);
        nP = length(numCells);
        ratioCells = cell(1, nP);
        for ipp = 1:nP
            numV = numCells{ipp};
            denV = denCells{ipp};
            denV(abs(denV) < DENOM_EPS) = NaN;
            ratioCells{ipp} = numV ./ denV;
        end
        ratioPatientMeans.(fld).(rl) = ratioCells;
    end
end

% -------------------------------------------------------------------------
% RECAP DES VALEURS DE RATIO (moyenne +/- SD inter-patients, moyennee sur
% le cycle)
% -------------------------------------------------------------------------
fprintf('\n');
fprintf('=================================================================\n');
fprintf(' RECAP DES VALEURS DE RATIO EMG (moyenne +/- SD, N=%d patients)\n', length(PATIENT_IDS));
fprintf(' Valeur = moyenne du ratio (num/den) sur les 101 pts du cycle,\n');
fprintf(' par patient, puis moyenne +/- SD inter-patients par condition\n');
fprintf('=================================================================\n');
fprintf('%-24s  %-16s  %s\n', 'Ratio', 'Condition', 'Moyenne +/- SD');
fprintf('%s\n', repmat('-', 1, 60));

for ir = 1:nRatios
    rl = RATIO_DEFS(ir).label;
    for ic = 1:length(CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        pts = ratioPatientMeans.(fld).(rl);
        if isempty(pts)
            fprintf('%-24s  %-16s  %s\n', RATIO_DEFS(ir).display, COND_LABELS{ic}, '-');
            continue;
        end
        stack = cat(1, pts{:});                  % (N_patients, 101)
        cycleMeanPerPatient = nanmean(stack, 2);  % (N_patients, 1)
        mVal = nanmean(cycleMeanPerPatient);
        sVal = nanstd(cycleMeanPerPatient);
        fprintf('%-24s  %-16s  %.2f +/- %.2f\n', RATIO_DEFS(ir).display, COND_LABELS{ic}, mVal, sVal);
    end
    fprintf('%s\n', repmat('-', 1, 60));
end
fprintf('=================================================================\n\n');

% -------------------------------------------------------------------------
% ANALYSE SPM1D : ANOVA RM 7 conditions + post-hoc sur TOUTES les paires
% (meme design que extract_emg_cycles_all_comp.m, applique aux ratios)
% -------------------------------------------------------------------------
fprintf('\n=== Choix des tests statistiques (ratio EMG) ===\n');
fprintf('  Design        : mesures repetees intra-sujet (10 patients x 7 conditions)\n');
fprintf('  Donnees       : ratio point-par-point (num/den) des cycles moyens deja caches\n');
fprintf('  Test omnibus  : ANOVA RM non parametrique a 1 facteur (spm1d.stats.nonparam.anova1rm, Monte Carlo 10000 iterations)\n');
fprintf('  Post-hoc      : t-test apparie sur chacune des %d paires de conditions (spm1d.stats.ttest_paired, parametrique)\n', N_PAIRS);
fprintf('  Correction    : Holm-Bonferroni sur %d comparaisons (FWER alpha = %.2f ;\n', N_PAIRS, ALPHA_FWER);
fprintf('                  seuils de alpha/%d = %.5f a alpha/1 = %.2f selon le rang de la p-valeur)\n', N_PAIRS, ALPHA_FWER/N_PAIRS, ALPHA_FWER);
fprintf('  Temporel      : Random Field Theory via SPM1D (Pataky 2010)\n');
fprintf('%s\n', repmat('-', 1, 55));

spmData = struct();
for ic = 1:length(CONDITIONS_ORDERED)
    fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
    spmData.(fld) = struct();
    for ir = 1:nRatios
        rl  = RATIO_DEFS(ir).label;
        pts = ratioPatientMeans.(fld).(rl);
        if isempty(pts)
            spmData.(fld)(ir).mat = [];
        else
            spmData.(fld)(ir).mat = cat(1, pts{:});
        end
    end
end

spmResults = struct();
for ir = 1:nRatios
    spmResults(ir).ratio          = RATIO_DEFS(ir).label;
    spmResults(ir).anova_sig      = false;
    spmResults(ir).anova_clusters = {};
    spmResults(ir).posthoc        = struct();
end

figure('Name','SPM1D -- Ratio EMG -- ANOVA + post-hoc toutes paires', ...
       'units','normalized','outerposition',[0 0 1 1], 'Color','white');

for ir = 1:nRatios
    ax = subplot(1, nRatios, ir); %#ok<NASGU>
    hold on;

    legendHandles = gobjects(length(CONDITIONS_ORDERED), 1);
    y_min_plot = Inf; y_max_plot = -Inf;

    for ic = 1:length(CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        if isempty(spmData.(fld)(ir).mat), continue; end
        mat = spmData.(fld)(ir).mat;
        mc  = nanmean(mat, 1);
        sc  = nanstd(mat, 0, 1);
        fill([X_CYCLE fliplr(X_CYCLE)], [mc+sc fliplr(mc-sc)], COLORS(ic,:), ...
             'FaceAlpha', 0.10, 'EdgeColor','none', 'HandleVisibility','off');
        legendHandles(ic) = plot(X_CYCLE, mc, 'Color', COLORS(ic,:), 'LineWidth', 2, ...
                                 'DisplayName', COND_LABELS{ic});
        y_min_plot = min(y_min_plot, min(mc-sc));
        y_max_plot = max(y_max_plot, max(mc+sc));
    end

    if ~isfinite(y_min_plot), y_min_plot = 0; y_max_plot = 2; end
    y_min_plot = min(y_min_plot, 1); y_max_plot = max(y_max_plot, 1);  % ratio=1 toujours visible
    data_range = max(y_max_plot - y_min_plot, 0.01);

    yline(1, '--', 'Color', [0.55 0.55 0.55], 'LineWidth', 1, 'HandleVisibility', 'off');

    BAR_HEIGHT = data_range * 0.03;
    BAR_GAP    = data_range * 0.01;
    y_bar_top  = y_min_plot - data_range * 0.04;

    % ANOVA RM
    all_mat = []; group_vec = []; subj_vec = [];
    for ic = 1:length(CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        if isempty(spmData.(fld)(ir).mat), continue; end
        mat = spmData.(fld)(ir).mat;
        n   = size(mat, 1);
        all_mat   = [all_mat;   mat];
        group_vec = [group_vec; repmat(ic, n, 1)];
        subj_vec  = [subj_vec;  (1:n)'];
    end

    anova_sig = false;
    if length(unique(group_vec)) >= 2
        try
            spm_F  = spm1d.stats.nonparam.anova1rm(all_mat, group_vec, subj_vec);
            spmi_F = spm_F.inference(0.05, 'iterations', 10000, 'interp', true);
            anova_sig = ~isempty(spmi_F.clusters);
            spmResults(ir).anova_sig      = anova_sig;
            spmResults(ir).anova_clusters = spmi_F.clusters;
            if anova_sig, sig_str = 'SIGNIFICATIF'; else, sig_str = 'non significatif'; end
            fprintf('%s ANOVA : %s\n', RATIO_DEFS(ir).display, sig_str);
        catch ME
            fprintf('%s ANOVA erreur : %s\n', RATIO_DEFS(ir).display, ME.message);
        end
    end

    % Post-hoc : toutes les paires (si ANOVA sig)
    rowIdx = 0;
    if anova_sig
        % Passe 1 : SPM{t} de chaque paire testee ; passe 2 : inference au
        % seuil Holm-Bonferroni propre a chaque paire
        spmList = cell(1, N_PAIRS);
        for kp = 1:N_PAIRS
            fldA = matlab.lang.makeValidName(ALL_PAIRS{kp,1});
            fldB = matlab.lang.makeValidName(ALL_PAIRS{kp,2});
            if isempty(spmData.(fldA)(ir).mat) || isempty(spmData.(fldB)(ir).mat), continue; end
            try
                spmList{kp} = spm1d.stats.ttest_paired(spmData.(fldB)(ir).mat, spmData.(fldA)(ir).mat);
            catch ME
                fprintf('  %s | %s vs %s erreur : %s\n', RATIO_DEFS(ir).display, ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}, ME.message);
            end
        end
        [alphaHolm, pHolm] = holmAlphaSPM1D(spmList, ALPHA_FWER);

        for kp = 1:N_PAIRS
            if isempty(spmList{kp}), continue; end
            condA = ALL_PAIRS{kp,1}; condB = ALL_PAIRS{kp,2};
            fldA = matlab.lang.makeValidName(condA);
            fldB = matlab.lang.makeValidName(condB);
            data_A = spmData.(fldA)(ir).mat;
            data_B = spmData.(fldB)(ir).mat;

            try
                spmi_t = spmList{kp}.inference(alphaHolm(kp), 'two_tailed', true, 'interp', true);

                pairFld = pairFieldName(condA, condB);
                spmResults(ir).posthoc.(pairFld).clusters = spmi_t.clusters;
                spmResults(ir).posthoc.(pairFld).p_holm     = pHolm(kp);
                spmResults(ir).posthoc.(pairFld).alpha_holm = alphaHolm(kp);
                spmResults(ir).posthoc.(pairFld).sig      = ~isempty(spmi_t.clusters);
                spmResults(ir).posthoc.(pairFld).condA    = condA;
                spmResults(ir).posthoc.(pairFld).condB    = condB;

                if ~isempty(spmi_t.clusters)
                    rowIdx = rowIdx + 1;
                    y_bar = y_bar_top - (rowIdx-1) * (BAR_HEIGHT + BAR_GAP);
                    mc_B_full = nanmean(data_B, 1);
                    mc_A_full = nanmean(data_A, 1);
                    ampInfo = struct('range_fes', {}, 'range_ref', {}, 'diff_mean', {});
                    for cl = 1:length(spmi_t.clusters)
                        ep = spmi_t.clusters{cl}.endpoints;
                        rectangle('Position', [ep(1)-1, y_bar, ep(2)-ep(1), BAR_HEIGHT], ...
                                  'FaceColor', PAIR_BAR_COLOR, 'EdgeColor','none', 'FaceAlpha', 0.85);
                        idx1 = max(1, round(ep(1))); idx2 = min(101, round(ep(2)));
                        seg_B = mc_B_full(idx1:idx2);
                        seg_A = mc_A_full(idx1:idx2);
                        ampInfo(cl).range_fes = [min(seg_B) max(seg_B)];
                        ampInfo(cl).range_ref = [min(seg_A) max(seg_A)];
                        ampInfo(cl).diff_mean = mean(seg_B) - mean(seg_A);
                    end
                    spmResults(ir).posthoc.(pairFld).ampInfo = ampInfo;
                end
            catch ME
                fprintf('  %s | %s vs %s erreur : %s\n', RATIO_DEFS(ir).display, condA, condB, ME.message);
            end
        end
    end

    bar_zone = max(rowIdx, 1) * (BAR_HEIGHT + BAR_GAP);
    ylim([y_bar_top - bar_zone - data_range*0.02, y_max_plot + data_range*0.05]);
    xlim([0 100]);
    xlabel('% cycle'); ylabel('Ratio EMG (a.u.)');
    title(RATIO_DEFS(ir).display, 'FontSize', 11, 'FontWeight','bold');
    valid_h = legendHandles(arrayfun(@(h) isvalid(h) && ~strcmp(h.DisplayName,''), legendHandles));
    legend(valid_h, 'Location','best', 'FontSize', 7);
    grid on; box on; hold off;
end

sgtitle('Comparaison des conditions de stimulation — Ratio EMG, toutes paires (Analyse SPM1D)', ...
        'FontSize', 12, 'FontWeight','bold');

% -------------------------------------------------------------------------
% TABLEAU RECAPITULATIF SPM1D
% -------------------------------------------------------------------------
fprintf('\n');
fprintf('=================================================================\n');
fprintf(' TABLEAU RECAPITULATIF SPM1D — RATIO EMG (toutes comparaisons)\n');
fprintf(' ANOVA RM (N=10 patients) | Post-hoc apparies | Holm-Bonferroni alpha=%.2f (%d comparaisons)\n', ALPHA_FWER, N_PAIRS);
fprintf('=================================================================\n');
fprintf('%-24s  %-18s  %-28s  %-10s  %-10s  %s\n', ...
        'Ratio', 'Test', 'Comparaison', 'Debut (%)', 'Fin (%)', 'p-value');
fprintf('%s\n', repmat('-', 1, 100));

for ir = 1:nRatios
    res = spmResults(ir);
    if res.anova_sig
        for cl = 1:length(res.anova_clusters)
            ep = res.anova_clusters{cl}.endpoints;
            pv = res.anova_clusters{cl}.P;
            fprintf('%-24s  %-18s  %-28s  %-10.1f  %-10.1f  %.4f\n', ...
                    RATIO_DEFS(ir).display, 'ANOVA (7 cond)', '—', ep(1)-1, ep(2)-1, pv);
        end
    else
        fprintf('%-24s  %-18s  %-28s  %-10s  %-10s  %s\n', ...
                RATIO_DEFS(ir).display, 'ANOVA (7 cond)', '—', '—', '—', 'n.s.');
    end

    anyPairSig = false;
    if res.anova_sig
        for kp = 1:N_PAIRS
            pairFld = pairFieldName(ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2});
            if ~isfield(res.posthoc, pairFld), continue; end
            ph = res.posthoc.(pairFld);
            if ~isfield(ph, 'sig') || ~ph.sig, continue; end
            anyPairSig = true;
            compLabel = sprintf('%s vs %s', condLabel(ph.condA, CONDITIONS_ORDERED, COND_LABELS), condLabel(ph.condB, CONDITIONS_ORDERED, COND_LABELS));
            for cl = 1:length(ph.clusters)
                ep = ph.clusters{cl}.endpoints;
                pv = ph.clusters{cl}.P;
                fprintf('%-24s  %-18s  %-28s  %-10.1f  %-10.1f  %.4f\n', ...
                        '', 't-test pairwise', compLabel, ep(1)-1, ep(2)-1, pv);
            end
        end
    end
    if res.anova_sig && ~anyPairSig
        fprintf('%-24s  %-18s  %-28s  %-10s  %-10s  %s\n', ...
                '', 't-test pairwise', sprintf('(aucune des %d paires sig.)', N_PAIRS), '—', '—', 'n.s.');
    end
    fprintf('%s\n', repmat('-', 1, 100));
end
fprintf('=================================================================\n\n');

% -------------------------------------------------------------------------
% SAUVEGARDE CACHE : permet de relancer uniquement la figure finale au
% prochain run, sans re-lancer tout le SPM1D non parametrique.
% -------------------------------------------------------------------------
save(CACHE_FILE, 'ratioPatientMeans', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', ...
                  'RATIO_LABELS', 'RATIO_DISPLAY', 'X_CYCLE', 'spmResults', 'ALL_PAIRS', 'POSTHOC_CORRECTION');
fprintf('Cache sauvegarde : %s\n', CACHE_FILE);

% =========================================================================
% FIGURE FINALE
% =========================================================================
plotAllCompFigureEMGRatio(ratioPatientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS, ...
                           RATIO_LABELS, RATIO_DISPLAY, X_CYCLE, spmResults, ALL_PAIRS);

disp(' '); disp('Termine.');

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
