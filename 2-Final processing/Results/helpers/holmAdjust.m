function [pAdj, rejected] = holmAdjust(p, alpha)
% =========================================================================
% holmAdjust.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Holm-Bonferroni step-down correction for a family of scalar
%               p-values (discrete parameters). Returns Holm-adjusted p-values,
%               so that pAdj < alpha gives the Holm decision.
% -------------------------------------------------------------------------
% Parameters  : p     : vector of p-values (NaN = test not performed, excluded)
%               alpha : family-wise alpha (default 0.05)
% Outputs     : pAdj     : Holm-adjusted p-values (NaN where p is NaN)
%               rejected : logical, pAdj < alpha
% -------------------------------------------------------------------------
% Dependencies: none
% References  : Holm S (1979), Scand J Stat 6:65-70
% =========================================================================

if nargin < 2, alpha = 0.05; end
pAdj     = NaN(size(p));
rejected = false(size(p));

tested = find(~isnan(p));
m = numel(tested);
if m == 0, return; end
[ps, ord] = sort(p(tested));
adj = min(1, (m - (1:m) + 1) .* ps(:)');
adj = cummax(adj);
pAdj(tested(ord)) = adj;
rejected(tested) = pAdj(tested) < alpha;
end
