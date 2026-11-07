function plotScapulaEmgHypothesisFigure(S)
% =========================================================================
% plotScapulaEmgHypothesisFigure.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : November 2026
% -------------------------------------------------------------------------
% Description : Article figure of the biomechanical results, as a function of
%               thoracohumeral elevation (ascending phase, 20 to 90 deg), four
%               rows:
%                 - row 1: scapulothoracic angles of the conditions shown,
%                   with mean +/- SD bands for No FES, Rehab and the
%                   optimised patterns;
%                 - row 2: absolute deviation of these angles from No FES,
%                   Rehab and mean of the optimised patterns (mean +/- SD),
%                   with the bars of the hypothesis test;
%                 - row 3: EMG envelopes normalised to the peak of each
%                   trial, as row 1;
%                 - row 4: absolute deviation of the EMG envelopes from No
%                   FES, as row 2, with the bars of the exploratory test
%                   (common scale for the four muscles).
%               Bars are bicoloured: upper half Rehab, lower half optimised
%               patterns. One x label under the kinematic rows and one under
%               the EMG rows, condition legend at the bottom.
% -------------------------------------------------------------------------
% Parameters  : S : struct with fields
%                   grid, conds, condLabels, colors, showConds, colRef,
%                   colOCP, dofLabels, raw (cell per angle of cell per
%                   condition, (nPat, nGrid)), devRef / devOCP (cell per
%                   angle, (nPat, nGrid)), barsDev (cell per angle of [start
%                   end] rows, deg), muscleNames, emg (cell per muscle of
%                   cell per condition), emgDevRef / emgDevOCP, barsEmgDev
%                   (cell per muscle)
% Outputs     : 1 figure (1800 x 1800 px)
% -------------------------------------------------------------------------
% Dependencies: none
% =========================================================================

FONT = 'Times New Roman';
FS_TICK = 22; FS_LABEL = 26; FS_TITLE = 26; FS_LEGEND = 26;
LEGEND_ORDER = {'No FES', 'Rehab', 'Random', 'Min PW', 'Min force', 'Min stress', 'Min fatigue'};
% Groupes des bandes moyenne +/- ET (couleur de la 1re condition de chaque groupe)
GROUPS = {{'No FES'}, {'Rehab','Random'}, {'Min_stress','Min_pulse_width','Min_force','Min_fatigue'}};
BAND_ALPHA = [0.13 0.13 0.18];
grp = cellfun(@(g) g(ismember(g, S.showConds)), GROUPS, 'UniformOutput', false);
keepG = ~cellfun(@isempty, grp); grp = grp(keepG); alphaG = BAND_ALPHA(keepG);
colOf = @(c) S.colors(strcmp(S.conds, c), :);
isShown = ismember(S.conds, S.showConds);
nDof = numel(S.dofLabels); nMus = numel(S.muscleNames);

% taille fixe et theme clair : rendu independant de l'ecran et du theme de MATLAB
fig = figure('Name', 'Manuscript figure -- scapulothoracic kinematics and EMG vs thoracohumeral elevation', ...
             'Units', 'pixels', 'Position', [0 0 1800 1800], 'Color', 'white');
if isprop(fig, 'Theme'), fig.Theme = 'light'; end
TOP = 0.026; BOTTOM = 0.085; LEFT = 0.095; RIGHT = 0.015; COLGAP = 0.045;
ROWGAPS = [0.055 0.095 0.055];   % plus d'air sous la rangee 2 : label x de la partie cinematique
nRow = 4;
row_h = (1 - TOP - BOTTOM - sum(ROWGAPS)) / nRow;
rowBottom = 1 - TOP - (1:nRow)*row_h - [0 cumsum(ROWGAPS)];
col_st  = (1 - LEFT - RIGHT - (nDof-1)*COLGAP) / nDof;
col_emg = (1 - LEFT - RIGHT - (nMus-1)*COLGAP) / nMus;
axPos = @(r, k, w) [LEFT + (k-1)*(w + COLGAP), rowBottom(r), w, row_h];

% --- Rangee 1 : angles scapulothoraciques ---------------------------------
for id = 1:nDof
    ax = axes('Position', axPos(1, id, col_st)); hold(ax, 'on');
    [y_min, y_max] = drawBandsAndLines(S.raw{id}, grp, alphaG, colOf, S, isShown);
    rngY = max(y_max - y_min, 0.01);
    ylim(ax, [y_min - 0.05*rngY, y_max + 0.08*rngY]);
    styleAxes(ax, FONT, dofTitle(S.dofLabels{id}), S.grid, FS_TICK, FS_TITLE);
    if id == 1, ylabel(ax, 'Angle (°)', 'FontName', FONT, 'FontSize', FS_LABEL); end
