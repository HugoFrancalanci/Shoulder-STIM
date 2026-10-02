function h = drawExclusionZone(ax, zone, mode)
% =========================================================================
% drawExclusionZone.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   October 2026
% -------------------------------------------------------------------------
% Description :  Draws the "not interpretable" zone (humerothoracic
%                elevation > threshold, see computeExclusionZone.m) as a
%                transparent grey vertical band spanning the full height of
%                the axes (xregion : follows any later ylim change, does not
%                alter the axis limits, hidden from legends). Call it right
%                after "hold on", before the curves, so it stays behind.
%                mode = 'legend' instead draws an invisible dummy patch in
%                a legend axes and returns its handle, to add the matching
%                grey entry to a custom legend.
% -------------------------------------------------------------------------
% Parameters :   ax   — target axes
%                zone — struct from computeExclusionZone.m (.threshold,
%                       .windows) ; [] or no window = nothing drawn
%                mode — optional, 'plot' (default) or 'legend'
% Outputs    :   h — handles of the xregion objects ('plot') or of the
%                    dummy legend patch ('legend') ; empty if no zone
% -------------------------------------------------------------------------
% Dependencies : MATLAB R2023a+ (xregion)
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
