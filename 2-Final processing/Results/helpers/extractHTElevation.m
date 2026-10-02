function elev = extractHTElevation(trial, jht, cycleKey)
% =========================================================================
% extractHTElevation.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   October 2026
% -------------------------------------------------------------------------
% Description :  Humerothoracic elevation (humerus relative to thorax) of
%                one trial, mean over its cycles, expressed POSITIVE upward
%                (deg). Used only to locate the part of the cycle where the
%                arm is elevated above EXCL_ELEV_THRESHOLD (90 deg), where
%                glenohumeral / scapulo-thoracic angles are not interpreted
%                (see computeExclusionZone.m / drawExclusionZone.m).
%                Source : Trial.Joint(jht).Euler.rcycle / lcycle, sequence
%                XZY for ANALYTIC2 (ComputeKinematics.m), dim 1 = X =
%                elevation with "- = elevation" (same convention as GH),
%                hence the sign flip.
% -------------------------------------------------------------------------
% Parameters :   trial    — one element of the K-LAB Trial struct array
%                jht      — humerothoracic joint index (HUMEROTHORACIC_JOINT_IDX
%                           in usercommands_conditions.m : RHT=1 / LHT=6)
%                cycleKey — 'rcycle' or 'lcycle'
% Outputs    :   elev — (1,101) mean elevation (deg, + = elevation), or []
%                       if the kinematics is missing
% -------------------------------------------------------------------------
% Dependencies : none
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
