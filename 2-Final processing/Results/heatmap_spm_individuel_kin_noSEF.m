% =========================================================================
% heatmap_spm_individuel_kin_noSEF.m
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
% Description:   Summary heatmaps of individual SPM1D results for scapular
%                kinematics (10 patients x 6 conditions, reference No FES).
%                Produces separate figures for readability :
%                Figure 1 : 3 DOF markers (X, Y, Z) per cell :
%                  - Large filled circle  : post-hoc significant vs No FES
%                  - Medium empty circle  : ANOVA significant, post-hoc n.s.
%                  - Cell background      : gradient encoding the relative
%                    rank (1-6) at which the condition was administered,
%                    among the 6 compared conditions only (No FES excluded
%                    from the ranking, since it is the reference, always 1st)
%                Figure 2 : same grid, markers shown only where
%                    significant, fill colored by the mean angular
%                    difference (condition - No FES, in degrees) over the
%                    significant cluster window (diverging colormap,
%                    blue=negatif, rouge=positif) ; marker BORDER colored
%                    by DOF, with legend.
%                Figure 3 : % of patients (N=10) with a significant
%                    post-hoc vs No FES, per condition and DOF.
%                Figure 4 : dumbbell chart - one row per significant
%                    cluster (patient x condition x DOF), showing the
%                    actual angular value (°) of the condition (filled
%                    marker) and of No FES (hollow marker), connected by a
%                    line, colored by DOF.
%                Results are hardcoded from extract_scapular_kinematics_noSEF.m
%                console output (ANOVA RM + ttest_paired, Bonferroni
%                alpha=0.05/6, N=3 blocks per patient, exploratoire) and
%                from the condition order in usercommands_conditions.m
%                (PATIENT_COND.(PID).condition).
% -------------------------------------------------------------------------
% Parameters :   sig(patient,condition,dof)     — post-hoc significance matrix
%                warn(patient,condition)        — 1 if block was duplicated
%                order(patient,condition)       — relative rank (1-6) of the
%                                                  condition among the 6
%                                                  compared conditions only
%                diffDeg(patient,condition,dof) — mean angular difference (°)
%                                                  (condition - No FES) over
%                                                  the significant cluster
%                                                  window ; NaN if n.s.
%                entryLabel/entryDOF/entryCond/entryRef — one row per
%                                                  significant cluster, for
%                                                  the Figure 4 dumbbell chart
% Outputs    :   4 figures (see Description)
% -------------------------------------------------------------------------
% Dependencies : none (standalone — results hardcoded)
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution -
% NonCommercial 4.0 International License. To view a copy of this license,
% visit http://creativecommons.org/licenses/by-nc/4.0/
% =========================================================================

clear; clc; close all;

PATIENTS   = {'P001','P002','P003','P004','P005','P006','P007','P008','P009','P010'};
CONDITIONS = {'Min fatigue','Min stress','Random','Min pulse width','Rehab','Min force'};
DOF_LABELS = {'X','Y','Z'};
N_PAT  = length(PATIENTS);
N_COND = length(CONDITIONS);

% -------------------------------------------------------------------------
% sig(patient, condition, dof) = 1 si post-hoc significatif (vs No FES)
% Conditions : 1=Min_fatigue 2=Min_stress 3=Random 4=Min_pulse_width 5=Rehab 6=Min_force
% DOF        : 1=X  2=Y  3=Z
% -------------------------------------------------------------------------
sig = zeros(N_PAT, N_COND, 3);

% P001
sig(1,3,3) = 1;                                         % Random Z

% P002
sig(2,1,2) = 1;                                         % Min_fatigue Y

