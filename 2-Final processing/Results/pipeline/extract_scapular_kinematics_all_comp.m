% =========================================================================
% extract_scapular_kinematics_all_comp.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : July 2026
% -------------------------------------------------------------------------
% Description : Scapulothoracic kinematics (YXZ sequence, 3 degrees of
%               freedom: lateral / medial rotation, protraction / retraction,
%               posterior / anterior tilt), 10 participants, 7 conditions.
%               SPM1D comparison of the conditions over the movement cycle, at
%               the group level (N = 10) and per participant (3 trials).
%               Statistics: non-parametric repeated-measures ANOVA across the
%               7 conditions (10 000 permutations), then, if significant,
%               paired t-tests on the 21 pairs of conditions with
%               Holm-Bonferroni correction (alpha = 0.05).
%               Results are saved in a cache; later runs only redraw the
%               figures (FORCE_RECOMPUTE = true to recompute).
% -------------------------------------------------------------------------
% Parameters  : Joint index: RST = 3 / LST = 8 (from DOMINANT_SIDE)
%               ALPHA_FWER = 0.05, EXCL_ELEV_THRESHOLD = 90 deg, FORCE_RECOMPUTE
% Outputs     : Per-participant and group figures, console tables,
%               cache_scapulothoracic_all_comp.mat (used by
%               extract_scapulohumeral_rhythm_all_comp.m)
% -------------------------------------------------------------------------
% Dependencies: usercommands_conditions.m, K-LAB .mat files, helpers/,
%               plotting/plotAllCompFigure.m, spm1dmatlab-master/
% References  : Pataky TC (2010), J Biomech 43:1976-1982
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' extract_scapular_kinematics_all_comp.m');
disp('=========================================');
disp(' ');

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
CACHE_FILE = fullfile(dataDir(), 'cache_scapulothoracic_all_comp.mat');

% Post-hoc correction method: saved in the cache, a cache
% computed with another correction (e.g. former Bonferroni) or without exclusion
% zone (EXCL_ZONE) is ignored and everything is recomputed.
POSTHOC_CORRECTION = 'holm';

cacheValid = false;
cachedCorrection = '';
cacheHasZone = false;
if isfile(CACHE_FILE) && ~FORCE_RECOMPUTE
    try
        cacheInfo    = whos('-file', CACHE_FILE);
        cacheVars    = {cacheInfo.name};
        cacheHasZone = ismember('EXCL_ZONE', cacheVars);
        flagVars     = intersect({'POSTHOC_CORRECTION'}, cacheVars);
        S_check      = struct();
        if ~isempty(flagVars), S_check = load(CACHE_FILE, flagVars{:}); end
        if isfield(S_check, 'POSTHOC_CORRECTION')
            cachedCorrection = S_check.POSTHOC_CORRECTION;
        end
    catch
    end
    cacheValid = strcmp(cachedCorrection, POSTHOC_CORRECTION) && cacheHasZone;
end

if cacheValid
    fprintf('Cache found: %s\n', CACHE_FILE);
    fprintf('-> Fast regeneration of the final figure (no SPM1D recomputation).\n');
    fprintf('  (set FORCE_RECOMPUTE=true in the script to recompute everything)\n\n');
    load(CACHE_FILE, 'patientMeans', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', 'DOF_LABELS', 'x', 'spmResults', 'ALL_PAIRS', 'indivSigClusters', 'PATIENT_IDS', 'EXCL_ZONE');

    plotAllCompFigure(patientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS, DOF_LABELS, 'Scapular kinematics', x, ...
                       spmResults, ALL_PAIRS, indivSigClusters, PATIENT_IDS, EXCL_ZONE);
    return;
elseif isfile(CACHE_FILE) && ~FORCE_RECOMPUTE
    fprintf('Cache found but outdated (correction "%s" -> "%s", exclusion zone present: %d): full recomputation.\n\n', ...
            cachedCorrection, POSTHOC_CORRECTION, cacheHasZone);
end

% -------------------------------------------------------------------------
% CHARGEMENT CONFIGURATION
% -------------------------------------------------------------------------
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'usercommands_conditions.m'));

% SPM1D already added to the path above (before the cache fast path)
rng(0);  % reproducibility of the non-parametric tests (Monte Carlo permutations)

% -------------------------------------------------------------------------
% DISPLAY PARAMETERS
% -------------------------------------------------------------------------
x = 0:100; % normalised cycle axis (101 points)

CONDITIONS_ORDERED = {'No FES','Min_fatigue','Min_stress','Random','Min_pulse_width','Rehab','Min_force'};
% Display labels for the legends (underscore to space)
COND_LABELS = {'No FES','Min fatigue','Min stress','Random','Min PW','Rehab','Min force'};
COLORS = [0.35 0.20 0.29;   % No FES:      aubergine
          0.66 0.80 0.63;   % Min_fatigue: sage green
          0.30 0.47 0.46;   % Min_stress:  dark teal
          0.91 0.76 0.45;   % Random:      golden yellow
          0.89 0.63 0.33;   % Min_pulse_width (Min PW): orange
          0.45 0.55 0.68;   % Rehab:       blue-grey (matches the palette)
          0.75 0.35 0.35];  % Min_force:   salmon red

