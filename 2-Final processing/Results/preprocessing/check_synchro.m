% =========================================================================
% check_synchro.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : July 2026
% -------------------------------------------------------------------------
% Description : Quality check of the SYNCHRO channel for all participants and
%               trials: plots the signal of each trial and prints whether the
%               stimulation synchronisation was active.
% -------------------------------------------------------------------------
% Parameters  : SYNCHRO_THRESH : threshold above which the signal is active
% Outputs     : 1 figure per participant; console table (trial, condition,
%               block, status, amplitude)
% -------------------------------------------------------------------------
% Dependencies: usercommands_conditions.m, K-LAB .mat files
% =========================================================================

run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'usercommands_conditions.m'));

SYNCHRO_THRESH = 1e-3; % threshold above which the signal is considered active

for ip = 1:length(PATIENT_IDS)
    patientID = PATIENT_IDS{ip};
    pnum = str2double(patientID(2:end));
    matFile = fullfile(dataFolder, ['P' num2str(pnum) '.mat']);
    if ~isfile(matFile), fprintf('%s: file missing\n', patientID); continue; end

    load(matFile, 'Trial');

    allIdx = filterAnalytic2(Trial);

    condList = PATIENT_COND.(patientID);
    fprintf('\n=== %s ===\n', patientID);
    fprintf('  %-4s  %-14s  %-5s  %-10s  %s\n', 'seq', 'condition', 'block', 'SYNCHRO', 'max(abs)');

    % SYNCHRO plot, all trials (all participants)
    doPlot = true;
    if doPlot
        nTrials = length(allIdx);
        nCols = 3;
        nRows = ceil(nTrials / nCols);
        figure('Name', sprintf('%s -- SYNCHRO, all trials', patientID), ...
               'units', 'normalized', 'outerposition', [0 0 1 1]);
    end

    for k = 1:length(allIdx)
        t    = Trial(allIdx(k));
        cond = condList.condition{k};
        blk  = condList.block(k);
        sIdx = find(strcmp({t.Emg.label}, 'SYNCHRO'), 1);
        if isempty(sIdx)
            fprintf('  %2d    %-14s  b%d    MISSING\n', k, cond, blk);
            continue;
        end
        sig      = double(t.Emg(sIdx).Signal.full(:));
        maxAbs   = max(abs(sig));
        isActive = maxAbs > SYNCHRO_THRESH;
        isFES    = ~strcmp(cond, 'No FES');
        status = '';
        if  isFES && ~isActive, status = ' <-- FES WITHOUT SIGNAL'; end
        if ~isFES &&  isActive, status = ' <-- No FES WITH SIGNAL (?)'; end
        fprintf('  %2d    %-14s  b%d    %-5s  %.2e%s\n', k, cond, blk, ...
                mat2str(isActive), maxAbs, status);

        if doPlot
            subplot(nRows, nCols, k);
            t_sig = (0:length(sig)-1) / 2000;
            if isActive
                col = [0.85 0.33 0.10]; % orange = FES active
            else
                col = [0 0 0];          % black = inactive
            end
            plot(t_sig, sig, 'Color', col, 'LineWidth', 0.5);
            title(sprintf('seq%d %s b%d', k, cond, blk), 'FontSize', 7);
            xlabel('s', 'FontSize', 6);
            ylim([-0.015 0.015]);
            grid on; box on;
            set(gca, 'FontSize', 6);
        end
    end

    if doPlot
        sgtitle(sprintf('%s -- SYNCHRO signal per ANALYTIC2 trial', patientID), ...
                'FontSize', 11, 'FontWeight', 'bold');
    end
end
