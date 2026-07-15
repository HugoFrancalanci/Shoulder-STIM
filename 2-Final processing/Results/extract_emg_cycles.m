% =========================================================================
% extract_emg_cycles.m
% Cycles EMG traites par patient et par condition — enveloppe + SPM1D
% Projet STIM_KC | K-LAB toolbox Protocol01
%
% Pipeline par trial :
%   1. Retrait artefact FES  : sur sig_proc (Signal.full nettoye) —
%                              detection pics MAD x6, blanking 8ms,
%                              interpolation pchip (conditions FES uniquement)
%   2. Segmentation cycles   : Trial.Rcycle(k).range ou Lcycle(k).range
%                              (indices frames camera) convertis en indices
%                              EMG via FS_EMG / FS_KIN (2200/100 = 22)
%   3. Normalisation temps   : interpolation pchip a 101 points (0-100%)
%   4. Enveloppe lineaire    : rectification onde entiere + Butterworth
%                              passe-bas 2e ordre 6 Hz par cycle
%                              (Winter DA, 2009 — Biomechanics and Motor
%                               Control of Human Movement, 4e ed.)
%   5. Normalisation ampl.   : enveloppe / (mean + 3*std) des 50 premieres
%                              frames cinematiques × 100 → % baseline
%                              (ref = repos pre-mouvement, pas % CMV)
%   6. Moyenne cycles        : nanmean sur les N cycles valides du trial
%
% Canaux : TRAPS, TRAPM, TRAPI, SERRA (SYNCHRO exclu)
%
% Sorties :
%   - 1 figure par patient : 4 muscles x 7 conditions (moyenne +- ET)
%   - 1 figure SPM1D par patient : meme layout + barres sig. (N=3 blocs,
%     exploratoire — puissance limitee par les ddl faibles)
%   - 1 figure globale P1-P10 : cycle moyen inter-patients +- ET
%   - 1 figure SPM1D groupee : ANOVA RM + post-hoc vs No FES (N=10)
%     Correction Bonferroni sur 6 comparaisons (alpha = 0.05/6)
%     Reference : Pataky TC (2010), J Biomech
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' extract_emg_cycles.m');
disp('=========================================');

run(fullfile(fileparts(mfilename('fullpath')), 'usercommands_conditions.m'));

% -------------------------------------------------------------------------
% PARAMETRES
% -------------------------------------------------------------------------
FS_EMG  = 2200;   % Hz — frequence EMG 
FS_KIN  = 100;    % Hz — frequence camera 

LP_FREQ = 6;      % Hz — coupure passe-bas enveloppe (Winter 2009)
LP_ORD  = 2;      % ordre Butterworth
X_CYCLE = 0:100;  % axe cycle normalise (101 pts)

% Parametres retrait FES
BLANK_MS      = 8;
MAD_FACTOR    = 6;
MIN_PERIOD_MS = 15;
MAX_BLANK_MS  = 20;

% Canaux a afficher 
EMG_LABELS = {'TRAPS','TRAPM','TRAPI','SERRA'};

CONDITIONS_ORDERED = {'No FES','Min_fatigue','Min_stress','Random','Min_pw','Rehab','Min_force'};
COND_LABELS = {'No FES','Min fatigue','Min stress','Random','Min power','Rehab','Min force'};
COLORS = [0.00 0.00 0.00;   % No FES       — noir
          0.00 0.45 0.74;   % Min_fatigue  — bleu
          0.85 0.33 0.10;   % Min_stress   — orange-rouge
          0.47 0.67 0.19;   % Random       — vert
          0.49 0.18 0.56;   % Min_pw       — violet
          0.93 0.69 0.13;   % Rehab        — jaune-or
          0.64 0.08 0.18];  % Min_force    — bordeaux

% Filtre passe-bas
[b_lp, a_lp] = butter(LP_ORD, LP_FREQ / (FS_EMG/2), 'low');

warnings = {};

