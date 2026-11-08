% =========================================================================
% nested_comparison.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : November 2026
% -------------------------------------------------------------------------
% Description : Hypothesis tests of the article, rehabilitation-like pattern
%               (Rehab) vs the mean of the four optimised patterns (OCP: Min
%               PW, Min force, Min stress, Min fatigue).
%                 - H4: for each scapulothoracic angle, absolute deviation
%                   from No FES at each degree of thoracohumeral elevation
%                   (20 to 90 deg); the deviation of Rehab is compared with
%                   the mean of the four OCP deviations.
%                 - EMG (exploratory): for each muscle, absolute deviation of
%                   the normalised envelope from No FES, compared as for H4,
%                   and direct comparison of the envelopes, Rehab vs the mean
%                   of the four OCP.
%                 - Sensitivity: the deviation tests repeated on all
%                   participants, over the elevation range common to all.
%                 - Thoracohumeral elevation (no hypothesis): curve over the
%                   cycle, Rehab vs the mean of the four OCP; discrete
%                   parameters (peak elevation, peak timing, mean plane of
%                   elevation), three contrasts: Rehab vs OCP, Rehab vs No
%                   FES and OCP vs No FES.
%               Statistics: paired, two-tailed tests with all sign
%               permutations: SPM1D t-test for curves, t-test for discrete
%               values. Holm-Bonferroni correction across the 3
%               scapulothoracic angles, across the 4 muscles and across the
%               3 contrasts of each discrete parameter. Each curve gets one
%               p-value (maximum |t| over the curve, permutation
%               distribution), and its clusters are computed at its Holm
%               threshold.
%               Article Figure 5: scapulothoracic angles and their deviation
%               from No FES (H4), EMG and its deviation from No FES, with the
%               Rehab vs OCP bars (thoracohumeral results reported in the
%               text only).
% -------------------------------------------------------------------------
% Parameters  : OCP_CONDS, REF_COND, NOFES_COND, ALPHA
%               EXPORT_FIGURE : high-resolution export (PNG 600 dpi + PDF)
% Outputs     : Console tables, cache_nested_comparison.mat, 1 figure
%               (plotScapulaEmgHypothesisFigure.m),
%               Figures/Figure_5_scapulothoracic_EMG.png/.pdf
% -------------------------------------------------------------------------
% Dependencies: cache_humerothoracic_all_comp.mat,
%               cache_scapulothoracic_all_comp.mat, cache_emg_all_comp.mat,
%               cache_scapulohumeral_rhythm_all_comp.mat,
%               helpers/crossingTimes.m,
%               cache_emg_elevation_all_comp.mat, helpers/holmAdjust.m,
%               helpers/conditionColors.m, helpers/exportFigure.m,
%               plotting/plotScapulaEmgHypothesisFigure.m, spm1dmatlab-master/
% References  : Holm S (1979), Scand J Stat 6:65-70
%               Pataky TC (2010), J Biomech 43:1976-1982
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' nested_comparison.m');
disp('=========================================');

HERE = fileparts(fileparts(mfilename('fullpath')));
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end
addpath(fullfile(HERE, 'helpers'));
addpath(fullfile(HERE, 'plotting'));

% -------------------------------------------------------------------------
% PARAMETRES
% -------------------------------------------------------------------------
OCP_CONDS  = {'Min_pulse_width','Min_force','Min_stress','Min_fatigue'};
REF_COND   = 'Rehab';
NOFES_COND = 'No FES';
ALPHA      = 0.05;
MAX_EXTRAP_DEG = 2.5;   % prolongation constante max sous le debut de montee (deg), comme les scripts 4 et 6
EXPORT_FIGURE = true;   % export haute resolution (helpers/exportFigure.m)
MUSCLE_DISPLAY = containers.Map({'TRAPS','TRAPM','TRAPI','SERRA'}, ...
    {'Upper trapezius', 'Middle trapezius', 'Lower trapezius', 'Serratus anterior'});
