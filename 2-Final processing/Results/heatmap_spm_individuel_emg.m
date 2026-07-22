% =========================================================================
% heatmap_spm_individuel_emg.m
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
% Description:   Summary heatmap of individual SPM1D results for surface EMG
%                (10 patients x 6 FES conditions, 4 muscles per cell).
%                Three-level markers per muscle (TRAPS, TRAPM, TRAPI, SERRA):
%                  - Large filled circle  : post-hoc significant vs No FES
%                  - Medium empty circle  : ANOVA significant, post-hoc n.s.
%                  - Small grey circle    : ANOVA non-significant
%                Results are hardcoded from extract_emg_cycles.m console
%                output (LP_FREQ=6Hz, ANOVA RM + ttest_paired, Bonferroni
%                alpha=0.05/6, N=3 blocks per patient, exploratoire).
% -------------------------------------------------------------------------
% Parameters :   sig(patient,condition,muscle)  — post-hoc significance matrix
%                anova_sig(patient,muscle)       — ANOVA significance matrix
% Outputs    :   1 figure : 10x6 heatmap with 4-muscle scatter markers
% -------------------------------------------------------------------------
% Dependencies : none (standalone — results hardcoded)
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution -
% NonCommercial 4.0 International License. To view a copy of this license,
% visit http://creativecommons.org/licenses/by-nc/4.0/
% =========================================================================
% Résumé des résultats SPM1D individuels — EMG
%
% Heatmap : patients (lignes) × conditions FES (colonnes)
% Chaque cellule : 4 marqueurs (TRAPS, TRAPM, TRAPI, SERRA)
%   - Grand plein   = post-hoc significatif vs No FES
%   - Moyen contour = ANOVA sig., post-hoc n.s.
%   - Petit gris    = ANOVA non significatif
%
% Source : extract_emg_cycles.m — analyse SPM1D individuelle
%          ANOVA RM + post-hoc ttest_paired vs No FES
%          Bonferroni α = 0.05/6 ≈ 0.0083 | N=3 blocs (exploratoire)
% =========================================================================

clear; clc; close all;

PATIENTS   = {'P001','P002','P003','P004','P005','P006','P007','P008','P009','P010'};
CONDITIONS = {'Min fatigue','Min stress','Random','Min pulse width','Rehab','Min force'};
MUSCLES    = {'TRAPS','TRAPM','TRAPI','SERRA'};
N_PAT  = length(PATIENTS);
N_COND = length(CONDITIONS);
N_MUS  = length(MUSCLES);

% -------------------------------------------------------------------------
% sig(patient, condition, muscle) = 1 si post-hoc significatif
% Conditions : 1=Min_fatigue 2=Min_stress 3=Random 4=Min_pulse_width 5=Rehab 6=Min_force
% Muscles    : 1=TRAPS  2=TRAPM  3=TRAPI  4=SERRA
% -------------------------------------------------------------------------
sig = zeros(N_PAT, N_COND, N_MUS);

% P003
sig(3,4,3) = 1;   % TRAPI — Min_pulse_width
sig(3,5,3) = 1;   % TRAPI — Rehab

% P005
sig(5,2,3) = 1;   % TRAPI — Min_stress
sig(5,3,3) = 1;   % TRAPI — Random

% -------------------------------------------------------------------------
% anova_sig(patient, muscle) = 1 si ANOVA RM significative (global 7 cond.)
% -------------------------------------------------------------------------
anova_sig = zeros(N_PAT, N_MUS);

% P001 : TRAPS, TRAPM
anova_sig(1,1) = 1; anova_sig(1,2) = 1;
% P002 : TRAPM, TRAPI, SERRA
anova_sig(2,2) = 1; anova_sig(2,3) = 1; anova_sig(2,4) = 1;
% P003 : TRAPM, TRAPI
anova_sig(3,2) = 1; anova_sig(3,3) = 1;
% P004 : TRAPM, TRAPI
anova_sig(4,2) = 1; anova_sig(4,3) = 1;
% P005 : tous
anova_sig(5,:) = 1;
% P006 : TRAPS, TRAPM
anova_sig(6,1) = 1; anova_sig(6,2) = 1;
% P007 : TRAPI
anova_sig(7,3) = 1;
% P008 : TRAPS, TRAPI, SERRA
anova_sig(8,1) = 1; anova_sig(8,3) = 1; anova_sig(8,4) = 1;
% P009 : TRAPS, TRAPM
anova_sig(9,1) = 1; anova_sig(9,2) = 1;
% P010 : aucun

