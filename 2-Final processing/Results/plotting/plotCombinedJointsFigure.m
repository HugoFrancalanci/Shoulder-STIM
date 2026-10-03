function plotCombinedJointsFigure(joints)
% =========================================================================
% plotCombinedJointsFigure.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   August 2026
% -------------------------------------------------------------------------
% Description :  "Final figure — all pairwise comparisons", combining
%                MULTIPLE joints in a single figure (one row per joint) --
%                built to stack the glenohumeral and scapulo-thoracic
%                "Figure 1" from plotAllCompFigure.m (group mean ± SD band,
%                group-level significant post-hoc bars only) so both joints
%                can be read off the same figure, DOF by DOF. Significant
%                pairs are recensed ONCE across ALL joints/DOF combined, so
%                a given condition pair (e.g. "No FES vs Random") keeps the
%                SAME colour wherever it turns out significant, in either
%                row -- makes it easy to spot a pair that matters for both
%                joints at a glance. Driven by generate_combined_all_comp_
%                figure.m, which loads the per-joint .mat caches and calls
%                this function -- no statistics are (re)computed here, and
%                nothing here touches the per-joint extract_*/cache scripts.
%                All figure-only cosmetics (DOF title text, legend wrapping)
%                live in this one file so they never require rerunning the
%                statistical pipeline. Uses subplot() + a screen-relative
%                figure size (same as every other figure in this project),
%                which is what guarantees it always fits the screen --
%                manually-positioned axes at a fixed inch size was tried
%                and dropped because it doesn't adapt to the actual screen.
% -------------------------------------------------------------------------
% Parameters :   joints — cell array, one struct per row (drawn top to
%                bottom in the given order), each with fields :
%                  .patientMeans       — struct, patientMeans.(cond) = cell
%                                        of (nDOF,101) matrices, one per patient
%                  .CONDITIONS_ORDERED — cell array of condition names (7)
%                  .COND_LABELS        — display labels
%                  .COLORS             — Nx3 RGB, one row per CONDITIONS_ORDERED
%                  .DOF_LABELS         — cell array of DOF titles for that joint
%                  .rowLabel           — short row name, prefixed to the
%                                        y-axis label of column 1 only (e.g.
%                                        'Glenohumeral', 'Scapulothoracic')
%                  .x                  — cycle axis, 0:100
%                  .spmResults         — struct array (1 x nDOF) :
%                                        spmResults(idof).posthoc.(pairFld).clusters/.sig
%                  .ALL_PAIRS          — Nx2 cell array of condition pairs
%                  .PATIENT_IDS        — cell array of patient ID strings
%                  .panelTitles        — optional, cell of panel titles
%                                        overriding dofTitle() (one per DOF)
%                  .titleWeight        — optional, 'normal' or 'bold'
%                                        (default : MATLAB default, bold)
%                  .EXCL_ZONE          — optional, struct from
%                                        computeExclusionZone.m (humerothoracic
%                                        elevation > 90 deg), grey vertical
%                                        band in every panel of that row ;
%                                        missing/[] = no zone
%                CONDITIONS_ORDERED / COND_LABELS / COLORS must be IDENTICAL
%                across all rows (checked, errors otherwise) -- they share a
%                single condition legend.
% Outputs    :   1 figure : length(joints) rows x max(nDOF) columns.
% -------------------------------------------------------------------------
% Dependencies : drawExclusionZone.m (same plotting/ folder)
% =========================================================================

nRows = length(joints);
nCols = 0;
for r = 1:nRows
    nCols = max(nCols, length(joints{r}.DOF_LABELS));
end