end

% --- Rangee 2 : ecart des angles a No FES (echelle propre a chaque angle) ----
for id = 1:nDof
    ax = axes('Position', axPos(2, id, col_st)); hold(ax, 'on');
    y_max = drawDeviation(S.devRef{id}, S.devOCP{id}, S);
    setDeviationLimits(ax, S.barsDev{id}, S, y_max);
    styleAxes(ax, FONT, '', S.grid, FS_TICK, FS_TITLE);
    if id == 1, ylabel(ax, 'Deviation (°)', 'FontName', FONT, 'FontSize', FS_LABEL); end
end

% --- Rangee 3 : EMG normalisee au pic (echelle commune 0-100 %) ------------
for m = 1:nMus
    ax = axes('Position', axPos(3, m, col_emg)); hold(ax, 'on');
    drawBandsAndLines(S.emg{m}, grp, alphaG, colOf, S, isShown, [0 100]);
    ylim(ax, [0 100]); yticks(ax, 0:20:100);
    styleAxes(ax, FONT, S.muscleNames{m}, S.grid, FS_TICK, FS_TITLE);
    if m == 1
        ylabel(ax, 'EMG (% of peak)', 'FontName', FONT, 'FontSize', FS_LABEL);
    else
        ax.YTickLabel = {};   % meme echelle que le premier panneau
    end
end

% --- Rangee 4 : ecart de l'EMG a No FES (echelle commune aux muscles) -------
yMaxEmg = 0;
for m = 1:nMus   % echelle commune : maximum des bandes sur les 4 muscles
    yMaxEmg = max([yMaxEmg, bandMax(S.emgDevRef{m}), bandMax(S.emgDevOCP{m})]);
end
for m = 1:nMus
    ax = axes('Position', axPos(4, m, col_emg)); hold(ax, 'on');
    drawDeviation(S.emgDevRef{m}, S.emgDevOCP{m}, S);
    setDeviationLimits(ax, S.barsEmgDev{m}, S, yMaxEmg);
    styleAxes(ax, FONT, '', S.grid, FS_TICK, FS_TITLE);
    if m == 1
        ylabel(ax, 'Deviation (% of peak)', 'FontName', FONT, 'FontSize', FS_LABEL);
    else
        ax.YTickLabel = {};   % meme echelle que le premier panneau
    end
end

% Noms des rangees (gras, verticaux) et label x unique
lab = axes('Position', [0 0 1 1], 'Visible', 'off'); hold(lab, 'on');
rowNames = {'Scapulothoracic', 'Deviation from No FES', 'Scapular muscles', 'Deviation from No FES'};
for r = 1:nRow
    text(lab, 0.014, rowBottom(r) + row_h/2, rowNames{r}, 'Rotation', 90, 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'middle', 'FontName', FONT, 'FontSize', FS_TITLE, 'FontWeight', 'bold');
