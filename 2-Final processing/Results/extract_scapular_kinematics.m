% =========================================================================
% extract_scapular_kinematics.m
% Cinématique scapulaire (3 DOF) par patient et par condition — SPM1D
% Projet STIM_KC | K-LAB toolbox Protocol01
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
% Sorties :
%   - 1 figure par patient : 3 DOF x 7 conditions (moyenne +- ET)
%   - 1 figure SPM1D par patient : meme layout + barres sig. (N=3 blocs,
%     exploratoire — puissance limitee par les ddl faibles)
%   - 1 figure globale P1-P10 : cycle moyen inter-patients +- ET
%   - 1 figure SPM1D groupee : ANOVA RM + post-hoc vs No FES (N=10)
%     Correction Bonferroni sur 6 comparaisons (alpha = 0.05/6)
%     Reference : Pataky TC (2010), J Biomech
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' extract_scapular_kinematics.m');
disp('=========================================');
disp(' ');

% -------------------------------------------------------------------------
% CHARGEMENT CONFIGURATION
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), 'usercommands_conditions.m'));

% -------------------------------------------------------------------------
% PARAMÈTRES DE VISUALISATION
% -------------------------------------------------------------------------
x = 0:100; % axe du cycle normalisé (101 pts)

CONDITIONS_ORDERED = {'No FES','Min_fatigue','Min_stress','Random','Min_pw','Rehab','Min_force'};
% Labels d'affichage pour les legendes (underscore → espace)
COND_LABELS = {'No FES','Min fatigue','Min stress','Random','Min power','Rehab','Min force'};
COLORS = [0.00 0.00 0.00;   % No FES       — noir
          0.00 0.45 0.74;   % Min_fatigue  — bleu
          0.85 0.33 0.10;   % Min_stress   — orange-rouge
          0.47 0.67 0.19;   % Random       — vert
          0.49 0.18 0.56;   % Min_pw       — violet
          0.93 0.69 0.13;   % Rehab        — jaune-or
          0.64 0.08 0.18];  % Min_force    — bordeaux

% Ordre de stockage dans .mat (ComputeKinematics.m, séquence YXZ) :
%   dim 1 = X = Rotation latérale/ médiale        (Euler(:,2,:))
%   dim 2 = Y = Protraction/Rétraction            (Euler(:,1,:))
%   dim 3 = Z = Bascule postérieure/antérieur     (Euler(:,3,:))
DOF_LABELS = {' X : Rotation latérale (-) / médiale (+)', 'Y : Protraction (+) / Rétraction (-)', 'Z : Bascule postérieure (+) / antérieure (-)'};

warnings = {};

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

FES_CONDS     = {'Min_fatigue','Min_stress','Random','Min_pw','Rehab','Min_force'};
ALPHA_POSTHOC = 0.05 / length(FES_CONDS);
BAR_COLORS    = COLORS(2:end, :);

