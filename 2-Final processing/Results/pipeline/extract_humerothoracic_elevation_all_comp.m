% =========================================================================
% extract_humerothoracic_elevation_all_comp.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Humerothoracic elevation (humerus relative to thorax) over the
%               movement cycle, 10 participants, 7 conditions (article
%               Figure 1).
%                 - SPM1D comparison of the conditions over the cycle (N = 10)
%                 - discrete parameters per trial, averaged per participant:
%                   peak elevation, peak timing, rise time (% of the cycle at
%                   which elevation first exceeds minimum + 50 % of its range),
%                   plane of elevation at peak elevation, and mean plane of
%                   elevation between 20 and 90 deg of elevation (ascending
%                   phase, same rules as the scapulothoracic angles)
%               Statistics: non-parametric repeated-measures ANOVA across the
%               7 conditions (10 000 permutations), then, if significant,
%               paired t-tests on the 21 pairs of conditions with
%               Holm-Bonferroni correction (alpha = 0.05). The discrete
%               parameters are also compared across the 6 FES conditions only
%               (same ANOVA), as for the perceptual ratings.
% -------------------------------------------------------------------------
% Parameters  : RISE_FRACTION = 0.5, WINDOW (console summary, % cycle)
%               EXCL_ELEV_THRESHOLD = 90 deg, N_ITER, ALPHA_FWER
% Outputs     : Console tables, 1 figure (plotCombinedJointsFigure.m),
%               cache_humerothoracic_all_comp.mat
% -------------------------------------------------------------------------
% Dependencies: usercommands_conditions.m, K-LAB .mat files, helpers/,
%               plotting/plotCombinedJointsFigure.m, spm1dmatlab-master/
% References  : Pataky TC (2010), J Biomech 43:1976-1982
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' extract_humerothoracic_elevation_all_comp.m');
disp('=========================================');

HERE = fileparts(fileparts(mfilename('fullpath')));
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end
addpath(fullfile(HERE, 'plotting'));
addpath(fullfile(HERE, 'helpers'));

% -------------------------------------------------------------------------
% PARAMETRES
% -------------------------------------------------------------------------
WINDOW              = [28 38];   % % cycle, fenetre d'interet (recap descriptif)
EXCL_ELEV_THRESHOLD = 90;        % deg, zone grisee sur les figures
RISE_FRACTION       = 0.5;       % temps de montee : 1er passage a min + 50 % (pic - min)
ALPHA_FWER          = 0.05;      % Holm-Bonferroni
N_ITER              = 10000;     % permutations ANOVA RM non parametrique

FORCE_RECOMPUTE = false;
CACHE_FILE = fullfile(dataDir(), 'cache_humerothoracic_all_comp.mat');

x = 0:100;
CONDITIONS_ORDERED = {'No FES','Min_fatigue','Min_stress','Random','Min_pulse_width','Rehab','Min_force'};
COND_LABELS = {'No FES','Min fatigue','Min stress','Random','Min PW','Rehab','Min force'};
COLORS = [0.35 0.20 0.29; 0.66 0.80 0.63; 0.30 0.47 0.46; 0.91 0.76 0.45; ...
          0.89 0.63 0.33; 0.45 0.55 0.68; 0.75 0.35 0.35];
DOF_LABELS = {'Humerothoracic elevation (+)'};
MIN_CONDS  = {'Min_fatigue','Min_stress','Min_pulse_width','Min_force'};   % commandes optimales
% Nouveau parametre : toujours en dernier (ordre des permutations inchange
% pour les parametres precedents)
DISC_PARAMS = {'peakElev', 'peakTime', 'riseTime', 'planeAtPeak', 'planeMean2090'};
DISC_LABELS = {'Peak elevation (deg)', 'Peak timing (% cycle)', ...
               sprintf('Rise time to %g%% of range (%% cycle)', 100*RISE_FRACTION), ...
               'Plane of elevation at peak (deg)', 'Mean plane of elevation 20-90 deg (deg)'};
