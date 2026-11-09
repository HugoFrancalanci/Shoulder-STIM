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
%                   trial, as row 1, with the bars of the exploratory direct
%                   comparison;
%                 - row 4: absolute deviation of the EMG envelopes from No
%                   FES, as row 2, with the bars of the exploratory test
%                   (common scale for the four muscles).
%               Bars are bicoloured: upper half Rehab, lower half optimised
%               patterns. One x label under the kinematic rows and one under
%               the EMG rows, framed legend table at the bottom.
% -------------------------------------------------------------------------
% Parameters  : S : struct with fields
%                   grid, conds, condLabels, colors, showConds, colRef,
%                   colOCP, dofLabels, raw (cell per angle of cell per
%                   condition, (nPat, nGrid)), devRef / devOCP (cell per
%                   angle, (nPat, nGrid)), barsDev (cell per angle of [start
%                   end] rows, deg), muscleNames, emg (cell per muscle of
%                   cell per condition), barsEMG, emgDevRef / emgDevOCP,
%                   barsEmgDev (cell per muscle)
% Outputs     : 1 figure (1800 x 2120 px)
% -------------------------------------------------------------------------
% Dependencies: none
% =========================================================================

FONT = 'Times New Roman';
FS_TICK = 22; FS_LABEL = 26; FS_TITLE = 26;
FIG_W = 1800; PLOTS_H = 1800; LEGEND_H = 320; FIG_H = PLOTS_H + LEGEND_H;   % pixels
yMap = @(y) (LEGEND_H + y * PLOTS_H) / FIG_H;   % height in the plot area -> height in the figure
% Groups of the mean +/- SD bands (colour of the first condition of each group)
GROUPS = {{'No FES'}, {'Rehab','Random'}, {'Min_stress','Min_pulse_width','Min_force','Min_fatigue'}};
BAND_ALPHA = [0.13 0.13 0.18];
grp = cellfun(@(g) g(ismember(g, S.showConds)), GROUPS, 'UniformOutput', false);
keepG = ~cellfun(@isempty, grp); grp = grp(keepG); alphaG = BAND_ALPHA(keepG);
colOf = @(c) S.colors(strcmp(S.conds, c), :);
isShown = ismember(S.conds, S.showConds);
nDof = numel(S.dofLabels); nMus = numel(S.muscleNames);

% fixed size and light theme: rendering independent of the screen and of the MATLAB theme
fig = figure('Name', 'Manuscript figure -- scapulothoracic kinematics and EMG vs thoracohumeral elevation', ...
             'Units', 'pixels', 'Position', [0 0 FIG_W FIG_H], 'Color', 'white');
if isprop(fig, 'Theme'), fig.Theme = 'light'; end
TOP = 0.026; BOTTOM = 0.085; LEFT = 0.095; RIGHT = 0.015; COLGAP = 0.045;
ROWGAPS = [0.055 0.095 0.055];   % more space under row 2: x label of the kinematic part
nRow = 4;
row_h = (1 - TOP - BOTTOM - sum(ROWGAPS)) / nRow;
rowBottom = 1 - TOP - (1:nRow)*row_h - [0 cumsum(ROWGAPS)];
col_st  = (1 - LEFT - RIGHT - (nDof-1)*COLGAP) / nDof;
col_emg = (1 - LEFT - RIGHT - (nMus-1)*COLGAP) / nMus;
axPos = @(r, k, w) [LEFT + (k-1)*(w + COLGAP), yMap(rowBottom(r)), w, row_h * PLOTS_H / FIG_H];

% --- Row 1: scapulothoracic angles ---------------------------------
for id = 1:nDof
    ax = axes('Position', axPos(1, id, col_st)); hold(ax, 'on');
    [y_min, y_max] = drawBandsAndLines(S.raw{id}, grp, alphaG, colOf, S, isShown);
    rngY = max(y_max - y_min, 0.01);
    ylim(ax, [y_min - 0.05*rngY, y_max + 0.08*rngY]);
    styleAxes(ax, FONT, dofTitle(S.dofLabels{id}), S.grid, FS_TICK, FS_TITLE);
    if id == 1, ylabel(ax, 'Angle (°)', 'FontName', FONT, 'FontSize', FS_LABEL); end
end

