% =========================================================================
% extract_emg_discrete_all_comp.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Discrete EMG parameters (article Figure 3), computed from the
%               trial envelopes of cache_emg_all_comp.mat:
%                 - peak timing: % of the cycle at the envelope maximum
%                 - activity duration: % of the cycle above minimum + 50 % of
%                   the range (full width at half maximum)
%                 - peak amplitude, onset and offset (console only)
%               Trial values are averaged per participant (N = 10).
%               Statistics: non-parametric repeated-measures ANOVA across the
%               7 conditions (10 000 permutations), then, if significant,
%               paired t-tests on the 21 pairs of conditions with
%               Holm-Bonferroni correction (alpha = 0.05).
% -------------------------------------------------------------------------
% Parameters  : ACT_THRESHOLD = 50 (% of the range)
%               REPORT_MUSCLES, MANUSCRIPT_MUSCLES, MANUSCRIPT_PARAMS
%               ALPHA_ANOVA, ALPHA_FWER, N_ITER
% Outputs     : Console tables, 2 figures (all parameters, article figure),
%               cache_emg_discrete_all_comp.mat
% -------------------------------------------------------------------------
% Dependencies: cache_emg_all_comp.mat (extract_emg_cycles_all_comp.m),
%               helpers/holmAdjust.m, plotting/plotDiscreteEMGFigure.m,
%               plotting/plotDiscreteEMGManuscript.m, spm1dmatlab-master/
% References  : Cappellini G et al. (2006), J Neurophysiol 95:3426-3437
%               Martino G et al. (2014), J Neurophysiol 112:2810-2821
%               Hawkes DH et al. (2019), PLoS One 14:e0211800
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' extract_emg_discrete_all_comp.m');
disp('=========================================');

HERE = fileparts(fileparts(mfilename('fullpath')));
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end
addpath(fullfile(HERE, 'plotting'));
addpath(fullfile(HERE, 'helpers'));

% -------------------------------------------------------------------------
% PARAMETRES
% -------------------------------------------------------------------------
ACT_THRESHOLD  = 50;       % % de (pic - min) : 50 = largeur a mi-hauteur (FWHM)
ALPHA_ANOVA    = 0.05;
ALPHA_FWER     = 0.05;     % Holm-Bonferroni sur les 21 paires (par muscle x parametre)
N_ITER         = 10000;    % permutations ANOVA RM non parametrique

MUSCLE_DISPLAY = containers.Map({'TRAPS','TRAPM','TRAPI','SERRA'}, ...
    {'Upper trapezius', 'Middle trapezius', 'Lower trapezius', 'Serratus anterior'});

% Muscles rapportes (figures) : les 4 muscles. Filtre d'AFFICHAGE
% uniquement (familles Holm par muscle -> retirer un muscle ne change pas
% les resultats des autres, sans recalcul ni nouveau tirage des permutations).
REPORT_MUSCLES = {'TRAPS', 'TRAPM', 'TRAPI', 'SERRA'};

% Hypotheses issues des courbes SPM1D, mises en evidence dans la console
TARGET_CHECKS = struct( ...
    'muscle', {'TRAPI'}, ...
    'conds',  {{'No FES'}}, ...
    'params', {{'peakAmp', 'peakTime'}});

% Figure manuscrit : muscles rapportes x instant du pic et duree d'activite.
% L'amplitude du pic n'est pas montree dans l'article (biais possible du
% retrait d'artefact FES sur l'amplitude dans les conditions stimulees) ;
% elle reste calculee et visible dans la figure supplementaire.
MANUSCRIPT_MUSCLES = REPORT_MUSCLES;
MANUSCRIPT_PARAMS  = {'peakTime', 'dur50'};

% -------------------------------------------------------------------------
% CACHE : regeneration rapide (tableaux + figure) sans refaire les
% permutations. Ignore si le seuil a change ou si FORCE_RECOMPUTE.
% -------------------------------------------------------------------------
FORCE_RECOMPUTE = false;
CACHE_FILE   = fullfile(dataDir(), 'cache_emg_discrete_all_comp.mat');
SOURCE_CACHE = fullfile(dataDir(), 'cache_emg_all_comp.mat');

