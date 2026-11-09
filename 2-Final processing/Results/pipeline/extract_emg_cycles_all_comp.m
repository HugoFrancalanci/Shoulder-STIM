% =========================================================================
% extract_emg_cycles_all_comp.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : July 2026
% -------------------------------------------------------------------------
% Description : Surface EMG of the upper, middle and lower trapezius and the
%               serratus anterior, 10 participants, 7 conditions. For each
%               trial: removal of the stimulation artefact (FES conditions),
%               segmentation of the movement cycles, linear envelope
%               (full-wave rectification, 6 Hz low-pass filter) normalised to
%               the pre-movement rest and to 101 points, mean over cycles.
%               SPM1D comparison of the conditions at the group level (N = 10)
%               and per participant (3 trials).
%               Statistics: non-parametric repeated-measures ANOVA across the
%               7 conditions (10 000 permutations), then, if significant,
%               paired t-tests on the 21 pairs of conditions with
%               Holm-Bonferroni correction (alpha = 0.05).
%               Results are saved in a cache; later runs only redraw the
%               figures (FORCE_RECOMPUTE = true to recompute).
% -------------------------------------------------------------------------
% Parameters  : FS_EMG = 2200 Hz, FS_KIN = 100 Hz, LP_FREQ = 6 Hz
%               BLANK_MS = 8, MAD_FACTOR = 6, MIN_PERIOD_MS = 15, MAX_BLANK_MS = 20
%               REPORT_MUSCLES : muscles shown in the figures
%               ALPHA_FWER = 0.05, FORCE_RECOMPUTE
% Outputs     : Per-participant and group figures, console tables,
%               cache_emg_all_comp.mat (used by extract_emg_elevation_all_comp.m)
% -------------------------------------------------------------------------
% Dependencies: usercommands_conditions.m, K-LAB .mat files, helpers/,
%               plotting/plotAllCompFigureEMG.m, spm1dmatlab-master/
% References  : Pataky TC (2010), J Biomech 43:1976-1982
%               Winter DA (2009), Biomechanics and Motor Control of Human
%               Movement, 4th ed.
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' extract_emg_cycles_all_comp.m');
disp('=========================================');

% SPM1D must be on the path BEFORE the load() of the cache (even in the
% cache fast path below): the SPM1D clusters are objects of a custom
% class, and MATLAB can rebuild them from the .mat only if the class
% defining them is already loaded ("Dot indexing is not
% supported for variables of this type" otherwise).
SPM1D_PATH = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end
addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'plotting'));
addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'helpers'));

% -------------------------------------------------------------------------
% CACHE: fast regeneration of the final figure only, without recomputing
% everything (the non-parametric Monte Carlo SPM1D is the slowest
% step). Set FORCE_RECOMPUTE to true to ignore the cache and redo everything.
% -------------------------------------------------------------------------
FORCE_RECOMPUTE = false;

% Muscles reported (figures): the 4 muscles. DISPLAY filter
% only (Holm families per muscle -> removing a muscle does not change
% the results of the others, no recomputation or new permutation draw).
REPORT_MUSCLES = {'TRAPS', 'TRAPM', 'TRAPI', 'SERRA'};
CACHE_FILE = fullfile(dataDir(), 'cache_emg_all_comp.mat');

% Post-hoc correction method: saved in the cache, a cache
% computed with another correction (e.g. former Bonferroni) or without the
% curves per block (patientBlocks, discrete analysis) is ignored and everything is
% recomputed.
POSTHOC_CORRECTION = 'holm';

cacheValid = false;
cachedCorrection = '';
cacheHasBlocks = false;
if isfile(CACHE_FILE) && ~FORCE_RECOMPUTE
    try
        cacheInfo      = whos('-file', CACHE_FILE);
        cacheVars      = {cacheInfo.name};
        cacheHasBlocks = ismember('patientBlocks', cacheVars);
        if ismember('POSTHOC_CORRECTION', cacheVars)
            S_check = load(CACHE_FILE, 'POSTHOC_CORRECTION');
            cachedCorrection = S_check.POSTHOC_CORRECTION;
        end
    catch
    end
    cacheValid = strcmp(cachedCorrection, POSTHOC_CORRECTION) && cacheHasBlocks;
end

if cacheValid
    fprintf('Cache found: %s\n', CACHE_FILE);
    fprintf('-> Fast regeneration of the final figure (no SPM1D recomputation).\n');
    fprintf('  (set FORCE_RECOMPUTE=true in the script to recompute everything)\n\n');
    load(CACHE_FILE, 'patientMeans', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', 'EMG_LABELS', 'X_CYCLE', 'spmResults', 'ALL_PAIRS', 'indivSigClusters', 'PATIENT_IDS');

    keepM = ismember(EMG_LABELS, REPORT_MUSCLES);
    plotAllCompFigureEMG(patientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS, EMG_LABELS(keepM), X_CYCLE, ...
                         spmResults(keepM), ALL_PAIRS, indivSigClusters(keepM), PATIENT_IDS);
    return;
elseif isfile(CACHE_FILE) && ~FORCE_RECOMPUTE
    fprintf('Cache found but outdated (correction "%s" -> "%s", curves per block present: %d): full recomputation.\n\n', ...
            cachedCorrection, POSTHOC_CORRECTION, cacheHasBlocks);
end

run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'usercommands_conditions.m'));

% SPM1D already added to the path above (before the cache fast path)
rng(0);  % reproducibility of the non-parametric tests (Monte Carlo permutations)

