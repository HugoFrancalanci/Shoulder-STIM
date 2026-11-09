% =========================================================================
% compare_fes_nofes.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : July 2026
% -------------------------------------------------------------------------
% Description : Visual characterisation of the stimulation artefact in the raw
%               EMG: overlays No FES and one FES condition for one participant
%               (full signal, zooms and single pulse). Used to set the
%               artefact-removal parameters.
% -------------------------------------------------------------------------
% Parameters  : PATIENT_ID, FES_COND, BLOCK, FS
%               ZOOM1_START / ZOOM1_DUR, ZOOM2_START / ZOOM2_DUR : zoom windows
% Outputs     : 5 figures
% -------------------------------------------------------------------------
% Dependencies: usercommands_conditions.m, K-LAB .mat files
% =========================================================================

clear; clc; close all;
run(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'usercommands_conditions.m'));

% -------------------------------------------------------------------------
% CONFIGURATION: adjust to the participant and the condition to inspect
% -------------------------------------------------------------------------
PATIENT_ID = 'P001';
FES_COND   = 'Rehab';   % FES condition to compare
BLOCK      = 1;
FS         = 2200;

% Zoom windows (seconds): adjust to target a movement burst
% Fig 2: wide view of the burst
ZOOM1_START = 6.0;
ZOOM1_DUR   = 5.0;

% Fig 3: fine zoom to see the individual pulses (~200 ms)
ZOOM2_START = 7.0;
ZOOM2_DUR   = 5.0;

% -------------------------------------------------------------------------
% CHARGEMENT
% -------------------------------------------------------------------------
pnum    = str2double(PATIENT_ID(2:end));
matFile = fullfile(dataFolder, ['P' num2str(pnum) '.mat']);
load(matFile, 'Trial');

allIdx = filterAnalytic2(Trial);

condList  = PATIENT_COND.(PATIENT_ID);
noFesSeq  = find(strcmp(condList.condition, 'No FES') & condList.block == BLOCK, 1);
fesSeq    = find(strcmp(condList.condition, FES_COND)  & condList.block == BLOCK, 1);
tNoFES    = Trial(allIdx(noFesSeq));
tFES      = Trial(allIdx(fesSeq));

fprintf('No FES : seq %d\n', noFesSeq);
fprintf('FES    : seq %d  (%s b%d)\n', fesSeq, FES_COND, BLOCK);

% EMG channels except SYNCHRO
emgIdx = find(~strcmp({tFES.Emg.label}, 'SYNCHRO'));
nEmg   = length(emgIdx);

% Colours
COL_NOFES = [0.00 0.00 0.00];   % black = No FES
COL_FES   = [0.85 0.20 0.10];   % red   = FES

% =========================================================================
% FIGURE 1: full signal, No FES (black) vs FES (red)
% =========================================================================
figure('Name', sprintf('%s -- Full signal No FES vs %s', PATIENT_ID, FES_COND), ...
       'units','normalized','outerposition',[0 0 1 1]);

for ji = 1:nEmg
    j   = emgIdx(ji);
    lbl = tFES.Emg(j).label;
    s0  = double(tNoFES.Emg(j).Signal.full(:));
    s1  = double(tFES.Emg(j).Signal.full(:));
    t0  = (0:length(s0)-1)/FS;
    t1  = (0:length(s1)-1)/FS;

    subplot(nEmg, 1, ji);
    plot(t0, s0, 'Color', COL_NOFES, 'LineWidth', 0.5); hold on;
    plot(t1, s1, 'Color', COL_FES,   'LineWidth', 0.5);
    title(lbl, 'FontSize', 9); ylabel('V'); grid on;
    if ji == 1
        legend({'No FES', sprintf('FES (%s b%d)', FES_COND, BLOCK)}, ...
               'Location','northeast');
    end
    if ji == nEmg, xlabel('Time (s)'); end
end
sgtitle(sprintf('%s  --  Full signal  --  No FES vs %s b%d', ...
        PATIENT_ID, FES_COND, BLOCK), 'FontSize', 12, 'FontWeight', 'bold');

% =========================================================================
% FIGURE 2: zoom on the movement burst (ZOOM1)
% =========================================================================
figure('Name', sprintf('%s -- Zoom burst %.1f-%.1fs', PATIENT_ID, ZOOM1_START, ZOOM1_START+ZOOM1_DUR), ...
       'units','normalized','outerposition',[0 0 1 1]);

z1a = max(1, round(ZOOM1_START*FS));
z2a = min(round((ZOOM1_START+ZOOM1_DUR)*FS), round(min(length(double(tNoFES.Emg(emgIdx(1)).Signal.full(:))), ...
                                                        length(double(tFES.Emg(emgIdx(1)).Signal.full(:))))));
t_za = (0:z2a-z1a)/FS;

