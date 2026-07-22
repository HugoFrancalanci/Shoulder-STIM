% =========================================================================
% heatmap_spm_individuel_kin_rehab.m
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
%                kinematics (10 patients x 5 conditions). No FES vs Rehab
%                is excluded here — already covered by
%                heatmap_spm_individuel_kin_noSEF.m (Rehab vs No FES).
%                Produces 4 separate figures for readability :
%                Figure 1 : 3 DOF markers (X, Y, Z) per cell :
%                  - Large filled circle  : post-hoc significant vs Rehab
%                  - Medium empty circle  : ANOVA significant, post-hoc n.s.
%                  - Cell background      : gradient encoding the relative
%                    rank (1-5) at which the condition was administered,
%                    among the 5 compared conditions only (No FES and
%                    Rehab excluded from the ranking, since not columns)
%                Figure 2 : same grid, markers shown only where
%                    significant, fill colored by the mean angular
%                    difference (condition - Rehab, in degrees) over the
%                    significant cluster window (diverging colormap,
%                    blue=negatif, rouge=positif) ; marker BORDER colored
%                    by DOF (same code as Figure 1), with legend.
%                Figure 3 : % of patients (N=10) with a
%                    significant post-hoc vs Rehab, per condition and DOF.
%                Figure 4 : dumbbell chart — one row per significant
%                    cluster (patient x condition x DOF), showing the
%                    actual angular value (°) of the condition (filled
%                    marker) and of Rehab (hollow marker), connected by a
%                    line, colored by DOF. Lets you read the real angle
%                    levels directly, not just the difference.
%                Results are hardcoded from extract_scapular_kinematics_rehab.m
%                console output (ANOVA RM + ttest_paired, Bonferroni
%                alpha=0.05/5, N=3 blocks per patient, exploratoire) and
%                from the condition order in usercommands_conditions.m
%                (PATIENT_COND.(PID).condition).
% -------------------------------------------------------------------------
% Parameters :   sig(patient,condition,dof)     — post-hoc significance matrix
%                warn(patient,condition)        — 1 if block was duplicated
%                order(patient,condition)       — relative rank (1-5) of the
%                                                  condition among the 5
%                                                  compared conditions only
%                diffDeg(patient,condition,dof) — mean angular difference (°)
%                                                  (condition - Rehab) over
%                                                  the significant cluster
%                                                  window ; NaN if n.s.
%                entryLabel/entryDOF/entryFes/entryRehab — one row per
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
CONDITIONS = {'Min fatigue','Min stress','Random','Min pulse width','Min force'};
DOF_LABELS = {'X','Y','Z'};
N_PAT  = length(PATIENTS);
N_COND = length(CONDITIONS);

% -------------------------------------------------------------------------
% sig(patient, condition, dof) = 1 si post-hoc significatif (vs Rehab)
% Conditions : 1=Min_fatigue 2=Min_stress 3=Random 4=Min_pulse_width 5=Min_force
% DOF        : 1=X  2=Y  3=Z
% -------------------------------------------------------------------------
sig = zeros(N_PAT, N_COND, 3);

% P001 — aucun

% P002
sig(2,1,3) = 1;                                         % Min_fatigue Z

% P003
sig(3,2,2) = 1;                                         % Min_stress Y
sig(3,1,3) = 1;                                         % Min_fatigue Z

% P004
sig(4,1,3) = 1; sig(4,4,3) = 1;                        % Min_fatigue/Min_pulse_width Z

% P005 — aucun

% P006
sig(6,3,1) = 1;                                         % Random X
sig(6,3,2) = 1;                                         % Random Y
sig(6,4,3) = 1;                                         % Min_pulse_width Z

% P007
sig(7,1,1) = 1; sig(7,5,1) = 1;                        % Min_fatigue/Min_force X
sig(7,2,3) = 1;                                         % Min_stress Z

% P008
sig(8,4,3) = 1;                                         % Min_pulse_width Z