% -------------------------------------------------------------------------
% PARAMETRES
% -------------------------------------------------------------------------
FS_EMG  = 2200;   % Hz
FS_KIN  = 100;    % Hz

LP_FREQ = 6;      % envelope low-pass cut-off (Winter 2009)
LP_ORD  = 2;      % Butterworth order
X_CYCLE = 0:100;  % normalised cycle axis (101 points)

% FES artefact removal parameters
BLANK_MS      = 8;
MAD_FACTOR    = 6;
MIN_PERIOD_MS = 15;
MAX_BLANK_MS  = 20;

% Channels to display
EMG_LABELS = {'TRAPS','TRAPM','TRAPI','SERRA'};

CONDITIONS_ORDERED = {'No FES','Min_fatigue','Min_stress','Random','Min_pulse_width','Rehab','Min_force'};
COND_LABELS = {'No FES','Min fatigue','Min stress','Random','Min PW','Rehab','Min force'};
COLORS = [0.35 0.20 0.29;   % No FES       aubergine
          0.66 0.80 0.63;   % Min_fatigue  sage green
          0.30 0.47 0.46;   % Min_stress   dark teal
          0.91 0.76 0.45;   % Random       golden yellow
          0.89 0.63 0.33;   % Min_pulse_width (Min PW) orange
          0.45 0.55 0.68;   % Rehab        blue-grey
          0.75 0.35 0.35];  % Min_force    salmon red

% Low-pass filter
[b_lp, a_lp] = butter(LP_ORD, LP_FREQ / (FS_EMG/2), 'low');

warnings = {};

% -------------------------------------------------------------------------
% ALL THE PAIRS OF CONDITIONS (C(7,2) = 21)
% -------------------------------------------------------------------------
ALL_PAIRS = {};
for a = 1:length(CONDITIONS_ORDERED)-1
    for b = a+1:length(CONDITIONS_ORDERED)
        ALL_PAIRS(end+1, :) = {CONDITIONS_ORDERED{a}, CONDITIONS_ORDERED{b}}; %#ok<AGROW>
    end
end
N_PAIRS        = size(ALL_PAIRS, 1);
ALPHA_FWER     = 0.05;  % Holm-Bonferroni: threshold alpha/(m-k+1) per pair (helpers/holmAlphaSPM1D.m)
PAIR_BAR_COLOR = [0.35 0.35 0.35];  % single neutral colour (no more "vs reference")

% Global accumulator: globalData.(condName).(muscle) = cell of (1,101) vectors
globalData = struct();
for ic = 1:length(CONDITIONS_ORDERED)
    fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
    globalData.(fld) = struct();
    for im = 1:length(EMG_LABELS)
        globalData.(fld).(EMG_LABELS{im}) = {};
    end
end

% SPM accumulator: patientMeans.(condName).(muscle) = cell, one (1,101) vector PER PARTICIPANT
patientMeans = struct();
for ic = 1:length(CONDITIONS_ORDERED)
    fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
    patientMeans.(fld) = struct();
    for im = 1:length(EMG_LABELS)
        patientMeans.(fld).(EMG_LABELS{im}) = {};
    end
end

% Curves PER BLOCK (one row per valid block), for the normalisation to the peak
% of each trial (extract_emg_elevation_all_comp.m):
% patientBlocks.(condName).(muscle){ip} = (n_blocks, 101)
patientBlocks = struct();
for ic = 1:length(CONDITIONS_ORDERED)
    fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
    patientBlocks.(fld) = struct();
    for im = 1:length(EMG_LABELS)
        patientBlocks.(fld).(EMG_LABELS{im}) = {};
    end
end

% Accumulator for the final figure: individual significant clusters
% indivSigClusters{im}.(pairFld){ip} = spmi_t_pt.clusters (empty cell if n.s.)
indivSigClusters = cell(length(EMG_LABELS), 1);
for im_i = 1:length(EMG_LABELS)
    indivSigClusters{im_i} = struct();
    for kp = 1:N_PAIRS
        fld = pairFieldName(ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2});
        indivSigClusters{im_i}.(fld) = cell(length(PATIENT_IDS), 1);
    end
end