% --- Row 2: deviation of the angles from No FES (own scale for each angle) ----
for id = 1:nDof
    ax = axes('Position', axPos(2, id, col_st)); hold(ax, 'on');
    y_max = drawDeviation(S.devRef{id}, S.devOCP{id}, S);
    setDeviationLimits(ax, S.barsDev{id}, S, y_max);
    styleAxes(ax, FONT, '', S.grid, FS_TICK, FS_TITLE);
    if id == 1, ylabel(ax, 'Deviation (°)', 'FontName', FONT, 'FontSize', FS_LABEL); end
end

% --- Row 3: EMG normalised to the peak (common scale 0-100 %) ------------
BAR_H = 6; BAR_TOP = -4 - BAR_H;   % in % of the peak, under the curves
yBottom = 0; if any(~cellfun(@isempty, S.barsEMG)), yBottom = BAR_TOP - 4; end
for m = 1:nMus
    ax = axes('Position', axPos(3, m, col_emg)); hold(ax, 'on');
    drawBandsAndLines(S.emg{m}, grp, alphaG, colOf, S, isShown, [0 100]);
    drawBars(S.barsEMG{m}, S.colRef, S.colOCP, BAR_TOP, BAR_H);
    ylim(ax, [yBottom 100]); yticks(ax, 0:20:100);
    styleAxes(ax, FONT, S.muscleNames{m}, S.grid, FS_TICK, FS_TITLE);
    if m == 1
        ylabel(ax, 'EMG (% of peak)', 'FontName', FONT, 'FontSize', FS_LABEL);
    else
        ax.YTickLabel = {};   % same scale as the first panel
    end
end

% --- Row 4: deviation of the EMG from No FES (common scale for the muscles) -------
yMaxEmg = 0;
for m = 1:nMus   % common scale: maximum of the bands over the 4 muscles
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
        ax.YTickLabel = {};   % same scale as the first panel
    end
end

% Row names (bold, vertical) and single x label
lab = axes('Position', [0 0 1 1], 'Visible', 'off'); hold(lab, 'on');
rowNames = {'Scapulothoracic', 'Deviation from No FES', 'Scapular muscles', 'Deviation from No FES'};
for r = 1:nRow
    text(lab, 0.014, yMap(rowBottom(r) + row_h/2), rowNames{r}, 'Rotation', 90, 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'middle', 'FontName', FONT, 'FontSize', FS_TITLE, 'FontWeight', 'bold');