for ji = 1:nEmg
    j   = emgIdx(ji);
    lbl = tFES.Emg(j).label;
    s0  = double(tNoFES.Emg(j).Signal.full(:));
    s1  = double(tFES.Emg(j).Signal.full(:));

    subplot(nEmg, 1, ji);
    plot(t_za, s0(z1a:z1a+length(t_za)-1), 'Color', COL_NOFES, 'LineWidth', 0.7); hold on;
    plot(t_za, s1(z1a:z1a+length(t_za)-1), 'Color', COL_FES,   'LineWidth', 0.7);
    title(lbl, 'FontSize', 9); ylabel('V'); grid on;
    if ji == 1
        legend({'No FES', sprintf('FES (%s b%d)', FES_COND, BLOCK)}, 'Location','northeast');
    end
    if ji == nEmg, xlabel(sprintf('Relative time (s)  [original signal at %.1fs]', ZOOM1_START)); end
end
sgtitle(sprintf('%s  --  Zoom %.1f-%.1fs  --  No FES vs %s b%d', ...
        PATIENT_ID, ZOOM1_START, ZOOM1_START+ZOOM1_DUR, FES_COND, BLOCK), ...
        'FontSize', 12, 'FontWeight', 'bold');

% =========================================================================
% FIGURE 3: fine zoom (~200 ms) to see the individual pulses
% =========================================================================
figure('Name', sprintf('%s -- Fine zoom %.1f-%.1fs', PATIENT_ID, ZOOM2_START, ZOOM2_START+ZOOM2_DUR), ...
       'units','normalized','outerposition',[0 0 1 1]);

z1b = max(1, round(ZOOM2_START*FS));
z2b = min(round((ZOOM2_START+ZOOM2_DUR)*FS), round(min(length(double(tNoFES.Emg(emgIdx(1)).Signal.full(:))), ...
                                                        length(double(tFES.Emg(emgIdx(1)).Signal.full(:))))));
t_zb = (0:z2b-z1b)/FS * 1000; % en ms

for ji = 1:nEmg
    j   = emgIdx(ji);
    lbl = tFES.Emg(j).label;
    s0  = double(tNoFES.Emg(j).Signal.full(:));
    s1  = double(tFES.Emg(j).Signal.full(:));

    subplot(nEmg, 1, ji);
    plot(t_zb, s0(z1b:z1b+length(t_zb)-1), 'Color', COL_NOFES, 'LineWidth', 1.0); hold on;
    plot(t_zb, s1(z1b:z1b+length(t_zb)-1), 'Color', COL_FES,   'LineWidth', 1.0);
    title(lbl, 'FontSize', 9); ylabel('V'); grid on;
    if ji == 1
        legend({'No FES', sprintf('FES (%s b%d)', FES_COND, BLOCK)}, 'Location','northeast');
    end
    if ji == nEmg, xlabel('Time (ms)'); end
end
sgtitle(sprintf('%s  --  Fine zoom %.0fms  --  No FES vs %s b%d  (look for periodic red spikes)', ...
        PATIENT_ID, ZOOM2_DUR*1000, FES_COND, BLOCK), ...
        'FontSize', 12, 'FontWeight', 'bold');

fprintf('\nAdjust ZOOM1_START and ZOOM2_START to target the movement burst.\n');
fprintf('Fig 3: if periodic red spikes are visible -> FES artefact detectable.\n');
fprintf('        if the signals are identical -> no artefact on this channel.\n');

% =========================================================================
% FIGURE 4: fine 300 ms zoom for ALL the FES conditions (TRAPS channel)
%            Aim: check whether the artefact frequency is constant
% =========================================================================
ALL_FES_COND = {'Min_fatigue','Min_stress','Random','Min_pulse_width','Rehab','Min_force'};

% Reference channel: TRAPS (the most contaminated)
refLabel = 'TRAPS';
noFesChIdx = find(strcmp({tNoFES.Emg.label}, refLabel), 1);
if isempty(noFesChIdx)
    % fallback: first non-SYNCHRO channel
    noFesChIdx = emgIdx(1);
    refLabel = tNoFES.Emg(noFesChIdx).label;
end
s_nofes_ref = double(tNoFES.Emg(noFesChIdx).Signal.full(:));

nCond = length(ALL_FES_COND);
cols_cond = lines(nCond);  % distinct colours per condition

figure('Name', sprintf('%s -- Fine zoom, all FES conditions -- %s', PATIENT_ID, refLabel), ...
       'units','normalized','outerposition',[0 0 1 1]);

z1c = max(1, round(ZOOM2_START*FS));
t_zc = (0:round(ZOOM2_DUR*FS))/FS * 1000;  % en ms

