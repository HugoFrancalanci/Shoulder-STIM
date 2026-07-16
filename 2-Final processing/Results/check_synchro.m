% =========================================================================
% check_synchro.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
%                https://www.unige.ch/medecine/chiru/en/research-groups/nicolas-holzer-et-florent-moissenet
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   July 2026
% -------------------------------------------------------------------------
% Description:   Utility script for quality control of the SYNCHRO channel
%                across all patients and ANALYTIC2 trials. For each patient,
%                plots all SYNCHRO signals (1 subplot per trial) and prints
%                a console table reporting condition, block, activity status,
%                and peak amplitude. Used to identify trials where FES
%                synchronisation was inactive (signal flat).
% -------------------------------------------------------------------------
% Parameters :   SYNCHRO_THRESH (default 1e-3) — threshold above which the
%                SYNCHRO signal is considered active
% Outputs    :   1 figure per patient : N_trials subplots of SYNCHRO signal
%                Console table : seq | condition | block | status | max(abs)
% -------------------------------------------------------------------------
% Dependencies : usercommands_conditions.m, K-LAB .mat files (P[n].mat)
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution -
% NonCommercial 4.0 International License. To view a copy of this license,
% visit http://creativecommons.org/licenses/by-nc/4.0/
% =========================================================================

run(fullfile(fileparts(mfilename('fullpath')), 'usercommands_conditions.m'));

SYNCHRO_THRESH = 1e-3; % seuil pour considerer le signal comme actif

for ip = 1:length(PATIENT_IDS)
    patientID = PATIENT_IDS{ip};
    pnum = str2double(patientID(2:end));
    matFile = fullfile(dataFolder, ['P' num2str(pnum) '.mat']);
    if ~isfile(matFile), fprintf('%s : fichier manquant\n', patientID); continue; end

    load(matFile, 'Trial');

    isA2 = false(1, length(Trial));
    for i = 1:length(Trial)
        if isfield(Trial(i), 'task') && strcmp(Trial(i).task, 'ANALYTIC2')
            isA2(i) = true;
        end
    end
    allIdx = find(isA2);
    exc = []; skipFirst = 0; skipPos = [];
    if isfield(PATIENT_EXCEPTIONS, patientID)
        exc = PATIENT_EXCEPTIONS.(patientID);
        if isfield(exc, 'skipFirstN'),    skipFirst = exc.skipFirstN;    end
        if isfield(exc, 'skipPositions'), skipPos   = exc.skipPositions; end
    end
    allIdx = allIdx(skipFirst+1:end);
    if ~isempty(skipPos)
        keep = true(1, length(allIdx));
        keep(skipPos(skipPos <= length(allIdx))) = false;
        allIdx = allIdx(keep);
    end

    condList = PATIENT_COND.(patientID);
    fprintf('\n=== %s ===\n', patientID);
    fprintf('  %-4s  %-14s  %-5s  %-10s  %s\n', 'seq', 'condition', 'block', 'SYNCHRO', 'max(abs)');

    % Plot SYNCHRO tous trials (tous patients)
    doPlot = true;
    if doPlot
        nTrials = length(allIdx);
        nCols = 3;
        nRows = ceil(nTrials / nCols);
        figure('Name', sprintf('%s -- SYNCHRO tous trials', patientID), ...
               'units', 'normalized', 'outerposition', [0 0 1 1]);
    end

    for k = 1:length(allIdx)
        t    = Trial(allIdx(k));
        cond = condList.condition{k};
        blk  = condList.block(k);
        sIdx = find(strcmp({t.Emg.label}, 'SYNCHRO'), 1);
        if isempty(sIdx)
            fprintf('  %2d    %-14s  b%d    ABSENT\n', k, cond, blk);
            continue;
        end
        sig      = double(t.Emg(sIdx).Signal.full(:));
        maxAbs   = max(abs(sig));
        isActive = maxAbs > SYNCHRO_THRESH;
        isFES    = ~strcmp(cond, 'No FES');
        status = '';
        if  isFES && ~isActive, status = ' <-- FES SANS SIGNAL'; end
        if ~isFES &&  isActive, status = ' <-- No FES AVEC SIGNAL (?)'; end
        fprintf('  %2d    %-14s  b%d    %-5s  %.2e%s\n', k, cond, blk, ...
                mat2str(isActive), maxAbs, status);

        if doPlot
            subplot(nRows, nCols, k);
            t_sig = (0:length(sig)-1) / 2000;
            if isActive
                col = [0.85 0.33 0.10]; % orange = FES actif
            else
                col = [0 0 0];          % noir = inactif
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
        sgtitle(sprintf('%s -- Signal SYNCHRO par trial ANALYTIC2', patientID), ...
                'FontSize', 11, 'FontWeight', 'bold');
    end
end