ref = joints{1};
for r = 2:nRows
    if ~isequal(joints{r}.CONDITIONS_ORDERED, ref.CONDITIONS_ORDERED) || ...
       ~isequal(joints{r}.COND_LABELS, ref.COND_LABELS) || ...
       ~isequal(joints{r}.COLORS, ref.COLORS)
        error(['plotCombinedJointsFigure: CONDITIONS_ORDERED/COND_LABELS/COLORS ' ...
               'differ between joint %d and joint 1 -- caches were not built ' ...
               'with the same condition/colour setup, cannot share one legend.'], r);
    end
end

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
for r = 1:nRows
    J = joints{r};
    for idof = 1:length(J.DOF_LABELS)
        for kp = 1:size(J.ALL_PAIRS, 1)
            condA = J.ALL_PAIRS{kp,1}; condB = J.ALL_PAIRS{kp,2};
            fld = pairFieldName(condA, condB);
            if isfield(J.spmResults(idof).posthoc, fld)
                ph = J.spmResults(idof).posthoc.(fld);
                if isfield(ph, 'sig') && ph.sig && ~ismember(fld, sigPairFlds)
                    sigPairFlds{end+1}  = fld; %#ok<AGROW>
                    sigPairLabel{end+1} = sprintf('%s vs %s', condLabel(condA, ref.CONDITIONS_ORDERED, ref.COND_LABELS), ...
                                                              condLabel(condB, ref.CONDITIONS_ORDERED, ref.COND_LABELS)); %#ok<AGROW>
                end
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

figure('Name', 'Final figure', ...
       'units','normalized','outerposition',[0 0 1 1], 'Color','white');

TOP_MARGIN    = 0.03;   
BOTTOM_MARGIN = 0.14;  
ROW_GAP       = 0.07;  
row_h = (1 - TOP_MARGIN - BOTTOM_MARGIN - (nRows-1)*ROW_GAP) / nRows;

LEFT_MARGIN  = 0.09;
RIGHT_MARGIN = 0.09;
COL_GAP      = 0.04;
col_w = (1 - LEFT_MARGIN - RIGHT_MARGIN - (nCols-1)*COL_GAP) / nCols;

for r = 1:nRows
    J = joints{r};
    nDOF = length(J.DOF_LABELS);

    for idof = 1:nDOF
        subplot(nRows, nCols, (r-1)*nCols + idof); hold on;
        pos = get(gca, 'Position');            
        pos(2) = 1 - TOP_MARGIN - r*row_h - (r-1)*ROW_GAP; 
        pos(4) = row_h;
        pos(1) = LEFT_MARGIN + (idof-1)*(col_w + COL_GAP);
        pos(3) = col_w;
        set(gca, 'Position', pos);
        if isfield(J, 'EXCL_ZONE'), drawExclusionZone(gca, J.EXCL_ZONE); end

        y_min = Inf; y_max = -Inf;
        for ic = 1:length(J.CONDITIONS_ORDERED)
            stack = getStack(J.patientMeans, J.CONDITIONS_ORDERED{ic});
            if isempty(stack), continue; end

            centralCurve = nanmean(stack(idof,:,:), 3); % (1,101)
            stdCurve     = nanstd(stack(idof,:,:), 0, 3); % (1,101)
            fill([J.x fliplr(J.x)], [centralCurve+stdCurve fliplr(centralCurve-stdCurve)], ...
                 J.COLORS(ic,:), 'FaceAlpha', 0.10, 'EdgeColor', 'none', 'HandleVisibility', 'off');
            y_min = min(y_min, min(centralCurve - stdCurve));
            y_max = max(y_max, max(centralCurve + stdCurve));

            plot(J.x, centralCurve, 'Color', J.COLORS(ic,:), 'LineWidth', 2.2);
        end
        if ~isfinite(y_min), y_min = 0; y_max = 1; end
        data_range = max(y_max - y_min, 0.01);

        bar_h     = data_range * 0.045;
        row_gap_b = data_range * 0.015;
        y_bar_top = y_min - data_range * 0.06;

        rowIdx = 0;
        for kp = 1:size(J.ALL_PAIRS, 1)
            condA = J.ALL_PAIRS{kp,1}; condB = J.ALL_PAIRS{kp,2};
            fld = pairFieldName(condA, condB);
            if ~isfield(J.spmResults(idof).posthoc, fld), continue; end
            ph = J.spmResults(idof).posthoc.(fld);
            if ~isfield(ph, 'sig') || ~ph.sig, continue; end

            rowIdx = rowIdx + 1;
            y_row  = y_bar_top - (rowIdx-1) * (bar_h + row_gap_b);
            col    = QUAL_PALETTE(mod(pairColorIdx(fld)-1, size(QUAL_PALETTE,1)) + 1, :);

            for cl = 1:length(ph.clusters)
                ep = ph.clusters{cl}.endpoints;
                rectangle('Position', [ep(1)-1, y_row, ep(2)-ep(1), bar_h], ...
                          'FaceColor', col, 'EdgeColor', 'k', 'LineWidth', 0.5, 'FaceAlpha', 0.9);
            end
        end

        y_bottom = y_bar_top - max(rowIdx,1) * (bar_h + row_gap_b);
        ylim([y_bottom, y_max + data_range*0.08]);
        xlim([0 100]);
        ttl = dofTitle(J.DOF_LABELS{idof});
        if isfield(J, 'panelTitles') && numel(J.panelTitles) >= idof, ttl = J.panelTitles{idof}; end
        hT = title(ttl, 'FontSize', 15, 'FontName', 'Times New Roman');
        if isfield(J, 'titleWeight'), hT.FontWeight = J.titleWeight; end
        if idof == 1
            ylabel('Angle (°)', 'FontSize', 14, 'FontName', 'Times New Roman');
        end
        if r == nRows, xlabel('Cycle (%)', 'FontSize', 14, 'FontName', 'Times New Roman'); end
        set(gca, 'FontSize', 9, 'FontName', 'Times New Roman');
        grid on; box on; hold off;
    end
