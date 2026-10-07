% =========================================================================
% extract_emg_elevation_all_comp.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Scapular muscle activity as a function of humerothoracic
%               elevation, and article Figure 2 (scapulothoracic angles on the
%               first row, EMG on the second). Uses the caches of the
%               humerothoracic, scapulohumeral rhythm and EMG scripts. Each
%               EMG envelope is normalised to the peak of its trial and
%               averaged per participant, then read at each humerothoracic
%               elevation between 20 and 90 deg (1 deg steps) during the
%               ascending phase, with the same rules as the scapulothoracic
%               angles. SPM1D comparison of the conditions with elevation
%               as the domain, for each muscle.
%               Statistics: non-parametric repeated-measures ANOVA across the
%               7 conditions (10 000 permutations), then, if significant,
%               paired t-tests on the 21 pairs of conditions with
%               Holm-Bonferroni correction (alpha = 0.05).
% -------------------------------------------------------------------------
% Parameters  : ELEV_GRID = 20:1:90 deg, MAX_EXTRAP_DEG = 2.5 deg
%               ALPHA_ANOVA, ALPHA_FWER, N_ITER, FORCE_RECOMPUTE
% Outputs     : Console tables, cache_emg_elevation_all_comp.mat,
%               1 figure (plotRhythmEmgFigure.m)
% -------------------------------------------------------------------------
% Dependencies: cache_humerothoracic_all_comp.mat, cache_emg_all_comp.mat,
%               cache_scapulohumeral_rhythm_all_comp.mat,
%               helpers/crossingTimes.m, helpers/holmAlphaSPM1D.m,
%               plotting/plotRhythmEmgFigure.m, spm1dmatlab-master/
% References  : Burden A (2010), J Electromyogr Kinesiol 20:1023-1035
%               Pataky TC (2010), J Biomech 43:1976-1982
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' extract_emg_elevation_all_comp.m');
disp('=========================================');

HERE = fileparts(fileparts(mfilename('fullpath')));
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end
addpath(fullfile(HERE, 'plotting'));
addpath(fullfile(HERE, 'helpers'));

% -------------------------------------------------------------------------
% PARAMETRES
% -------------------------------------------------------------------------
% Meme grille et memes regles que extract_scapulohumeral_rhythm_all_comp.m
ELEV_GRID      = 20:1:90;   % deg d'elevation humerothoracique
MAX_EXTRAP_DEG = 2.5;       % prolongation constante max sous le debut de montee (deg)

ALPHA_ANOVA = 0.05;
ALPHA_FWER  = 0.05;
N_ITER      = 10000;
FORCE_RECOMPUTE = false;
CACHE_FILE = fullfile(dataDir(), 'cache_emg_elevation_all_comp.mat');

MUSCLE_DISPLAY = containers.Map({'TRAPS','TRAPM','TRAPI','SERRA'}, ...
    {'Upper trapezius', 'Middle trapezius', 'Lower trapezius', 'Serratus anterior'});
SHOW_ELEV = [30 50 70 90];   % elevations auxquelles les valeurs moyennes sont affichees

% -------------------------------------------------------------------------
% CHARGEMENT DES CACHES
% -------------------------------------------------------------------------
H = load(fullfile(dataDir(), 'cache_humerothoracic_all_comp.mat'), 'patientMeans', 'x', ...
         'PATIENT_IDS', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS');
E = load(fullfile(dataDir(), 'cache_emg_all_comp.mat'), 'patientBlocks', 'EMG_LABELS', ...
         'PATIENT_IDS', 'CONDITIONS_ORDERED');
if ~isequal(H.PATIENT_IDS, E.PATIENT_IDS) || ~isequal(H.CONDITIONS_ORDERED, E.CONDITIONS_ORDERED)
    error('Patients ou conditions differents entre les caches cinematique et EMG.');
end
CONDITIONS_ORDERED = H.CONDITIONS_ORDERED;
COND_LABELS = H.COND_LABELS;
nCond = numel(CONDITIONS_ORDERED);
nPat  = numel(H.PATIENT_IDS);
MUS   = E.EMG_LABELS;
nMus  = numel(MUS);

% -------------------------------------------------------------------------
% ENVELOPPES NORMALISEES AU PIC EN FONCTION DE L'ELEVATION HT (montee)
% elevProf{jm}{ic} = (nPat, nGrid) ; memes regles que les angles
% scapulothoraciques (courbes completes sur la plage)
% -------------------------------------------------------------------------
tE = cell(nPat, nCond);
keepPat = true(nPat, 1);
for ic = 1:nCond
    for ip = 1:nPat
        tE{ip, ic} = crossingTimes(H.patientMeans.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic})){ip}, ...
                                   H.x, ELEV_GRID, MAX_EXTRAP_DEG);
        keepPat(ip) = keepPat(ip) && ~any(isnan(tE{ip, ic}));
    end
