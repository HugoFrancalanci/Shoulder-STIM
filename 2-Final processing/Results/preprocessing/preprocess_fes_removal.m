% =========================================================================
% preprocess_fes_removal.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : July 2026
% -------------------------------------------------------------------------
% Description : Visual check of the stimulation-artefact removal for one
%               participant and all FES conditions: No FES, raw and cleaned
%               signals over a few movement cycles, and a 300 ms zoom.
% -------------------------------------------------------------------------
% Parameters  : PATIENT_ID, VERIFY_BLOCK, N_CYCLES_DISPLAY
%               BLANK_MS = 8, MAD_FACTOR = 6, MIN_PERIOD_MS = 15, MAX_BLANK_MS = 20
%               ZOOM_V_START, ZOOM_V_DUR
% Outputs     : 2 figures per FES condition
% -------------------------------------------------------------------------
% Dependencies: usercommands_conditions.m, K-LAB .mat files
% =========================================================================

clear; clc; close all;
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'usercommands_conditions.m'));

% -------------------------------------------------------------------------
% PARAMETRES
% -------------------------------------------------------------------------
PATIENT_ID     = 'P001';
FS             = 2200;          % Hz (checked with check_fs.m)
FS_KIN         = 100;           % Hz: camera frequency (for Rcycle/Lcycle.range)

N_CYCLES_DISPLAY = 3;           % number of concatenated cycles for the figure
                                % "full signal" (instead of the whole trial),
                                % to align No FES and FES on a
                                % comparable duration and ease the comparison

BLANK_MS       = 8;             % ms to erase around each peak
MAD_FACTOR     = 6;             % threshold = MAD_FACTOR x MAD(signal)
MIN_PERIOD_MS  = 15;            % minimum spacing between two peaks (ms)
                                % (< FES period ~22 ms, to keep all the peaks)
MAX_BLANK_MS   = 20;            % if gap > MAX_BLANK_MS -> no interpolation

% FES trial to check and No FES reference trial
VERIFY_COND    = 'Rehab';
VERIFY_BLOCK   = 1;
NOFES_COND     = 'No FES';
NOFES_BLOCK    = 1;

% -------------------------------------------------------------------------
% CHARGEMENT
% -------------------------------------------------------------------------
pnum    = str2double(PATIENT_ID(2:end));
% matFile = fullfile(dataFolder, ['P' num2str(pnum) '.mat']);
matFile = fullfile(dataFolder, 'P1.mat');
load(matFile, 'Trial');

allIdx = filterAnalytic2(Trial);

condList = PATIENT_COND.(PATIENT_ID);

side     = DOMINANT_SIDE(PATIENT_ID);
cycleKey = 'Rcycle';
if strcmp(side, 'L'), cycleKey = 'Lcycle'; end

% -------------------------------------------------------------------------
% FONCTIONS LOCALES
% -------------------------------------------------------------------------

function [segCat, boundaries] = extractCycleConcat(sig, cyclesKin, fsEmg, fsKin, nWanted)
    % Concatenates the first N cycles (raw, full time resolution)
    % of a signal, from the Rcycle/Lcycle.range indices (camera frames).
    % boundaries: indices (in segCat) marking the end of each cycle.
    sig = sig(:);
    N   = length(sig);
    segCat = [];
    boundaries = [];
    if isempty(cyclesKin)
        warning('extractCycleConcat: empty cyclesKin (wrong side or Rcycle-Lcycle field?) -> falling back on the full signal.');
        segCat = sig;
        return;
    end
    nUse = min(nWanted, length(cyclesKin));
    for kc = 1:nUse
        rng = cyclesKin(kc).range;
        if isempty(rng) || length(rng) < 2, continue; end
        i1 = max(1, round(rng(1)   * fsEmg / fsKin));
        i2 = min(N, round(rng(end) * fsEmg / fsKin));
        if i2 - i1 < 10, continue; end
        segCat = [segCat; sig(i1:i2)]; %#ok<AGROW>
        boundaries(end+1) = length(segCat); %#ok<AGROW>
    end
    if isempty(segCat)
        warning('extractCycleConcat: no valid cycle found (wrong side or Rcycle-Lcycle field?) -> falling back on the full signal.');
        segCat = sig;   % fallback: no valid cycles -> full signal
    end
end