% -------------------------------------------------------------------------
% BOUCLE PATIENTS
% -------------------------------------------------------------------------
for ip = 1:length(PATIENT_IDS)

    patientID = PATIENT_IDS{ip};
    side      = DOMINANT_SIDE(patientID);
    cycleKey  = 'Rcycle';
    if strcmp(side, 'L'), cycleKey = 'Lcycle'; end

    pnum    = str2double(patientID(2:end));
    matFile = fullfile(dataFolder, ['P' num2str(pnum) '.mat']);

    if ~isfile(matFile)
        warnings{end+1} = ['[SKIP] ' patientID ': file not found'];
        continue;
    end

    fprintf('Processing %s (side %s)...\n', patientID, side);
    load(matFile, 'Trial');

    analyticTrials = filterAnalytic2(Trial);
    nTrials        = length(analyticTrials);
    condList       = PATIENT_COND.(patientID);
    nCond          = length(condList.condition);

    if nTrials ~= nCond
        warnings{end+1} = sprintf('[WARNING] %s: %d trials vs %d conditions', patientID, nTrials, nCond);
    end

    missingCondPos = [];
    if isfield(PATIENT_EXCEPTIONS, patientID) && ...
       isfield(PATIENT_EXCEPTIONS.(patientID), 'missingCondPositions')
        missingCondPos = PATIENT_EXCEPTIONS.(patientID).missingCondPositions;
    end

    % condData.(condName).(muscleLabel): cell array of 101-point vectors
    condData = struct();
    for ic = 1:length(CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        condData.(fld) = struct();
        for im = 1:length(EMG_LABELS)
            condData.(fld).(EMG_LABELS{im}) = {};
        end
    end

    trialIdx = 0;
    for iseq = 1:nCond

        cond   = condList.condition{iseq};
        isFES  = ~strcmp(cond, 'No FES');

        if ismember(iseq, missingCondPos)
            warnings{end+1} = sprintf('[WARNING] %s cond %d (%s): missing', patientID, iseq, cond);
            continue;
        end

        trialIdx = trialIdx + 1;
        if trialIdx > nTrials
            warnings{end+1} = sprintf('[WARNING] %s: no more trials at cond %d (%s)', patientID, iseq, cond);
            break;
        end

        itrial = analyticTrials(trialIdx);
        t      = Trial(itrial);

        fld = matlab.lang.makeValidName(cond);

        for im = 1:length(EMG_LABELS)
            mLabel   = EMG_LABELS{im};
            emgChIdx = find(strcmp({t.Emg.label}, mLabel), 1);
            if isempty(emgChIdx), continue; end

            emgCh = t.Emg(emgChIdx);

            % Signal.cycle.raw
            if ~isfield(emgCh.Signal, 'cycle') || ~isfield(emgCh.Signal.cycle, 'raw')
                warnings{end+1} = sprintf('[WARNING] %s trial %d (%s) %s: no cycle.raw', patientID, trialIdx, cond, mLabel);
                continue;
            end
            sig_full = double(emgCh.Signal.full(:));
            N_emg    = length(sig_full);

            % --- FES artefact removal on Signal.full (FES conditions only) ---
            if isFES
                sig_proc = removeFESArtifact(sig_full, FS_EMG, BLANK_MS, MAD_FACTOR, MIN_PERIOD_MS, MAX_BLANK_MS);
            else
                sig_proc = sig_full;
            end

            % --- Cycle cutting with Rcycle/Lcycle ---
            if ~isfield(t, cycleKey) || isempty(t.(cycleKey))
                warnings{end+1} = sprintf('[WARNING] %s trial %d (%s): no %s', patientID, trialIdx, cond, cycleKey);
                continue;
            end
            cycles_kin = t.(cycleKey);
            nCyclesTr  = length(cycles_kin);
            if nCyclesTr == 0, continue; end

            % --- Linear envelope per cycle (Winter 2009) ---
            cycMeans = zeros(nCyclesTr, 101);
            validCyc = false(nCyclesTr, 1);
            for kc = 1:nCyclesTr
                rng_c = cycles_kin(kc).range;
                if isempty(rng_c) || length(rng_c) < 2, continue; end
                i1 = max(1,     round(rng_c(1)   * FS_EMG / FS_KIN));
                i2 = min(N_emg, round(rng_c(end) * FS_EMG / FS_KIN));
                if i2 - i1 < 10, continue; end
                seg    = sig_proc(i1:i2);
                seg_env = filtfilt(b_lp, a_lp, abs(seg));
                t_orig  = linspace(0, 100, length(seg_env));
                cycMeans(kc,:) = interp1(t_orig, seg_env, X_CYCLE, 'pchip');
                validCyc(kc)   = true;
            end
            if ~any(validCyc), continue; end
            cycMeans = cycMeans(validCyc, :);

            % --- Amplitude normalisation (mean + 3*std before the movement) ---
            sig_env_full = filtfilt(b_lp, a_lp, abs(sig_proc));
            n_ref   = min(round(50 * FS_EMG / FS_KIN), length(sig_env_full));
            ref_val = mean(sig_env_full(1:n_ref)) + 3*std(sig_env_full(1:n_ref));
            if ref_val < 1e-10, ref_val = 1; end
            cycMeans = cycMeans / ref_val * 100;

            meanCycle = nanmean(cycMeans, 1);  % (1, 101)
            condData.(fld).(mLabel){end+1} = meanCycle;
            globalData.(fld).(mLabel){end+1} = meanCycle;
        end
    end % iseq

    % --- Mean of the blocks per condition (1 value per participant for SPM) ---
    for ic = 1:length(CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        for im = 1:length(EMG_LABELS)
            mLabel = EMG_LABELS{im};
            trials_cond = condData.(fld).(mLabel);
            if isempty(trials_cond)
                patientMeans.(fld).(mLabel){end+1} = NaN(1, 101);
                patientBlocks.(fld).(mLabel){end+1} = zeros(0, 101);
            else
                stack_pt = cat(1, trials_cond{:});
                patientMeans.(fld).(mLabel){end+1} = nanmean(stack_pt, 1);
                patientBlocks.(fld).(mLabel){end+1} = stack_pt;  % (n_blocks, 101)
            end
        end
    end

    % --- Participant figure ---
    figure('Name', patientID, 'units','normalized','outerposition',[0 0 1 1]);
    nMuscles = length(EMG_LABELS);

    for im = 1:nMuscles
        mLabel = EMG_LABELS{im};
        subplot(1, nMuscles, im);
        hold on;
        legendHandles = gobjects(length(CONDITIONS_ORDERED), 1);

        for ic = 1:length(CONDITIONS_ORDERED)
            cond = CONDITIONS_ORDERED{ic};
            fld  = matlab.lang.makeValidName(cond);
            trials_cond = condData.(fld).(mLabel);
            if isempty(trials_cond), continue; end

            stack = cat(1, trials_cond{:});    % (n_trials, 101)
            meanCurve = nanmean(stack, 1);     % (1, 101)
            stdCurve  = nanstd(stack, 0, 1);

            h = plot(X_CYCLE, meanCurve, 'Color', COLORS(ic,:), 'LineWidth', 2, ...
                     'DisplayName', cond);
            legendHandles(ic) = h;

            fill([X_CYCLE fliplr(X_CYCLE)], ...
                 [meanCurve+stdCurve fliplr(meanCurve-stdCurve)], ...
                 COLORS(ic,:), 'FaceAlpha', 0.10, 'EdgeColor', 'none', ...
                 'HandleVisibility', 'off');
        end

        xlabel('% cycle');
        ylabel('Normalised EMG (% baseline)');
        title(mLabel, 'FontSize', 11, 'FontWeight', 'bold');
        valid_h = legendHandles(arrayfun(@(h) isvalid(h) && ~strcmp(h.DisplayName,''), legendHandles));
        legend(valid_h, 'Location','best', 'FontSize', 7);
        grid on; box on; hold off;
    end

    sgtitle(sprintf('%s  -  Mean EMG cycles  (linear envelope, FES artefact removed)', patientID), ...
            'FontSize', 13, 'FontWeight', 'bold');

    % --- Participant SPM1D figure (N = 3 blocks per condition) ---
    fprintf('\n=== Individual EMG SPM1D (all comparisons): %s ===\n', patientID);
    figure('Name', [patientID ' - SPM1D EMG (all comp)'], 'units','normalized','outerposition',[0 0 1 1],'Color','white');

    patientSpmResults = struct();
    for im_init = 1:nMuscles
        patientSpmResults(im_init).posthoc = struct();
    end

    for im = 1:nMuscles
        mLabel = EMG_LABELS{im};
        subplot(1, nMuscles, im);
        hold on;
        legendHandles_spm = gobjects(length(CONDITIONS_ORDERED), 1);
        y_min_pt = Inf; y_max_pt = -Inf;

        for ic = 1:length(CONDITIONS_ORDERED)
            fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
            trials_cond = condData.(fld).(mLabel);
            if isempty(trials_cond), continue; end
            stack = cat(1, trials_cond{:});
            mc = nanmean(stack, 1);
            sc = nanstd(stack, 0, 1);
            fill([X_CYCLE fliplr(X_CYCLE)], [mc+sc fliplr(mc-sc)], ...
                 COLORS(ic,:), 'FaceAlpha', 0.10, 'EdgeColor','none','HandleVisibility','off');
            legendHandles_spm(ic) = plot(X_CYCLE, mc, 'Color', COLORS(ic,:), 'LineWidth', 2, ...
                                         'DisplayName', CONDITIONS_ORDERED{ic});
            y_min_pt = min(y_min_pt, min(mc-sc));
            y_max_pt = max(y_max_pt, max(mc+sc));
        end

        % Padding of condData for a balanced design (N_TARGET = 3 blocks)
        N_TARGET = 3;
        condData_padded = condData;
        for ic_p = 1:length(CONDITIONS_ORDERED)
            fld_p = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic_p});
            blocs = condData.(fld_p).(mLabel);
            if ~isempty(blocs) && length(blocs) < N_TARGET
                if im == 1
                    fprintf('  [WARN] %s - %s: %d blocks -> duplication\n', ...
                            patientID, CONDITIONS_ORDERED{ic_p}, length(blocs));
                end
                while length(condData_padded.(fld_p).(mLabel)) < N_TARGET
                    condData_padded.(fld_p).(mLabel){end+1} = condData_padded.(fld_p).(mLabel){end};
                end
            end
        end

        % Builds the matrices for the RM ANOVA from condData_padded
        all_mat_pt = []; group_vec_pt = []; subj_vec_pt = [];
        n_min = Inf;
        for ic = 1:length(CONDITIONS_ORDERED)
            fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
            trials_cond = condData_padded.(fld).(mLabel);
            if isempty(trials_cond), continue; end
            mat_ic = cat(1, trials_cond{:});
            n_ic   = size(mat_ic, 1);
            n_min  = min(n_min, n_ic);
            all_mat_pt   = [all_mat_pt;   mat_ic];
            group_vec_pt = [group_vec_pt; repmat(ic, n_ic, 1)];
            subj_vec_pt  = [subj_vec_pt;  (1:n_ic)'];
        end
        if ~isfinite(n_min), n_min = 0; end

        data_range   = max(y_max_pt - y_min_pt, 0.01);
        bar_h_pt     = data_range * 0.03;
        bar_gap_pt   = data_range * 0.01;
        y_bar_top_pt = y_min_pt - data_range * 0.04;
        anova_sig_pt = false;

        if length(unique(group_vec_pt)) >= 2
            try
                warning('off', 'all');
                spm_F_pt  = spm1d.stats.nonparam.anova1rm(all_mat_pt, group_vec_pt, subj_vec_pt);
                warning('on', 'all');
                spmi_F_pt = spm_F_pt.inference(0.05, 'iterations', 10000, 'interp', true);
                anova_sig_pt = ~isempty(spmi_F_pt.clusters);
            catch ME_anova
                fprintf('  %s - ANOVA error: %s\n', mLabel, ME_anova.message);
            end
        end

        rowIdx_pt = 0;
        if anova_sig_pt && n_min < 3
            fprintf('  %s - ANOVA: SIGNIFICANT but post-hoc skipped (df=%d, N=%d insufficient for RFT)\n', ...
                    mLabel, n_min-1, n_min);
        elseif anova_sig_pt
            fprintf('  %s - ANOVA: SIGNIFICANT -> post-hoc (%d pairs tested)\n', mLabel, N_PAIRS);
            % Pass 1: SPM{t} of each tested pair; pass 2: inference at the
            % Holm-Bonferroni threshold of each pair (helpers/holmAlphaSPM1D.m)
            spmList_pt = cell(1, N_PAIRS);
            for kp = 1:N_PAIRS
                fldA = matlab.lang.makeValidName(ALL_PAIRS{kp,1});
                fldB = matlab.lang.makeValidName(ALL_PAIRS{kp,2});
                if isempty(condData_padded.(fldA).(mLabel)) || isempty(condData_padded.(fldB).(mLabel)), continue; end
                try
                    spmList_pt{kp} = spm1d.stats.ttest_paired(cat(1, condData_padded.(fldB).(mLabel){:}), ...
                                                              cat(1, condData_padded.(fldA).(mLabel){:}));
                catch ME_ph
                    fprintf('    %s vs %s: error - %s\n', ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}, ME_ph.message);
                end
            end
            [alphaHolm_pt, pHolm_pt] = holmAlphaSPM1D(spmList_pt, ALPHA_FWER);

            for kp = 1:N_PAIRS
                if isempty(spmList_pt{kp}), continue; end
                condA = ALL_PAIRS{kp,1}; condB = ALL_PAIRS{kp,2};
                try
                    spmi_t_pt = spmList_pt{kp}.inference(alphaHolm_pt(kp), 'two_tailed', true, 'interp', true);
                    if ~isempty(spmi_t_pt.clusters)
                        rowIdx_pt = rowIdx_pt + 1;
                        fprintf('    %s vs %s: SIGNIFICANT (%d cluster(s), Holm p=%.5f < alpha=%.5f)\n', ...
                                condLabel(condA, CONDITIONS_ORDERED, COND_LABELS), condLabel(condB, CONDITIONS_ORDERED, COND_LABELS), ...
                                length(spmi_t_pt.clusters), pHolm_pt(kp), alphaHolm_pt(kp));
                        y_bar_pt = y_bar_top_pt - (rowIdx_pt-1) * (bar_h_pt + bar_gap_pt);
                        for cl = 1:length(spmi_t_pt.clusters)
                            ep = spmi_t_pt.clusters{cl}.endpoints;
                            rectangle('Position', [ep(1)-1, y_bar_pt, ep(2)-ep(1), bar_h_pt], ...
                                      'FaceColor', PAIR_BAR_COLOR, 'EdgeColor','none','FaceAlpha',0.85);
                            fprintf('      cluster %d: %.1f%%-%.1f%% of the cycle (duration %.1f%%)\n', ...
                                    cl, ep(1)-1, ep(2)-1, ep(2)-ep(1));
                        end
                        pairFld = pairFieldName(condA, condB);
                        patientSpmResults(im).posthoc.(pairFld).condA = condA;
                        patientSpmResults(im).posthoc.(pairFld).condB = condB;
                        patientSpmResults(im).posthoc.(pairFld).clusters = spmi_t_pt.clusters;
                        indivSigClusters{im}.(pairFld){ip} = spmi_t_pt.clusters;
                    end
                catch ME_ph
                    fprintf('    %s vs %s: error - %s\n', condA, condB, ME_ph.message);
                end
            end
            if rowIdx_pt == 0
                fprintf('    (no significant pair - RFT + Holm-Bonferroni alpha=%.2f on %d comparisons)\n', ALPHA_FWER, N_PAIRS);
            end
        else
            fprintf('  %s - ANOVA: not significant\n', mLabel);
        end

        bar_zone_pt = max(rowIdx_pt, 1) * (bar_h_pt + bar_gap_pt);
        if isfinite(y_min_pt)
            ylim([y_min_pt - bar_zone_pt - data_range*0.05, y_max_pt + data_range*0.05]);
        end

        xlabel('% cycle');
        ylabel('Normalised EMG (% baseline)');
        title(mLabel, 'FontSize', 11, 'FontWeight', 'bold');
        valid_h = legendHandles_spm(arrayfun(@(h) isvalid(h) && ~strcmp(h.DisplayName,''), legendHandles_spm));
        legend(valid_h, 'Location','best', 'FontSize', 7);
        grid on; box on; hold off;
    end

    sgtitle(sprintf('%s  -  Individual EMG SPM1D, all comparisons (N = 3 blocks per condition)', patientID), ...
            'FontSize', 13, 'FontWeight', 'bold');

    % --- Individual summary table ---
    fprintf('\n  --- Individual summary table (%s): significant cluster ---\n', patientID);
    fprintf('  %-10s  %-28s  %-9s  %-9s  %s\n', ...
            'Muscle', 'Comparaison', 'Debut(%)', 'Fin(%)', 'p-value');
    anyRow_pt = false;
    for im = 1:nMuscles
        for kp = 1:N_PAIRS
            pairFld = pairFieldName(ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2});
            if ~isfield(patientSpmResults(im).posthoc, pairFld), continue; end
            ph = patientSpmResults(im).posthoc.(pairFld);
            if ~isfield(ph, 'clusters') || isempty(ph.clusters), continue; end
            compLabel = sprintf('%s vs %s', condLabel(ph.condA, CONDITIONS_ORDERED, COND_LABELS), condLabel(ph.condB, CONDITIONS_ORDERED, COND_LABELS));
            for cl = 1:length(ph.clusters)
                ep = ph.clusters{cl}.endpoints;
                pv = ph.clusters{cl}.P;
                fprintf('  %-10s  %-28s  %-9.1f  %-9.1f  %.4f\n', ...
                        EMG_LABELS{im}, compLabel, ep(1)-1, ep(2)-1, pv);
                anyRow_pt = true;
            end
        end
    end
    if ~anyRow_pt
        fprintf('  (no significant post-hoc for %s)\n', patientID);
    end

