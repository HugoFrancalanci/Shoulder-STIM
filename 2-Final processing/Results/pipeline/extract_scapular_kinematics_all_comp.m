% =========================================================================
% extract_scapular_kinematics_all_comp.m
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
% Description:   Extracts and analyses scapular kinematics (3 DOF, YXZ
%                sequence, ISB) from K-LAB .mat files for 10 healthy participants across
%                7 FES conditions. Same pipeline as extract_scapular_kinematics_noSEF.m /
%                _rehab.m, EXCEPT the post-hoc does not compare against a
%                single reference condition (No FES or Rehab) : it compares
%                ALL possible pairs of conditions (7 conditions -> 21 pairs),
%                Holm-Bonferroni (FWER alpha = 0.05). Produces 7 output figures:
%                (1) Per-patient : 3 DOF x 7 conditions, mean ± SD across blocks
%                (2) Per-patient SPM1D : individual ANOVA RM (N=3 blocks as
%                    observations, balanced via last-block padding) + paired
%                    t-tests for every pair of conditions (only drawn/logged
%                    when significant), Holm-Bonferroni alpha=0.05
%                (3) Global P1-P10 : inter-patient mean ± SD, all conditions
%                (4) Grouped SPM1D (N=10) : ANOVA RM + post-hoc on all 21
%                    pairs, Holm-Bonferroni alpha=0.05, RFT correction (Pataky 2010)
%                Also prints, for each significant cluster (individual and
%                group), a recap table with the % cycle window, p-value,
%                and the real angular value (°) of both compared conditions
%                over that window, plus their difference.
%                (5-7) "Figure finale — toutes comparaisons" (plotAllCompFigure.m,
%                    3 figures) : group-level only (no individual patient
%                    curves/bars mixed into the same panel as the group).
%                    Each DOF panel spans the FULL figure height (1 row x 3
%                    columns) ; significance bars are drawn INSIDE the curve
%                    panel (not a separate subplot), one distinct colour per
%                    significant pair (stable across panels), identified via
%                    the legend rather than inline text — (5) group mean ± SD,
%                    (6) group mean + every individual patient's own curve
%                    (desaturated, no SD band), (7) same as (5) but with one
%                    labelled "P#" row per individually-significant patient
%                    stacked under each significant pair's group bar.
% -------------------------------------------------------------------------
% Parameters :   Joint index : RST=3 (right) / LST=8 (left), from
%                DOMINANT_SIDE map in usercommands_conditions.m
%                ALL_PAIRS (21 condition pairs), ALPHA_FWER=0.05 (Holm-
%                Bonferroni step-down over the 21 pairs, helpers/
%                holmAlphaSPM1D.m), EXCL_ELEV_THRESHOLD=90 deg (grey
%                'not interpretable' zone where humerothoracic elevation
%                exceeds 90 deg, helpers/computeExclusionZone.m — visual
%                only, statistics still run on the full cycle)
% Outputs    :   7 figures (see Description); console output per patient
%                reporting ANOVA p-value per DOF and significant pairwise
%                post-hoc clusters, plus recap tables (individual and group)
%                with angular values per significant cluster;
%                cache_scapulothoracic_all_comp.mat — on the FIRST full run, all
%                data needed to redraw the final figure is cached here
%                (patientMeans, spmResults, indivSigClusters, PATIENT_IDS,
%                and the display parameters). On every subsequent run, if
%                this cache file exists, the script skips the entire
%                patient loop / SPM1D computation and just reloads the
%                cache to redraw plotAllCompFigure.m in seconds (useful
%                while iterating on the figure's appearance — indivSigClusters
%                and PATIENT_IDS are cached too, ready for a future
%                individual-level companion figure, even though the current
%                plotAllCompFigure.m only uses the group-level data). Set
%                FORCE_RECOMPUTE=true at the top of the script to bypass the
%                cache and recompute everything from scratch. Article-ready
%                summary tables (group/individual/combined) are generated
%                separately from this cache by generate_article_table_kin*.m.
% -------------------------------------------------------------------------
% Dependencies : usercommands_conditions.m, K-LAB .mat files (P[n].mat),
%                plotAllCompFigure.m (plotting/ subfolder),
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
% Cinématique scapulaire (3 DOF) par patient et par condition — SPM1D
% Projet STIM_KC | K-LAB toolbox Protocol01 | Variante "toutes comparaisons"
%
% Donnees source : Trial.Joint(jscap).Euler.rcycle / lcycle
%   Shape MATLAB : (3, 1, 101, N_cycles) — deja normalises en temps
%   jscap = 3 (RST, cote droit) ou 8 (LST, cote gauche)
%   Sequence YXZ :
%     dim 1 = X : Rotation laterale (-) / mediale (+)
%     dim 2 = Y : Protraction (+) / Retraction (-)
%     dim 3 = Z : Bascule posterieure (+) / anterieure (-)
%
% Pipeline par trial :
%   1. Extraction cycles  : squeeze(Euler.rcycle) → (3, 101, N)
%   2. Moyenne cycles     : nanmean sur N → (3, 101) par trial
%   3. Stockage par block : condData.(cond){end+1} = (3, 101)
%
% Difference cle vs _noSEF.m / _rehab.m : le post-hoc ne compare pas chaque
% condition a UNE reference fixe, mais TOUTES les paires de conditions
% (C(7,2) = 21 paires), correction Holm-Bonferroni sur 21 comparaisons
% (seuil alpha/(m-k+1) pour la k-ieme plus petite p-valeur, Holm 1979).
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' extract_scapular_kinematics_all_comp.m');
disp('=========================================');
disp(' ');

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
CACHE_FILE = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'cache_scapulothoracic_all_comp.mat');

