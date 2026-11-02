% =========================================================================
% compare_ocp_vs_nonocp.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : November 2026
% -------------------------------------------------------------------------
% Description : Comparison of the optimised patterns (OCP: Min PW, Min force,
%               Min stress, Min fatigue) with the non-optimised patterns
%               (Rehab and Random together, then Rehab alone). Each participant
%               gives one value or curve per group, the mean of the group's
%               conditions, so that a participant counts only once. No FES is
%               not used.
%               Outcomes: perceived discomfort and assistance, discrete
%               thoracohumeral parameters, thoracohumeral elevation over the
%               cycle, scapulothoracic angles and EMG (% of peak) over the
%               20-90 deg elevation range.
%               Statistics (paired, two-tailed, all sign permutations):
%                 - ratings: Wilcoxon signed-rank test
%                 - discrete parameters: permutation t-test
%                 - curves: non-parametric SPM1D t-test, with the parametric
%                   SPM1D t-test as a comparison
%               Holm-Bonferroni correction within each family of outcomes.
% -------------------------------------------------------------------------
% Parameters  : OCP_CONDS, REF_GROUPS, ALPHA, PERCEPT_DIR
% Outputs     : Console tables, cache_ocp_vs_nonocp.mat
% -------------------------------------------------------------------------
% Dependencies: cache_humerothoracic_all_comp.mat,
%               cache_scapulohumeral_rhythm_all_comp.mat,
%               cache_emg_elevation_all_comp.mat, Data_clean_discomfort.csv,
%               Data_clean_assistance.csv, helpers/holmAdjust.m,
%               spm1dmatlab-master/
% References  : Holm S (1979), Scand J Stat 6:65-70
%               Pataky TC (2010), J Biomech 43:1976-1982
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' compare_ocp_vs_nonocp.m');
disp('=========================================');

HERE = fileparts(fileparts(mfilename('fullpath')));
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end
addpath(fullfile(HERE, 'helpers'));

% -------------------------------------------------------------------------
% PARAMETRES
% -------------------------------------------------------------------------
OCP_CONDS  = {'Min_pulse_width','Min_force','Min_stress','Min_fatigue'};
REF_GROUPS = struct('name', {'Rehab + Random', 'Rehab'}, 'conds', {{'Rehab','Random'}, {'Rehab'}});
ALPHA      = 0.05;
PERCEPT_DIR = ['C:\Users\franc\OneDrive - Université de Genève\PhD Hugo\05_Ressources\01_Data\01_Etudes\' ...
               'E02_Classification_rTSA\Clinique\Données\KLAB-UPPERLIMB-PROTOCOL01\Data\__FES_Kevin_Co'];
DISC_PARAMS = {'peakElev', 'peakTime', 'planeMean2090'};
DISC_LABELS = {'Peak elevation (deg)', 'Peak timing (% cycle)', 'Mean plane of elevation (deg)'};
OUTCOMES    = {'discomfort', 'assistance'};
MUSCLE_DISPLAY = containers.Map({'TRAPS','TRAPM','TRAPI','SERRA'}, ...
    {'Upper trapezius', 'Middle trapezius', 'Lower trapezius', 'Serratus anterior'});
CACHE_FILE = fullfile(dataDir(), 'cache_ocp_vs_nonocp.mat');

% -------------------------------------------------------------------------
% CHARGEMENT DES DONNEES
% -------------------------------------------------------------------------
H = load(fullfile(dataDir(), 'cache_humerothoracic_all_comp.mat'), 'patientMeans', 'x', 'disc', ...
         'CONDITIONS_ORDERED', 'PATIENT_IDS');
RH = load(fullfile(dataDir(), 'cache_scapulohumeral_rhythm_all_comp.mat'), 'joints', 'ELEV_GRID');
E = load(fullfile(dataDir(), 'cache_emg_elevation_all_comp.mat'), 'elevProf', 'ELEV_GRID', 'EMG_LABELS', ...
         'CONDITIONS_ORDERED');
CONDS = H.CONDITIONS_ORDERED;
nPat  = numel(H.PATIENT_IDS);

