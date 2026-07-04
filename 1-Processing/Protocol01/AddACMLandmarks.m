% Author     :   F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   August 2023
% -------------------------------------------------------------------------
% Description:   Define scapula landmarks in the inertial coordinate system
% -------------------------------------------------------------------------
% Dependencies : To be defined
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function [Trial,Vmarker] = AddACMLandmarks(Session,Trial,Marker,Vmarker)

if contains(Trial.file,'CALIBRATION1')
    disp('  - Ajout des landmarks scapulaires');
    % -------------------------------------------------------------------------
    % RIGHT ACM
    % -------------------------------------------------------------------------
    % Set scapular plane normal (pointing posteriorly)
    scapularNormal = cross(Marker.RSAA-Marker.RSIA,Marker.RSRS-Marker.RSIA);
    scapularNormal = scapularNormal./sqrt(scapularNormal(:,1).^2+scapularNormal(:,2).^2+scapularNormal(:,3).^2);
    % Set SIA, SRS, SAA and SCT markers in the inertial coordinate system (ICS)
    % Remove marker height along the scapular plane normal
    % (negative direction for SIA, SAA and SRS, positive direction for SCT)
    Trial.Vmarker(2).type               = 'cluster-based landmark';
    Trial.Vmarker(2).Body.Segment.label = 'RScapula';
    Trial.Vmarker(2).Trajectory.full    = Marker.RSIA'-Session.markerHeight1*scapularNormal'; % In ICS
    Vmarker.RSIA                        = Trial.Vmarker(2).Trajectory.full; % Needed to share the static position with trial reconstruction
    Trial.Vmarker(3).type               = 'cluster-based landmark';
    Trial.Vmarker(3).Body.Segment.label = 'RScapula';
    Trial.Vmarker(3).Trajectory.full    = Marker.RSRS'-Session.markerHeight1*scapularNormal'; % In ICS
    Vmarker.RSRS                        = Trial.Vmarker(3).Trajectory.full; % Needed to share the static position with trial reconstruction
    Trial.Vmarker(4).type               = 'cluster-based landmark';
    Trial.Vmarker(4).Body.Segment.label = 'RScapula';
    Trial.Vmarker(4).Trajectory.full    = Marker.RSAA'-Session.markerHeight1*scapularNormal'; % In ICS
    Vmarker.RSAA                        = Trial.Vmarker(4).Trajectory.full; % Needed to share the static position with trial reconstruction
    Trial.Vmarker(5).type               = 'cluster-based landmark';
    Trial.Vmarker(5).Body.Segment.label = 'RScapula';
    Trial.Vmarker(5).Trajectory.full    = Marker.RSCT'-Session.markerHeight1*scapularNormal'; % In ICS
    Vmarker.RSCT                        = Trial.Vmarker(5).Trajectory.full; % Needed to share the static position with trial reconstruction
    % Store static ACM position
    Vmarker.RACM1                       = Marker.RACM1';
    Vmarker.RACM2                       = Marker.RACM2';
    Vmarker.RACM3                       = Marker.RACM3';
    % -------------------------------------------------------------------------
    % LEFT ACM
    % -------------------------------------------------------------------------
    % Set scapular plane normal
    scapularNormal = cross(Marker.LSRS-Marker.LSIA,Marker.LSAA-Marker.LSIA);
    scapularNormal = scapularNormal./sqrt(scapularNormal(:,1).^2+scapularNormal(:,2).^2+scapularNormal(:,3).^2);
    % Set SIA, SRS, SAA and SCT markers in the inertial coordinate system (ICS)
    % Remove marker height along the scapular plane normal
    % (negative direction for SIA, SAA and SRS, positive direction for SCT)
    Trial.Vmarker(6).type               = 'cluster-based landmark';
    Trial.Vmarker(6).Body.Segment.label = 'LScapula';
    Trial.Vmarker(6).Trajectory.full    = Marker.LSIA'-Session.markerHeight1*scapularNormal'; % In ICS
    Vmarker.LSIA                        = Trial.Vmarker(6).Trajectory.full; % Needed to share the static position with trial reconstruction
    Trial.Vmarker(7).type               = 'cluster-based landmark';
    Trial.Vmarker(7).Body.Segment.label = 'LScapula';
    Trial.Vmarker(7).Trajectory.full    = Marker.LSRS'-Session.markerHeight1*scapularNormal'; % In ICS
    Vmarker.LSRS                        = Trial.Vmarker(7).Trajectory.full; % Needed to share the static position with trial reconstruction
    Trial.Vmarker(8).type               = 'cluster-based landmark';
    Trial.Vmarker(8).Body.Segment.label = 'LScapula';
    Trial.Vmarker(8).Trajectory.full    = Marker.LSAA'-Session.markerHeight1*scapularNormal'; % In ICS
    Vmarker.LSAA                        = Trial.Vmarker(8).Trajectory.full; % Needed to share the static position with trial reconstruction
    Trial.Vmarker(9).type               = 'cluster-based landmark';
    Trial.Vmarker(9).Body.Segment.label = 'LScapula';
    Trial.Vmarker(9).Trajectory.full    = Marker.LSCT'+Session.markerHeight1*scapularNormal'; % In ICS
    Vmarker.LSCT                        = Trial.Vmarker(9).Trajectory.full; % Needed to share the static position with trial reconstruction
    % Store static ACM position
    Vmarker.LACM1                       = Marker.LACM1';
    Vmarker.LACM2                       = Marker.LACM2';
    Vmarker.LACM3                       = Marker.LACM3';
