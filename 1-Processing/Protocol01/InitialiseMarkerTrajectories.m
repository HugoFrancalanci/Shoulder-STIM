% Author       : F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License      : Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code  : To be defined
% Reference    : To be defined
% Date         : December 2021
% -------------------------------------------------------------------------
% Description  : This routine initialise the markerset used in this project.
% Inputs       : To be defined
% Outputs      : To be defined
% -------------------------------------------------------------------------
% Dependencies : None
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function Trial = InitialiseMarkerTrajectories(markerSet,Trial,Marker,Units)

% Get markerSet parameters
trajectorySet = markerSet(:,1);
landmarkList  = markerSet(:,2);
segmentList   = markerSet(:,3);
curveList     = markerSet(:,4:5);

% Initialise markers
Trial.Marker = [];
if ~strcmp(trajectorySet{1},'') % Empty list
    for i = 1:length(trajectorySet)
        Trial.Marker(i).label                 = trajectorySet{i};
        Trial.Marker(i).type                  = landmarkList{i};
        Trial.Marker(i).Body.Segment.label    = segmentList{i};
        Trial.Marker(i).Body.Curve.label      = curveList{i*2-1};
        Trial.Marker(i).Body.Curve.index      = curveList{i*2};
        if isfield(Marker,trajectorySet{i})
            Trial.Marker(i).Trajectory.full   = permute(Marker.(trajectorySet{i}),[2,3,1])*Units.ratio;
            Trial.Marker(i).Trajectory.rcycle = [];
            Trial.Marker(i).Trajectory.lcycle = [];
            Trial.Marker(i).Trajectory.units  = Units.output;
            Trial.Marker(i).Trajectory.Gap    = [];
        else
            Trial.Marker(i).Trajectory.full   = [];
            Trial.Marker(i).Trajectory.rcycle = [];
            Trial.Marker(i).Trajectory.lcycle = [];
            Trial.Marker(i).Trajectory.units  = Units.output;
            Trial.Marker(i).Trajectory.Gap    = [];
        end
    end
end