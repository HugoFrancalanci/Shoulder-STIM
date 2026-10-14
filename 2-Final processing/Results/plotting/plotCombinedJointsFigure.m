function plotCombinedJointsFigure(joints)
% =========================================================================
% plotCombinedJointsFigure.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : August 2026
% -------------------------------------------------------------------------
% Description : Group figure with one row per joint and one column per degree
%               of freedom (article Figure 1, humerothoracic elevation). Group
%               mean +/- SD per condition. Each significant pair is shown as
%               a bicoloured bar under the curves (upper half: colour of the
%               first condition, lower half: colour of the second), ordered
%               by type of comparison (helpers/pairTypeRank.m). Condition
%               legend at the bottom.
% -------------------------------------------------------------------------
% Parameters  : joints : cell array, one struct per row, with fields
%                        patientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS,
%                        DOF_LABELS, rowLabel ('' = none), x, spmResults,
%                        ALL_PAIRS, PATIENT_IDS and optional panelTitles,
%                        titleWeight, EXCL_ZONE
% Outputs     : 1 figure
% -------------------------------------------------------------------------
% Dependencies: drawExclusionZone.m, helpers/pairTypeRank.m
% =========================================================================

FONT = 'Times New Roman';
FS_TICK = 16; FS_LABEL = 20; FS_TITLE = 20; FS_LEGEND = 20;   % tailles de police
LEGEND_ORDER = {'No FES', 'Rehab', 'Random', 'Min PW', 'Min force', 'Min stress', 'Min fatigue'};

nRows = numel(joints);
nCols = max(cellfun(@(j) numel(j.DOF_LABELS), joints));
ref = joints{1};
for r = 2:nRows
    if ~isequal(joints{r}.CONDITIONS_ORDERED, ref.CONDITIONS_ORDERED) || ...
       ~isequal(joints{r}.COND_LABELS, ref.COND_LABELS) || ~isequal(joints{r}.COLORS, ref.COLORS)
        error(['plotCombinedJointsFigure: CONDITIONS_ORDERED/COND_LABELS/COLORS differ between ' ...
               'joint %d and joint 1, cannot share one legend.'], r);
    end
end

figure('Name', 'Final figure', 'units', 'normalized', 'outerposition', [0 0 1 1], 'Color', 'white');
hasRowLabels  = any(cellfun(@(j) ~isempty(j.rowLabel), joints));
TOP_MARGIN    = 0.05;
BOTTOM_MARGIN = 0.13;   % libelle x + legende des conditions
ROW_GAP       = 0.07;
LEFT_MARGIN   = 0.07 + 0.02 * hasRowLabels;
RIGHT_MARGIN  = 0.09;
COL_GAP       = 0.04;
row_h = (1 - TOP_MARGIN - BOTTOM_MARGIN - (nRows-1)*ROW_GAP) / nRows;
col_w = (1 - LEFT_MARGIN - RIGHT_MARGIN - (nCols-1)*COL_GAP) / nCols;

