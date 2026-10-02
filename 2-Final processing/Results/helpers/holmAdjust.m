function [pAdj, rejected] = holmAdjust(p, alpha)
% =========================================================================
% holmAdjust.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   October 2026
% -------------------------------------------------------------------------
% Description :  Holm-Bonferroni step-down correction (Holm 1979) for a
%                family of scalar (0D) p-values — discrete-parameter
%                counterpart of holmAlphaSPM1D.m (used for the 1D SPM
%                curves). Returns Holm-ADJUSTED p-values :
%                  pAdj(k-th smallest) = max_{j<=k} min(1, (m-j+1) * p_(j))
%                so that rejected = pAdj < alpha is exactly the Holm
%                step-down decision.
% -------------------------------------------------------------------------
% Parameters :   p     — vector of raw p-values (NaN = test not performed,
%                        excluded from the family)
%                alpha — family-wise alpha (default 0.05)
% Outputs    :   pAdj     — Holm-adjusted p-values (NaN where p is NaN)
%                rejected — logical, pAdj < alpha
% -------------------------------------------------------------------------
% Dependencies : none
% Reference  :   Holm S (1979), Scand J Stat 6:65-70
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
