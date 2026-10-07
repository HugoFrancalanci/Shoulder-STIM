function plane = extractHTPlane(trial, jht, cycleKey)
% =========================================================================
% extractHTPlane.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Humerothoracic plane of elevation of one trial (orientation
%               of the humeral long axis in the transverse plane of the
%               thorax, 0 deg = frontal plane, + = anterior), averaged over
%               its cycles. Read from Trial.Joint(jht).ElevationPlane, as
%               computed by the K-LAB toolbox (ComputeKinematics.m), and
%               brought back to [-180, 180] deg.
% -------------------------------------------------------------------------
% Parameters  : trial    : one element of the K-LAB Trial struct array
%               jht      : humerothoracic joint index (R = 1, L = 6)
%               cycleKey : 'rcycle' or 'lcycle'
% Outputs     : plane : (1,101) mean plane of elevation (deg), [] if missing
% -------------------------------------------------------------------------
% Dependencies: none
% =========================================================================

plane = [];
try
    ep = trial.Joint(jht).ElevationPlane;
    if ~isfield(ep, cycleKey) || isempty(ep.(cycleKey)), return; end
    data = squeeze(ep.(cycleKey));                 % (101, nCycles) or (101,1)
    if isrow(data), data = data'; end
    if size(data, 1) ~= 101, return; end
    data = mod(data + 180, 360) - 180;             % [-180, 180] deg
    plane = mean(data, 2, 'omitnan')';
catch
    plane = [];
end
end
