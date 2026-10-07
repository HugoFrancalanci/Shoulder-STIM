function plotRhythmEmgFigure(J, ELEV_GRID, CONDITIONS_ORDERED, COND_LABELS, COLORS, ALL_PAIRS, K)
% =========================================================================
% plotRhythmEmgFigure.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Article Figure 2, as a function of humerothoracic elevation
%               (ascending phase, 20 to 90 deg). Row 1: scapulothoracic angles,
%               one column per degree of freedom. Row 2: EMG envelopes
%               normalised to the peak of each trial, one column per muscle.
%               Group
%               mean +/- SD per condition, significant pairs (SPM1D, Holm) as
%               grey bars under the curves, one grey level per pair for both
%               rows.
% -------------------------------------------------------------------------
% Parameters  : J : scapulothoracic joint struct (DOF_LABELS, rhythmMeans,
%                   spmResults), from cache_scapulohumeral_rhythm_all_comp.mat
%               ELEV_GRID, CONDITIONS_ORDERED, COND_LABELS, COLORS
%               ALL_PAIRS : pairs of condition names (rhythm cache)
%               K : EMG struct of extract_emg_elevation_all_comp.m (x,
%                   muscleNames, emgMean, emgSD, spm, ALL_PAIRS as indices)
% Outputs     : 1 figure
% -------------------------------------------------------------------------
% Dependencies: none
% =========================================================================

FONT = 'Times New Roman';
FS_TICK = 13; FS_LABEL = 16; FS_TITLE = 17; FS_LEGEND = 14;   % tailles de police
LEGEND_ORDER = {'No FES', 'Rehab', 'Random', 'Min PW', 'Min force', 'Min stress', 'Min fatigue'};
nCond = numel(COND_LABELS);
nDof  = numel(J.DOF_LABELS);
nMus  = numel(K.muscleNames);
step  = ELEV_GRID(2) - ELEV_GRID(1);

% Paires significatives des deux rangees : libelle -> couleur stable
% (d'abord la cinematique, dans l'ordre des paires, puis l'EMG)
sigLbl = {};
for id = 1:nDof
    res = J.spmResults(id);
    for kp = 1:size(ALL_PAIRS, 1)
        pf = matlab.lang.makeValidName(sprintf('%s_vs_%s', ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}));
        if isfield(res.posthoc, pf) && res.posthoc.(pf).sig
            sigLbl = addLabel(sigLbl, pairLabel(ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}, CONDITIONS_ORDERED, COND_LABELS));
        end
    end
end
for m = 1:nMus
    for kp = find(K.spm(m).pairSig(:))'
        sigLbl = addLabel(sigLbl, pairLabel(CONDITIONS_ORDERED{K.ALL_PAIRS(kp,1)}, CONDITIONS_ORDERED{K.ALL_PAIRS(kp,2)}, ...
                                            CONDITIONS_ORDERED, COND_LABELS));
    end
