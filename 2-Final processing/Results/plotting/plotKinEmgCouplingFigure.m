function plotKinEmgCouplingFigure(K)
% =========================================================================
% plotKinEmgCouplingFigure.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Kinematics x EMG figure for one muscle, 2 x 2 panels:
%               humerothoracic elevation (mean rise time marked on each curve),
%               EMG envelope normalised to the peak of each trial, and
%               humerothoracic rise time against EMG peak timing and activity
%               duration with the within-participant slope.
% -------------------------------------------------------------------------
% Parameters  : K : struct with x, COND_LABELS, COLORS, htMean, emgMean,
%                   emgSD, kin, emg, emgTitles, emgYLabels, rm, muscleName,
%                   kinXLabel, actThreshold
% Outputs     : 1 figure
% -------------------------------------------------------------------------
% Dependencies: none
% =========================================================================

FONT  = 'Times New Roman';
nCond = numel(K.COND_LABELS);

figure('Name', 'Manuscript figure -- kinematics x EMG coupling', ...
       'units', 'normalized', 'outerposition', [0 0 1 1], 'Color', 'white');

LEFT = 0.07; RIGHT = 0.02; COL_GAP = 0.08;
TOP = 0.06; BOTTOM = 0.14; ROW_GAP = 0.13;
w = (1 - LEFT - RIGHT - COL_GAP) / 2;
h = (1 - TOP - BOTTOM - ROW_GAP) / 2;
pos = @(r, c) [LEFT + (c-1)*(w + COL_GAP), 1 - TOP - r*h - (r-1)*ROW_GAP, w, h];

% --- Ligne 1 : decours temporels ------------------------------------------
ax = axes('Position', pos(1, 1)); hold(ax, 'on');
meanKin = mean(K.kin, 1, 'omitnan');
for ic = 1:nCond
    plot(K.x, K.htMean(ic,:), '-', 'Color', K.COLORS(ic,:), 'LineWidth', 2);
end
for ic = 1:nCond   % marqueurs au-dessus de toutes les courbes
    plot(meanKin(ic), interp1(K.x, K.htMean(ic,:), meanKin(ic)), 'o', 'MarkerSize', 8, ...
         'MarkerFaceColor', K.COLORS(ic,:), 'MarkerEdgeColor', 'white', 'LineWidth', 1);
end
styleAxes(ax, FONT, 'Humerothoracic elevation', 'Cycle (%)', 'Angle (°)');
xlim(ax, [0 100]);

ax = axes('Position', pos(1, 2)); hold(ax, 'on');
for ic = 1:nCond   % bandes moyenne ± ET entre patients (bornees a 0-100 %)
    lo = max(K.emgMean(ic,:) - K.emgSD(ic,:), 0);
    hi = min(K.emgMean(ic,:) + K.emgSD(ic,:), 100);
    fill([K.x fliplr(K.x)], [hi fliplr(lo)], K.COLORS(ic,:), 'FaceAlpha', 0.08, 'EdgeColor', 'none');
end
plot([0 100], [1 1] * K.actThreshold, 'k:', 'LineWidth', 1);
for ic = 1:nCond
    plot(K.x, K.emgMean(ic,:), '-', 'Color', K.COLORS(ic,:), 'LineWidth', 2);
end
styleAxes(ax, FONT, K.muscleName, 'Cycle (%)', 'Normalised EMG (% of peak)');
xlim(ax, [0 100]); ylim(ax, [0 100]);

% --- Ligne 2 : couplage ----------------------------------------------------
for k = 1:2
    ax = axes('Position', pos(2, k)); hold(ax, 'on');
    X = K.kin; Y = K.emg{k};
    for ic = 1:nCond
        scatter(X(:,ic), Y(:,ic), 22, K.COLORS(ic,:), 'filled', 'MarkerFaceAlpha', 0.35);
    end
    % pente commune intra-sujet, passant par la moyenne generale
    xr = [min(X(:)) max(X(:))]; gx = mean(X(:), 'omitnan'); gy = mean(Y(:), 'omitnan');
    plot(xr, gy + K.rm(k).slope * (xr - gx), '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.2);
    for ic = 1:nCond
        mx = mean(X(:,ic), 'omitnan'); sx = std(X(:,ic), 'omitnan');
        my = mean(Y(:,ic), 'omitnan'); sy = std(Y(:,ic), 'omitnan');
        errorbar(mx, my, sy, sy, sx, sx, 'o', 'Color', K.COLORS(ic,:), 'MarkerFaceColor', K.COLORS(ic,:), ...
                 'MarkerSize', 8, 'LineWidth', 1.5, 'CapSize', 4);
    end
    styleAxes(ax, FONT, {K.emgTitles{k}, sprintf('r_{rm} = %.2f, p %s', K.rm(k).r, pStr(K.rm(k).p))}, ...
              K.kinXLabel, K.emgYLabels{k});
end

drawLegend(K.COND_LABELS, K.COLORS, FONT);
end


function styleAxes(ax, FONT, ttl, xl, yl)
    title(ax, ttl, 'FontName', FONT, 'FontSize', 14, 'FontWeight', 'normal');
    xlabel(ax, xl, 'FontName', FONT, 'FontSize', 13);
    ylabel(ax, yl, 'FontName', FONT, 'FontSize', 13);
    set(ax, 'FontName', FONT, 'FontSize', 11);
    ax.YAxis.Exponent = 0;
    grid(ax, 'on'); box(ax, 'on');
end


function s = pStr(p)
    if p < 0.001, s = '< 0.001'; else, s = sprintf('= %.3f', p); end
end


function drawLegend(COND_LABELS, COLORS, FONT)
    % Une ligne : couleurs des conditions + participants individuels + pente
    % commune intra-sujet (meme principe que plotDiscreteEMGManuscript.m)
    legAx = axes('Position', [0.03, 0.02, 0.95, 0.03], 'Visible', 'off');
    hold(legAx, 'on');
    h = gobjects(1, numel(COND_LABELS) + 2);
    for ic = 1:numel(COND_LABELS)
        h(ic) = plot(legAx, NaN, NaN, 'o-', 'Color', COLORS(ic,:), 'MarkerFaceColor', COLORS(ic,:), ...
                     'LineWidth', 2.5, 'MarkerSize', 6, 'DisplayName', COND_LABELS{ic});
    end
    h(end-1) = plot(legAx, NaN, NaN, 'o', 'Color', [0.6 0.6 0.6], 'MarkerFaceColor', [0.75 0.75 0.75], ...
                    'MarkerSize', 5, 'DisplayName', 'Individual participants');
    h(end) = plot(legAx, NaN, NaN, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, ...
                  'DisplayName', 'Within-subject slope');
    lgd = legend(legAx, h, 'Orientation', 'horizontal', 'Box', 'off', 'FontSize', 11, ...
                 'NumColumns', numel(h), 'FontName', FONT);
    drawnow;
    lgd.Units = 'normalized';
    lgd.Position(1) = 0.5 - lgd.Position(3)/2;
    lgd.Position(2) = 0.02;
    hold(legAx, 'off');
end
