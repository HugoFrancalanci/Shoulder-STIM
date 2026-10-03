% =========================================================================
% extract_emg_cycles_all_comp.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
%                https://www.unige.ch/medecine/chiru/en/research-groups/nicolas-holzer-et-florent-moissenet
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   July 2026
% -------------------------------------------------------------------------
% Description:   Extracts and analyses surface EMG cycles (4 muscles) from
%                K-LAB .mat files for 10 healthy participants across 7 FES
%                conditions. Same pipeline as extract_emg_cycles_noSEF.m /
%                _rehab.m (FES artefact removal, cycle segmentation, linear
%                envelope, amplitude normalisation), EXCEPT the post-hoc
%                does not compare against a single reference condition
%                (No FES or Rehab) : it compares ALL possible pairs of
%                conditions (7 conditions -> 21 pairs), Holm-Bonferroni
%                (FWER alpha = 0.05) — kinematics counterpart of extract_scapular_
%                kinematics_all_comp.m. Produces 7 output figures:
%                (1) Per-patient : 4 muscles x 7 conditions, mean ± SD
%                (2) Per-patient SPM1D : individual ANOVA RM (N=3 blocks,
%                    balanced via last-block padding) + paired t-tests for
%                    every pair of conditions (only drawn/logged when
%                    significant), Holm-Bonferroni alpha=0.05
%                (3) Global P1-P10 : inter-patient mean ± SD, all conditions
%                (4) Grouped SPM1D (N=10) : ANOVA RM + post-hoc on all 21
%                    pairs, Holm-Bonferroni alpha=0.05, RFT correction (Pataky 2010)
%                (5-7) "Figure finale — toutes comparaisons" (plotAllCompFigureEMG.m,
%                    3 figures) : group-level only (no individual patient
%                    curves/bars mixed into the same panel as the group).
%                    Each muscle panel spans the FULL figure height (1 row x
%                    4 columns) ; significance bars are drawn INSIDE the
%                    curve panel (not a separate subplot), one distinct
%                    colour per significant pair (stable across panels),
%                    identified via the legend rather than inline text —
%                    (5) group mean ± SD, (6) group mean + every individual
%                    patient's own curve (desaturated, no SD band), (7) same
%                    as (5) but with one labelled "P#" row per individually-
%                    significant patient stacked under each significant
%                    pair's group bar.
% -------------------------------------------------------------------------
% Parameters :   LP_FREQ=6Hz, BLANK_MS=8, MAD_FACTOR=6,
%                MIN_PERIOD_MS=15, MAX_BLANK_MS=20, FS_EMG=2200, FS_KIN=100
%                ALL_PAIRS (21 condition pairs), ALPHA_FWER=0.05 (Holm-
%                Bonferroni step-down over the 21 pairs, helpers/holmAlphaSPM1D.m)
% Outputs    :   7 figures (see Description); console output per patient
%                reporting ANOVA result per muscle and significant pairwise
%                post-hoc clusters; cache_emg_all_comp.mat — on the FIRST
%                full run, all data needed to redraw the final figure is
%                cached here (patientMeans, patientBlocks — per-block
%                curves used by extract_emg_discrete_all_comp.m —,
%                spmResults, indivSigClusters, PATIENT_IDS, the display
%                parameters and POSTHOC_CORRECTION ; a cache built with
%                another correction or without patientBlocks is ignored). On every
%                subsequent run, if this cache file exists, the script skips
%                the entire patient loop / SPM1D computation and just
%                reloads the cache to redraw plotAllCompFigureEMG.m in
%                seconds. Set FORCE_RECOMPUTE=true at the top of the script
%                to bypass the cache and recompute everything from scratch.
%                Article-ready summary tables (group/individual/combined)
%                are generated separately from this cache by
%                generate_article_table_emg*.m.
% -------------------------------------------------------------------------
% Dependencies : usercommands_conditions.m, K-LAB .mat files (P[n].mat),
%                plotAllCompFigureEMG.m (plotting/ subfolder),
%                spm1dmatlab-master/ (Pataky 2010, spm1d.stats.nonparam.anova1rm
%                — permutation-based, Monte Carlo with 10000 iterations
%                (exact enumeration is infeasible : nPermTotal=factorial(70)
%                since the permuter shuffles all patient*condition rows,
%                not within-subject) — and the parametric
%                spm1d.stats.ttest_paired for the Holm-Bonferroni-corrected
%                post-hoc, unchanged)
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution -
% NonCommercial 4.0 International License. To view a copy of this license,
% visit http://creativecommons.org/licenses/by-nc/4.0/
% =========================================================================
% Cycles EMG traites par patient et par condition avec enveloppe + SPM1D
% Projet STIM_KC | K-LAB toolbox Protocol01 | Variante "toutes comparaisons"
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
% Difference cle vs _noSEF.m / _rehab.m : le post-hoc ne compare pas chaque
% condition a UNE reference fixe, mais TOUTES les paires de conditions
% (C(7,2) = 21 paires), correction Holm-Bonferroni sur 21 comparaisons
% (seuil alpha/(m-k+1) pour la k-ieme plus petite p-valeur, Holm 1979).
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' extract_emg_cycles_all_comp.m');
disp('=========================================');

