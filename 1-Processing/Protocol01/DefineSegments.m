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
% Description:   Define the segments used in the kinematic chain(s)
% -------------------------------------------------------------------------
% Dependencies : To be defined
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function Trial = DefineSegments(c3dFiles,Session,Trial)

% -------------------------------------------------------------------------
% Thorax parameters
% -------------------------------------------------------------------------
% Extract marker trajectories
SJN = Trial.Marker(1).Trajectory.full;
SME = Trial.Marker(2).Trajectory.full;
SXS = Trial.Marker(3).Trajectory.full;
CV7 = Trial.Marker(4).Trajectory.full;
TV3 = Trial.Marker(5).Trajectory.full;
TV5 = Trial.Marker(6).Trajectory.full;
TV8 = Trial.Marker(7).Trajectory.full;
S1  = Trial.Marker(8).Trajectory.full;
% Segment axes (Wu et al. 2005)
O4 = SJN;
Y4 = Vnorm_array3((CV7+SJN)/2-(TV8+SXS)/2);
Z4 = Vnorm_array3(cross(SJN-(TV8+SXS)/2,CV7-(TV8+SXS)/2));
X4 = Vnorm_array3(cross(Y4,Z4));
Trial.Segment(4).T.full = [X4 Y4 Z4 O4; repmat([0 0 0 1],[1,1,size(SJN,3)])];
% Segment parameters (Naaim thesis)
rP4                      = (CV7+SJN)/2;
rD4                      = (TV8+SXS)/2;
w4                       = Z4;
u4                       = Vnorm_array3(cross((rP4-rD4),w4));
Trial.Segment(4).Q.full  = [u4; rP4; rD4; w4];
Trial.Segment(4).rM.full = [SJN SME SXS CV7 TV3 TV5 TV8 S1];

% -------------------------------------------------------------------------
% Right humerus parameters
% -------------------------------------------------------------------------
% Extract marker trajectories
Cluster_RA_01 = Trial.Marker(18).Trajectory.full;
Cluster_RA_02 = Trial.Marker(19).Trajectory.full;
Cluster_RA_03 = Trial.Marker(20).Trajectory.full;
Cluster_RA_04 = Trial.Marker(21).Trajectory.full;
Cluster_RA_05 = Trial.Marker(22).Trajectory.full;
RHME          = Trial.Marker(23).Trajectory.full;
RHLE          = Trial.Marker(24).Trajectory.full;
RCAJ          = Trial.Marker(10).Trajectory.full;
LCAJ          = Trial.Marker(33).Trajectory.full;
RRSP          = Trial.Marker(30).Trajectory.full;
RUSP          = Trial.Marker(31).Trajectory.full;
% Define elbow joint centre
REJC                              = (RHME+RHLE)/2;
Trial.Vmarker(10).Trajectory.full = REJC;
% Define glenohumeral joint centre
% Method 1: Rab's regression (Rab et al. 2002)
referenceMarker                   = RCAJ;
referenceLength                   = mean(sqrt(sum(abs(RCAJ-LCAJ).^2,1)),3);
offset                            = -0.17*referenceLength; % -17%
thoraxSIaxis                      = (CV7+SJN)/2-(TV8+SXS)/2;
thoraxSIaxis                      = thoraxSIaxis./sqrt(sum(abs(thoraxSIaxis).^2,1));
RGJC                              = referenceMarker+(offset+Session.markerHeight1)*thoraxSIaxis;
Trial.Vmarker(11).Trajectory.full = RGJC;
% Segment axes (Wu et al. 2005)
O1 = RGJC;
Y1 = Vnorm_array3(RGJC-REJC);
if (contains(c3dFiles.name,'ANALYTIC3') || contains(c3dFiles.name,'ANALYTIC4'))
    X1 = Vnorm_array3((RUSP+RRSP)/2-REJC); % Wu et al. 2005 option 2
else
    X1 = Vnorm_array3(cross(RGJC-RHLE,RGJC-RHME)); % Wu et al. 2005 option 1
end
Z1 = Vnorm_array3(cross(X1,Y1));
Trial.Segment(1).T.full = [X1 Y1 Z1 O1; repmat([0 0 0 1],[1,1,size(SJN,3)])];
% Segment parameters (Naaim thesis)
u1                       = X1;
rP1                      = RGJC;
rD1                      = REJC;
w1                       = Z1;
Trial.Segment(1).Q.full  = [u1; rP1; rD1; w1];
Trial.Segment(1).rM.full = [Cluster_RA_01 Cluster_RA_02 Cluster_RA_03 Cluster_RA_04 Cluster_RA_05 RHME RHLE];

% -------------------------------------------------------------------------
% Right scapula parameters
% -------------------------------------------------------------------------
% Extract marker trajectories
Cluster_RS_01 = Trial.Marker(11).Trajectory.full;
Cluster_RS_02 = Trial.Marker(12).Trajectory.full;
Cluster_RS_03 = Trial.Marker(13).Trajectory.full;
RSIA          = Trial.Marker(14).Trajectory.full;
RSRS          = Trial.Marker(15).Trajectory.full;
RSAA          = Trial.Marker(16).Trajectory.full;
RSCT          = Trial.Marker(17).Trajectory.full;
RCAJ          = Trial.Marker(10).Trajectory.full;
% Segment axes (Wu et al. 2005)
O2 = RSAA;
Z2 = Vnorm_array3(RSAA-RSRS);
X2 = Vnorm_array3(cross(RSRS-RSIA,RSAA-RSIA));
Y2 = Vnorm_array3(cross(Z2,X2));
Trial.Segment(2).T.full = [X2 Y2 Z2 O2; repmat([0 0 0 1],[1,1,size(RSIA,3)])];
% Segment parameters
u2                       = X2;
rP2                      = RCAJ; % Should be the equivalent point on scapula, but not available in dataset
rD2                      = RSAA; % Should be the glenoid fossa centre, but not available in dataset
w2                       = Z2;
Trial.Segment(2).Q.full  = [u2; rP2; rD2; w2];
Trial.Segment(2).rM.full = [Cluster_RS_01 Cluster_RS_02 Cluster_RS_03 RSIA RSRS RSAA RSCT];

