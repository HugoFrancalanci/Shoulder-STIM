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
%                CONDITIONS_ORDERED / COND_LABELS / COLORS must be IDENTICAL
%                across all rows (checked, errors otherwise) -- they share a
%                single condition legend.
% Outputs    :   1 figure : length(joints) rows x max(nDOF) columns.
% -------------------------------------------------------------------------
% Dependencies : none
% =========================================================================

nRows = length(joints);
nCols = 0;
for r = 1:nRows
    nCols = max(nCols, length(joints{r}.DOF_LABELS));
end

% --- Coherence entre lignes : meme reference de conditions/couleurs, sinon
% la legende partagee (une seule fois, pas une par ligne) n'a pas de sens ---
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

% Palette qualitative pour les paires significatives (10 couleurs
% distinctes, style Tableau10 ; une paire garde la meme couleur sur toutes
% les lignes/joints et tous les DOF ou elle apparait)
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

% --- Recenser une seule fois TOUTES les paires significatives, tous joints
% et tous DOF confondus, dans l'ordre de premiere rencontre ---
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

% --- Taille normale, relative a l'ecran (identique a plotAllCompFigure.m
% et toutes les autres figures du projet) : garantit que la fenetre tient
% toujours a l'ecran, quelle que soit sa taille/resolution/DPI ---
figure('Name', 'Final figure -- All pairwise comparisons (combined joints)', ...
       'units','normalized','outerposition',[0 0 1 1], 'Color','white');

for r = 1:nRows
    J = joints{r};
    nDOF = length(J.DOF_LABELS);

    for idof = 1:nDOF
        subplot(nRows, nCols, (r-1)*nCols + idof); hold on;

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
                          'FaceColor', col, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
            end
        end

        y_bottom = y_bar_top - max(rowIdx,1) * (bar_h + row_gap_b);
        ylim([y_bottom, y_max + data_range*0.08]);
        xlim([0 100]);
        title(dofTitle(J.DOF_LABELS{idof}), 'FontSize', 10);
        if idof == 1
            ylabel(sprintf('%s — Angle (°)', J.rowLabel), 'FontSize', 10);
        else
            ylabel('Angle (°)', 'FontSize', 10);
        end
        if r == nRows, xlabel('Cycle (%)', 'FontSize', 10); end
        set(gca, 'FontSize', 8);
        grid on; box on; hold off;
    end
end

sgtitle('Final figure — all pairwise comparisons', 'FontSize', 14, 'FontWeight', 'bold');

drawLegend(ref, sigPairLabel, nSigPairs, QUAL_PALETTE);

end


function s = dofTitle(label)
    % Un seul cas particulier : "Plane of elevation" n'a pas de sens
    % physique en +/- sans preciser le sens (contrairement aux autres DOF
    % qui portent deja leur convention de signe dans le libelle). Ajoute ici
    % uniquement -- ne touche pas DOF_LABELS dans les caches/scripts source.
    % Convention Anterior(+)/Posterior(-) choisie par analogie avec l'usage
    % le plus courant en litterature d'epaule (0 = plan coronal, + vers la
    % flexion/anterieur) -- pas verifiee contre la definition exacte des
    % axes segment (Wu et al. 2005) pour cette sequence XZY composee ; a
    % confirmer si besoin.
    if strcmpi(strtrim(label), 'Plane of elevation')
        s = {'Plane of elevation', '(Anterior +, Posterior -)'};
    else
        s = label;
    end
end


function drawLegend(ref, sigPairLabel, nSigPairs, QUAL_PALETTE)
    % Legende conditions (1 ligne) directement au-dessus de la legende
    % paires significatives (jusqu'a 2 lignes, NumColumns = ceil(n/2) force
    % le passage a la ligne des qu'il y a plus de la moitie des entrees) --
    % ecart minimal entre les deux, comme dans plotAllCompFigure.m.

    legAx1 = axes('Position', [0.03 0.033 0.95 0.028], 'Visible', 'off');
    hold(legAx1, 'on');
    legHandles1 = gobjects(1, length(ref.CONDITIONS_ORDERED));
    for ic = 1:length(ref.CONDITIONS_ORDERED)
        legHandles1(ic) = plot(legAx1, NaN, NaN, 'Color', ref.COLORS(ic,:), 'LineWidth', 2.5, ...
                                'DisplayName', ref.COND_LABELS{ic});
    end
    lgd1 = legend(legAx1, legHandles1, 'Orientation','horizontal', 'Box','off', 'FontSize', 8, ...
                   'NumColumns', length(ref.CONDITIONS_ORDERED));
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
                'MarkerFaceColor', col, 'MarkerEdgeColor', 'none', 'MarkerSize', 8, ...
                'DisplayName', sigPairLabel{k});
        end
        nCols2 = ceil(nSigPairs / 2);  % force le passage sur 2 lignes des que possible
        lgd2 = legend(legAx2, legHandles2, 'Orientation','horizontal', 'Box','off', 'FontSize', 7.5, ...
                       'NumColumns', nCols2);
        drawnow;
        lgd2.Units = 'normalized';
        lgd2.Position(1) = 0.5 - lgd2.Position(3)/2;
        lgd2.Position(2) = 0.002;
        hold(legAx2, 'off');
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