% SPM1D doit etre sur le path AVANT le load() du cache (meme dans le
% cache-fast-path ci-dessous) : les clusters SPM1D sont des objets de
% classe custom, et MATLAB ne peut les reconstruire depuis le .mat que si
% la classe qui les definit est deja chargee ("Dot indexing is not
% supported for variables of this type" sinon).
SPM1D_PATH = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end
addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'plotting'));
addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'helpers'));

% -------------------------------------------------------------------------
% CACHE : regeneration rapide de la figure finale seule, sans tout
% recalculer (le SPM1D non parametrique Monte Carlo est le poste le plus
% lent). Met FORCE_RECOMPUTE a true pour ignorer le cache et tout refaire.
% -------------------------------------------------------------------------
FORCE_RECOMPUTE = false;

% Muscles rapportes (figures) : les 4 muscles. Filtre d'AFFICHAGE
% uniquement (familles Holm par muscle -> retirer un muscle ne change pas
% les resultats des autres, sans recalcul ni nouveau tirage des permutations).
REPORT_MUSCLES = {'TRAPS', 'TRAPM', 'TRAPI', 'SERRA'};
CACHE_FILE = fullfile(dataDir(), 'cache_emg_all_comp.mat');

% Methode de correction post-hoc : sauvegardee dans le cache, un cache
% calcule avec une autre correction (ex. ancien Bonferroni) ou sans les
% courbes par bloc (patientBlocks, analyse discrete) est ignore et tout est
% recalcule.
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
    fprintf('Cache trouve : %s\n', CACHE_FILE);
    fprintf('→ Regeneration rapide de la figure finale (pas de re-calcul SPM1D).\n');
    fprintf('  (mettre FORCE_RECOMPUTE=true dans le script pour tout recalculer)\n\n');
    load(CACHE_FILE, 'patientMeans', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', 'EMG_LABELS', 'X_CYCLE', 'spmResults', 'ALL_PAIRS', 'indivSigClusters', 'PATIENT_IDS');

    keepM = ismember(EMG_LABELS, REPORT_MUSCLES);
    plotAllCompFigureEMG(patientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS, EMG_LABELS(keepM), X_CYCLE, ...
                         spmResults(keepM), ALL_PAIRS, indivSigClusters(keepM), PATIENT_IDS);
    return;
elseif isfile(CACHE_FILE) && ~FORCE_RECOMPUTE
    fprintf('Cache trouve mais obsolete (correction "%s" -> "%s", courbes par bloc presentes : %d) : recalcul complet.\n\n', ...
            cachedCorrection, POSTHOC_CORRECTION, cacheHasBlocks);
end

run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'usercommands_conditions.m'));