for ci = 1:nCond
    cond = ALL_FES_COND{ci};
    seq  = find(strcmp(condList.condition, cond) & condList.block == BLOCK, 1);

    subplot(nCond, 1, ci);

    % No FES reference (grey)
    nSamples = min(length(s_nofes_ref) - z1c + 1, length(t_zc));
    plot(t_zc(1:nSamples), s_nofes_ref(z1c:z1c+nSamples-1), ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 0.8); hold on;

    if isempty(seq)
        title(sprintf('%s b%d  [MISSING]', cond, BLOCK), 'FontSize', 8, 'Color', [0.5 0.5 0.5]);
    else
        tFES_ci   = Trial(allIdx(seq));
        chIdx_ci  = find(strcmp({tFES_ci.Emg.label}, refLabel), 1);
        if isempty(chIdx_ci)
            title(sprintf('%s b%d  [channel missing]', cond, BLOCK), 'FontSize', 8);
        else
            s_fes_ci = double(tFES_ci.Emg(chIdx_ci).Signal.full(:));
            nS2 = min(length(s_fes_ci) - z1c + 1, length(t_zc));
            plot(t_zc(1:nS2), s_fes_ci(z1c:z1c+nS2-1), ...
                 'Color', cols_cond(ci,:), 'LineWidth', 1.0);
            title(sprintf('%s b%d', cond, BLOCK), 'FontSize', 8);
        end
    end

    ylabel('V', 'FontSize', 7); grid on;
    if ci == 1
        legend({'No FES (ref)', cond}, 'Location','northeast', 'FontSize', 7);
    end
    if ci == nCond, xlabel('Time (ms)'); end
    set(gca, 'FontSize', 7);
end

sgtitle(sprintf('%s  --  Fine zoom %.0f ms  --  All FES conditions  --  Channel: %s', ...
        PATIENT_ID, ZOOM2_DUR*1000, refLabel), ...
        'FontSize', 12, 'FontWeight', 'bold');

fprintf('Fig 4: compare the spike period between conditions (should be ~constant for the same FES frequency).\n');

% =========================================================================
% FIGURE 5: very fine zoom (~50 ms) on a single FES pulse
%            Aim: measure the exact width of the spike to choose
%            the blanking duration in the removal algorithm
% =========================================================================
% Parameters: adjust PULSE_START to centre on a visible spike
PULSE_START = 7.05;   % seconds: point just before a Rehab spike
PULSE_DUR   = 0.05;   % 50ms

% Uses the Rehab condition (the most contaminated) as the reference
seqRehab = find(strcmp(condList.condition, 'Rehab') & condList.block == BLOCK, 1);
if isempty(seqRehab)
    % fallback on the first available FES condition
    for ci = 1:length(ALL_FES_COND)
        seqRehab = find(strcmp(condList.condition, ALL_FES_COND{ci}) & condList.block == BLOCK, 1);
        if ~isempty(seqRehab), break; end
    end
end
tRef = Trial(allIdx(seqRehab));

z1p = max(1, round(PULSE_START * FS));
z2p = min(round((PULSE_START + PULSE_DUR) * FS), length(double(tRef.Emg(1).Signal.full(:))));
t_p = (0:z2p-z1p) / FS * 1000;  % en ms

figure('Name', sprintf('%s -- Single pulse %.3f-%.3fs (Rehab)', PATIENT_ID, PULSE_START, PULSE_START+PULSE_DUR), ...
       'units','normalized','outerposition',[0 0 1 1]);

for ji = 1:nEmg
    j    = emgIdx(ji);
    lbl  = tRef.Emg(j).label;
    sig  = double(tRef.Emg(j).Signal.full(:));
    s0   = double(tNoFES.Emg(j).Signal.full(:));
    nS   = min(length(sig)-z1p+1, length(t_p));

    subplot(nEmg, 1, ji);
    plot(t_p(1:nS), s0(z1p:z1p+nS-1), 'Color', [0.6 0.6 0.6], 'LineWidth', 1.2); hold on;
    plot(t_p(1:nS), sig(z1p:z1p+nS-1), 'Color', COL_FES, 'LineWidth', 1.5);

    % Marks the zero crossing to estimate the width visually
    yline(0, '--k', 'LineWidth', 0.5);
    title(lbl, 'FontSize', 9); ylabel('V'); grid on;
    if ji == 1
        legend({'No FES (ref)', 'FES Rehab'}, 'Location','northeast');
    end
    if ji == nEmg, xlabel('Time (ms)'); end
end

sgtitle(sprintf('%s  --  Single pulse zoom %.0f ms  --  Rehab b%d  (measure spike width -> blanking duration)', ...
        PATIENT_ID, PULSE_DUR*1000, BLOCK), 'FontSize', 12, 'FontWeight', 'bold');

fprintf('Fig 5: measure the spike width (start of the positive peak -> return to zero).\n');
fprintf('        This duration = blanking duration to apply in the removal algorithm.\n');
fprintf('        Adjust PULSE_START to centre on a clean spike.\n');