end
for r = [2 4]   % label x sous la partie cinematique (rangee 2) et sous l'EMG (rangee 4)
    text(lab, LEFT + (1 - LEFT - RIGHT)/2, rowBottom(r) - 0.043, 'Thoracohumeral elevation (°)', ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontName', FONT, 'FontSize', FS_LABEL);
end

% Legende : conditions tracees (ordre LEGEND_ORDER) + moyenne des patrons optimises
legOrder = cellfun(@(l) find(strcmp(S.condLabels, l), 1), LEGEND_ORDER);
legOrder = legOrder(isShown(legOrder));
legAx = axes('Position', [0.02 0.004 0.96 0.028], 'Visible', 'off'); hold(legAx, 'on');
h = gobjects(1, numel(legOrder) + 1);
for k = 1:numel(legOrder)
    ic = legOrder(k);
    h(k) = plot(legAx, NaN, NaN, 'Color', S.colors(ic,:), 'LineWidth', 3.5, 'DisplayName', S.condLabels{ic});
end
h(end) = plot(legAx, NaN, NaN, '--', 'Color', S.colOCP, 'LineWidth', 3.5, 'DisplayName', 'Optimised (mean)');
% centree par MATLAB (Location) : reste centree quelle que soit la taille de rendu
legend(legAx, h, 'Orientation', 'horizontal', 'Box', 'off', 'FontName', FONT, 'FontSize', FS_LEGEND, ...
       'NumColumns', numel(h), 'Location', 'north');
end


function [y_min, y_max] = drawBandsAndLines(Y, grp, alphaG, colOf, S, isShown, clip)
    % Bandes moyenne +/- ET par groupe, puis courbes moyennes des conditions
    % tracees. Y : cell par condition, (nPat, nGrid). clip : bornes des bandes.
    if nargin < 7, clip = [-Inf Inf]; end
    y_min = Inf; y_max = -Inf;
    for g = 1:numel(grp)
        [mg, sg] = groupBand(Y(ismember(S.conds, grp{g})));
        lo = max(mg - sg, clip(1)); hi = min(mg + sg, clip(2));
        fill([S.grid fliplr(S.grid)], [hi fliplr(lo)], colOf(grp{g}{1}), 'FaceAlpha', alphaG(g), 'EdgeColor', 'none');
        y_min = min(y_min, min(lo)); y_max = max(y_max, max(hi));
    end
    for ic = find(isShown)
        plot(S.grid, mean(Y{ic}, 1, 'omitnan'), 'Color', S.colors(ic,:), 'LineWidth', 2.8);
    end
end


function y_max = drawDeviation(devRef, devOCP, S)
    % Ecart a No FES : Rehab (trait plein) et moyenne des OCP (tirets), +/- ET
    curves = {devRef, devOCP}; cols = {S.colRef, S.colOCP}; styles = {'-', '--'}; alphas = [0.13 0.18];
    for q = 1:2
        mu = mean(curves{q}, 1, 'omitnan'); sd = std(curves{q}, 0, 1, 'omitnan');
        fill([S.grid fliplr(S.grid)], [mu+sd fliplr(max(mu-sd, 0))], cols{q}, 'FaceAlpha', alphas(q), 'EdgeColor', 'none');
    end
    for q = 1:2
        plot(S.grid, mean(curves{q}, 1, 'omitnan'), styles{q}, 'Color', cols{q}, 'LineWidth', 2.8);
    end
    y_max = max(bandMax(devRef), bandMax(devOCP));
end


function setDeviationLimits(ax, bars, S, y_max)
    % Barre du test sous les courbes, puis limites de l'axe y
    barH = 0.06*y_max; yTop = -0.06*y_max - barH;
    drawBars(bars, S.colRef, S.colOCP, yTop, barH);
    ylim(ax, [yTop - 0.04*y_max, 1.08*y_max]);
end


function v = bandMax(Y)
    v = max(mean(Y, 1, 'omitnan') + std(Y, 0, 1, 'omitnan'));
end


function [mu, sd] = groupBand(stacks)
    % Moyenne +/- ET entre participants d'un groupe de conditions. stacks : une
    % matrice (N, nPts) par condition, moyennees d'abord pour chaque participant
    M = mean(cat(3, stacks{:}), 3);
    mu = mean(M, 1, 'omitnan'); sd = std(M, 0, 1, 'omitnan');
end


function drawBars(E, colA, colB, yTop, barH)
    % Une barre bicolore (A en haut, B en bas) ; E : [debut fin] par zone
    for c = 1:size(E, 1)
        w = max(E(c,2) - E(c,1), 0.5);
        rectangle('Position', [E(c,1), yTop + barH/2, w, barH/2], 'FaceColor', colA, 'EdgeColor', 'none');
        rectangle('Position', [E(c,1), yTop, w, barH/2], 'FaceColor', colB, 'EdgeColor', 'none');
        rectangle('Position', [E(c,1), yTop, w, barH], 'FaceColor', 'none', 'EdgeColor', 'k', 'LineWidth', 0.5);
    end
end


function styleAxes(ax, FONT, ttl, xg, fsTick, fsTitle)
    set(ax, 'FontName', FONT, 'FontSize', fsTick);
    if ~isempty(ttl), title(ax, ttl, 'FontName', FONT, 'FontSize', fsTitle, 'FontWeight', 'bold'); end
    ax.YAxis.Exponent = 0;
    xlim(ax, [xg(1) xg(end)]);
    xticks(ax, 20:10:90); xtickangle(ax, 0);   % graduations droites, jusqu'a 90 sur chaque panneau
    grid(ax, 'on'); box(ax, 'on');
end


function s = dofTitle(label)
    % Titres des degres de liberte scapulothoraciques
    lbl = strtrim(label);
    if strcmpi(lbl, 'Protraction (+) / retraction (-)')
        s = {'Retraction (-) / protraction (+)'};
    elseif strcmpi(lbl, 'Posterior (+) / anterior (-) tilt')
        s = {'Anterior (-) / Posterior (+) tilt'};
    else
        s = label;
    end
end
