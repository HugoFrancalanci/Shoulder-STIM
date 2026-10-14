function C = conditionColors(conditions)
% =========================================================================
% conditionColors.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Colour of each condition in the article figures, by group:
%               no stimulation in dark grey, non-optimised patterns in red
%               and orange, optimised patterns in blues and greens (dark and
%               light shades so that the groups stay distinct in grey scale).
% -------------------------------------------------------------------------
% Parameters  : conditions : cell array of condition names (code names)
% Outputs     : C : (numel(conditions), 3) RGB colours
% -------------------------------------------------------------------------
% Dependencies: none
% =========================================================================

PALETTE = { ...
    'No FES',          [0.20 0.20 0.20];   % no stimulation
    'Rehab',           [0.80 0.13 0.15];   % non-optimised
    'Random',          [0.96 0.55 0.13];   % non-optimised
    'Min_pulse_width', [0.13 0.29 0.60];   % optimised
    'Min_force',       [0.40 0.65 0.88];   % optimised
    'Min_stress',      [0.00 0.50 0.40];   % optimised
    'Min_fatigue',     [0.55 0.80 0.40]};  % optimised

C = NaN(numel(conditions), 3);
for k = 1:numel(conditions)
    i = find(strcmp(PALETTE(:,1), conditions{k}), 1);
    if isempty(i), error('conditionColors: unknown condition "%s".', conditions{k}); end
    C(k, :) = PALETTE{i, 2};
end
end