end
for r = [2 4]   % x label under the kinematic part (row 2) and under the EMG (row 4)
    text(lab, LEFT + (1 - LEFT - RIGHT)/2, yMap(rowBottom(r) - 0.043), 'Thoracohumeral elevation (°)', ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontName', FONT, 'FontSize', FS_LABEL);
end

drawLegendTable(S, grp, alphaG, colOf, FONT, FIG_W, FIG_H);
end


function drawLegendTable(S, grp, alphaG, colOf, FONT, figW, figH)
    % Framed legend table, in pixels from the top of the figure. Rows: what is
    % drawn; columns: the three groups of conditions.
    FS = 20.5; SW = 34; GAP = 8; LINE_W = 3.5;
    ySwatch = 0.3 * FS * 96 / 72;           % height of a swatch above the text baseline
    X0 = 129; C = [535.27 898.08 1303]; C4 = 1501.25;   % row names, three columns, second optimised column
    yHead = 1818; yIndiv = [1870 1910]; yMean = 1966; ySD = 2020; yBars = 2074;
    yIndivMid = mean(yIndiv);
    ax = axes('Position', [0 0 1 1], 'Visible', 'off', 'XLim', [0 figW], 'YLim', [0 figH], 'YDir', 'reverse'); hold(ax, 'on');
    rectangle(ax, 'Position', [99 1780 1602 318], 'EdgeColor', [0.15 0.15 0.15], 'LineWidth', 1.5);
    label = @(x, y, s, weight) text(ax, x, y, s, 'FontName', FONT, 'FontSize', FS, 'FontWeight', weight, ...
                                    'VerticalAlignment', 'baseline', 'Color', [0.13 0.13 0.13]);
    entry = @(x, y, s, col, style) [plot(ax, [x x + SW], [y y] - ySwatch, style, 'Color', col, 'LineWidth', LINE_W), ...
                                    label(x + SW + GAP, y, s, 'normal')];
    condCol = @(lab) S.colors(strcmp(S.condLabels, lab), :);
    heads = {'No-stimulation', 'Rehabilitation-like', 'Optimised FES'};
    for k = 1:3, label(C(k), yHead, heads{k}, 'bold'); end
    names = {'Individual patterns', 'Mean patterns', 'Standard deviation', 'Bicoloured bars'};
    rowY = [yIndivMid yMean ySD yBars];
    for k = 1:4, label(X0, rowY(k), names{k}, 'bold'); end
    % individual patterns
    entry(C(1), yIndivMid, 'No FES', condCol('No FES'), '-');
    entry(C(2), yIndivMid, 'Rehab', condCol('Rehab'), '-');
    entry(C(3), yIndiv(1), 'Min PW', condCol('Min PW'), '-');
    entry(C4, yIndiv(1), 'Min force', condCol('Min force'), '-');
    entry(C(3), yIndiv(2), 'Min stress', condCol('Min stress'), '-');
    entry(C4, yIndiv(2), 'Min fatigue', condCol('Min fatigue'), '-');
    % means of the two stimulation groups, as drawn on the deviation rows
    entry(C(2), yMean, 'Rehab', S.colRef, '-');
    entry(C(3), yMean, 'Mean of the four patterns', S.colOCP, '--');
    % standard deviation bands
    h = 18;
    for g = 1:numel(grp)
        x = C(g); y = ySD - ySwatch - h/2;
        fill(ax, [x x + SW x + SW x], [y y y + h y + h], colOf(grp{g}{1}), 'FaceAlpha', alphaG(g), 'EdgeColor', 'none');
    end
    % bicoloured bars
    h = 14; y = yBars - ySwatch - h/2;
    rectangle(ax, 'Position', [C(1) y SW h/2], 'FaceColor', S.colRef, 'EdgeColor', 'none');
    rectangle(ax, 'Position', [C(1) y + h/2 SW h/2], 'FaceColor', S.colOCP, 'EdgeColor', 'none');
    rectangle(ax, 'Position', [C(1) y SW h], 'FaceColor', 'none', 'EdgeColor', 'k', 'LineWidth', 0.5);
    label(C(1) + SW + GAP, yBars, 'Rehab vs optimised patterns (adjusted p < 0.05)', 'normal');
end


function [y_min, y_max] = drawBandsAndLines(Y, grp, alphaG, colOf, S, isShown, clip)
    % Mean +/- SD bands per group, then mean curves of the conditions
    % drawn. Y: cell per condition, (nPat, nGrid). clip: limits of the bands.
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
    % Deviation from No FES: Rehab (solid) and mean of the OCP (dashed), +/- SD
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
    % Bar of the test under the curves, then y axis limits
    barH = 0.06*y_max; yTop = -0.06*y_max - barH;
    drawBars(bars, S.colRef, S.colOCP, yTop, barH);
    ylim(ax, [yTop - 0.04*y_max, 1.08*y_max]);
end


function v = bandMax(Y)
    v = max(mean(Y, 1, 'omitnan') + std(Y, 0, 1, 'omitnan'));
end


function [mu, sd] = groupBand(stacks)
    % Mean +/- SD across participants of a group of conditions. stacks: one
    % (N, nPts) matrix per condition, averaged first for each participant
    M = mean(cat(3, stacks{:}), 3);
    mu = mean(M, 1, 'omitnan'); sd = std(M, 0, 1, 'omitnan');
end


function drawBars(E, colA, colB, yTop, barH)
    % One bicoloured bar (A on top, B below); E: [start end] per range
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
    xticks(ax, 20:10:90); xtickangle(ax, 0);   % straight tick labels, up to 90 on each panel
    grid(ax, 'on'); box(ax, 'on');
end


function s = dofTitle(label)
    % Titles of the scapulothoracic degrees of freedom
    lbl = strtrim(label);
    if strcmpi(lbl, 'Protraction (+) / retraction (-)')
        s = {'Retraction (-) / protraction (+)'};
    elseif strcmpi(lbl, 'Posterior (+) / anterior (-) tilt')
        s = {'Anterior (-) / Posterior (+) tilt'};
    else
        s = label;
    end
end
