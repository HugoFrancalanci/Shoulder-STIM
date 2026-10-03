function plotRhythmFigure(joints, ELEV_GRID, CONDITIONS_ORDERED, COND_LABELS, COLORS, ALL_PAIRS)
% =========================================================================
% plotRhythmFigure.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   October 2026
% -------------------------------------------------------------------------
% Description :  Scapulohumeral-rhythm figure (extract_scapulohumeral_
%                rhythm_all_comp.m) : one row per joint (GH, ST), one column
%                per DOF ; x-axis = humerothoracic elevation (deg, ascending
%                phase) instead of % cycle. Group mean ± SD per condition,
%                Holm-significant pairs as coloured bars under the curves
%                (one colour per pair, stable across panels and listed in
%                the legend) — same visual conventions as
%                plotCombinedJointsFigure.m (Times New Roman, joint name on
%                the left, condition legend at the bottom, same DOF titles
%                via dofTitle, kept identical to plotCombinedJointsFigure.m).
% -------------------------------------------------------------------------
% Parameters :   joints — cell of structs (.name, .DOF_LABELS,
%                         .rhythmMeans.(cond){ip} = (nDOF, nGrid),
%                         .spmResults(idof).posthoc.(pair).clusters/.sig)
%                ELEV_GRID, CONDITIONS_ORDERED, COND_LABELS, COLORS, ALL_PAIRS
% Outputs    :   1 figure
% -------------------------------------------------------------------------
% Dependencies : none
% =========================================================================

FONT = 'Times New Roman';
QUAL_PALETTE = [0.121 0.466 0.705; 1.000 0.498 0.055; 0.172 0.627 0.172; 0.839 0.153 0.157; ...
                0.580 0.404 0.741; 0.549 0.337 0.294; 0.890 0.467 0.761; 0.498 0.498 0.498; ...
                0.737 0.741 0.133; 0.090 0.745 0.812];
nRows = numel(joints);
nCols = max(cellfun(@(J) numel(J.DOF_LABELS), joints));
step  = ELEV_GRID(2) - ELEV_GRID(1);

% paires significatives recensees une fois (couleur stable)
sigFlds = {}; sigLbl = {};
for r = 1:nRows
    for id = 1:numel(joints{r}.DOF_LABELS)
        res = joints{r}.spmResults(id);
        for kp = 1:size(ALL_PAIRS, 1)
            pf = matlab.lang.makeValidName(sprintf('%s_vs_%s', ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}));
            if isfield(res.posthoc, pf) && res.posthoc.(pf).sig && ~ismember(pf, sigFlds)
                sigFlds{end+1} = pf; %#ok<AGROW>
                sigLbl{end+1} = sprintf('%s vs %s', COND_LABELS{strcmp(CONDITIONS_ORDERED, ALL_PAIRS{kp,1})}, ...
                                        COND_LABELS{strcmp(CONDITIONS_ORDERED, ALL_PAIRS{kp,2})}); %#ok<AGROW>
            end
        end
    end
end

figure('Name', 'Scapulohumeral rhythm -- GH / ST vs humerothoracic elevation', ...
       'units', 'normalized', 'outerposition', [0 0 1 1], 'Color', 'white');
TOP = 0.04; BOTTOM = 0.14; ROWGAP = 0.08; LEFT = 0.09; RIGHT = 0.02; COLGAP = 0.05;
row_h = (1 - TOP - BOTTOM - (nRows-1)*ROWGAP) / nRows;
col_w = (1 - LEFT - RIGHT - (nCols-1)*COLGAP) / nCols;