% Plan d'elevation moyen sur la montee : meme grille et memes regles que
% extract_scapulohumeral_rhythm_all_comp.m
PLANE_GRID     = 20:1:90;   % deg d'elevation humerothoracique
MAX_EXTRAP_DEG = 2.5;       % prolongation constante max sous le debut de montee (deg)

ALL_PAIRS = {};
for a = 1:numel(CONDITIONS_ORDERED)-1
    for b = a+1:numel(CONDITIONS_ORDERED)
        ALL_PAIRS(end+1, :) = CONDITIONS_ORDERED([a b]); %#ok<SAGROW>
    end
end
N_PAIRS = size(ALL_PAIRS, 1);

cacheValid = false;
if isfile(CACHE_FILE) && ~FORCE_RECOMPUTE
    S_check = load(CACHE_FILE, 'disc');   % cache sans le dernier parametre -> recalcul
    cacheValid = isfield(S_check, 'disc') && isfield(S_check.disc, DISC_PARAMS{end});
    clear S_check
end
if cacheValid
    fprintf('Cache trouve : %s\n-> pas de recalcul (FORCE_RECOMPUTE=true pour tout refaire)\n\n', CACHE_FILE);
    load(CACHE_FILE);
else
    run(fullfile(HERE, 'usercommands_conditions.m'));
    rng(0);
    warnings = {};

    % ---------------------------------------------------------------------
    % EXTRACTION : patientMeans.(cond){ip} = (1,101) ; patientBlocks idem par bloc
    % ---------------------------------------------------------------------
    % planeBlocks : plan d'elevation (1,101) de chaque bloc, memes lignes que patientBlocks
    patientMeans = struct(); patientBlocks = struct(); planeBlocks = struct();
    for ic = 1:numel(CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        patientMeans.(fld) = {}; patientBlocks.(fld) = {}; planeBlocks.(fld) = {};
    end
    for ip = 1:numel(PATIENT_IDS)
        patientID = PATIENT_IDS{ip};
        side      = DOMINANT_SIDE(patientID);
        jht       = HUMEROTHORACIC_JOINT_IDX(side);
        cycleKey  = 'rcycle';
        if strcmp(side, 'L'), cycleKey = 'lcycle'; end
        matFile = fullfile(dataFolder, ['P' num2str(str2double(patientID(2:end))) '.mat']);
        if ~isfile(matFile), error('Fichier introuvable : %s', matFile); end
        fprintf('Traitement %s (cote %s)...\n', patientID, side);
        load(matFile, 'Trial');

        analyticTrials = filterAnalytic2(Trial, patientID, PATIENT_EXCEPTIONS);
        nTrials  = numel(analyticTrials);
        condList = PATIENT_COND.(patientID);
        missingCondPos = [];
        if isfield(PATIENT_EXCEPTIONS, patientID) && isfield(PATIENT_EXCEPTIONS.(patientID), 'missingCondPositions')
            missingCondPos = PATIENT_EXCEPTIONS.(patientID).missingCondPositions;
        end
        blocks = struct(); pblocks = struct();
        for ic = 1:numel(CONDITIONS_ORDERED)
            blocks.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic})) = zeros(0, 101);
            pblocks.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic})) = zeros(0, 101);
        end
        trialIdx = 0;
        for iseq = 1:numel(condList.condition)
            cond = condList.condition{iseq};
            if ismember(iseq, missingCondPos), continue; end
            trialIdx = trialIdx + 1;
            if trialIdx > nTrials, break; end
            ht = extractHTElevation(Trial(analyticTrials(trialIdx)), jht, cycleKey);
            if isempty(ht)
                warnings{end+1} = sprintf('[WARNING] %s cond %d (%s) : elevation HT absente', patientID, iseq, cond); %#ok<SAGROW>
                continue;
            end
            fld = matlab.lang.makeValidName(cond);
            blocks.(fld)(end+1, :) = ht;
            pl = extractHTPlane(Trial(analyticTrials(trialIdx)), jht, cycleKey);
            if isempty(pl)
                warnings{end+1} = sprintf('[WARNING] %s cond %d (%s) : plan d''elevation absent', patientID, iseq, cond); %#ok<SAGROW>
                pl = NaN(1, 101);
            end
            pblocks.(fld)(end+1, :) = pl;
        end
        for ic = 1:numel(CONDITIONS_ORDERED)
            fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
            patientBlocks.(fld){ip} = blocks.(fld);
            planeBlocks.(fld){ip}   = pblocks.(fld);
            if isempty(blocks.(fld))
                patientMeans.(fld){ip} = NaN(1, 101);
            else
                patientMeans.(fld){ip} = mean(blocks.(fld), 1, 'omitnan');
            end
        end
    end

    % ---------------------------------------------------------------------
    % (1) SPM1D : ANOVA RM non parametrique + post-hoc Holm (21 paires)
    % ---------------------------------------------------------------------
    Y = cell(1, numel(CONDITIONS_ORDERED));
    for ic = 1:numel(CONDITIONS_ORDERED)
        Y{ic} = cat(1, patientMeans.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic})){:});  % (N,101)
    end
    nPat = size(Y{1}, 1);
    spmResults = struct('dof_label', DOF_LABELS{1}, 'anova_sig', false, 'anova_clusters', {{}}, 'posthoc', struct());
    Fi = spm1d.stats.nonparam.anova1rm(cat(1, Y{:}), kron((1:numel(Y))', ones(nPat,1)), repmat((1:nPat)', numel(Y), 1)) ...
           .inference(0.05, 'iterations', N_ITER, 'interp', true);
    spmResults.anova_sig = ~isempty(Fi.clusters);
    spmResults.anova_clusters = Fi.clusters;
    if spmResults.anova_sig
        spmList = cell(1, N_PAIRS);
        for kp = 1:N_PAIRS
            a = strcmp(CONDITIONS_ORDERED, ALL_PAIRS{kp,1}); b = strcmp(CONDITIONS_ORDERED, ALL_PAIRS{kp,2});
            spmList{kp} = spm1d.stats.ttest_paired(Y{b}, Y{a});
        end
        [alphaHolm, pHolm] = holmAlphaSPM1D(spmList, ALPHA_FWER);
        for kp = 1:N_PAIRS
            fld = matlab.lang.makeValidName(sprintf('%s_vs_%s', ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}));
            spmi = spmList{kp}.inference(alphaHolm(kp), 'two_tailed', true, 'interp', true);
            spmResults.posthoc.(fld) = struct('clusters', {spmi.clusters}, 'sig', ~isempty(spmi.clusters), ...
                'condA', ALL_PAIRS{kp,1}, 'condB', ALL_PAIRS{kp,2}, 'p_holm', pHolm(kp), 'alpha_holm', alphaHolm(kp));
        end
    end

    % ---------------------------------------------------------------------
    % (2) PARAMETRES DISCRETS par bloc -> moyenne par patient + stats 0D
    % ---------------------------------------------------------------------
    disc = struct();
    for k = 1:numel(DISC_PARAMS), disc.(DISC_PARAMS{k}) = NaN(nPat, numel(CONDITIONS_ORDERED)); end
    for ic = 1:numel(CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        for ip = 1:nPat
            B = patientBlocks.(fld){ip}; P = planeBlocks.(fld){ip};
            if isempty(B), continue; end
            v = NaN(size(B,1), 4);
            for kb = 1:size(B,1)
                v(kb, 1:3) = htParams(B(kb,:), x, RISE_FRACTION);
                [~, ipk] = max(B(kb,:));
                v(kb, 4) = P(kb, ipk);              % plan d'elevation au pic d'elevation
            end
            v = mean(v, 1, 'omitnan');
            for k = 1:4, disc.(DISC_PARAMS{k})(ip, ic) = v(k); end
            % plan moyen 20-90 deg : courbes moyennes du patient (elevation et
            % plan), lues a chaque degre d'elevation pendant la montee
            tE = crossingTimes(patientMeans.(fld){ip}, x, PLANE_GRID, MAX_EXTRAP_DEG);
            disc.planeMean2090(ip, ic) = mean(interp1(x, mean(P, 1, 'omitnan'), tE, 'linear'));   % NaN si plage incomplete
        end
    end
    % courbes completes dans toutes les conditions (memes regles que la figure 2)
    disc.planeMean2090(any(isnan(disc.planeMean2090), 2), :) = NaN;
    discStats = struct();
    for k = 1:numel(DISC_PARAMS)
        Yd = disc.(DISC_PARAMS{k});
        keep = all(~isnan(Yd), 2); y = Yd(keep, :); n = size(y, 1);
        st = struct('n', n, 'anova_p', NaN, 'anova_sig', false, 'p', NaN(N_PAIRS,1), 'pHolm', NaN(N_PAIRS,1), ...
                    'sig', false(N_PAIRS,1), 'meanDiff', NaN(N_PAIRS,1), 'sdDiff', NaN(N_PAIRS,1));
        Fd = spm1d.stats.nonparam.anova1rm(y(:), kron((1:size(y,2))', ones(n,1)), repmat((1:n)', size(y,2), 1)) ...
               .inference(0.05, 'iterations', N_ITER);
        st.anova_p = Fd.p; st.anova_sig = Fd.p < 0.05;
        for kp = 1:N_PAIRS
            a = find(strcmp(CONDITIONS_ORDERED, ALL_PAIRS{kp,1})); b = find(strcmp(CONDITIONS_ORDERED, ALL_PAIRS{kp,2}));
            dd = y(:,b) - y(:,a); st.meanDiff(kp) = mean(dd); st.sdDiff(kp) = std(dd);
            if std(dd) > 0
                st.p(kp) = spm1d.stats.ttest_paired(y(:,b), y(:,a)).inference(0.05, 'two_tailed', true).p;
            end
        end
        [st.pHolm, rej] = holmAdjust(st.p, ALPHA_FWER);
        st.sig = rej(:) & st.anova_sig;
        discStats.(DISC_PARAMS{k}) = st;
    end

    htGroupMean = mean(cat(1, Y{:}), 1, 'omitnan');
    EXCL_ZONE   = computeExclusionZone(htGroupMean, x, EXCL_ELEV_THRESHOLD);
    save(CACHE_FILE, 'patientMeans', 'patientBlocks', 'planeBlocks', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', 'DOF_LABELS', ...
         'x', 'spmResults', 'ALL_PAIRS', 'PATIENT_IDS', 'disc', 'discStats', 'EXCL_ZONE', 'htGroupMean', ...
         'RISE_FRACTION', 'N_ITER', 'ALPHA_FWER');
    fprintf('Cache sauvegarde : %s\n', CACHE_FILE);
    for i = 1:numel(warnings), disp(warnings{i}); end
end

% -------------------------------------------------------------------------
% Parametres discrets : ANOVA sur les 6 conditions FES seules (meme methode).
% Calculee a part (graine propre par parametre) pour ne pas modifier les
% permutations des tests precedents ; ajoutee au cache si absente.
% -------------------------------------------------------------------------
if ~isfield(discStats.(DISC_PARAMS{1}), 'anova_p_fes')
    iFES = ~strcmp(CONDITIONS_ORDERED, 'No FES');
    for k = 1:numel(DISC_PARAMS)
        Yd = disc.(DISC_PARAMS{k})(:, iFES);
        y = Yd(all(~isnan(Yd), 2), :); n = size(y, 1);
        rng(0);
        Fd = spm1d.stats.nonparam.anova1rm(y(:), kron((1:size(y,2))', ones(n,1)), repmat((1:n)', size(y,2), 1)) ...
               .inference(0.05, 'iterations', N_ITER);
        discStats.(DISC_PARAMS{k}).anova_p_fes = Fd.p;
        discStats.(DISC_PARAMS{k}).anova_sig_fes = Fd.p < 0.05;
    end
    save(CACHE_FILE, 'discStats', '-append');
    fprintf('ANOVA FES seules ajoutee au cache : %s\n', CACHE_FILE);
end

% =========================================================================
% CONSOLE
% =========================================================================
nCond = numel(CONDITIONS_ORDERED);
w = (x >= WINDOW(1)) & (x <= WINDOW(2));
fprintf('\n=== Elevation humerothoracique (+ = elevation), N = %d ===\n', numel(PATIENT_IDS));
fprintf('%-12s  %-20s', 'Condition', sprintf('Fenetre %d-%d %% (deg)', WINDOW));
fprintf('  %-18s', DISC_PARAMS{:}); fprintf('\n');
winVals = NaN(numel(PATIENT_IDS), nCond);
for ic = 1:nCond
    fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
    M = cat(1, patientMeans.(fld){:});
    winVals(:, ic) = mean(M(:, w), 2);
    fprintf('%-12s  %-20s', COND_LABELS{ic}, msd(winVals(:, ic)));
    for k = 1:numel(DISC_PARAMS), fprintf('  %-18s', msd(disc.(DISC_PARAMS{k})(:, ic))); end
    fprintf('\n');
end

isMin = ismember(CONDITIONS_ORDERED, MIN_CONDS);
dMin = mean(winVals(:, isMin), 2) - mean(winVals(:, ~isMin), 2);
fprintf('\nContraste par patient, fenetre %d-%d %% : commandes Min - {No FES, Random, Rehab}\n', WINDOW);
fprintf('  %+.1f ± %.1f deg ; %d/%d patients avec moins d''elevation en Min (descriptif)\n', ...
        mean(dMin), std(dMin), sum(dMin < 0), numel(dMin));
for k = 1:numel(DISC_PARAMS)
    dk = mean(disc.(DISC_PARAMS{k})(:, isMin), 2) - mean(disc.(DISC_PARAMS{k})(:, ~isMin), 2);
    fprintf('  %-12s : %+.1f ± %.1f\n', DISC_PARAMS{k}, mean(dk, 'omitnan'), std(dk, 'omitnan'));
end

fprintf('\n=== SPM1D (cycle complet) : ANOVA RM non parametrique + post-hoc Holm ===\n');
if ~spmResults.anova_sig
    fprintf('  ANOVA : n.s.\n');
else
    for c = 1:numel(spmResults.anova_clusters)
        ep = spmResults.anova_clusters{c}.endpoints;   % 0-based = % cycle
        fprintf('  ANOVA : %.1f-%.1f %% du cycle, p = %s\n', max(ep(1),0), min(ep(2),100), fmtP(spmResults.anova_clusters{c}.P));
    end
    anySig = false;
    for kp = 1:N_PAIRS
        fld = matlab.lang.makeValidName(sprintf('%s_vs_%s', ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}));
        ph = spmResults.posthoc.(fld);
        if ~ph.sig, continue; end
        anySig = true;
        for c = 1:numel(ph.clusters)
            ep = ph.clusters{c}.endpoints;   % 0-based = % cycle
            fprintf('  %-12s vs %-12s : %.1f-%.1f %% du cycle, p = %s\n', COND_LABELS{strcmp(CONDITIONS_ORDERED, ph.condA)}, ...
                    COND_LABELS{strcmp(CONDITIONS_ORDERED, ph.condB)}, max(ep(1),0), min(ep(2),100), fmtP(ph.clusters{c}.P));
        end
    end
    if ~anySig, fprintf('  (aucune paire significative apres Holm)\n'); end