% Accumulateur global : globalData.(condName).(muscle) = cell de vecteurs (1,101)
% Utilise pour la figure globale (visualisation)
globalData = struct();
for ic = 1:length(CONDITIONS_ORDERED)
    fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
    globalData.(fld) = struct();
    for im = 1:length(EMG_LABELS)
        globalData.(fld).(EMG_LABELS{im}) = {};
    end
end

% Accumulateur SPM : patientMeans.(condName).(muscle) = cell, un vecteur (1,101) PAR PATIENT
patientMeans = struct();
for ic = 1:length(CONDITIONS_ORDERED)
    fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
    patientMeans.(fld) = struct();
    for im = 1:length(EMG_LABELS)
        patientMeans.(fld).(EMG_LABELS{im}) = {};
    end
end

FES_CONDS     = {'Min_fatigue','Min_stress','Random','Min_pw','Rehab','Min_force'};
ALPHA_POSTHOC = 0.05 / length(FES_CONDS);
BAR_COLORS    = COLORS(2:end, :);

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
        warnings{end+1} = ['[SKIP] ' patientID ' : fichier introuvable'];
        continue;
    end

    fprintf('Traitement %s (cote %s)...\n', patientID, side);
    load(matFile, 'Trial');

    analyticTrials = filterAnalytic2(Trial, patientID, PATIENT_EXCEPTIONS);
    nTrials        = length(analyticTrials);
    condList       = PATIENT_COND.(patientID);
    nCond          = length(condList.condition);

    if nTrials ~= nCond
        warnings{end+1} = sprintf('[WARNING] %s : %d trials vs %d conditions', patientID, nTrials, nCond);
    end

    missingCondPos = [];
    if isfield(PATIENT_EXCEPTIONS, patientID) && ...
       isfield(PATIENT_EXCEPTIONS.(patientID), 'missingCondPositions')
        missingCondPos = PATIENT_EXCEPTIONS.(patientID).missingCondPositions;
    end

    % condData.(condName).(muscleLabel) : cell array de vecteurs 101 pts
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
            warnings{end+1} = sprintf('[WARNING] %s cond %d (%s) : absent', patientID, iseq, cond);
            continue;
        end

        trialIdx = trialIdx + 1;
        if trialIdx > nTrials
            warnings{end+1} = sprintf('[WARNING] %s : plus de trials a la cond %d (%s)', patientID, iseq, cond);
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
                warnings{end+1} = sprintf('[WARNING] %s trial %d (%s) %s : pas de cycle.raw', patientID, trialIdx, cond, mLabel);
                continue;
            end
            sig_full = double(emgCh.Signal.full(:));
            N_emg    = length(sig_full);

            % --- Retrait FES sur Signal.full (conditions FES uniquement) ---
            if isFES
                sig_proc = removeFESArtifact(sig_full, FS_EMG, BLANK_MS, MAD_FACTOR, MIN_PERIOD_MS, MAX_BLANK_MS);
            else
                sig_proc = sig_full;
            end

            % --- Decoupage cycles via Rcycle/Lcycle ---
            if ~isfield(t, cycleKey) || isempty(t.(cycleKey))
                warnings{end+1} = sprintf('[WARNING] %s trial %d (%s) : pas de %s', patientID, trialIdx, cond, cycleKey);
                continue;
            end
            cycles_kin = t.(cycleKey);
            nCyclesTr  = length(cycles_kin);
            if nCyclesTr == 0, continue; end

            % --- Enveloppe lineaire par cycle (Winter 2009) ---
            cycMeans = zeros(nCyclesTr, 101);
            validCyc = false(nCyclesTr, 1);
            for kc = 1:nCyclesTr
                rng = cycles_kin(kc).range;
                if isempty(rng) || length(rng) < 2, continue; end
                i1 = max(1,     round(rng(1)   * FS_EMG / FS_KIN));
                i2 = min(N_emg, round(rng(end) * FS_EMG / FS_KIN));
                if i2 - i1 < 10, continue; end
                seg    = sig_proc(i1:i2);
                seg_env = filtfilt(b_lp, a_lp, abs(seg));
                t_orig  = linspace(0, 100, length(seg_env));
                cycMeans(kc,:) = interp1(t_orig, seg_env, X_CYCLE, 'pchip');
                validCyc(kc)   = true;
            end
            if ~any(validCyc), continue; end
            cycMeans = cycMeans(validCyc, :);

            % --- Normalisation amplitude (mean + 3*std pre-mouvement) ---
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

    % --- Moyenne des blocs par condition (1 valeur par patient pour SPM) ---
    for ic = 1:length(CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
        for im = 1:length(EMG_LABELS)
            mLabel = EMG_LABELS{im};
            trials_cond = condData.(fld).(mLabel);
            if isempty(trials_cond)
                patientMeans.(fld).(mLabel){end+1} = NaN(1, 101);
            else
                stack_pt = cat(1, trials_cond{:});
                patientMeans.(fld).(mLabel){end+1} = nanmean(stack_pt, 1);
            end
        end
    end

    % --- Figure patient ---
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

            % Bande d'ecart-type (transparente)
            fill([X_CYCLE fliplr(X_CYCLE)], ...
                 [meanCurve+stdCurve fliplr(meanCurve-stdCurve)], ...
                 COLORS(ic,:), 'FaceAlpha', 0.10, 'EdgeColor', 'none', ...
                 'HandleVisibility', 'off');
        end

        xlabel('% cycle');
        ylabel('EMG normalise (% baseline)');
        title(mLabel, 'FontSize', 11, 'FontWeight', 'bold');
        valid_h = legendHandles(arrayfun(@(h) isvalid(h) && ~strcmp(h.DisplayName,''), legendHandles));
        legend(valid_h, 'Location','best', 'FontSize', 7);
        grid on; box on; hold off;
    end

    sgtitle(sprintf('%s  —  Cycles EMG moyens  (enveloppe lineaire, FES retire)', patientID), ...
            'FontSize', 13, 'FontWeight', 'bold');

    % --- Figure patient SPM1D (N=3 blocs par condition) ---
    fprintf('\n=== SPM1D individuel : %s ===\n', patientID);
    figure('Name', [patientID ' - SPM1D'], 'units','normalized','outerposition',[0 0 1 1],'Color','white');

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

        % Padding condData pour design balancé (N_TARGET = 3 blocs)
        N_TARGET = 3;
        condData_padded = condData;
        for ic_p = 1:length(CONDITIONS_ORDERED)
            fld_p = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic_p});
            blocs = condData.(fld_p).(mLabel);
            if ~isempty(blocs) && length(blocs) < N_TARGET
                if im == 1
                    fprintf('  [WARN] %s — %s : %d blocs → duplication\n', ...
                            patientID, CONDITIONS_ORDERED{ic_p}, length(blocs));
                end
                while length(condData_padded.(fld_p).(mLabel)) < N_TARGET
                    condData_padded.(fld_p).(mLabel){end+1} = condData_padded.(fld_p).(mLabel){end};
                end
            end
        end

        % Construire matrices pour ANOVA RM depuis condData_padded
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
                spm_F_pt  = spm1d.stats.anova1rm(all_mat_pt, group_vec_pt, subj_vec_pt);
                warning('on', 'all');
                spmi_F_pt = spm_F_pt.inference(0.05, 'interp', true);
                anova_sig_pt = ~isempty(spmi_F_pt.clusters);
            catch ME_anova
                fprintf('  %s — ANOVA erreur : %s\n', mLabel, ME_anova.message);
            end
        end

        if anova_sig_pt && n_min < 3
            fprintf('  %s — ANOVA : SIGNIFICATIF mais post-hoc ignoré (ddl=%d, N=%d insuffisant pour RFT)\n', ...
                    mLabel, n_min-1, n_min);
        elseif anova_sig_pt
            fprintf('  %s — ANOVA : SIGNIFICATIF → post-hoc\n', mLabel);
            fld_nofes = matlab.lang.makeValidName('No FES');
            data_nofes_pt = condData_padded.(fld_nofes).(mLabel);
            if ~isempty(data_nofes_pt)
                data_nofes_mat = cat(1, data_nofes_pt{:});
                for fc = 1:length(FES_CONDS)
                    fld_fes = matlab.lang.makeValidName(FES_CONDS{fc});
                    if ~isfield(condData_padded, fld_fes) || isempty(condData_padded.(fld_fes).(mLabel)), continue; end
                    data_fes_mat = cat(1, condData_padded.(fld_fes).(mLabel){:});
                    try
                        spm_t_pt  = spm1d.stats.ttest_paired(data_fes_mat, data_nofes_mat);
                        spmi_t_pt = spm_t_pt.inference(ALPHA_POSTHOC, 'two_tailed', true, 'interp', true);
                        if ~isempty(spmi_t_pt.clusters)
                            fprintf('    %s vs No FES : SIGNIFICATIF (%d cluster(s))\n', ...
                                    FES_CONDS{fc}, length(spmi_t_pt.clusters));
                            y_bar_pt = y_bar_top_pt - (fc-1) * (bar_h_pt + bar_gap_pt);
                            for cl = 1:length(spmi_t_pt.clusters)
                                ep = spmi_t_pt.clusters{cl}.endpoints;
                                rectangle('Position', [ep(1)-1, y_bar_pt, ep(2)-ep(1), bar_h_pt], ...
                                          'FaceColor', BAR_COLORS(fc,:), 'EdgeColor','none','FaceAlpha',0.85);
                            end
                        else
                            fprintf('    %s vs No FES : n.s.  (ddl=%d, seuil RFT élevé + Bonferroni α=%.4f)\n', ...
                                    FES_CONDS{fc}, size(data_fes_mat,1)-1, ALPHA_POSTHOC);
                        end
                    catch ME_ph
                        fprintf('    %s vs No FES : erreur — %s\n', FES_CONDS{fc}, ME_ph.message);
                    end
                end
            end
        else
            fprintf('  %s — ANOVA : non significatif\n', mLabel);
        end

        bar_zone_pt = length(FES_CONDS) * (bar_h_pt + bar_gap_pt);
        if isfinite(y_min_pt)
            ylim([y_min_pt - bar_zone_pt - data_range*0.05, y_max_pt + data_range*0.05]);
        end

        xlabel('% cycle');
        ylabel('EMG normalise (% baseline)');
        title(mLabel, 'FontSize', 11, 'FontWeight', 'bold');
        valid_h = legendHandles_spm(arrayfun(@(h) isvalid(h) && ~strcmp(h.DisplayName,''), legendHandles_spm));
        legend(valid_h, 'Location','best', 'FontSize', 7);
        grid on; box on; hold off;
    end

    sgtitle(sprintf('%s  —  SPM1D individuel (N=3 blocs par condition)', patientID), ...
            'FontSize', 13, 'FontWeight', 'bold');

