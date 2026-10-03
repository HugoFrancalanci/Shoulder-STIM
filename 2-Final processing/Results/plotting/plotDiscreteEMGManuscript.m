function plotDiscreteEMGManuscript(disc, stats, PARAMS, PARAM_LABELS, EMG_LABELS, MUSCLE_DISPLAY, ...
                                   COND_LABELS, COLORS, pairIdx, muscles, params)
% =========================================================================
% plotDiscreteEMGManuscript.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   October 2026
% -------------------------------------------------------------------------
% Description :  Manuscript version of the discrete EMG figure
%                (extract_emg_discrete_all_comp.m) : grid metric (rows) x
%                muscle (columns), restricted to the requested muscles /
%                metrics (typically the 3 metrics of the Methods : peak
%                amplitude, peak timing, activity duration > 50 %). Same layout conventions as
%                plotCombinedJointsFigure.m : metric name written
%                vertically on the left of each row (bold), unit only on
%                the y-axis, muscle names on top, Times New Roman.
%                Per condition : every patient's value (grey dots joined
%                across conditions by thin lines) and the group mean ± SD
%                (coloured marker + error bar). Pairs significant after
%                Holm-Bonferroni (paired t-test, significant RM-ANOVA) are
%                marked by brackets with stars (* p<0.05, ** p<0.01,
%                *** p<0.001, Holm-adjusted), packed on as few levels as
%                possible (non-overlapping brackets share a level). Muscle
%                names on top (ANOVA p-values are not shown in the figure).
%                Metric name and unit are
%                written at a fixed position left of each row (aligned).
%                Bottom legend as in plotCombinedJointsFigure.m : one
%                colour entry per condition + individual participants (star
%                thresholds go in the figure caption).
% -------------------------------------------------------------------------
% Parameters :   disc, stats, PARAMS, PARAM_LABELS, EMG_LABELS,
%                MUSCLE_DISPLAY, COND_LABELS, COLORS, pairIdx — see
%                plotDiscreteEMGFigure.m
%                muscles — cell array of EMG labels (columns, in order)
%                params  — cell array of metric names (rows, in order)
% Outputs    :   1 figure
% -------------------------------------------------------------------------
% Dependencies : none
% =========================================================================

FONT  = 'Times New Roman';
nCond = numel(COND_LABELS);
nRows = numel(params);
nCols = numel(muscles);

figure('Name', 'Manuscript figure -- EMG discrete parameters', ...
       'units', 'normalized', 'outerposition', [0 0 1 1], 'Color', 'white');

TOP_MARGIN    = 0.05;
BOTTOM_MARGIN = 0.13;   % graduations inclinees + legende (1 ligne)
ROW_GAP       = 0.04;
LEFT_MARGIN   = 0.08;    % unite (Cycle (%)) rapprochee des axes
RIGHT_MARGIN  = 0.07;    % espace libre a droite de la derniere colonne
COL_GAP       = 0.045;
row_h = (1 - TOP_MARGIN - BOTTOM_MARGIN - (nRows-1)*ROW_GAP) / nRows;
col_w = (1 - LEFT_MARGIN - RIGHT_MARGIN - (nCols-1)*COL_GAP) / nCols;