% P003
sig(3,4,1) = 1;                                         % Min_pulse_width X
sig(3,3,2) = 1;                                         % Random Y
sig(3,2,3) = 1; sig(3,4,3) = 1; sig(3,5,3) = 1;        % Min_stress/Min_pulse_width/Rehab Z

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
sig(8,4,1) = 1;                                         % Min_pulse_width X
sig(8,4,3) = 1; sig(8,5,3) = 1;                         % Min_pulse_width/Rehab Z

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
warn(4,4)  = 1;   % P004 — Min_pulse_width
warn(5,1)  = 1;   % P005 — Min_fatigue
warn(6,1)  = 1;   % P006 — Min_fatigue
warn(7,2)  = 1;   % P007 — Min_stress (+ No FES non représenté, référence)
warn(8,4)  = 1;   % P008 — Min_pulse_width
warn(9,3)  = 1;   % P009 — Random
warn(10,6) = 1;   % P010 — Min_force

% -------------------------------------------------------------------------
% order(patient, condition) = rang RELATIF (1-6) de passage de la condition,
% parmi les 6 conditions comparees ici uniquement (No FES exclu du rang,
% puisque c'est la reference, toujours administree en 1er).
% Source : position absolue dans PATIENT_COND.(PID).condition
%          (usercommands_conditions.m), reordonnee 1-6 apres retrait de
%          No FES (toujours 1er).
% Colonnes : 1=Min_fatigue 2=Min_stress 3=Random 4=Min_pulse_width 5=Rehab 6=Min_force
% -------------------------------------------------------------------------
order = [ ...
    1 2 3 4 5 6;   % P001
    5 4 6 3 2 1;   % P002
    4 2 5 1 3 6;   % P003
    4 5 6 2 1 3;   % P004
    2 3 1 6 4 5;   % P005
    2 3 1 5 6 4;   % P006
    1 2 4 5 6 3;   % P007
    6 1 4 2 3 5;   % P008
    3 6 2 1 5 4;   % P009
    6 1 5 3 4 2];  % P010

% -------------------------------------------------------------------------
% diffDeg(patient, condition, dof) = difference angulaire moyenne (°)
% (condition - No FES) sur la fenetre du cluster significatif.
% Source : tableau recap. individuel imprime par extract_scapular_kinematics_noSEF.m
% (colonne "Diff (°)"). NaN si non significatif. Moyenne des clusters quand
% plusieurs existent pour une meme cellule (patient,condition,dof).
% -------------------------------------------------------------------------
diffDeg = NaN(N_PAT, N_COND, 3);

diffDeg(1,3,3)  = -13.2;                          % P001 Random Z

diffDeg(2,1,2)  = 7.6;                            % P002 Min_fatigue Y

diffDeg(3,4,1)  = 10.6;                           % P003 Min_pulse_width X
diffDeg(3,3,2)  = mean([16.4 15.1]);              % P003 Random Y (2 clusters)
diffDeg(3,2,3)  = -5.4;                           % P003 Min_stress Z
diffDeg(3,4,3)  = -7.4;                           % P003 Min_pulse_width Z
diffDeg(3,5,3)  = -8.5;                           % P003 Rehab Z

diffDeg(4,5,2)  = mean([12.7 7.4]);               % P004 Rehab Y (2 clusters)
diffDeg(4,1,3)  = -4.8;                           % P004 Min_fatigue Z
diffDeg(4,3,3)  = -23.7;                          % P004 Random Z
diffDeg(4,5,3)  = -14.0;                          % P004 Rehab Z
diffDeg(4,6,3)  = -25.6;                          % P004 Min_force Z

diffDeg(6,1,1)  = 13.0;                           % P006 Min_fatigue X
diffDeg(6,1,2)  = 10.1;                           % P006 Min_fatigue Y
diffDeg(6,6,2)  = 3.0;                            % P006 Min_force Y
diffDeg(6,1,3)  = -11.7;                          % P006 Min_fatigue Z
diffDeg(6,3,3)  = -8.2;                           % P006 Random Z

diffDeg(7,2,1)  = mean([13.2 12.5]);              % P007 Min_stress X (2 clusters)
diffDeg(7,2,3)  = mean([-3.3 -1.9 -3.6 -3.3 -2.6]); % P007 Min_stress Z (5 clusters)
diffDeg(7,5,3)  = mean([-8.8 -7.4]);              % P007 Rehab Z (2 clusters)

diffDeg(8,4,1)  = mean([24.1 21.2]);              % P008 Min_pulse_width X (2 clusters)
diffDeg(8,4,3)  = -20.2;                          % P008 Min_pulse_width Z
diffDeg(8,5,3)  = -15.7;                          % P008 Rehab Z

diffDeg(10,1,1) = 11.1;                           % P010 Min_fatigue X
diffDeg(10,6,2) = 10.9;                           % P010 Min_force Y
diffDeg(10,5,3) = -8.7;                           % P010 Rehab Z

% -------------------------------------------------------------------------
% Couleurs DOF
% -------------------------------------------------------------------------
DOF_COLORS = [0.85 0.33 0.10;   % X — orange-rouge
              0.00 0.45 0.74;   % Y — bleu
              0.47 0.67 0.19];  % Z — vert

% Colormap pour le gradient d'ordre relatif de passage (1 = tres clair, 6 = clair/gris-bleu)
% Reste volontairement dans des tons clairs pour ne pas nuire a la lisibilite des marqueurs DOF
LIGHT_COLOR = [0.97 0.97 0.96];
DARK_COLOR  = [0.68 0.74 0.82];
ORDER_CMAP  = [linspace(LIGHT_COLOR(1), DARK_COLOR(1), 64)', ...
               linspace(LIGHT_COLOR(2), DARK_COLOR(2), 64)', ...
               linspace(LIGHT_COLOR(3), DARK_COLOR(3), 64)'];
ORDER_RANGE = [1 6];

% Colormap divergente pour la difference angulaire (bleu = negatif, rouge = positif)
NEG_COLOR = [0.22 0.42 0.72];
MID_COLOR = [0.97 0.97 0.97];
POS_COLOR = [0.78 0.22 0.20];
DIFF_CMAP = [linspace(NEG_COLOR(1), MID_COLOR(1), 32)', linspace(NEG_COLOR(2), MID_COLOR(2), 32)', linspace(NEG_COLOR(3), MID_COLOR(3), 32)'; ...
             linspace(MID_COLOR(1), POS_COLOR(1), 32)', linspace(MID_COLOR(2), POS_COLOR(2), 32)', linspace(MID_COLOR(3), POS_COLOR(3), 32)'];
maxAbsDiff = max(abs(diffDeg(:)), [], 'omitnan');
DIFF_RANGE = [-ceil(maxAbsDiff), ceil(maxAbsDiff)];

% -------------------------------------------------------------------------
% FIGURE 1 : significativite + ordre de passage
% -------------------------------------------------------------------------
figure('Name','SPM1D individuel — significativite vs No FES', ...
       'units','normalized','outerposition',[0.05 0.05 0.90 0.85],'Color','white');

ax = axes('Position',[0.09 0.16 0.83 0.70]);
hold on;

% Fond des cellules (gradient = ordre de passage)
for ip = 1:N_PAT
    for ic = 1:N_COND
        cellColor = orderColor(order(ip,ic), ORDER_RANGE, ORDER_CMAP);
        rectangle('Position',[ic-0.5, ip-0.5, 1, 1], ...
                  'FaceColor', cellColor, 'EdgeColor', [0.85 0.85 0.85], ...
                  'LineWidth', 0.75, 'HandleVisibility','off');
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

% Colorbar du gradient d'ordre relatif de passage
colormap(ax, ORDER_CMAP);
caxis(ax, ORDER_RANGE);
cb = colorbar(ax, 'Position', [0.935 0.16 0.02 0.70]);
cb.Label.String = 'Ordre relatif (1er a 6e parmi les conditions comparees)';
cb.Ticks = 1:6;

% Légende explicite
h = gobjects(4,1);
for id = 1:3
    h(id) = scatter(NaN, NaN, MS_SIG, DOF_COLORS(id,:), 'o', 'filled', ...
                    'MarkerEdgeColor', DOF_COLORS(id,:)*0.65, ...
                    'DisplayName', ['DOF ' DOF_LABELS{id} '  (sig.)']);
end
h(4) = scatter(NaN, NaN, MS_NS, [0.82 0.82 0.82], 'o', 'LineWidth', 0.8, ...
               'DisplayName', 'n.s.');
legend(h, 'Location','southoutside', ...
       'Orientation','horizontal','FontSize', 10,'Box','off');

title({'Analyse SPM1D individuelle — reference No FES'; ...
     'N = 3 blocs  |  Bonferroni \alpha = 0.0083'}, ...
      'FontSize', 13, 'FontWeight', 'bold');

hold off;

% -------------------------------------------------------------------------
% FIGURE 2 : difference angulaire (condition - No FES)
% -------------------------------------------------------------------------
figure('Name','SPM1D individuel — difference angulaire vs No FES', ...
       'units','normalized','outerposition',[0.05 0.05 0.90 0.85],'Color','white');

ax3 = axes('Position',[0.09 0.16 0.83 0.70]);
hold on;

for ip = 1:N_PAT
    for ic = 1:N_COND
        rectangle('Position',[ic-0.5, ip-0.5, 1, 1], ...
                  'FaceColor', [0.96 0.96 0.96], 'EdgeColor', [0.85 0.85 0.85], ...
                  'LineWidth', 0.75, 'HandleVisibility','off');
    end
end

for id = 1:3
    xs = []; ys = []; cs = [];
    for ip = 1:N_PAT
        for ic = 1:N_COND
            if sig(ip, ic, id)
                xs(end+1) = ic + dx(id);
                ys(end+1) = ip;
                cs(end+1,:) = valueColor(diffDeg(ip,ic,id), DIFF_RANGE, DIFF_CMAP);
            end
        end
    end
    if ~isempty(xs)
        scatter(xs, ys, MS_SIG, cs, 'o', 'filled', ...
                'MarkerEdgeColor', DOF_COLORS(id,:), 'LineWidth', 2, 'HandleVisibility','off');
    end
end

set(ax3, 'XTick', 1:N_COND, 'XTickLabel', CONDITIONS, 'FontSize', 11, 'FontWeight','bold');
set(ax3, 'YTick', 1:N_PAT,  'YTickLabel', PATIENTS,   'FontSize', 10);
set(ax3, 'XAxisLocation', 'top');
set(ax3, 'YDir', 'reverse');
xlim(ax3, [0.5, N_COND+0.5]);
ylim(ax3, [0.5, N_PAT+0.5]);
grid off; box on;
ax3.XAxis.TickLength = [0 0];
ax3.YAxis.TickLength = [0 0];

colormap(ax3, DIFF_CMAP);
caxis(ax3, DIFF_RANGE);
cb2 = colorbar(ax3, 'Position', [0.935 0.16 0.02 0.70]);
cb2.Label.String = 'Diff. angulaire condition - No FES (°)';

hDof2 = gobjects(3,1);
for id = 1:3
    hDof2(id) = plot(NaN, NaN, 'o', 'MarkerFaceColor', 'none', ...
                      'MarkerEdgeColor', DOF_COLORS(id,:), 'LineWidth', 2, 'MarkerSize', 10, ...
                      'DisplayName', ['DOF ' DOF_LABELS{id}]);
end
legend(hDof2, 'Location','southoutside', 'Orientation','horizontal', 'FontSize', 10, 'Box','off');

title({'Amplitude de la difference angulaire — reference No FES'; ...
     'Clusters significatifs uniquement (moyenne si plusieurs clusters) — bordure = DOF'}, ...
      'FontSize', 13, 'FontWeight', 'bold');

hold off;

% -------------------------------------------------------------------------
% FIGURE 3 : % de patients significatifs par condition et par DOF
% -------------------------------------------------------------------------
pctSig = zeros(N_COND, 3);
for ic = 1:N_COND
    for id = 1:3
        pctSig(ic, id) = 100 * sum(sig(:, ic, id)) / N_PAT;
    end
end

figure('Name','SPM1D individuel — % patients significatifs vs No FES', ...
       'units','normalized','outerposition',[0.05 0.05 0.90 0.85],'Color','white');

ax2 = axes('Position',[0.09 0.16 0.83 0.70]);
b = bar(ax2, pctSig, 'grouped');
for id = 1:3
    b(id).FaceColor = DOF_COLORS(id,:);
end
hold(ax2, 'on');
set(ax2, 'XTick', 1:N_COND, 'XTickLabel', CONDITIONS, 'FontSize', 11, 'FontWeight','bold');
xlim(ax2, [0.5, N_COND+0.5]);
ylim(ax2, [0 100]);
ylabel(ax2, '% patients significatifs', 'FontSize', 11);
grid(ax2, 'on'); box(ax2, 'on');

hLeg = gobjects(3,1);
for id = 1:3
    hLeg(id) = plot(NaN, NaN, 's', 'MarkerFaceColor', DOF_COLORS(id,:), ...
                     'MarkerEdgeColor','none', 'MarkerSize', 10, ...
                     'DisplayName', ['DOF ' DOF_LABELS{id}]);
end
legend(hLeg, 'Location','southoutside', 'Orientation','horizontal', 'FontSize', 10, 'Box','off');

title('% de patients (N=10) avec post-hoc significatif vs No FES, par condition et DOF', ...
      'FontSize', 13, 'FontWeight', 'bold');

% -------------------------------------------------------------------------
% Liste des entrees significatives : valeur angulaire (°) reelle de la
% condition et de No FES, sur la fenetre du cluster significatif (une ligne
% par patient x condition x DOF significatif, moyenne si plusieurs clusters).
% Source : colonnes "Angle cond (°)" / "Angle No FES (°)" du tableau recap.
% individuel (milieu de range).
% -------------------------------------------------------------------------
entryLabel = { ...
    'P001 - Random (Z)'; ...
    'P002 - Min fatigue (Y)'; ...
    'P003 - Min pulse width (X)'; ...
    'P003 - Random (Y)'; ...
    'P003 - Min stress (Z)'; ...
    'P003 - Min pulse width (Z)'; ...
    'P003 - Rehab (Z)'; ...
    'P004 - Rehab (Y)'; ...
    'P004 - Min fatigue (Z)'; ...
    'P004 - Random (Z)'; ...
    'P004 - Rehab (Z)'; ...
    'P004 - Min force (Z)'; ...
    'P006 - Min fatigue (X)'; ...
    'P006 - Min fatigue (Y)'; ...
    'P006 - Min force (Y)'; ...
    'P006 - Min fatigue (Z)'; ...
    'P006 - Random (Z)'; ...
    'P007 - Min stress (X)'; ...
    'P007 - Min stress (Z)'; ...
    'P007 - Rehab (Z)'; ...
    'P008 - Min pulse width (X)'; ...
    'P008 - Min pulse width (Z)'; ...
    'P008 - Rehab (Z)'; ...
    'P010 - Min fatigue (X)'; ...
    'P010 - Min force (Y)'; ...
    'P010 - Rehab (Z)'};

entryDOF = [3 2 1 2 3 3 3 2 3 3 3 3 1 2 2 3 3 1 3 3 1 3 3 1 2 3];   % 1=X 2=Y 3=Z

entryCond = [ ...
    -22.70; 17.20; -25.30; 46.10; -23.70; -25.40; -23.90; ...
    38.025; -3.20; -18.75; -12.75; -21.90; ...
    -2.15; 51.45; 50.35; -12.05; -8.25; ...
    -39.35; -1.05; -3.80; ...
    -5.525; -27.40; -29.05; ...
    -12.00; 37.40; -11.60];

entryRef = [ ...
    -9.55; 9.60; -35.90; 30.35; -18.30; -18.00; -15.40; ...
    27.975; 1.60; 4.90; 1.20; 3.70; ...
    -15.05; 41.35; 47.30; -0.30; 0.00; ...
    -52.10; 1.84; 4.325; ...
    -28.175; -7.20; -13.45; ...
    -23.00; 26.50; -2.90];

N_ENTRY = length(entryLabel);

% -------------------------------------------------------------------------
% FIGURE 4 : valeur angulaire reelle condition vs No FES (dumbbell chart)
% -------------------------------------------------------------------------
figure('Name','SPM1D individuel — angle condition vs No FES (clusters significatifs)', ...
       'units','normalized','outerposition',[0.05 0.05 0.90 0.85],'Color','white');

ax4 = axes('Position',[0.30 0.08 0.63 0.80]);
hold on;

xline(0, 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility','off');

for k = 1:N_ENTRY
    yk  = N_ENTRY - k + 1;
    dof = entryDOF(k);
    plot([entryRef(k) entryCond(k)], [yk yk], '-', ...
         'Color', [0.75 0.75 0.75], 'LineWidth', 1.5, 'HandleVisibility','off');
    plot(entryRef(k), yk, 'o', 'MarkerFaceColor', 'none', ...
         'MarkerEdgeColor', DOF_COLORS(dof,:), 'LineWidth', 2, 'MarkerSize', 9, ...
         'HandleVisibility','off');
    plot(entryCond(k), yk, 'o', 'MarkerFaceColor', DOF_COLORS(dof,:), ...
         'MarkerEdgeColor', DOF_COLORS(dof,:), 'LineWidth', 1, 'MarkerSize', 9, ...
         'HandleVisibility','off');
end

set(ax4, 'YTick', 1:N_ENTRY, 'YTickLabel', flipud(entryLabel), 'FontSize', 9);
ylim(ax4, [0.5, N_ENTRY+0.5]);
xlabel(ax4, 'Angle (°)', 'FontSize', 11);
grid(ax4, 'on'); box(ax4, 'on');

hLeg4 = gobjects(5,1);
for id = 1:3
    hLeg4(id) = plot(NaN, NaN, 'o', 'MarkerFaceColor', DOF_COLORS(id,:), ...
                      'MarkerEdgeColor', DOF_COLORS(id,:), 'MarkerSize', 9, ...
                      'DisplayName', ['DOF ' DOF_LABELS{id}]);
end
hLeg4(4) = plot(NaN, NaN, 'o', 'MarkerFaceColor', [0.4 0.4 0.4], ...
                'MarkerEdgeColor', [0.4 0.4 0.4], 'MarkerSize', 9, 'DisplayName', 'Condition (plein)');
hLeg4(5) = plot(NaN, NaN, 'o', 'MarkerFaceColor', 'none', ...
                'MarkerEdgeColor', [0.4 0.4 0.4], 'LineWidth', 2, 'MarkerSize', 9, 'DisplayName', 'No FES (creux)');
legend(hLeg4, 'Location','southoutside', 'Orientation','horizontal', 'FontSize', 9, 'Box','off', 'NumColumns', 5);

title({'Valeur angulaire reelle : condition vs No FES'; ...
     'Une ligne par cluster significatif (moyenne si plusieurs) — couleur = DOF, plein = condition, creux = No FES'}, ...
      'FontSize', 13, 'FontWeight', 'bold');

hold off;


% =========================================================================
% FONCTIONS LOCALES
% =========================================================================

function c = orderColor(v, range, cmap)
    n = size(cmap, 1);
    idx = round(interp1(range, [1 n], v));
    idx = max(1, min(n, idx));
    c = cmap(idx, :);
end

function c = valueColor(v, range, cmap)
    n = size(cmap, 1);
    idx = round(interp1(range, [1 n], v));
    idx = max(1, min(n, idx));
    c = cmap(idx, :);
end
