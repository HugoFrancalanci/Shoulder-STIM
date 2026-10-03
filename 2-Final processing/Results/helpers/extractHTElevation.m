function elev = extractHTElevation(trial, jht, cycleKey)
% =========================================================================
% extractHTElevation.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Humerothoracic elevation (humerus relative to thorax) of one
%               trial, averaged over its cycles and expressed positive upward
%               (deg). Read from Trial.Joint(jht).Euler (XZY sequence, first
%               angle, sign inverted so that + = elevation).
% -------------------------------------------------------------------------
% Parameters  : trial    : one element of the K-LAB Trial struct array
%               jht      : humerothoracic joint index (R = 1, L = 6)
%               cycleKey : 'rcycle' or 'lcycle'
% Outputs     : elev : (1,101) mean elevation (deg), [] if missing
% -------------------------------------------------------------------------
% Dependencies: none
% =========================================================================

elev = [];
try
    euler = trial.Joint(jht).Euler;
    if ~isfield(euler, cycleKey), return; end
    data = euler.(cycleKey);
    if isempty(data), return; end

    data = squeeze(data); % (3, 1, 101, N) → (3, 101, N)
    if ndims(data) == 3
        data = nanmean(data, 3); % → (3, 101)
    elseif ~(ismatrix(data) && size(data,1) == 3 && size(data,2) == 101)
        return;
    end
    elev = -data(1, :);
catch
    elev = [];
end
end
