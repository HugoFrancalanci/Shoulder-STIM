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

function [Patient,Session,Pathology] = ImportSessionData()

% Extract data
tSession                     = readtable('Session.xlsx','Range','A4:F57');
% Patient
Patient.ID                   = cell2mat(table2array(tSession(1,2)));
Patient.lastname             = cell2mat(table2array(tSession(2,2)));
Patient.firstname            = cell2mat(table2array(tSession(3,2)));
Patient.gender               = cell2mat(table2array(tSession(4,2)));
Patient.dob  = NaT;
Pathology.Diagnosis.side     = cell2mat(table2array(tSession(9,2)));
Pathology.Diagnosis.d1       = cell2mat(table2array(tSession(10,2)));
Pathology.Diagnosis.d2       = cell2mat(table2array(tSession(11,2)));
Pathology.Diagnosis.d3       = cell2mat(table2array(tSession(12,2)));
Pathology.Diagnosis.d4       = cell2mat(table2array(tSession(13,2)));
Pathology.Diagnosis.d5       = cell2mat(table2array(tSession(14,2)));
Pathology.PlanedSurgery.i1   = cell2mat(table2array(tSession(15,2)));
Pathology.PlanedSurgery.i2   = cell2mat(table2array(tSession(16,2)));
Pathology.PlanedSurgery.i3   = cell2mat(table2array(tSession(17,2)));
Pathology.PlanedSurgery.i4   = cell2mat(table2array(tSession(18,2)));
Pathology.PlanedSurgery.i5   = cell2mat(table2array(tSession(19,2)));
Pathology.PreviousSurgery.i1 = cell2mat(table2array(tSession(20,2)));
Pathology.PreviousSurgery.i2 = cell2mat(table2array(tSession(21,2)));
Pathology.PreviousSurgery.i3 = cell2mat(table2array(tSession(22,2)));
Pathology.PreviousSurgery.i4 = cell2mat(table2array(tSession(23,2)));
Pathology.PreviousSurgery.i5 = cell2mat(table2array(tSession(24,2)));
% Session
Session.ID                   = cell2mat(table2array(tSession(26,2)));
Session.date = NaT;
Session.objective            = cell2mat(table2array(tSession(30,2)));
Session.physician            = cell2mat(table2array(tSession(27,2)));
Session.operator             = cell2mat(table2array(tSession(28,2)));
Session.protocol             = cell2mat(table2array(tSession(32,2)));
Session.markerHeight1        = 0.0095; % m, related to scapular and clavicle markers
Session.markerHeight2        = 0.0140; % m, related to thorax and humerus markers
Session.patientBodyMass = 70; % kg — placeholder
Session.patientHeight = 1.70; % m — placeholder
Session.comments      = '';
Session.Pain.label    = {};
Session.Pain.Rvalue   = [];
Session.Pain.Lvalue   = [];