DISC_PARAMS = {'peakElev', 'peakTime', 'planeMean2090'};
DISC_LABELS = {'Peak elevation (deg)', 'Peak timing (% cycle)', 'Mean plane of elevation (deg)'};
CACHE_FILE = fullfile(dataDir(), 'cache_nested_comparison.mat');

% -------------------------------------------------------------------------
% CHARGEMENT DES CACHES
% -------------------------------------------------------------------------
H  = load(fullfile(dataDir(), 'cache_humerothoracic_all_comp.mat'), 'patientMeans', 'x', 'disc', 'CONDITIONS_ORDERED', ...
          'COND_LABELS', 'DOF_LABELS', 'PATIENT_IDS');
RH = load(fullfile(dataDir(), 'cache_scapulohumeral_rhythm_all_comp.mat'), 'joints', 'ELEV_GRID', 'CONDITIONS_ORDERED');
E  = load(fullfile(dataDir(), 'cache_emg_elevation_all_comp.mat'), 'elevProf', 'ELEV_GRID', 'EMG_LABELS', 'CONDITIONS_ORDERED');
if ~isequal(RH.ELEV_GRID, E.ELEV_GRID) || ~isequal(RH.CONDITIONS_ORDERED, E.CONDITIONS_ORDERED) ...
        || ~isequal(H.CONDITIONS_ORDERED, RH.CONDITIONS_ORDERED)
    error('Grille d''elevation ou conditions differentes entre les caches.');
end
CONDS = RH.CONDITIONS_ORDERED;
GRID  = RH.ELEV_GRID;
iRef  = strcmp(CONDS, REF_COND);
iNo   = strcmp(CONDS, NOFES_COND);
isOCP = ismember(CONDS, OCP_CONDS);

% -------------------------------------------------------------------------
% H4 : ecart absolu a No FES des angles scapulothoraciques
% -------------------------------------------------------------------------
JST = RH.joints{cellfun(@(j) strcmp(j.name, 'Scapulothoracic'), RH.joints)};
nDOF = numel(JST.DOF_LABELS);
h4 = cell(1, nDOF); rawST = cell(1, nDOF);
for id = 1:nDOF
    Y = cell(1, numel(CONDS));   % (nPat, nGrid) par condition
    for ic = 1:numel(CONDS)
        Rs = JST.rhythmMeans.(matlab.lang.makeValidName(CONDS{ic}));
        Y{ic} = cell2mat(cellfun(@(r) r(id, :), Rs(:), 'UniformOutput', false));
    end
    devRef = abs(Y{iRef} - Y{iNo});
    devOCP = mean(abs(cat(3, Y{isOCP}) - Y{iNo}), 3);          % ecart de chaque OCP, puis moyenne
    sgnRef = Y{iRef} - Y{iNo};
    sgnOCP = mean(cat(3, Y{isOCP}), 3) - Y{iNo};
    h4{id} = curveTest(devRef, devOCP, sgnRef, sgnOCP, GRID, JST.DOF_LABELS{id});
    rawST{id} = Y;
end
h4 = holmCurves([h4{:}], ALPHA);

% -------------------------------------------------------------------------
% EMG (exploratoire) : ecart absolu a No FES de l'enveloppe normalisee,
% comme pour H4
% -------------------------------------------------------------------------
nMus = numel(E.EMG_LABELS);
emgDev = cell(1, nMus);
for jm = 1:nMus
    P = E.elevProf{jm};
    devRef = abs(P{iRef} - P{iNo}); devOCP = mean(abs(cat(3, P{isOCP}) - P{iNo}), 3);
    emgDev{jm} = curveTest(devRef, devOCP, P{iRef} - P{iNo}, mean(cat(3, P{isOCP}), 3) - P{iNo}, GRID, ...
                           MUSCLE_DISPLAY(E.EMG_LABELS{jm}));
end
emgDev = holmCurves([emgDev{:}], ALPHA);