% Methode de correction post-hoc : sauvegardee dans le cache, un cache
% calcule avec une autre correction (ex. ancien Bonferroni) ou sans zone
% d'exclusion (EXCL_ZONE) est ignore et tout est recalcule.
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
    fprintf('Cache trouve : %s\n', CACHE_FILE);
    fprintf('→ Regeneration rapide de la figure finale (pas de re-calcul SPM1D).\n');
    fprintf('  (mettre FORCE_RECOMPUTE=true dans le script pour tout recalculer)\n\n');
    load(CACHE_FILE, 'patientMeans', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', 'DOF_LABELS', 'x', 'spmResults', 'ALL_PAIRS', 'indivSigClusters', 'PATIENT_IDS', 'EXCL_ZONE');

    plotAllCompFigure(patientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS, DOF_LABELS, 'Scapular kinematics', x, ...
                       spmResults, ALL_PAIRS, indivSigClusters, PATIENT_IDS, EXCL_ZONE);
    return;
elseif isfile(CACHE_FILE) && ~FORCE_RECOMPUTE
    fprintf('Cache trouve mais obsolete (correction "%s" -> "%s", zone d exclusion presente : %d) : recalcul complet.\n\n', ...
            cachedCorrection, POSTHOC_CORRECTION, cacheHasZone);
end

% -------------------------------------------------------------------------
% CHARGEMENT CONFIGURATION
% -------------------------------------------------------------------------
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'usercommands_conditions.m'));

% SPM1D deja ajoute au path plus haut (avant le cache-fast-path)
rng(0);  % reproductibilite des tests non parametriques (permutation Monte Carlo)

% -------------------------------------------------------------------------
% PARAMÈTRES DE VISUALISATION
% -------------------------------------------------------------------------
x = 0:100; % axe du cycle normalisé (101 pts)

CONDITIONS_ORDERED = {'No FES','Min_fatigue','Min_stress','Random','Min_pulse_width','Rehab','Min_force'};
% Labels d'affichage pour les legendes (underscore → espace)
COND_LABELS = {'No FES','Min fatigue','Min stress','Random','Min PW','Rehab','Min force'};
COLORS = [0.35 0.20 0.29;   % No FES       — aubergine
          0.66 0.80 0.63;   % Min_fatigue  — vert sauge
          0.30 0.47 0.46;   % Min_stress   — bleu-vert (teal) fonce
          0.91 0.76 0.45;   % Random       — jaune dore
          0.89 0.63 0.33;   % Min_pulse_width (Min PW) — orange
          0.45 0.55 0.68;   % Rehab        — bleu-gris (assorti a la palette)
          0.75 0.35 0.35];  % Min_force    — rouge saumon