function cleaned = removeFESArtifact(sig, fs, blank_ms, mad_factor, min_period_ms, max_blank_ms)
    % Returns the signal with the FES artefacts removed by blanking + spline.
    sig = sig(:);
    n   = length(sig);
    blank_s  = round(blank_ms / 1000 * fs);
    min_dist = round(min_period_ms / 1000 * fs);
    max_blank_s = round(max_blank_ms / 1000 * fs);

    % Adaptive threshold on the absolute value
    mad_val  = median(abs(sig - median(sig)));
    thresh   = mad_factor * mad_val;

    % Detection of positive AND negative peaks (biphasic spike)
    [~, locs_pos] = findpeaks( sig, 'MinPeakHeight', thresh, 'MinPeakDistance', min_dist);
    [~, locs_neg] = findpeaks(-sig, 'MinPeakHeight', thresh, 'MinPeakDistance', min_dist);
    locs = sort([locs_pos; locs_neg]);

    % Merges peaks that are too close (same biphasic spike)
    if length(locs) > 1
        merged = locs(1);
        for k = 2:length(locs)
            if locs(k) - merged(end) < min_dist
                merged(end) = round((merged(end) + locs(k)) / 2);
            else
                merged(end+1) = locs(k); %#ok<AGROW>
            end
        end
        locs = merged(:);
    end

    % Blanking: NaN around each peak
    mask = true(n, 1);
    half = floor(blank_s / 2);
    for k = 1:length(locs)
        i1 = max(1,   locs(k) - half);
        i2 = min(n,   locs(k) + half);
        mask(i1:i2) = false;
    end

    % Cubic interpolation on the gaps <= max_blank_s
    cleaned = sig;
    valid_idx = find(mask);
    if length(valid_idx) < 4, cleaned = sig; return; end

    % Finds the NaN segments
    invalid_idx = find(~mask);
    if isempty(invalid_idx), return; end

    % Groups the invalid indices into continuous segments
    breaks = [0; find(diff(invalid_idx) > 1); length(invalid_idx)];
    for b = 1:length(breaks)-1
        seg = invalid_idx(breaks(b)+1 : breaks(b+1));
        if length(seg) > max_blank_s, continue; end  % gap too wide -> no interpolation
        i1 = seg(1); i2 = seg(end);
        % Anchor points: 3 valid points on each side
        left  = valid_idx(valid_idx < i1);
        right = valid_idx(valid_idx > i2);
        if length(left) < 2 || length(right) < 2, continue; end
        left  = left(max(1,end-2):end);
        right = right(1:min(end,3));
        xi = [left; right];
        yi = sig(xi);
        xq = (i1:i2)';
        cleaned(xq) = interp1(xi, yi, xq, 'pchip');
    end
end

% -------------------------------------------------------------------------
% LOADING No FES (common reference)
% -------------------------------------------------------------------------
seqN = find(strcmp(condList.condition, NOFES_COND) & condList.block == NOFES_BLOCK, 1);
if isempty(seqN)
    warning('Condition %s b%d not found for %s - reference curve left out.', NOFES_COND, NOFES_BLOCK, PATIENT_ID);
    tN = [];
else
    tN = Trial(allIdx(seqN));
end
nofes_labels = {};
cyclesN = [];
if ~isempty(tN)
    nofes_labels = {tN.Emg.label};
    if isfield(tN, cycleKey), cyclesN = tN.(cycleKey); end
end

% -------------------------------------------------------------------------
% LOOP ON ALL THE FES CONDITIONS
% -------------------------------------------------------------------------
ALL_FES_CONDS = {'Min_fatigue','Min_stress','Random','Min_pulse_width','Rehab','Min_force'};
ZOOM_V_START  = 7.0;
ZOOM_V_DUR    = 0.3;

