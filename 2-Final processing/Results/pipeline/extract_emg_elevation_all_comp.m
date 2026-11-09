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
%               EXPORT_FIGURE : high-resolution export (PNG 600 dpi + PDF)
% Outputs     : Console tables, cache_emg_elevation_all_comp.mat,
%               1 figure (plotRhythmEmgFigure.m),
%               Figures/Figure_6_scapulothoracic_EMG.png/.pdf
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
% Same grid and same rules as extract_scapulohumeral_rhythm_all_comp.m
ELEV_GRID      = 20:1:90;   % deg of humerothoracic elevation
MAX_EXTRAP_DEG = 2.5;       % maximum constant extension below the start of the rise (deg)

ALPHA_ANOVA = 0.05;
ALPHA_FWER  = 0.05;
N_ITER      = 10000;
FORCE_RECOMPUTE = false;
EXPORT_FIGURE   = false;   % secondary figure (7 conditions), not exported: article figure by nested_comparison.m
CACHE_FILE = fullfile(dataDir(), 'cache_emg_elevation_all_comp.mat');

MUSCLE_DISPLAY = containers.Map({'TRAPS','TRAPM','TRAPI','SERRA'}, ...
    {'Upper trapezius', 'Middle trapezius', 'Lower trapezius', 'Serratus anterior'});
SHOW_ELEV = [30 50 70 90];   % elevations at which the mean values are displayed

