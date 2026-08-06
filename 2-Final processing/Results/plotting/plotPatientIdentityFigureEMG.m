function plotPatientIdentityFigureEMG(patientMeans, CONDITIONS_ORDERED, COND_LABELS, EMG_LABELS, x, ...
                                       refCond, fesConds, indivSigClusters, patientIDs)
% =========================================================================
% plotPatientIdentityFigureEMG.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   July 2026
% -------------------------------------------------------------------------
% Description :  EMG counterpart of plotPatientIdentityFigure.m, focused on
%                identifying INDIVIDUAL patients (P1-P10) rather than the
%                group. Same grid layout (muscle x FES condition vs
%                reference), but every patient gets a fixed, distinct color
%                used consistently across all panels (solid line = compared
%                condition, dashed line = reference), so a given patient's
%                curve can be traced panel to panel. No group mean is drawn
%                here — that is the purpose of plotCombinedFigureEMG.m.
%                Significance : intra-individual only (per-patient post-hoc
%                clusters, indivSigClusters), one fixed row per patient
%                (same vertical position across all panels), colored in
%                that patient's own color so bar and curve match.
% -------------------------------------------------------------------------
% Parameters :   patientMeans        — struct, patientMeans.(cond).(muscle) =
%                                      cell of (1,101) vectors, one per patient
%                CONDITIONS_ORDERED  — cell array of condition names (7)
%                COND_LABELS         — display labels (standardized abbreviations,
%                                      e.g. "Min PW" for "Min_pulse_width")
%                EMG_LABELS          — cell array of muscle names (4)
%                x                   — cycle axis, 0:100
%                refCond             — reference condition name (string)
%                fesConds            — cell array of compared condition names
%                indivSigClusters    — cell array (1x4, per muscle) of structs :
%                                      indivSigClusters{im}.(fld){ip} =
%                                      spm1d clusters (cell, empty if n.s.)
%                patientIDs          — cell array of patient ID strings (N=10)
% Outputs    :   1 figure : grid length(EMG_LABELS) x length(fesConds)
% -------------------------------------------------------------------------
% Dependencies : none
% =========================================================================

nMusc = length(EMG_LABELS);
nFes  = length(fesConds);
nPat  = length(patientIDs);

% Palette qualitative a 10 couleurs (Tableau10), fixe par patient (P1..P10)
PATIENT_COLORS = [ ...
    0.306 0.475 0.655;  % P1 - blue
    0.949 0.557 0.169;  % P2 - orange
    0.882 0.341 0.349;  % P3 - red
    0.463 0.718 0.698;  % P4 - teal
    0.349 0.631 0.310;  % P5 - green
    0.929 0.788 0.282;  % P6 - yellow
    0.690 0.478 0.631;  % P7 - purple
    1.000 0.616 0.655;  % P8 - pink
    0.612 0.459 0.373;  % P9 - brown
    0.729 0.690 0.675]; % P10 - grey

patientShort = cell(nPat, 1);
for ip = 1:nPat
    patientShort{ip} = sprintf('P%d', str2double(patientIDs{ip}(2:end)));
end

figure('Name', sprintf('Individual patients EMG -- Each condition vs %s', refCond), ...
       'units','normalized','outerposition',[0 0 1 1], 'Color','white');

for im = 1:nMusc
    mLabel = EMG_LABELS{im};
    stackRef = getPatientStackEMG(patientMeans, refCond, mLabel);

    for fc = 1:nFes
        subplot(nMusc, nFes, (im-1)*nFes + fc); hold on;

        fld_fes = matlab.lang.makeValidName(fesConds{fc});
        stackFes = getPatientStackEMG(patientMeans, fesConds{fc}, mLabel);

        y_min = Inf; y_max = -Inf;

        for ip = 1:nPat
            col = PATIENT_COLORS(min(ip, size(PATIENT_COLORS,1)), :);

            if ~isempty(stackRef) && ip <= size(stackRef, 1)
                curveR = stackRef(ip,:);
                if ~all(isnan(curveR))
                    plot(x, curveR, 'Color', col, 'LineStyle', '--', 'LineWidth', 1.1, ...
                         'HandleVisibility','off');
                    y_min = min(y_min, min(curveR)); y_max = max(y_max, max(curveR));
                end
            end

            if ~isempty(stackFes) && ip <= size(stackFes, 1)
                curveF = stackFes(ip,:);
                if ~all(isnan(curveF))
                    plot(x, curveF, 'Color', col, 'LineStyle', '-', 'LineWidth', 1.3, ...
                         'HandleVisibility','off');
                    y_min = min(y_min, min(curveF)); y_max = max(y_max, max(curveF));
                end
            end
        end

        if ~isfinite(y_min), y_min = 0; y_max = 1; end
        data_range = max(y_max - y_min, 0.01);

        % --- Barres intra-individuelles (transparentes) : une rangee fixe par patient ---
        bar_zone = data_range * 1.05;
        rowH     = bar_zone / (nPat * 1.05);
        rowGap   = rowH * 0.15;
        y_bar_top = y_min - data_range * 0.06;

        if ~isempty(indivSigClusters) && isfield(indivSigClusters{im}, fld_fes)
            patClusters = indivSigClusters{im}.(fld_fes);
            for ip = 1:min(nPat, length(patClusters))
                clusters_ip = patClusters{ip};
                if isempty(clusters_ip), continue; end
                col = PATIENT_COLORS(min(ip, size(PATIENT_COLORS,1)), :);
                y_row = y_bar_top - (ip-1) * (rowH + rowGap);
                for cl = 1:length(clusters_ip)
                    ep = clusters_ip{cl}.endpoints;
                    rectangle('Position', [ep(1)-1, y_row, ep(2)-ep(1), rowH], ...
                              'FaceColor', col, 'EdgeColor', 'none', 'FaceAlpha', 0.85);
                end
            end
        end

        y_bottom = y_bar_top - nPat * (rowH + rowGap) - data_range*0.02;
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
% Legende unique centree : couleur = patient, trait plein = condition,
% trait pointille = reference.
% -------------------------------------------------------------------------
legAx = axes('Position', [0.06 0.005 0.90 0.045], 'Visible', 'off');
hold(legAx, 'on');

legHandles = gobjects(1, nPat + 2);
for ip = 1:nPat
    legHandles(ip) = plot(legAx, NaN, NaN, 'Color', PATIENT_COLORS(ip,:), 'LineWidth', 2.5, ...
                           'DisplayName', patientShort{ip});
end
legHandles(end-1) = plot(legAx, NaN, NaN, 'Color', [0.2 0.2 0.2], 'LineStyle', '-', ...
                          'LineWidth', 2, 'DisplayName', 'Condition (solid)');
legHandles(end) = plot(legAx, NaN, NaN, 'Color', [0.2 0.2 0.2], 'LineStyle', '--', ...
                        'LineWidth', 2, 'DisplayName', sprintf('%s (dashed)', refCond));

lgd = legend(legAx, legHandles, 'Orientation','horizontal', 'Box','off', 'FontSize', 9, 'NumColumns', nPat+2);
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