for r = 1:nRows
    J = joints{r};
    for idof = 1:numel(J.DOF_LABELS)
        ax = axes('Position', [LEFT_MARGIN + (idof-1)*(col_w + COL_GAP), 1 - TOP_MARGIN - r*row_h - (r-1)*ROW_GAP, ...
                               col_w, row_h]);
        hold(ax, 'on');
        if isfield(J, 'EXCL_ZONE'), drawExclusionZone(ax, J.EXCL_ZONE); end

        y_min = Inf; y_max = -Inf;
        for ic = 1:numel(J.CONDITIONS_ORDERED)
            stack = getStack(J.patientMeans, J.CONDITIONS_ORDERED{ic});
            if isempty(stack), continue; end
            mu = mean(stack(idof,:,:), 3, 'omitnan'); sd = std(stack(idof,:,:), 0, 3, 'omitnan');
            fill([J.x fliplr(J.x)], [mu+sd fliplr(mu-sd)], J.COLORS(ic,:), 'FaceAlpha', 0.10, ...
                 'EdgeColor', 'none', 'HandleVisibility', 'off');
            plot(J.x, mu, 'Color', J.COLORS(ic,:), 'LineWidth', 2.2);
            y_min = min(y_min, min(mu - sd)); y_max = max(y_max, max(mu + sd));
        end
        if ~isfinite(y_min), y_min = 0; y_max = 1; end
        rngY = max(y_max - y_min, 0.01);

        % paires significatives du panneau, rangees par type de comparaison
        sig = {};
        for kp = 1:size(J.ALL_PAIRS, 1)
            fld = matlab.lang.makeValidName(sprintf('%s_vs_%s', J.ALL_PAIRS{kp,1}, J.ALL_PAIRS{kp,2}));
            if isfield(J.spmResults(idof).posthoc, fld) && J.spmResults(idof).posthoc.(fld).sig
                sig(end+1, :) = {J.ALL_PAIRS{kp,1}, J.ALL_PAIRS{kp,2}, J.spmResults(idof).posthoc.(fld).clusters}; %#ok<AGROW>
            end
        end
        if ~isempty(sig)
            [~, ord] = sort(cellfun(@(a, b) pairTypeRank(a, b), sig(:,1), sig(:,2)));
            sig = sig(ord, :);
        end
        bar_h = 0.06 * rngY; gap = 0.02 * rngY; y_top = y_min - 0.06 * rngY;
        for k = 1:size(sig, 1)   % barre bicolore : condition A en haut, B en bas
            y_row = y_top - (k-1) * (bar_h + gap);
            colA = J.COLORS(strcmp(J.CONDITIONS_ORDERED, sig{k,1}), :);
            colB = J.COLORS(strcmp(J.CONDITIONS_ORDERED, sig{k,2}), :);
            for cl = 1:numel(sig{k,3})
                ep = sig{k,3}{cl}.endpoints;   % 1 % d'avance accepte (convention de la toolbox d'origine)
                xb = ep(1) - 1; wb = ep(2) - ep(1);
                rectangle('Position', [xb, y_row + bar_h/2, wb, bar_h/2], 'FaceColor', colA, 'EdgeColor', 'none');
                rectangle('Position', [xb, y_row, wb, bar_h/2], 'FaceColor', colB, 'EdgeColor', 'none');
                rectangle('Position', [xb, y_row, wb, bar_h], 'FaceColor', 'none', 'EdgeColor', 'k', 'LineWidth', 0.5);
            end
        end
        ylim(ax, [y_top - max(size(sig, 1), 1) * (bar_h + gap), y_max + 0.08 * rngY]);
        xlim(ax, [0 100]);

        ttl = dofTitle(J.DOF_LABELS{idof});
        if isfield(J, 'panelTitles') && numel(J.panelTitles) >= idof, ttl = J.panelTitles{idof}; end
        set(ax, 'FontSize', FS_TICK, 'FontName', FONT);
        hT = title(ax, ttl, 'FontSize', FS_TITLE, 'FontName', FONT);
        if isfield(J, 'titleWeight'), hT.FontWeight = J.titleWeight; end
        if idof == 1, ylabel(ax, 'Angle (°)', 'FontSize', FS_LABEL, 'FontName', FONT); end
        if r == nRows, xlabel(ax, 'Cycle (%)', 'FontSize', FS_LABEL, 'FontName', FONT); end
        grid(ax, 'on'); box(ax, 'on');
    end
end

% Noms des rangees (gras, verticaux), si presents
lab = axes('Position', [0 0 1 1], 'Visible', 'off'); hold(lab, 'on');
for r = 1:nRows
    if isempty(joints{r}.rowLabel), continue; end
    yb = 1 - TOP_MARGIN - r*row_h - (r-1)*ROW_GAP;
    text(lab, 0.03, yb + row_h/2, joints{r}.rowLabel, 'Rotation', 90, 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'middle', 'FontSize', FS_TITLE, 'FontName', FONT, 'FontWeight', 'bold');
end

% Legende des conditions (ordre LEGEND_ORDER) + zone d'exclusion eventuelle
exclZone = [];
for r = 1:nRows
    if isfield(joints{r}, 'EXCL_ZONE') && ~isempty(joints{r}.EXCL_ZONE), exclZone = joints{r}.EXCL_ZONE; break; end
end
legOrder = cellfun(@(l) find(strcmp(ref.COND_LABELS, l), 1), LEGEND_ORDER);
legAx = axes('Position', [0.03 0.005 0.95 0.04], 'Visible', 'off'); hold(legAx, 'on');
h = gobjects(1, numel(legOrder));
for k = 1:numel(legOrder)
    ic = legOrder(k);
    h(k) = plot(legAx, NaN, NaN, 'Color', ref.COLORS(ic,:), 'LineWidth', 3.5, 'DisplayName', ref.COND_LABELS{ic});
end
h = [h, drawExclusionZone(legAx, exclZone, 'legend')];
lgd = legend(legAx, h, 'Orientation', 'horizontal', 'Box', 'off', 'FontSize', FS_LEGEND, ...
             'NumColumns', numel(h), 'FontName', FONT);
drawnow; lgd.Units = 'normalized'; lgd.Position(1) = 0.5 - lgd.Position(3)/2; lgd.Position(2) = 0.005;
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


function stack = getStack(patientMeans, condName)
    fld = matlab.lang.makeValidName(condName);
    if ~isfield(patientMeans, fld) || isempty(patientMeans.(fld))
        stack = [];
        return;
    end
    pts = patientMeans.(fld);
    stack = cat(3, pts{:}); % (nDOF,101,N)
end