% SPM1D deja ajoute au path plus haut (avant le cache-fast-path)
rng(0);  % reproductibilite des tests non parametriques (permutation Monte Carlo)

% -------------------------------------------------------------------------
% PARAMETRES
% -------------------------------------------------------------------------
FS_EMG  = 2200;   % Hz
FS_KIN  = 100;    % Hz

LP_FREQ = 6;      % coupure passe-bas enveloppe (Winter 2009)
LP_ORD  = 2;      % ordre Butterworth
X_CYCLE = 0:100;  % axe cycle normalise (101 pts)

% Parametres retrait FES
BLANK_MS      = 8;
MAD_FACTOR    = 6;
MIN_PERIOD_MS = 15;
MAX_BLANK_MS  = 20;

% Canaux a afficher
EMG_LABELS = {'TRAPS','TRAPM','TRAPI','SERRA'};

CONDITIONS_ORDERED = {'No FES','Min_fatigue','Min_stress','Random','Min_pulse_width','Rehab','Min_force'};
COND_LABELS = {'No FES','Min fatigue','Min stress','Random','Min PW','Rehab','Min force'};
COLORS = [0.35 0.20 0.29;   % No FES       aubergine
          0.66 0.80 0.63;   % Min_fatigue  vert sauge
          0.30 0.47 0.46;   % Min_stress   bleu-vert (teal) fonce
          0.91 0.76 0.45;   % Random       jaune dore
          0.89 0.63 0.33;   % Min_pulse_width (Min PW) orange
          0.45 0.55 0.68;   % Rehab        bleu-gris
          0.75 0.35 0.35];  % Min_force    rouge saumon

% Filtre passe-bas
[b_lp, a_lp] = butter(LP_ORD, LP_FREQ / (FS_EMG/2), 'low');

warnings = {};

% -------------------------------------------------------------------------
% TOUTES LES PAIRES DE CONDITIONS (C(7,2) = 21)
% -------------------------------------------------------------------------
ALL_PAIRS = {};
for a = 1:length(CONDITIONS_ORDERED)-1
    for b = a+1:length(CONDITIONS_ORDERED)
        ALL_PAIRS(end+1, :) = {CONDITIONS_ORDERED{a}, CONDITIONS_ORDERED{b}}; %#ok<AGROW>
    end
end
N_PAIRS        = size(ALL_PAIRS, 1);
ALPHA_FWER     = 0.05;  % Holm-Bonferroni : seuil alpha/(m-k+1) par paire (helpers/holmAlphaSPM1D.m)
PAIR_BAR_COLOR = [0.35 0.35 0.35];  % couleur neutre unique (plus de "vs reference")

% Accumulateur global : globalData.(condName).(muscle) = cell de vecteurs (1,101)
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