% P009
sig(9,4,2) = 1; sig(9,5,2) = 1;                        % Min_pulse_width/Min_force Y

% P010 — aucun

% -------------------------------------------------------------------------
% warn(patient, condition) = 1 si bloc dupliqué pour cette condition
% -------------------------------------------------------------------------
warn = zeros(N_PAT, N_COND);
warn(1,2)  = 1;   % P001 — Min_stress
warn(3,2)  = 1;   % P003 — Min_stress
warn(4,4)  = 1;   % P004 — Min_pulse_width
warn(5,1)  = 1;   % P005 — Min_fatigue
warn(6,1)  = 1;   % P006 — Min_fatigue
warn(7,2)  = 1;   % P007 — Min_stress
warn(8,4)  = 1;   % P008 — Min_pulse_width
warn(9,3)  = 1;   % P009 — Random
warn(10,5) = 1;   % P010 — Min_force
% P002 — Rehab dupliqué (2 blocs) non représenté (référence, pas une colonne)
% P007 — No FES dupliqué (2 blocs) non représenté (comparaison exclue ici)

% -------------------------------------------------------------------------
% order(patient, condition) = rang RELATIF (1-5) de passage de la condition,
% parmi les 5 conditions comparees ici uniquement (No FES et Rehab exclus
% des colonnes ne sont pas comptes dans ce rang).
% Source : position absolue dans PATIENT_COND.(PID).condition
%          (usercommands_conditions.m), reordonnee 1-5 apres retrait de
%          No FES (toujours 1er) et Rehab (reference).
% Colonnes : 1=Min_fatigue 2=Min_stress 3=Random 4=Min_pulse_width 5=Min_force
% -------------------------------------------------------------------------
order = [ ...
    1 2 3 4 5;   % P001
    4 3 5 2 1;   % P002
    3 2 4 1 5;   % P003
    3 4 5 1 2;   % P004
    2 3 1 5 4;   % P005
    2 3 1 5 4;   % P006
    1 2 4 5 3;   % P007
    5 1 3 2 4;   % P008
    3 5 2 1 4;   % P009
    5 1 4 3 2];  % P010

% -------------------------------------------------------------------------
% diffDeg(patient, condition, dof) = difference angulaire moyenne (°)
% (condition - Rehab) sur la fenetre du cluster significatif.
% Source : tableau recap. individuel imprime par extract_scapular_kinematics_rehab.m
% (colonne "Diff (°)"). NaN si non significatif. Quand plusieurs clusters
% existent pour une meme cellule (patient,condition,dof), valeur moyenne
% des clusters (ex: P003 Min stress Y : -11.9 et -13.1 -> -12.5).
% -------------------------------------------------------------------------
diffDeg = NaN(N_PAT, N_COND, 3);

diffDeg(2,1,3) = -5.3;                  % P002 Min_fatigue Z

diffDeg(3,2,2) = mean([-11.9 -13.1]);   % P003 Min_stress Y (2 clusters)
diffDeg(3,1,3) = -5.4;                  % P003 Min_fatigue Z

diffDeg(4,1,3) = -9.1;                  % P004 Min_fatigue Z
diffDeg(4,4,3) = 10.4;                  % P004 Min_pulse_width Z

diffDeg(6,3,1) = 9.6;                   % P006 Random X
diffDeg(6,3,2) = 4.2;                   % P006 Random Y
diffDeg(6,4,3) = mean([4.0 3.6]);       % P006 Min_pulse_width Z (2 clusters)

diffDeg(7,1,1) = -7.1;                  % P007 Min_fatigue X
diffDeg(7,5,1) = -1.0;                  % P007 Min_force X
diffDeg(7,2,3) = 3.9;                   % P007 Min_stress Z

diffDeg(8,4,3) = 2.1;                   % P008 Min_pulse_width Z

diffDeg(9,4,2) = -7.2;                  % P009 Min_pulse_width Y
diffDeg(9,5,2) = -4.0;                  % P009 Min_force Y

