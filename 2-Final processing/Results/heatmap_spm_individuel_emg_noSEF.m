% =========================================================================
% heatmap_spm_individuel_emg_noSEF.m
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
% Description:   Summary heatmaps of individual SPM1D results for surface EMG
%                (10 patients x 6 FES conditions, 4 muscles per cell).
%                Figure 1 — markers per muscle (TRAPS, TRAPM, TRAPI, SERRA):
%                  - Large filled circle  : post-hoc significant vs No FES
%                  - Small grey circle    : n.s.
%                  - Cell background      : gradient encoding the relative
%                    rank (1-6) at which the condition was administered,
%                    among the 6 compared conditions only (No FES excluded
%                    from the ranking, since it is the reference)
%                Figure 2 — % of patients (N=10) with a significant
%                    post-hoc vs No FES, per condition and muscle.
%                No angular/amplitude-value figures here (unlike the
%                kinematics heatmaps) — EMG amplitude values are not
%                tabulated per significant cluster. ANOVA result is not
%                displayed (dropped — not discriminating across cells).
%                Results are hardcoded from extract_emg_cycles_noSEF.m console
%                output (LP_FREQ=6Hz, ANOVA RM + ttest_paired, Bonferroni
%                alpha=0.05/6, N=3 blocks per patient, exploratoire).
% -------------------------------------------------------------------------
% Parameters :   sig(patient,condition,muscle)  — post-hoc significance matrix
%                order(patient,condition)        — relative rank (1-6) of the
%                                                   condition among the 6
%                                                   compared conditions only
% Outputs    :   2 figures (see Description)
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
%   - Petit gris    = n.s.
%
% Source : extract_emg_cycles_noSEF.m — analyse SPM1D individuelle
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
% order(patient, condition) = rang RELATIF (1-6) de passage de la condition,
% parmi les 6 conditions comparees ici uniquement (No FES exclu du rang,
% puisque c'est la reference, toujours administree en 1er). Memes valeurs
% que heatmap_spm_individuel_kin_noSEF.m (meme ordre de passage en session,
% independant de la mesure kin vs EMG).
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
% Couleurs muscles
% -------------------------------------------------------------------------
MUS_COLORS = [0.85 0.33 0.10;   % TRAPS — orange-rouge
              0.00 0.45 0.74;   % TRAPM — bleu
              0.47 0.67 0.19;   % TRAPI — vert
              0.49 0.18 0.56];  % SERRA — violet

% Colormap pour le gradient d'ordre relatif de passage (1 = tres clair, 6 = clair/gris-bleu)
LIGHT_COLOR = [0.97 0.97 0.96];
DARK_COLOR  = [0.68 0.74 0.82];
ORDER_CMAP  = [linspace(LIGHT_COLOR(1), DARK_COLOR(1), 64)', ...
               linspace(LIGHT_COLOR(2), DARK_COLOR(2), 64)', ...
               linspace(LIGHT_COLOR(3), DARK_COLOR(3), 64)'];
ORDER_RANGE = [1 6];

% -------------------------------------------------------------------------
% FIGURE 1 : significativite + ordre de passage
% -------------------------------------------------------------------------
figure('Name','SPM1D individuel — significativite EMG vs No FES', ...
       'units','normalized','outerposition',[0.05 0.05 0.90 0.85],'Color','white');

ax = axes('Position',[0.09 0.16 0.83 0.70]);
hold on;

% Fond des cellules (gradient = ordre de passage)
for ip = 1:N_PAT
    for ic = 1:N_COND
        cellColor = orderColor(order(ip,ic), ORDER_RANGE, ORDER_CMAP);
        rectangle('Position',[ic-0.5, ip-0.5, 1, 1], ...
                  'FaceColor', cellColor, 'EdgeColor',[0.85 0.85 0.85], ...
                  'LineWidth', 0.75, 'HandleVisibility','off');
    end
end

% Décalages des 4 muscles dans la cellule
dx     = [-0.30, -0.10, 0.10, 0.30];
MS_SIG = 110;   % post-hoc sig — grand plein
MS_NS  = 25;    % n.s.         — petit gris

for im = 1:N_MUS
    xs_sig = []; ys_sig = [];
    xs_ns  = []; ys_ns  = [];

    for ip = 1:N_PAT
        for ic = 1:N_COND
            xc = ic + dx(im);
            if sig(ip, ic, im)
                xs_sig(end+1) = xc; ys_sig(end+1) = ip;
            else
                xs_ns(end+1)  = xc; ys_ns(end+1)  = ip;
            end
        end
    end

    if ~isempty(xs_ns)
        scatter(xs_ns, ys_ns, MS_NS, [0.82 0.82 0.82], 'o', ...
                'LineWidth', 0.5, 'HandleVisibility','off');
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

% Colorbar du gradient d'ordre relatif de passage
colormap(ax, ORDER_CMAP);
caxis(ax, ORDER_RANGE);
cb = colorbar(ax, 'Position', [0.935 0.16 0.02 0.70]);
cb.Label.String = 'Ordre relatif (1er a 6e parmi les conditions comparees)';
cb.Ticks = 1:6;

% Légende
h = gobjects(N_MUS+1, 1);
for im = 1:N_MUS
    h(im) = scatter(NaN, NaN, MS_SIG, MUS_COLORS(im,:), 'o', 'filled', ...
                    'MarkerEdgeColor', MUS_COLORS(im,:)*0.65, ...
                    'DisplayName', [MUSCLES{im} '  (sig.)']);
end
h(N_MUS+1) = scatter(NaN, NaN, MS_NS, [0.82 0.82 0.82], 'o', 'LineWidth', 0.5, ...
                     'DisplayName', 'n.s.');

legend(h, 'Location','southoutside', 'Orientation','horizontal', ...
       'FontSize', 10, 'Box','off');

title({'Analyse SPM1D individuelle — EMG — reference No FES'; ...
       'N = 3 blocs  |  Bonferroni \alpha = 0.0083'}, ...
      'FontSize', 11, 'FontWeight','bold');

hold off;

% -------------------------------------------------------------------------
% FIGURE 2 : % de patients significatifs par condition et par muscle
% -------------------------------------------------------------------------
pctSig = zeros(N_COND, N_MUS);
for ic = 1:N_COND
    for im = 1:N_MUS
        pctSig(ic, im) = 100 * sum(sig(:, ic, im)) / N_PAT;
    end
end

figure('Name','SPM1D individuel — % patients significatifs EMG vs No FES', ...
       'units','normalized','outerposition',[0.05 0.05 0.90 0.85],'Color','white');

ax2 = axes('Position',[0.09 0.16 0.83 0.70]);
b = bar(ax2, pctSig, 'grouped');
for im = 1:N_MUS
    b(im).FaceColor = MUS_COLORS(im,:);
end
hold(ax2, 'on');
set(ax2, 'XTick', 1:N_COND, 'XTickLabel', CONDITIONS, 'FontSize', 11, 'FontWeight','bold');
xlim(ax2, [0.5, N_COND+0.5]);
ylim(ax2, [0 100]);
ylabel(ax2, '% patients significatifs', 'FontSize', 11);
grid(ax2, 'on'); box(ax2, 'on');

hLeg = gobjects(N_MUS,1);
for im = 1:N_MUS
    hLeg(im) = plot(NaN, NaN, 's', 'MarkerFaceColor', MUS_COLORS(im,:), ...
                     'MarkerEdgeColor','none', 'MarkerSize', 10, ...
                     'DisplayName', MUSCLES{im});
end
legend(hLeg, 'Location','southoutside', 'Orientation','horizontal', 'FontSize', 10, 'Box','off');

title('% de patients (N=10) avec post-hoc significatif vs No FES, par condition et muscle', ...
      'FontSize', 13, 'FontWeight', 'bold');


% =========================================================================
% FONCTIONS LOCALES
% =========================================================================

function c = orderColor(v, range, cmap)
    n = size(cmap, 1);
    idx = round(interp1(range, [1 n], v));
    idx = max(1, min(n, idx));
    c = cmap(idx, :);
end