% EMG (exploratoire) : comparaison directe de l'enveloppe normalisee,
% Rehab contre moyenne OCP
emg = cell(1, nMus);
for jm = 1:nMus
    P = E.elevProf{jm};
    yRef = P{iRef}; yOCP = mean(cat(3, P{isOCP}), 3);
    emg{jm} = curveTest(yRef, yOCP, yRef - P{iNo}, yOCP - P{iNo}, GRID, MUSCLE_DISPLAY(E.EMG_LABELS{jm}));
end
emg = holmCurves([emg{:}], ALPHA);

% -------------------------------------------------------------------------
% SENSIBILITE : memes tests sur tous les participants, sur la plage
% d'elevation commune (bornes hautes inchangees, debut plus eleve)
% -------------------------------------------------------------------------
SC = load(fullfile(dataDir(), 'cache_scapulothoracic_all_comp.mat'), 'patientMeans', 'x');
EB = load(fullfile(dataDir(), 'cache_emg_all_comp.mat'), 'patientBlocks');
usedConds = CONDS(iNo | iRef | isOCP);
nPatAll = numel(H.PATIENT_IDS);
sensStart = NaN;
for g0 = GRID(1):GRID(end)   % premier debut de plage complet pour tous les participants
    ok = true;
    for ic = 1:numel(usedConds)
        pm = H.patientMeans.(matlab.lang.makeValidName(usedConds{ic}));
        for ip = 1:nPatAll
            ok = ok && ~any(isnan(crossingTimes(pm{ip}, H.x, g0:GRID(end), MAX_EXTRAP_DEG)));
        end
    end
    if ok, sensStart = g0; break; end
end
SENS_GRID = sensStart:GRID(end);
sensT = NaN(nPatAll, numel(SENS_GRID), numel(CONDS));   % instants de lecture (% cycle)
sensAng = NaN(nPatAll, numel(SENS_GRID), numel(CONDS), nDOF);
sensEmg = NaN(nPatAll, numel(SENS_GRID), numel(CONDS), nMus);
for ic = find(iNo | iRef | isOCP)
    fld = matlab.lang.makeValidName(CONDS{ic});
    for ip = 1:nPatAll
        sensT(ip, :, ic) = crossingTimes(H.patientMeans.(fld){ip}, H.x, SENS_GRID, MAX_EXTRAP_DEG);
        for id = 1:nDOF
            sensAng(ip, :, ic, id) = interp1(SC.x, SC.patientMeans.(fld){ip}(id, :), sensT(ip, :, ic), 'linear');
        end
        for jm = 1:nMus
            B = EB.patientBlocks.(fld).(E.EMG_LABELS{jm}){ip};
            if isempty(B), continue; end
            sensEmg(ip, :, ic, jm) = interp1(H.x, mean(100 * B ./ max(B, [], 2), 1), sensT(ip, :, ic), 'linear');
        end
    end
end
sensDev = @(A) deal(abs(A(:, :, iRef) - A(:, :, iNo)), mean(abs(A(:, :, isOCP) - A(:, :, iNo)), 3));
sensH4 = cell(1, nDOF);
for id = 1:nDOF
    A = sensAng(:, :, :, id);
    [dR, dO] = sensDev(A);
    sensH4{id} = curveTest(dR, dO, A(:, :, iRef) - A(:, :, iNo), mean(A(:, :, isOCP), 3) - A(:, :, iNo), SENS_GRID, JST.DOF_LABELS{id});
end
sensH4 = holmCurves([sensH4{:}], ALPHA);
sensEMG = cell(1, nMus);
for jm = 1:nMus
    A = sensEmg(:, :, :, jm);
    [dR, dO] = sensDev(A);
    sensEMG{jm} = curveTest(dR, dO, A(:, :, iRef) - A(:, :, iNo), mean(A(:, :, isOCP), 3) - A(:, :, iNo), SENS_GRID, ...
                            MUSCLE_DISPLAY(E.EMG_LABELS{jm}));
