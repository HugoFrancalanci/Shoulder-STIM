function h = drawExclusionZone(ax, zone, mode)
% =========================================================================
% drawExclusionZone.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Draws the zone where humerothoracic elevation exceeds 90 deg
%               (see computeExclusionZone.m) as a grey vertical band. With
%               mode = 'legend', returns a dummy patch for a custom legend.
% -------------------------------------------------------------------------
% Parameters  : ax   : target axes
%               zone : struct from computeExclusionZone.m ([] = nothing drawn)
%               mode : 'plot' (default) or 'legend'
% Outputs     : h : graphic handles (empty if no zone)
% -------------------------------------------------------------------------
% Dependencies: MATLAB R2023a or later (xregion)
% =========================================================================

EXCL_COLOR = [0.55 0.55 0.55];
EXCL_ALPHA = 0.18;

if nargin < 3, mode = 'plot'; end
h = gobjects(0);
if isempty(zone) || ~isstruct(zone) || isempty(zone.windows), return; end

if strcmp(mode, 'legend')
    h = patch(ax, NaN, NaN, EXCL_COLOR, 'FaceAlpha', EXCL_ALPHA, 'EdgeColor', 'none', ...
              'DisplayName', sprintf('Humerothoracic elevation > %g° (not interpretable)', zone.threshold));
    return;
end

for k = 1:size(zone.windows, 1)
    h(k) = xregion(ax, zone.windows(k,1), zone.windows(k,2), ...
                   'FaceColor', EXCL_COLOR, 'FaceAlpha', EXCL_ALPHA, 'HandleVisibility', 'off');
end
end