% -------------------------------------------------------------------------
% BOUCLE PATIENTS
% -------------------------------------------------------------------------
for ip = 1:length(PATIENT_IDS)

    patientID = PATIENT_IDS{ip};
    side      = DOMINANT_SIDE(patientID);
    jscap     = SCAPULA_JOINT_IDX(side);
    cycleKey  = 'rcycle';
    if strcmp(side, 'L'), cycleKey = 'lcycle'; end

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

    % Boucle sur les positions de condition (1→nCond)
    % trialIdx : compteur indépendant de trials consommés depuis analyticTrials
    % → si position dans missingCondPos : NaN sans consommer de trial
    % → si extractScapulaMean retourne [] : couvre le 8ème ANALYTIC2 vide et tout autre vide
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
    end

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

        legendHandles = gobjects(length(CONDITIONS_ORDERED), 1);

        for ic = 1:length(CONDITIONS_ORDERED)
            cond = CONDITIONS_ORDERED{ic};
            fld  = matlab.lang.makeValidName(cond);
            trials_cond = condData.(fld);

            if isempty(trials_cond), continue; end

            % Empiler les 3 trials → (3, 101, n_trials_valides)
            stack = cat(3, trials_cond{:}); % (3, 101, n)
            % Moyenne et écart-type sur les trials
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
    fprintf('\n=== SPM1D individuel cinématique : %s ===\n', patientID);
    figure('Name', [patientID ' - SPM1D Kin'], 'units','normalized','outerposition',[0 0 1 1],'Color','white');

    for idof = 1:3
        subplot(1, 3, idof);
        hold on;
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
        y_bar_top_pt = y_min_pt - 0.5;
        anova_sig_pt = false;

        if length(unique(group_vec_pt)) >= 2
            try
                warning('off', 'all');
                spm_F_pt  = spm1d.stats.anova1rm(all_mat_pt, group_vec_pt, subj_vec_pt);
                warning('on', 'all');
                spmi_F_pt = spm_F_pt.inference(0.05, 'interp', true);
                anova_sig_pt = ~isempty(spmi_F_pt.clusters);
            catch ME_anova
                warning('on', 'all');
                fprintf('  DOF %d — ANOVA erreur : %s\n', idof, ME_anova.message);
            end
        end

        if anova_sig_pt && n_min < 3
            fprintf('  DOF %d (%s) — ANOVA : SIGNIFICATIF mais post-hoc ignoré (ddl=%d, N=%d insuffisant pour RFT)\n', ...
                    idof, DOF_LABELS{idof}, n_min-1, n_min);
        elseif anova_sig_pt
            fprintf('  DOF %d (%s) — ANOVA : SIGNIFICATIF → post-hoc\n', idof, DOF_LABELS{idof});
            fld_nofes = matlab.lang.makeValidName('No FES');
            trials_nofes = condData_padded.(fld_nofes);
            if ~isempty(trials_nofes)
                data_nofes_mat = zeros(N_TARGET, 101);
                for kb = 1:N_TARGET
                    data_nofes_mat(kb,:) = trials_nofes{kb}(idof,:);
                end
                for fc = 1:length(FES_CONDS)
                    fld_fes = matlab.lang.makeValidName(FES_CONDS{fc});
                    if ~isfield(condData_padded, fld_fes) || isempty(condData_padded.(fld_fes)), continue; end
                    trials_fes = condData_padded.(fld_fes);
                    data_fes_mat = zeros(N_TARGET, 101);
                    for kb = 1:N_TARGET
                        data_fes_mat(kb,:) = trials_fes{kb}(idof,:);
                    end
                    try
                        spm_t_pt  = spm1d.stats.ttest_paired(data_fes_mat, data_nofes_mat);
                        spmi_t_pt = spm_t_pt.inference(ALPHA_POSTHOC, 'two_tailed', true, 'interp', true);
                        if ~isempty(spmi_t_pt.clusters)
                            fprintf('    %s vs No FES : SIGNIFICATIF (%d cluster(s))\n', ...
                                    FES_CONDS{fc}, length(spmi_t_pt.clusters));
                            y_bar_pt = y_bar_top_pt - (fc-1) * (bar_h_pt + 0.1);
                            for cl = 1:length(spmi_t_pt.clusters)
                                ep = spmi_t_pt.clusters{cl}.endpoints;
                                rectangle('Position', [ep(1)-1, y_bar_pt, ep(2)-ep(1), bar_h_pt], ...
                                          'FaceColor', BAR_COLORS(fc,:), 'EdgeColor','none','FaceAlpha',0.85);
                            end
                        else
                            fprintf('    %s vs No FES : n.s.  (ddl=%d, seuil RFT élevé + Bonferroni α=%.4f)\n', ...
                                    FES_CONDS{fc}, length(trials_fes)-1, ALPHA_POSTHOC);
                        end
                    catch ME_ph
                        fprintf('    %s vs No FES : erreur — %s\n', FES_CONDS{fc}, ME_ph.message);
                    end
                end
            end
        else
            fprintf('  DOF %d (%s) — ANOVA : non significatif\n', idof, DOF_LABELS{idof});
        end

        bar_zone_pt = length(FES_CONDS) * (bar_h_pt + 0.1);
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

    sgtitle(sprintf('%s  —  SPM1D individuel cinématique (N=3 blocs)', patientID), ...
            'FontSize', 13, 'FontWeight', 'bold');

end % ip

% =========================================================================
% FIGURE GLOBALE : cycle moyen inter-patients (P1-P10), 3 DOF, 7 conditions
% =========================================================================
figure('Name', 'Global -- Cycle moyen scapulaire P1-P10', ...
       'units','normalized','outerposition',[0 0 1 1], 'Color','white');

