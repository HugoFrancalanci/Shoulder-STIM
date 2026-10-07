% =========================================================================
% extract_scapulohumeral_rhythm_all_comp.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Scapulothoracic and glenohumeral angles as a function of
%               humerothoracic elevation during the ascending phase (article
%               Figure 2, first row, drawn by
%               extract_emg_elevation_all_comp.m). For each elevation
%               between 20 and 90 deg (1 deg steps), the angles are read at
%               the first instant the arm reaches that elevation. Curves
%               starting less than 2.5 deg above 20 deg are extended with
%               their first value. SPM1D comparison of the conditions with humerothoracic
%               elevation as the domain.
%               Statistics: non-parametric repeated-measures ANOVA across the
%               7 conditions (10 000 permutations), then, if significant,
%               paired t-tests on the 21 pairs of conditions with
%               Holm-Bonferroni correction (alpha = 0.05).
% -------------------------------------------------------------------------
% Parameters  : ELEV_GRID = 20:1:90 deg, MAX_EXTRAP_DEG = 2.5 deg
%               N_ITER, ALPHA_FWER
% Outputs     : Console tables, cache_scapulohumeral_rhythm_all_comp.mat
% -------------------------------------------------------------------------
% Dependencies: cache_glenohumeral_all_comp.mat,
%               cache_scapulothoracic_all_comp.mat,
%               cache_humerothoracic_all_comp.mat, helpers/ (crossingTimes.m),
%               spm1dmatlab-master/
% References  : Pataky TC (2010), J Biomech 43:1976-1982
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' extract_scapulohumeral_rhythm_all_comp.m');
disp('=========================================');

HERE = fileparts(fileparts(mfilename('fullpath')));
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end
addpath(fullfile(HERE, 'helpers'));

% -------------------------------------------------------------------------
% PARAMETRES
% -------------------------------------------------------------------------
ELEV_GRID      = 20:1:90;   % deg d'elevation humerothoracique (consigne article, <= 90)
MAX_EXTRAP_DEG = 2.5;       % prolongation constante max sous le debut de montee (deg)
N_ITER     = 10000;
ALPHA_FWER = 0.05;
MIN_CONDS  = {'Min_fatigue','Min_stress','Min_pulse_width','Min_force'};   % commandes optimales

FORCE_RECOMPUTE = false;
CACHE_FILE = fullfile(dataDir(), 'cache_scapulohumeral_rhythm_all_comp.mat');

cacheValid = false;
if isfile(CACHE_FILE) && ~FORCE_RECOMPUTE
    S_check = load(CACHE_FILE);
    cacheValid = isfield(S_check, 'ELEV_GRID') && isequal(S_check.ELEV_GRID, ELEV_GRID) && ...
                 isfield(S_check, 'MAX_EXTRAP_DEG') && isequal(S_check.MAX_EXTRAP_DEG, MAX_EXTRAP_DEG);
    clear S_check
end

if cacheValid
    fprintf('Cache trouve : %s\n-> pas de recalcul\n\n', CACHE_FILE);
    load(CACHE_FILE);
