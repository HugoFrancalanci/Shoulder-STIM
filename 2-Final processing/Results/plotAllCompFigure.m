function plotAllCompFigure(patientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS, DOF_LABELS, x, ...
                            spmResults, ALL_PAIRS, indivSigClusters, PATIENT_IDS)
% =========================================================================
% plotAllCompFigure.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   July 2026
% -------------------------------------------------------------------------
% Description :  "Figure finale — toutes comparaisons" companion to
%                plotCombinedFigure.m, for the all-pairwise-comparisons
%                variant (extract_scapular_kinematics_all_comp.m). Unlike
%                plotCombinedFigure.m : no reference condition — all 7
%                condition group means are overlaid together in a single
%                panel per DOF, spanning the FULL figure height (1 row x
%                nDOF columns). Significance bars are drawn INSIDE the same
%                panel, below the curves (ylim extended downward). Since
%                only a handful of the 21 possible pairs are typically
%                significant, each significant pair is assigned its OWN
%                distinct color (consistent across all DOF panels and
%                across all figures below) and identified via the legend,
%                instead of an inline text label next to every bar.
%                Produces THREE figures (same curve/legend logic reused
%                across all three) :
%                  (1) group mean ± SD band, one shaded band per condition,
%                      group-level post-hoc bars only.
%                  (2) group mean + every individual patient's own curve
%                      (thin, desaturated ~45% toward grey, semi-transparent),
%                      no SD band — real trajectories instead of a summary
%                      band. Group-level post-hoc bars only.
%                  (3) same curves as (1) (mean ± SD), but for every
%                      significant pair : the opaque group-level bar is
%                      followed underneath by one semi-transparent row per
%                      patient who was ALSO individually significant for
%                      that same pair (indivSigClusters), each labelled
%                      "P#" next to its own bar — same label-placement
%                      logic as plotCombinedFigureLabeled.m (next to the
%                      first cluster, flips to the left if too close to the
%                      right edge or if the patient has several close
%                      clusters on the same row).
% -------------------------------------------------------------------------
% Parameters :   patientMeans        — struct, patientMeans.(cond) = cell of
%                                      (3,101) matrices, one per patient
%                CONDITIONS_ORDERED  — cell array of condition names (7)
%                COND_LABELS         — display labels (underscore -> space)
%                COLORS              — Nx3 RGB, one row per CONDITIONS_ORDERED
%                DOF_LABELS          — cell array of DOF titles (3)
%                x                   — cycle axis, 0:100
%                spmResults          — struct array (1x3, per DOF) :
%                                      spmResults(idof).posthoc.(pairFld).clusters/.sig
%                                      pairFld = pairFieldName(condA,condB)
%                ALL_PAIRS           — Nx2 cell array of condition-name
%                                      pairs {condA, condB} (raw names from
%                                      CONDITIONS_ORDERED, same ones used to
%                                      build pairFld in the calling script)
%                indivSigClusters    — cell array (1x3, per DOF) of structs :
%                                      indivSigClusters{idof}.(pairFld){ip} =
%                                      spm1d clusters (cell, empty if n.s.)
%                PATIENT_IDS         — cell array of patient ID strings (N=10)
% Outputs    :   3 figures : 1 row x length(DOF_LABELS) columns each
% -------------------------------------------------------------------------
% Dependencies : none
% =========================================================================

nDOF   = length(DOF_LABELS);
nPairs = size(ALL_PAIRS, 1);

% Palette qualitative pour les paires significatives (10 couleurs
% distinctes, style Tableau10 ; une paire garde la meme couleur sur tous
% les DOF et sur les trois figures)
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

% --- Recenser une seule fois toutes les paires significatives (au moins un
% DOF), dans l'ordre de premiere rencontre, pour assigner une couleur
% stable et construire la legende ---
sigPairFlds  = {};
sigPairLabel = {};
for idof = 1:nDOF
    for kp = 1:nPairs
        condA = ALL_PAIRS{kp,1}; condB = ALL_PAIRS{kp,2};
        fld = pairFieldName(condA, condB);
        if isfield(spmResults(idof).posthoc, fld)
            ph = spmResults(idof).posthoc.(fld);
            if isfield(ph, 'sig') && ph.sig && ~ismember(fld, sigPairFlds)
                sigPairFlds{end+1}  = fld; %#ok<AGROW>
                sigPairLabel{end+1} = sprintf('%s vs %s', strrep(condA,'_',' '), strrep(condB,'_',' ')); %#ok<AGROW>
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
drawFigure('sd', 'group');

% --- FIGURE 2 : moyenne de groupe + courbes individuelles ---
drawFigure('individual', 'group');

