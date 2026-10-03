function plotKinEmgCouplingAllMuscles(K)
% =========================================================================
% plotKinEmgCouplingAllMuscles.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   October 2026
% -------------------------------------------------------------------------
% Description :  All-muscle version of plotKinEmgCouplingFigure.m
%                (extract_kinematics_emg_coupling_all_comp.m), manuscript
%                figure, Times New Roman, grid of 3 rows x nMuscles columns
%                (the humerothoracic elevation itself is shown in its own
%                article figure, not repeated here) :
%                row 1 — per muscle, the envelope normalised to each
%                        trial's own peak (% of peak), group mean ± SD
%                        (across participants) per condition, dotted line =
%                        50 % activity threshold ;
%                        If K.spm is given : SPM1D post-hoc pairs significant
%                        after Holm-Bonferroni drawn as bars under the
%                        curves (one colour per pair, black edge, same
%                        convention as plotCombinedJointsFigure.m), listed
%                        on a second legend line ;
%                rows 2-3 — per muscle, kinematic parameter (x) vs EMG peak
%                        timing (row 2) and activity duration (row 3) : one
%                        dot per participant x condition, condition mean ±
%                        SD on both axes, common within-subject slope of
%                        the repeated-measures correlation : solid dark line
%                        if p < 0.05, light dashed line otherwise (r_rm and
%                        p reported in the text) ; same x limits in a row.
%                Same layout conventions as plotDiscreteEMGManuscript.m :
%                metric name (bold) and unit written vertically at a fixed
%                position left of each row, muscle names on top, bottom
%                legend (conditions, individual participants, within-
%                subject slope).
% -------------------------------------------------------------------------
% Parameters :   K — struct :
%                  x (1,101), COND_LABELS, COLORS (nCond,3)
%                  kin (nPat,nCond), kinXLabel
%                  muscleNames — cell (1,nMus)
%                  emgMean, emgSD — cells (1,nMus) of (nCond,101)
%                  emg — cell {param}{muscle} of (nPat,nCond)
%                  rm — struct array (nParam, nMus) : r, p, slope
%                  rowNames — cell of 2 metric names (rows 2-3)
%                  actThreshold
%                  spm (optional) — struct array (1,nMus) : pairSig (nP,1),
%                         pairClusters {nP} of [start end p] (% cycle)
%                  ALL_PAIRS (with spm) — (nP,2) condition indices
% Outputs    :   1 figure
% -------------------------------------------------------------------------
% Dependencies : none
% =========================================================================

FONT  = 'Times New Roman';
nCond = numel(K.COND_LABELS);
nMus  = numel(K.muscleNames);
ALPHA_RM = 0.05;   % seuil de la correlation a mesures repetees (style de la pente)
QUAL_PALETTE = [0.121 0.466 0.705; 1.000 0.498 0.055; 0.172 0.627 0.172; 0.839 0.153 0.157; ...
                0.580 0.404 0.741; 0.549 0.337 0.294; 0.890 0.467 0.761; 0.498 0.498 0.498; ...
                0.737 0.741 0.133; 0.090 0.745 0.812];   % cf. plotCombinedJointsFigure.m

% Paires significatives (tous muscles) : une couleur stable par paire
hasSpm = isfield(K, 'spm') && ~isempty(K.spm);
sigPairs = [];
if hasSpm
    sigPairs = find(any(cell2mat(arrayfun(@(s) s.pairSig(:), K.spm, 'UniformOutput', false)), 2))';
end
pairLabels = arrayfun(@(kp) sprintf('%s vs %s', K.COND_LABELS{K.ALL_PAIRS(kp,1)}, ...
                      K.COND_LABELS{K.ALL_PAIRS(kp,2)}), sigPairs, 'UniformOutput', false);
nRowsBar = 0;   % lignes de barres : maximum sur les muscles (meme ylim pour toute la ligne 1)
if hasSpm
    for m = 1:nMus, nRowsBar = max(nRowsBar, sum(K.spm(m).pairSig)); end
end
BAR_H = 4.5; BAR_GAP = 1.5; BAR_TOP = -4;   % en % du pic, sous les courbes
yBottom1 = 0;
if nRowsBar > 0, yBottom1 = BAR_TOP - nRowsBar * (BAR_H + BAR_GAP); end

figure('Name', 'Manuscript figure -- kinematics x EMG coupling, all muscles', ...
       'units', 'normalized', 'outerposition', [0 0 1 1], 'Color', 'white');

