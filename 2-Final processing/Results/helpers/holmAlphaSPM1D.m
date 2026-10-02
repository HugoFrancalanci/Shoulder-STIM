function [alphaAdj, pTest, rejected] = holmAlphaSPM1D(spmList, alpha)
% =========================================================================
% holmAlphaSPM1D.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   October 2026
% -------------------------------------------------------------------------
% Description :  Holm-Bonferroni step-down correction (Holm 1979) for a
%                family of SPM1D two-tailed t-tests (post-hoc). Replaces the
%                single Bonferroni threshold alpha/m by one threshold per
%                test, alpha/(m-k+1) for the k-th smallest p-value, which is
%                uniformly more powerful while still controlling the
%                family-wise error rate at alpha.
%                Each test needs ONE p-value to be ranked : SPM1D only
%                reports cluster p-values above a given threshold, so the
%                test-level p-value used here is the RFT probability that
%                the maximum of the 1D t field exceeds the observed maximum
%                |t| (two-tailed, same RFT/Bonferroni-corrected survival
%                function as spm1d's own inference). By construction,
%                pTest(k) < a  <=>  spm.inference(a) has at least one
%                supra-threshold cluster — so the Holm decision and the
%                clusters drawn afterwards are consistent.
%                Usage in the calling script : run spm.inference(alphaAdj(k),
%                'two_tailed', true, ...) on each test. For tests NOT
%                rejected by Holm, alphaAdj is set to the threshold at which
%                the step-down procedure stopped ; since their p-value is
%                >= that threshold, inference returns no cluster for them.
% -------------------------------------------------------------------------
% Parameters :   spmList — cell array of spm1d SPM{t} objects (output of
%                          spm1d.stats.ttest_paired, BEFORE .inference) ;
%                          empty cells = comparisons not performed (excluded
%                          from the family, m counts non-empty cells only)
%                alpha   — family-wise alpha (e.g. 0.05)
% Outputs    :   alphaAdj — 1 x numel(spmList), alpha to pass to inference
%                           (NaN for empty cells)
%                pTest    — 1 x numel(spmList), test-level p-value (NaN for
%                           empty cells)
%                rejected — 1 x numel(spmList) logical, true if H0 rejected
% -------------------------------------------------------------------------
% Dependencies : spm1dmatlab-master/ (spm1d.rft1d.t.sf_resels)
% Reference  :   Holm S (1979), A simple sequentially rejective multiple
%                test procedure, Scand J Stat 6:65-70
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
