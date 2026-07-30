function plotCombinedFigureLabeledEMG(patientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS, EMG_LABELS, x, ...
                                       refCond, fesConds, spmResults, indivSigClusters, patientIDs)
% =========================================================================
% plotCombinedFigureLabeledEMG.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   July 2026
% -------------------------------------------------------------------------
% Description :  EMG counterpart of plotCombinedFigureLabeled.m (group mean +
%                individual patient curves + group/individual post-hoc
%                bars), except the individual ("intra-individual") bars are
%                labelled with the significant patient's ID (P1, P2, ...)
%                directly next to that patient's own bar, on every panel
%                (all muscles x all compared conditions) — so a reader can
%                identify which patient each bar belongs to without needing
%                the separate plotPatientIdentityFigureEMG.m. The x-axis
%                stays [0,100] on every panel (no widening), so the curves
%                are never re-scaled relative to the other figures. If a
%                patient has several close significant clusters on the same
%                row, the label is placed before the very first cluster
%                instead of after it, to avoid falling between two bars.
% -------------------------------------------------------------------------
% Parameters :   same as plotCombinedFigureEMG.m — see that file for details.
% Outputs    :   1 figure : grid length(EMG_LABELS) x length(fesConds)
% -------------------------------------------------------------------------
% Dependencies : none
% =========================================================================

nMusc = length(EMG_LABELS);
nFes  = length(fesConds);
nPat  = length(patientIDs);

refIdx = find(strcmp(CONDITIONS_ORDERED, refCond), 1);
refColor = [0.30 0.30 0.30];
if ~isempty(refIdx), refColor = COLORS(refIdx,:); end

figure('Name', sprintf('Final figure EMG (labelled) -- Each condition vs %s', refCond), ...
       'units','normalized','outerposition',[0 0 1 1], 'Color','white');