% Storage order in the .mat (ComputeKinematics.m, YXZ sequence):
%   dim 1 = X = Lateral/medial rotation           (Euler(:,2,:))
%   dim 2 = Y = Protraction/retraction            (Euler(:,1,:))
%   dim 3 = Z = Posterior/anterior tilt           (Euler(:,3,:))
DOF_LABELS = {'Lateral (-) / medial (+) rotation', 'Protraction (+) / retraction (-)', 'Posterior (+) / anterior (-) tilt'};
DOF_SHORT  = {'X (Rot lat/med)', 'Y (Pro/Ret)', 'Z (Basc post/ant)'};

warnings = {};

% Zone of non-interpretability: part of the cycle where the humerothoracic
% elevation exceeds this threshold (vertical grey band on the figures,
% statistics unchanged). Group: mean curve of the 10 participants;
% individual figures: curve of the participant.
EXCL_ELEV_THRESHOLD = 90;  % deg
htPatientMeans = {};       % one (1,101) vector per participant, all conditions together

% -------------------------------------------------------------------------
% ALL THE PAIRS OF CONDITIONS (C(7,2) = 21)
% -------------------------------------------------------------------------
ALL_PAIRS = {};
for a = 1:length(CONDITIONS_ORDERED)-1
    for b = a+1:length(CONDITIONS_ORDERED)
        ALL_PAIRS(end+1, :) = {CONDITIONS_ORDERED{a}, CONDITIONS_ORDERED{b}}; %#ok<AGROW>
    end
end
N_PAIRS       = size(ALL_PAIRS, 1);
ALPHA_FWER    = 0.05;  % Holm-Bonferroni: threshold alpha/(m-k+1) per pair (helpers/holmAlphaSPM1D.m)
PAIR_BAR_COLOR = [0.35 0.35 0.35];  % single neutral colour (no more "vs reference")

% Global accumulator: globalData.(condName) = cell array of (3,101) vectors, one per trial
% Used for the global figure (display).
globalData = struct();
for ic = 1:length(CONDITIONS_ORDERED)
    globalData.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic})) = {};
end

% SPM accumulator: patientMeans.(condName) = cell array, one (3,101) vector PER PARTICIPANT
% (mean of the 3 valid blocks), so N = 10 independent observations for the ANOVA
patientMeans = struct();
for ic = 1:length(CONDITIONS_ORDERED)
    patientMeans.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic})) = {};
end

% Accumulator for the final figure: individual significant clusters
% indivSigClusters{idof}.(pairFld){ip} = spmi_t_pt.clusters (empty cell if n.s.)
indivSigClusters = cell(3,1);
for idof_i = 1:3
    indivSigClusters{idof_i} = struct();
    for kp = 1:N_PAIRS
        fld = pairFieldName(ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2});
        indivSigClusters{idof_i}.(fld) = cell(length(PATIENT_IDS), 1);
    end
end