end
elevProf = cell(1, nMus);
for jm = 1:nMus
    elevProf{jm} = cell(1, nCond);
    for ic = 1:nCond
        Pc = peakNormalisedPatients(E.patientBlocks, MUS{jm}, CONDITIONS_ORDERED{ic}, nPat, numel(H.x));
        R = NaN(nPat, numel(ELEV_GRID));
        for ip = find(keepPat)'
            R(ip, :) = interp1(H.x, Pc(ip, :), tE{ip, ic}, 'linear');
        end
        elevProf{jm}{ic} = R;
    end
end
excluded = H.PATIENT_IDS(~keepPat);
fprintf('\nEMG en fonction de l''elevation HT (%d-%d deg, montee) : N = %d\n', ...
        ELEV_GRID(1), ELEV_GRID(end), sum(keepPat));

% -------------------------------------------------------------------------
% SPM1D : domaine = elevation HT (tous les muscles)
% -------------------------------------------------------------------------
ALL_PAIRS = nchoosek(1:nCond, 2);      % meme ordre que les autres scripts
cacheValid = false;
if isfile(CACHE_FILE) && ~FORCE_RECOMPUTE
    S_check = load(CACHE_FILE, 'ELEV_GRID', 'MAX_EXTRAP_DEG');
    cacheValid = isequal(S_check.ELEV_GRID, ELEV_GRID) && isequal(S_check.MAX_EXTRAP_DEG, MAX_EXTRAP_DEG);
end
if cacheValid
    fprintf('Cache trouve : %s\n-> pas de recalcul\n', CACHE_FILE);
    load(CACHE_FILE, 'spmPeak');
else
    rng(0);
    spmPeak = struct('muscle', MUS, 'anovaSig', false, 'anovaClusters', [], ...
                     'pairSig', false(size(ALL_PAIRS,1),1), 'pairClusters', {cell(size(ALL_PAIRS,1),1)}, ...
                     'pairP', NaN(size(ALL_PAIRS,1),1), 'pairSign', zeros(size(ALL_PAIRS,1),1));
    for jm = 1:nMus
        spmPeak(jm) = spmAllPairs(elevProf{jm}, ELEV_GRID, ALL_PAIRS, ALPHA_ANOVA, ALPHA_FWER, N_ITER, spmPeak(jm));
    end
    PATIENT_IDS = H.PATIENT_IDS; EMG_LABELS = MUS;
    save(CACHE_FILE, 'spmPeak', 'elevProf', 'excluded', 'ELEV_GRID', 'MAX_EXTRAP_DEG', 'ALL_PAIRS', ...
         'ALPHA_ANOVA', 'ALPHA_FWER', 'N_ITER', 'CONDITIONS_ORDERED', 'COND_LABELS', 'PATIENT_IDS', 'EMG_LABELS');
    fprintf('Cache sauvegarde : %s\n', CACHE_FILE);
end
printSpmPeak(spmPeak, ALL_PAIRS, COND_LABELS, MUSCLE_DISPLAY);

% -------------------------------------------------------------------------
% CONSOLE : valeurs moyennes par condition a quelques elevations
% -------------------------------------------------------------------------
emgMean = cell(1, nMus); emgSD = cell(1, nMus);
for jm = 1:nMus
    emgMean{jm} = cell2mat(cellfun(@(y) mean(y, 1, 'omitnan'), elevProf{jm}(:), 'UniformOutput', false));
    emgSD{jm}   = cell2mat(cellfun(@(y) std(y, 0, 1, 'omitnan'), elevProf{jm}(:), 'UniformOutput', false));
    fprintf('\n%s (%% du pic, moyenne ± ET)\n    %-12s', MUSCLE_DISPLAY(MUS{jm}), 'Condition');
    fprintf('  %11d deg', SHOW_ELEV); fprintf('\n');
    iShow = ismember(ELEV_GRID, SHOW_ELEV);
    for ic = 1:nCond
        fprintf('    %-12s', COND_LABELS{ic});
        fprintf('  %6.1f ± %5.1f', [emgMean{jm}(ic, iShow); emgSD{jm}(ic, iShow)]);
        fprintf('\n');
    end
end

% -------------------------------------------------------------------------
% FIGURE
% -------------------------------------------------------------------------
% Figure 2 de l'article : angles scapulothoraciques (rangee 1, cache du
% rythme scapulohumeral) et EMG (rangee 2)
K = struct('x', ELEV_GRID, 'muscleNames', {cellfun(@(m) MUSCLE_DISPLAY(m), MUS, 'UniformOutput', false)}, ...
           'emgMean', {emgMean}, 'emgSD', {emgSD}, 'spm', spmPeak, 'ALL_PAIRS', ALL_PAIRS);