end
sensEMG = holmCurves([sensEMG{:}], ALPHA);
sensEMGdirect = cell(1, nMus);
for jm = 1:nMus
    A = sensEmg(:, :, :, jm);
    yRef = A(:, :, iRef); yOCP = mean(A(:, :, isOCP), 3);
    sensEMGdirect{jm} = curveTest(yRef, yOCP, yRef - A(:, :, iNo), yOCP - A(:, :, iNo), SENS_GRID, MUSCLE_DISPLAY(E.EMG_LABELS{jm}));
end
sensEMGdirect = holmCurves([sensEMGdirect{:}], ALPHA);

% -------------------------------------------------------------------------
% ELEVATION THORACOHUMERALE : courbe et parametres discrets
% -------------------------------------------------------------------------
Yht = cell(1, numel(CONDS));
for ic = 1:numel(CONDS)
    Yht{ic} = cat(1, H.patientMeans.(matlab.lang.makeValidName(CONDS{ic})){:});   % (nPat, 101)
end
yRef = Yht{iRef}; yOCP = mean(cat(3, Yht{isOCP}), 3);
htCurve = curveTest(yRef, yOCP, yRef - Yht{iNo}, yOCP - Yht{iNo}, H.x, 'Thoracohumeral elevation');
htCurve = holmCurves(htCurve, ALPHA);   % test unique : seuil = ALPHA

% Parametres discrets : 3 contrastes par parametre, Holm sur ces 3 contrastes
CONTRASTS = {'Rehab vs OCP', 'Rehab vs No FES', 'OCP vs No FES'};
htDisc = struct('param', DISC_PARAMS, 'label', DISC_LABELS, 'nofes', [], 'ref', [], 'ocp', [], ...
                'contrasts', {CONTRASTS}, 'p', NaN(1, 3), 'pHolm', NaN(1, 3));
for k = 1:numel(DISC_PARAMS)
    Yd = H.disc.(DISC_PARAMS{k});
    keep = all(~isnan(Yd(:, iNo | iRef | isOCP)), 2);
    r = htDisc(k);
    r.nofes = Yd(keep, iNo); r.ref = Yd(keep, iRef); r.ocp = mean(Yd(keep, isOCP), 2);
    r.p = [signFlipP(r.ref - r.ocp), signFlipP(r.ref - r.nofes), signFlipP(r.ocp - r.nofes)];
    r.pHolm = holmAdjust(r.p, ALPHA);
    htDisc(k) = r;
end

save(CACHE_FILE, 'h4', 'emgDev', 'emg', 'sensH4', 'sensEMG', 'sensEMGdirect', 'SENS_GRID', 'htCurve', 'htDisc', 'OCP_CONDS', 'REF_COND', 'NOFES_COND', 'ALPHA', 'GRID');
fprintf('Cache sauvegarde : %s\n', CACHE_FILE);

% =========================================================================
% CONSOLE
% =========================================================================
fprintf('\n=== H4 : ecart absolu a No FES, Rehab contre moyenne des 4 OCP (Holm sur %d angles) ===\n', nDOF);
fprintf('Valeurs dans chaque zone : ecart absolu (deg), puis difference signee moyenne avec No FES (deg)\n');
for id = 1:nDOF, printCurve(h4(id), 'deg', 'deg'); end
fprintf('\n=== EMG (exploratoire) : ecart absolu a No FES, Rehab contre moyenne des 4 OCP (Holm sur %d muscles) ===\n', nMus);
for jm = 1:nMus, printCurve(emgDev(jm), 'deg', '%'); end
fprintf('\n=== EMG (exploratoire) : comparaison directe, Rehab contre moyenne des 4 OCP, %% du pic (Holm sur %d muscles) ===\n', nMus);
fprintf('Valeurs dans chaque zone : enveloppe (%% du pic), puis difference signee moyenne avec No FES (%% du pic)\n');
for jm = 1:nMus, printCurve(emg(jm), 'deg', '%'); end

fprintf('\n=== Sensibilite : memes tests sur tous les participants, de %d a %d deg ===\n', SENS_GRID(1), SENS_GRID(end));
for id = 1:nDOF, printCurve(sensH4(id), 'deg', 'deg'); end
for jm = 1:nMus, printCurve(sensEMG(jm), 'deg', '%'); end
fprintf('EMG, comparaison directe :\n');
for jm = 1:nMus, printCurve(sensEMGdirect(jm), 'deg', '%'); end