percept = cell(1, numel(OUTCOMES));
for k = 1:numel(OUTCOMES)
    percept{k} = readtable(fullfile(PERCEPT_DIR, ['Data_clean_' OUTCOMES{k} '.csv']), 'TextType', 'string');
    percept{k}.Condition = replace(percept{k}.Condition, 'Min_pw', 'Min_pulse_width');   % nom utilise dans le pipeline
end

Yht = cell(1, numel(CONDS));
for ic = 1:numel(CONDS)
    Yht{ic} = cat(1, H.patientMeans.(matlab.lang.makeValidName(CONDS{ic})){:});
end
JST = RH.joints{cellfun(@(j) strcmp(j.name, 'Scapulothoracic'), RH.joints)};
nDOF = numel(JST.DOF_LABELS);
Yst = cell(1, nDOF);
for id = 1:nDOF
    Yst{id} = cell(1, numel(CONDS));
    for ic = 1:numel(CONDS)
        Rs = JST.rhythmMeans.(matlab.lang.makeValidName(CONDS{ic}));
        Yst{id}{ic} = cell2mat(cellfun(@(r) r(id, :), Rs(:), 'UniformOutput', false));
    end
end
nMus = numel(E.EMG_LABELS);

% -------------------------------------------------------------------------
% CONTRASTES : OCP contre chaque groupe de reference
% -------------------------------------------------------------------------
results = struct('name', {REF_GROUPS.name}, 'conds', {REF_GROUPS.conds}, 'ratings', [], 'discRes', [], ...
                 'curvesHT', [], 'curvesST', [], 'curvesEMG', []);
for ir = 1:numel(REF_GROUPS)
    refConds = REF_GROUPS(ir).conds;
    isOCP = ismember(CONDS, OCP_CONDS);
    isRef = ismember(CONDS, refConds);

    % --- (1) notes perceptives ---
    ratings = struct('name', OUTCOMES, 'ocp', [], 'ref', [], 'p', NaN, 'pHolm', NaN, 'nLower', NaN, 'n', NaN);
    for k = 1:numel(OUTCOMES)
        T = percept{k};
        P = unique(T.Participant);
        [vO, vR] = deal(NaN(numel(P), 1));
        for ip = 1:numel(P)
            vO(ip) = groupRating(T, P(ip), OCP_CONDS);
            vR(ip) = groupRating(T, P(ip), refConds);
        end
        d = vO - vR;
        ratings(k).ocp = vO; ratings(k).ref = vR;
        ratings(k).p = signFlipP(signedRankValues(d));
        ratings(k).nLower = sum(d < 0); ratings(k).n = numel(d);
    end
    pAdj = holmAdjust([ratings.p], ALPHA);
    for k = 1:numel(ratings), ratings(k).pHolm = pAdj(k); end

    % --- (2) parametres discrets thoracohumeraux ---
    discRes = struct('param', DISC_PARAMS, 'label', DISC_LABELS, 'ocp', [], 'ref', [], 'p', NaN, 'pHolm', NaN, 'nLower', NaN, 'n', NaN);
    for k = 1:numel(DISC_PARAMS)
        Yd = H.disc.(DISC_PARAMS{k});
        keep = all(~isnan(Yd), 2);
        vO = mean(Yd(keep, isOCP), 2); vR = mean(Yd(keep, isRef), 2);
        d = vO - vR;
        discRes(k).ocp = vO; discRes(k).ref = vR;
        discRes(k).p = signFlipP(d);
        discRes(k).nLower = sum(d < 0); discRes(k).n = numel(d);
    end
    pAdj = holmAdjust([discRes.p], ALPHA);
    for k = 1:numel(discRes), discRes(k).pHolm = pAdj(k); end

    % --- (3) courbes : elevation (cycle), scapulothoracique et EMG (elevation) ---
    curvesHT = compareCurves(pooled(Yht, isOCP), pooled(Yht, isRef), H.x, ALPHA);
    curvesHT.label = 'Thoracohumeral elevation';

    curvesST = cell(1, nDOF);
    for id = 1:nDOF
        curvesST{id} = compareCurves(pooled(Yst{id}, isOCP), pooled(Yst{id}, isRef), RH.ELEV_GRID, ALPHA);
        curvesST{id}.label = JST.DOF_LABELS{id};
    end
    curvesST = holmOnCurves([curvesST{:}], ALPHA);

    curvesEMG = cell(1, nMus);
    for jm = 1:nMus
        curvesEMG{jm} = compareCurves(pooled(E.elevProf{jm}, ismember(E.CONDITIONS_ORDERED, OCP_CONDS)), ...
                                      pooled(E.elevProf{jm}, ismember(E.CONDITIONS_ORDERED, refConds)), E.ELEV_GRID, ALPHA);
        curvesEMG{jm}.label = MUSCLE_DISPLAY(E.EMG_LABELS{jm});
    end
    curvesEMG = holmOnCurves([curvesEMG{:}], ALPHA);

    results(ir).ratings = ratings; results(ir).discRes = discRes;
    results(ir).curvesHT = curvesHT; results(ir).curvesST = curvesST; results(ir).curvesEMG = curvesEMG;