elseif ~contains(Trial.file,'CALIBRATION3') && ~contains(Trial.file,'CALIBRATION4')
    disp('  - Ajout des landmarks scapulaires');
    % -------------------------------------------------------------------------
    % RIGHT ACM
    % -------------------------------------------------------------------------
    for t = 1:size(Marker.RACM1,1)
        % Compute rigid transformation between static and dynamic ACM
        clear x y R d rms;
        x                                       = [Vmarker.RACM1';Vmarker.RACM2';Vmarker.RACM3'];
        y                                       = [Marker.RACM1(t,:);Marker.RACM2(t,:);Marker.RACM3(t,:)];
        [R,d,rms]                               = soder(x,y);
        % Apply rigid transformation on scapula anatomical landmarks
        Trial.Vmarker(2).type                   = 'cluster-based landmark';
        Trial.Vmarker(2).Body.Segment.label     = 'RScapula';
        Trial.Vmarker(2).Trajectory.full(:,:,t) = R*Vmarker.RSIA+d; % In ICS
        Trial.Vmarker(3).type                   = 'cluster-based landmark';
        Trial.Vmarker(3).Body.Segment.label     = 'RScapula';
        Trial.Vmarker(3).Trajectory.full(:,:,t) = R*Vmarker.RSRS+d; % In ICS
        Trial.Vmarker(4).type                   = 'cluster-based landmark';
        Trial.Vmarker(4).Body.Segment.label     = 'RScapula';
        Trial.Vmarker(4).Trajectory.full(:,:,t) = R*Vmarker.RSAA+d; % In ICS
        Trial.Vmarker(5).type                   = 'cluster-based landmark';
        Trial.Vmarker(5).Body.Segment.label     = 'RScapula';
        Trial.Vmarker(5).Trajectory.full(:,:,t) = R*Vmarker.RSCT+d; % In ICS
    end
    % -------------------------------------------------------------------------
    % LEFT ACM
    % -------------------------------------------------------------------------
    for t = 1:size(Marker.LACM1,1)
        % Compute rigid transformation between static and dynamic ACM
        clear x y R d rms;
        x                                       = [Vmarker.LACM1';Vmarker.LACM2';Vmarker.LACM3'];
        y                                       = [Marker.LACM1(t,:);Marker.LACM2(t,:);Marker.LACM3(t,:)];
        [R,d,rms]                               = soder(x,y);
        % Apply rigid transformation on scapula anatomical landmarks
        Trial.Vmarker(6).type                   = 'cluster-based landmark';
        Trial.Vmarker(6).Body.Segment.label     = 'LScapula';
        Trial.Vmarker(6).Trajectory.full(:,:,t) = R*Vmarker.LSIA+d; % In ICS
        Trial.Vmarker(7).type                   = 'cluster-based landmark';
        Trial.Vmarker(7).Body.Segment.label     = 'LScapula';
        Trial.Vmarker(7).Trajectory.full(:,:,t) = R*Vmarker.LSRS+d; % In ICS
        Trial.Vmarker(8).type                   = 'cluster-based landmark';
        Trial.Vmarker(8).Body.Segment.label     = 'LScapula';
        Trial.Vmarker(8).Trajectory.full(:,:,t) = R*Vmarker.LSAA+d; % In ICS
        Trial.Vmarker(9).type                   = 'cluster-based landmark';
        Trial.Vmarker(9).Body.Segment.label     = 'LScapula';
        Trial.Vmarker(9).Trajectory.full(:,:,t) = R*Vmarker.LSCT+d; % In ICS
    end
end