% Courbes PAR BLOC (une ligne par bloc valide), pour l'analyse discrete
% (pic, timing, duree d'activite : extract_emg_discrete_all_comp.m) :
% patientBlocks.(condName).(muscle){ip} = (n_blocs, 101)
patientBlocks = struct();
for ic = 1:length(CONDITIONS_ORDERED)
    fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
    patientBlocks.(fld) = struct();
    for im = 1:length(EMG_LABELS)
        patientBlocks.(fld).(EMG_LABELS{im}) = {};
    end
end

% Accumulateur pour la figure finale : clusters significatifs individuels
% indivSigClusters{im}.(pairFld){ip} = spmi_t_pt.clusters (cell vide si n.s.)
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
                patientBlocks.(fld).(mLabel){end+1} = zeros(0, 101);
            else
                stack_pt = cat(1, trials_cond{:});
                patientMeans.(fld).(mLabel){end+1} = nanmean(stack_pt, 1);
                patientBlocks.(fld).(mLabel){end+1} = stack_pt;  % (n_blocs, 101)
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
    fprintf('\n=== SPM1D individuel EMG (toutes comparaisons) : %s ===\n', patientID);
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
                spm_F_pt  = spm1d.stats.nonparam.anova1rm(all_mat_pt, group_vec_pt, subj_vec_pt);
                warning('on', 'all');
                spmi_F_pt = spm_F_pt.inference(0.05, 'iterations', 10000, 'interp', true);
                anova_sig_pt = ~isempty(spmi_F_pt.clusters);
            catch ME_anova
                fprintf('  %s — ANOVA erreur : %s\n', mLabel, ME_anova.message);
            end
        end

        rowIdx_pt = 0;
        if anova_sig_pt && n_min < 3
            fprintf('  %s — ANOVA : SIGNIFICATIF mais post-hoc ignoré (ddl=%d, N=%d insuffisant pour RFT)\n', ...
                    mLabel, n_min-1, n_min);
        elseif anova_sig_pt
            fprintf('  %s — ANOVA : SIGNIFICATIF → post-hoc (%d paires testees)\n', mLabel, N_PAIRS);
            % Passe 1 : SPM{t} de chaque paire testee ; passe 2 : inference au
            % seuil Holm-Bonferroni propre a chaque paire (helpers/holmAlphaSPM1D.m)
            spmList_pt = cell(1, N_PAIRS);
            for kp = 1:N_PAIRS
                fldA = matlab.lang.makeValidName(ALL_PAIRS{kp,1});
                fldB = matlab.lang.makeValidName(ALL_PAIRS{kp,2});
                if isempty(condData_padded.(fldA).(mLabel)) || isempty(condData_padded.(fldB).(mLabel)), continue; end
                try
                    spmList_pt{kp} = spm1d.stats.ttest_paired(cat(1, condData_padded.(fldB).(mLabel){:}), ...
                                                              cat(1, condData_padded.(fldA).(mLabel){:}));
                catch ME_ph
                    fprintf('    %s vs %s : erreur — %s\n', ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}, ME_ph.message);
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
                        fprintf('    %s vs %s : SIGNIFICATIF (%d cluster(s), Holm p=%.5f < alpha=%.5f)\n', ...
                                condLabel(condA, CONDITIONS_ORDERED, COND_LABELS), condLabel(condB, CONDITIONS_ORDERED, COND_LABELS), ...
                                length(spmi_t_pt.clusters), pHolm_pt(kp), alphaHolm_pt(kp));
                        y_bar_pt = y_bar_top_pt - (rowIdx_pt-1) * (bar_h_pt + bar_gap_pt);
                        for cl = 1:length(spmi_t_pt.clusters)
                            ep = spmi_t_pt.clusters{cl}.endpoints;
                            rectangle('Position', [ep(1)-1, y_bar_pt, ep(2)-ep(1), bar_h_pt], ...
                                      'FaceColor', PAIR_BAR_COLOR, 'EdgeColor','none','FaceAlpha',0.85);
                            fprintf('      cluster %d : %.1f%%-%.1f%% du cycle (duree %.1f%%)\n', ...
                                    cl, ep(1)-1, ep(2)-1, ep(2)-ep(1));
                        end
                        pairFld = pairFieldName(condA, condB);
                        patientSpmResults(im).posthoc.(pairFld).condA = condA;
                        patientSpmResults(im).posthoc.(pairFld).condB = condB;
                        patientSpmResults(im).posthoc.(pairFld).clusters = spmi_t_pt.clusters;
                        indivSigClusters{im}.(pairFld){ip} = spmi_t_pt.clusters;
                    end
                catch ME_ph
                    fprintf('    %s vs %s : erreur — %s\n', condA, condB, ME_ph.message);
                end
            end
            if rowIdx_pt == 0
                fprintf('    (aucune paire significative — RFT + Holm-Bonferroni alpha=%.2f sur %d comparaisons)\n', ALPHA_FWER, N_PAIRS);
            end
        else
            fprintf('  %s — ANOVA : non significatif\n', mLabel);
        end

        bar_zone_pt = max(rowIdx_pt, 1) * (bar_h_pt + bar_gap_pt);
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

    sgtitle(sprintf('%s  —  SPM1D individuel EMG, toutes comparaisons (N=3 blocs par condition)', patientID), ...
            'FontSize', 13, 'FontWeight', 'bold');

    % --- Tableau recapitulatif individuel ---
    fprintf('\n  --- Tableau recap. individuel (%s) : cluster significatif ---\n', patientID);
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
        fprintf('  (aucun post-hoc significatif pour %s)\n', patientID);
    end

