function plotAllCompFigureEMGRatio(patientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS, ...
                                    RATIO_LABELS, RATIO_DISPLAY, x, spmResults, ALL_PAIRS)
% =========================================================================
% plotAllCompFigureEMGRatio.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   August 2026
% -------------------------------------------------------------------------
% Description :  Ratio counterpart of plotAllCompFigureEMG.m, for
%                extract_emg_ratio_all_comp.m. Same "final figure"
%                convention: one panel per ratio, ALL 7 condition group
%                means overlaid, significance bars drawn INSIDE the panel
%                below the curves, one stable colour per significant pair,
%                identified via a shared legend. Produces TWO figures (not
%                three like the amplitude version) :
%                  (1) group mean +- SD band, group-level post-hoc bars.
%                  (2) group mean + every individual patient's own curve
%                      (thin, desaturated), no SD band, group-level bars.
%                No per-patient "P#" labelled variant here: the ratio is
%                derived from the already block-averaged cache
%                (patientMeans), so there is no per-block data left to run
%                an individual-level (N=3) SPM1D on -- see
%                extract_emg_ratio_all_comp.m header for details.
%                A dashed reference line at ratio = 1 (equal amplitude
%                between the two muscles) is drawn in every panel.
% -------------------------------------------------------------------------
% Dependencies : none
% =========================================================================

nRatios = length(RATIO_LABELS);
nPairs  = size(ALL_PAIRS, 1);

set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultTextFontName', 'Times New Roman');
set(groot, 'defaultLegendFontName', 'Times New Roman');

QUAL_PALETTE = [ ...
    0.121 0.466 0.705;
    1.000 0.498 0.055;
    0.172 0.627 0.172;
    0.839 0.153 0.157;
    0.580 0.404 0.741;
    0.549 0.337 0.294;
    0.890 0.467 0.761;
    0.498 0.498 0.498;
    0.737 0.741 0.133;
    0.090 0.745 0.812];

sigPairFlds  = {};
sigPairLabel = {};
for ir = 1:nRatios
    for kp = 1:nPairs
        condA = ALL_PAIRS{kp,1}; condB = ALL_PAIRS{kp,2};
        fld = pairFieldName(condA, condB);
        if isfield(spmResults(ir).posthoc, fld)
            ph = spmResults(ir).posthoc.(fld);
            if isfield(ph, 'sig') && ph.sig && ~ismember(fld, sigPairFlds)
                sigPairFlds{end+1}  = fld; %#ok<AGROW>
                sigPairLabel{end+1} = sprintf('%s vs %s', condLabel(condA), condLabel(condB)); %#ok<AGROW>
            end
        end
    end
end
nSigPairs = length(sigPairFlds);
if nSigPairs > 0
    pairColorIdx = containers.Map(sigPairFlds, num2cell(1:nSigPairs));
else
    pairColorIdx = containers.Map();
end

% --- FIGURE 1 : moyenne de groupe + bande d'ecart-type ---
drawFigure('sd');