end

save(CACHE_FILE, 'results', 'OCP_CONDS', 'REF_GROUPS', 'ALPHA');
fprintf('Cache sauvegarde : %s\n', CACHE_FILE);

% =========================================================================
% CONSOLE
% =========================================================================
for ir = 1:numel(results)
    R = results(ir);
    fprintf('\n#########################################################\n');
    fprintf('OCP (%s) contre %s (N = %d, difference = OCP - reference)\n', strjoin(OCP_CONDS, ', '), R.name, nPat);
    fprintf('#########################################################\n');

    fprintf('\n=== Notes perceptives (Wilcoxon apparie exact, Holm sur 2 tests) ===\n');
    for k = 1:numel(R.ratings)
        r = R.ratings(k);
        fprintf('%-12s OCP %.2f ± %.2f ; ref %.2f ± %.2f ; diff %+.2f ± %.2f ; %d/%d OCP < ref ; p = %s ; p Holm = %s\n', ...
                r.name, mean(r.ocp), std(r.ocp), mean(r.ref), std(r.ref), mean(r.ocp - r.ref), std(r.ocp - r.ref), ...
                r.nLower, r.n, fmtP(r.p), fmtP(r.pHolm));
    end

    fprintf('\n=== Parametres discrets (permutation appariee, Holm sur 3 tests) ===\n');
    for k = 1:numel(R.discRes)
        r = R.discRes(k);
        fprintf('%-32s OCP %.1f ± %.1f ; ref %.1f ± %.1f ; diff %+.1f ± %.1f ; %d/%d OCP < ref ; p = %s ; p Holm = %s\n', ...
                r.label, mean(r.ocp), std(r.ocp), mean(r.ref), std(r.ref), mean(r.ocp - r.ref), std(r.ocp - r.ref), ...
                r.nLower, r.n, fmtP(r.p), fmtP(r.pHolm));
    end

    fprintf('\n=== Courbes : elevation sur le cycle (%% du cycle) ===\n');
    printCurve(R.curvesHT);
    fprintf('\n=== Courbes : scapulothoracique (deg d''elevation, Holm sur %d DOF) ===\n', nDOF);
    for id = 1:nDOF, printCurve(R.curvesST(id)); end
    fprintf('\n=== Courbes : EMG en %% du pic (deg d''elevation, Holm sur %d muscles) ===\n', nMus);
    for jm = 1:nMus, printCurve(R.curvesEMG(jm)); end
end

disp(' '); disp('Termine.');


% =========================================================================
% FONCTIONS LOCALES
% =========================================================================

function v = groupRating(T, participant, conds)
    % Moyenne des conditions du groupe, chacune etant la moyenne de ses essais
    vals = NaN(1, numel(conds));
    for ic = 1:numel(conds)
        vals(ic) = mean(T.Value(T.Participant == participant & T.Condition == conds{ic}));
    end
    v = mean(vals);