% Ordre de stockage dans .mat (ComputeKinematics.m, séquence YXZ) :
%   dim 1 = X = Rotation latérale/ médiale        (Euler(:,2,:))
%   dim 2 = Y = Protraction/Rétraction            (Euler(:,1,:))
%   dim 3 = Z = Bascule postérieure/antérieur     (Euler(:,3,:))
DOF_LABELS = {'Lateral (-) / medial (+) rotation', 'Protraction (+) / retraction (-)', 'Posterior (+) / anterior (-) tilt'};
DOF_SHORT  = {'X (Rot lat/med)', 'Y (Pro/Ret)', 'Z (Basc post/ant)'};

warnings = {};

% Zone de non interpretabilite : portion du cycle ou l'elevation
% humerothoracique depasse ce seuil (bande grise verticale sur les figures,
% statistiques inchangees). Groupe : courbe moyenne des 10 patients ;
% figures individuelles : courbe propre au patient.
EXCL_ELEV_THRESHOLD = 90;  % deg
htPatientMeans = {};       % un vecteur (1,101) par patient, toutes conditions confondues

% -------------------------------------------------------------------------
% TOUTES LES PAIRES DE CONDITIONS (C(7,2) = 21)
% -------------------------------------------------------------------------
ALL_PAIRS = {};
for a = 1:length(CONDITIONS_ORDERED)-1
    for b = a+1:length(CONDITIONS_ORDERED)
        ALL_PAIRS(end+1, :) = {CONDITIONS_ORDERED{a}, CONDITIONS_ORDERED{b}}; %#ok<AGROW>
    end
end
N_PAIRS       = size(ALL_PAIRS, 1);
ALPHA_FWER    = 0.05;  % Holm-Bonferroni : seuil alpha/(m-k+1) par paire (helpers/holmAlphaSPM1D.m)
PAIR_BAR_COLOR = [0.35 0.35 0.35];  % couleur neutre unique (plus de "vs reference")

% Accumulateur global : globalData.(condName) = cell array de vecteurs (3,101), un par trial
% Utilise pour la figure globale (visualisation).
globalData = struct();
for ic = 1:length(CONDITIONS_ORDERED)
    globalData.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic})) = {};
end

% Accumulateur SPM : patientMeans.(condName) = cell array, un vecteur (3,101) PAR PATIENT
% (moyenne des 3 blocks valides) → N=10 observations independantes pour l'ANOVA
patientMeans = struct();
for ic = 1:length(CONDITIONS_ORDERED)
    patientMeans.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic})) = {};
end