end

fprintf('\n=== Parametres discrets : ANOVA RM (permutation) + post-hoc Holm ===\n');
for k = 1:numel(DISC_PARAMS)
    st = discStats.(DISC_PARAMS{k});
    fprintf('%-40s ANOVA p = %s ; FES seules p = %s', DISC_LABELS{k}, fmtP(st.anova_p), fmtP(st.anova_p_fes));
    if ~st.anova_sig, fprintf('  -> n.s.\n'); continue; end
    if ~any(st.sig), fprintf('  -> aucune paire sig. apres Holm\n'); continue; end
    fprintf('\n');
    for kp = find(st.sig)'
        fprintf('    %-12s vs %-12s : diff B-A = %+.1f ± %.1f ; p Holm = %s\n', ...
                COND_LABELS{strcmp(CONDITIONS_ORDERED, ALL_PAIRS{kp,1})}, COND_LABELS{strcmp(CONDITIONS_ORDERED, ALL_PAIRS{kp,2})}, ...
                st.meanDiff(kp), st.sdDiff(kp), fmtP(st.pHolm(kp)));
    end
end

% =========================================================================
% FIGURES (meme mise en page que les autres articulations). Pas de zone
% grisee ici : c'est cette courbe qui la definit pour GH / ST, l'elevation
% humerothoracique elle-meme reste interpretable au-dela de 90 deg.
% =========================================================================
J = struct('patientMeans', patientMeans, 'CONDITIONS_ORDERED', {CONDITIONS_ORDERED}, 'COND_LABELS', {COND_LABELS}, ...
           'COLORS', COLORS, 'DOF_LABELS', {DOF_LABELS}, 'rowLabel', 'Humerothoracic', 'x', x, ...
           'spmResults', spmResults, 'ALL_PAIRS', {ALL_PAIRS}, 'PATIENT_IDS', {PATIENT_IDS}, ...
           'panelTitles', {{'Elevation'}}, 'titleWeight', 'normal');