else
    HT = load(fullfile(dataDir(), 'cache_humerothoracic_all_comp.mat'), 'patientMeans', 'x');
    JOINT_FILES = {'Glenohumeral', 'cache_glenohumeral_all_comp.mat'; ...
                   'Scapulothoracic', 'cache_scapulothoracic_all_comp.mat'};
    rng(0);
    joints = cell(1, size(JOINT_FILES, 1));
    for j = 1:size(JOINT_FILES, 1)
        S = load(fullfile(dataDir(), JOINT_FILES{j,2}), 'patientMeans', 'CONDITIONS_ORDERED', 'COND_LABELS', ...
                 'COLORS', 'DOF_LABELS', 'ALL_PAIRS', 'PATIENT_IDS', 'x');
        J = struct('name', JOINT_FILES{j,1}, 'DOF_LABELS', {S.DOF_LABELS}, 'rhythmMeans', struct());
        nDOF = numel(S.DOF_LABELS); nPat = numel(S.PATIENT_IDS); nCond = numel(S.CONDITIONS_ORDERED);

        % --- angles articulaires en fonction de l'elevation HT (montee) ---
        for ic = 1:nCond
            fld = matlab.lang.makeValidName(S.CONDITIONS_ORDERED{ic});
            J.rhythmMeans.(fld) = cell(1, nPat);
            for ip = 1:nPat
                tE = crossingTimes(HT.patientMeans.(fld){ip}, HT.x, ELEV_GRID, MAX_EXTRAP_DEG);
                A  = S.patientMeans.(fld){ip};               % (nDOF, 101)
                R  = NaN(nDOF, numel(ELEV_GRID));
                for id = 1:nDOF
                    R(id, :) = interp1(S.x, A(id, :), tE, 'linear');
                end
                J.rhythmMeans.(fld){ip} = R;
            end
        end
        % courbes completes sur la plage dans toutes les conditions :
        % meme N pour les stats, le contraste et la figure
        keepPat = true(1, nPat);
        for ic = 1:nCond
            Rs = J.rhythmMeans.(matlab.lang.makeValidName(S.CONDITIONS_ORDERED{ic}));
            keepPat = keepPat & cellfun(@(r) ~any(isnan(r(:))), Rs);
        end
        for ic = 1:nCond
            fld = matlab.lang.makeValidName(S.CONDITIONS_ORDERED{ic});
            for ip = find(~keepPat)
                J.rhythmMeans.(fld){ip}(:) = NaN;
            end
        end
        J.excluded = S.PATIENT_IDS(~keepPat);

        % --- SPM1D par DOF (domaine = elevation HT) ---
        J.spmResults = struct('dof_label', {}, 'anova_sig', {}, 'anova_clusters', {}, 'posthoc', {}, 'n', {});
        for id = 1:nDOF
            Y = cell(1, nCond);
            for ic = 1:nCond
                Rs = J.rhythmMeans.(matlab.lang.makeValidName(S.CONDITIONS_ORDERED{ic}));
                Y{ic} = cell2mat(cellfun(@(r) r(id, :), Rs(:), 'UniformOutput', false));   % (nPat, nGrid)
            end
            keep = all(~isnan(cat(2, Y{:})), 2);         % exclusion listwise si courbe incomplete
            Y = cellfun(@(y) y(keep, :), Y, 'UniformOutput', false);
            n = sum(keep);
            res = struct('dof_label', S.DOF_LABELS{id}, 'anova_sig', false, 'anova_clusters', {{}}, 'posthoc', struct(), 'n', n);
            Fi = spm1d.stats.nonparam.anova1rm(cat(1, Y{:}), kron((1:nCond)', ones(n,1)), repmat((1:n)', nCond, 1)) ...
                   .inference(0.05, 'iterations', N_ITER, 'interp', true);
            res.anova_sig = ~isempty(Fi.clusters);
            res.anova_clusters = Fi.clusters;
            if res.anova_sig
                nPairs = size(S.ALL_PAIRS, 1);
                spmList = cell(1, nPairs);
                for kp = 1:nPairs
                    a = strcmp(S.CONDITIONS_ORDERED, S.ALL_PAIRS{kp,1}); b = strcmp(S.CONDITIONS_ORDERED, S.ALL_PAIRS{kp,2});
                    spmList{kp} = spm1d.stats.ttest_paired(Y{b}, Y{a});
                end
                [alphaHolm, pHolm] = holmAlphaSPM1D(spmList, ALPHA_FWER);
                for kp = 1:nPairs
                    pf = matlab.lang.makeValidName(sprintf('%s_vs_%s', S.ALL_PAIRS{kp,1}, S.ALL_PAIRS{kp,2}));
                    spmi = spmList{kp}.inference(alphaHolm(kp), 'two_tailed', true, 'interp', true);
                    res.posthoc.(pf) = struct('clusters', {spmi.clusters}, 'sig', ~isempty(spmi.clusters), ...
                        'condA', S.ALL_PAIRS{kp,1}, 'condB', S.ALL_PAIRS{kp,2}, 'p_holm', pHolm(kp), 'alpha_holm', alphaHolm(kp));
                end
            end
            J.spmResults(id) = res;
        end
        joints{j} = J;
        CONDITIONS_ORDERED = S.CONDITIONS_ORDERED; COND_LABELS = S.COND_LABELS; COLORS = S.COLORS;
        ALL_PAIRS = S.ALL_PAIRS; PATIENT_IDS = S.PATIENT_IDS;
    end
    save(CACHE_FILE, 'joints', 'ELEV_GRID', 'MAX_EXTRAP_DEG', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', 'ALL_PAIRS', ...
         'PATIENT_IDS', 'N_ITER', 'ALPHA_FWER');
    fprintf('Cache sauvegarde : %s\n', CACHE_FILE);