rowNames = cell(1, nRows);
rowUnits = cell(1, nRows);
for r = 1:nRows
    kparam = find(strcmp(PARAMS, params{r}), 1);
    [rowNames{r}, rowUnits{r}] = splitLabel(PARAM_LABELS{kparam});

    for c = 1:nCols
        im = find(strcmp(EMG_LABELS, muscles{c}), 1);
        % axes() direct (pas subplot + set Position : subplot supprime les
        % axes deja repositionnes qu'il chevauche)
        ax = axes('Position', [LEFT_MARGIN + (c-1)*(col_w + COL_GAP), ...
                               1 - TOP_MARGIN - r*row_h - (r-1)*ROW_GAP, col_w, row_h]);
        hold(ax, 'on');

        Y  = disc.(params{r})(:, :, im);        % (nPat, nCond)
        st = stats(im).(params{r});

        for ip = 1:size(Y, 1)
            plot(1:nCond, Y(ip, :), '-', 'Color', [0.80 0.80 0.80], 'LineWidth', 0.5);
            plot(1:nCond, Y(ip, :), '.', 'Color', [0.55 0.55 0.55], 'MarkerSize', 8);
        end
        mu = mean(Y, 1, 'omitnan'); sd = std(Y, 0, 1, 'omitnan');
        for ic = 1:nCond
            errorbar(ic, mu(ic), sd(ic), 'o', 'Color', COLORS(ic,:), 'MarkerFaceColor', COLORS(ic,:), ...
                     'MarkerSize', 6, 'LineWidth', 1.5, 'CapSize', 4);
        end

        yTop = max([Y; mu + sd], [], 1, 'omitnan');
        yl   = [min([Y(:); (mu - sd)'], [], 'omitnan'), max(yTop)];
        if any(~isfinite(yl)) || yl(2) <= yl(1), yl = [0 1]; end
        rngY = yl(2) - yl(1);

        nLev = 0;
        if st.anova_sig && any(st.sig)
            nLev = drawSigBrackets(pairIdx(st.sig, :), st.pHolm(st.sig), yl(2), rngY, FONT, 12);
        end
        ylim([yl(1) - 0.05*rngY, yl(2) + (0.08 + 0.14*nLev)*rngY]);
        xlim([0.5 nCond + 0.5]);
        ax.YAxis.Exponent = 0;
        yt = ax.YTick;                       % pas de graduation dans la zone des crochets
        ax.YTick = yt(yt <= yl(2) + 0.02*rngY);
        ytickformat(ax, '%g');

        % p de l'ANOVA non affiche (dans le texte / la legende) : nom du
        % muscle seulement, au-dessus de la premiere ligne
        if r == 1
            title(MUSCLE_DISPLAY(muscles{c}), 'FontName', FONT, 'FontSize', 14, 'FontWeight', 'normal');
        end
        set(ax, 'XTick', 1:nCond, 'FontName', FONT, 'FontSize', 10);
        if r == nRows
            set(ax, 'XTickLabel', COND_LABELS, 'XTickLabelRotation', 35);
        else
            set(ax, 'XTickLabel', []);
        end
        grid on; box on; hold off;
    end
end

% Nom des metriques (gras) + unite, verticaux a gauche de chaque ligne, a
% x fixe dans un calque pleine figure -> alignes d'une ligne a l'autre quelle
% que soit la largeur des graduations (cf. plotCombinedJointsFigure.m)
labelAx = axes('Position', [0 0 1 1], 'Visible', 'off');
hold(labelAx, 'on');
for r = 1:nRows
    row_bottom = 1 - TOP_MARGIN - r*row_h - (r-1)*ROW_GAP;
    text(labelAx, 0.022, row_bottom + row_h/2, rowNames{r}, ...
         'Rotation', 90, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
         'FontSize', 14, 'FontName', FONT, 'FontWeight', 'bold');
    text(labelAx, 0.046, row_bottom + row_h/2, rowUnits{r}, ...
         'Rotation', 90, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
         'FontSize', 12, 'FontName', FONT);
end
hold(labelAx, 'off');

drawLegend(COND_LABELS, COLORS, FONT);
end


function [name, unitStr] = splitLabel(lbl)
    % 'Peak amplitude (Normalised EMG (%))' -> 'Peak amplitude', 'Normalised EMG (%)'
    k = strfind(lbl, ' (');
    if isempty(k)
        name = lbl; unitStr = '';
    else
        name = strtrim(lbl(1:k(1)-1));
        unitStr = strtrim(lbl(k(1)+2:end-1));   % retire les parentheses externes
    end
end


function drawLegend(COND_LABELS, COLORS, FONT)
    % Une ligne : couleurs des conditions + participants individuels (meme
    % principe que drawLegend de plotCombinedJointsFigure.m) ; seuils des
    % etoiles donnes dans la legende de la figure (article)
    legAx = axes('Position', [0.03, 0.015, 0.95, 0.03], 'Visible', 'off');
    hold(legAx, 'on');
    h = gobjects(1, numel(COND_LABELS) + 1);
    for ic = 1:numel(COND_LABELS)
        h(ic) = plot(legAx, NaN, NaN, 'o-', 'Color', COLORS(ic,:), 'MarkerFaceColor', COLORS(ic,:), ...
                     'LineWidth', 2.5, 'MarkerSize', 6, 'DisplayName', COND_LABELS{ic});
    end
    h(end) = plot(legAx, NaN, NaN, '.-', 'Color', [0.55 0.55 0.55], 'LineWidth', 0.8, 'MarkerSize', 12, ...
                  'DisplayName', 'Individual participants');
    lgd = legend(legAx, h, 'Orientation', 'horizontal', 'Box', 'off', 'FontSize', 11, ...
                 'NumColumns', numel(h), 'FontName', FONT);
    drawnow;
    lgd.Units = 'normalized';
    lgd.Position(1) = 0.5 - lgd.Position(3)/2;
    lgd.Position(2) = 0.015;
    hold(legAx, 'off');
end


function nLevels = drawSigBrackets(sigPairs, pHolm, yBase, rngY, FONT, fontSize)
    % Crochets + etoiles des paires Holm-significatives. Les crochets sont
    % ranges sur des niveaux compacts : du plus court au plus long, chacun
    % sur le niveau le plus bas ou il ne chevauche aucun autre crochet.
    nLevels = 0;
    if isempty(sigPairs), return; end
    [~, ord] = sort(sigPairs(:,2) - sigPairs(:,1));
    levelSpans = {};                      % levelSpans{l} = (n x 2) intervalles occupes
    for s = ord'
        a = sigPairs(s,1); b = sigPairs(s,2);
        lvl = 1;
        while lvl <= numel(levelSpans) && any(levelSpans{lvl}(:,1) <= b & levelSpans{lvl}(:,2) >= a)
            lvl = lvl + 1;
        end
        if lvl > numel(levelSpans), levelSpans{lvl} = zeros(0,2); end
        levelSpans{lvl}(end+1,:) = [a b];
        yb = yBase + rngY * (0.06 + 0.14 * (lvl-1));
        plot([a a b b], [yb - rngY*0.025, yb, yb, yb - rngY*0.025], 'k-', 'LineWidth', 0.8);
        % etoiles centrees SUR le trait, fond blanc : elles interrompent leur
        % propre crochet au lieu de deborder sur le niveau du dessus
        text((a+b)/2, yb, starStr(pHolm(s)), 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'middle', 'FontName', FONT, 'FontSize', fontSize, ...
             'BackgroundColor', 'white', 'Margin', 0.5);
    end
    nLevels = numel(levelSpans);
end


function s = starStr(p)
    if p < 0.001, s = '***'; elseif p < 0.01, s = '**'; else, s = '*'; end
end