% -------------------------------------------------------------------------
% LOADING THE CACHES
% -------------------------------------------------------------------------
H = load(fullfile(dataDir(), 'cache_humerothoracic_all_comp.mat'), 'patientMeans', 'x', ...
         'PATIENT_IDS', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS');
E = load(fullfile(dataDir(), 'cache_emg_all_comp.mat'), 'patientBlocks', 'EMG_LABELS', ...
         'PATIENT_IDS', 'CONDITIONS_ORDERED');
if ~isequal(H.PATIENT_IDS, E.PATIENT_IDS) || ~isequal(H.CONDITIONS_ORDERED, E.CONDITIONS_ORDERED)
    error('Participants or conditions differ between the kinematic and EMG caches.');
end
CONDITIONS_ORDERED = H.CONDITIONS_ORDERED;
COND_LABELS = H.COND_LABELS;
nCond = numel(CONDITIONS_ORDERED);
nPat  = numel(H.PATIENT_IDS);
MUS   = E.EMG_LABELS;
nMus  = numel(MUS);

% -------------------------------------------------------------------------
% ENVELOPES NORMALISED TO THE PEAK AGAINST HT ELEVATION (rise)
% elevProf{jm}{ic} = (nPat, nGrid); same rules as the scapulothoracic
% angles (complete curves over the range)
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
fprintf('\nEMG against HT elevation (%d-%d deg, rise): N = %d\n', ...
        ELEV_GRID(1), ELEV_GRID(end), sum(keepPat));

% -------------------------------------------------------------------------
% SPM1D: domain = HT elevation (all the muscles)
% -------------------------------------------------------------------------
ALL_PAIRS = nchoosek(1:nCond, 2);      % same order as the other scripts
cacheValid = false;
if isfile(CACHE_FILE) && ~FORCE_RECOMPUTE
    S_check = load(CACHE_FILE, 'ELEV_GRID', 'MAX_EXTRAP_DEG');
    cacheValid = isequal(S_check.ELEV_GRID, ELEV_GRID) && isequal(S_check.MAX_EXTRAP_DEG, MAX_EXTRAP_DEG);
end
if cacheValid
    fprintf('Cache found: %s\n-> no recomputation\n', CACHE_FILE);
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
    fprintf('Cache saved: %s\n', CACHE_FILE);
end
printSpmPeak(spmPeak, ALL_PAIRS, COND_LABELS, MUSCLE_DISPLAY);

% -------------------------------------------------------------------------
% CONSOLE: mean values per condition at a few elevations
% -------------------------------------------------------------------------
emgMean = cell(1, nMus); emgSD = cell(1, nMus);
for jm = 1:nMus
    emgMean{jm} = cell2mat(cellfun(@(y) mean(y, 1, 'omitnan'), elevProf{jm}(:), 'UniformOutput', false));
    emgSD{jm}   = cell2mat(cellfun(@(y) std(y, 0, 1, 'omitnan'), elevProf{jm}(:), 'UniformOutput', false));
    fprintf('\n%s (%% of peak, mean ± SD)\n    %-12s', MUSCLE_DISPLAY(MUS{jm}), 'Condition');
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
% Secondary figure: scapulothoracic angles (row 1, cache of the
% scapulohumeral rhythm) and EMG (row 2)
K = struct('x', ELEV_GRID, 'muscleNames', {cellfun(@(m) MUSCLE_DISPLAY(m), MUS, 'UniformOutput', false)}, ...
           'emgMean', {emgMean}, 'elevProf', {elevProf}, 'spm', spmPeak, 'ALL_PAIRS', ALL_PAIRS);
RH = load(fullfile(dataDir(), 'cache_scapulohumeral_rhythm_all_comp.mat'), 'joints', 'ELEV_GRID', ...
          'CONDITIONS_ORDERED', 'ALL_PAIRS');
if ~isequal(RH.ELEV_GRID, ELEV_GRID) || ~isequal(RH.CONDITIONS_ORDERED, CONDITIONS_ORDERED)
    error('Elevation grid or conditions differ between the rhythm and EMG caches.');
end
JST = RH.joints{cellfun(@(j) strcmp(j.name, 'Scapulothoracic'), RH.joints)};
plotRhythmEmgFigure(JST, ELEV_GRID, CONDITIONS_ORDERED, COND_LABELS, conditionColors(CONDITIONS_ORDERED), RH.ALL_PAIRS, K);
if EXPORT_FIGURE, exportFigure(gcf, 'Figure_6_scapulothoracic_EMG'); end

disp(' '); disp('Done.');


% =========================================================================
% FONCTIONS LOCALES
% =========================================================================

function P = peakNormalisedPatients(patientBlocks, muscle, cond, nPat, nPts)
    % (nPat, nPts): each block expressed relative to its own peak, mean per participant
    P = NaN(nPat, nPts);
    fld = matlab.lang.makeValidName(cond);
    for ip = 1:nPat
        B = patientBlocks.(fld).(muscle){ip};
        if isempty(B), continue; end
        P(ip, :) = mean(100 * B ./ max(B, [], 2), 1);
    end
end


function st = spmAllPairs(Yc, grid, ALL_PAIRS, alphaA, alphaF, nIter, st)
    % Non-parametric RM ANOVA (7 conditions) then, if significant, paired SPM{t}
    % on all the pairs, Holm-Bonferroni (helpers/holmAlphaSPM1D.m).
    % Cluster limits in the unit of grid (0-based spm1d endpoints:
    % grid(1) + ep * step).
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
        if st.pairSig(kp)   % sign of the difference B - A in the first cluster
            ep = ti.clusters{1}.endpoints;
            idx = max(1, floor(ep(1)) + 1):min(Q, ceil(ep(2)) + 1);
            st.pairSign(kp) = sign(mean(mean(Y{ALL_PAIRS(kp,2)}(:, idx) - Y{ALL_PAIRS(kp,1)}(:, idx))));
        end
    end
end


function T = clusterTable(clusters, toUnit)
    % [start end p] per cluster, limits in the unit of the domain
    T = zeros(numel(clusters), 3);
    for k = 1:numel(clusters)
        T(k, :) = [toUnit(clusters{k}.endpoints(:)') clusters{k}.P];
    end
end


function printSpmPeak(spmPeak, ALL_PAIRS, COND_LABELS, MUSCLE_DISPLAY)
    fprintf('\n=== SPM1D on the envelopes normalised to the peak (%% of peak), domain = HT elevation (deg) ===\n');
    for jm = 1:numel(spmPeak)
        st = spmPeak(jm);
        fprintf('%-20s ANOVA: ', MUSCLE_DISPLAY(st.muscle));
        if ~st.anovaSig, fprintf('n.s.\n'); continue; end
        fprintf('%s\n', strjoin(arrayfun(@(k) sprintf('%.1f-%.1f deg (p = %s)', st.anovaClusters(k,1), ...
                st.anovaClusters(k,2), fmtP(st.anovaClusters(k,3))), 1:size(st.anovaClusters,1), 'UniformOutput', false), ', '));
        if ~any(st.pairSig), fprintf('    no significant pair after Holm\n'); continue; end
        for kp = find(st.pairSig)'
            C = st.pairClusters{kp};
            sgn = '>'; if st.pairSign(kp) > 0, sgn = '<'; end
            fprintf('    %-12s %s %-12s: %s (p Holm test = %.4f)\n', COND_LABELS{ALL_PAIRS(kp,1)}, sgn, ...
                    COND_LABELS{ALL_PAIRS(kp,2)}, strjoin(arrayfun(@(k) sprintf('%.1f-%.1f deg', C(k,1), C(k,2)), ...
                    1:size(C,1), 'UniformOutput', false), ', '), st.pairP(kp));
        end
    end
end


function s = fmtP(p)
    if p < 0.001, s = '<0.001'; else, s = sprintf('%.3f', p); end
end