for r = 1:nRows
    J = joints{r};
    for id = 1:numel(J.DOF_LABELS)
        ax = axes('Position', [LEFT + (id-1)*(col_w + COLGAP), 1 - TOP - r*row_h - (r-1)*ROWGAP, col_w, row_h]);
        hold(ax, 'on');
        y_min = Inf; y_max = -Inf;
        for ic = 1:numel(CONDITIONS_ORDERED)
            Rs = J.rhythmMeans.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic}));
            M  = cell2mat(cellfun(@(q) q(id, :), Rs(:), 'UniformOutput', false));
            mu = mean(M, 1, 'omitnan'); sd = std(M, 0, 1, 'omitnan');
            fill([ELEV_GRID fliplr(ELEV_GRID)], [mu+sd fliplr(mu-sd)], COLORS(ic,:), ...
                 'FaceAlpha', 0.10, 'EdgeColor', 'none');
            plot(ELEV_GRID, mu, 'Color', COLORS(ic,:), 'LineWidth', 2.2);
            y_min = min(y_min, min(mu - sd)); y_max = max(y_max, max(mu + sd));
        end
        rngY = max(y_max - y_min, 0.01);
        bar_h = 0.045*rngY; gap = 0.015*rngY; y_top = y_min - 0.06*rngY; row = 0;
        res = J.spmResults(id);
        for k = 1:numel(sigFlds)
            if ~isfield(res.posthoc, sigFlds{k}) || ~res.posthoc.(sigFlds{k}).sig, continue; end
            row = row + 1; yb = y_top - (row-1)*(bar_h + gap);
            col = QUAL_PALETTE(mod(k-1, size(QUAL_PALETTE,1)) + 1, :);
            cl = res.posthoc.(sigFlds{k}).clusters;
            for c = 1:numel(cl)
                ep = ELEV_GRID(1) + cl{c}.endpoints * step;   % endpoints spm1d 0-based
                rectangle('Position', [ep(1), yb, ep(2)-ep(1), bar_h], 'FaceColor', col, 'EdgeColor', 'k', 'LineWidth', 0.5);
            end
        end
        ylim([y_top - max(row,1)*(bar_h + gap), y_max + 0.08*rngY]);
        xlim([ELEV_GRID(1) ELEV_GRID(end)]);
        title(dofTitle(J.DOF_LABELS{id}), 'FontName', FONT, 'FontSize', 14, 'FontWeight', 'normal');
        if id == 1, ylabel('Angle (°)', 'FontName', FONT, 'FontSize', 13); end
        if r == nRows, xlabel('Humerothoracic elevation (°)', 'FontName', FONT, 'FontSize', 13); end
        set(ax, 'FontName', FONT, 'FontSize', 10); grid(ax, 'on'); box(ax, 'on');
    end
end

lab = axes('Position', [0 0 1 1], 'Visible', 'off'); hold(lab, 'on');
for r = 1:nRows
    yb = 1 - TOP - r*row_h - (r-1)*ROWGAP;
    text(lab, 0.025, yb + row_h/2, joints{r}.name, 'Rotation', 90, 'HorizontalAlignment', 'center', ...
         'FontName', FONT, 'FontSize', 14, 'FontWeight', 'bold');
end

legAx = axes('Position', [0.03 0.06 0.95 0.03], 'Visible', 'off'); hold(legAx, 'on');
h = gobjects(1, numel(COND_LABELS));
for ic = 1:numel(COND_LABELS)
    h(ic) = plot(legAx, NaN, NaN, 'Color', COLORS(ic,:), 'LineWidth', 2.5, 'DisplayName', COND_LABELS{ic});
end
lgd = legend(legAx, h, 'Orientation', 'horizontal', 'Box', 'off', 'FontName', FONT, 'FontSize', 11, 'NumColumns', numel(h));
drawnow; lgd.Units = 'normalized'; lgd.Position(1) = 0.5 - lgd.Position(3)/2; lgd.Position(2) = 0.042;   % rapprochee de la ligne des paires
if ~isempty(sigFlds)
    legAx2 = axes('Position', [0.03 0.015 0.95 0.03], 'Visible', 'off'); hold(legAx2, 'on');
    h2 = gobjects(1, numel(sigFlds));
    for k = 1:numel(sigFlds)
        h2(k) = plot(legAx2, NaN, NaN, 's', 'MarkerFaceColor', QUAL_PALETTE(mod(k-1, size(QUAL_PALETTE,1)) + 1, :), ...
                     'MarkerEdgeColor', 'none', 'MarkerSize', 9, 'DisplayName', sigLbl{k});
    end
    lgd2 = legend(legAx2, h2, 'Orientation', 'horizontal', 'Box', 'off', 'FontName', FONT, 'FontSize', 11, ...
                  'NumColumns', min(numel(h2), 6));
    drawnow; lgd2.Units = 'normalized'; lgd2.Position(1) = 0.5 - lgd2.Position(3)/2; lgd2.Position(2) = 0.012;
end
end


function s = dofTitle(label)
    % Titres d'axes identiques a plotCombinedJointsFigure.m (figure 5)
    lbl = strtrim(label);
    if strcmpi(lbl, 'Plane of elevation')
        s = {'Anterior (-) / posterior (+) plane of elevation'};
    elseif strcmpi(lbl, 'Elevation')
        s = {'Flexion (-) / extension (+)'};
    elseif strcmpi(lbl, 'Protraction (+) / retraction (-)')
        s = {'External (-) / internal (+) rotation'};
    elseif strcmpi(lbl, 'Posterior (+) / anterior (-) tilt')
        s = {'Anterior (-) / Posterior (+) tilt'};
    else
        s = label;
    end
end