end

% =========================================================================
% CONSOLE
% =========================================================================
isMin = ismember(CONDITIONS_ORDERED, MIN_CONDS);
% endpoints spm1d = position 0-based du noeud (X = 0:Q-1 dans spm1d.geom.cluster_geom)
nodeToDeg = @(ep) ELEV_GRID(1) + ep * (ELEV_GRID(2) - ELEV_GRID(1));
SHOW_ELEV = [50 70 90];   % elevations auxquelles les angles moyens sont affiches
for j = 1:numel(joints)
    J = joints{j};
    fprintf('\n=== %s : angles en fonction de l''elevation humerothoracique (%d-%d deg, montee) ===\n', ...
            J.name, ELEV_GRID(1), ELEV_GRID(end));
    fprintf('    N = %d\n', numel(PATIENT_IDS) - numel(J.excluded));
    for id = 1:numel(J.DOF_LABELS)
        res = J.spmResults(id);
        % contraste descriptif Min - autres, moyenne sur la grille, par patient
        M = NaN(numel(PATIENT_IDS), numel(CONDITIONS_ORDERED));
        for ic = 1:numel(CONDITIONS_ORDERED)
            Rs = J.rhythmMeans.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic}));
            M(:, ic) = cellfun(@(r) mean(r(id, :), 'omitnan'), Rs(:));
        end
        d = mean(M(:, isMin), 2) - mean(M(:, ~isMin), 2);
        fprintf('%-40s  Min - autres = %+.1f ± %.1f deg (%d/%d patients < 0)\n', res.dof_label, ...
                mean(d, 'omitnan'), std(d, 'omitnan'), sum(d < 0), sum(~isnan(d)));
        % angles moyens par condition a quelques elevations (sens des differences)
        fprintf('    %-12s', 'Condition'); fprintf('  %5d deg', SHOW_ELEV); fprintf('\n');
        for ic = 1:numel(CONDITIONS_ORDERED)
            Rs = J.rhythmMeans.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic}));
            Mg = mean(cell2mat(cellfun(@(r) r(id, :), Rs(:), 'UniformOutput', false)), 1, 'omitnan');
            fprintf('    %-12s', COND_LABELS{ic}); fprintf('  %8.1f', Mg(ismember(ELEV_GRID, SHOW_ELEV))); fprintf('\n');
        end
        if ~res.anova_sig
            fprintf('    ANOVA : n.s.\n');
            continue;
        end
        for c = 1:numel(res.anova_clusters)
            ep = res.anova_clusters{c}.endpoints;
            fprintf('    ANOVA : %.1f-%.1f deg d''elevation, p = %s\n', nodeToDeg(ep(1)), nodeToDeg(ep(2)), fmtP(res.anova_clusters{c}.P));
        end
        anySig = false;
        for kp = 1:size(ALL_PAIRS, 1)
            pf = matlab.lang.makeValidName(sprintf('%s_vs_%s', ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}));
            ph = res.posthoc.(pf);
            if ~ph.sig, continue; end
            anySig = true;
            for c = 1:numel(ph.clusters)
                ep = ph.clusters{c}.endpoints;
                fprintf('    %-12s vs %-12s : %.1f-%.1f deg, p = %s\n', COND_LABELS{strcmp(CONDITIONS_ORDERED, ph.condA)}, ...
                        COND_LABELS{strcmp(CONDITIONS_ORDERED, ph.condB)}, nodeToDeg(ep(1)), nodeToDeg(ep(2)), fmtP(ph.clusters{c}.P));
            end
        end
        if ~anySig, fprintf('    (aucune paire significative apres Holm)\n'); end
    end
end

disp(' '); disp('Termine.');


% =========================================================================
% FONCTIONS LOCALES
% =========================================================================

function s = fmtP(p)
    if isnan(p), s = '-'; elseif p < 0.001, s = '<0.001'; else, s = sprintf('%.3f', p); end
end
