function [r, p, df, slope] = rmCorr(X, Y)
% =========================================================================
% rmCorr.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   October 2026
% -------------------------------------------------------------------------
% Description :  Repeated-measures correlation (Bakdash & Marusich 2017,
%                Front Psychol 8:456) : common within-subject linear
%                association between two variables measured in several
%                conditions per subject. Each subject's values are centred
%                on that subject's mean (removes between-subject
%                differences), then Pearson r on the pooled centred values,
%                df = N_obs - N_subjects - 1. Pairs with a NaN are dropped
%                (a subject's mean is computed on its complete pairs).
% -------------------------------------------------------------------------
% Parameters :   X, Y — (nSubjects, nConditions)
% Outputs    :   r, p (two-tailed), df, slope (common within-subject slope
%                of Y on X)
% -------------------------------------------------------------------------
% Dependencies : none (p from the incomplete beta function)
% =========================================================================

ok = ~isnan(X) & ~isnan(Y);
X(~ok) = NaN; Y(~ok) = NaN;
nSub = sum(any(ok, 2));
xc = X - mean(X, 2, 'omitnan');
yc = Y - mean(Y, 2, 'omitnan');
xc = xc(ok); yc = yc(ok);
r     = sum(xc .* yc) / sqrt(sum(xc.^2) * sum(yc.^2));
slope = sum(xc .* yc) / sum(xc.^2);
df    = numel(xc) - nSub - 1;
t     = r * sqrt(df / (1 - r^2));
p     = betainc(df / (df + t^2), df / 2, 0.5);   % = 2 * (1 - tcdf(|t|, df))
end