end % ip

% =========================================================================
% GLOBAL FIGURE: mean EMG cycle across participants (P1-P10)
% =========================================================================
figure('Name','Global -- Mean EMG cycles P1-P10 (all comp)', ...
       'units','normalized','outerposition',[0 0 1 1], 'Color','white');

for im = 1:length(EMG_LABELS)
    mLabel = EMG_LABELS{im};
    subplot(1, length(EMG_LABELS), im);
    hold on;
    legendHandles = gobjects(length(CONDITIONS_ORDERED), 1);

    for ic = 1:length(CONDITIONS_ORDERED)
        fld  = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        pts  = globalData.(fld).(mLabel);
        if isempty(pts), continue; end

        stack     = cat(1, pts{:});
        meanCurve = nanmean(stack, 1);
        stdCurve  = nanstd(stack, 0, 1);

        fill([X_CYCLE fliplr(X_CYCLE)], [meanCurve+stdCurve fliplr(meanCurve-stdCurve)], ...
             COLORS(ic,:), 'FaceAlpha', 0.12, 'EdgeColor','none', 'HandleVisibility','off');
        legendHandles(ic) = plot(X_CYCLE, meanCurve, 'Color', COLORS(ic,:), 'LineWidth', 2, ...
                                 'DisplayName', COND_LABELS{ic});
    end

    xlabel('% cycle'); ylabel('Normalised EMG (% baseline)');
    title(mLabel, 'FontSize', 11, 'FontWeight','bold');
    valid_h = legendHandles(arrayfun(@(h) isvalid(h) && ~strcmp(h.DisplayName,''), legendHandles));
    legend(valid_h, 'Location','best', 'FontSize', 7);
    grid on; box on; hold off;