for idof = 1:3
    subplot(1, 3, idof);
    hold on;
    legendHandles = gobjects(length(CONDITIONS_ORDERED), 1);

    for ic = 1:length(CONDITIONS_ORDERED)
        cond = CONDITIONS_ORDERED{ic};
        fld  = matlab.lang.makeValidName(cond);
        pts  = globalData.(fld);
        if isempty(pts), continue; end

        % Empiler tous les trials valides de tous les patients → (3,101,n)
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
% ANALYSE SPM1D : ANOVA RM 7 conditions + post-hoc chaque FES vs No FES
%
% Design : mesures repetees intra-sujet (memes 10 patients dans chaque condition)
%   - Une ligne par patient = moyenne de ses blocks valides → N=10
%   - ANOVA : spm1d.stats.anova1rm (repeated-measures one-way ANOVA)
%   - Post-hoc : spm1d.stats.ttest_paired (t-test apparie, memes patients)
%   - Correction Bonferroni sur les 6 comparaisons post-hoc : alpha = 0.05/6
% =========================================================================
SPM1D_PATH = fullfile(fileparts(mfilename('fullpath')), 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end

FES_CONDS     = {'Min_fatigue','Min_stress','Random','Min_pw','Rehab','Min_force'};
ALPHA_POSTHOC = 0.05 / length(FES_CONDS);  % Bonferroni : 0.05/6 ≈ 0.0083
% Couleurs barres post-hoc : meme ordre que CONDITIONS_ORDERED (indices 2-7)
BAR_COLORS  = COLORS(2:end, :);
BAR_HEIGHT  = 0.8;

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
DOF_SHORT = {'X (Rot lat/med)', 'Y (Pro/Ret)', 'Z (Basc post/ant)'};

fprintf('\n=== Choix des tests statistiques ===\n');
fprintf('  Design        : mesures repetees intra-sujet (10 patients x 7 conditions)\n');
fprintf('  Independance  : 1 moyenne par patient par condition (3 blocs moyennes)\n');
fprintf('  Test omnibus  : ANOVA RM a 1 facteur (spm1d.stats.anova1rm)\n');
fprintf('                  → controle la variabilite inter-individuelle\n');
fprintf('  Post-hoc      : t-test apparie chaque FES vs No FES (spm1d.stats.ttest_paired)\n');
fprintf('                  → memes patients dans les deux conditions comparees\n');
fprintf('  Correction    : Bonferroni sur 6 comparaisons post-hoc (alpha = %.4f)\n', ALPHA_POSTHOC);
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

% Figure SPM
figure('Name', 'SPM1D -- Cinematique scapulaire -- ANOVA + post-hoc vs No FES', ...
       'units','normalized','outerposition',[0 0 1 1], 'Color','white');

for idof = 1:3
    ax = subplot(1, 3, idof);
    hold on;

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

    % Marge pour les barres sous le graphique
    bar_zone   = length(FES_CONDS) * (BAR_HEIGHT + 0.3);
    y_bar_top  = y_min_plot - 1;

    % --- ANOVA SPM1D RM : 7 conditions (repeated measures) ---
    % Matrice empilee + vecteurs groupes et sujets pour anova1rm
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
            spm_F  = spm1d.stats.anova1rm(all_mat, group_vec, subj_vec);
            spmi_F = spm_F.inference(0.05, 'interp', true);
            anova_sig = ~isempty(spmi_F.clusters);
            spmResults(idof).anova_sig      = anova_sig;
            spmResults(idof).anova_clusters = spmi_F.clusters;
            if anova_sig, sig_str = 'SIGNIFICATIF'; else, sig_str = 'non significatif'; end
            fprintf('DOF %d ANOVA : %s\n', idof, sig_str);
        catch ME
            fprintf('DOF %d ANOVA erreur : %s\n', idof, ME.message);
        end
    end

    % --- Post-hoc : chaque FES vs No FES (si ANOVA sig) ---
    fld_nofes = matlab.lang.makeValidName('No FES');
    if anova_sig && ~isempty(spmData.(fld_nofes))
        data_nofes = spmData.(fld_nofes)(idof).mat;

        for fc = 1:length(FES_CONDS)
            fld_fes = matlab.lang.makeValidName(FES_CONDS{fc});
            if isempty(spmData.(fld_fes)), continue; end
            data_fes = spmData.(fld_fes)(idof).mat;

            try
                spm_t  = spm1d.stats.ttest_paired(data_fes, data_nofes);
                spmi_t = spm_t.inference(ALPHA_POSTHOC, 'two_tailed', true, 'interp', true);

                % Stocker resultats post-hoc
                spmResults(idof).posthoc.(matlab.lang.makeValidName(FES_CONDS{fc})).clusters = spmi_t.clusters;
                spmResults(idof).posthoc.(matlab.lang.makeValidName(FES_CONDS{fc})).sig = ~isempty(spmi_t.clusters);

                if ~isempty(spmi_t.clusters)
                    y_bar = y_bar_top - (fc-1) * (BAR_HEIGHT + 0.3);
                    for cl = 1:length(spmi_t.clusters)
                        ep = spmi_t.clusters{cl}.endpoints;
                        x1 = (ep(1)-1) / 100 * 100;
                        x2 = (ep(2)-1) / 100 * 100;
                        rectangle('Position', [x1, y_bar, x2-x1, BAR_HEIGHT], ...
                                  'FaceColor', BAR_COLORS(fc,:), ...
                                  'EdgeColor', 'none', 'FaceAlpha', 0.85);
                    end
                end
            catch ME
                fprintf('  DOF %d | %s vs No FES erreur : %s\n', idof, strrep(FES_CONDS{fc},'_',' '), ME.message);
            end
        end

        % Legende barres post-hoc
        for fc = 1:length(FES_CONDS)
            plot(NaN, NaN, 's', 'MarkerFaceColor', BAR_COLORS(fc,:), ...
                 'MarkerEdgeColor','none', 'MarkerSize', 8, ...
                 'DisplayName', [strrep(FES_CONDS{fc},'_',' ') ' vs No FES'], 'HandleVisibility','on');
        end
    end

    % Axes
    ylim([y_bar_top - bar_zone - 0.5,  y_max_plot + 1]);
    xlim([0 100]);
    xlabel('% cycle'); ylabel('Angle (°)');
    title(DOF_LABELS{idof});
    valid_h = findobj(ax, 'Type','line');
    valid_h = flipud(valid_h);
    legend(valid_h(arrayfun(@(h) ~isempty(h.DisplayName), valid_h)), ...
           'Location','best', 'FontSize', 7);
    grid on; box on; hold off;
end

sgtitle('Comparaison des conditions de stimulation pour l''ensemble des patients (Analyse SPM1D)', ...
        'FontSize', 12, 'FontWeight', 'bold');

% -------------------------------------------------------------------------
% TABLEAU RECAPITULATIF SPM1D
% -------------------------------------------------------------------------
DOF_SHORT = {'X (Rot lat/med)', 'Y (Pro/Ret)', 'Z (Basc post/ant)'};

fprintf('\n');
fprintf('=================================================================\n');
fprintf(' TABLEAU RECAPITULATIF SPM1D — Cinematique scapulaire\n');
fprintf(' ANOVA RM (N=10 patients) | Post-hoc apparies | Bonferroni alpha=%.4f\n', ALPHA_POSTHOC);
fprintf('=================================================================\n');
fprintf('%-20s  %-18s  %-12s  %-10s  %-10s  %s\n', ...
        'DOF', 'Test', 'Condition', 'Debut (%)', 'Fin (%)', 'p-value');
fprintf('%s\n', repmat('-', 1, 85));

for idof = 1:3
    res = spmResults(idof);

    % --- ANOVA ---
    if res.anova_sig
        for cl = 1:length(res.anova_clusters)
            ep  = res.anova_clusters{cl}.endpoints;
            pv  = res.anova_clusters{cl}.P;
            x1c = (ep(1)-1);
            x2c = (ep(2)-1);
            fprintf('%-20s  %-18s  %-12s  %-10.1f  %-10.1f  %.4f\n', ...
                    DOF_SHORT{idof}, 'ANOVA (7 cond)', '—', x1c, x2c, pv);
        end
    else
        fprintf('%-20s  %-18s  %-12s  %-10s  %-10s  %s\n', ...
                DOF_SHORT{idof}, 'ANOVA (7 cond)', '—', '—', '—', 'n.s.');
    end

    % --- Post-hoc ---
    if res.anova_sig
        for fc = 1:length(FES_CONDS)
            fld_fc = matlab.lang.makeValidName(FES_CONDS{fc});
            if ~isfield(res.posthoc, fld_fc), continue; end
            ph = res.posthoc.(fld_fc);
            if ph.sig
                for cl = 1:length(ph.clusters)
                    ep  = ph.clusters{cl}.endpoints;
                    pv  = ph.clusters{cl}.P;
                    x1c = (ep(1)-1);
                    x2c = (ep(2)-1);
                    fprintf('%-20s  %-18s  %-12s  %-10.1f  %-10.1f  %.4f\n', ...
                            '', ['t-test vs No FES'], strrep(FES_CONDS{fc},'_',' '), x1c, x2c, pv);
                end
            else
                fprintf('%-20s  %-18s  %-12s  %-10s  %-10s  %s\n', ...
                        '', 't-test vs No FES', strrep(FES_CONDS{fc},'_',' '), '—', '—', 'n.s.');
            end
        end
    end
    fprintf('%s\n', repmat('-', 1, 85));
end
fprintf('=================================================================\n\n');

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