% -------------------------------------------------------------------------
% Liste des entrees significatives : valeur angulaire (°) reelle de la
% condition FES et de Rehab, sur la fenetre du cluster significatif
% (une ligne par patient x condition x DOF significatif). Utilise pour la
% Figure 4 (dumbbell chart). Source : colonnes "Angle cond (°)" / "Angle
% Rehab (°)" du tableau recap. individuel (milieu de range ; moyenne si
% plusieurs clusters, ex: P003 Min stress Y).
% -------------------------------------------------------------------------
entryLabel = { ...
    'P002 - Min fatigue (Z)'; ...
    'P003 - Min stress (Y)'; ...
    'P003 - Min fatigue (Z)'; ...
    'P004 - Min fatigue (Z)'; ...
    'P004 - Min pulse width (Z)'; ...
    'P006 - Random (X)'; ...
    'P006 - Random (Y)'; ...
    'P006 - Min pulse width (Z)'; ...
    'P007 - Min fatigue (X)'; ...
    'P007 - Min force (X)'; ...
    'P007 - Min stress (Z)'; ...
    'P008 - Min pulse width (Z)'; ...
    'P009 - Min pulse width (Y)'; ...
    'P009 - Min force (Y)'};

entryDOF = [3 2 3 3 3 1 2 3 1 1 3 3 2 2];   % 1=X 2=Y 3=Z

entryFes = [ ...
    -11.05; 29.225; -29.2; -2.15; -8.4; ...
    -18.1; 53.6; -9.8; -35.0; -40.95; ...
    -0.85; -17.7; 38.8; 31.8];

entryRehab = [ ...
    -5.75; 41.675; -23.85; 6.95; -18.8; ...
    -27.7; 49.4; -13.625; -27.9; -39.95; ...
    -4.75; -19.7; 46.0; 35.85];

N_ENTRY = length(entryLabel);

% -------------------------------------------------------------------------
% Couleurs DOF
% -------------------------------------------------------------------------
DOF_COLORS = [0.85 0.33 0.10;   % X — orange-rouge
              0.00 0.45 0.74;   % Y — bleu
              0.47 0.67 0.19];  % Z — vert