end % ip

% =========================================================================
% FIGURE GLOBALE : cycle EMG moyen inter-patients (P1-P10)
% =========================================================================
figure('Name','Global -- Cycles EMG moyens P1-P10', ...
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

    xlabel('% cycle'); ylabel('EMG normalise (% baseline)');
    title(mLabel, 'FontSize', 11, 'FontWeight','bold');
    valid_h = legendHandles(arrayfun(@(h) isvalid(h) && ~strcmp(h.DisplayName,''), legendHandles));
    legend(valid_h, 'Location','best', 'FontSize', 7);
    grid on; box on; hold off;
end
sgtitle('Comparaison des conditions de stimulation — Ensemble des patients (EMG)', ...
        'FontSize', 13, 'FontWeight','bold');

% =========================================================================
% ANALYSE SPM1D : ANOVA RM 7 conditions + post-hoc chaque FES vs No FES
% =========================================================================
SPM1D_PATH = fullfile(fileparts(mfilename('fullpath')), 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end

FES_CONDS     = {'Min_fatigue','Min_stress','Random','Min_pw','Rehab','Min_force'};
ALPHA_POSTHOC = 0.05 / length(FES_CONDS);
BAR_COLORS    = COLORS(2:end, :);
BAR_HEIGHT    = 0.02;

fprintf('\n=== Choix des tests statistiques (EMG) ===\n');
fprintf('  Design        : mesures repetees intra-sujet (10 patients x 7 conditions)\n');
fprintf('  Independance  : 1 moyenne par patient par condition (blocks moyennes)\n');
fprintf('  Test omnibus  : ANOVA RM a 1 facteur (spm1d.stats.anova1rm)\n');
fprintf('  Post-hoc      : t-test apparie chaque FES vs No FES (ttest_paired)\n');
fprintf('  Correction    : Bonferroni sur 6 comparaisons (alpha = %.4f)\n', ALPHA_POSTHOC);
fprintf('  Temporel      : Random Field Theory via SPM1D (Pataky 2010)\n');
fprintf('%s\n', repmat('-', 1, 55));

% Preparer matrices (N_patients x 101) par condition et par muscle
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

% Structure resultats
spmResults = struct();
for im = 1:length(EMG_LABELS)
    spmResults(im).muscle         = EMG_LABELS{im};
    spmResults(im).anova_sig      = false;
    spmResults(im).anova_clusters = {};
    spmResults(im).posthoc        = struct();
end

% Figure SPM
figure('Name','SPM1D -- EMG -- ANOVA + post-hoc vs No FES', ...
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

    bar_zone  = length(FES_CONDS) * (BAR_HEIGHT + 0.005);
    y_bar_top = y_min_plot - 0.02;

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
            spm_F  = spm1d.stats.anova1rm(all_mat, group_vec, subj_vec);
            spmi_F = spm_F.inference(0.05, 'interp', true);
            anova_sig = ~isempty(spmi_F.clusters);
            spmResults(im).anova_sig      = anova_sig;
            spmResults(im).anova_clusters = spmi_F.clusters;
            if anova_sig, sig_str = 'SIGNIFICATIF'; else, sig_str = 'non significatif'; end
            fprintf('%s ANOVA : %s\n', mLabel, sig_str);
        catch ME
            fprintf('%s ANOVA erreur : %s\n', mLabel, ME.message);
        end
    end

    % Post-hoc
    fld_nofes = matlab.lang.makeValidName('No FES');
    if anova_sig && ~isempty(spmData.(fld_nofes)(im).mat)
        data_nofes = spmData.(fld_nofes)(im).mat;
        for fc = 1:length(FES_CONDS)
            fld_fes = matlab.lang.makeValidName(FES_CONDS{fc});
            if isempty(spmData.(fld_fes)(im).mat), continue; end
            data_fes = spmData.(fld_fes)(im).mat;
            try
                spm_t  = spm1d.stats.ttest_paired(data_fes, data_nofes);
                spmi_t = spm_t.inference(ALPHA_POSTHOC, 'two_tailed', true, 'interp', true);
                spmResults(im).posthoc.(matlab.lang.makeValidName(FES_CONDS{fc})).clusters = spmi_t.clusters;
                spmResults(im).posthoc.(matlab.lang.makeValidName(FES_CONDS{fc})).sig      = ~isempty(spmi_t.clusters);
                if ~isempty(spmi_t.clusters)
                    y_bar = y_bar_top - (fc-1) * (BAR_HEIGHT + 0.005);
                    for cl = 1:length(spmi_t.clusters)
                        ep = spmi_t.clusters{cl}.endpoints;
                        rectangle('Position', [ep(1)-1, y_bar, ep(2)-ep(1), BAR_HEIGHT], ...
                                  'FaceColor', BAR_COLORS(fc,:), 'EdgeColor','none', 'FaceAlpha', 0.85);
                    end
                end
            catch ME
                fprintf('  %s | %s vs No FES erreur : %s\n', mLabel, FES_CONDS{fc}, ME.message);
            end
        end
        for fc = 1:length(FES_CONDS)
            plot(NaN, NaN, 's', 'MarkerFaceColor', BAR_COLORS(fc,:), 'MarkerEdgeColor','none', ...
                 'MarkerSize', 8, 'DisplayName', [strrep(FES_CONDS{fc},'_',' ') ' vs No FES']);
        end
    end

    if isfinite(y_min_plot) && isfinite(y_max_plot) && y_max_plot > y_bar_top - bar_zone - 0.01
        ylim([y_bar_top - bar_zone - 0.01, y_max_plot + 0.02]);
    end
    xlim([0 100]);
    xlabel('% cycle'); ylabel('EMG normalise (% baseline)');
    title(mLabel, 'FontSize', 11, 'FontWeight','bold');
    valid_h = findobj(ax, 'Type','line');
    valid_h = flipud(valid_h);
    legend(valid_h(arrayfun(@(h) ~isempty(h.DisplayName), valid_h)), 'Location','best', 'FontSize', 7);
    grid on; box on; hold off;
end

sgtitle('Comparaison des conditions de stimulation — EMG (Analyse SPM1D)', ...
        'FontSize', 12, 'FontWeight','bold');

% -------------------------------------------------------------------------
% TABLEAU RECAPITULATIF SPM1D
% -------------------------------------------------------------------------
fprintf('\n');
fprintf('=================================================================\n');
fprintf(' TABLEAU RECAPITULATIF SPM1D — EMG\n');
fprintf(' ANOVA RM (N=10 patients) | Post-hoc apparies | Bonferroni alpha=%.4f\n', ALPHA_POSTHOC);
fprintf('=================================================================\n');
fprintf('%-12s  %-18s  %-12s  %-10s  %-10s  %s\n', ...
        'Muscle', 'Test', 'Condition', 'Debut (%)', 'Fin (%)', 'p-value');
fprintf('%s\n', repmat('-', 1, 80));

for im = 1:length(EMG_LABELS)
    res = spmResults(im);
    if res.anova_sig
        for cl = 1:length(res.anova_clusters)
            ep = res.anova_clusters{cl}.endpoints;
            pv = res.anova_clusters{cl}.P;
            fprintf('%-12s  %-18s  %-12s  %-10.1f  %-10.1f  %.4f\n', ...
                    EMG_LABELS{im}, 'ANOVA (7 cond)', '—', ep(1)-1, ep(2)-1, pv);
        end
    else
        fprintf('%-12s  %-18s  %-12s  %-10s  %-10s  %s\n', ...
                EMG_LABELS{im}, 'ANOVA (7 cond)', '—', '—', '—', 'n.s.');
    end
    if res.anova_sig
        for fc = 1:length(FES_CONDS)
            fld_fc = matlab.lang.makeValidName(FES_CONDS{fc});
            if ~isfield(res.posthoc, fld_fc), continue; end
            ph = res.posthoc.(fld_fc);
            if ph.sig
                for cl = 1:length(ph.clusters)
                    ep = ph.clusters{cl}.endpoints;
                    pv = ph.clusters{cl}.P;
                    fprintf('%-12s  %-18s  %-12s  %-10.1f  %-10.1f  %.4f\n', ...
                            '', 't-test vs No FES', strrep(FES_CONDS{fc},'_',' '), ep(1)-1, ep(2)-1, pv);
                end
            else
                fprintf('%-12s  %-18s  %-12s  %-10s  %-10s  %s\n', ...
                        '', 't-test vs No FES', strrep(FES_CONDS{fc},'_',' '), '—', '—', 'n.s.');
            end
        end
    end
    fprintf('%s\n', repmat('-', 1, 80));
end
fprintf('=================================================================\n\n');

% -------------------------------------------------------------------------
% WARNINGS
% -------------------------------------------------------------------------
if ~isempty(warnings)
    disp(' '); disp('--- Avertissements ---');
    for i = 1:length(warnings), disp(warnings{i}); end
end
disp(' '); disp('Termine.');

% =========================================================================
% FONCTIONS LOCALES
% =========================================================================

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
