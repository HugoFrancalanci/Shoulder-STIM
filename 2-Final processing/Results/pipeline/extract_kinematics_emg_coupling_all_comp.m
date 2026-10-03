% =========================================================================
% extract_kinematics_emg_coupling_all_comp.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Coupling between the timing of arm elevation and the timing of
%               scapular muscle activity (article Figure 4). Uses the caches
%               of the humerothoracic and EMG scripts.
%                 - SPM1D comparison of the EMG envelopes normalised to the peak
%                   of each trial (averaged per participant), all muscles
%                 - repeated-measures correlation between the humerothoracic
%                   rise time and the EMG peak timing and activity duration
%               Statistics: non-parametric repeated-measures ANOVA across the
%               7 conditions (10 000 permutations), then, if significant,
%               paired t-tests on the 21 pairs of conditions with
%               Holm-Bonferroni correction (alpha = 0.05).
% -------------------------------------------------------------------------
% Parameters  : COUPLING_MUSCLE : muscle of the single-muscle figure
%               KIN_PARAM, EMG_PARAMS, MIN_CONDS
%               ALPHA_ANOVA, ALPHA_FWER, N_ITER, FORCE_RECOMPUTE_SPM
% Outputs     : Console tables, 2 figures (single muscle, all muscles),
%               cache_emg_peaknorm_spm_all_comp.mat
% -------------------------------------------------------------------------
% Dependencies: cache_humerothoracic_all_comp.mat, cache_emg_all_comp.mat,
%               cache_emg_discrete_all_comp.mat, helpers/rmCorr.m,
%               helpers/holmAlphaSPM1D.m, plotting/plotKinEmgCouplingFigure.m,
%               plotting/plotKinEmgCouplingAllMuscles.m, spm1dmatlab-master/
% References  : Bakdash JZ, Marusich LR (2017), Front Psychol 8:456
%               Burden A (2010), J Electromyogr Kinesiol 20:1023-1035
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' extract_kinematics_emg_coupling_all_comp.m');
disp('=========================================');

HERE = fileparts(fileparts(mfilename('fullpath')));
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end
addpath(fullfile(HERE, 'plotting'));
addpath(fullfile(HERE, 'helpers'));

% -------------------------------------------------------------------------
% PARAMETRES
% -------------------------------------------------------------------------
COUPLING_MUSCLE = 'TRAPS';                    % muscle de la figure
KIN_PARAM       = 'riseTime';                 % parametre cinematique (abscisse)
EMG_PARAMS      = {'peakTime', 'dur50'};      % parametres EMG (lignes du bas)
MIN_CONDS       = {'Min_fatigue', 'Min_stress', 'Min_pulse_width', 'Min_force'};

% SPM1D sur les enveloppes normalisees au pic (% du pic de chaque essai) :
% meme plan que extract_emg_cycles_all_comp.m (ANOVA RM non parametrique
% puis 21 paires, Holm-Bonferroni). Cache propre ; FORCE_RECOMPUTE_SPM pour
% refaire les permutations.
ALPHA_ANOVA = 0.05;
ALPHA_FWER  = 0.05;
N_ITER      = 10000;
FORCE_RECOMPUTE_SPM = false;
SPM_CACHE = fullfile(dataDir(), 'cache_emg_peaknorm_spm_all_comp.mat');

MUSCLE_DISPLAY = containers.Map({'TRAPS','TRAPM','TRAPI','SERRA'}, ...
    {'Upper trapezius', 'Middle trapezius', 'Lower trapezius', 'Serratus anterior'});
KIN_DISPLAY = containers.Map({'riseTime', 'peakTime'}, ...
    {'Humerothoracic elevation (% cycle)', 'Humerothoracic elevation peak timing (% cycle)'});

