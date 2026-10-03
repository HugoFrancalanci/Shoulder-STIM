function [r, p, df, slope] = rmCorr(X, Y)
% =========================================================================
% rmCorr.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Repeated-measures correlation: common within-participant
%               linear association between two variables measured in several
%               conditions. Values are centred on each participant's mean, then
%               pooled; df = N_obs - N_participants - 1.
% -------------------------------------------------------------------------
% Parameters  : X, Y : (nParticipants, nConditions)
% Outputs     : r, p (two-tailed), df, slope (common within-participant slope
%               of Y on X)
% -------------------------------------------------------------------------
% Dependencies: none
% References  : Bakdash JZ, Marusich LR (2017), Front Psychol 8:456
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