cacheValid = false;
if isfile(CACHE_FILE) && ~FORCE_RECOMPUTE
    cacheInfo = whos('-file', CACHE_FILE);
    if ismember('ACT_THRESHOLD', {cacheInfo.name})
        S_check = load(CACHE_FILE, 'ACT_THRESHOLD');
        cacheValid = isequal(S_check.ACT_THRESHOLD, ACT_THRESHOLD);
    end
end

if cacheValid
    fprintf('Cache trouve : %s\n', CACHE_FILE);
    fprintf('-> Regeneration rapide (pas de re-calcul des statistiques).\n\n');
    load(CACHE_FILE);
else
    if ~isfile(SOURCE_CACHE)
        error('Cache source introuvable : %s (lance d''abord extract_emg_cycles_all_comp.m)', SOURCE_CACHE);
    end
    srcInfo = whos('-file', SOURCE_CACHE);
    if ~ismember('patientBlocks', {srcInfo.name})
        error(['%s ne contient pas patientBlocks (courbes par bloc) : relance ' ...
               'extract_emg_cycles_all_comp.m (le cache est regenere automatiquement).'], SOURCE_CACHE);
    end
    load(SOURCE_CACHE, 'patientBlocks', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', 'EMG_LABELS', ...
                       'X_CYCLE', 'ALL_PAIRS', 'PATIENT_IDS');
    rng(0);  % reproductibilite des permutations

    % ---------------------------------------------------------------------
    % PARAMETRES DISCRETS (definition)
    % ---------------------------------------------------------------------
    PARAMS     = {'peakAmp', 'peakTime', sprintf('dur%d', ACT_THRESHOLD)};
    DESCR_ONLY = {sprintf('onset%d', ACT_THRESHOLD), sprintf('offset%d', ACT_THRESHOLD)};

    nPat  = numel(PATIENT_IDS);
    nCond = numel(CONDITIONS_ORDERED);
    nMus  = numel(EMG_LABELS);

    % disc.(param) : (nPat, nCond, nMus), moyenne des blocs par patient
    disc = struct();
    for f = [PARAMS DESCR_ONLY]
        disc.(f{1}) = NaN(nPat, nCond, nMus);
    end
    nBlocks = zeros(nPat, nCond, nMus);

    for ic = 1:nCond
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        for im = 1:nMus
            for ip = 1:nPat
                B = patientBlocks.(fld).(EMG_LABELS{im}){ip};  % (n_blocs, 101)
                nB = size(B, 1);
                nBlocks(ip, ic, im) = nB;
                if nB == 0, continue; end
                vals = NaN(nB, numel(PARAMS) + numel(DESCR_ONLY));
                for kb = 1:nB
                    vals(kb, :) = discreteParams(B(kb, :), X_CYCLE, ACT_THRESHOLD);
                end
                v = mean(vals, 1, 'omitnan');
                allF = [PARAMS DESCR_ONLY];
                for k = 1:numel(allF)
                    disc.(allF{k})(ip, ic, im) = v(k);
                end
            end
        end
    end

    % ---------------------------------------------------------------------
    % STATISTIQUES : ANOVA RM non parametrique + t-tests apparies Holm
    % ---------------------------------------------------------------------
    nPairs = size(ALL_PAIRS, 1);
    pairIdx = zeros(nPairs, 2);
    for kp = 1:nPairs
        pairIdx(kp, :) = [find(strcmp(CONDITIONS_ORDERED, ALL_PAIRS{kp,1})), ...
                          find(strcmp(CONDITIONS_ORDERED, ALL_PAIRS{kp,2}))];
    end

    stats = struct();
    for im = 1:nMus
        for kparam = 1:numel(PARAMS)
            prm = PARAMS{kparam};
            Y = disc.(prm)(:, :, im);              % (nPat, nCond)
            keep = all(~isnan(Y), 2);              % exclusion listwise
            y = Y(keep, :);
            n = size(y, 1);
            st = struct('n', n, 'anova_p', NaN, 'anova_sig', false, ...
                        'p', NaN(nPairs,1), 'pHolm', NaN(nPairs,1), 'sig', false(nPairs,1), ...
                        't', NaN(nPairs,1), 'meanDiff', NaN(nPairs,1), 'sdDiff', NaN(nPairs,1));
            if n >= 3
                yy = y(:);
                A  = kron((1:nCond)', ones(n, 1));
                S  = repmat((1:n)', nCond, 1);
                try
                    Fi = spm1d.stats.nonparam.anova1rm(yy, A, S).inference(ALPHA_ANOVA, 'iterations', N_ITER);
                    st.anova_p = Fi.p;
                    st.anova_sig = Fi.p < ALPHA_ANOVA;
                catch ME
                    fprintf('  %s | %s : ANOVA erreur - %s\n', EMG_LABELS{im}, prm, ME.message);
                end
                for kp = 1:nPairs
                    a = pairIdx(kp,1); b = pairIdx(kp,2);
                    d = y(:,b) - y(:,a);
                    st.meanDiff(kp) = mean(d);
                    st.sdDiff(kp)   = std(d);
                    if std(d) == 0, continue; end
                    ti = spm1d.stats.ttest_paired(y(:,b), y(:,a)).inference(ALPHA_FWER, 'two_tailed', true);
                    st.p(kp) = ti.p;
                    st.t(kp) = ti.z;
                end
                [st.pHolm, rej] = holmAdjust(st.p, ALPHA_FWER);
                st.sig = rej(:) & st.anova_sig;    % post-hoc interprete seulement si ANOVA sig.
            end
            stats(im).(prm) = st;
        end
    end

    save(CACHE_FILE, 'disc', 'nBlocks', 'stats', 'PARAMS', 'DESCR_ONLY', 'ACT_THRESHOLD', ...
         'ALPHA_ANOVA', 'ALPHA_FWER', 'N_ITER', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', ...
         'EMG_LABELS', 'X_CYCLE', 'ALL_PAIRS', 'PATIENT_IDS', 'pairIdx');
    fprintf('Cache sauvegarde : %s\n', CACHE_FILE);
end

% -------------------------------------------------------------------------
% Libelles d'affichage "Metrique (unite)" : redefinis a chaque run (et non
% relus du cache) pour pouvoir les modifier sans recalcul
% -------------------------------------------------------------------------
PARAM_LABELS = {'Peak amplitude (Normalised EMG (%))', 'Peak timing (Cycle (%))', ...
                sprintf('Activity duration > %d%% (Cycle (%%))', ACT_THRESHOLD)};

% -------------------------------------------------------------------------
% RESTRICTION AUX MUSCLES RAPPORTES (affichage uniquement)
% -------------------------------------------------------------------------
keepM  = ismember(EMG_LABELS, REPORT_MUSCLES);
discR  = structfun(@(a) a(:, :, keepM), disc, 'UniformOutput', false);
statsR = stats(keepM);
LABR   = EMG_LABELS(keepM);

% -------------------------------------------------------------------------
% TABLEAUX CONSOLE
% -------------------------------------------------------------------------
printMethods(ACT_THRESHOLD, ALPHA_ANOVA, ALPHA_FWER, N_ITER);
printDescriptive(discR, PARAMS, DESCR_ONLY, LABR, MUSCLE_DISPLAY, COND_LABELS);
printStats(statsR, PARAMS, PARAM_LABELS, LABR, MUSCLE_DISPLAY, ALL_PAIRS, CONDITIONS_ORDERED, COND_LABELS, discR, pairIdx);
printTargetChecks(TARGET_CHECKS, statsR, discR, PARAMS, PARAM_LABELS, LABR, MUSCLE_DISPLAY, ALL_PAIRS, CONDITIONS_ORDERED, COND_LABELS, pairIdx);

% -------------------------------------------------------------------------
% FIGURES : grille supplementaire (muscles rapportes x 3 parametres) + figure
% manuscrit (MANUSCRIPT_MUSCLES / MANUSCRIPT_PARAMS)
% -------------------------------------------------------------------------
plotDiscreteEMGFigure(discR, statsR, PARAMS, PARAM_LABELS, LABR, MUSCLE_DISPLAY, ...
                      COND_LABELS, COLORS, pairIdx);
plotDiscreteEMGManuscript(discR, statsR, PARAMS, PARAM_LABELS, LABR, MUSCLE_DISPLAY, ...
                          COND_LABELS, COLORS, pairIdx, MANUSCRIPT_MUSCLES, MANUSCRIPT_PARAMS);

disp(' '); disp('Termine.');


% =========================================================================
% FONCTIONS LOCALES
% =========================================================================

function v = discreteParams(c, x, threshold)
    % [peakAmp, peakTime, duree d'activite, onset, offset de la bouffee principale]
    c = c(:)';
    v = NaN(1, 5);
    if all(isnan(c)), return; end
    [pk, ipk] = max(c);
    mn = min(c);
    v(1) = pk;
    v(2) = x(ipk);
    W = supraThresholdWindows(c, x, mn + threshold / 100 * (pk - mn));
    v(3) = sum(W(:,2) - W(:,1));
    main = find(W(:,1) <= x(ipk) & W(:,2) >= x(ipk), 1);
    if ~isempty(main)
        v(4) = W(main, 1);
        v(5) = W(main, 2);
    end
end


function W = supraThresholdWindows(c, x, thr)
    % Fenetres [debut fin] (% cycle) ou c > thr, bords interpoles lineairement
    above = c > thr;
    W = zeros(0, 2);
    if ~any(above), return; end
    d  = diff([false above false]);
    i1 = find(d == 1);
    i2 = find(d == -1) - 1;
    for k = 1:numel(i1)
        a = i1(k); b = i2(k);
        xs = x(a); xe = x(b);
        if a > 1, xs = x(a-1) + (thr - c(a-1)) / (c(a) - c(a-1)) * (x(a) - x(a-1)); end
        if b < numel(c), xe = x(b) + (thr - c(b)) / (c(b+1) - c(b)) * (x(b+1) - x(b)); end
        W(end+1, :) = [xs xe]; %#ok<AGROW>
    end
end


function printMethods(th, aA, aF, nIt)
    fprintf('\n=== Parametres discrets EMG (toutes comparaisons) ===\n');
    fprintf('  Niveau        : courbe moyenne de chaque bloc -> parametres -> moyenne des blocs par patient (N=10)\n');
    fprintf('  Pic           : amplitude max de l''enveloppe (%% baseline) et instant (%% cycle)\n');
    fprintf('  Duree activite: %% du cycle ou l''enveloppe > min + %g%% x (pic - min) (FWHM ; Cappellini 2006)\n', th);
    fprintf('  Omnibus       : ANOVA RM non parametrique (spm1d 0D, %d permutations), alpha = %.2f\n', nIt, aA);
    fprintf('  Post-hoc      : t-tests apparies sur les 21 paires, Holm-Bonferroni (FWER %.2f) par muscle x parametre,\n', aF);
    fprintf('                  interpretes uniquement si l''ANOVA est significative\n');
end


function printDescriptive(disc, PARAMS, DESCR_ONLY, EMG_LABELS, MUSCLE_DISPLAY, COND_LABELS)
    allF = [PARAMS DESCR_ONLY];
    for im = 1:numel(EMG_LABELS)
        fprintf('\n--- %s : moyenne ± ET (N patients) ---\n', MUSCLE_DISPLAY(EMG_LABELS{im}));
        fprintf('%-12s', 'Condition');
        for k = 1:numel(allF), fprintf('  %-17s', allF{k}); end
        fprintf('\n');
        for ic = 1:numel(COND_LABELS)
            fprintf('%-12s', COND_LABELS{ic});
            for k = 1:numel(allF)
                v = disc.(allF{k})(:, ic, im);
                fprintf('  %-17s', sprintf('%.1f ± %.1f', mean(v, 'omitnan'), std(v, 'omitnan')));
            end
            fprintf('\n');
        end
    end
end


function printStats(stats, PARAMS, PARAM_LABELS, EMG_LABELS, MUSCLE_DISPLAY, ALL_PAIRS, CONDITIONS_ORDERED, COND_LABELS, disc, pairIdx)
    fprintf('\n=================================================================\n');
    fprintf(' STATISTIQUES - ANOVA RM (permutation) + post-hoc Holm-Bonferroni\n');
    fprintf('=================================================================\n');
    for im = 1:numel(EMG_LABELS)
        for k = 1:numel(PARAMS)
            st = stats(im).(PARAMS{k});
            fprintf('%-24s %-38s ANOVA p = %-7s (N=%d)', MUSCLE_DISPLAY(EMG_LABELS{im}), PARAM_LABELS{k}, fmtP(st.anova_p), st.n);
            if ~st.anova_sig
                fprintf('  -> n.s.\n');
                continue;
            end
            if ~any(st.sig)
                fprintf('  -> aucune paire sig. apres Holm\n');
                continue;
            end
            fprintf('\n');
            for kp = find(st.sig)'
                a = pairIdx(kp,1); b = pairIdx(kp,2);
                vA = disc.(PARAMS{k})(:, a, im); vB = disc.(PARAMS{k})(:, b, im);
                fprintf('    %-12s vs %-12s : %s = %.1f ± %.1f vs %.1f ± %.1f ; diff B-A = %+.1f ± %.1f ; t = %.2f ; p = %s ; p Holm = %s\n', ...
                        condLabel(ALL_PAIRS{kp,1}, CONDITIONS_ORDERED, COND_LABELS), condLabel(ALL_PAIRS{kp,2}, CONDITIONS_ORDERED, COND_LABELS), ...
                        PARAMS{k}, mean(vA,'omitnan'), std(vA,'omitnan'), mean(vB,'omitnan'), std(vB,'omitnan'), ...
                        st.meanDiff(kp), st.sdDiff(kp), st.t(kp), fmtP(st.p(kp)), fmtP(st.pHolm(kp)));
            end
        end
        fprintf('%s\n', repmat('-', 1, 90));
    end
end


function printTargetChecks(TC, stats, disc, PARAMS, PARAM_LABELS, EMG_LABELS, MUSCLE_DISPLAY, ALL_PAIRS, CONDITIONS_ORDERED, COND_LABELS, pairIdx)
    fprintf('\n=================================================================\n');
    fprintf(' VERIFICATION CIBLEE (hypotheses issues des courbes SPM1D)\n');
    fprintf('=================================================================\n');
    for t = 1:numel(TC)
        im = find(strcmp(EMG_LABELS, TC(t).muscle), 1);
        if isempty(im), continue; end
        for c = 1:numel(TC(t).conds)
            ic = find(strcmp(CONDITIONS_ORDERED, TC(t).conds{c}), 1);
            for k = 1:numel(TC(t).params)
                prm = TC(t).params{k};
                kparam = find(strcmp(PARAMS, prm), 1);
                if isempty(kparam), continue; end
                st = stats(im).(prm);
                fprintf('\n%s - %s - %s  (ANOVA p = %s)\n', MUSCLE_DISPLAY(TC(t).muscle), ...
                        condLabel(TC(t).conds{c}, CONDITIONS_ORDERED, COND_LABELS), PARAM_LABELS{kparam}, fmtP(st.anova_p));
                v0 = disc.(prm)(:, ic, im);
                fprintf('  %s : %.1f ± %.1f\n', condLabel(TC(t).conds{c}, CONDITIONS_ORDERED, COND_LABELS), mean(v0,'omitnan'), std(v0,'omitnan'));
                for kp = find(any(pairIdx == ic, 2))'
                    other = pairIdx(kp, pairIdx(kp,:) ~= ic);
                    sgn = 1; if pairIdx(kp,1) == ic, sgn = -1; end  % diff = cond cible - autre
                    vO = disc.(prm)(:, other, im);
                    flag = '';
                    if st.sig(kp), flag = '  <-- SIGNIFICATIF (Holm)'; end
                    fprintf('    vs %-12s : %.1f ± %.1f ; diff (cible - autre) = %+.1f ± %.1f ; p = %-7s ; p Holm = %-7s%s\n', ...
                            condLabel(CONDITIONS_ORDERED{other}, CONDITIONS_ORDERED, COND_LABELS), ...
                            mean(vO,'omitnan'), std(vO,'omitnan'), sgn * st.meanDiff(kp), st.sdDiff(kp), ...
                            fmtP(st.p(kp)), fmtP(st.pHolm(kp)), flag);
                end
            end
        end
    end
end


function s = fmtP(p)
    if isnan(p)
        s = '-';
    elseif p < 0.001
        s = '<0.001';
    else
        s = sprintf('%.3f', p);
    end
end


function lbl = condLabel(condRaw, CONDITIONS_ORDERED, COND_LABELS)
    idx = find(strcmp(CONDITIONS_ORDERED, condRaw), 1);
    if isempty(idx)
        lbl = strrep(condRaw, '_', ' ');
    else
        lbl = COND_LABELS{idx};
    end
end