% --- FIGURE 3 : moyenne +- SD, barres groupe + individuelles etiquetees P# ---
drawFigure('sd', 'labelled');


    function drawFigure(curveMode, barMode)
        if strcmp(curveMode, 'sd')
            curveSuffix = 'group mean +- SD';
        else
            curveSuffix = 'group mean + individual patients';
        end
        if strcmp(barMode, 'labelled')
            figName     = sprintf('Final figure -- All pairwise comparisons (%s, patient IDs)', curveSuffix);
            titleSuffix = sprintf('(%s, patient IDs next to individual bars)', curveSuffix);
        else
            figName     = sprintf('Final figure -- All pairwise comparisons (%s)', curveSuffix);
            titleSuffix = sprintf('(%s)', curveSuffix);
        end

        figure('Name', figName, 'units','normalized','outerposition',[0 0 1 1], 'Color','white');

        for idof = 1:nDOF
            subplot(1, nDOF, idof); hold on;

            y_min = Inf; y_max = -Inf;
            for ic = 1:length(CONDITIONS_ORDERED)
                stack = getPatientStackKin(patientMeans, CONDITIONS_ORDERED{ic});
                if isempty(stack), continue; end

                if strcmp(curveMode, 'sd')
                    centralCurve = nanmean(stack(idof,:,:), 3); % (1,101)
                    stdCurve = nanstd(stack(idof,:,:), 0, 3); % (1,101)
                    fill([x fliplr(x)], [centralCurve+stdCurve fliplr(centralCurve-stdCurve)], ...
                         COLORS(ic,:), 'FaceAlpha', 0.10, 'EdgeColor', 'none', 'HandleVisibility', 'off');
                    y_min = min(y_min, min(centralCurve - stdCurve));
                    y_max = max(y_max, max(centralCurve + stdCurve));
                else
                    centralCurve = nanmean(stack(idof,:,:), 3); % (1,101)
                    for ipp = 1:size(stack, 3)
                        curve = stack(idof,:,ipp);
                        if all(isnan(curve)), continue; end
                        desatColor = COLORS(ic,:) * 0.55 + [0.6 0.6 0.6] * 0.45;
                        pInd = plot(x, curve, 'Color', desatColor, 'LineWidth', 0.5, 'HandleVisibility','off');
                        pInd.Color(4) = 0.50;
                        y_min = min(y_min, min(curve));
                        y_max = max(y_max, max(curve));
                    end
                end

                plot(x, centralCurve, 'Color', COLORS(ic,:), 'LineWidth', 2.2, ...
                     'DisplayName', COND_LABELS{ic});
            end
            if ~isfinite(y_min), y_min = 0; y_max = 1; end
            data_range = max(y_max - y_min, 0.01);

            bar_h     = data_range * 0.045;
            row_gap   = data_range * 0.015;
            y_bar_top = y_min - data_range * 0.06;

            if strcmp(barMode, 'labelled')
                rowIdx = drawSigBarsLabelled(idof, y_bar_top, bar_h, row_gap);
            else
                rowIdx = drawSigBars(idof, y_bar_top, bar_h, row_gap);
            end

            y_bottom = y_bar_top - max(rowIdx,1) * (bar_h + row_gap);
            ylim([y_bottom, y_max + data_range*0.08]);
            xlim([0 100]);
            title(DOF_LABELS{idof}, 'FontSize', 10);
            ylabel('Angle (°)', 'FontSize', 11);
            xlabel('Cycle (%)', 'FontSize', 10);
            set(gca, 'FontSize', 8);
            grid on; box on; hold off;
        end

        sgtitle(sprintf('Scapular kinematics — group mean, all pairwise post-hoc comparisons %s', titleSuffix), ...
                'FontSize', 13, 'FontWeight', 'bold');

        drawLegend();
    end


    function rowIdx = drawSigBars(idof, y_bar_top, bar_h, row_gap)
        rowIdx = 0;
        for kp = 1:nPairs
            condA = ALL_PAIRS{kp,1}; condB = ALL_PAIRS{kp,2};
            fld = pairFieldName(condA, condB);
            if ~isfield(spmResults(idof).posthoc, fld), continue; end
            ph = spmResults(idof).posthoc.(fld);
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


    function rowIdx = drawSigBarsLabelled(idof, y_bar_top, bar_h, row_gap)
        rowIdx = 0;
        for kp = 1:nPairs
            condA = ALL_PAIRS{kp,1}; condB = ALL_PAIRS{kp,2};
            fld = pairFieldName(condA, condB);
            if ~isfield(spmResults(idof).posthoc, fld), continue; end
            ph = spmResults(idof).posthoc.(fld);
            if ~isfield(ph, 'sig') || ~ph.sig, continue; end

            col = QUAL_PALETTE(mod(pairColorIdx(fld)-1, size(QUAL_PALETTE,1)) + 1, :);

            % --- Barre groupe (pleine, opaque) ---
            rowIdx = rowIdx + 1;
            y_row  = y_bar_top - (rowIdx-1) * (bar_h + row_gap);
            for cl = 1:length(ph.clusters)
                ep = ph.clusters{cl}.endpoints;
                rectangle('Position', [ep(1)-1, y_row, ep(2)-ep(1), bar_h], ...
                          'FaceColor', col, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
            end

            % --- Barres individuelles (semi-transparentes) pour cette paire,
            % une par patient significatif, etiquetees P# ---
            if ~isempty(indivSigClusters) && isfield(indivSigClusters{idof}, fld)
                patClusters = indivSigClusters{idof}.(fld);
                for ip = 1:min(length(PATIENT_IDS), length(patClusters))
                    clusters_ip = patClusters{ip};
                    if isempty(clusters_ip), continue; end

                    rowIdx = rowIdx + 1;
                    y_row  = y_bar_top - (rowIdx-1) * (bar_h + row_gap);
                    for cl = 1:length(clusters_ip)
                        ep = clusters_ip{cl}.endpoints;
                        rectangle('Position', [ep(1)-1, y_row, ep(2)-ep(1), bar_h], ...
                                  'FaceColor', col, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                    end

                    % Etiquette P# juste a cote du premier cluster de ce
                    % patient (bascule a gauche si trop pres du bord droit
                    % ou si plusieurs clusters proches) — meme logique que
                    % plotCombinedFigureLabeled.m
                    patNum  = str2double(PATIENT_IDS{ip}(2:end));
                    epFirst = clusters_ip{1}.endpoints;
                    xStart  = epFirst(1) - 1;
                    xEnd    = epFirst(2) - 1;
                    clustersClose = false;
                    for cl2 = 2:length(clusters_ip)
                        epPrev = clusters_ip{cl2-1}.endpoints;
                        epCurr = clusters_ip{cl2}.endpoints;
                        if (epCurr(1)-1) - (epPrev(2)-1) < 8
                            clustersClose = true;
                            break;
                        end
                    end
                    if clustersClose || xEnd > 95
                        labelX = xStart - 1.5;
                        labelAlign = 'right';
                    else
                        labelX = xEnd + 1.5;
                        labelAlign = 'left';
                    end
                    text(labelX, y_row + bar_h/2, sprintf('P%d', patNum), ...
                         'FontSize', 5.5, 'HorizontalAlignment', labelAlign, ...
                         'VerticalAlignment', 'middle', 'Color', col*0.8);
                end
            end
        end
    end


    function drawLegend()
        legAx = axes('Position', [0.03 0.005 0.95 0.045], 'Visible', 'off');
        hold(legAx, 'on');

        legHandles = gobjects(1, length(CONDITIONS_ORDERED) + nSigPairs);
        for ic = 1:length(CONDITIONS_ORDERED)
            legHandles(ic) = plot(legAx, NaN, NaN, 'Color', COLORS(ic,:), 'LineWidth', 2.5, ...
                                   'DisplayName', COND_LABELS{ic});
        end
        for k = 1:nSigPairs
            col = QUAL_PALETTE(mod(k-1, size(QUAL_PALETTE,1)) + 1, :);
            legHandles(length(CONDITIONS_ORDERED)+k) = plot(legAx, NaN, NaN, 's', ...
                'MarkerFaceColor', col, 'MarkerEdgeColor', 'none', 'MarkerSize', 10, ...
                'DisplayName', sigPairLabel{k});
        end

        lgd = legend(legAx, legHandles, 'Orientation','horizontal', 'Box','off', 'FontSize', 8, 'NumColumns', min(7, length(legHandles)));
        drawnow;
        lgd.Units = 'normalized';
        lgd.Position(1) = 0.5 - lgd.Position(3)/2;
        lgd.Position(2) = 0.003;
        hold(legAx, 'off');
    end

end


function fld = pairFieldName(condA, condB)
    fld = matlab.lang.makeValidName(sprintf('%s_vs_%s', condA, condB));
end


function stack = getPatientStackKin(patientMeans, condName)
    fld = matlab.lang.makeValidName(condName);
    if ~isfield(patientMeans, fld) || isempty(patientMeans.(fld))
        stack = [];
        return;
    end
    pts = patientMeans.(fld);
    stack = cat(3, pts{:}); % (3,101,N)
end