fprintf('\n=== Elevation thoracohumerale : Rehab contre moyenne des 4 OCP ===\n');
fprintf('Courbe (test unique). Valeurs dans chaque zone : elevation (deg), puis difference signee avec No FES (deg)\n');
printCurve(htCurve, '%', 'deg');
fprintf('\n=== Elevation thoracohumerale : parametres discrets (Holm sur les 3 contrastes de chaque parametre) ===\n');
for k = 1:numel(htDisc)
    r = htDisc(k);
    fprintf('%s : No FES %.1f ± %.1f ; Rehab %.1f ± %.1f ; OCP %.1f ± %.1f\n', r.label, mean(r.nofes), std(r.nofes), ...
            mean(r.ref), std(r.ref), mean(r.ocp), std(r.ocp));
    dd = {r.ref - r.ocp, r.ref - r.nofes, r.ocp - r.nofes};
    for q = 1:3
        fprintf('    %-16s diff %+.1f ± %.1f (%d/%d > 0) ; p = %s ; p Holm = %s\n', r.contrasts{q}, mean(dd{q}), std(dd{q}), ...
                sum(dd{q} > 0), numel(dd{q}), fmtP(r.p(q)), fmtP(r.pHolm(q)));
    end
end

% =========================================================================
% FIGURE DE L'ARTICLE : angles scapulothoraciques et ecart a No FES (H4),
% EMG et ecart a No FES ; barres du contraste Rehab / OCP (moitie haute :
% Rehab, moitie basse : couleur de la bande OCP)
% =========================================================================
COLORS = conditionColors(CONDS);
colRef = COLORS(iRef, :); colOCP = COLORS(strcmp(CONDS, 'Min_stress'), :);
barsOf = @(c) c.clusters(:, 1:2) .* c.sig;   % zones significatives, [] sinon
S6 = struct('grid', GRID, 'conds', {CONDS}, 'condLabels', {H.COND_LABELS}, 'colors', COLORS, ...
            'showConds', {[{NOFES_COND, REF_COND}, OCP_CONDS]}, 'colRef', colRef, 'colOCP', colOCP, ...
            'dofLabels', {JST.DOF_LABELS}, 'raw', {rawST}, ...
            'devRef', {arrayfun(@(c) c.yA, h4, 'UniformOutput', false)}, ...
            'devOCP', {arrayfun(@(c) c.yB, h4, 'UniformOutput', false)}, ...
            'barsDev', {arrayfun(barsOf, h4, 'UniformOutput', false)}, ...
            'muscleNames', {arrayfun(@(c) c.label, emgDev, 'UniformOutput', false)}, 'emg', {E.elevProf}, ...
            'barsEMG', {arrayfun(barsOf, emg, 'UniformOutput', false)}, ...
            'emgDevRef', {arrayfun(@(c) c.yA, emgDev, 'UniformOutput', false)}, ...
            'emgDevOCP', {arrayfun(@(c) c.yB, emgDev, 'UniformOutput', false)}, ...
            'barsEmgDev', {arrayfun(barsOf, emgDev, 'UniformOutput', false)});
plotScapulaEmgHypothesisFigure(S6);
if EXPORT_FIGURE, exportFigure(gcf, 'Figure_5_scapulothoracic_EMG', [], [18.75 18.75]); end   % 1800 x 1800 px

disp(' '); disp('Termine.');


% =========================================================================
% FONCTIONS LOCALES
% =========================================================================

function c = curveTest(yA, yB, sA, sB, grid, label)
    % yA, yB : courbes comparees (nPat, nGrid) ; sA, sB : differences signees
    % avec No FES, pour la description. Courbes completes uniquement.
    keep = all(~isnan([yA yB]), 2);
    c = struct('label', label, 'grid', grid, 'yA', yA(keep, :), 'yB', yB(keep, :), ...
               'sA', sA(keep, :), 'sB', sB(keep, :), 'pTest', NaN, 'pHolm', NaN, ...
               'alphaHolm', NaN, 'sig', false, 'clusters', zeros(0, 7));
    c.pTest = maxTPermutation(c.yA - c.yB);