end % ip

% =========================================================================
% FIGURE GLOBALE : cycle EMG moyen inter-patients (P1-P10)
% =========================================================================
figure('Name','Global -- Cycles EMG moyens P1-P10 (all comp)', ...
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
% ANALYSE SPM1D : ANOVA RM 7 conditions + post-hoc sur TOUTES les paires
% =========================================================================

fprintf('\n=== Choix des tests statistiques (EMG) ===\n');
fprintf('  Design        : mesures repetees intra-sujet (10 patients x 7 conditions)\n');
fprintf('  Independance  : 1 moyenne par patient par condition (blocks moyennes)\n');
fprintf('  Test omnibus  : ANOVA RM non parametrique a 1 facteur (spm1d.stats.nonparam.anova1rm, Monte Carlo 10000 iterations)\n');
fprintf('  Post-hoc      : t-test apparie sur chacune des %d paires de conditions (spm1d.stats.ttest_paired, parametrique)\n', N_PAIRS);
fprintf('  Correction    : Holm-Bonferroni sur %d comparaisons (FWER alpha = %.2f ;\n', N_PAIRS, ALPHA_FWER);
fprintf('                  seuils de alpha/%d = %.5f a alpha/1 = %.2f selon le rang de la p-valeur)\n', N_PAIRS, ALPHA_FWER/N_PAIRS, ALPHA_FWER);
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

% Figure SPM (courbes + barres empilees uniquement pour les paires significatives)
figure('Name','SPM1D -- EMG -- ANOVA + post-hoc toutes paires', ...
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
            if anova_sig, sig_str = 'SIGNIFICATIF'; else, sig_str = 'non significatif'; end
            fprintf('%s ANOVA : %s\n', mLabel, sig_str);
        catch ME
            fprintf('%s ANOVA erreur : %s\n', mLabel, ME.message);
        end
    end

    % Post-hoc : toutes les paires (si ANOVA sig)
    rowIdx = 0;
    if anova_sig
        % Passe 1 : SPM{t} de chaque paire testee ; passe 2 : inference au
        % seuil Holm-Bonferroni propre a chaque paire
        spmList = cell(1, N_PAIRS);
        for kp = 1:N_PAIRS
            fldA = matlab.lang.makeValidName(ALL_PAIRS{kp,1});
            fldB = matlab.lang.makeValidName(ALL_PAIRS{kp,2});
            if isempty(spmData.(fldA)(im).mat) || isempty(spmData.(fldB)(im).mat), continue; end
            try
                spmList{kp} = spm1d.stats.ttest_paired(spmData.(fldB)(im).mat, spmData.(fldA)(im).mat);
            catch ME
                fprintf('  %s | %s vs %s erreur : %s\n', mLabel, ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}, ME.message);
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
                fprintf('  %s | %s vs %s erreur : %s\n', mLabel, condA, condB, ME.message);
            end
        end
    end

    bar_zone = max(rowIdx, 1) * (BAR_HEIGHT + BAR_GAP);
    if isfinite(y_min_plot) && isfinite(y_max_plot) && y_max_plot > y_bar_top - bar_zone - 0.01
        ylim([y_bar_top - bar_zone - 0.01, y_max_plot + 0.02]);
    end
    xlim([0 100]);
    xlabel('% cycle'); ylabel('EMG normalise (% baseline)');
    title(mLabel, 'FontSize', 11, 'FontWeight','bold');
    valid_h = legendHandles(arrayfun(@(h) isvalid(h) && ~strcmp(h.DisplayName,''), legendHandles));
    legend(valid_h, 'Location','best', 'FontSize', 7);
    grid on; box on; hold off;
end

sgtitle('Comparaison des conditions de stimulation — EMG, toutes paires (Analyse SPM1D)', ...
        'FontSize', 12, 'FontWeight','bold');

% -------------------------------------------------------------------------
% TABLEAU RECAPITULATIF SPM1D
% -------------------------------------------------------------------------
fprintf('\n');
fprintf('=================================================================\n');
fprintf(' TABLEAU RECAPITULATIF SPM1D — EMG (toutes comparaisons)\n');
fprintf(' ANOVA RM (N=10 patients) | Post-hoc apparies | Holm-Bonferroni alpha=%.2f (%d comparaisons)\n', ALPHA_FWER, N_PAIRS);
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
                    EMG_LABELS{im}, 'ANOVA (7 cond)', '—', ep(1)-1, ep(2)-1, pv);
        end
    else
        fprintf('%-10s  %-18s  %-28s  %-10s  %-10s  %s\n', ...
                EMG_LABELS{im}, 'ANOVA (7 cond)', '—', '—', '—', 'n.s.');
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
                '', 't-test pairwise', sprintf('(aucune des %d paires sig.)', N_PAIRS), '—', '—', 'n.s.');
    end
    fprintf('%s\n', repmat('-', 1, 90));