end
sgtitle('Comparison of the stimulation conditions - All participants (EMG)', ...
        'FontSize', 13, 'FontWeight','bold');

% =========================================================================
% SPM1D ANALYSIS: RM ANOVA on 7 conditions + post-hoc on ALL the pairs
% =========================================================================

fprintf('\n=== Choice of the statistical tests (EMG) ===\n');
fprintf('  Design        : within-subject repeated measures (10 participants x 7 conditions)\n');
fprintf('  Independence  : 1 mean per participant per condition (averaged blocks)\n');
fprintf('  Omnibus test  : one-way non-parametric RM ANOVA (spm1d.stats.nonparam.anova1rm, Monte Carlo 10000 iterations)\n');
fprintf('  Post-hoc      : paired t-test on each of the %d pairs of conditions (spm1d.stats.ttest_paired, parametric)\n', N_PAIRS);
fprintf('  Correction    : Holm-Bonferroni on %d comparisons (FWER alpha = %.2f;\n', N_PAIRS, ALPHA_FWER);
fprintf('                  thresholds from alpha/%d = %.5f to alpha/1 = %.2f according to the rank of the p-value)\n', N_PAIRS, ALPHA_FWER/N_PAIRS, ALPHA_FWER);
fprintf('  Temporal      : Random Field Theory with SPM1D (Pataky 2010)\n');
fprintf('%s\n', repmat('-', 1, 55));

