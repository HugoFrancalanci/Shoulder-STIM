% Author     :   F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   April 2022
% -------------------------------------------------------------------------
% Description:   Initialise virtual marker structure
% -------------------------------------------------------------------------
% Dependencies : To be defined
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function Trial = InitialiseVmarkerTrajectories(Trial)

vmarkerLabels = {'SXS','RSIA2','RSRS2','RSAA2','RSCT2','LSIA2','LSRS2','LSAA2','LSCT2','REJC','RGJC','LEJC','LGJC'};
             
for i = 1:length(vmarkerLabels)
    Trial.Vmarker(i).label              = vmarkerLabels{i};
    Trial.Vmarker(i).type               = '';
    Trial.Vmarker(i).Body.Segment.label = '';
    Trial.Vmarker(i).Body.Curve.label   = 'none';
    Trial.Vmarker(i).Body.Curve.index   = 'none';
    Trial.Vmarker(i).Trajectory.full    = [];
    Trial.Vmarker(i).Trajectory.rcycle  = [];
    Trial.Vmarker(i).Trajectory.lcycle  = [];
    Trial.Vmarker(i).Trajectory.units   = 'm';
    Trial.Vmarker(i).Trajectory.Gap     = [];
end