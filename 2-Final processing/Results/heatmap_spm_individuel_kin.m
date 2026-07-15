% =========================================================================
% heatmap_spm_individuel_kin.m
% Résumé des résultats SPM1D individuels — cinématique scapulaire
%
% Heatmap : patients (lignes) × conditions FES (colonnes)
% Chaque cellule : 3 cercles (DOF X, Y, Z) — plein = post-hoc significatif
% Fond orange = bloc dupliqué (2 blocs disponibles au lieu de 3)
%
% Source : extract_scapular_kinematics.m — analyse SPM1D individuelle
%          ANOVA RM + post-hoc ttest_paired vs No FES
%          Bonferroni α = 0.05/6 ≈ 0.0083 | N=3 blocs (exploratoire)
% =========================================================================

clear; clc; close all;

PATIENTS   = {'P001','P002','P003','P004','P005','P006','P007','P008','P009','P010'};
CONDITIONS = {'Min fatigue','Min stress','Random','Min pw','Rehab','Min force'};
DOF_LABELS = {'X','Y','Z'};
N_PAT  = length(PATIENTS);
N_COND = length(CONDITIONS);

% -------------------------------------------------------------------------
% sig(patient, condition, dof) = 1 si post-hoc significatif
% Conditions : 1=Min_fatigue 2=Min_stress 3=Random 4=Min_pw 5=Rehab 6=Min_force
% DOF        : 1=X  2=Y  3=Z
% -------------------------------------------------------------------------
sig = zeros(N_PAT, N_COND, 3);

% P001
sig(1,3,3) = 1;                                         % Random Z

% P002
sig(2,1,2) = 1;                                         % Min_fatigue Y

% P003
sig(3,4,1) = 1;                                         % Min_pw X
sig(3,3,2) = 1;                                         % Random Y
sig(3,2,3) = 1; sig(3,4,3) = 1; sig(3,5,3) = 1;        % Min_stress/Min_pw/Rehab Z

% P004
sig(4,5,2) = 1;                                         % Rehab Y
sig(4,1,3) = 1; sig(4,3,3) = 1;                         % Min_fatigue/Random Z
sig(4,5,3) = 1; sig(4,6,3) = 1;                         % Rehab/Min_force Z

% P005 — aucun

% P006
sig(6,1,1) = 1;                                         % Min_fatigue X
sig(6,1,2) = 1; sig(6,6,2) = 1;                         % Min_fatigue/Min_force Y
sig(6,1,3) = 1; sig(6,3,3) = 1;                         % Min_fatigue/Random Z

% P007
sig(7,2,1) = 1;                                         % Min_stress X
sig(7,2,3) = 1; sig(7,5,3) = 1;                         % Min_stress/Rehab Z

% P008
sig(8,4,1) = 1;                                         % Min_pw X
sig(8,4,3) = 1; sig(8,5,3) = 1;                         % Min_pw/Rehab Z

% P009 — aucun

% P010
sig(10,1,1) = 1;                                        % Min_fatigue X
sig(10,6,2) = 1;                                        % Min_force Y
sig(10,5,3) = 1;                                        % Rehab Z

% -------------------------------------------------------------------------
% warn(patient, condition) = 1 si bloc dupliqué pour cette condition
% -------------------------------------------------------------------------
warn = zeros(N_PAT, N_COND);
warn(1,2)  = 1;   % P001 — Min_stress
warn(2,5)  = 1;   % P002 — Rehab
warn(3,2)  = 1;   % P003 — Min_stress
warn(4,4)  = 1;   % P004 — Min_pw
warn(5,1)  = 1;   % P005 — Min_fatigue
warn(6,1)  = 1;   % P006 — Min_fatigue
warn(7,2)  = 1;   % P007 — Min_stress (+ No FES non représenté)
warn(8,4)  = 1;   % P008 — Min_pw
warn(9,3)  = 1;   % P009 — Random
warn(10,6) = 1;   % P010 — Min_force

% -------------------------------------------------------------------------
% Couleurs DOF
% -------------------------------------------------------------------------
DOF_COLORS = [0.85 0.33 0.10;   % X — orange-rouge
              0.00 0.45 0.74;   % Y — bleu
              0.47 0.67 0.19];  % Z — vert

% -------------------------------------------------------------------------
% Figure
% -------------------------------------------------------------------------
figure('Name','Analyse SPM1D individuelle', ...
       'units','normalized','outerposition',[0.05 0.05 0.90 0.85],'Color','white');

ax = axes('Position',[0.10 0.16 0.87 0.70]);
hold on;

% Fond des cellules + bordure ANOVA (significative pour tous patients × DOF)
ANOVA_COLOR = [0.20 0.50 0.80]; % bleu sobre
for ip = 1:N_PAT
    for ic = 1:N_COND
        rectangle('Position',[ic-0.5, ip-0.5, 1, 1], ...
                  'FaceColor',[0.96 0.96 0.96], 'EdgeColor', ANOVA_COLOR, ...
                  'LineWidth', 1.4, 'HandleVisibility','off');
    end
end

% Marqueurs DOF avec scatter (toujours circulaires)
dx = [-0.26, 0, 0.26];
MS_SIG = 120;   % taille marqueur significatif
MS_NS  = 40;    % taille marqueur n.s.

for id = 1:3
    xs_sig = []; ys_sig = [];
    xs_ns  = []; ys_ns  = [];
    for ip = 1:N_PAT
        for ic = 1:N_COND
            xc = ic + dx(id);
            if sig(ip, ic, id)
                xs_sig(end+1) = xc;
                ys_sig(end+1) = ip;
            else
                xs_ns(end+1) = xc;
                ys_ns(end+1) = ip;
            end
        end
    end
    if ~isempty(xs_ns)
        scatter(xs_ns, ys_ns, MS_NS, [0.82 0.82 0.82], 'o', ...
                'LineWidth', 0.8, 'HandleVisibility','off');
    end
    if ~isempty(xs_sig)
        scatter(xs_sig, ys_sig, MS_SIG, DOF_COLORS(id,:), 'o', 'filled', ...
                'MarkerEdgeColor', DOF_COLORS(id,:)*0.65, 'LineWidth', 0.8, ...
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

% Légende explicite
h = gobjects(5,1);
for id = 1:3
    h(id) = scatter(NaN, NaN, MS_SIG, DOF_COLORS(id,:), 'o', 'filled', ...
                    'MarkerEdgeColor', DOF_COLORS(id,:)*0.65, ...
                    'DisplayName', ['DOF ' DOF_LABELS{id} '  (sig.)']);
end
h(4) = scatter(NaN, NaN, MS_NS, [0.82 0.82 0.82], 'o', 'LineWidth', 0.8, ...
               'DisplayName', 'n.s.');
h(5) = plot(NaN, NaN, 's', 'MarkerFaceColor', [0.96 0.96 0.96], ...
            'MarkerEdgeColor', ANOVA_COLOR, 'MarkerSize', 12, 'LineWidth', 1.4, ...
            'DisplayName', 'ANOVA (sig.)');
legend(h([5 1 2 3 4]), 'Location','southoutside','Orientation','horizontal','FontSize', 10,'Box','off');

title({'Analyse SPM1D individuelle'; ...
     'N = 3 blocs  |  Bonferroni \alpha = 0.0083'}, ...
      'FontSize', 11, 'FontWeight','bold');

hold off;