TOP_MARGIN    = 0.05;
BOTTOM_MARGIN = 0.15;   % libelle x + legende (2 lignes)
ROW_GAP       = [0.075 0.035];   % (1-2), (2-3)
LEFT_MARGIN   = 0.09;
RIGHT_MARGIN  = 0.015;
COL_GAP       = 0.04;
row_h = (1 - TOP_MARGIN - BOTTOM_MARGIN - sum(ROW_GAP)) / 3;
col_w = (1 - LEFT_MARGIN - RIGHT_MARGIN - (nMus-1)*COL_GAP) / nMus;
rowBottom = [1 - TOP_MARGIN - row_h, ...
             1 - TOP_MARGIN - 2*row_h - ROW_GAP(1), ...
             1 - TOP_MARGIN - 3*row_h - sum(ROW_GAP)];
colLeft = LEFT_MARGIN + (0:nMus-1) * (col_w + COL_GAP);

% --- Ligne 1 : decours temporels (% du pic) --------------------------------
for m = 1:nMus
    ax = axes('Position', [colLeft(m) rowBottom(1) col_w row_h]); hold(ax, 'on');
    for ic = 1:nCond   % bandes moyenne ± ET entre patients (bornees a 0-100 %)
        lo = max(K.emgMean{m}(ic,:) - K.emgSD{m}(ic,:), 0);
        hi = min(K.emgMean{m}(ic,:) + K.emgSD{m}(ic,:), 100);
        fill([K.x fliplr(K.x)], [hi fliplr(lo)], K.COLORS(ic,:), 'FaceAlpha', 0.08, 'EdgeColor', 'none');
    end
    plot([0 100], [1 1] * K.actThreshold, 'k:', 'LineWidth', 1);
    for ic = 1:nCond
        plot(K.x, K.emgMean{m}(ic,:), '-', 'Color', K.COLORS(ic,:), 'LineWidth', 1.8);
    end
    rowIdx = 0;
    for kp = sigPairs
        if ~K.spm(m).pairSig(kp), continue; end
        rowIdx = rowIdx + 1;
        y_row = BAR_TOP - rowIdx * BAR_H - (rowIdx - 1) * BAR_GAP;
        col = QUAL_PALETTE(mod(find(sigPairs == kp) - 1, size(QUAL_PALETTE, 1)) + 1, :);
        C = K.spm(m).pairClusters{kp};
        for cl = 1:size(C, 1)
            rectangle('Position', [C(cl,1), y_row, max(C(cl,2) - C(cl,1), 0.5), BAR_H], ...
                      'FaceColor', col, 'EdgeColor', 'k', 'LineWidth', 0.5);
        end
    end
    styleAxes(ax, FONT, K.muscleNames{m}, 'Cycle (%)');
    ax.Title.FontSize = 14;
    xlim(ax, [0 100]); ylim(ax, [yBottom1 100]); yticks(ax, 0:20:100);
end

