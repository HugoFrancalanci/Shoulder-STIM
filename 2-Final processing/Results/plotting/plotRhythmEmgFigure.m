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
%               normalised to the peak of each trial, one column per muscle
%               (shared y axis). Group mean per condition, with mean +/- SD
%               bands for 3 groups of conditions (No FES, non-optimised,
%               optimised). Each significant pair (SPM1D, Holm) is shown as a bicoloured bar
%               under the curves (upper half: first condition, lower half:
%               second condition), ordered by type of comparison
%               (helpers/pairTypeRank.m). One x label for the figure,
%               condition legend at the bottom.
% -------------------------------------------------------------------------
% Parameters  : J : scapulothoracic joint struct (DOF_LABELS, rhythmMeans,
%                   spmResults), from cache_scapulohumeral_rhythm_all_comp.mat
%               ELEV_GRID, CONDITIONS_ORDERED, COND_LABELS, COLORS
%               ALL_PAIRS : pairs of condition names (rhythm cache)
%               K : EMG struct of extract_emg_elevation_all_comp.m (x,
%                   muscleNames, emgMean, elevProf, spm, ALL_PAIRS as indices)
% Outputs     : 1 figure
% -------------------------------------------------------------------------
% Dependencies: helpers/pairTypeRank.m
% =========================================================================

FONT = 'Times New Roman';
FS_TICK = 22; FS_LABEL = 26; FS_TITLE = 26; FS_LEGEND = 26;   % tailles de police (comme la figure 1)
LEGEND_ORDER = {'No FES', 'Rehab', 'Random', 'Min PW', 'Min force', 'Min stress', 'Min fatigue'};
% Groupes des bandes moyenne +/- ET (couleur de la 1re condition de chaque groupe)
GROUPS = {{'No FES'}, {'Rehab','Random'}, {'Min_stress','Min_pulse_width','Min_force','Min_fatigue'}};
BAND_ALPHA = [0.13 0.13 0.18];
nCond = numel(COND_LABELS);
nDof  = numel(J.DOF_LABELS);
nMus  = numel(K.muscleNames);
step  = ELEV_GRID(2) - ELEV_GRID(1);
colOf = @(cond) COLORS(strcmp(CONDITIONS_ORDERED, cond), :);

% taille fixe et theme clair : rendu independant de l'ecran et du theme de MATLAB
fig = figure('Name', 'Manuscript figure -- scapulothoracic kinematics and EMG vs humerothoracic elevation', ...
             'Units', 'pixels', 'Position', [0 0 1800 900], 'Color', 'white');
if isprop(fig, 'Theme'), fig.Theme = 'light'; end
TOP = 0.05; BOTTOM = 0.165; ROWGAP = 0.115; LEFT = 0.09; RIGHT = 0.015;   % ROWGAP : air entre les graduations x de la rangee 1 et les titres des muscles
COLGAP_ST = 0.04;    % rangee 1 : chaque panneau a sa propre echelle
COLGAP_EMG = 0.045;  % rangee 2 : echelle commune, graduations y sur le 1er panneau seulement ;
                     % ecart suffisant pour que "90" et le "20" suivant ne se chevauchent pas
row_h = (1 - TOP - BOTTOM - ROWGAP) / 2;
rowBottom = [1 - TOP - row_h, BOTTOM];