% Accumulateur pour la figure finale : clusters significatifs individuels
% indivSigClusters{idof}.(pairFld){ip} = spmi_t_pt.clusters (cell vide si n.s.)
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
    jht = HUMEROTHORACIC_JOINT_IDX(side);  % elevation humerothoracique (zone d'exclusion)

    pnum    = str2double(patientID(2:end));
    matFile = fullfile(dataFolder, ['P' num2str(pnum) '.mat']);

    if ~isfile(matFile)
        warnings{end+1} = ['[SKIP] ' patientID ' : fichier introuvable'];
        continue;
    end

    fprintf('Traitement %s (côté %s)...\n', patientID, side);
    load(matFile, 'Trial');

    analyticTrials = filterAnalytic2(Trial, patientID, PATIENT_EXCEPTIONS);
    nTrials        = length(analyticTrials);
    condList       = PATIENT_COND.(patientID);
    nCond          = length(condList.condition);

    if nTrials ~= nCond
        warnings{end+1} = sprintf('[WARNING] %s : %d trials vs %d conditions', patientID, nTrials, nCond);
    end

    % --- Accumulation des trials par condition ---
    % condData.(condName) : cell array de matrices (3×101), une par trial valide
    condData = struct();
    for ic = 1:length(CONDITIONS_ORDERED)
        condData.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic})) = {};
    end

    % Lecture missingCondPositions (P007 : No FES block 1 absent)
    missingCondPos = [];
    if isfield(PATIENT_EXCEPTIONS, patientID) && ...
       isfield(PATIENT_EXCEPTIONS.(patientID), 'missingCondPositions')
        missingCondPos = PATIENT_EXCEPTIONS.(patientID).missingCondPositions;
    end

    htTrials = {};  % elevation humerothoracique (1,101) par trial valide

    % Boucle sur les positions de condition (1→nCond)
    trialIdx = 0;
    for iseq = 1:nCond

        cond = condList.condition{iseq};

        if ismember(iseq, missingCondPos)
            warnings{end+1} = sprintf('[WARNING] %s condition %d (%s) : aucun trial disponible', patientID, iseq, cond);
            continue;
        end

        trialIdx = trialIdx + 1;
        if trialIdx > nTrials
            warnings{end+1} = sprintf('[WARNING] %s : plus de trials à la condition %d (%s)', patientID, iseq, cond);
            break;
        end

        itrial = analyticTrials(trialIdx);
        data   = extractScapulaMean(Trial(itrial), jscap, cycleKey);

        if isempty(data)
            warnings{end+1} = sprintf('[WARNING] %s trial %d → cond %d (%s) : cinématique absente', patientID, trialIdx, iseq, cond);
            continue;
        end

        fld = matlab.lang.makeValidName(cond);
        condData.(fld){end+1} = data; % (3, 101)
        globalData.(fld){end+1} = data; % accumulation inter-patients

        ht = extractHTElevation(Trial(itrial), jht, cycleKey);
        if ~isempty(ht), htTrials{end+1} = ht; end %#ok<AGROW>
    end

    % --- Zone d'exclusion propre au patient (elevation HT > seuil) ---
    if isempty(htTrials)
        htPatientMeans{end+1} = NaN(1, 101); %#ok<AGROW>
        warnings{end+1} = sprintf('[WARNING] %s : elevation humerothoracique absente (pas de zone d exclusion)', patientID);
    else
        htPatientMeans{end+1} = nanmean(cat(1, htTrials{:}), 1); %#ok<AGROW>
    end
    zonePt = computeExclusionZone(htPatientMeans{end}, x, EXCL_ELEV_THRESHOLD);

    % --- Moyenne des blocks par condition pour SPM (une ligne par patient) ---
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

    % --- Figure patient ---
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

    sgtitle(sprintf('Comparaison des conditions de stimulation : %s (côté %s)', patientID, side), ...
            'FontSize', 13, 'FontWeight', 'bold');

    % --- Figure patient SPM1D (N=3 blocs par condition) ---
    fprintf('\n=== SPM1D individuel cinématique (toutes comparaisons) : %s ===\n', patientID);
    figure('Name', [patientID ' - SPM1D Kin (all comp)'], 'units','normalized','outerposition',[0 0 1 1],'Color','white');

    % Stockage des resultats post-hoc individuels (pour le tableau recap patient)
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

        % Construire matrices (n_blocks × 101) pour ANOVA RM — design balancé
        % Cible : 3 blocs par condition. Si une condition n'en a que 2,
        % on duplique le dernier bloc (avec avertissement console).
        N_TARGET = 3;

        condData_padded = condData;
        for ic = 1:length(CONDITIONS_ORDERED)
            fld = matlab.lang.makeValidName(CONDITIONS_ORDERED{ic});
            n_blocs = length(condData_padded.(fld));
            if n_blocs > 0 && n_blocs < N_TARGET && idof == 1
                fprintf('  [WARN] %s — %s : %d blocs seulement → duplication du dernier bloc\n', ...
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
                fprintf('  DOF %d — ANOVA erreur : %s\n', idof, ME_anova.message);
            end
        end

        rowIdx_pt = 0;
        if anova_sig_pt && n_min < 3
            fprintf('  DOF %d (%s) — ANOVA : SIGNIFICATIF mais post-hoc ignoré (ddl=%d, N=%d insuffisant pour RFT)\n', ...
                    idof, DOF_LABELS{idof}, n_min-1, n_min);
        elseif anova_sig_pt
            fprintf('  DOF %d (%s) — ANOVA : SIGNIFICATIF → post-hoc (%d paires testees)\n', idof, DOF_LABELS{idof}, N_PAIRS);
            % Passe 1 : SPM{t} de chaque paire testee ; passe 2 : inference au
            % seuil Holm-Bonferroni propre a chaque paire (helpers/holmAlphaSPM1D.m)
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
                    fprintf('    %s vs %s : erreur — %s\n', condA, condB, ME_ph.message);
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
                        fprintf('    %s vs %s : SIGNIFICATIF (%d cluster(s), Holm p=%.5f < alpha=%.5f)\n', ...
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
                    fprintf('    %s vs %s : erreur — %s\n', condA, condB, ME_ph.message);
                end
            end
            if rowIdx_pt == 0
                fprintf('    (aucune paire significative — RFT + Holm-Bonferroni alpha=%.2f sur %d comparaisons)\n', ALPHA_FWER, N_PAIRS);
            end
        else
            fprintf('  DOF %d (%s) — ANOVA : non significatif\n', idof, DOF_LABELS{idof});
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

    sgtitle(sprintf('%s  —  SPM1D individuel cinématique, toutes comparaisons (N=3 blocs)', patientID), ...
            'FontSize', 13, 'FontWeight', 'bold');

    % --- Tableau recapitulatif individuel : % cycle significatif <-> valeur angulaire ---
    fprintf('\n  --- Tableau recap. individuel (%s) : cluster significatif -> valeur angulaire ---\n', patientID);
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
        fprintf('  (aucun post-hoc significatif pour %s)\n', patientID);
    end

end % ip

% =========================================================================
% ZONE D'EXCLUSION GROUPE : elevation humerothoracique moyenne (10 patients,
% toutes conditions) > EXCL_ELEV_THRESHOLD
% =========================================================================
htGroupMean = nanmean(cat(1, htPatientMeans{:}), 1);  % (1,101)
EXCL_ZONE   = computeExclusionZone(htGroupMean, x, EXCL_ELEV_THRESHOLD);
fprintf('\n=== Zone d''exclusion (elevation humerothoracique moyenne > %g°) ===\n', EXCL_ELEV_THRESHOLD);
[htMax, iHtMax] = max(htGroupMean);
fprintf('  Elevation HT moyenne max : %.1f° a %d %% du cycle\n', htMax, x(iHtMax));
if isempty(EXCL_ZONE.windows)
    fprintf('  (seuil jamais depasse : aucune zone grisee)\n');
end
for kz = 1:size(EXCL_ZONE.windows, 1)
    fprintf('  Zone %d : %.1f %% -> %.1f %% du cycle\n', kz, EXCL_ZONE.windows(kz,1), EXCL_ZONE.windows(kz,2));
end

% =========================================================================
% FIGURE GLOBALE : cycle moyen inter-patients (P1-P10), 3 DOF, 7 conditions
% =========================================================================
figure('Name', 'Global -- Cycle moyen scapulaire P1-P10 (all comp)', ...
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

sgtitle('Comparaison des conditions de stimulation pour l''ensemble des patients', ...
        'FontSize', 13, 'FontWeight', 'bold');

% =========================================================================
% ANALYSE SPM1D : ANOVA RM 7 conditions + post-hoc sur TOUTES les paires
%
% Design : mesures repetees intra-sujet (memes 10 patients dans chaque condition)
%   - Une ligne par patient = moyenne de ses blocks valides → N=10
%   - ANOVA : spm1d.stats.nonparam.anova1rm (repeated-measures one-way ANOVA,
%     permutation-based, Monte Carlo, 10000 iterations)
%   - Post-hoc : spm1d.stats.ttest_paired (t-test apparie, memes patients,
%     reste parametrique) sur les 21 paires de conditions possibles
%   - Correction Holm-Bonferroni sur les 21 comparaisons post-hoc (FWER
%     alpha = 0.05) : la k-ieme plus petite p-valeur est comparee a
%     alpha/(m-k+1), arret a la premiere non rejetee (helpers/holmAlphaSPM1D.m)
% =========================================================================

% Preparer les matrices (N_patients x 101) par condition et par DOF
% Une ligne = moyenne des blocks valides d'UN patient
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
fprintf('\n=== Choix des tests statistiques ===\n');
fprintf('  Design        : mesures repetees intra-sujet (10 patients x 7 conditions)\n');
fprintf('  Independance  : 1 moyenne par patient par condition (3 blocs moyennes)\n');
fprintf('  Test omnibus  : ANOVA RM non parametrique a 1 facteur (spm1d.stats.nonparam.anova1rm, Monte Carlo 10000 iterations)\n');
fprintf('                  → controle la variabilite inter-individuelle\n');
fprintf('  Post-hoc      : t-test apparie sur chacune des %d paires de conditions (spm1d.stats.ttest_paired, parametrique)\n', N_PAIRS);
fprintf('                  → memes patients dans les deux conditions comparees\n');
fprintf('  Correction    : Holm-Bonferroni sur %d comparaisons post-hoc (FWER alpha = %.2f ;\n', N_PAIRS, ALPHA_FWER);
fprintf('                  seuils de alpha/%d = %.5f a alpha/1 = %.2f selon le rang de la p-valeur)\n', N_PAIRS, ALPHA_FWER/N_PAIRS, ALPHA_FWER);
fprintf('  Zone grisee   : elevation humerothoracique > %g° (visuel uniquement, stats sur tout le cycle)\n', EXCL_ELEV_THRESHOLD);
fprintf('  Temporel      : Random Field Theory via SPM1D (Pataky 2010)\n');
fprintf('  Parametrique  : N=10, robustesse de l ANOVA RM aux deviations moderates\n');
fprintf('                  de normalite acceptee (standard en biomecanique clinique)\n');
fprintf('%s\n', repmat('-', 1, 55));

% Structure de stockage des resultats pour le tableau recapitulatif
spmResults = struct();
for idof = 1:3
    spmResults(idof).dof_label  = DOF_LABELS{idof};
    spmResults(idof).anova_sig  = false;
    spmResults(idof).anova_clusters = {};
    spmResults(idof).posthoc    = struct();
end

% Figure SPM (courbes + barres empilees uniquement pour les paires significatives)
figure('Name', 'SPM1D -- Cinematique scapulaire -- ANOVA + post-hoc toutes paires', ...
       'units','normalized','outerposition',[0 0 1 1], 'Color','white');

for idof = 1:3
    ax = subplot(1, 3, idof);
    hold on;
    drawExclusionZone(ax, EXCL_ZONE);

    % --- Tracer les courbes moyennes (meme apparence que figure globale) ---
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
        subj_vec  = [subj_vec;  (1:n)'];  % identifiants patients 1..N
    end

    anova_sig = false;
    if length(unique(group_vec)) >= 2
        try
            spm_F  = spm1d.stats.nonparam.anova1rm(all_mat, group_vec, subj_vec);
            spmi_F = spm_F.inference(0.05, 'iterations', 10000, 'interp', true);
            anova_sig = ~isempty(spmi_F.clusters);
            spmResults(idof).anova_sig      = anova_sig;
            spmResults(idof).anova_clusters = spmi_F.clusters;
            if anova_sig, sig_str = 'SIGNIFICATIF'; else, sig_str = 'non significatif'; end
            fprintf('DOF %d ANOVA : %s\n', idof, sig_str);
        catch ME
            fprintf('DOF %d ANOVA erreur : %s\n', idof, ME.message);
        end
    end

    % --- Post-hoc : toutes les paires (si ANOVA sig) ---
    rowIdx = 0;
    if anova_sig
        % Passe 1 : SPM{t} de chaque paire testee ; passe 2 : inference au
        % seuil Holm-Bonferroni propre a chaque paire
        spmList = cell(1, N_PAIRS);
        for kp = 1:N_PAIRS
            fldA = matlab.lang.makeValidName(ALL_PAIRS{kp,1});
            fldB = matlab.lang.makeValidName(ALL_PAIRS{kp,2});
            if isempty(spmData.(fldA)) || isempty(spmData.(fldB)), continue; end
            try
                spmList{kp} = spm1d.stats.ttest_paired(spmData.(fldB)(idof).mat, spmData.(fldA)(idof).mat);
            catch ME
                fprintf('  DOF %d | %s vs %s erreur : %s\n', idof, ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}, ME.message);
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
                fprintf('  DOF %d | %s vs %s erreur : %s\n', idof, condA, condB, ME.message);
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

sgtitle('Comparaison des conditions de stimulation — toutes paires (Analyse SPM1D)', ...
        'FontSize', 12, 'FontWeight', 'bold');

% -------------------------------------------------------------------------
% TABLEAU RECAPITULATIF SPM1D
% -------------------------------------------------------------------------
fprintf('\n');
fprintf('=================================================================\n');
fprintf(' TABLEAU RECAPITULATIF SPM1D — Cinematique scapulaire (toutes comparaisons)\n');
fprintf(' ANOVA RM (N=10 patients) | Post-hoc apparies | Holm-Bonferroni alpha=%.2f (%d comparaisons)\n', ALPHA_FWER, N_PAIRS);
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
                    DOF_SHORT{idof}, 'ANOVA (7 cond)', '—', x1c, x2c, pv, '—', '—', '—');
        end
    else
        fprintf('%-20s  %-18s  %-28s  %-10s  %-10s  %-9s  %-16s  %-16s  %s\n', ...
                DOF_SHORT{idof}, 'ANOVA (7 cond)', '—', '—', '—', 'n.s.', '—', '—', '—');
    end

    % --- Post-hoc : uniquement les paires significatives ---
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
                '', 't-test pairwise', sprintf('(aucune des %d paires sig.)', N_PAIRS), '—', '—', 'n.s.', '—', '—', '—');
    end
    fprintf('%s\n', repmat('-', 1, 135));