% -------------------------------------------------------------------------
% CHARGEMENT DES CACHES
% -------------------------------------------------------------------------
H = load(fullfile(dataDir(), 'cache_humerothoracic_all_comp.mat'), 'patientMeans', 'disc', 'x', ...
         'PATIENT_IDS', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS');
E = load(fullfile(dataDir(), 'cache_emg_all_comp.mat'), 'patientBlocks', 'EMG_LABELS', ...
         'PATIENT_IDS', 'CONDITIONS_ORDERED');
D = load(fullfile(dataDir(), 'cache_emg_discrete_all_comp.mat'), 'disc', 'EMG_LABELS', ...
         'PATIENT_IDS', 'ACT_THRESHOLD');
if ~isequal(H.PATIENT_IDS, E.PATIENT_IDS, D.PATIENT_IDS) || ~isequal(H.CONDITIONS_ORDERED, E.CONDITIONS_ORDERED)
    error('Patients ou conditions differents entre les caches cinematique et EMG.');
end
CONDITIONS_ORDERED = H.CONDITIONS_ORDERED;
COND_LABELS = H.COND_LABELS;
nCond = numel(CONDITIONS_ORDERED);
nPat  = numel(H.PATIENT_IDS);
isMin = ismember(CONDITIONS_ORDERED, MIN_CONDS);
im    = find(strcmp(D.EMG_LABELS, COUPLING_MUSCLE), 1);

% -------------------------------------------------------------------------
% CORRELATIONS A MESURES REPETEES : tous muscles x parametres
% -------------------------------------------------------------------------
fprintf('\n=== Correlation a mesures repetees (Bakdash & Marusich 2017), N = %d patients x %d conditions ===\n', nPat, nCond);
fprintf('%-20s %-10s', 'Muscle', 'EMG');
kinList = {'riseTime', 'peakTime'};
for kk = 1:numel(kinList), fprintf('  %-26s', ['vs HT ' kinList{kk}]); end
fprintf('\n');
for jm = 1:numel(D.EMG_LABELS)
    for ke = 1:numel(EMG_PARAMS)
        fprintf('%-20s %-10s', MUSCLE_DISPLAY(D.EMG_LABELS{jm}), EMG_PARAMS{ke});
        for kk = 1:numel(kinList)
            [r, p, df] = rmCorr(H.disc.(kinList{kk}), D.disc.(EMG_PARAMS{ke})(:, :, jm));
            fprintf('  %-26s', sprintf('r = %+.2f, p = %s (df %d)', r, fmtP(p), df));
        end
        fprintf('\n');
    end
end

% -------------------------------------------------------------------------
% MUSCLE DE LA FIGURE : au-dela de l'effet condition, et patient par patient
% -------------------------------------------------------------------------
kin = H.disc.(KIN_PARAM);
fprintf('\n=== %s vs HT %s ===\n', MUSCLE_DISPLAY(COUPLING_MUSCLE), KIN_PARAM);
dKin = mean(kin(:, isMin), 2, 'omitnan') - mean(kin(:, ~isMin), 2, 'omitnan');
fprintf('  HT %s : Min - (autres) = %+.1f ± %.1f %% cycle (%d/%d patients > 0)\n', ...
        KIN_PARAM, mean(dKin), std(dKin), sum(dKin > 0), nPat);
rm = struct('r', {}, 'p', {}, 'slope', {});
for ke = 1:numel(EMG_PARAMS)
    Y = D.disc.(EMG_PARAMS{ke})(:, :, im);
    [rm(ke).r, rm(ke).p, df, rm(ke).slope] = rmCorr(kin, Y);
    % double centrage (sujet puis condition) : variations residuelles
    kc = kin - mean(kin, 2, 'omitnan'); kc = kc - mean(kc, 1, 'omitnan');
    yc = Y   - mean(Y,   2, 'omitnan'); yc = yc - mean(yc, 1, 'omitnan');
    ok = ~isnan(kc) & ~isnan(yc);
    rr = sum(kc(ok) .* yc(ok)) / sqrt(sum(kc(ok).^2) * sum(yc(ok).^2)); dfr = sum(ok(:)) - nPat - nCond - 1;   % sujet + condition (-1 commun) + r
    pr = betainc(dfr / (dfr + rr^2 * dfr / (1 - rr^2)), dfr / 2, 0.5);
    dY = mean(Y(:, isMin), 2, 'omitnan') - mean(Y(:, ~isMin), 2, 'omitnan');
    sameDir = sign(dY) == sign(mean(dY)) & dKin > 0;
    fprintf('  %-9s : r_rm = %+.2f (p = %s, df %d) ; sans effet condition r = %+.2f (p = %s, df %d) ;\n', ...
            EMG_PARAMS{ke}, rm(ke).r, fmtP(rm(ke).p), df, rr, fmtP(pr), dfr);
    fprintf('              Min - (autres) = %+.1f ± %.1f %% cycle ; meme sens que le groupe ET montee plus lente : %d/%d patients\n', ...
            mean(dY), std(dY), sum(sameDir), nPat);
end

% -------------------------------------------------------------------------
% SPM1D : enveloppes normalisees au pic (tous les muscles)
% -------------------------------------------------------------------------
MUS = D.EMG_LABELS;
ALL_PAIRS = nchoosek(1:nCond, 2);      % meme ordre que les autres scripts
if isfile(SPM_CACHE) && ~FORCE_RECOMPUTE_SPM
    fprintf('\nCache SPM1D (%% du pic) trouve : %s\n', SPM_CACHE);
    load(SPM_CACHE, 'spmPeak');
else
    rng(0);
    spmPeak = struct('muscle', MUS, 'anovaSig', false, 'anovaClusters', [], ...
                     'pairSig', false(size(ALL_PAIRS,1),1), 'pairClusters', {cell(size(ALL_PAIRS,1),1)}, ...
                     'pairP', NaN(size(ALL_PAIRS,1),1), 'pairSign', zeros(size(ALL_PAIRS,1),1));
    for jm = 1:numel(MUS)
        Yc = cell(1, nCond);
        for ic = 1:nCond
            Yc{ic} = peakNormalisedPatients(E.patientBlocks, MUS{jm}, CONDITIONS_ORDERED{ic}, nPat, numel(H.x));
        end
        spmPeak(jm) = spmAllPairs(Yc, ALL_PAIRS, ALPHA_ANOVA, ALPHA_FWER, N_ITER, spmPeak(jm));
    end
    save(SPM_CACHE, 'spmPeak', 'ALL_PAIRS', 'ALPHA_ANOVA', 'ALPHA_FWER', 'N_ITER', 'CONDITIONS_ORDERED');
    fprintf('Cache SPM1D sauvegarde : %s\n', SPM_CACHE);
end
printSpmPeak(spmPeak, ALL_PAIRS, COND_LABELS, MUSCLE_DISPLAY);

% -------------------------------------------------------------------------
% FIGURES : (1) muscle COUPLING_MUSCLE seul ; (2) tous les muscles
% -------------------------------------------------------------------------
htMean = NaN(nCond, numel(H.x));
for ic = 1:nCond
    htMean(ic, :) = mean(cat(1, H.patientMeans.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic})){:}), 1, 'omitnan');