% Colormap pour le gradient d'ordre relatif de passage (1 = tres clair, 5 = clair/gris-bleu)
% Reste volontairement dans des tons clairs pour ne pas nuire a la lisibilite des marqueurs DOF
LIGHT_COLOR = [0.97 0.97 0.96];
DARK_COLOR  = [0.68 0.74 0.82];
ORDER_CMAP  = [linspace(LIGHT_COLOR(1), DARK_COLOR(1), 64)', ...
               linspace(LIGHT_COLOR(2), DARK_COLOR(2), 64)', ...
               linspace(LIGHT_COLOR(3), DARK_COLOR(3), 64)'];
ORDER_RANGE = [1 5];

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
figure('Name','SPM1D individuel — significativite vs Rehab', ...
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
cb.Label.String = 'Ordre relatif (1er a 5e parmi les conditions comparees)';
cb.Ticks = 1:5;

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

title({'Analyse SPM1D individuelle — reference Rehab'; ...
     'N = 3 blocs  |  Bonferroni \alpha = 0.01'}, ...
      'FontSize', 13, 'FontWeight', 'bold');

hold off;

% -------------------------------------------------------------------------
% FIGURE 2 : difference angulaire (condition - Rehab)
% -------------------------------------------------------------------------
figure('Name','SPM1D individuel — difference angulaire vs Rehab', ...
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
                cs(end+1,:) = diffColor(diffDeg(ip,ic,id), DIFF_RANGE, DIFF_CMAP);
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
cb2.Label.String = 'Diff. angulaire condition - Rehab (°)';

% Légende : la bordure du marqueur indique le DOF (remplissage = valeur de la diff.)
hDof2 = gobjects(3,1);
for id = 1:3
    hDof2(id) = plot(NaN, NaN, 'o', 'MarkerFaceColor', 'none', ...
                      'MarkerEdgeColor', DOF_COLORS(id,:), 'LineWidth', 2, 'MarkerSize', 10, ...
                      'DisplayName', ['DOF ' DOF_LABELS{id}]);
end
legend(hDof2, 'Location','southoutside', 'Orientation','horizontal', 'FontSize', 10, 'Box','off');

title({'Amplitude de la difference angulaire — reference Rehab'; ...
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

figure('Name','SPM1D individuel — % patients significatifs vs Rehab', ...
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

title('% de patients (N=10) avec post-hoc significatif vs Rehab, par condition et DOF', ...
      'FontSize', 13, 'FontWeight', 'bold');

% -------------------------------------------------------------------------
% FIGURE 4 : valeur angulaire reelle FES vs Rehab (dumbbell chart)
% -------------------------------------------------------------------------
figure('Name','SPM1D individuel — angle FES vs Rehab (clusters significatifs)', ...
       'units','normalized','outerposition',[0.05 0.05 0.90 0.85],'Color','white');

ax4 = axes('Position',[0.28 0.10 0.65 0.78]);
hold on;

xline(0, 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility','off');

for k = 1:N_ENTRY
    yk  = N_ENTRY - k + 1;   % P002 en haut, P009 en bas
    dof = entryDOF(k);
    plot([entryRehab(k) entryFes(k)], [yk yk], '-', ...
         'Color', [0.75 0.75 0.75], 'LineWidth', 1.5, 'HandleVisibility','off');
    plot(entryRehab(k), yk, 'o', 'MarkerFaceColor', 'none', ...
         'MarkerEdgeColor', DOF_COLORS(dof,:), 'LineWidth', 2, 'MarkerSize', 9, ...
         'HandleVisibility','off');
    plot(entryFes(k), yk, 'o', 'MarkerFaceColor', DOF_COLORS(dof,:), ...
         'MarkerEdgeColor', DOF_COLORS(dof,:), 'LineWidth', 1, 'MarkerSize', 9, ...
         'HandleVisibility','off');
end

set(ax4, 'YTick', 1:N_ENTRY, 'YTickLabel', flipud(entryLabel), 'FontSize', 10);
ylim(ax4, [0.5, N_ENTRY+0.5]);
xlabel(ax4, 'Angle (°)', 'FontSize', 11);
grid(ax4, 'on'); box(ax4, 'on');

% Légende : couleur = DOF, rempli = condition, creux = Rehab
hLeg4 = gobjects(5,1);
for id = 1:3
    hLeg4(id) = plot(NaN, NaN, 'o', 'MarkerFaceColor', DOF_COLORS(id,:), ...
                      'MarkerEdgeColor', DOF_COLORS(id,:), 'MarkerSize', 9, ...
                      'DisplayName', ['DOF ' DOF_LABELS{id}]);
end
hLeg4(4) = plot(NaN, NaN, 'o', 'MarkerFaceColor', [0.4 0.4 0.4], ...
                'MarkerEdgeColor', [0.4 0.4 0.4], 'MarkerSize', 9, 'DisplayName', 'Condition (plein)');
hLeg4(5) = plot(NaN, NaN, 'o', 'MarkerFaceColor', 'none', ...
                'MarkerEdgeColor', [0.4 0.4 0.4], 'LineWidth', 2, 'MarkerSize', 9, 'DisplayName', 'Rehab (creux)');
legend(hLeg4, 'Location','southoutside', 'Orientation','horizontal', 'FontSize', 9, 'Box','off', 'NumColumns', 5);

title({'Valeur angulaire reelle : condition vs Rehab'; ...
     'Une ligne par cluster significatif — couleur = DOF, plein = condition, creux = Rehab'}, ...
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

function c = diffColor(v, range, cmap)
    n = size(cmap, 1);
    idx = round(interp1(range, [1 n], v));
    idx = max(1, min(n, idx));
    c = cmap(idx, :);
end