plotCombinedJointsFigure({J});

disp(' '); disp('Termine.');


% =========================================================================
% FONCTIONS LOCALES
% =========================================================================

function v = htParams(c, x, frac)
    % [pic (deg), instant du pic (% cycle), temps de montee a min + frac (pic - min)]
    v = NaN(1, 3);
    if all(isnan(c)), return; end
    [pk, ipk] = max(c); mn = min(c(1:ipk));
    v(1) = pk; v(2) = x(ipk);
    thr = mn + frac * (pk - mn);
    k = find(c(1:ipk) >= thr, 1);
    if isempty(k), return; end
    if k == 1
        v(3) = x(1);
    else
        v(3) = x(k-1) + (thr - c(k-1)) / (c(k) - c(k-1)) * (x(k) - x(k-1));  % interpolation lineaire
    end
end


function s = msd(v)
    s = sprintf('%.1f ± %.1f', mean(v, 'omitnan'), std(v, 'omitnan'));
end


function s = fmtP(p)
    if isnan(p), s = '-'; elseif p < 0.001, s = '<0.001'; else, s = sprintf('%.3f', p); end
end


function analyticIdx = filterAnalytic2(Trial, patientID, PATIENT_EXCEPTIONS)
    isAnalytic = false(1, length(Trial));
    for i = 1:length(Trial)
        if isfield(Trial(i), 'task') && strcmp(Trial(i).task, 'ANALYTIC2')
            isAnalytic(i) = true;
        end
    end
    allIdx = find(isAnalytic);
    skipFirst = 0; skipPos = [];
    if isfield(PATIENT_EXCEPTIONS, patientID)
        exc = PATIENT_EXCEPTIONS.(patientID);
        if isfield(exc, 'skipFirstN'),    skipFirst = exc.skipFirstN;    end
        if isfield(exc, 'skipPositions'), skipPos   = exc.skipPositions; end
    end
    allIdx = allIdx(skipFirst+1:end);
    if ~isempty(skipPos)
        keep = true(1, length(allIdx));
        keep(skipPos(skipPos <= length(allIdx))) = false;
        allIdx = allIdx(keep);
    end
    analyticIdx = allIdx;
end
