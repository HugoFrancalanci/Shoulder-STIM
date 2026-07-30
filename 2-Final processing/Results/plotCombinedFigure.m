function plotCombinedFigure(patientMeans, CONDITIONS_ORDERED, COND_LABELS, COLORS, DOF_LABELS, x, ...
                             refCond, fesConds, spmResults, indivSigClusters, patientIDs)
% =========================================================================
% plotCombinedFigure.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   July 2026
% -------------------------------------------------------------------------
% Description :  "Figure finale" — combine group-mean and individual-patient
%                results (N=10) in a single figure : grid DOF x FES
%                condition, each panel overlays the reference condition and
%                one compared condition (mean + every patient's own curve),
%                mirroring the SPM1D post-hoc pairs. Shared function called
%                from extract_scapular_kinematics_noSEF.m and
%                extract_scapular_kinematics_rehab.m (identical layout,
%                only the reference condition / FES_CONDS differ).
%                Significance is shown at two levels, stacked below each
%                panel's curves :
%                  - group-level bar   : from spmResults(idof).posthoc,
%                    same clusters as the main SPM1D group figure.
%                  - individual bars   : one thin row per patient with a
%                    significant post-hoc cluster of their own
%                    (indivSigClusters), stacked under the group bar.
% -------------------------------------------------------------------------
% Parameters :   patientMeans        — struct, patientMeans.(cond) = cell of
%                                      (3,101) matrices, one per patient
%                CONDITIONS_ORDERED  — cell array of condition names (7)
%                COND_LABELS         — display labels (underscore -> space)
%                COLORS              — Nx3 RGB, one row per CONDITIONS_ORDERED
%                DOF_LABELS          — cell array of DOF titles (3)
%                x                   — cycle axis, 0:100
%                refCond             — reference condition name (string)
%                fesConds            — cell array of compared condition names
%                spmResults          — struct array (1x3, per DOF) from the
%                                      group SPM1D section :
%                                      spmResults(idof).posthoc.(fld).clusters/.sig
%                indivSigClusters    — cell array (1x3, per DOF) of structs :
%                                      indivSigClusters{idof}.(fld){ip} =
%                                      spm1d clusters (cell, empty if n.s.)
%                patientIDs          — cell array of patient ID strings (N=10)
% Outputs    :   1 figure : grid DOF x length(fesConds)
% -------------------------------------------------------------------------
% Dependencies : none
% =========================================================================

nDOF = length(DOF_LABELS);
nFes = length(fesConds);
nPat = length(patientIDs);

refIdx = find(strcmp(CONDITIONS_ORDERED, refCond), 1);
refColor = [0.30 0.30 0.30];
if ~isempty(refIdx), refColor = COLORS(refIdx,:); end
stackRef = getPatientStack(patientMeans, refCond);

figure('Name', sprintf('Final figure -- Each condition vs %s', refCond), ...
       'units','normalized','outerposition',[0 0 1 1], 'Color','white');

for idof = 1:nDOF
    for fc = 1:nFes
        subplot(nDOF, nFes, (idof-1)*nFes + fc); hold on;

        fld_fes = matlab.lang.makeValidName(fesConds{fc});
        condIdx = find(strcmp(CONDITIONS_ORDERED, fesConds{fc}), 1);
        condColor = [0.4 0.4 0.4];
        if ~isempty(condIdx), condColor = COLORS(condIdx,:); end
        stackFes = getPatientStack(patientMeans, fesConds{fc});

        y_min = Inf; y_max = -Inf;

        % --- Reference : individuel + moyenne ---
        hRef = gobjects(1);
        if ~isempty(stackRef)
            for ip = 1:size(stackRef, 3)
                curve = squeeze(stackRef(idof,:,ip));
                if all(isnan(curve)), continue; end
                pIndR = plot(x, curve, 'Color', refColor, 'LineWidth', 0.5, 'HandleVisibility','off');
                pIndR.Color(4) = 0.50;
                y_min = min(y_min, min(curve)); y_max = max(y_max, max(curve));
            end
            meanRef = nanmean(stackRef(idof,:,:), 3);
            hRef = plot(x, meanRef, 'Color', refColor, 'LineWidth', 2.5, 'DisplayName', refCond);
            y_min = min(y_min, min(meanRef)); y_max = max(y_max, max(meanRef));
        end

        % --- Condition FES : individuel + moyenne ---
        hFes = gobjects(1);
        if ~isempty(stackFes)
            for ip = 1:size(stackFes, 3)
                curve = squeeze(stackFes(idof,:,ip));
                if all(isnan(curve)), continue; end
                pIndF = plot(x, curve, 'Color', condColor, 'LineWidth', 0.5, 'HandleVisibility','off');
                pIndF.Color(4) = 0.50;
                y_min = min(y_min, min(curve)); y_max = max(y_max, max(curve));
            end
            meanFes = nanmean(stackFes(idof,:,:), 3);
            hFes = plot(x, meanFes, 'Color', condColor, 'LineWidth', 2.5, ...
                        'DisplayName', condLabel(fesConds{fc}, CONDITIONS_ORDERED, COND_LABELS));
            y_min = min(y_min, min(meanFes)); y_max = max(y_max, max(meanFes));
        end

        if ~isfinite(y_min), y_min = 0; y_max = 1; end
        data_range = max(y_max - y_min, 0.01);

        % --- Barre de significativite groupe (pleine, opaque) ---
        bar_h    = data_range * 0.04;
        gap      = data_range * 0.03;
        y_bar_top = y_min - data_range * 0.06;

        if ~isempty(spmResults) && isfield(spmResults(idof).posthoc, fld_fes)
            ph = spmResults(idof).posthoc.(fld_fes);
            if isfield(ph, 'sig') && ph.sig
                for cl = 1:length(ph.clusters)
                    ep = ph.clusters{cl}.endpoints;
                    rectangle('Position', [ep(1)-1, y_bar_top, ep(2)-ep(1), bar_h], ...
                              'FaceColor', condColor, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
                end
            end
        end
        % --- Barres individuelles (semi-transparentes, une par patient significatif) ---
        % Hauteur decouplee de bar_h (independante) pour rester grande meme si la barre groupe est reduite
        rowH   = data_range * 0.117;
        rowGap = gap * 0.4;
        rowIdx = 0;
        if ~isempty(indivSigClusters) && isfield(indivSigClusters{idof}, fld_fes)
            patClusters = indivSigClusters{idof}.(fld_fes);
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
            end
        end

        y_bottom = y_bar_top - gap - (rowIdx+1) * (rowH + rowGap);
        ylim([y_bottom, y_max + data_range*0.08]);
        xlim([0 100]);

        if idof == 1, title(condLabel(fesConds{fc}, CONDITIONS_ORDERED, COND_LABELS), 'FontSize', 10); end
        if fc == 1, ylabel(dofDescriptionEN(idof), 'FontSize', 12); end
        if idof == nDOF, xlabel('Cycle (%)', 'FontSize', 12); end
        set(gca, 'FontSize', 6);
        grid on; box on; hold off;
    end
end

sgtitle(sprintf('Scapular kinematics pattern between each condition vs %s', refCond), ...
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
                        'DisplayName', 'Post-hoc intra-individual (per patient)');

lgd = legend(legAx, legHandles, 'Orientation','horizontal', ...
             'Box','off', 'FontSize', 9);
drawnow;
lgd.Units = 'normalized';
lgd.Position(1) = 0.5 - lgd.Position(3)/2;  % centre horizontalement dans la figure
lgd.Position(2) = 0.005;
hold(legAx, 'off');

end


function lbl = dofDescriptionEN(idof)
    labels = {'Lateral (-) / medial (+) rotation (deg)', ...
              'Protraction (+) / retraction (-) (deg)', ...
              'Posterior (+) / anterior (-) tilt (deg)'};
    lbl = labels{idof};
end


function stack = getPatientStack(patientMeans, condName)
    fld = matlab.lang.makeValidName(condName);
    if ~isfield(patientMeans, fld) || isempty(patientMeans.(fld))
        stack = [];
        return;
    end
    pts = patientMeans.(fld);
    stack = cat(3, pts{:});
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