RH = load(fullfile(dataDir(), 'cache_scapulohumeral_rhythm_all_comp.mat'), 'joints', 'ELEV_GRID', ...
          'CONDITIONS_ORDERED', 'ALL_PAIRS');
if ~isequal(RH.ELEV_GRID, ELEV_GRID) || ~isequal(RH.CONDITIONS_ORDERED, CONDITIONS_ORDERED)
    error('Grille d''elevation ou conditions differentes entre les caches rythme et EMG.');
end
JST = RH.joints{cellfun(@(j) strcmp(j.name, 'Scapulothoracic'), RH.joints)};
plotRhythmEmgFigure(JST, ELEV_GRID, CONDITIONS_ORDERED, COND_LABELS, H.COLORS, RH.ALL_PAIRS, K);

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


function st = spmAllPairs(Yc, grid, ALL_PAIRS, alphaA, alphaF, nIter, st)
    % ANOVA RM non parametrique (7 conditions) puis, si significative, SPM{t}
    % apparie sur toutes les paires, Holm-Bonferroni (helpers/holmAlphaSPM1D.m).
    % Bornes des clusters dans l'unite de grid (endpoints spm1d 0-based :
    % grid(1) + ep * pas).
    nCond = numel(Yc);
    Q = numel(grid);
    toUnit = @(ep) grid(1) + ep * (grid(2) - grid(1));
    keep = all(cell2mat(cellfun(@(y) all(~isnan(y), 2), Yc, 'UniformOutput', false)), 2);   % listwise
    Y = cellfun(@(y) y(keep, :), Yc, 'UniformOutput', false);
    n = sum(keep);
    A  = kron((1:nCond)', ones(n, 1));
    S  = repmat((1:n)', nCond, 1);
    Fi = spm1d.stats.nonparam.anova1rm(cat(1, Y{:}), A, S).inference(alphaA, 'iterations', nIter, 'interp', true);
    st.anovaSig = ~isempty(Fi.clusters);
    st.anovaClusters = clusterTable(Fi.clusters, toUnit);
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
        st.pairClusters{kp} = clusterTable(ti.clusters, toUnit);
        if st.pairSig(kp)   % signe de la difference B - A dans le 1er cluster
            ep = ti.clusters{1}.endpoints;
            idx = max(1, floor(ep(1)) + 1):min(Q, ceil(ep(2)) + 1);
            st.pairSign(kp) = sign(mean(mean(Y{ALL_PAIRS(kp,2)}(:, idx) - Y{ALL_PAIRS(kp,1)}(:, idx))));
        end
    end
end


function T = clusterTable(clusters, toUnit)
    % [debut fin p] par cluster, bornes dans l'unite du domaine
    T = zeros(numel(clusters), 3);
    for k = 1:numel(clusters)
        T(k, :) = [toUnit(clusters{k}.endpoints(:)') clusters{k}.P];
    end
end


function printSpmPeak(spmPeak, ALL_PAIRS, COND_LABELS, MUSCLE_DISPLAY)
    fprintf('\n=== SPM1D sur les enveloppes normalisees au pic (%% du pic), domaine = elevation HT (deg) ===\n');
    for jm = 1:numel(spmPeak)
        st = spmPeak(jm);
        fprintf('%-20s ANOVA : ', MUSCLE_DISPLAY(st.muscle));
        if ~st.anovaSig, fprintf('n.s.\n'); continue; end
        fprintf('%s\n', strjoin(arrayfun(@(k) sprintf('%.1f-%.1f deg (p = %s)', st.anovaClusters(k,1), ...
                st.anovaClusters(k,2), fmtP(st.anovaClusters(k,3))), 1:size(st.anovaClusters,1), 'UniformOutput', false), ', '));
        if ~any(st.pairSig), fprintf('    aucune paire significative apres Holm\n'); continue; end
        for kp = find(st.pairSig)'
            C = st.pairClusters{kp};
            sgn = '>'; if st.pairSign(kp) > 0, sgn = '<'; end
            fprintf('    %-12s %s %-12s : %s (p Holm test = %.4f)\n', COND_LABELS{ALL_PAIRS(kp,1)}, sgn, ...
                    COND_LABELS{ALL_PAIRS(kp,2)}, strjoin(arrayfun(@(k) sprintf('%.1f-%.1f deg', C(k,1), C(k,2)), ...
                    1:size(C,1), 'UniformOutput', false), ', '), st.pairP(kp));
        end
    end
end


function s = fmtP(p)
    if p < 0.001, s = '<0.001'; else, s = sprintf('%.3f', p); end
end