end

rowLabelAx = axes('Position', [0 0 1 1], 'Visible', 'off');
hold(rowLabelAx, 'on');
for r = 1:nRows
    row_bottom = 1 - TOP_MARGIN - r*row_h - (r-1)*ROW_GAP;
    text(rowLabelAx, 0.03, row_bottom + row_h/2, joints{r}.rowLabel, ...
         'Rotation', 90, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
         'FontSize', 13, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
end

% sgtitle('Differences in glenohumeral and scapulothoracic kinematics between the seven conditions', 'FontSize', 15, 'FontWeight', 'bold', 'FontName', 'Times New Roman');

exclZoneLeg = [];
for r = 1:nRows
    if isfield(joints{r}, 'EXCL_ZONE') && ~isempty(joints{r}.EXCL_ZONE)
        exclZoneLeg = joints{r}.EXCL_ZONE;
        break;
    end
end
drawLegend(ref, sigPairLabel, nSigPairs, QUAL_PALETTE, BOTTOM_MARGIN, exclZoneLeg);

end


function s = dofTitle(label)
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


function drawLegend(ref, sigPairLabel, nSigPairs, QUAL_PALETTE, BOTTOM_MARGIN, exclZone)

    LEG_GAP = 0.012;
    h1 = 0.63 * BOTTOM_MARGIN;
    h2 = BOTTOM_MARGIN - h1 - LEG_GAP;
    legAx1 = axes('Position', [0.03, h2 + LEG_GAP, 0.95, h1], 'Visible', 'off');
    hold(legAx1, 'on');
    legHandles1 = gobjects(1, length(ref.CONDITIONS_ORDERED));
    for ic = 1:length(ref.CONDITIONS_ORDERED)
        legHandles1(ic) = plot(legAx1, NaN, NaN, 'Color', ref.COLORS(ic,:), 'LineWidth', 2.5, ...
                                'DisplayName', ref.COND_LABELS{ic});
    end
    legHandles1 = [legHandles1, drawExclusionZone(legAx1, exclZone, 'legend')];
    lgd1 = legend(legAx1, legHandles1, 'Orientation','horizontal', 'Box','off', 'FontSize', 9, ...
                   'NumColumns', length(legHandles1), 'FontName', 'Times New Roman');
    drawnow;
    lgd1.Units = 'normalized';
    lgd1.Position(1) = 0.5 - lgd1.Position(3)/2;
    lgd1.Position(2) = h2 + LEG_GAP;
    hold(legAx1, 'off');

% une seule ligne si les paires tiennent (<= 4), sinon reparties sur 2 lignes
if nSigPairs <= 4
    nRow1 = nSigPairs;
else
    nRow1 = ceil(nSigPairs / 2);
end
idxRow1 = 1:nRow1;
idxRow2 = (nRow1+1):nSigPairs;
rowH    = h2 / 2;   
legAx2a = axes('Position', [0.03, rowH, 0.95, rowH], 'Visible', 'off');
hold(legAx2a, 'on');
legHandles2a = gobjects(1, length(idxRow1));
for kk = 1:length(idxRow1)
    k = idxRow1(kk);
    col = QUAL_PALETTE(mod(k-1, size(QUAL_PALETTE,1)) + 1, :);
    legHandles2a(kk) = plot(legAx2a, NaN, NaN, 's', 'MarkerFaceColor', col, ...
        'MarkerEdgeColor', 'none', 'MarkerSize', 9, 'DisplayName', sigPairLabel{k});
end


lgd2a = legend(legAx2a, legHandles2a, 'Orientation','horizontal', 'Box','off', ...
               'FontSize', 9, 'FontName', 'Times New Roman', 'NumColumns', length(idxRow1));
drawnow;
lgd2a.Units = 'normalized';
lgd2a.Position(1) = 0.5 - lgd2a.Position(3)/2;
lgd2a.Position(2) = rowH;
hold(legAx2a, 'off');

if ~isempty(idxRow2)
    legAx2b = axes('Position', [0.03, 0, 0.95, rowH], 'Visible', 'off');
    hold(legAx2b, 'on');
    legHandles2b = gobjects(1, length(idxRow2));
    for kk = 1:length(idxRow2)
        k = idxRow2(kk);
        col = QUAL_PALETTE(mod(k-1, size(QUAL_PALETTE,1)) + 1, :);
        legHandles2b(kk) = plot(legAx2b, NaN, NaN, 's', 'MarkerFaceColor', col, ...
            'MarkerEdgeColor', 'none', 'MarkerSize', 9, 'DisplayName', sigPairLabel{k});
    end
    lgd2b = legend(legAx2b, legHandles2b, 'Orientation','horizontal', 'Box','off', ...
                   'FontSize', 9, 'FontName', 'Times New Roman', 'NumColumns', length(idxRow2));
    drawnow;
    lgd2b.Units = 'normalized';
    lgd2b.Position(1) = 0.5 - lgd2b.Position(3)/2;
    lgd2b.Position(2) = -0.002;
    hold(legAx2b, 'off');
end

end


function fld = pairFieldName(condA, condB)
    fld = matlab.lang.makeValidName(sprintf('%s_vs_%s', condA, condB));
end


function lbl = condLabel(condRaw, CONDITIONS_ORDERED, COND_LABELS)
    idx = find(strcmp(CONDITIONS_ORDERED, condRaw), 1);
    if isempty(idx)
        lbl = strrep(condRaw, '_', ' ');
    else
        lbl = COND_LABELS{idx};
    end
end


function stack = getStack(patientMeans, condName)
    fld = matlab.lang.makeValidName(condName);
    if ~isfield(patientMeans, fld) || isempty(patientMeans.(fld))
        stack = [];
        return;
    end
    pts = patientMeans.(fld);
    stack = cat(3, pts{:}); % (nDOF,101,N)
end