% --- Rangee 1 : angles scapulothoraciques ---------------------------------
col_w = (1 - LEFT - RIGHT - (nDof-1)*COLGAP_ST) / nDof;
for id = 1:nDof
    ax = axes('Position', [LEFT + (id-1)*(col_w + COLGAP_ST), rowBottom(1), col_w, row_h]); hold(ax, 'on');
    y_min = Inf; y_max = -Inf;
    stackOf = @(c) cell2mat(cellfun(@(q) q(id, :), J.rhythmMeans.(matlab.lang.makeValidName(c))(:), 'UniformOutput', false));
    for g = 1:numel(GROUPS)   % bandes par groupe de conditions, sous les courbes
        [mg, sg] = groupBand(cellfun(stackOf, GROUPS{g}, 'UniformOutput', false));
        fill([ELEV_GRID fliplr(ELEV_GRID)], [mg+sg fliplr(mg-sg)], colOf(GROUPS{g}{1}), 'FaceAlpha', BAND_ALPHA(g), 'EdgeColor', 'none');
        y_min = min(y_min, min(mg - sg)); y_max = max(y_max, max(mg + sg));
    end
    for ic = 1:nCond
        mu = mean(stackOf(CONDITIONS_ORDERED{ic}), 1, 'omitnan');
        plot(ELEV_GRID, mu, 'Color', COLORS(ic,:), 'LineWidth', 2.8);
        y_min = min(y_min, min(mu)); y_max = max(y_max, max(mu));
    end
    rngY = max(y_max - y_min, 0.01);
    res = J.spmResults(id);
    sig = {};
    for kp = 1:size(ALL_PAIRS, 1)
        pf = matlab.lang.makeValidName(sprintf('%s_vs_%s', ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}));
        if isfield(res.posthoc, pf) && res.posthoc.(pf).sig
            ep = cell2mat(cellfun(@(c) ELEV_GRID(1) + c.endpoints * step, res.posthoc.(pf).clusters(:), ...
                                  'UniformOutput', false));   % endpoints spm1d 0-based -> deg
            sig(end+1, :) = {ALL_PAIRS{kp,1}, ALL_PAIRS{kp,2}, ep}; %#ok<AGROW>
        end
    end
    nBars = drawPairBars(sig, colOf, y_min - 0.06*rngY, 0.06*rngY, 0.02*rngY);
    ylim(ax, [y_min - 0.06*rngY - max(nBars, 1)*0.08*rngY, y_max + 0.08*rngY]);
    styleAxes(ax, FONT, dofTitle(J.DOF_LABELS{id}), ELEV_GRID, FS_TICK, FS_TITLE);
    xticks(ax, 20:10:90); xtickangle(ax, 0);   % graduations droites, jusqu'a 90 sur chaque panneau
    if id == 1, ylabel(ax, 'Angle (°)', 'FontName', FONT, 'FontSize', FS_LABEL); end
end

% --- Rangee 2 : EMG normalisee au pic (echelle commune 0-100 %) ------------
BAR_H = 6; BAR_GAP = 2; BAR_TOP = -4;   % en % du pic, sous les courbes
nRowsBar = max(arrayfun(@(s) sum(s.pairSig), K.spm));
yBottom = BAR_TOP - max(nRowsBar, 0) * (BAR_H + BAR_GAP);
if nRowsBar == 0, yBottom = 0; end
col_w = (1 - LEFT - RIGHT - (nMus-1)*COLGAP_EMG) / nMus;
for m = 1:nMus
    ax = axes('Position', [LEFT + (m-1)*(col_w + COLGAP_EMG), rowBottom(2), col_w, row_h]); hold(ax, 'on');
    for g = 1:numel(GROUPS)   % bandes moyenne +/- ET par groupe (bornees a 0-100 %)
        [mg, sg] = groupBand(K.elevProf{m}(ismember(CONDITIONS_ORDERED, GROUPS{g})));
        lo = max(mg - sg, 0); hi = min(mg + sg, 100);
        fill([K.x fliplr(K.x)], [hi fliplr(lo)], colOf(GROUPS{g}{1}), 'FaceAlpha', BAND_ALPHA(g), 'EdgeColor', 'none');
    end
    for ic = 1:nCond
        plot(K.x, K.emgMean{m}(ic,:), '-', 'Color', COLORS(ic,:), 'LineWidth', 2.8);
    end
    sig = {};
    for kp = find(K.spm(m).pairSig(:))'
        sig(end+1, :) = {CONDITIONS_ORDERED{K.ALL_PAIRS(kp,1)}, CONDITIONS_ORDERED{K.ALL_PAIRS(kp,2)}, ...
                         K.spm(m).pairClusters{kp}(:, 1:2)}; %#ok<AGROW>
    end
    drawPairBars(sig, colOf, BAR_TOP - BAR_H, BAR_H, BAR_GAP);
    ylim(ax, [yBottom 100]); yticks(ax, 0:20:100);
    styleAxes(ax, FONT, K.muscleNames{m}, K.x, FS_TICK, FS_TITLE);
    xticks(ax, 20:10:90); xtickangle(ax, 0);   % memes graduations que la rangee 1
    if m == 1
        ylabel(ax, 'Normalised EMG (% of peak)', 'FontName', FONT, 'FontSize', FS_LABEL);
    else
        ax.YTickLabel = {};   % meme echelle que le premier panneau
    end