% -------------------------------------------------------------------------
% Right clavicle parameters
% -------------------------------------------------------------------------
% To be done

% -------------------------------------------------------------------------
% Left humerus parameters
% -------------------------------------------------------------------------
% Extract marker trajectories
Cluster_LA_01 = Trial.Marker(41).Trajectory.full;
Cluster_LA_02 = Trial.Marker(42).Trajectory.full;
Cluster_LA_03 = Trial.Marker(43).Trajectory.full;
Cluster_LA_04 = Trial.Marker(44).Trajectory.full;
Cluster_LA_05 = Trial.Marker(45).Trajectory.full;
LHME          = Trial.Marker(46).Trajectory.full;
LHLE          = Trial.Marker(47).Trajectory.full;
RCAJ          = Trial.Marker(10).Trajectory.full;
LCAJ          = Trial.Marker(33).Trajectory.full;
LRSP          = Trial.Marker(53).Trajectory.full;
LUSP          = Trial.Marker(54).Trajectory.full;
% Define elbow joint centre
LEJC                              = (LHME+LHLE)/2;
Trial.Vmarker(12).Trajectory.full = LEJC;
% Define glenohumeral joint centre
% Method 1: Rab's regression (Rab et al. 2002)
referenceMarker                   = LCAJ;
referenceLength                   = mean(sqrt(sum(abs(RCAJ-LCAJ).^2,1)),3);
offset                            = -0.17*referenceLength; % -17%
thoraxSIaxis                      = (CV7+SJN)/2-(TV8+SXS)/2;
thoraxSIaxis                      = thoraxSIaxis./sqrt(sum(abs(thoraxSIaxis).^2,1));
LGJC                              = referenceMarker+(offset+Session.markerHeight1)*thoraxSIaxis;
Trial.Vmarker(13).Trajectory.full = LGJC;
% Segment axes (Wu et al. 2005)
O5 = LGJC;
Y5 = Vnorm_array3(LGJC-LEJC);
if (contains(c3dFiles.name,'ANALYTIC3') || contains(c3dFiles.name,'ANALYTIC4'))
    X5 = Vnorm_array3((LUSP+LRSP)/2-LEJC); % Wu et al. 2005 option 2
else
    X5 = Vnorm_array3(cross(LGJC-LHLE,LGJC-LHME)); % Wu et al. 2005 option 1
end
Z5 = Vnorm_array3(cross(X5,Y5));
Trial.Segment(5).T.full = [X5 Y5 Z5 O5; repmat([0 0 0 1],[1,1,size(SJN,3)])];
% Segment parameters (Naaim thesis)
u5                       = X5;
rP5                      = LGJC;
rD5                      = LEJC;
w5                       = Z5;
Trial.Segment(5).Q.full  = [u5; rP5; rD5; w5];
Trial.Segment(5).rM.full = [Cluster_LA_01 Cluster_LA_02 Cluster_LA_03 Cluster_LA_04 Cluster_LA_05 LHME LHLE];

% -------------------------------------------------------------------------
% Left scapula parameters
% -------------------------------------------------------------------------
% Extract marker trajectories
Cluster_LS_01 = Trial.Marker(34).Trajectory.full;
Cluster_LS_02 = Trial.Marker(35).Trajectory.full;
Cluster_LS_03 = Trial.Marker(36).Trajectory.full;
LSIA          = Trial.Marker(37).Trajectory.full;
LSRS          = Trial.Marker(38).Trajectory.full;
LSAA          = Trial.Marker(39).Trajectory.full;
LSCT          = Trial.Marker(40).Trajectory.full;
LCAJ          = Trial.Marker(33).Trajectory.full;
% Segment axes (Wu et al. 2005)
O6 = LSAA;
Z6 = Vnorm_array3(LSAA-LSRS);
X6 = Vnorm_array3(cross(LSRS-LSIA,LSAA-LSIA));
Y6 = Vnorm_array3(cross(Z6,X6));
Trial.Segment(6).T.full = [X6 Y6 Z6 O6; repmat([0 0 0 1],[1,1,size(LSIA,3)])];
% Segment parameters
u6                       = X6;
rP6                      = LCAJ; % Should be the equivalent point on scapula, but not available in dataset
rD6                      = LSAA; % Should be the glenoid fossa centre, but not available in dataset
w6                       = Z6;
Trial.Segment(6).Q.full  = [u6; rP6; rD6; w6];
Trial.Segment(6).rM.full = [Cluster_LS_01 Cluster_LS_02 Cluster_LS_03 LSIA LSRS LSAA LSCT];

% -------------------------------------------------------------------------
% Left clavicle parameters
% -------------------------------------------------------------------------
% To be done