for im = 1:nMusc
    mLabel = EMG_LABELS{im};
    stackRef = getPatientStackEMG(patientMeans, refCond, mLabel);

    for fc = 1:nFes
        subplot(nMusc, nFes, (im-1)*nFes + fc); hold on;

        fld_fes = matlab.lang.makeValidName(fesConds{fc});
        condIdx = find(strcmp(CONDITIONS_ORDERED, fesConds{fc}), 1);
        condColor = [0.4 0.4 0.4];
        if ~isempty(condIdx), condColor = COLORS(condIdx,:); end
        stackFes = getPatientStackEMG(patientMeans, fesConds{fc}, mLabel);

        y_min = Inf; y_max = -Inf;

        % --- Reference : individuel + moyenne ---
        if ~isempty(stackRef)
            for ip = 1:size(stackRef, 1)
                curve = stackRef(ip,:);
                if all(isnan(curve)), continue; end
                pIndR = plot(x, curve, 'Color', refColor, 'LineWidth', 0.5, 'HandleVisibility','off');
                pIndR.Color(4) = 0.50;
                y_min = min(y_min, min(curve)); y_max = max(y_max, max(curve));
            end
            meanRef = nanmean(stackRef, 1);
            plot(x, meanRef, 'Color', refColor, 'LineWidth', 2.5, 'DisplayName', refCond);
            y_min = min(y_min, min(meanRef)); y_max = max(y_max, max(meanRef));
        end

        % --- Condition FES : individuel + moyenne ---
        if ~isempty(stackFes)
            for ip = 1:size(stackFes, 1)
                curve = stackFes(ip,:);
                if all(isnan(curve)), continue; end
                pIndF = plot(x, curve, 'Color', condColor, 'LineWidth', 0.5, 'HandleVisibility','off');
                pIndF.Color(4) = 0.50;
                y_min = min(y_min, min(curve)); y_max = max(y_max, max(curve));
            end
            meanFes = nanmean(stackFes, 1);
            plot(x, meanFes, 'Color', condColor, 'LineWidth', 2.5, ...
                 'DisplayName', condLabel(fesConds{fc}, CONDITIONS_ORDERED, COND_LABELS));
            y_min = min(y_min, min(meanFes)); y_max = max(y_max, max(meanFes));
        end

        if ~isfinite(y_min), y_min = 0; y_max = 1; end
        data_range = max(y_max - y_min, 0.01);

        % --- Barre de significativite groupe (pleine, opaque) ---
        bar_h    = data_range * 0.04;
        gap      = data_range * 0.03;
        y_bar_top = y_min - data_range * 0.06;

        if ~isempty(spmResults) && isfield(spmResults(im).posthoc, fld_fes)
            ph = spmResults(im).posthoc.(fld_fes);
            if isfield(ph, 'sig') && ph.sig
                for cl = 1:length(ph.clusters)
                    ep = ph.clusters{cl}.endpoints;
                    rectangle('Position', [ep(1)-1, y_bar_top, ep(2)-ep(1), bar_h], ...
                              'FaceColor', condColor, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
                end
            end
        end

        % --- Barres individuelles (semi-transparentes, une par patient significatif) ---
        rowH   = data_range * 0.117;
        rowGap = rowH * 0.5;
        rowIdx = 0;
        if ~isempty(indivSigClusters) && isfield(indivSigClusters{im}, fld_fes)
            patClusters = indivSigClusters{im}.(fld_fes);
            for ip = 1:min(nPat, length(patClusters))
                clusters_ip = patClusters{ip};
                if isempty(clusters_ip), continue; end
                rowIdx = rowIdx + 1;
                y_row = y_bar_top - gap - rowIdx * (rowH + rowGap);
                for cl = 1:length(clusters_ip)
                    ep = clusters_ip{cl}.endpoints;
                    rectangle('Position', [ep(1)-1, y_row, ep(2)-ep(1), rowH], ...
                              'FaceColor', condColor, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
                end

                % Etiquette P# juste a cote du premier cluster significatif de
                % ce patient (pas d'elargissement d'axe : place a droite du
                % cluster, ou a gauche si trop pres du bord droit). Si ce
                % patient a plusieurs clusters proches les uns des autres,
                % l'etiquette risque de retomber entre deux barres : dans ce
                % cas on la place avant (a gauche) le tout premier cluster.
                patNum  = str2double(patientIDs{ip}(2:end));
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
                text(labelX, y_row + rowH/2, sprintf('P%d', patNum), ...
                     'FontSize', 5.5, 'HorizontalAlignment', labelAlign, ...
                     'VerticalAlignment','middle', 'Color', condColor*0.8);
            end
        end

        y_bottom = y_bar_top - gap - (rowIdx+1) * (rowH + rowGap);
        ylim([y_bottom, y_max + data_range*0.08]);
        xlim([0 100]);

        if im == 1, title(condLabel(fesConds{fc}, CONDITIONS_ORDERED, COND_LABELS), 'FontSize', 10); end
        if fc == 1, ylabel(sprintf('%s (%% baseline)', mLabel), 'FontSize', 12); end
        if im == nMusc, xlabel('Cycle (%)', 'FontSize', 12); end
        set(gca, 'FontSize', 6);
        grid on; box on; hold off;
    end
end

sgtitle(sprintf('EMG pattern between each condition vs %s', refCond), ...
        'FontSize', 13, 'FontWeight', 'bold');

% -------------------------------------------------------------------------
% Single global legend : one colour entry per condition (reference +
% compared conditions), plus two bar shades explaining the two post-hoc
% levels (inter-individual = group, intra-individual = per patient).
% -------------------------------------------------------------------------
legAx = axes('Position', [0.06 0.005 0.90 0.045], 'Visible', 'off');
hold(legAx, 'on');

legHandles = gobjects(1, nFes + 3);
legHandles(1) = plot(legAx, NaN, NaN, 'Color', refColor, 'LineWidth', 2.5, 'DisplayName', refCond);
for fc = 1:nFes
    condIdx = find(strcmp(CONDITIONS_ORDERED, fesConds{fc}), 1);
    c = [0.4 0.4 0.4];
    if ~isempty(condIdx), c = COLORS(condIdx,:); end
    legHandles(1+fc) = plot(legAx, NaN, NaN, 'Color', c, 'LineWidth', 2.5, ...
                             'DisplayName', condLabel(fesConds{fc}, CONDITIONS_ORDERED, COND_LABELS));
end
legHandles(end-1) = plot(legAx, NaN, NaN, 's', 'MarkerFaceColor', [0.15 0.15 0.15], ...
                          'MarkerEdgeColor', 'none', 'MarkerSize', 11, ...
                          'DisplayName', 'Post-hoc inter-individual (group)');
legHandles(end) = plot(legAx, NaN, NaN, 's', 'MarkerFaceColor', [0.70 0.70 0.70], ...
                        'MarkerEdgeColor', 'none', 'MarkerSize', 11, ...
                        'DisplayName', 'Post-hoc intra-individual (per patients)');

lgd = legend(legAx, legHandles, 'Orientation','horizontal', ...
             'Box','off', 'FontSize', 9);
drawnow;
lgd.Units = 'normalized';
lgd.Position(1) = 0.5 - lgd.Position(3)/2;
lgd.Position(2) = 0.005;
hold(legAx, 'off');

end


function stack = getPatientStackEMG(patientMeans, condName, muscleLabel)
    fld = matlab.lang.makeValidName(condName);
    if ~isfield(patientMeans, fld) || ~isfield(patientMeans.(fld), muscleLabel) || isempty(patientMeans.(fld).(muscleLabel))
        stack = [];
        return;
    end
    pts = patientMeans.(fld).(muscleLabel);
    stack = cat(1, pts{:});
end


function lbl = condLabel(condRaw, CONDITIONS_ORDERED, COND_LABELS)
    % Renvoie le libelle d'affichage standardise (COND_LABELS) pour une
    % condition brute, plutot qu'un simple strrep('_',' ') qui ne
    % respecte pas les abreviations (ex. "Min PW" et non "Min pulse width").
    idx = find(strcmp(CONDITIONS_ORDERED, condRaw), 1);
    if isempty(idx)
        lbl = strrep(condRaw, '_', ' ');
    else
        lbl = COND_LABELS{idx};
    end
end
