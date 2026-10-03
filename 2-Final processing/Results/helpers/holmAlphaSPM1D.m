function [alphaAdj, pTest, rejected] = holmAlphaSPM1D(spmList, alpha)
% =========================================================================
% holmAlphaSPM1D.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Holm-Bonferroni step-down correction for a family of SPM1D
%               paired t-tests. Each test is given one p-value (random field
%               theory probability of its maximum |t|), the p-values are ranked
%               and the k-th smallest is compared with alpha / (m - k + 1).
%               Returns the alpha to use in spm.inference() for each test.
% -------------------------------------------------------------------------
% Parameters  : spmList : cell array of spm1d SPM{t} objects (before inference);
%                         empty cells are excluded from the family
%               alpha   : family-wise alpha (e.g. 0.05)
% Outputs     : alphaAdj : alpha to pass to inference (NaN for empty cells)
%               pTest    : test-level p-value (NaN for empty cells)
%               rejected : logical, true if H0 is rejected
% -------------------------------------------------------------------------
% Dependencies: spm1dmatlab-master/
% References  : Holm S (1979), Scand J Stat 6:65-70
% =========================================================================

nTests   = numel(spmList);
alphaAdj = NaN(1, nTests);
pTest    = NaN(1, nTests);
rejected = false(1, nTests);

for k = 1:nTests
    s = spmList{k};
    if isempty(s), continue; end
    zmax = max(abs(s.z), [], 'omitnan');
    if isempty(zmax) || isnan(zmax)
        pTest(k) = 1;
    elseif isinf(zmax)
        pTest(k) = 0;
    else
        p1 = spm1d.rft1d.t.sf_resels(zmax, s.df(2), s.resels, 'withBonf', true, 'nNodes', s.nNodes);
        pTest(k) = min(1, 2 * p1);  % two-tailed (inference utilise alpha/2 par queue)
    end
end

tested = find(~isnan(pTest));
m = numel(tested);
[~, ord] = sort(pTest(tested));

stopped   = false;
alphaStop = NaN;
for r = 1:m
    k   = tested(ord(r));
    thr = alpha / (m - r + 1);
    if ~stopped && pTest(k) < thr
        alphaAdj(k) = thr;
        rejected(k) = true;
    else
        if ~stopped
            alphaStop = thr;
            stopped   = true;
        end
        alphaAdj(k) = alphaStop;
    end
end

end
