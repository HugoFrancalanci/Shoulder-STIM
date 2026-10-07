function tE = crossingTimes(ht, x, grid, maxExtrap)
% =========================================================================
% crossingTimes.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Time (% cycle) at which the humerothoracic elevation first
%               reaches each value of grid during the ascending phase (start
%               to peak). Below the start of the ascent, the time of the
%               minimum is used (value extended as a constant) if the gap is
%               at most maxExtrap deg, NaN otherwise. NaN also if the
%               elevation is never reached.
% -------------------------------------------------------------------------
% Parameters  : ht        : (1,101) humerothoracic elevation (deg)
%               x         : (1,101) cycle axis (%)
%               grid      : elevations to read (deg)
%               maxExtrap : maximal constant extension below the start (deg)
% Outputs     : tE : (1,numel(grid)) times (% cycle)
% -------------------------------------------------------------------------
% Dependencies: none
% =========================================================================

ht = ht(:)'; tE = NaN(size(grid));
[~, ipk] = max(ht);
[htMin, iMin] = min(ht(1:ipk));
for g = 1:numel(grid)
    if grid(g) < htMin
        if htMin - grid(g) <= maxExtrap, tE(g) = x(iMin); end
        continue;
    end
    k = find(ht(1:ipk) >= grid(g), 1);
    if isempty(k), continue; end
    if k == 1
        tE(g) = x(1);
    else
        tE(g) = x(k-1) + (grid(g) - ht(k-1)) / (ht(k) - ht(k-1)) * (x(k) - x(k-1));
    end
end
end