end
[emgMean, emgSD] = peakNormalisedMean(E.patientBlocks, COUPLING_MUSCLE, CONDITIONS_ORDERED, nPat, numel(H.x));

K = struct('x', H.x, 'COND_LABELS', {COND_LABELS}, 'COLORS', H.COLORS, ...
           'htMean', htMean, 'emgMean', emgMean, 'emgSD', emgSD, 'kin', kin, ...
           'emg', {{D.disc.(EMG_PARAMS{1})(:, :, im), D.disc.(EMG_PARAMS{2})(:, :, im)}}, ...
           'emgTitles', {{[MUSCLE_DISPLAY(COUPLING_MUSCLE) ' peak timing'], ...
                          sprintf('%s activity duration > %d%%', MUSCLE_DISPLAY(COUPLING_MUSCLE), D.ACT_THRESHOLD)}}, ...
           'emgYLabels', {{'Peak timing (% cycle)', 'Activity duration (% cycle)'}}, ...
           'rm', rm, 'muscleName', MUSCLE_DISPLAY(COUPLING_MUSCLE), ...
           'kinXLabel', KIN_DISPLAY(KIN_PARAM), 'actThreshold', D.ACT_THRESHOLD);
plotKinEmgCouplingFigure(K);

nMus = numel(MUS);
rmAll = struct('r', cell(numel(EMG_PARAMS), nMus), 'p', [], 'slope', []);
emgAll = cell(1, numel(EMG_PARAMS)); emgMeanAll = cell(1, nMus); emgSDAll = cell(1, nMus);
for jm = 1:nMus
    [emgMeanAll{jm}, emgSDAll{jm}] = peakNormalisedMean(E.patientBlocks, MUS{jm}, CONDITIONS_ORDERED, nPat, numel(H.x));
    for ke = 1:numel(EMG_PARAMS)
        emgAll{ke}{jm} = D.disc.(EMG_PARAMS{ke})(:, :, jm);
        [rmAll(ke,jm).r, rmAll(ke,jm).p, ~, rmAll(ke,jm).slope] = rmCorr(kin, emgAll{ke}{jm});
    end