% -------------------------------------------------------------------------
% Couleurs muscles
% -------------------------------------------------------------------------
MUS_COLORS = [0.85 0.33 0.10;   % TRAPS — orange-rouge
              0.00 0.45 0.74;   % TRAPM — bleu
              0.47 0.67 0.19;   % TRAPI — vert
              0.49 0.18 0.56];  % SERRA — violet

% -------------------------------------------------------------------------
% Figure
% -------------------------------------------------------------------------
figure('Name','Analyse SPM1D individuelle — EMG', ...
       'units','normalized','outerposition',[0.05 0.05 0.90 0.85],'Color','white');

ax = axes('Position',[0.10 0.16 0.87 0.70]);
hold on;

% Fond des cellules
for ip = 1:N_PAT
    for ic = 1:N_COND
        rectangle('Position',[ic-0.5, ip-0.5, 1, 1], ...
                  'FaceColor',[0.96 0.96 0.96], 'EdgeColor',[0.80 0.80 0.80], ...
                  'LineWidth', 0.8, 'HandleVisibility','off');
    end
end

% Décalages des 4 muscles dans la cellule
dx     = [-0.30, -0.10, 0.10, 0.30];
MS_SIG   = 110;   % post-hoc sig   — grand plein
MS_ANOVA = 70;    % ANOVA sig n.s. — moyen contour
MS_NS    = 25;    % ANOVA non sig  — petit gris

for im = 1:N_MUS
    xs_sig   = []; ys_sig   = [];
    xs_anova = []; ys_anova = [];
    xs_ns    = []; ys_ns    = [];

    for ip = 1:N_PAT
        for ic = 1:N_COND
            xc = ic + dx(im);
            if sig(ip, ic, im)
                xs_sig(end+1)   = xc; ys_sig(end+1)   = ip;
            elseif anova_sig(ip, im)
                xs_anova(end+1) = xc; ys_anova(end+1) = ip;
            else
                xs_ns(end+1)    = xc; ys_ns(end+1)    = ip;
            end
        end
    end

    if ~isempty(xs_ns)
        scatter(xs_ns, ys_ns, MS_NS, [0.82 0.82 0.82], 'o', ...
                'LineWidth', 0.5, 'HandleVisibility','off');
    end
    if ~isempty(xs_anova)
        scatter(xs_anova, ys_anova, MS_ANOVA, MUS_COLORS(im,:), 'o', ...
                'LineWidth', 1.3, 'HandleVisibility','off');
    end
    if ~isempty(xs_sig)
        scatter(xs_sig, ys_sig, MS_SIG, MUS_COLORS(im,:), 'o', 'filled', ...
                'MarkerEdgeColor', MUS_COLORS(im,:)*0.65, 'LineWidth', 0.8, ...
                'HandleVisibility','off');
    end
end

% Axes
set(ax, 'XTick', 1:N_COND, 'XTickLabel', CONDITIONS, 'FontSize', 11, 'FontWeight','bold');
set(ax, 'YTick', 1:N_PAT,  'YTickLabel', PATIENTS,   'FontSize', 10);
set(ax, 'XAxisLocation', 'top');
set(ax, 'YDir', 'reverse');
xlim([0.5, N_COND+0.5]);
ylim([0.5, N_PAT+0.5]);
grid off; box on;
ax.XAxis.TickLength = [0 0];
ax.YAxis.TickLength = [0 0];

% Légende
h = gobjects(N_MUS+2, 1);
for im = 1:N_MUS
    h(im) = scatter(NaN, NaN, MS_SIG, MUS_COLORS(im,:), 'o', 'filled', ...
                    'MarkerEdgeColor', MUS_COLORS(im,:)*0.65, ...
                    'DisplayName', [MUSCLES{im} '  (post-hoc sig.)']);
end
h(N_MUS+1) = scatter(NaN, NaN, MS_ANOVA, [0.40 0.40 0.40], 'o', 'LineWidth', 1.3, ...
                     'DisplayName', 'ANOVA sig., post-hoc n.s.');
h(N_MUS+2) = scatter(NaN, NaN, MS_NS, [0.82 0.82 0.82], 'o', 'LineWidth', 0.5, ...
                     'DisplayName', 'ANOVA non sig.');

legend(h, 'Location','southoutside', 'Orientation','horizontal', ...
       'FontSize', 10, 'Box','off');

title({'Analyse SPM1D individuelle'; ...
       'N = 3 blocs  |  Bonferroni \alpha = 0.0083'}, ...
      'FontSize', 11, 'FontWeight','bold');

hold off;