end


function Y = pooled(Yc, isGroup)
    % (nPat, nPts) : moyenne des conditions du groupe pour chaque participant
    Y = mean(cat(3, Yc{isGroup}), 3);
end


function v = signedRankValues(d)
    % Rangs signes (ex aequo : rang moyen), differences nulles retirees
    d = d(d ~= 0);
    a = abs(d(:));
    r = zeros(size(a));
    for k = 1:numel(a)
        r(k) = sum(a < a(k)) + (sum(a == a(k)) + 1) / 2;
    end
    v = sign(d(:)) .* r;
end


function p = signFlipP(v)
    % p bilateral exact : toutes les inversions de signe. La somme des carres
    % restant fixe, |somme| est equivalent a |t| pour le test apparie.
    v = v(:);
    n = numel(v);
    signs = 2 * (dec2bin(0:2^n - 1, n) - '0') - 1;
    s = abs(signs * abs(v));
    p = mean(s >= abs(sum(v)) - 1e-12);
end


function res = compareCurves(yO, yR, grid, alpha)
    % SPM1D apparie bilateral, non parametrique (toutes les permutations) et
    % parametrique. Bornes des clusters dans l'unite de grid.
    keep = all(~isnan([yO yR]), 2);
    yO = yO(keep, :); yR = yR(keep, :);
    res = struct('label', '', 'n', sum(keep), 'grid', grid, 'yO', yO, 'yR', yR, 'alpha', alpha, ...
                 'clustersNP', [], 'clustersP', [], 'pCurve', 1, 'pHolm', NaN);
    ti = spm1d.stats.nonparam.ttest_paired(yO, yR).inference(alpha, 'two_tailed', true, 'interp', true);
    res.clustersNP = clusterTable(ti.clusters, grid, yO, yR);
    tp = spm1d.stats.ttest_paired(yO, yR).inference(alpha, 'two_tailed', true, 'interp', true);
    res.clustersP = clusterTable(tp.clusters, grid, yO, yR);
    if ~isempty(res.clustersNP), res.pCurve = min(res.clustersNP(:, 3)); end
end


function T = clusterTable(clusters, grid, yO, yR)
    % [debut fin p moyO etO moyR etR] par cluster ; endpoints spm1d 0-based
    T = zeros(numel(clusters), 7);
    Q = numel(grid);
    for k = 1:numel(clusters)
        ep = clusters{k}.endpoints(:)';
        idx = max(1, floor(ep(1)) + 1):min(Q, ceil(ep(2)) + 1);
        mO = mean(yO(:, idx), 2); mR = mean(yR(:, idx), 2);
        T(k, :) = [grid(1) + ep * (grid(2) - grid(1)), clusters{k}.P, mean(mO), std(mO), mean(mR), std(mR)];
    end
end


function C = holmOnCurves(C, alpha)
    % Holm sur la famille, a partir du plus petit p de cluster de chaque courbe
    pAdj = holmAdjust([C.pCurve], alpha);
    for k = 1:numel(C), C(k).pHolm = pAdj(k); end
end


function printCurve(c)
    fprintf('%-34s N = %d', c.label, c.n);
    if ~isnan(c.pHolm) && ~isempty(c.clustersNP), fprintf(' ; p Holm courbe = %s', fmtP(c.pHolm)); end
    fprintf('\n');
    printClusters('non parametrique', c.clustersNP);
    printClusters('parametrique', c.clustersP);
end


function printClusters(name, T)
    if isempty(T), fprintf('    %-17s : n.s.\n', name); return; end
    for k = 1:size(T, 1)
        fprintf('    %-17s : %.1f-%.1f ; p = %s ; OCP %.1f ± %.1f vs ref %.1f ± %.1f\n', name, T(k, 1), T(k, 2), ...
                fmtP(T(k, 3)), T(k, 4), T(k, 5), T(k, 6), T(k, 7));
    end
end


function s = fmtP(p)
    if isnan(p), s = '-'; elseif p < 0.001, s = '<0.001'; else, s = sprintf('%.3f', p); end
end