end
K2 = struct('x', H.x, 'COND_LABELS', {COND_LABELS}, 'COLORS', H.COLORS, 'htMean', htMean, ...
            'kin', kin, 'kinXLabel', KIN_DISPLAY(KIN_PARAM), ...
            'muscleNames', {cellfun(@(m) MUSCLE_DISPLAY(m), MUS, 'UniformOutput', false)}, ...
            'emgMean', {emgMeanAll}, 'emgSD', {emgSDAll}, 'emg', {emgAll}, 'rm', rmAll, ...
            'rowNames', {{'Peak timing', sprintf('Activity duration > %d%%', D.ACT_THRESHOLD)}}, ...
            'actThreshold', D.ACT_THRESHOLD, 'spm', spmPeak, 'ALL_PAIRS', ALL_PAIRS);
plotKinEmgCouplingAllMuscles(K2);

disp(' '); disp('Termine.');


% =========================================================================
% FONCTIONS LOCALES
% =========================================================================

function P = peakNormalisedPatients(patientBlocks, muscle, cond, nPat, nPts)
    % (nPat, nPts) : chaque bloc rapporte a son propre pic, moyenne par patient
    P = NaN(nPat, nPts);
    fld = matlab.lang.makeValidName(cond);
    for ip = 1:nPat
        B = patientBlocks.(fld).(muscle){ip};
        if isempty(B), continue; end
        P(ip, :) = mean(100 * B ./ max(B, [], 2), 1);
    end
end