% Prepares the matrices (N_participants x 101) per condition and per muscle
spmData = struct();
for ic = 1:length(CONDITIONS_ORDERED)
    fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
    spmData.(fld) = struct();
    for im = 1:length(EMG_LABELS)
        mLabel = EMG_LABELS{im};
        pts    = patientMeans.(fld).(mLabel);
        if isempty(pts)
            spmData.(fld)(im).mat = [];
        else
            spmData.(fld)(im).mat = cat(1, pts{:});
        end
    end
end

% Results structure
spmResults = struct();
for im = 1:length(EMG_LABELS)
    spmResults(im).muscle         = EMG_LABELS{im};
    spmResults(im).anova_sig      = false;
    spmResults(im).anova_clusters = {};
    spmResults(im).posthoc        = struct();
end

% SPM figure (curves + stacked bars for the significant pairs only)
figure('Name','SPM1D -- EMG -- ANOVA + post-hoc on all pairs', ...
       'units','normalized','outerposition',[0 0 1 1], 'Color','white');

for im = 1:length(EMG_LABELS)
    mLabel = EMG_LABELS{im};
    ax = subplot(1, length(EMG_LABELS), im);
    hold on;

    legendHandles = gobjects(length(CONDITIONS_ORDERED), 1);
    y_min_plot = Inf; y_max_plot = -Inf;

    for ic = 1:length(CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        if isempty(spmData.(fld)(im).mat), continue; end
        mat = spmData.(fld)(im).mat;
        mc  = nanmean(mat, 1);
        sc  = nanstd(mat, 0, 1);
        fill([X_CYCLE fliplr(X_CYCLE)], [mc+sc fliplr(mc-sc)], COLORS(ic,:), ...
             'FaceAlpha', 0.10, 'EdgeColor','none', 'HandleVisibility','off');
        legendHandles(ic) = plot(X_CYCLE, mc, 'Color', COLORS(ic,:), 'LineWidth', 2, ...
                                 'DisplayName', COND_LABELS{ic});
        y_min_plot = min(y_min_plot, min(mc-sc));
        y_max_plot = max(y_max_plot, max(mc+sc));
    end

    BAR_HEIGHT = 0.02;
    BAR_GAP    = 0.005;
    y_bar_top  = y_min_plot - 0.02;

    % ANOVA RM
    all_mat = []; group_vec = []; subj_vec = [];
    for ic = 1:length(CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        if isempty(spmData.(fld)(im).mat), continue; end
        mat = spmData.(fld)(im).mat;
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
            spmResults(im).anova_sig      = anova_sig;
            spmResults(im).anova_clusters = spmi_F.clusters;
            if anova_sig, sig_str = 'SIGNIFICANT'; else, sig_str = 'not significant'; end
            fprintf('%s ANOVA: %s\n', mLabel, sig_str);
        catch ME
            fprintf('%s ANOVA error: %s\n', mLabel, ME.message);
        end
    end

    % Post-hoc: all the pairs (if the ANOVA is significant)
    rowIdx = 0;
    if anova_sig
        % Pass 1: SPM{t} of each tested pair; pass 2: inference at the
        % Holm-Bonferroni threshold of each pair
        spmList = cell(1, N_PAIRS);
        for kp = 1:N_PAIRS
            fldA = matlab.lang.makeValidName(ALL_PAIRS{kp,1});
            fldB = matlab.lang.makeValidName(ALL_PAIRS{kp,2});
            if isempty(spmData.(fldA)(im).mat) || isempty(spmData.(fldB)(im).mat), continue; end
            try
                spmList{kp} = spm1d.stats.ttest_paired(spmData.(fldB)(im).mat, spmData.(fldA)(im).mat);
            catch ME
                fprintf('  %s | %s vs %s error: %s\n', mLabel, ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}, ME.message);
            end
        end
        [alphaHolm, pHolm] = holmAlphaSPM1D(spmList, ALPHA_FWER);

        for kp = 1:N_PAIRS
            if isempty(spmList{kp}), continue; end
            condA = ALL_PAIRS{kp,1}; condB = ALL_PAIRS{kp,2};
            fldA = matlab.lang.makeValidName(condA);
            fldB = matlab.lang.makeValidName(condB);
            data_A = spmData.(fldA)(im).mat;
            data_B = spmData.(fldB)(im).mat;

            try
                spmi_t = spmList{kp}.inference(alphaHolm(kp), 'two_tailed', true, 'interp', true);

                pairFld = pairFieldName(condA, condB);
                spmResults(im).posthoc.(pairFld).clusters = spmi_t.clusters;
                spmResults(im).posthoc.(pairFld).p_holm     = pHolm(kp);
                spmResults(im).posthoc.(pairFld).alpha_holm = alphaHolm(kp);
                spmResults(im).posthoc.(pairFld).sig      = ~isempty(spmi_t.clusters);
                spmResults(im).posthoc.(pairFld).condA    = condA;
                spmResults(im).posthoc.(pairFld).condB    = condB;

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
                    spmResults(im).posthoc.(pairFld).ampInfo = ampInfo;
                end
            catch ME
                fprintf('  %s | %s vs %s error: %s\n', mLabel, condA, condB, ME.message);
            end
        end
    end

    bar_zone = max(rowIdx, 1) * (BAR_HEIGHT + BAR_GAP);
    if isfinite(y_min_plot) && isfinite(y_max_plot) && y_max_plot > y_bar_top - bar_zone - 0.01
        ylim([y_bar_top - bar_zone - 0.01, y_max_plot + 0.02]);
    end
    xlim([0 100]);
    xlabel('% cycle'); ylabel('Normalised EMG (% baseline)');
    title(mLabel, 'FontSize', 11, 'FontWeight','bold');
    valid_h = legendHandles(arrayfun(@(h) isvalid(h) && ~strcmp(h.DisplayName,''), legendHandles));
    legend(valid_h, 'Location','best', 'FontSize', 7);
    grid on; box on; hold off;
end

sgtitle('Comparison of the stimulation conditions - EMG, all pairs (SPM1D analysis)', ...
        'FontSize', 12, 'FontWeight','bold');

% -------------------------------------------------------------------------
% TABLEAU RECAPITULATIF SPM1D
% -------------------------------------------------------------------------
fprintf('\n');
fprintf('=================================================================\n');
fprintf(' SPM1D SUMMARY TABLE - EMG (all comparisons)\n');
fprintf(' RM ANOVA (N=10 participants) | Paired post-hoc | Holm-Bonferroni alpha=%.2f (%d comparisons)\n', ALPHA_FWER, N_PAIRS);
fprintf('=================================================================\n');
fprintf('%-10s  %-18s  %-28s  %-10s  %-10s  %s\n', ...
        'Muscle', 'Test', 'Comparaison', 'Debut (%)', 'Fin (%)', 'p-value');
fprintf('%s\n', repmat('-', 1, 90));

for im = 1:length(EMG_LABELS)
    res = spmResults(im);
    if res.anova_sig
        for cl = 1:length(res.anova_clusters)
            ep = res.anova_clusters{cl}.endpoints;
            pv = res.anova_clusters{cl}.P;
            fprintf('%-10s  %-18s  %-28s  %-10.1f  %-10.1f  %.4f\n', ...
                    EMG_LABELS{im}, 'ANOVA (7 cond)', '-', ep(1)-1, ep(2)-1, pv);
        end
    else
        fprintf('%-10s  %-18s  %-28s  %-10s  %-10s  %s\n', ...
                EMG_LABELS{im}, 'ANOVA (7 cond)', '-', '-', '-', 'n.s.');
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
                fprintf('%-10s  %-18s  %-28s  %-10.1f  %-10.1f  %.4f\n', ...
                        '', 't-test pairwise', compLabel, ep(1)-1, ep(2)-1, pv);
            end
        end
    end
    if res.anova_sig && ~anyPairSig
        fprintf('%-10s  %-18s  %-28s  %-10s  %-10s  %s\n', ...
                '', 't-test pairwise', sprintf('(none of the %d pairs sig.)', N_PAIRS), '-', '-', 'n.s.');
    end
    fprintf('%s\n', repmat('-', 1, 90));
end
fprintf('=================================================================\n\n');

% -------------------------------------------------------------------------
% CACHE SAVE: allows rerunning only the final figure at the
% next run (see the CACHE block at the top of the script), without rerunning all the
% non-parametric SPM1D (the slowest step).
% -------------------------------------------------------------------------
save(CACHE_FILE, 'patientMeans', 'patientBlocks', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', 'EMG_LABELS', 'X_CYCLE', 'spmResults', 'ALL_PAIRS', 'indivSigClusters', 'PATIENT_IDS', 'POSTHOC_CORRECTION');
fprintf('Cache saved: %s\n', CACHE_FILE);

% =========================================================================
% FINAL FIGURE, ALL COMPARISONS: group means only (no
% individual curves or bars), with the significant post-hoc results of
% ALL the pairs shown under each muscle plot
% (dedicated subplot, not over the curves), labelled "Cond A vs Cond B".
% =========================================================================
keepM = ismember(EMG_LABELS, REPORT_MUSCLES);   % upper trapezius removed from the figure
plotAllCompFigureEMG(patientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS, EMG_LABELS(keepM), X_CYCLE, ...
                     spmResults(keepM), ALL_PAIRS, indivSigClusters(keepM), PATIENT_IDS);

% -------------------------------------------------------------------------
% WARNINGS
% -------------------------------------------------------------------------
if ~isempty(warnings)
    disp(' '); disp('--- Warnings ---');
    for i = 1:length(warnings), disp(warnings{i}); end
end
disp(' '); disp('Done.');

% =========================================================================
% FONCTIONS LOCALES
% =========================================================================

function fld = pairFieldName(condA, condB)
    fld = matlab.lang.makeValidName(sprintf('%s_vs_%s', condA, condB));
end

function lbl = condLabel(condRaw, CONDITIONS_ORDERED, COND_LABELS)
    % Returns the standard display label (COND_LABELS) of a
    % raw condition, rather than a plain strrep('_',' ') that does not
    % respect the abbreviations (e.g. "Min PW", not "Min pulse width").
    idx = find(strcmp(CONDITIONS_ORDERED, condRaw), 1);
    if isempty(idx)
        lbl = strrep(condRaw, '_', ' ');
    else
        lbl = COND_LABELS{idx};
    end
end

function cleaned = removeFESArtifact(sig, fs, blank_ms, mad_factor, min_period_ms, max_blank_ms)
    sig = sig(:);
    n   = length(sig);
    blank_s     = round(blank_ms / 1000 * fs);
    min_dist    = round(min_period_ms / 1000 * fs);
    max_blank_s = round(max_blank_ms / 1000 * fs);

    mad_val = median(abs(sig - median(sig)));
    thresh  = mad_factor * mad_val;

    [~, locs_pos] = findpeaks( sig, 'MinPeakHeight', thresh, 'MinPeakDistance', min_dist);
    [~, locs_neg] = findpeaks(-sig, 'MinPeakHeight', thresh, 'MinPeakDistance', min_dist);
    locs = sort([locs_pos; locs_neg]);

    if length(locs) > 1
        merged = locs(1);
        for k = 2:length(locs)
            if locs(k) - merged(end) < min_dist
                merged(end) = round((merged(end) + locs(k)) / 2);
            else
                merged(end+1) = locs(k); %#ok<AGROW>
            end
        end
        locs = merged(:);
    end

    mask = true(n, 1);
    half = floor(blank_s / 2);
    for k = 1:length(locs)
        i1 = max(1, locs(k) - half);
        i2 = min(n, locs(k) + half);
        mask(i1:i2) = false;
    end

    cleaned     = sig;
    valid_idx   = find(mask);
    invalid_idx = find(~mask);
    if length(valid_idx) < 4 || isempty(invalid_idx), return; end

    breaks = [0; find(diff(invalid_idx) > 1); length(invalid_idx)];
    for b = 1:length(breaks)-1
        seg = invalid_idx(breaks(b)+1 : breaks(b+1));
        if length(seg) > max_blank_s, continue; end
        i1 = seg(1); i2 = seg(end);
        left  = valid_idx(valid_idx < i1);
        right = valid_idx(valid_idx > i2);
        if length(left) < 2 || length(right) < 2, continue; end
        left  = left(max(1,end-2):end);
        right = right(1:min(end,3));
        cleaned((i1:i2)') = interp1([left; right], sig([left; right]), (i1:i2)', 'pchip');
    end
end
