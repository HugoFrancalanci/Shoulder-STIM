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