end

% Noms des rangees (gras, verticaux, au plus pres des graphes) et label x unique
lab = axes('Position', [0 0 1 1], 'Visible', 'off'); hold(lab, 'on');
rowNames = {'Scapulothoracic', 'Scapular muscles'};
for r = 1:2
    text(lab, 0.012, rowBottom(r) + row_h/2, rowNames{r}, 'Rotation', 90, 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'middle', 'FontName', FONT, 'FontSize', FS_TITLE, 'FontWeight', 'bold');
end
text(lab, LEFT + (1 - LEFT - RIGHT)/2, BOTTOM - 0.08, 'Thoracohumeral elevation (°)', ...
     'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontName', FONT, 'FontSize', FS_LABEL);

% Legende des conditions (ordre LEGEND_ORDER)
legOrder = cellfun(@(l) find(strcmp(COND_LABELS, l), 1), LEGEND_ORDER);
legAx = axes('Position', [0.03 0.005 0.95 0.05], 'Visible', 'off'); hold(legAx, 'on');
h = gobjects(1, nCond);
for k = 1:nCond
    ic = legOrder(k);
    h(k) = plot(legAx, NaN, NaN, 'Color', COLORS(ic,:), 'LineWidth', 3.5, 'DisplayName', COND_LABELS{ic});
end
% centree par MATLAB (Location) : reste centree quelle que soit la taille de rendu
legend(legAx, h, 'Orientation', 'horizontal', 'Box', 'off', 'FontName', FONT, 'FontSize', FS_LEGEND, ...
       'NumColumns', nCond, 'Location', 'north');
end


function [mu, sd] = groupBand(stacks)
    % Moyenne +/- ET entre participants d'un groupe de conditions. stacks : une
    % matrice (N, nPts) par condition, moyennees d'abord pour chaque participant
    M = mean(cat(3, stacks{:}), 3);
    mu = mean(M, 1, 'omitnan'); sd = std(M, 0, 1, 'omitnan');
end


function n = drawPairBars(sig, colOf, yTop, barH, gap)
    % Barres bicolores sous les courbes, rangees par type de comparaison.
    % sig : {condA, condB, [debut fin] par cluster (unites de l'axe x)}
    n = size(sig, 1);
    if n == 0, return; end
    [~, ord] = sort(cellfun(@(a, b) pairTypeRank(a, b), sig(:,1), sig(:,2)));
    sig = sig(ord, :);
    for k = 1:n
        y = yTop - (k-1) * (barH + gap);
        C = sig{k,3};
        for c = 1:size(C, 1)
            w = max(C(c,2) - C(c,1), 0.5);
            rectangle('Position', [C(c,1), y + barH/2, w, barH/2], 'FaceColor', colOf(sig{k,1}), 'EdgeColor', 'none');
            rectangle('Position', [C(c,1), y, w, barH/2], 'FaceColor', colOf(sig{k,2}), 'EdgeColor', 'none');
            rectangle('Position', [C(c,1), y, w, barH], 'FaceColor', 'none', 'EdgeColor', 'k', 'LineWidth', 0.5);
        end
    end
end


function styleAxes(ax, FONT, ttl, xg, fsTick, fsTitle)
    set(ax, 'FontName', FONT, 'FontSize', fsTick);
    title(ax, ttl, 'FontName', FONT, 'FontSize', fsTitle, 'FontWeight', 'bold');   % titres des DOF et des muscles en gras
    ax.YAxis.Exponent = 0;
    xlim(ax, [xg(1) xg(end)]);
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