% --- Lignes 2-3 : couplage -------------------------------------------------
xAll  = K.kin(:);
xlimS = [5 * floor(min(xAll) / 5), 5 * ceil(max(xAll) / 5)];
for k = 1:2
    for m = 1:nMus
        ax = axes('Position', [colLeft(m) rowBottom(k+1) col_w row_h]); hold(ax, 'on');
        X = K.kin; Y = K.emg{k}{m};
        for ic = 1:nCond
            scatter(X(:,ic), Y(:,ic), 16, K.COLORS(ic,:), 'filled', 'MarkerFaceAlpha', 0.35);
        end
        gx = mean(X(:), 'omitnan'); gy = mean(Y(:), 'omitnan');
        if K.rm(k,m).p < ALPHA_RM   % correlation significative : trait plein fonce
            plot(xlimS, gy + K.rm(k,m).slope * (xlimS - gx), '-', 'Color', [0.15 0.15 0.15], 'LineWidth', 1.6);
        else                        % non significative : tirets clairs
            plot(xlimS, gy + K.rm(k,m).slope * (xlimS - gx), '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.1);
        end
        for ic = 1:nCond
            mx = mean(X(:,ic), 'omitnan'); sx = std(X(:,ic), 'omitnan');
            my = mean(Y(:,ic), 'omitnan'); sy = std(Y(:,ic), 'omitnan');
            errorbar(mx, my, sy, sy, sx, sx, 'o', 'Color', K.COLORS(ic,:), 'MarkerFaceColor', K.COLORS(ic,:), ...
                     'MarkerSize', 6, 'LineWidth', 1.3, 'CapSize', 3);
        end
        xl = ''; if k == 2, xl = K.kinXLabel; end
        styleAxes(ax, FONT, '', xl);   % r_rm et p dans le texte / la legende, pas sur la figure
        xlim(ax, xlimS);
    end
end

% Nom des metriques (gras) + unite, verticaux a gauche de chaque ligne, a x
% fixe (alignes d'une ligne a l'autre ; cf. plotDiscreteEMGManuscript.m)
rowNames = [{'Normalised EMG'}, K.rowNames];
rowUnits = {'% of peak', 'Cycle (%)', 'Cycle (%)'};
labelAx = axes('Position', [0 0 1 1], 'Visible', 'off'); hold(labelAx, 'on');
for r = 1:3
    text(labelAx, 0.022, rowBottom(r) + row_h/2, rowNames{r}, 'Rotation', 90, ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
         'FontSize', 14, 'FontName', FONT, 'FontWeight', 'bold');
    text(labelAx, 0.048, rowBottom(r) + row_h/2, rowUnits{r}, 'Rotation', 90, ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
         'FontSize', 12, 'FontName', FONT);
end
hold(labelAx, 'off');

drawLegend(K.COND_LABELS, K.COLORS, FONT, pairLabels, QUAL_PALETTE);
end


function styleAxes(ax, FONT, ttl, xl)
    title(ax, ttl, 'FontName', FONT, 'FontSize', 12, 'FontWeight', 'normal');
    if ~isempty(xl), xlabel(ax, xl, 'FontName', FONT, 'FontSize', 12); end
    set(ax, 'FontName', FONT, 'FontSize', 10);
    ax.YAxis.Exponent = 0;
    grid(ax, 'on'); box(ax, 'on');
end


function drawLegend(COND_LABELS, COLORS, FONT, pairLabels, QUAL_PALETTE)
    % Ligne 1 : couleurs des conditions + participants individuels
    % (cf. plotDiscreteEMGManuscript.m) ; ligne 2 : style de la pente
    % (correlation significative ou non) + paires SPM1D significatives
    % (cf. plotCombinedJointsFigure.m)
    legAx = axes('Position', [0.03, 0.045, 0.95, 0.03], 'Visible', 'off');
    hold(legAx, 'on');
    h = gobjects(1, numel(COND_LABELS) + 1);
    for ic = 1:numel(COND_LABELS)
        h(ic) = plot(legAx, NaN, NaN, 'o-', 'Color', COLORS(ic,:), 'MarkerFaceColor', COLORS(ic,:), ...
                     'LineWidth', 2.5, 'MarkerSize', 6, 'DisplayName', COND_LABELS{ic});
    end
    h(end) = plot(legAx, NaN, NaN, 'o', 'Color', [0.6 0.6 0.6], 'MarkerFaceColor', [0.75 0.75 0.75], ...
                  'MarkerSize', 5, 'DisplayName', 'Individual participants');
    centreLegend(legend(legAx, h, 'Orientation', 'horizontal', 'Box', 'off', 'FontSize', 11, ...
                        'NumColumns', numel(h), 'FontName', FONT), 0.045);
    hold(legAx, 'off');

    legAx2 = axes('Position', [0.03, 0.01, 0.95, 0.03], 'Visible', 'off');
    hold(legAx2, 'on');
    h2 = gobjects(1, 2 + numel(pairLabels));
    h2(1) = plot(legAx2, NaN, NaN, '-', 'Color', [0.15 0.15 0.15], 'LineWidth', 1.6, ...
                 'DisplayName', 'Significant correlation');
    h2(2) = plot(legAx2, NaN, NaN, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.1, ...
                 'DisplayName', 'Non-significant correlation');
    for k = 1:numel(pairLabels)
        h2(2+k) = plot(legAx2, NaN, NaN, 's', 'MarkerFaceColor', QUAL_PALETTE(mod(k-1, size(QUAL_PALETTE,1)) + 1, :), ...
                       'MarkerEdgeColor', 'k', 'MarkerSize', 9, 'DisplayName', pairLabels{k});
    end
    centreLegend(legend(legAx2, h2, 'Orientation', 'horizontal', 'Box', 'off', 'FontSize', 11, ...
                        'NumColumns', numel(h2), 'FontName', FONT), 0.01);
    hold(legAx2, 'off');
end


function centreLegend(lgd, y)
    drawnow;
    lgd.Units = 'normalized';
    lgd.Position(1) = 0.5 - lgd.Position(3)/2;
    lgd.Position(2) = y;
end