% -------------------------------------------------------------------------
% BOUCLE PATIENTS
% -------------------------------------------------------------------------
for ip = 1:length(PATIENT_IDS)

    patientID = PATIENT_IDS{ip};
    side      = DOMINANT_SIDE(patientID);
    jscap     = SCAPULA_JOINT_IDX(side);
    cycleKey  = 'rcycle';
    if strcmp(side, 'L'), cycleKey = 'lcycle'; end
    jht = HUMEROTHORACIC_JOINT_IDX(side);  % humerothoracic elevation (exclusion zone)

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

    % --- Accumulation of the trials per condition ---
    % condData.(condName): cell array of (3 x 101) matrices, one per valid trial
    condData = struct();
    for ic = 1:length(CONDITIONS_ORDERED)
        condData.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic})) = {};
    end

    % Reads missingCondPositions (P007: No FES block 1 missing)
    missingCondPos = [];
    if isfield(PATIENT_EXCEPTIONS, patientID) && ...
       isfield(PATIENT_EXCEPTIONS.(patientID), 'missingCondPositions')
        missingCondPos = PATIENT_EXCEPTIONS.(patientID).missingCondPositions;
    end

    htTrials = {};  % humerothoracic elevation (1,101) per valid trial

    % Loop on the condition positions (1 to nCond)
    trialIdx = 0;
    for iseq = 1:nCond

        cond = condList.condition{iseq};

        if ismember(iseq, missingCondPos)
            warnings{end+1} = sprintf('[WARNING] %s condition %d (%s): no trial available', patientID, iseq, cond);
            continue;
        end

        trialIdx = trialIdx + 1;
        if trialIdx > nTrials
            warnings{end+1} = sprintf('[WARNING] %s: no more trials at condition %d (%s)', patientID, iseq, cond);
            break;
        end

        itrial = analyticTrials(trialIdx);
        data   = extractScapulaMean(Trial(itrial), jscap, cycleKey);

        if isempty(data)
            warnings{end+1} = sprintf('[WARNING] %s trial %d -> cond %d (%s): kinematics missing', patientID, trialIdx, iseq, cond);
            continue;
        end

        fld = matlab.lang.makeValidName(cond);
        condData.(fld){end+1} = data; % (3, 101)
        globalData.(fld){end+1} = data; % accumulation across participants

        ht = extractHTElevation(Trial(itrial), jht, cycleKey);
        if ~isempty(ht), htTrials{end+1} = ht; end %#ok<AGROW>
    end

    % --- Exclusion zone of the participant (HT elevation > threshold) ---
    if isempty(htTrials)
        htPatientMeans{end+1} = NaN(1, 101); %#ok<AGROW>
        warnings{end+1} = sprintf('[WARNING] %s: humerothoracic elevation missing (no exclusion zone)', patientID);
    else
        htPatientMeans{end+1} = nanmean(cat(1, htTrials{:}), 1); %#ok<AGROW>
    end
    zonePt = computeExclusionZone(htPatientMeans{end}, x, EXCL_ELEV_THRESHOLD);

    % --- Mean of the blocks per condition for SPM (one row per participant) ---
    for ic = 1:length(CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        trials_cond = condData.(fld);
        if isempty(trials_cond)
            patientMeans.(fld){end+1} = NaN(3, 101);
        else
            stack_pt = cat(3, trials_cond{:}); % (3,101,n_blocks)
            patientMeans.(fld){end+1} = nanmean(stack_pt, 3); % (3,101)
        end
    end

    % --- Participant figure ---
    fig = figure('Name', patientID, ...
                 'units', 'normalized', 'outerposition', [0 0 1 1], 'Color', 'white');

    for idof = 1:3
        subplot(1, 3, idof);
        hold on;
        drawExclusionZone(gca, zonePt);

        legendHandles = gobjects(length(CONDITIONS_ORDERED), 1);

        for ic = 1:length(CONDITIONS_ORDERED)
            cond = CONDITIONS_ORDERED{ic};
            fld  = matlab.lang.makeValidName(cond);
            trials_cond = condData.(fld);

            if isempty(trials_cond), continue; end

            stack = cat(3, trials_cond{:}); % (3, 101, n)
            meanCurve = nanmean(stack(idof, :, :), 3); % (1, 101)
            stdCurve  = nanstd(stack(idof, :, :), 0, 3);

            fill([x fliplr(x)], [meanCurve+stdCurve fliplr(meanCurve-stdCurve)], ...
                 COLORS(ic,:), 'FaceAlpha', 0.12, 'EdgeColor', 'none', 'HandleVisibility','off');
            legendHandles(ic) = plot(x, meanCurve, ...
                'Color',     COLORS(ic,:), ...
                'LineWidth', 2, ...
                'DisplayName', COND_LABELS{ic});
        end

        xlabel('% cycle');
        ylabel('Angle (°)');
        title(DOF_LABELS{idof});
        legend(legendHandles(arrayfun(@(h) isvalid(h) && ~strcmp(h.DisplayName,''), legendHandles)), ...
               'Location', 'best', 'FontSize', 8);
        grid on;
        box on;
        hold off;
    end

    sgtitle(sprintf('Comparison of the stimulation conditions: %s (side %s)', patientID, side), ...
            'FontSize', 13, 'FontWeight', 'bold');

    % --- Participant SPM1D figure (N = 3 blocks per condition) ---
    fprintf('\n=== Individual kinematic SPM1D (all comparisons): %s ===\n', patientID);
    figure('Name', [patientID ' - SPM1D Kin (all comp)'], 'units','normalized','outerposition',[0 0 1 1],'Color','white');

    % Storage of the individual post-hoc results (for the participant summary table)
    patientSpmResults = struct();
    for idof_init = 1:3
        patientSpmResults(idof_init).posthoc = struct();
    end

    for idof = 1:3
        subplot(1, 3, idof);
        hold on;
        drawExclusionZone(gca, zonePt);
        legendHandles_spm = gobjects(length(CONDITIONS_ORDERED), 1);
        y_min_pt = Inf; y_max_pt = -Inf;

        for ic = 1:length(CONDITIONS_ORDERED)
            cond = CONDITIONS_ORDERED{ic};
            fld  = matlab.lang.makeValidName(cond);
            trials_cond = condData.(fld);
            if isempty(trials_cond), continue; end
            stack = cat(3, trials_cond{:}); % (3, 101, n_blocks)
            mc = squeeze(nanmean(stack(idof,:,:), 3));  % (1,101)
            sc = squeeze(nanstd(stack(idof,:,:), 0, 3));
            fill([x fliplr(x)], [mc+sc fliplr(mc-sc)], ...
                 COLORS(ic,:), 'FaceAlpha', 0.12, 'EdgeColor','none','HandleVisibility','off');
            legendHandles_spm(ic) = plot(x, mc, 'Color', COLORS(ic,:), 'LineWidth', 2, ...
                                         'DisplayName', COND_LABELS{ic});
            y_min_pt = min(y_min_pt, min(mc-sc));
            y_max_pt = max(y_max_pt, max(mc+sc));
        end

        % Builds the matrices (n_blocks x 101) for the RM ANOVA: balanced design
        % Target: 3 blocks per condition. If a condition has only 2,
        % the last block is duplicated (with a console warning).
        N_TARGET = 3;

        condData_padded = condData;
        for ic = 1:length(CONDITIONS_ORDERED)
            fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
            n_blocs = length(condData_padded.(fld));
            if n_blocs > 0 && n_blocs < N_TARGET && idof == 1
                fprintf('  [WARN] %s - %s: only %d blocks -> last block duplicated\n', ...
                        patientID, CONDITIONS_ORDERED{ic}, n_blocs);
            end
            while length(condData_padded.(fld)) < N_TARGET && ~isempty(condData_padded.(fld))
                condData_padded.(fld){end+1} = condData_padded.(fld){end};
            end
        end

        all_mat_pt = []; group_vec_pt = []; subj_vec_pt = [];
        for ic = 1:length(CONDITIONS_ORDERED)
            fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
            trials_cond = condData_padded.(fld);
            if isempty(trials_cond), continue; end
            mat_ic = zeros(N_TARGET, 101);
            for kb = 1:N_TARGET
                mat_ic(kb,:) = trials_cond{kb}(idof,:);
            end
            all_mat_pt   = [all_mat_pt;   mat_ic];
            group_vec_pt = [group_vec_pt; repmat(ic, N_TARGET, 1)];
            subj_vec_pt  = [subj_vec_pt;  (1:N_TARGET)'];
        end
        n_min = N_TARGET;

        bar_h_pt     = 0.3;
        bar_gap_pt   = 0.1;
        y_bar_top_pt = y_min_pt - 0.5;
        anova_sig_pt = false;

        if length(unique(group_vec_pt)) >= 2
            try
                warning('off', 'all');
                spm_F_pt  = spm1d.stats.nonparam.anova1rm(all_mat_pt, group_vec_pt, subj_vec_pt);
                warning('on', 'all');
                spmi_F_pt = spm_F_pt.inference(0.05, 'iterations', 10000, 'interp', true);
                anova_sig_pt = ~isempty(spmi_F_pt.clusters);
            catch ME_anova
                warning('on', 'all');
                fprintf('  DOF %d - ANOVA error: %s\n', idof, ME_anova.message);
            end
        end

        rowIdx_pt = 0;
        if anova_sig_pt && n_min < 3
            fprintf('  DOF %d (%s) - ANOVA: SIGNIFICANT but post-hoc skipped (df=%d, N=%d insufficient for RFT)\n', ...
                    idof, DOF_LABELS{idof}, n_min-1, n_min);
        elseif anova_sig_pt
            fprintf('  DOF %d (%s) - ANOVA: SIGNIFICANT -> post-hoc (%d pairs tested)\n', idof, DOF_LABELS{idof}, N_PAIRS);
            % Pass 1: SPM{t} of each tested pair; pass 2: inference at the
            % Holm-Bonferroni threshold of each pair (helpers/holmAlphaSPM1D.m)
            spmList_pt = cell(1, N_PAIRS);
            dataA_pt   = cell(1, N_PAIRS);
            dataB_pt   = cell(1, N_PAIRS);
            for kp = 1:N_PAIRS
                condA = ALL_PAIRS{kp,1}; condB = ALL_PAIRS{kp,2};
                fldA = matlab.lang.makeValidName(condA);
                fldB = matlab.lang.makeValidName(condB);
                if isempty(condData_padded.(fldA)) || isempty(condData_padded.(fldB)), continue; end
                trials_A = condData_padded.(fldA);
                trials_B = condData_padded.(fldB);
                data_A_mat = zeros(N_TARGET, 101);
                data_B_mat = zeros(N_TARGET, 101);
                for kb = 1:N_TARGET
                    data_A_mat(kb,:) = trials_A{kb}(idof,:);
                    data_B_mat(kb,:) = trials_B{kb}(idof,:);
                end
                dataA_pt{kp} = data_A_mat;
                dataB_pt{kp} = data_B_mat;
                try
                    spmList_pt{kp} = spm1d.stats.ttest_paired(data_B_mat, data_A_mat);
                catch ME_ph
                    fprintf('    %s vs %s: error - %s\n', condA, condB, ME_ph.message);
                end
            end
            [alphaHolm_pt, pHolm_pt] = holmAlphaSPM1D(spmList_pt, ALPHA_FWER);

            for kp = 1:N_PAIRS
                if isempty(spmList_pt{kp}), continue; end
                condA = ALL_PAIRS{kp,1}; condB = ALL_PAIRS{kp,2};
                data_A_mat = dataA_pt{kp};
                data_B_mat = dataB_pt{kp};
                try
                    spmi_t_pt = spmList_pt{kp}.inference(alphaHolm_pt(kp), 'two_tailed', true, 'interp', true);
                    if ~isempty(spmi_t_pt.clusters)
                        rowIdx_pt = rowIdx_pt + 1;
                        fprintf('    %s vs %s: SIGNIFICANT (%d cluster(s), Holm p=%.5f < alpha=%.5f)\n', ...
                                condLabel(condA, CONDITIONS_ORDERED, COND_LABELS), condLabel(condB, CONDITIONS_ORDERED, COND_LABELS), ...
                                length(spmi_t_pt.clusters), pHolm_pt(kp), alphaHolm_pt(kp));
                        y_bar_pt = y_bar_top_pt - (rowIdx_pt-1) * (bar_h_pt + bar_gap_pt);
                        mc_B_full = mean(data_B_mat, 1);
                        mc_A_full = mean(data_A_mat, 1);
                        clusterInfo_pt = struct('ep', {}, 'pv', {}, 'range_fes', {}, 'range_ref', {}, 'diff_mean', {});
                        for cl = 1:length(spmi_t_pt.clusters)
                            ep = spmi_t_pt.clusters{cl}.endpoints;
                            rectangle('Position', [ep(1)-1, y_bar_pt, ep(2)-ep(1), bar_h_pt], ...
                                      'FaceColor', PAIR_BAR_COLOR, 'EdgeColor','none','FaceAlpha',0.85);
                            idx1 = max(1, round(ep(1))); idx2 = min(101, round(ep(2)));
                            seg_B = mc_B_full(idx1:idx2);
                            seg_A = mc_A_full(idx1:idx2);
                            clusterInfo_pt(cl).ep        = ep;
                            clusterInfo_pt(cl).pv        = spmi_t_pt.clusters{cl}.P;
                            clusterInfo_pt(cl).range_fes = [min(seg_B) max(seg_B)];
                            clusterInfo_pt(cl).range_ref = [min(seg_A) max(seg_A)];
                            clusterInfo_pt(cl).diff_mean = mean(seg_B) - mean(seg_A);
                        end
                        pairFld = pairFieldName(condA, condB);
                        patientSpmResults(idof).posthoc.(pairFld).clusterInfo = clusterInfo_pt;
                        patientSpmResults(idof).posthoc.(pairFld).condA = condA;
                        patientSpmResults(idof).posthoc.(pairFld).condB = condB;
                        indivSigClusters{idof}.(pairFld){ip} = spmi_t_pt.clusters;
                    end
                catch ME_ph
                    fprintf('    %s vs %s: error - %s\n', condA, condB, ME_ph.message);
                end
            end
            if rowIdx_pt == 0
                fprintf('    (no significant pair - RFT + Holm-Bonferroni alpha=%.2f on %d comparisons)\n', ALPHA_FWER, N_PAIRS);
            end
        else
            fprintf('  DOF %d (%s) - ANOVA: not significant\n', idof, DOF_LABELS{idof});
        end

        bar_zone_pt = max(rowIdx_pt, 1) * (bar_h_pt + bar_gap_pt);
        if isfinite(y_min_pt)
            ylim([y_min_pt - bar_zone_pt - 1, y_max_pt + 1]);
        end

        xlabel('% cycle');
        ylabel('Angle (°)');
        title(DOF_LABELS{idof});
        valid_h = legendHandles_spm(arrayfun(@(h) isvalid(h) && ~strcmp(h.DisplayName,''), legendHandles_spm));
        legend(valid_h, 'Location','best', 'FontSize', 8);
        grid on; box on; hold off;
    end

    sgtitle(sprintf('%s  -  Individual kinematic SPM1D, all comparisons (N = 3 blocks)', patientID), ...
            'FontSize', 13, 'FontWeight', 'bold');

    % --- Individual summary table: significant % of cycle <-> angular value ---
    fprintf('\n  --- Individual summary table (%s): significant cluster -> angular value ---\n', patientID);
    fprintf('  %-16s  %-28s  %-9s  %-9s  %-8s  %-16s  %-16s  %s\n', ...
            'DOF', 'Comparaison', 'Debut(%)', 'Fin(%)', 'p-value', 'Angle B (°)', 'Angle A (°)', 'Diff (°)');
    anyRow_pt = false;
    for idof = 1:3
        for kp = 1:N_PAIRS
            pairFld = pairFieldName(ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2});
            if ~isfield(patientSpmResults(idof).posthoc, pairFld), continue; end
            ph = patientSpmResults(idof).posthoc.(pairFld);
            if ~isfield(ph, 'clusterInfo') || isempty(ph.clusterInfo), continue; end
            compLabel = sprintf('%s vs %s', condLabel(ph.condA, CONDITIONS_ORDERED, COND_LABELS), condLabel(ph.condB, CONDITIONS_ORDERED, COND_LABELS));
            for cl = 1:length(ph.clusterInfo)
                ci = ph.clusterInfo(cl);
                fprintf('  %-16s  %-28s  %-9.1f  %-9.1f  %-8.4f  %-16s  %-16s  %.1f\n', ...
                        DOF_SHORT{idof}, compLabel, ci.ep(1)-1, ci.ep(2)-1, ci.pv, ...
                        rangeStr(ci.range_fes), rangeStr(ci.range_ref), ci.diff_mean);
                anyRow_pt = true;
            end
        end
    end
    if ~anyRow_pt
        fprintf('  (no significant post-hoc for %s)\n', patientID);
    end

end % ip

% =========================================================================
% GROUP EXCLUSION ZONE: mean humerothoracic elevation (10 participants,
% all conditions) > EXCL_ELEV_THRESHOLD
% =========================================================================
htGroupMean = nanmean(cat(1, htPatientMeans{:}), 1);  % (1,101)
EXCL_ZONE   = computeExclusionZone(htGroupMean, x, EXCL_ELEV_THRESHOLD);
fprintf('\n=== Exclusion zone (mean humerothoracic elevation > %g°) ===\n', EXCL_ELEV_THRESHOLD);
[htMax, iHtMax] = max(htGroupMean);
fprintf('  Maximum mean HT elevation: %.1f° at %d %% of the cycle\n', htMax, x(iHtMax));
if isempty(EXCL_ZONE.windows)
    fprintf('  (threshold never exceeded: no grey zone)\n');
end
for kz = 1:size(EXCL_ZONE.windows, 1)
    fprintf('  Zone %d: %.1f %% -> %.1f %% of the cycle\n', kz, EXCL_ZONE.windows(kz,1), EXCL_ZONE.windows(kz,2));
end

% =========================================================================
% GLOBAL FIGURE: mean cycle across participants (P1-P10), 3 DOF, 7 conditions
% =========================================================================
figure('Name', 'Global -- Mean scapular cycle P1-P10 (all comp)', ...
       'units','normalized','outerposition',[0 0 1 1], 'Color','white');

for idof = 1:3
    subplot(1, 3, idof);
    hold on;
    drawExclusionZone(gca, EXCL_ZONE);
    legendHandles = gobjects(length(CONDITIONS_ORDERED), 1);

    for ic = 1:length(CONDITIONS_ORDERED)
        cond = CONDITIONS_ORDERED{ic};
        fld  = matlab.lang.makeValidName(cond);
        pts  = globalData.(fld);
        if isempty(pts), continue; end

        stack     = cat(3, pts{:});
        meanCurve = nanmean(stack(idof,:,:), 3);   % (1,101)
        stdCurve  = nanstd(stack(idof,:,:), 0, 3); % (1,101)

        fill([x fliplr(x)], [meanCurve+stdCurve fliplr(meanCurve-stdCurve)], ...
             COLORS(ic,:), 'FaceAlpha', 0.12, 'EdgeColor', 'none', 'HandleVisibility','off');

        legendHandles(ic) = plot(x, meanCurve, ...
            'Color', COLORS(ic,:), 'LineWidth', 2, 'DisplayName', COND_LABELS{ic});
    end

    xlabel('% cycle'); ylabel('Angle (°)');
    title(DOF_LABELS{idof});
    valid_h = legendHandles(arrayfun(@(h) isvalid(h) && ~strcmp(h.DisplayName,''), legendHandles));
    legend(valid_h, 'Location','best', 'FontSize', 8);
    grid on; box on; hold off;
end

sgtitle('Comparison of the stimulation conditions for all the participants', ...
        'FontSize', 13, 'FontWeight', 'bold');

% =========================================================================
% SPM1D ANALYSIS: RM ANOVA on 7 conditions + post-hoc on ALL the pairs
%
% Design: within-subject repeated measures (same 10 participants in each condition)
%   - One row per participant = mean of its valid blocks, so N = 10
%   - ANOVA: spm1d.stats.nonparam.anova1rm (repeated-measures one-way ANOVA,
%     permutation-based, Monte Carlo, 10000 iterations)
%   - Post-hoc: spm1d.stats.ttest_paired (paired t-test, same participants,
%     remains parametric) on the 21 possible pairs of conditions
%   - Holm-Bonferroni correction on the 21 post-hoc comparisons (FWER
%     alpha = 0.05): the k-th smallest p-value is compared with
%     alpha/(m-k+1), stopping at the first non-rejected one (helpers/holmAlphaSPM1D.m)
% =========================================================================

% Prepares the matrices (N_participants x 101) per condition and per DOF
% One row = mean of the valid blocks of ONE participant
spmData = struct();
for ic = 1:length(CONDITIONS_ORDERED)
    fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
    pts = patientMeans.(fld);
    if isempty(pts)
        spmData.(fld) = [];
        continue;
    end
    stack = cat(3, pts{:});   % (3, 101, N_patients)
    for idof = 1:3
        mat = squeeze(stack(idof,:,:))';  % (N_patients, 101)
        spmData.(fld)(idof).mat = mat;
    end
end

% -------------------------------------------------------------------------
% CHOIX DES TESTS STATISTIQUES
% -------------------------------------------------------------------------
fprintf('\n=== Choice of the statistical tests ===\n');
fprintf('  Design        : within-subject repeated measures (10 participants x 7 conditions)\n');
fprintf('  Independence  : 1 mean per participant per condition (3 averaged blocks)\n');
fprintf('  Omnibus test  : one-way non-parametric RM ANOVA (spm1d.stats.nonparam.anova1rm, Monte Carlo 10000 iterations)\n');
fprintf('                  -> controls the inter-individual variability\n');
fprintf('  Post-hoc      : paired t-test on each of the %d pairs of conditions (spm1d.stats.ttest_paired, parametric)\n', N_PAIRS);
fprintf('                  -> same participants in the two compared conditions\n');
fprintf('  Correction    : Holm-Bonferroni on %d post-hoc comparisons (FWER alpha = %.2f;\n', N_PAIRS, ALPHA_FWER);
fprintf('                  thresholds from alpha/%d = %.5f to alpha/1 = %.2f according to the rank of the p-value)\n', N_PAIRS, ALPHA_FWER/N_PAIRS, ALPHA_FWER);
fprintf('  Grey zone     : humerothoracic elevation > %g° (visual only, statistics on the whole cycle)\n', EXCL_ELEV_THRESHOLD);
fprintf('  Temporal      : Random Field Theory with SPM1D (Pataky 2010)\n');
fprintf('  Parametric    : N=10, robustness of the RM ANOVA to moderate deviations\n');
fprintf('                  from normality accepted (standard in clinical biomechanics)\n');
fprintf('%s\n', repmat('-', 1, 55));

% Storage structure of the results for the summary table
spmResults = struct();
for idof = 1:3
    spmResults(idof).dof_label  = DOF_LABELS{idof};
    spmResults(idof).anova_sig  = false;
    spmResults(idof).anova_clusters = {};
    spmResults(idof).posthoc    = struct();
end

% SPM figure (curves + stacked bars for the significant pairs only)
figure('Name', 'SPM1D -- Scapular kinematics -- ANOVA + post-hoc on all pairs', ...
       'units','normalized','outerposition',[0 0 1 1], 'Color','white');

for idof = 1:3
    ax = subplot(1, 3, idof);
    hold on;
    drawExclusionZone(ax, EXCL_ZONE);

    % --- Draws the mean curves (same look as the global figure) ---
    legendHandles = gobjects(length(CONDITIONS_ORDERED), 1);
    y_min_plot = Inf; y_max_plot = -Inf;
    for ic = 1:length(CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        if isempty(spmData.(fld)), continue; end
        mat = spmData.(fld)(idof).mat;
        mc  = nanmean(mat, 1);
        sc  = nanstd(mat,  0, 1);
        fill([x fliplr(x)], [mc+sc fliplr(mc-sc)], COLORS(ic,:), ...
             'FaceAlpha', 0.10, 'EdgeColor', 'none', 'HandleVisibility','off');
        legendHandles(ic) = plot(x, mc, 'Color', COLORS(ic,:), 'LineWidth', 2, ...
                                 'DisplayName', COND_LABELS{ic});
        y_min_plot = min(y_min_plot, min(mc-sc));
        y_max_plot = max(y_max_plot, max(mc+sc));
    end

    BAR_HEIGHT = 0.8;
    BAR_GAP    = 0.3;
    y_bar_top  = y_min_plot - 1;

    % --- ANOVA SPM1D RM : 7 conditions (repeated measures) ---
    all_mat   = [];
    group_vec = [];
    subj_vec  = [];
    for ic = 1:length(CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        if isempty(spmData.(fld)), continue; end
        mat = spmData.(fld)(idof).mat;  % (N_patients, 101)
        n   = size(mat, 1);
        all_mat   = [all_mat;   mat];
        group_vec = [group_vec; repmat(ic, n, 1)];
        subj_vec  = [subj_vec;  (1:n)'];  % participant identifiers 1..N
    end

    anova_sig = false;
    if length(unique(group_vec)) >= 2
        try
            spm_F  = spm1d.stats.nonparam.anova1rm(all_mat, group_vec, subj_vec);
            spmi_F = spm_F.inference(0.05, 'iterations', 10000, 'interp', true);
            anova_sig = ~isempty(spmi_F.clusters);
            spmResults(idof).anova_sig      = anova_sig;
            spmResults(idof).anova_clusters = spmi_F.clusters;
            if anova_sig, sig_str = 'SIGNIFICANT'; else, sig_str = 'not significant'; end
            fprintf('DOF %d ANOVA: %s\n', idof, sig_str);
        catch ME
            fprintf('DOF %d ANOVA error: %s\n', idof, ME.message);
        end
    end

    % --- Post-hoc: all the pairs (if the ANOVA is significant) ---
    rowIdx = 0;
    if anova_sig
        % Pass 1: SPM{t} of each tested pair; pass 2: inference at the
        % Holm-Bonferroni threshold of each pair
        spmList = cell(1, N_PAIRS);
        for kp = 1:N_PAIRS
            fldA = matlab.lang.makeValidName(ALL_PAIRS{kp,1});
            fldB = matlab.lang.makeValidName(ALL_PAIRS{kp,2});
            if isempty(spmData.(fldA)) || isempty(spmData.(fldB)), continue; end
            try
                spmList{kp} = spm1d.stats.ttest_paired(spmData.(fldB)(idof).mat, spmData.(fldA)(idof).mat);
            catch ME
                fprintf('  DOF %d | %s vs %s error: %s\n', idof, ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}, ME.message);
            end
        end
        [alphaHolm, pHolm] = holmAlphaSPM1D(spmList, ALPHA_FWER);

        for kp = 1:N_PAIRS
            if isempty(spmList{kp}), continue; end
            condA = ALL_PAIRS{kp,1}; condB = ALL_PAIRS{kp,2};
            fldA = matlab.lang.makeValidName(condA);
            fldB = matlab.lang.makeValidName(condB);
            data_A = spmData.(fldA)(idof).mat;
            data_B = spmData.(fldB)(idof).mat;

            try
                spmi_t = spmList{kp}.inference(alphaHolm(kp), 'two_tailed', true, 'interp', true);

                pairFld = pairFieldName(condA, condB);
                spmResults(idof).posthoc.(pairFld).clusters = spmi_t.clusters;
                spmResults(idof).posthoc.(pairFld).p_holm     = pHolm(kp);
                spmResults(idof).posthoc.(pairFld).alpha_holm = alphaHolm(kp);
                spmResults(idof).posthoc.(pairFld).sig      = ~isempty(spmi_t.clusters);
                spmResults(idof).posthoc.(pairFld).condA    = condA;
                spmResults(idof).posthoc.(pairFld).condB    = condB;

                if ~isempty(spmi_t.clusters)
                    rowIdx = rowIdx + 1;
                    y_bar = y_bar_top - (rowIdx-1) * (BAR_HEIGHT + BAR_GAP);
                    mc_B_full = nanmean(data_B, 1);
                    mc_A_full = nanmean(data_A, 1);
                    clusterInfo = struct('range_fes', {}, 'range_ref', {}, 'diff_mean', {});
                    for cl = 1:length(spmi_t.clusters)
                        ep = spmi_t.clusters{cl}.endpoints;
                        rectangle('Position', [ep(1)-1, y_bar, ep(2)-ep(1), BAR_HEIGHT], ...
                                  'FaceColor', PAIR_BAR_COLOR, ...
                                  'EdgeColor', 'none', 'FaceAlpha', 0.85);
                        idx1 = max(1, round(ep(1))); idx2 = min(101, round(ep(2)));
                        seg_B = mc_B_full(idx1:idx2);
                        seg_A = mc_A_full(idx1:idx2);
                        clusterInfo(cl).range_fes = [min(seg_B) max(seg_B)];
                        clusterInfo(cl).range_ref = [min(seg_A) max(seg_A)];
                        clusterInfo(cl).diff_mean = mean(seg_B) - mean(seg_A);
                    end
                    spmResults(idof).posthoc.(pairFld).angleInfo = clusterInfo;
                end
            catch ME
                fprintf('  DOF %d | %s vs %s error: %s\n', idof, condA, condB, ME.message);
            end
        end
    end

    bar_zone = max(rowIdx, 1) * (BAR_HEIGHT + BAR_GAP);

    % Axes
    ylim([y_bar_top - bar_zone - 0.5,  y_max_plot + 1]);
    xlim([0 100]);
    xlabel('% cycle'); ylabel('Angle (°)');
    title(DOF_LABELS{idof});
    valid_h = legendHandles(arrayfun(@(h) isvalid(h) && ~strcmp(h.DisplayName,''), legendHandles));
    legend(valid_h, 'Location','best', 'FontSize', 7);
    grid on; box on; hold off;
end

sgtitle('Comparison of the stimulation conditions - all pairs (SPM1D analysis)', ...
        'FontSize', 12, 'FontWeight', 'bold');

% -------------------------------------------------------------------------
% TABLEAU RECAPITULATIF SPM1D
% -------------------------------------------------------------------------
fprintf('\n');
fprintf('=================================================================\n');
fprintf(' SPM1D SUMMARY TABLE - Scapular kinematics (all comparisons)\n');
fprintf(' RM ANOVA (N=10 participants) | Paired post-hoc | Holm-Bonferroni alpha=%.2f (%d comparisons)\n', ALPHA_FWER, N_PAIRS);
fprintf('=================================================================\n');
fprintf('%-20s  %-18s  %-28s  %-10s  %-10s  %-9s  %-16s  %-16s  %s\n', ...
        'DOF', 'Test', 'Comparaison', 'Debut (%)', 'Fin (%)', 'p-value', 'Angle B (°)', 'Angle A (°)', 'Diff (°)');
fprintf('%s\n', repmat('-', 1, 135));

for idof = 1:3
    res = spmResults(idof);

    % --- ANOVA ---
    if res.anova_sig
        for cl = 1:length(res.anova_clusters)
            ep  = res.anova_clusters{cl}.endpoints;
            pv  = res.anova_clusters{cl}.P;
            x1c = (ep(1)-1);
            x2c = (ep(2)-1);
            fprintf('%-20s  %-18s  %-28s  %-10.1f  %-10.1f  %-9.4f  %-16s  %-16s  %s\n', ...
                    DOF_SHORT{idof}, 'ANOVA (7 cond)', '-', x1c, x2c, pv, '-', '-', '-');
        end
    else
        fprintf('%-20s  %-18s  %-28s  %-10s  %-10s  %-9s  %-16s  %-16s  %s\n', ...
                DOF_SHORT{idof}, 'ANOVA (7 cond)', '-', '-', '-', 'n.s.', '-', '-', '-');
    end

    % --- Post-hoc: significant pairs only ---
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
                ep  = ph.clusters{cl}.endpoints;
                pv  = ph.clusters{cl}.P;
                x1c = (ep(1)-1);
                x2c = (ep(2)-1);
                ai  = ph.angleInfo(cl);
                fprintf('%-20s  %-18s  %-28s  %-10.1f  %-10.1f  %-9.4f  %-16s  %-16s  %.1f\n', ...
                        '', 't-test pairwise', compLabel, x1c, x2c, pv, ...
                        rangeStr(ai.range_fes), rangeStr(ai.range_ref), ai.diff_mean);
            end
        end
    end
    if res.anova_sig && ~anyPairSig
        fprintf('%-20s  %-18s  %-28s  %-10s  %-10s  %-9s  %-16s  %-16s  %s\n', ...
                '', 't-test pairwise', sprintf('(none of the %d pairs sig.)', N_PAIRS), '-', '-', 'n.s.', '-', '-', '-');
    end
    fprintf('%s\n', repmat('-', 1, 135));
end
fprintf('=================================================================\n\n');

% -------------------------------------------------------------------------
% CACHE SAVE: allows rerunning only the final figure at the
% next run (see the CACHE block at the top of the script), without rerunning all the
% non-parametric SPM1D (the slowest step).
% -------------------------------------------------------------------------
save(CACHE_FILE, 'patientMeans', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', 'DOF_LABELS', 'x', 'spmResults', 'ALL_PAIRS', 'indivSigClusters', 'PATIENT_IDS', 'POSTHOC_CORRECTION', 'EXCL_ZONE', 'htGroupMean');
fprintf('Cache saved: %s\n', CACHE_FILE);

% =========================================================================
% FINAL FIGURE, ALL COMPARISONS: group means only (no
% individual curves or bars), with the significant post-hoc results of
% ALL the pairs shown under each DOF plot (dedicated
% subplot, not over the curves), labelled "Cond A vs Cond B".
% =========================================================================
plotAllCompFigure(patientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS, DOF_LABELS, 'Scapular kinematics', x, ...
                   spmResults, ALL_PAIRS, indivSigClusters, PATIENT_IDS, EXCL_ZONE);

% -------------------------------------------------------------------------
% WARNINGS
% -------------------------------------------------------------------------
if ~isempty(warnings)
    disp(' ');
    disp('--- Warnings ---');
    for i = 1:length(warnings)
        disp(warnings{i});
    end
end

disp(' ');
disp('Done.');


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


function s = rangeStr(r)
    s = sprintf('%.1f to %.1f', r(1), r(2));
end


function meanData = extractScapulaMean(trial, jscap, cycleKey)
    meanData = [];
    try
        euler = trial.Joint(jscap).Euler;
        if ~isfield(euler, cycleKey), return; end
        data = euler.(cycleKey);
        if isempty(data), return; end

        data = squeeze(data); % (3, 1, 101, N) → (3, 101, N)

        if ndims(data) == 3
            meanData = nanmean(data, 3); % → (3, 101)
        elseif ismatrix(data) && size(data,1) == 3 && size(data,2) == 101
            meanData = data;
        end
    catch
        meanData = [];
    end
end