% --- FIGURE 2 : moyenne de groupe + courbes individuelles ---
drawFigure('individual');


    function drawFigure(curveMode)
        if strcmp(curveMode, 'sd')
            curveSuffix = 'group mean +- SD';
        else
            curveSuffix = 'group mean + individual patients';
        end
        figName = sprintf('Final figure EMG ratio -- All pairwise comparisons (%s)', curveSuffix);

        figure('Name', figName, 'units','normalized','outerposition',[0 0 1 1], 'Color','white');

        for ir = 1:nRatios
            rl = RATIO_LABELS{ir};
            subplot(1, nRatios, ir); hold on;

            y_min = Inf; y_max = -Inf;
            for ic = 1:length(CONDITIONS_ORDERED)
                stack = getPatientStackRatio(patientMeans, CONDITIONS_ORDERED{ic}, rl);
                if isempty(stack), continue; end

                if strcmp(curveMode, 'sd')
                    centralCurve = nanmean(stack, 1); % (1,101)
                    stdCurve = nanstd(stack, 0, 1); % (1,101)
                    fill([x fliplr(x)], [centralCurve+stdCurve fliplr(centralCurve-stdCurve)], ...
                         COLORS(ic,:), 'FaceAlpha', 0.10, 'EdgeColor', 'none', 'HandleVisibility', 'off');
                    y_min = min(y_min, min(centralCurve - stdCurve));
                    y_max = max(y_max, max(centralCurve + stdCurve));
                else
                    centralCurve = nanmean(stack, 1); % (1,101)
                    for ipp = 1:size(stack, 1)
                        curve = stack(ipp,:);
                        if all(isnan(curve)), continue; end
                        desatColor = COLORS(ic,:) * 0.8 + [0.6 0.6 0.6] * 0.2;
                        pInd = plot(x, curve, 'Color', desatColor, 'LineWidth', 0.6, 'HandleVisibility','off');
                        pInd.Color(4) = 0.90;
                        y_min = min(y_min, min(curve));
                        y_max = max(y_max, max(curve));
                    end
                end

                plot(x, centralCurve, 'Color', COLORS(ic,:), 'LineWidth', 2.2, ...
                     'DisplayName', COND_LABELS{ic});
            end
            if ~isfinite(y_min), y_min = 0; y_max = 2; end
            y_min = min(y_min, 1); y_max = max(y_max, 1);  % ratio=1 toujours dans le cadre
            data_range = max(y_max - y_min, 0.01);

            yline(1, '--', 'Color', [0.55 0.55 0.55], 'LineWidth', 1, 'HandleVisibility', 'off');

            bar_h     = data_range * 0.045;
            row_gap   = data_range * 0.015;
            y_bar_top = y_min - data_range * 0.06;

            rowIdx = drawSigBars(ir, y_bar_top, bar_h, row_gap);

            y_bottom = y_bar_top - max(rowIdx,1) * (bar_h + row_gap);
            ylim([y_bottom, y_max + data_range*0.08]);
            xlim([0 100]);
            title(RATIO_DISPLAY{ir}, 'FontSize', 15);
            if ir == 1
                ylabel('EMG amplitude ratio (a.u.)', 'FontSize', 14);
            end
            xlabel('Cycle (%)', 'FontSize', 14);
            set(gca, 'FontSize', 9);
            grid on; box on; hold off;
        end

        sgtitle('EMG ratio pattern between FES conditions', 'FontSize', 13, 'FontWeight', 'bold');

        drawLegend();
    end


    function rowIdx = drawSigBars(ir, y_bar_top, bar_h, row_gap)
        rowIdx = 0;
        for kp = 1:nPairs
            condA = ALL_PAIRS{kp,1}; condB = ALL_PAIRS{kp,2};
            fld = pairFieldName(condA, condB);
            if ~isfield(spmResults(ir).posthoc, fld), continue; end
            ph = spmResults(ir).posthoc.(fld);
            if ~isfield(ph, 'sig') || ~ph.sig, continue; end

            rowIdx = rowIdx + 1;
            y_row  = y_bar_top - (rowIdx-1) * (bar_h + row_gap);
            col    = QUAL_PALETTE(mod(pairColorIdx(fld)-1, size(QUAL_PALETTE,1)) + 1, :);

            for cl = 1:length(ph.clusters)
                ep = ph.clusters{cl}.endpoints;
                rectangle('Position', [ep(1)-1, y_row, ep(2)-ep(1), bar_h], ...
                          'FaceColor', col, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
            end
        end
    end


    function drawLegend()
        % Deux legendes empilees, chacune sur une seule ligne (meme logique
        % que plotAllCompFigureEMG.m).

        legAx1 = axes('Position', [0.03 0.033 0.95 0.03], 'Visible', 'off');
        hold(legAx1, 'on');
        legHandles1 = gobjects(1, length(CONDITIONS_ORDERED));
        for ic = 1:length(CONDITIONS_ORDERED)
            legHandles1(ic) = plot(legAx1, NaN, NaN, 'Color', COLORS(ic,:), 'LineWidth', 2.5, ...
                                    'DisplayName', COND_LABELS{ic});
        end
        lgd1 = legend(legAx1, legHandles1, 'Orientation','horizontal', 'Box','off', 'FontSize', 9, ...
                       'NumColumns', length(CONDITIONS_ORDERED));
        drawnow;
        lgd1.Units = 'normalized';
        lgd1.Position(1) = 0.5 - lgd1.Position(3)/2;
        lgd1.Position(2) = 0.033;
        hold(legAx1, 'off');

        if nSigPairs > 0
            legAx2 = axes('Position', [0.03 0.002 0.95 0.03], 'Visible', 'off');
            hold(legAx2, 'on');
            legHandles2 = gobjects(1, nSigPairs);
            for k = 1:nSigPairs
                col = QUAL_PALETTE(mod(k-1, size(QUAL_PALETTE,1)) + 1, :);
                legHandles2(k) = plot(legAx2, NaN, NaN, 's', ...
                    'MarkerFaceColor', col, 'MarkerEdgeColor', 'none', 'MarkerSize', 10, ...
                    'DisplayName', sigPairLabel{k});
            end
            lgd2 = legend(legAx2, legHandles2, 'Orientation','horizontal', 'Box','off', 'FontSize', 9, ...
                           'NumColumns', nSigPairs);
            drawnow;
            lgd2.Units = 'normalized';
            lgd2.Position(1) = 0.5 - lgd2.Position(3)/2;
            lgd2.Position(2) = 0.002;
            hold(legAx2, 'off');
        end
    end


    function lbl = condLabel(condRaw)
        idx = find(strcmp(CONDITIONS_ORDERED, condRaw), 1);
        if isempty(idx)
            lbl = strrep(condRaw, '_', ' ');
        else
            lbl = COND_LABELS{idx};
        end
    end

end


function fld = pairFieldName(condA, condB)
    fld = matlab.lang.makeValidName(sprintf('%s_vs_%s', condA, condB));
end


function stack = getPatientStackRatio(patientMeans, condName, ratioLabel)
    fld = matlab.lang.makeValidName(condName);
    if ~isfield(patientMeans, fld) || ~isfield(patientMeans.(fld), ratioLabel) || isempty(patientMeans.(fld).(ratioLabel))
        stack = [];
        return;
    end
    pts = patientMeans.(fld).(ratioLabel);
    stack = cat(1, pts{:});
end