for ifc = 1:length(ALL_FES_CONDS)
    cur_cond = ALL_FES_CONDS{ifc};

    seqV = find(strcmp(condList.condition, cur_cond) & condList.block == VERIFY_BLOCK, 1);
    if isempty(seqV)
        fprintf('  [SKIP] %s b%d not found\n', cur_cond, VERIFY_BLOCK);
        continue;
    end
    tV     = Trial(allIdx(seqV));
    emgIdx = find(~strcmp({tV.Emg.label}, 'SYNCHRO'));
    nEmg   = length(emgIdx);
    cyclesV = [];
    if isfield(tV, cycleKey), cyclesV = tV.(cycleKey); end

    % --- Full signal figure (N_CYCLES_DISPLAY concatenated cycles) ---
    figure('Name', sprintf('%s -- FES artefact removal: %s b%d', PATIENT_ID, cur_cond, VERIFY_BLOCK), ...
           'units','normalized','outerposition',[0 0 1 1]);

    for ji = 1:nEmg
        j    = emgIdx(ji);
        lbl  = tV.Emg(j).label;
        sig_full     = double(tV.Emg(j).Signal.full(:));
        cleaned_full = removeFESArtifact(sig_full, FS, BLANK_MS, MAD_FACTOR, MIN_PERIOD_MS, MAX_BLANK_MS);

        [sig,     ~     ] = extractCycleConcat(sig_full,     cyclesV, FS, FS_KIN, N_CYCLES_DISPLAY);
        [cleaned, cycBnd] = extractCycleConcat(cleaned_full, cyclesV, FS, FS_KIN, N_CYCLES_DISPLAY);
        t_s = (0:length(sig)-1) / FS;

        subplot(nEmg, 1, ji); hold on;

        ref_vals = cleaned;
        if ~isempty(tN)
            jN = find(strcmp(nofes_labels, lbl), 1);
            if ~isempty(jN)
                sig_n_full = double(tN.Emg(jN).Signal.full(:));
                sig_n = extractCycleConcat(sig_n_full, cyclesN, FS, FS_KIN, N_CYCLES_DISPLAY);
                t_n   = (0:length(sig_n)-1) / FS;
                plot(t_n, sig_n, 'Color', [0.10 0.10 0.10], 'LineWidth', 0.6);
                ref_vals = [ref_vals; sig_n];
            end
        end

        plot(t_s, sig,     'Color', [0.88 0.88 0.88], 'LineWidth', 0.4);
        plot(t_s, cleaned, 'Color', [0.10 0.45 0.75], 'LineWidth', 0.9);

        y_lim = max(abs(ref_vals)) * 1.4;
        if y_lim > 0, ylim([-y_lim, y_lim]); end

        % Cycle separators (grey dotted lines)
        for cb = cycBnd(1:end-1)
            xline(cb/FS, 'Color', [0.6 0.6 0.6], 'LineStyle', ':', 'LineWidth', 0.6, 'HandleVisibility','off');
        end

        title(lbl, 'FontSize', 9); ylabel('V'); grid on;
        if ji == 1
            if ~isempty(tN)
                legend({'No FES', 'Raw (FES)', 'Cleaned (FES)'}, 'Location','northeast');
            else
                legend({'Raw', 'Cleaned'}, 'Location','northeast');
            end
        end
        if ji == nEmg, xlabel(sprintf('Time (s) - %d concatenated cycles', N_CYCLES_DISPLAY)); end
    end

    sgtitle(sprintf('%s  --  %s b%d  --  %d concatenated cycles  (black = No FES, grey = raw, blue = cleaned)', ...
            PATIENT_ID, cur_cond, VERIFY_BLOCK, N_CYCLES_DISPLAY), 'FontSize', 11, 'FontWeight', 'bold');

    % --- 300 ms zoom figure ---
    figure('Name', sprintf('%s -- Zoom : %s b%d', PATIENT_ID, cur_cond, VERIFY_BLOCK), ...
           'units','normalized','outerposition',[0 0 1 1]);

    z1v  = max(1, round(ZOOM_V_START * FS));
    t_zv = (0:round(ZOOM_V_DUR*FS)) / FS * 1000;

    for ji = 1:nEmg
        j    = emgIdx(ji);
        lbl  = tV.Emg(j).label;
        sig  = double(tV.Emg(j).Signal.full(:));
        cleaned = removeFESArtifact(sig, FS, BLANK_MS, MAD_FACTOR, MIN_PERIOD_MS, MAX_BLANK_MS);
        nS   = min(length(sig)-z1v+1, length(t_zv));

        subplot(nEmg, 1, ji); hold on;

        if ~isempty(tN)
            jN = find(strcmp(nofes_labels, lbl), 1);
            if ~isempty(jN)
                sig_n = double(tN.Emg(jN).Signal.full(:));
                if length(sig_n) >= z1v
                    nS_n = min(length(sig_n)-z1v+1, length(t_zv));
                    plot(t_zv(1:nS_n), sig_n(z1v:z1v+nS_n-1), 'Color', [0.10 0.10 0.10], 'LineWidth', 0.9);
                end
            end
        end

        plot(t_zv(1:nS), sig(z1v:z1v+nS-1),     'Color', [0.80 0.80 0.80], 'LineWidth', 1.0);
        plot(t_zv(1:nS), cleaned(z1v:z1v+nS-1), 'Color', [0.10 0.45 0.75], 'LineWidth', 1.4);

        title(lbl, 'FontSize', 9); ylabel('V'); grid on;
        if ji == 1
            if ~isempty(tN)
                legend({'No FES', 'Raw (FES)', 'Cleaned (FES)'}, 'Location','northeast');
            else
                legend({'Raw', 'Cleaned'}, 'Location','northeast');
            end
        end
        if ji == nEmg, xlabel('Time (ms)'); end
    end

    sgtitle(sprintf('%s  --  Zoom 300ms  --  %s b%d', PATIENT_ID, cur_cond, VERIFY_BLOCK), ...
            'FontSize', 11, 'FontWeight', 'bold');

end % ifc

fprintf('\n--- Parameters used ---\n');
fprintf('  Blanking     : %d ms (%d samples)\n', BLANK_MS, round(BLANK_MS/1000*FS));
fprintf('  Threshold    : %.0f x MAD\n', MAD_FACTOR);
fprintf('  Min. spacing : %d ms between peaks\n', MIN_PERIOD_MS);
fprintf('  Max. gap     : %d ms (above = no interpolation)\n', MAX_BLANK_MS);
fprintf('\nIf too much signal is erased: lower MAD_FACTOR or raise MIN_PERIOD_MS.\n');
fprintf('If spikes remain        : lower MAD_FACTOR or raise BLANK_MS.\n');
