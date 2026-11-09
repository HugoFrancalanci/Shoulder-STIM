% Author     :   H. Francalanci
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
% Date       :   June 2025
% -------------------------------------------------------------------------
% Description:   Automatic detection of humeral elevation cycles by threshold
%                crossing (30 deg by default). One cycle = rise above the
%                threshold, then fall below it. Detects 3 cycles.
%                Visual validation with a manual fallback (m = ginput).
%
% Inputs:
%   value       - kinematic signal (1 x N vector, already unwrapped, in degrees)
%   trialName   - name of the trial (for the figure title)
%   side        - 'Right' or 'Left' (display only)
%
% Output:
%   cycles      - struct array with cycles(i).range = indices of cycle i
% -------------------------------------------------------------------------

function [cycles, threshold] = detectCycles(value, trialName, side, threshold)

cycles    = [];
nCycles   = 3;
% -------------------------------------------------------------------------
% 1 - Asks for the threshold on the first trial (empty threshold)
% -------------------------------------------------------------------------
if isempty(threshold)
    fig0 = figure('Position', [200 300 1200 400]);
    hold on;
    title(sprintf('%s  —  %s', trialName, side), 'Interpreter', 'none');
    xlabel('Frames'); ylabel('Angle (deg)');
    plot(1:length(value), value, 'r', 'LineWidth', 1.5);
    hl = yline(30, 'k--', 'LineWidth', 1.2);
    disp('  -> Signal displayed. Enter = threshold 30 deg  |  Type a value + Enter');
    rep = input('  Threshold (deg): ', 's');
    if isempty(strtrim(rep))
        threshold = 30;
    else
        threshold = str2double(strtrim(rep));
        if isnan(threshold), threshold = 30; end
    end
    delete(hl);
    yline(threshold, 'k--', 'LineWidth', 1.2);
    drawnow; pause(0.5);
    if ishandle(fig0), close(fig0); end
end

% -------------------------------------------------------------------------
% 2 - Detection by threshold crossing
% -------------------------------------------------------------------------
above = value > threshold;
transitions = diff(above); % +1 = rise, -1 = fall

onsets  = find(transitions ==  1); % Crossings above the threshold
offsets = find(transitions == -1); % Crossings below the threshold

% Pairs each onset with its next offset
pairs = [];
for i = 1:length(onsets)
    next_offset = offsets(offsets > onsets(i));
    if ~isempty(next_offset)
        pairs = [pairs; onsets(i), next_offset(1)];
    end
end

if size(pairs, 1) >= nCycles
    % Takes the first 3 detected cycles
    pairs   = pairs(1:nCycles, :);
    autoOk  = true;
else
    autoOk  = false;
end

% -------------------------------------------------------------------------
% 3 - Display
% -------------------------------------------------------------------------
fig = figure('Position', [200 300 1200 400]);
hold on;
title(sprintf('%s  —  %s', trialName, side), 'Interpreter', 'none');
xlabel('Frames'); ylabel('Angle (deg)');
ylo = min(value) - 5;
yhi = max(value) + 5;
ylim([ylo yhi]);
plot(1:length(value), value, 'r', 'LineWidth', 1.5);
yline(threshold, 'k--', '30°', 'LineWidth', 1);

if autoOk
    for i = 1:nCycles
        patch([pairs(i,1) pairs(i,2) pairs(i,2) pairs(i,1)], ...
              [ylo ylo yhi yhi], ...
              [0 0.8 0], 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    end
    disp(['  [' side '] Auto : ' num2str(nCycles) ' cycles detected.']);
    disp('  -> Enter = validate  |  m + Enter = manual mode');
else
    disp(['  [' side '] Automatic detection insufficient (' num2str(size(pairs,1)) ' cycles). Manual mode on.']);
end

% -------------------------------------------------------------------------
% 4 - Validation or manual fallback
% -------------------------------------------------------------------------
useManual = false;
if autoOk
    rep = input('', 's');
    if strcmpi(strtrim(rep), 'm')
        useManual = true;
    end
else
    useManual = true;
end

if useManual
    disp(['  [' side '] Click on the start and the end of each cycle (' num2str(nCycles*2) ' clicks).']);
    clf; hold on;
    title(sprintf('%s  —  %s  (manuel)', trialName, side), 'Interpreter', 'none');
    xlabel('Frames'); ylabel('Angle (deg)');
    ylim([ylo yhi]);
    plot(1:length(value), value, 'r', 'LineWidth', 1.5);
    yline(threshold, 'k--', '30°', 'LineWidth', 1);
    pts  = ginput(nCycles * 2);
    pts  = sort(fix(pts(:,1)));
    pairs = reshape(pts, 2, nCycles)';
    for i = 1:nCycles
        patch([pairs(i,1) pairs(i,2) pairs(i,2) pairs(i,1)], ...
              [ylo ylo yhi yhi], ...
              [0 0.8 0], 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    end
end

close(fig);

% -------------------------------------------------------------------------
% 5 - Building the cycles
% -------------------------------------------------------------------------
if size(pairs, 1) >= 1
    for i = 1:size(pairs, 1)
        cycles(i).range = (pairs(i,1):pairs(i,2))';
    end
else
    warning('detectCycles: no cycle defined for %s (%s).', trialName, side);
end