end


function p = maxTPermutation(d)
    % p bilateral du t maximal sur la courbe, toutes les inversions de signe
    n = size(d, 1);
    signs = 2 * (dec2bin(0:2^n - 1, n) - '0') - 1;
    tObs = max(abs(tField(d)));
    tMax = zeros(size(signs, 1), 1);
    for k = 1:size(signs, 1)
        tMax(k) = max(abs(tField(d .* signs(k, :)')));
    end
    p = mean(tMax >= tObs - 1e-12);
end


function p = signFlipP(d)
    % p bilateral exact d'un t-test apparie par permutation (toutes les
    % inversions de signe). La somme des carres restant fixe, |somme| est
    % equivalent a |t|.
    d = d(:);
    n = numel(d);
    signs = 2 * (dec2bin(0:2^n - 1, n) - '0') - 1;
    p = mean(abs(signs * abs(d)) >= abs(sum(d)) - 1e-12);
end


function t = tField(d)
    t = mean(d, 1) ./ (std(d, 0, 1) / sqrt(size(d, 1)));
end


function C = holmCurves(C, alpha)
    % Holm sur la famille de courbes (p du t maximal), puis zones de chaque
    % courbe calculees a son seuil de Holm
    m = numel(C);
    pAdj = holmAdjust([C.pTest], alpha);
    [~, ord] = sort([C.pTest]);
    stopped = false;
    for r = 1:m
        k = ord(r);
        thr = alpha / (m - r + 1);
        stopped = stopped || C(k).pTest >= thr;
        C(k).pHolm = pAdj(k);
        C(k).alphaHolm = thr;
        if stopped, continue; end
        C(k).sig = true;
        ti = spm1d.stats.nonparam.ttest_paired(C(k).yA, C(k).yB).inference(thr, 'two_tailed', true, 'interp', true);
        C(k).clusters = clusterTable(ti.clusters, C(k));
    end
end


function T = clusterTable(clusters, c)
    % [debut fin moyA etA moyB etB] dans l'unite de la grille, puis
    % differences signees moyennes avec No FES [sA sB] dans la zone
    T = zeros(numel(clusters), 8);
    Q = numel(c.grid);
    for k = 1:numel(clusters)
        ep = clusters{k}.endpoints(:)';
        idx = max(1, floor(ep(1)) + 1):min(Q, ceil(ep(2)) + 1);
        a = mean(c.yA(:, idx), 2); b = mean(c.yB(:, idx), 2);
        T(k, :) = [c.grid(1) + ep * (c.grid(2) - c.grid(1)), mean(a), std(a), mean(b), std(b), ...
                   mean(mean(c.sA(:, idx), 2)), mean(mean(c.sB(:, idx), 2))];
    end
end


function printCurve(c, xUnit, unit)
    % xUnit : unite du domaine ('deg' d'elevation ou '%' du cycle) ; unit :
    % unite des valeurs
    fprintf('%-34s p = %s ; p Holm = %s', c.label, fmtP(c.pTest), fmtP(c.pHolm));
    if ~c.sig, fprintf(' ; n.s.\n'); return; end
    fprintf('\n');
    for k = 1:size(c.clusters, 1)
        T = c.clusters(k, :);
        fprintf('    %.1f-%.1f %s : Rehab %.1f ± %.1f vs OCP %.1f ± %.1f %s ; signe Rehab %+.1f, OCP %+.1f\n', ...
                T(1), T(2), xUnit, T(3), T(4), T(5), T(6), unit, T(7), T(8));
    end
end


function s = fmtP(p)
    if isnan(p), s = '-'; elseif p < 0.001, s = '<0.001'; else, s = sprintf('%.3f', p); end
end