function st = spmAllPairs(Yc, ALL_PAIRS, alphaA, alphaF, nIter, st)
    % ANOVA RM non parametrique (7 conditions) puis, si significative, SPM{t}
    % apparie sur toutes les paires, Holm-Bonferroni (helpers/holmAlphaSPM1D.m).
    % Bornes des clusters en % du cycle (convention exacte : x = 0:100,
    % endpoints 0-based).
    nCond = numel(Yc);
    keep = all(cell2mat(cellfun(@(y) all(~isnan(y), 2), Yc, 'UniformOutput', false)), 2);   % listwise
    Y = cellfun(@(y) y(keep, :), Yc, 'UniformOutput', false);
    n = sum(keep);
    A  = kron((1:nCond)', ones(n, 1));
    S  = repmat((1:n)', nCond, 1);
    Fi = spm1d.stats.nonparam.anova1rm(cat(1, Y{:}), A, S).inference(alphaA, 'iterations', nIter, 'interp', true);
    st.anovaSig = ~isempty(Fi.clusters);
    st.anovaClusters = clusterTable(Fi.clusters);
    if ~st.anovaSig, return; end
    nP = size(ALL_PAIRS, 1);
    spmList = cell(1, nP);
    for kp = 1:nP
        spmList{kp} = spm1d.stats.ttest_paired(Y{ALL_PAIRS(kp,2)}, Y{ALL_PAIRS(kp,1)});
    end
    [alphaHolm, pHolm] = holmAlphaSPM1D(spmList, alphaF);
    for kp = 1:nP
        ti = spmList{kp}.inference(alphaHolm(kp), 'two_tailed', true, 'interp', true);
        st.pairP(kp) = pHolm(kp);
        st.pairSig(kp) = ~isempty(ti.clusters);
        st.pairClusters{kp} = clusterTable(ti.clusters);
        if st.pairSig(kp)   % signe de la difference B - A dans le 1er cluster
            ep = st.pairClusters{kp}(1, 1:2);
            idx = max(1, floor(ep(1)) + 1):min(101, ceil(ep(2)) + 1);
            st.pairSign(kp) = sign(mean(mean(Y{ALL_PAIRS(kp,2)}(:, idx) - Y{ALL_PAIRS(kp,1)}(:, idx))));
        end
    end
end


function T = clusterTable(clusters)
    % [debut fin p] par cluster, bornes en % du cycle
    T = zeros(numel(clusters), 3);
    for k = 1:numel(clusters)
        T(k, :) = [clusters{k}.endpoints(:)' clusters{k}.P];
    end
end


function printSpmPeak(spmPeak, ALL_PAIRS, COND_LABELS, MUSCLE_DISPLAY)
    fprintf('\n=== SPM1D sur les enveloppes normalisees au pic (%% du pic) ===\n');
    for jm = 1:numel(spmPeak)
        st = spmPeak(jm);
        fprintf('%-20s ANOVA : ', MUSCLE_DISPLAY(st.muscle));
        if ~st.anovaSig, fprintf('n.s.\n'); continue; end
        fprintf('%s\n', strjoin(arrayfun(@(k) sprintf('%.1f-%.1f %% (p = %.3f)', st.anovaClusters(k,1), ...
                st.anovaClusters(k,2), st.anovaClusters(k,3)), 1:size(st.anovaClusters,1), 'UniformOutput', false), ', '));
        if ~any(st.pairSig), fprintf('    aucune paire significative apres Holm\n'); continue; end
        for kp = find(st.pairSig)'
            C = st.pairClusters{kp};
            sgn = '>'; if st.pairSign(kp) > 0, sgn = '<'; end
            fprintf('    %-12s %s %-12s : %s (p Holm test = %.4f)\n', COND_LABELS{ALL_PAIRS(kp,1)}, sgn, ...
                    COND_LABELS{ALL_PAIRS(kp,2)}, strjoin(arrayfun(@(k) sprintf('%.1f-%.1f %%', C(k,1), C(k,2)), ...
                    1:size(C,1), 'UniformOutput', false), ', '), st.pairP(kp));
        end
    end
end


function [M, S] = peakNormalisedMean(patientBlocks, muscle, CONDITIONS_ORDERED, nPat, nPts)
    % Enveloppe (nCond, nPts) : chaque bloc rapporte a son propre pic (% du
    % pic), moyenne des blocs par patient, puis moyenne (M) et ecart-type (S)
    % entre patients
    M = NaN(numel(CONDITIONS_ORDERED), nPts); S = M;
    for ic = 1:numel(CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        pm = NaN(nPat, nPts);
        for ip = 1:nPat
            B = patientBlocks.(fld).(muscle){ip};        % (n_blocs, nPts)
            if isempty(B), continue; end
            pm(ip, :) = mean(100 * B ./ max(B, [], 2), 1);
        end
        M(ic, :) = mean(pm, 1, 'omitnan');
        S(ic, :) = std(pm, 0, 1, 'omitnan');
    end
end


function s = fmtP(p)
    if p < 0.001, s = '<0.001'; else, s = sprintf('%.3f', p); end
end
