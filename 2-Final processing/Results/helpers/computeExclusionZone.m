function zone = computeExclusionZone(elevCurve, x, threshold)
% =========================================================================
% computeExclusionZone.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Finds the part(s) of the movement cycle where the
%               humerothoracic elevation exceeds a threshold (90 deg). Window
%               edges are linearly interpolated between samples.
% -------------------------------------------------------------------------
% Parameters  : elevCurve : (1,101) humerothoracic elevation (deg, + = elevation)
%               x         : cycle axis, 0:100
%               threshold : elevation threshold (deg)
% Outputs     : zone : struct with .threshold (deg) and .windows, a K x 2
%                      matrix [start end] in % of the cycle (0 x 2 if never
%                      exceeded)
% -------------------------------------------------------------------------
% Dependencies: none
% =========================================================================

zone.threshold = threshold;
zone.windows   = zeros(0, 2);
if isempty(elevCurve), return; end

c = elevCurve(:)';
above = c > threshold;
above(isnan(c)) = false;
if ~any(above), return; end

d      = diff([false above false]);
iStart = find(d == 1);
iEnd   = find(d == -1) - 1;

for k = 1:numel(iStart)
    i1 = iStart(k);
    i2 = iEnd(k);
    xs = x(i1);
    if i1 > 1
        xs = crossing(x(i1-1), x(i1), c(i1-1), c(i1), threshold);
    end
    xe = x(i2);
    if i2 < numel(c)
        xe = crossing(x(i2), x(i2+1), c(i2), c(i2+1), threshold);
    end
    zone.windows(end+1, :) = [xs xe]; %#ok<AGROW>
end
end


function xc = crossing(xa, xb, ca, cb, thr)
    if cb == ca
        xc = xa;
    else
        xc = xa + (thr - ca) / (cb - ca) * (xb - xa);
    end
end