end
% un niveau de gris par paire, du plus fonce au plus clair (bords noirs)
if numel(sigLbl) <= 1, GREYS = repmat(0.5, max(numel(sigLbl), 1), 3);
else, GREYS = repmat(linspace(0.15, 0.85, numel(sigLbl))', 1, 3); end
pairCol = @(lbl) GREYS(strcmp(sigLbl, lbl), :);

figure('Name', 'Manuscript figure -- scapulothoracic kinematics and EMG vs humerothoracic elevation', ...
       'units', 'normalized', 'outerposition', [0 0 1 1], 'Color', 'white');
TOP = 0.04; BOTTOM = 0.17; ROWGAP = 0.09; LEFT = 0.09; RIGHT = 0.02; COLGAP = 0.035;
row_h = (1 - TOP - BOTTOM - ROWGAP) / 2;
rowBottom = [1 - TOP - row_h, BOTTOM];

% --- Rangee 1 : angles scapulothoraciques ---------------------------------
col_w = (1 - LEFT - RIGHT - (nDof-1)*COLGAP) / nDof;
for id = 1:nDof
    ax = axes('Position', [LEFT + (id-1)*(col_w + COLGAP), rowBottom(1), col_w, row_h]); hold(ax, 'on');
    y_min = Inf; y_max = -Inf;
    for ic = 1:nCond
        Rs = J.rhythmMeans.(matlab.lang.makeValidName(CONDITIONS_ORDERED{ic}));
        M  = cell2mat(cellfun(@(q) q(id, :), Rs(:), 'UniformOutput', false));
        mu = mean(M, 1, 'omitnan'); sd = std(M, 0, 1, 'omitnan');
        fill([ELEV_GRID fliplr(ELEV_GRID)], [mu+sd fliplr(mu-sd)], COLORS(ic,:), 'FaceAlpha', 0.10, 'EdgeColor', 'none');
        plot(ELEV_GRID, mu, 'Color', COLORS(ic,:), 'LineWidth', 2.2);
        y_min = min(y_min, min(mu - sd)); y_max = max(y_max, max(mu + sd));
    end
    rngY = max(y_max - y_min, 0.01);
    bar_h = 0.045*rngY; gap = 0.015*rngY; y_top = y_min - 0.06*rngY; row = 0;
    res = J.spmResults(id);
    for kp = 1:size(ALL_PAIRS, 1)
        pf = matlab.lang.makeValidName(sprintf('%s_vs_%s', ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}));
        if ~isfield(res.posthoc, pf) || ~res.posthoc.(pf).sig, continue; end
        row = row + 1; yb = y_top - (row-1)*(bar_h + gap);
        col = pairCol(pairLabel(ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}, CONDITIONS_ORDERED, COND_LABELS));
        cl = res.posthoc.(pf).clusters;
        for c = 1:numel(cl)
            ep = ELEV_GRID(1) + cl{c}.endpoints * step;   % endpoints spm1d 0-based
            rectangle('Position', [ep(1), yb, ep(2)-ep(1), bar_h], 'FaceColor', col, 'EdgeColor', 'k', 'LineWidth', 0.5);
        end
    end
    ylim(ax, [y_top - max(row,1)*(bar_h + gap), y_max + 0.08*rngY]);
    styleAxes(ax, FONT, dofTitle(J.DOF_LABELS{id}), ELEV_GRID, FS_TICK, FS_TITLE);
    if id == 1, ylabel(ax, 'Angle (°)', 'FontName', FONT, 'FontSize', FS_LABEL); end
end

% --- Rangee 2 : EMG normalisee au pic --------------------------------------
nRowsBar = 0;
for m = 1:nMus, nRowsBar = max(nRowsBar, sum(K.spm(m).pairSig)); end
BAR_H = 4.5; BAR_GAP = 1.5; BAR_TOP = -4;   % en % du pic, sous les courbes
yBottom = 0;
if nRowsBar > 0, yBottom = BAR_TOP - nRowsBar * (BAR_H + BAR_GAP); end
col_w = (1 - LEFT - RIGHT - (nMus-1)*COLGAP) / nMus;
for m = 1:nMus
    ax = axes('Position', [LEFT + (m-1)*(col_w + COLGAP), rowBottom(2), col_w, row_h]); hold(ax, 'on');
    for ic = 1:nCond   % bandes moyenne +/- ET (bornees a 0-100 %)
        lo = max(K.emgMean{m}(ic,:) - K.emgSD{m}(ic,:), 0);
        hi = min(K.emgMean{m}(ic,:) + K.emgSD{m}(ic,:), 100);
        fill([K.x fliplr(K.x)], [hi fliplr(lo)], COLORS(ic,:), 'FaceAlpha', 0.08, 'EdgeColor', 'none');
    end
    for ic = 1:nCond
        plot(K.x, K.emgMean{m}(ic,:), '-', 'Color', COLORS(ic,:), 'LineWidth', 2.2);
    end
    rowIdx = 0;
    for kp = find(K.spm(m).pairSig(:))'
        rowIdx = rowIdx + 1;
        y_row = BAR_TOP - rowIdx * BAR_H - (rowIdx - 1) * BAR_GAP;
        col = pairCol(pairLabel(CONDITIONS_ORDERED{K.ALL_PAIRS(kp,1)}, CONDITIONS_ORDERED{K.ALL_PAIRS(kp,2)}, ...
                                CONDITIONS_ORDERED, COND_LABELS));
        C = K.spm(m).pairClusters{kp};
        for cl = 1:size(C, 1)
            rectangle('Position', [C(cl,1), y_row, max(C(cl,2) - C(cl,1), 0.5), BAR_H], ...
                      'FaceColor', col, 'EdgeColor', 'k', 'LineWidth', 0.5);
        end
    end
    ylim(ax, [yBottom 100]); yticks(ax, 0:20:100);
    styleAxes(ax, FONT, K.muscleNames{m}, K.x, FS_TICK, FS_TITLE);
    if m == 1, ylabel(ax, 'Normalised EMG (% of peak)','FontName', FONT, 'FontSize', FS_LABEL); end
    xlabel(ax, 'Humerothoracic elevation (°)', 'FontName', FONT, 'FontSize', FS_LABEL);