end
fprintf('=================================================================\n\n');

% -------------------------------------------------------------------------
% SAUVEGARDE CACHE : permet de relancer uniquement la figure finale au
% prochain run (voir bloc CACHE en haut du script), sans re-lancer tout le
% SPM1D non parametrique (le plus lent).
% -------------------------------------------------------------------------
save(CACHE_FILE, 'patientMeans', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', 'DOF_LABELS', 'x', 'spmResults', 'ALL_PAIRS', 'indivSigClusters', 'PATIENT_IDS', 'POSTHOC_CORRECTION', 'EXCL_ZONE', 'htGroupMean');
fprintf('Cache sauvegarde : %s\n', CACHE_FILE);

% =========================================================================
% FIGURE FINALE — TOUTES COMPARAISONS : moyennes de groupe uniquement (pas
% de courbes ni barres individuelles), avec les post-hoc significatifs de
% TOUTES les paires affiches en dessous de chaque graphe DOF (sous-graphe
% dedie, pas superpose aux courbes), etiquetes "Cond A vs Cond B".
% =========================================================================
plotAllCompFigure(patientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS, DOF_LABELS, 'Scapular kinematics', x, ...
                   spmResults, ALL_PAIRS, indivSigClusters, PATIENT_IDS, EXCL_ZONE);

% -------------------------------------------------------------------------
% WARNINGS
% -------------------------------------------------------------------------
if ~isempty(warnings)
    disp(' ');
    disp('--- Avertissements ---');
    for i = 1:length(warnings)
        disp(warnings{i});
    end
end

disp(' ');
disp('Terminé.');


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


function s = rangeStr(r)
    s = sprintf('%.1f to %.1f', r(1), r(2));
end


function analyticIdx = filterAnalytic2(Trial, patientID, PATIENT_EXCEPTIONS)
    isAnalytic = false(1, length(Trial));
    for i = 1:length(Trial)
        if isfield(Trial(i), 'task') && strcmp(Trial(i).task, 'ANALYTIC2')
            isAnalytic(i) = true;
        end
    end
    allIdx = find(isAnalytic);

    skipFirst = 0;
    skipPos   = [];
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