end
fprintf('=================================================================\n\n');

% -------------------------------------------------------------------------
% SAUVEGARDE CACHE : permet de relancer uniquement la figure finale au
% prochain run (voir bloc CACHE en haut du script), sans re-lancer tout le
% SPM1D non parametrique (le plus lent).
% -------------------------------------------------------------------------
save(CACHE_FILE, 'patientMeans', 'patientBlocks', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', 'EMG_LABELS', 'X_CYCLE', 'spmResults', 'ALL_PAIRS', 'indivSigClusters', 'PATIENT_IDS', 'POSTHOC_CORRECTION');
fprintf('Cache sauvegarde : %s\n', CACHE_FILE);

% =========================================================================
% FIGURE FINALE — TOUTES COMPARAISONS : moyennes de groupe uniquement (pas
% de courbes ni barres individuelles), avec les post-hoc significatifs de
% TOUTES les paires affiches en dessous de chaque graphe muscle
% (sous-graphe dedie, pas superpose aux courbes), etiquetes "Cond A vs Cond B".
% =========================================================================
keepM = ismember(EMG_LABELS, REPORT_MUSCLES);   % trapeze superieur retire de la figure
plotAllCompFigureEMG(patientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS, EMG_LABELS(keepM), X_CYCLE, ...
                     spmResults(keepM), ALL_PAIRS, indivSigClusters(keepM), PATIENT_IDS);

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

function fld = pairFieldName(condA, condB)
    fld = matlab.lang.makeValidName(sprintf('%s_vs_%s', condA, condB));
end

function lbl = condLabel(condRaw, CONDITIONS_ORDERED, COND_LABELS)
    % Renvoie le libelle d'affichage standardise (COND_LABELS) pour une
    % condition brute, plutot qu'un simple strrep('_',' ') qui ne
    % respecte pas les abreviations (ex. "Min PW" et non "Min pulse width").
    idx = find(strcmp(CONDITIONS_ORDERED, condRaw), 1);
    if isempty(idx)
        lbl = strrep(condRaw, '_', ' ');
    else
        lbl = COND_LABELS{idx};
    end
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
