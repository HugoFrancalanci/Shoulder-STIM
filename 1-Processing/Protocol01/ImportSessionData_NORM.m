% Author     :   F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   May 2022
% -------------------------------------------------------------------------
% Description:   Import Session.xlsx file data
% -------------------------------------------------------------------------
% Dependencies : None
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function [Patient,Session,Pathology] = ImportSessionData_NORM(participantID)

% Extract data
tSession = readtable('C:\Users\Florent\OneDrive - Université de Genève\_CLINIQUE\Données\Protocole01_Recrutement_Cinesiologie.xlsx','Range','A4:K36','Sheet',2);
for iparticipant = 1:size(tSession,1)
    if strcmp(cell2mat(table2array(tSession(iparticipant,1))),participantID)
        tSession = tSession(iparticipant,:);
        break;
    end
end
% Patient
Patient.ID                   = cell2mat(table2array(tSession(1,1)));
Patient.lastname             = '';
Patient.firstname            = '';
if table2array(tSession(1,2)) == 0
    Patient.gender           = 'Homme';
elseif table2array(tSession(1,2)) == 1
    Patient.gender           = 'Femme';
end
Patient.dob                  = ''; % The date format must be defined accordingly in the Matlab settings
if table2array(tSession(1,7)) == 0
    Patient.dominantArm      = 'Droit';
elseif table2array(tSession(1,7)) == 1
    Patient.dominantArm      = 'Gauche';
end
Patient.WORC.DA              = table2array(tSession(1,8));
Patient.WORC.NA              = table2array(tSession(1,9));
Patient.WOSI.DA              = table2array(tSession(1,10));
Patient.WOSI.NA              = table2array(tSession(1,11));
Pathology.Diagnosis.side     = '';
Pathology.Diagnosis.d1       = '';
Pathology.Diagnosis.d2       = '';
Pathology.Diagnosis.d3       = '';
Pathology.Diagnosis.d4       = '';
Pathology.Diagnosis.d5       = '';
Pathology.PlanedSurgery.i1   = '';
Pathology.PlanedSurgery.i2   = '';
Pathology.PlanedSurgery.i3   = '';
Pathology.PlanedSurgery.i4   = '';
Pathology.PlanedSurgery.i5   = '';
Pathology.PreviousSurgery.i1 = '';
Pathology.PreviousSurgery.i2 = '';
Pathology.PreviousSurgery.i3 = '';
Pathology.PreviousSurgery.i4 = '';
Pathology.PreviousSurgery.i5 = '';
% Session
Session.ID                   = cell2mat(table2array(tSession(1,1))); % Participant ID reported here
Session.date                 = '20240101'; % The date format must be defined accordingly in the Matlab settings
Session.objective            = '';
Session.physician            = '';
Session.operator             = '';
Session.protocol             = 'PROTOCOL01';
Session.markerHeight1        = 0.0095; % m, related to scapular and clavicle markers
Session.markerHeight2        = 0.0140; % m, related to thorax and humerus markers
Session.patientAge           = table2array(tSession(1,3));
if iscell(table2array(tSession(1,4)))
    Session.patientHeight    = str2num(cell2mat(table2array(tSession(1,4))))*1e-2; % m
else
    Session.patientHeight    = table2array(tSession(1,4))*1e-2; % m
end
if iscell(table2array(tSession(1,5)))
    Session.patientBodyMass  = str2num(cell2mat(table2array(tSession(1,5)))); % kg
else
    Session.patientBodyMass  = table2array(tSession(1,5)); % kg
end
if iscell(table2array(tSession(1,6)))
    Session.patientSpan      = str2num(cell2mat(table2array(tSession(1,6))))*1e-2; % m
else
    Session.patientSpan      = table2array(tSession(1,6))*1e-2; % m
end
Session.comments             = '';
Session.Pain.label           = '';
Session.Pain.Rvalue          = '';
Session.Pain.Lvalue          = '';