end

% Noms des rangees (gras, verticaux)
lab = axes('Position', [0 0 1 1], 'Visible', 'off'); hold(lab, 'on');
rowNames = {'Scapulothoracic', 'Scapular muscles'};
for r = 1:2
    text(lab, 0.022, rowBottom(r) + row_h/2, rowNames{r}, 'Rotation', 90, 'HorizontalAlignment', 'center', ...
         'FontName', FONT, 'FontSize', FS_TITLE, 'FontWeight', 'bold');
end

% Legende : conditions (ordre LEGEND_ORDER), puis paires significatives
legOrder = cellfun(@(l) find(strcmp(COND_LABELS, l), 1), LEGEND_ORDER);
legAx = axes('Position', [0.03 0.06 0.95 0.03], 'Visible', 'off'); hold(legAx, 'on');
h = gobjects(1, nCond);
for k = 1:nCond
    ic = legOrder(k);
    h(k) = plot(legAx, NaN, NaN, 'Color', COLORS(ic,:), 'LineWidth', 2.5, 'DisplayName', COND_LABELS{ic});
end
lgd = legend(legAx, h, 'Orientation', 'horizontal', 'Box', 'off', 'FontName', FONT, 'FontSize', FS_LEGEND, 'NumColumns', nCond);
drawnow; lgd.Units = 'normalized'; lgd.Position(1) = 0.5 - lgd.Position(3)/2; lgd.Position(2) = 0.05;
if ~isempty(sigLbl)
    legAx2 = axes('Position', [0.03 0.015 0.95 0.03], 'Visible', 'off'); hold(legAx2, 'on');
    h2 = gobjects(1, numel(sigLbl));
    for k = 1:numel(sigLbl)
        h2(k) = plot(legAx2, NaN, NaN, 's', 'MarkerFaceColor', pairCol(sigLbl{k}), 'MarkerEdgeColor', 'k', ...
                     'MarkerSize', 11, 'DisplayName', sigLbl{k});
    end
    lgd2 = legend(legAx2, h2, 'Orientation', 'horizontal', 'Box', 'off', 'FontName', FONT, 'FontSize', FS_LEGEND, ...
                  'NumColumns', min(numel(h2), 6));
    drawnow; lgd2.Units = 'normalized'; lgd2.Position(1) = 0.5 - lgd2.Position(3)/2; lgd2.Position(2) = 0.015;
end
end


function styleAxes(ax, FONT, ttl, xg, fsTick, fsTitle)
    set(ax, 'FontName', FONT, 'FontSize', fsTick);
    title(ax, ttl, 'FontName', FONT, 'FontSize', fsTitle, 'FontWeight', 'normal');
    ax.YAxis.Exponent = 0;
    xlim(ax, [xg(1) xg(end)]);
    grid(ax, 'on'); box(ax, 'on');
end


function lbl = pairLabel(condA, condB, CONDITIONS_ORDERED, COND_LABELS)
    lbl = sprintf('%s vs %s', COND_LABELS{strcmp(CONDITIONS_ORDERED, condA)}, COND_LABELS{strcmp(CONDITIONS_ORDERED, condB)});
end


function L = addLabel(L, lbl)
    if ~ismember(lbl, L), L{end+1} = lbl; end
end


function s = dofTitle(label)
    % Titres des degres de liberte scapulothoraciques
    lbl = strtrim(label);
    if strcmpi(lbl, 'Protraction (+) / retraction (-)')
        s = {'External (-) / internal (+) rotation'};
    elseif strcmpi(lbl, 'Posterior (+) / anterior (-) tilt')
        s = {'Anterior (-) / Posterior (+) tilt'};
    else
        s = label;
    end
end
