% Author     :   H. Francalanci
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
% Date       :   June 2025
% -------------------------------------------------------------------------
% Description:   Détection automatique des cycles d'élévation humérale
%                par passage de seuil (30°). Un cycle = montée au-dessus
%                de 30° puis descente en dessous de 30°. Détecte 3 cycles.
%                Validation visuelle avec fallback manuel (m = ginput).
%
% Inputs:
%   value       - signal cinématique (vecteur 1×N, déjà unwrappé, en degrés)
%   trialName   - nom du trial (pour le titre de la figure)
%   side        - 'Droit' ou 'Gauche'
%
% Output:
%   cycles      - struct array avec cycles(i).range = indices du cycle i
% -------------------------------------------------------------------------

function [cycles, threshold] = detectCycles(value, trialName, side, threshold)

cycles    = [];
nCycles   = 3;
% -------------------------------------------------------------------------
% 1 - Demande du seuil si premier trial (threshold vide)
% -------------------------------------------------------------------------
if isempty(threshold)
    fig0 = figure('Position', [200 300 1200 400]);
    hold on;
    title(sprintf('%s  —  %s', trialName, side), 'Interpreter', 'none');
    xlabel('Frames'); ylabel('Angle (deg)');
    plot(1:length(value), value, 'r', 'LineWidth', 1.5);
    hl = yline(30, 'k--', 'LineWidth', 1.2);
    disp('  → Signal affiché. Entrée = seuil 30°  |  Taper une valeur + Entrée');
    rep = input('  Seuil (deg) : ', 's');
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
% 2 - Détection par passage de seuil
% -------------------------------------------------------------------------
above = value > threshold;
transitions = diff(above); % +1 = montée, -1 = descente

onsets  = find(transitions ==  1); % Passages au-dessus du seuil
offsets = find(transitions == -1); % Passages en dessous du seuil

% Apparier chaque onset avec son offset suivant
pairs = [];
for i = 1:length(onsets)
    next_offset = offsets(offsets > onsets(i));
    if ~isempty(next_offset)
        pairs = [pairs; onsets(i), next_offset(1)];
    end
end

if size(pairs, 1) >= nCycles
    % Prendre les 3 premiers cycles détectés
    pairs   = pairs(1:nCycles, :);
    autoOk  = true;
else
    autoOk  = false;
end

% -------------------------------------------------------------------------
% 3 - Affichage
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
    disp(['  [' side '] Auto : ' num2str(nCycles) ' cycles détectés.']);
    disp('  → Entrée = valider  |  m + Entrée = mode manuel');
else
    disp(['  [' side '] Détection auto insuffisante (' num2str(size(pairs,1)) ' cycles). Mode manuel activé.']);
end

% -------------------------------------------------------------------------
% 4 - Validation ou fallback manuel
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
    disp(['  [' side '] Cliquer sur le début et la fin de chaque cycle (' num2str(nCycles*2) ' clics).']);
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
% 5 - Construction des cycles
% -------------------------------------------------------------------------
if size(pairs, 1) >= 1
    for i = 1:size(pairs, 1)
        cycles(i).range = (pairs(i,1):pairs(i,2))';
    end
else
    warning('detectCycles: aucun cycle défini pour %s (%s).', trialName, side);
end
