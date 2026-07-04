% Author     :   F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   May 2025
% -------------------------------------------------------------------------
% Description:   Extract analysis outcomes of the annual registry report
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% INIT WORKSPACE
% -------------------------------------------------------------------------
clearvars %-except data;
close all;
warning off;
clc;

% -------------------------------------------------------------------------
% SET FOLDERS
% -------------------------------------------------------------------------
Folder.toolbox       = 'C:\Users\Florent\OneDrive - Université de Genève\_CLINIQUE\Matlab\KLAB_ShoulderAnalysis_Toolbox\1-Processing\Protocol01\';
Folder.dependencies  = 'C:\Users\Florent\OneDrive - Université de Genève\_CLINIQUE\Matlab\KLAB_ShoulderAnalysis_Toolbox\1-Processing\dependencies\';
Folder.data          = 'C:\Users\Florent\OneDrive - Université de Genève\_CLINIQUE\Données\KLAB-UPPERLIMB-PROTOCOL01\Data\';
Folder.outcomes      = 'C:\Users\Florent\OneDrive - Université de Genève\_CLINIQUE\Données\';
addpath(Folder.toolbox);
addpath(genpath(Folder.dependencies));
disp(' ');

% -------------------------------------------------------------------------
% GET PATIENT LIST
% -------------------------------------------------------------------------
cd(Folder.outcomes);
patientList = readcell('Registre_extract_klab_20250512.xlsx');

% -------------------------------------------------------------------------
% GET DATA
% -------------------------------------------------------------------------
% Get folder list
cd(Folder.data);
d = dir;
dirs = d([d.isdir]);
folderList = dirs(~ismember({dirs.name}, {'.','..'}));
% Extract data related to each patient
range = 2:size(patientList,1); % from 2 to size(patientList,1) = 113
kpatient = 1;
for ipatient = range
    patientID = cell2mat(patientList(ipatient,2));
    for ifolder = 1:size(folderList,1)
        if contains(folderList(ifolder).name,num2str(patientID))
            disp(['Patient: ',num2str(patientID)]);
            % Get session list
            cd(folderList(ifolder).name);
            d = dir;
            dirs = d([d.isdir]);
            sessionList = dirs(~ismember({dirs.name}, {'.','..','CT'}));
            % Extract data related to each session
            for isession = 1:size(sessionList,1)
                disp(['    > Session: ',sessionList(isession).name]);
                cd(sessionList(isession).name);
                d = dir;
                matFile = dir('*.mat');
                Patient(kpatient).ID = patientID;
                Patient(kpatient).iside = 1; % Used in the storing process to order data
                Patient(kpatient).Session(isession).date = sessionList(isession).name;
                if isempty(matFile)
                    d = dir;
                    isReport = any(strcmp({d([d.isdir]).name}, 'Report'));
                    if isReport
                        cd('Report\');
                        matFile = dir('*.mat');
                        Patient(kpatient).Session(isession).data = load(matFile.name);
                        cd('..');
                    else
                        Patient(kpatient).Session(isession).data = [];
                    end
                else
                    Patient(kpatient).Session(isession).data = load(matFile.name);                    
                end
                cd('..');
            end
            kpatient = kpatient+1;
            cd('..');
        end
    end
end

%% ------------------------------------------------------------------------
% EXTRACT REQUIRED DATA
% -------------------------------------------------------------------------
for ipatient = 1:size(Patient,2)
    Outcomes.Patient(ipatient).ID = Patient(ipatient).ID;    
    Outcomes.Patient(ipatient).processing = 0; % Check if patient already processed for another EDS (see storing process hereafter)
    Outcomes.Patient(ipatient).side(1).label = 'Right';
    Outcomes.Patient(ipatient).side(1).preOP = [];
    Outcomes.Patient(ipatient).side(1).postOP = [];
    Outcomes.Patient(ipatient).side(2).label = 'Left';
    Outcomes.Patient(ipatient).side(2).preOP = [];
    Outcomes.Patient(ipatient).side(2).postOP = [];
    for isession = 1:size(Patient(ipatient).Session,2)
        if isfield(Patient(ipatient).Session(isession),'data')
            if ~isempty(Patient(ipatient).Session(isession).data)
                if contains(Patient(ipatient).Session(isession).data.Pathology.Diagnosis.side,'Droite')
                    if contains(Patient(ipatient).Session(isession).data.Session.objective,'pré-opératoire')
                        % PreOP            
                        Outcomes.Patient(ipatient).side(1).preOP.date = Patient(ipatient).Session(isession).data.Session.date;
                        % Humerothoracic maximum angle
                        Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.flexion.HTmax = [];
                        Outcomes.Patient(ipatient).side(1).preOP.controlateral.flexion.HTmax = [];
                        Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.abduction.HTmax = [];
                        Outcomes.Patient(ipatient).side(1).preOP.controlateral.abduction.HTmax = [];
                        Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.externalRotation.HTmax = [];
                        Outcomes.Patient(ipatient).side(1).preOP.controlateral.externalRotation.HTmax = [];
                        Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.internalRotation.HTmax = [];
                        Outcomes.Patient(ipatient).side(1).preOP.controlateral.internalRotation.HTmax = [];
                        if isfield(Patient(ipatient).Session(isession).data,'Trial')
                            if ~isempty(Patient(ipatient).Session(isession).data.Trial)
                                for itrial = 1:size(Patient(ipatient).Session(isession).data.Trial,2)
                                    if contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC1')
                                        Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.flexion.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,3,:)))); % Flexion: itrial = 1, right HT: ijoint = 1, Angle of interest: ieuler = 3
                                        Outcomes.Patient(ipatient).side(1).preOP.controlateral.flexion.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,3,:)))); % Flexion: itrial = 1, left HT: ijoint = 6, Angle of interest: ieuler = 3
                                    elseif contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC2')
                                        Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.abduction.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,1,:)))); % Abduction: itrial = 2, right HT: ijoint = 1, Angle of interest: ieuler = 1
                                        Outcomes.Patient(ipatient).side(1).preOP.controlateral.abduction.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,1,:)))); % Abduction: itrial = 2, left HT: ijoint = 6, Angle of interest: ieuler = 1
                                    elseif contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC3')
                                        if ceil(min((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))) < -10 % sign error detected 
                                            Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.externalRotation.HTmax = ceil(max(-(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))); % External rotation: itrial = 3, right HT: ijoint = 1, Angle of interest: ieuler = 2
                                        else
                                            Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.externalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))); % External rotation: itrial = 3, right HT: ijoint = 1, Angle of interest: ieuler = 2
                                        end
                                        if ceil(min((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))) < -10 % sign error detected 
                                            Outcomes.Patient(ipatient).side(1).preOP.controlateral.externalRotation.HTmax = ceil(max(-(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))); % External rotation: itrial = 3, left HT: ijoint = 6, Angle of interest: ieuler = 2
                                        else
                                            Outcomes.Patient(ipatient).side(1).preOP.controlateral.externalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))); % External rotation: itrial = 3, left HT: ijoint = 6, Angle of interest: ieuler = 2
                                        end
                                    elseif contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC4')
                                        Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.internalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))); % Internal rotation: itrial = 4, right HT: ijoint = 1, Angle of interest: ieuler = 2
                                        Outcomes.Patient(ipatient).side(1).preOP.controlateral.internalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial ).Joint(6).Euler.full(:,2,:)))); % Internal rotation: itrial = 4, left HT: ijoint = 6, Angle of interest: ieuler = 2
                                    end
                                end
                            end
                        end
                        % Pain
                        if isfield(Patient(ipatient).Session(isession).data.Session.Pain,'Rvalue')
                            if ~isempty(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue)
                                Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.flexion.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(4));
                                Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.abduction.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(5));
                                Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.externalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(6));
                                Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.internalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(7));
                            else
                                Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.flexion.pain = [];
                                Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.abduction.pain = [];
                                Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.externalRotation.pain = [];
                                Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.internalRotation.pain = [];
                            end
                            if ~isempty(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue)
                                Outcomes.Patient(ipatient).side(1).preOP.controlateral.flexion.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(4));
                                Outcomes.Patient(ipatient).side(1).preOP.controlateral.abduction.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(5));
                                Outcomes.Patient(ipatient).side(1).preOP.controlateral.externalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(6));
                                Outcomes.Patient(ipatient).side(1).preOP.controlateral.internalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(7));
                            else
                                Outcomes.Patient(ipatient).side(1).preOP.controlateral.flexion.pain = [];
                                Outcomes.Patient(ipatient).side(1).preOP.controlateral.abduction.pain = [];
                                Outcomes.Patient(ipatient).side(1).preOP.controlateral.externalRotation.pain = [];
                                Outcomes.Patient(ipatient).side(1).preOP.controlateral.internalRotation.pain = [];
                            end
                        else
                            Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.flexion.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(4));
                            Outcomes.Patient(ipatient).side(1).preOP.controlateral.flexion.pain = [];
                            Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.abduction.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(5));
                            Outcomes.Patient(ipatient).side(1).preOP.controlateral.abduction.pain = [];
                            Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.externalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(6));
                            Outcomes.Patient(ipatient).side(1).preOP.controlateral.externalRotation.pain = [];
                            Outcomes.Patient(ipatient).side(1).preOP.ipsilateral.internalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(7));
                            Outcomes.Patient(ipatient).side(1).preOP.controlateral.internalRotation.pain = [];
                        end
                    elseif contains(Patient(ipatient).Session(isession).data.Session.objective,'post-opératoire')
                        % PostOP            
                        Outcomes.Patient(ipatient).side(1).postOP.date = Patient(ipatient).Session(isession).data.Session.date;
                        % Humerothoracic maximum angle
                        Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.flexion.HTmax = [];
                        Outcomes.Patient(ipatient).side(1).postOP.controlateral.flexion.HTmax = [];
                        Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.abduction.HTmax = [];
                        Outcomes.Patient(ipatient).side(1).postOP.controlateral.abduction.HTmax = [];
                        Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.externalRotation.HTmax = [];
                        Outcomes.Patient(ipatient).side(1).postOP.controlateral.externalRotation.HTmax = [];
                        Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.internalRotation.HTmax = [];
                        Outcomes.Patient(ipatient).side(1).postOP.controlateral.internalRotation.HTmax = [];
                        if isfield(Patient(ipatient).Session(isession).data,'Trial')
                            if ~isempty(Patient(ipatient).Session(isession).data.Trial)
                                for itrial = 1:size(Patient(ipatient).Session(isession).data.Trial,2)
                                    if contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC1')
                                        Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.flexion.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,3,:)))); % Flexion: itrial = 1, right HT: ijoint = 1, Angle of interest: ieuler = 3
                                        Outcomes.Patient(ipatient).side(1).postOP.controlateral.flexion.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,3,:)))); % Flexion: itrial = 1, left HT: ijoint = 6, Angle of interest: ieuler = 3
                                    elseif contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC2')
                                        Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.abduction.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,1,:)))); % Abduction: itrial = 2, right HT: ijoint = 1, Angle of interest: ieuler = 1
                                        Outcomes.Patient(ipatient).side(1).postOP.controlateral.abduction.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,1,:)))); % Abduction: itrial = 2, left HT: ijoint = 6, Angle of interest: ieuler = 1
                                    elseif contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC3')
                                        if ceil(min((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))) < -10 % sign error detected 
                                            Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.externalRotation.HTmax = ceil(max(-(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))); % External rotation: itrial = 3, right HT: ijoint = 1, Angle of interest: ieuler = 2
                                        else
                                            Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.externalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))); % External rotation: itrial = 3, right HT: ijoint = 1, Angle of interest: ieuler = 2
                                        end
                                        if ceil(min((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))) < -10 % sign error detected 
                                            Outcomes.Patient(ipatient).side(1).postOP.controlateral.externalRotation.HTmax = ceil(max(-(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))); % External rotation: itrial = 3, left HT: ijoint = 6, Angle of interest: ieuler = 2
                                        else
                                            Outcomes.Patient(ipatient).side(1).postOP.controlateral.externalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))); % External rotation: itrial = 3, left HT: ijoint = 6, Angle of interest: ieuler = 2
                                        end
                                    elseif contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC4')
                                        Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.internalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))); % Internal rotation: itrial = 4, right HT: ijoint = 1, Angle of interest: ieuler = 2
                                        Outcomes.Patient(ipatient).side(1).postOP.controlateral.internalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))); % Internal rotation: itrial = 4, left HT: ijoint = 6, Angle of interest: ieuler = 2
                                    end
                                end
                            end
                        end
                        % Pain
                        if isfield(Patient(ipatient).Session(isession).data.Session.Pain,'Rvalue')
                            if ~isempty(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue)
                                Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.flexion.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(4));
                                Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.abduction.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(5));
                                Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.externalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(6));
                                Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.internalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(7));
                            else
                                Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.flexion.pain = [];
                                Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.abduction.pain = [];
                                Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.externalRotation.pain = [];
                                Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.internalRotation.pain = [];
                            end
                            if ~isempty(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue)
                                Outcomes.Patient(ipatient).side(1).postOP.controlateral.flexion.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(4));
                                Outcomes.Patient(ipatient).side(1).postOP.controlateral.abduction.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(5));
                                Outcomes.Patient(ipatient).side(1).postOP.controlateral.externalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(6));
                                Outcomes.Patient(ipatient).side(1).postOP.controlateral.internalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(7));
                            else
                                Outcomes.Patient(ipatient).side(1).postOP.controlateral.flexion.pain = [];
                                Outcomes.Patient(ipatient).side(1).postOP.controlateral.abduction.pain = [];
                                Outcomes.Patient(ipatient).side(1).postOP.controlateral.externalRotation.pain = [];
                                Outcomes.Patient(ipatient).side(1).postOP.controlateral.internalRotation.pain = [];
                            end
                        else
                            Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.flexion.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(4));
                            Outcomes.Patient(ipatient).side(1).postOP.controlateral.flexion.pain = [];
                            Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.abduction.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(5));
                            Outcomes.Patient(ipatient).side(1).postOP.controlateral.abduction.pain = [];
                            Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.externalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(6));
                            Outcomes.Patient(ipatient).side(1).postOP.controlateral.externalRotation.pain = [];
                            Outcomes.Patient(ipatient).side(1).postOP.ipsilateral.internalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(7));
                            Outcomes.Patient(ipatient).side(1).postOP.controlateral.internalRotation.pain = [];
                        end
                    end
                elseif contains(Patient(ipatient).Session(isession).data.Pathology.Diagnosis.side,'Gauche')
                    if contains(Patient(ipatient).Session(isession).data.Session.objective,'pré-opératoire')
                        % PreOP            
                        Outcomes.Patient(ipatient).side(2).preOP.date = Patient(ipatient).Session(isession).data.Session.date;
                        % Humerothoracic maximum angle
                        Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.flexion.HTmax = [];
                        Outcomes.Patient(ipatient).side(2).preOP.controlateral.flexion.HTmax = [];
                        Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.abduction.HTmax = [];
                        Outcomes.Patient(ipatient).side(2).preOP.controlateral.abduction.HTmax = [];
                        Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.externalRotation.HTmax = [];
                        Outcomes.Patient(ipatient).side(2).preOP.controlateral.externalRotation.HTmax = [];
                        Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.internalRotation.HTmax = [];
                        Outcomes.Patient(ipatient).side(2).preOP.controlateral.internalRotation.HTmax = [];
                        if isfield(Patient(ipatient).Session(isession).data,'Trial')
                            if ~isempty(Patient(ipatient).Session(isession).data.Trial)
                                for itrial = 1:size(Patient(ipatient).Session(isession).data.Trial,2)
                                    if contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC1')
                                        Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.flexion.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,3,:)))); % Flexion: itrial = 1, right HT: ijoint = 1, Angle of interest: ieuler = 3
                                        Outcomes.Patient(ipatient).side(2).preOP.controlateral.flexion.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,3,:)))); % Flexion: itrial = 1, left HT: ijoint = 6, Angle of interest: ieuler = 3
                                    elseif contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC2')
                                        Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.abduction.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,1,:)))); % Abduction: itrial = 2, right HT: ijoint = 1, Angle of interest: ieuler = 1
                                        Outcomes.Patient(ipatient).side(2).preOP.controlateral.abduction.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,1,:)))); % Abduction: itrial = 2, left HT: ijoint = 6, Angle of interest: ieuler = 1
                                    elseif contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC3')
                                        if ceil(min((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))) < -10 % sign error detected 
                                            Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.externalRotation.HTmax = ceil(max(-(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))); % External rotation: itrial = 3, right HT: ijoint = 1, Angle of interest: ieuler = 2
                                        else
                                            Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.externalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))); % External rotation: itrial = 3, right HT: ijoint = 1, Angle of interest: ieuler = 2
                                        end
                                        if ceil(min((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))) < -10 % sign error detected 
                                            Outcomes.Patient(ipatient).side(2).preOP.controlateral.externalRotation.HTmax = ceil(max(-(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))); % External rotation: itrial = 3, left HT: ijoint = 6, Angle of interest: ieuler = 2
                                        else
                                            Outcomes.Patient(ipatient).side(2).preOP.controlateral.externalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))); % External rotation: itrial = 3, left HT: ijoint = 6, Angle of interest: ieuler = 2
                                        end
                                    elseif contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC4')
                                        Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.internalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))); % Internal rotation: itrial = 4, right HT: ijoint = 1, Angle of interest: ieuler = 2
                                        Outcomes.Patient(ipatient).side(2).preOP.controlateral.internalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))); % Internal rotation: itrial = 4, left HT: ijoint = 6, Angle of interest: ieuler = 2
                                    end
                                end
                            end
                        end
                        % Pain
                        if isfield(Patient(ipatient).Session(isession).data.Session.Pain,'Rvalue')
                            if ~isempty(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue)
                                Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.flexion.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(4));
                                Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.abduction.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(5));
                                Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.externalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(6));
                                Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.internalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(7));
                            else
                                Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.flexion.pain = [];
                                Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.abduction.pain = [];
                                Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.externalRotation.pain = [];
                                Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.internalRotation.pain = [];
                            end
                            if ~isempty(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue)
                                Outcomes.Patient(ipatient).side(2).preOP.controlateral.flexion.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(4));
                                Outcomes.Patient(ipatient).side(2).preOP.controlateral.abduction.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(5));
                                Outcomes.Patient(ipatient).side(2).preOP.controlateral.externalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(6));
                                Outcomes.Patient(ipatient).side(2).preOP.controlateral.internalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(7));
                            else
                                Outcomes.Patient(ipatient).side(2).preOP.controlateral.flexion.pain = [];
                                Outcomes.Patient(ipatient).side(2).preOP.controlateral.abduction.pain = [];
                                Outcomes.Patient(ipatient).side(2).preOP.controlateral.externalRotation.pain = [];
                                Outcomes.Patient(ipatient).side(2).preOP.controlateral.internalRotation.pain = [];
                            end
                        else
                            Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.flexion.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(4));
                            Outcomes.Patient(ipatient).side(2).preOP.controlateral.flexion.pain = [];
                            Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.abduction.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(5));
                            Outcomes.Patient(ipatient).side(2).preOP.controlateral.abduction.pain = [];
                            Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.externalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(6));
                            Outcomes.Patient(ipatient).side(2).preOP.controlateral.externalRotation.pain = [];
                            Outcomes.Patient(ipatient).side(2).preOP.ipsilateral.internalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(7));
                            Outcomes.Patient(ipatient).side(2).preOP.controlateral.internalRotation.pain = [];
                        end
                    elseif contains(Patient(ipatient).Session(isession).data.Session.objective,'post-opératoire')
                        % PostOP            
                        Outcomes.Patient(ipatient).side(2).postOP.date = Patient(ipatient).Session(isession).data.Session.date;
                        % Humerothoracic maximum angle
                        Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.flexion.HTmax = [];
                        Outcomes.Patient(ipatient).side(2).postOP.controlateral.flexion.HTmax = [];
                        Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.abduction.HTmax = [];
                        Outcomes.Patient(ipatient).side(2).postOP.controlateral.abduction.HTmax = [];
                        Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.externalRotation.HTmax = [];
                        Outcomes.Patient(ipatient).side(2).postOP.controlateral.externalRotation.HTmax = [];
                        Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.internalRotation.HTmax = [];
                        Outcomes.Patient(ipatient).side(2).postOP.controlateral.internalRotation.HTmax = [];
                        if isfield(Patient(ipatient).Session(isession).data,'Trial')
                            if ~isempty(Patient(ipatient).Session(isession).data.Trial)
                                for itrial = 1:size(Patient(ipatient).Session(isession).data.Trial,2)
                                    if contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC1')
                                        Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.flexion.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,3,:)))); % Flexion: itrial = 1, right HT: ijoint = 1, Angle of interest: ieuler = 3
                                        Outcomes.Patient(ipatient).side(2).postOP.controlateral.flexion.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,3,:)))); % Flexion: itrial = 1, left HT: ijoint = 6, Angle of interest: ieuler = 3
                                    elseif contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC2')
                                        Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.abduction.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,1,:)))); % Abduction: itrial = 2, right HT: ijoint = 1, Angle of interest: ieuler = 1
                                        Outcomes.Patient(ipatient).side(2).postOP.controlateral.abduction.HTmax = ceil(max(abs(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,1,:)))); % Abduction: itrial = 2, left HT: ijoint = 6, Angle of interest: ieuler = 1
                                    elseif contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC3')
                                        if ceil(min((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))) < -10 % sign error detected 
                                            Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.externalRotation.HTmax = ceil(max(-(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))); % External rotation: itrial = 3, right HT: ijoint = 1, Angle of interest: ieuler = 2
                                        else
                                            Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.externalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))); % External rotation: itrial = 3, right HT: ijoint = 1, Angle of interest: ieuler = 2
                                        end
                                        if ceil(min((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))) < -10 % sign error detected 
                                            Outcomes.Patient(ipatient).side(2).postOP.controlateral.externalRotation.HTmax = ceil(max(-(Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))); % External rotation: itrial = 3, left HT: ijoint = 6, Angle of interest: ieuler = 2
                                        else
                                            Outcomes.Patient(ipatient).side(2).postOP.controlateral.externalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))); % External rotation: itrial = 3, left HT: ijoint = 6, Angle of interest: ieuler = 2
                                        end
                                    elseif contains(Patient(ipatient).Session(isession).data.Trial(itrial).task,'ANALYTIC4')
                                        Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.internalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(6).Euler.full(:,2,:)))); % Internal rotation: itrial = 4, right HT: ijoint = 1, Angle of interest: ieuler = 2
                                        Outcomes.Patient(ipatient).side(2).postOP.controlateral.internalRotation.HTmax = ceil(max((Patient(ipatient).Session(isession).data.Trial(itrial).Joint(1).Euler.full(:,2,:)))); % Internal rotation: itrial = 4, left HT: ijoint = 6, Angle of interest: ieuler = 2
                                    end
                                end
                            end
                        end
                        % Pain
                        if isfield(Patient(ipatient).Session(isession).data.Session.Pain,'Rvalue')
                            if ~isempty(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue)
                                Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.flexion.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(4));
                                Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.abduction.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(5));
                                Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.externalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(6));
                                Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.internalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Lvalue(7));
                            else
                                Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.flexion.pain = [];
                                Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.abduction.pain = [];
                                Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.externalRotation.pain = [];
                                Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.internalRotation.pain = [];
                            end
                            if ~isempty(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue)
                                Outcomes.Patient(ipatient).side(2).postOP.controlateral.flexion.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(4));
                                Outcomes.Patient(ipatient).side(2).postOP.controlateral.abduction.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(5));
                                Outcomes.Patient(ipatient).side(2).postOP.controlateral.externalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(6));
                                Outcomes.Patient(ipatient).side(2).postOP.controlateral.internalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.Rvalue(7));
                            else
                                Outcomes.Patient(ipatient).side(2).postOP.controlateral.flexion.pain = [];
                                Outcomes.Patient(ipatient).side(2).postOP.controlateral.abduction.pain = [];
                                Outcomes.Patient(ipatient).side(2).postOP.controlateral.externalRotation.pain = [];
                                Outcomes.Patient(ipatient).side(2).postOP.controlateral.internalRotation.pain = [];
                            end
                        else
                            Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.flexion.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(4));
                            Outcomes.Patient(ipatient).side(2).postOP.controlateral.flexion.pain = [];
                            Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.abduction.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(5));
                            Outcomes.Patient(ipatient).side(2).postOP.controlateral.abduction.pain = [];
                            Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.externalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(6));
                            Outcomes.Patient(ipatient).side(2).postOP.controlateral.externalRotation.pain = [];
                            Outcomes.Patient(ipatient).side(2).postOP.ipsilateral.internalRotation.pain = ceil(Patient(ipatient).Session(isession).data.Session.Pain.value(7));
                            Outcomes.Patient(ipatient).side(2).postOP.controlateral.internalRotation.pain = [];
                        end
                    end
                end
            end
        end
    end
end

%% ------------------------------------------------------------------------
% ORDER OPERATED SIDES
% -------------------------------------------------------------------------
for ipatient = 1:size(Patient,2)
    % Find back right order of EDS
    if ~isempty(Outcomes.Patient(ipatient).side(1).preOP)
        if isfield(Outcomes.Patient(ipatient).side(1).preOP,'date')
            d1 = Outcomes.Patient(ipatient).side(1).preOP.date;
        else
            d1 = [];
        end
    else
        d1 = [];
    end
    if ~isempty(Outcomes.Patient(ipatient).side(1).postOP)
        if isfield(Outcomes.Patient(ipatient).side(1).postOP,'date')
            d2 = Outcomes.Patient(ipatient).side(1).postOP.date;
        else
            d2 = [];
        end
    else
        d2 = [];
    end
    if ~isempty(Outcomes.Patient(ipatient).side(2).preOP)        
        if isfield(Outcomes.Patient(ipatient).side(2).preOP,'date')
            d3 = Outcomes.Patient(ipatient).side(2).preOP.date;
        else
            d3 = [];
        end
    else
        d3 = [];
    end
    if ~isempty(Outcomes.Patient(ipatient).side(2).postOP)
        if isfield(Outcomes.Patient(ipatient).side(2).postOP,'date')
            d4 = Outcomes.Patient(ipatient).side(2).postOP.date;
        else
            d4 = [];
        end
    else
        d4 = [];
    end
    dates = {d1, 'side(1).preOP'; 
             d2, 'side(1).postOP'; 
             d3, 'side(2).preOP'; 
             d4, 'side(2).postOP'};
    valid_idx = ~cellfun(@isempty, dates(:,1));
    valid_dates = dates(valid_idx, :);
    dt = vertcat(valid_dates{:,1});
    [sorted_dt, sort_idx] = sort(dt);
    sorted_dates_with_labels = valid_dates(sort_idx, :);
    % Reorder sides per date of surgery
    Outcomes2.Patient(ipatient).ID = Outcomes.Patient(ipatient).ID;
    if isempty(sorted_dates_with_labels)
        Outcomes2.Patient(ipatient).side(1) = Outcomes.Patient(ipatient).side(1);
        Outcomes2.Patient(ipatient).side(2) = Outcomes.Patient(ipatient).side(2);
    else
        if contains(sorted_dates_with_labels{1,2},'side(1)') % side1 first
            Outcomes2.Patient(ipatient).side(1) = Outcomes.Patient(ipatient).side(1);
            Outcomes2.Patient(ipatient).side(2) = Outcomes.Patient(ipatient).side(2);
        elseif contains(sorted_dates_with_labels{1,2},'side(2)') % side2 first
            Outcomes2.Patient(ipatient).side(1) = Outcomes.Patient(ipatient).side(2);
            Outcomes2.Patient(ipatient).side(2) = Outcomes.Patient(ipatient).side(1);
        end
    end
end

%% ------------------------------------------------------------------------
% STORE DATA IN REPORT FILE
% -------------------------------------------------------------------------
cd(Folder.outcomes); % 'Registre_extract_klab_20250512.xlsx'
for ipatient1 = range
    for ipatient2 = 1:size(Patient,2)
        if Outcomes.Patient(ipatient2).ID == cell2mat(patientList(ipatient1,2))
            data{ipatient1-1,1} = Outcomes2.Patient(ipatient2).ID;
            if ~isempty(Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP)
                data{ipatient1-1,2} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).label;
                data{ipatient1-1,3} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP.date;
                if isfield(Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP,'ipsilateral')
                    data{ipatient1-1,4} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP.ipsilateral.flexion.HTmax;
                    data{ipatient1-1,5} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP.controlateral.flexion.HTmax;
                    data{ipatient1-1,6} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP.ipsilateral.flexion.pain;
                    data{ipatient1-1,7} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP.ipsilateral.abduction.HTmax;
                    data{ipatient1-1,8} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP.controlateral.abduction.HTmax;
                    data{ipatient1-1,9} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP.ipsilateral.abduction.pain;
                    data{ipatient1-1,10} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP.ipsilateral.externalRotation.HTmax;
                    data{ipatient1-1,11} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP.controlateral.externalRotation.HTmax;
                    data{ipatient1-1,12} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP.ipsilateral.externalRotation.pain;
                    data{ipatient1-1,13} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP.ipsilateral.internalRotation.HTmax;
                    data{ipatient1-1,14} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP.controlateral.internalRotation.HTmax;
                    data{ipatient1-1,15} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).preOP.ipsilateral.internalRotation.pain;
                end
            end
            if ~isempty(Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP)
                data{ipatient1-1,2} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).label;
                data{ipatient1-1,16} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP.date;
                if isfield(Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP,'ipsilateral')
                    data{ipatient1-1,17} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP.ipsilateral.flexion.HTmax;
                    data{ipatient1-1,18} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP.controlateral.flexion.HTmax;
                    data{ipatient1-1,19} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP.ipsilateral.flexion.pain;
                    data{ipatient1-1,20} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP.ipsilateral.abduction.HTmax;
                    data{ipatient1-1,21} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP.controlateral.abduction.HTmax;
                    data{ipatient1-1,22} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP.ipsilateral.abduction.pain;
                    data{ipatient1-1,23} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP.ipsilateral.externalRotation.HTmax;
                    data{ipatient1-1,24} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP.controlateral.externalRotation.HTmax;
                    data{ipatient1-1,25} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP.ipsilateral.externalRotation.pain;
                    data{ipatient1-1,26} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP.ipsilateral.internalRotation.HTmax;
                    data{ipatient1-1,27} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP.controlateral.internalRotation.HTmax;
                    data{ipatient1-1,28} = Outcomes2.Patient(ipatient2).side(Patient(ipatient2).iside).postOP.ipsilateral.internalRotation.pain;
                end
            end
            Patient(ipatient2).iside = Patient(ipatient2).iside+1;
        end
    end
end

writecell(data, 'mon_fichier.csv');

%% ------------------------------------------------------------------------
% PLOT / OPERATED SIDE
% -------------------------------------------------------------------------

% === Étape 1 : Lecture et nettoyage ===
filename = 'Registre_extract_klab_20250512.xlsx';
T = readtable(filename);
T.Properties.VariableNames = strrep(T.Properties.VariableNames, '.', '_');
T.Properties.VariableNames = strrep(T.Properties.VariableNames, ' ', '_');

% === Étape 2 : Conversion des colonnes utiles ===
vars_to_convert = {
    'klab_flexion_max_operated_3', 'klab_flexion_pain_3', ...
    'klab_flexion_max_operated_5', 'klab_flexion_pain_5', ...
    'klab_abduction_max_operated_3', 'klab_abduction_pain_3', ...
    'klab_abduction_max_operated_5', 'klab_abduction_pain_5', ...
    'klab_externalRotation_max_operated_3', 'klab_externalRotation_pain_3', ...
    'klab_externalRotation_max_operated_5', 'klab_externalRotation_pain_5', ...
    'klab_internalRotation_max_operated_3', 'klab_internalRotation_pain_3', ...
    'klab_internalRotation_max_operated_5', 'klab_internalRotation_pain_5'
};
for i = 1:length(vars_to_convert)
    if ismember(vars_to_convert{i}, T.Properties.VariableNames)
        T.(vars_to_convert{i}) = str2double(string(T.(vars_to_convert{i})));
    else
        warning('Colonne manquante : %s', vars_to_convert{i});
    end
end

% === Étape 3 : Données PREOP ===
flexion_amp_pre     = T.klab_flexion_max_operated_3;
flexion_pain_pre    = T.klab_flexion_pain_3;
abduction_amp_pre   = T.klab_abduction_max_operated_3;
abduction_pain_pre  = T.klab_abduction_pain_3;
external_amp_pre    = T.klab_externalRotation_max_operated_3;
external_pain_pre   = T.klab_externalRotation_pain_3;
internal_amp_pre    = T.klab_internalRotation_max_operated_3;
internal_pain_pre   = T.klab_internalRotation_pain_3;

% === Étape 4 : Données POSTOP ===
flexion_amp_post     = T.klab_flexion_max_operated_5;
flexion_pain_post    = T.klab_flexion_pain_5;
abduction_amp_post   = T.klab_abduction_max_operated_5;
abduction_pain_post  = T.klab_abduction_pain_5;
external_amp_post    = T.klab_externalRotation_max_operated_5;
external_pain_post   = T.klab_externalRotation_pain_5;
internal_amp_post    = T.klab_internalRotation_max_operated_5;
internal_pain_post   = T.klab_internalRotation_pain_5;

% === Étape 5 : Données DELTA (POSTOP - PREOP)
flexion_amp_delta     = flexion_amp_post - flexion_amp_pre;
flexion_pain_delta    = flexion_pain_post - flexion_pain_pre;
abduction_amp_delta   = abduction_amp_post - abduction_amp_pre;
abduction_pain_delta  = abduction_pain_post - abduction_pain_pre;
external_amp_delta    = external_amp_post - external_amp_pre;
external_pain_delta   = external_pain_post - external_pain_pre;
internal_amp_delta    = internal_amp_post - internal_amp_pre;
internal_pain_delta   = internal_pain_post - internal_pain_pre;

% === Étape 6 : Filtres valides pour chaque jeu de données
valid_flexion_delta   = ~isnan(flexion_amp_delta)   & ~isnan(flexion_pain_delta);
valid_abduction_delta = ~isnan(abduction_amp_delta) & ~isnan(abduction_pain_delta);
valid_external_delta  = ~isnan(external_amp_delta)  & ~isnan(external_pain_delta);
valid_internal_delta  = ~isnan(internal_amp_delta)  & ~isnan(internal_pain_delta);

valid_flexion_pre     = ~isnan(flexion_amp_pre)     & ~isnan(flexion_pain_pre);
valid_abduction_pre   = ~isnan(abduction_amp_pre)   & ~isnan(abduction_pain_pre);
valid_external_pre    = ~isnan(external_amp_pre)    & ~isnan(external_pain_pre);
valid_internal_pre    = ~isnan(internal_amp_pre)    & ~isnan(internal_pain_pre);

valid_flexion_post    = ~isnan(flexion_amp_post)    & ~isnan(flexion_pain_post);
valid_abduction_post  = ~isnan(abduction_amp_post)  & ~isnan(abduction_pain_post);
valid_external_post   = ~isnan(external_amp_post)   & ~isnan(external_pain_post);
valid_internal_post   = ~isnan(internal_amp_post)   & ~isnan(internal_pain_post);

% === Tracés DELTA POSTOP – PREOP ===
figure('Color', 'white');

subplot(2,2,1);
n = sum(valid_flexion_delta);
scatter(-flexion_pain_delta(valid_flexion_delta), flexion_amp_delta(valid_flexion_delta), 'filled');
xlabel('Δ Douleur (+ diminution)'); ylabel('Δ Amplitude (+ augmentation)');
title(sprintf('Flexion (n = %d)', n));
xline(0,'--'); yline(0,'--'); axis([-10 10 -90 90]); grid on; box on;
xticks(-10:2:10); yticks(-90:20:90);

subplot(2,2,2);
n = sum(valid_abduction_delta);
scatter(-abduction_pain_delta(valid_abduction_delta), abduction_amp_delta(valid_abduction_delta), 'filled');
xlabel('Δ Douleur (+ diminution)'); ylabel('Δ Amplitude (+ augmentation)');
title(sprintf('Abduction (n = %d)', n));
xline(0,'--'); yline(0,'--'); axis([-10 10 -90 90]); grid on; box on;
xticks(-10:2:10); yticks(-90:20:90);

subplot(2,2,3);
n = sum(valid_external_delta);
scatter(-external_pain_delta(valid_external_delta), external_amp_delta(valid_external_delta), 'filled');
xlabel('Δ Douleur (+ diminution)'); ylabel('Δ Amplitude (+ augmentation)');
title(sprintf('Rotation externe (n = %d)', n));
xline(0,'--'); yline(0,'--'); axis([-10 10 -90 90]); grid on; box on;
xticks(-10:2:10); yticks(-90:20:90);

subplot(2,2,4);
n = sum(valid_internal_delta);
scatter(-internal_pain_delta(valid_internal_delta), internal_amp_delta(valid_internal_delta), 'filled');
xlabel('Δ Douleur (+ diminution)'); ylabel('Δ Amplitude (+ augmentation)');
title(sprintf('Rotation interne (n = %d)', n));
xline(0,'--'); yline(0,'--'); axis([-10 10 -90 90]); grid on; box on;
xticks(-10:2:10); yticks(-90:20:90);

sgtitle('Évolution PostOP - PreOP : amplitude et douleur');

% === Tracés PREOP absolu ===
figure('Color', 'white');

for i = 1:4
    subplot(2,2,i);
    
    amp_list = {flexion_amp_pre, abduction_amp_pre, external_amp_pre, internal_amp_pre};
    pain_list = {flexion_pain_pre, abduction_pain_pre, external_pain_pre, internal_pain_pre};
    thresholds_list = {[0 90 120 150], [0 90 120 150], [0 20 30 50], [0 20 30 50]};
    movement_names = {'Flexion', 'Abduction', 'Rotation externe', 'Rotation interne'};

    amp = amp_list{i};
    pain = pain_list{i};
    thresholds = thresholds_list{i};

    valid = ~isnan(amp) & ~isnan(pain);
    amp = amp(valid);
    pain = pain(valid);
    n = sum(valid);

    colors = get_color(amp, thresholds);
    sizes = arrayfun(get_marker_size, pain);

    hold on;
    for j = 1:length(amp)
        scatter(pain(j), amp(j), sizes(j), 'filled', 'MarkerFaceColor', colors{j});
    end

    xlabel('Douleur preOP (EVA)');
    ylabel('Amplitude preOP (°)');
    title(sprintf('%s (n = %d)', movement_names{i}, n));
    axis([0 10 0 180]); xticks(0:2:10); yticks(0:20:180); grid on; box on;
end

sgtitle('PreOP : amplitude articulaire vs douleur');

% === Tracés POSTOP absolu ===
figure('Color', 'white');

for i = 1:4
    subplot(2,2,i);
    
    amp_list = {flexion_amp_post, abduction_amp_post, external_amp_post, internal_amp_post};
    pain_list = {flexion_pain_post, abduction_pain_post, external_pain_post, internal_pain_post};
    thresholds_list = {[0 90 120 150], [0 90 120 150], [0 20 30 50], [0 20 30 50]};
    movement_names = {'Flexion', 'Abduction', 'Rotation externe', 'Rotation interne'};

    amp = amp_list{i};
    pain = pain_list{i};
    thresholds = thresholds_list{i};

    valid = ~isnan(amp) & ~isnan(pain);
    amp = amp(valid);
    pain = pain(valid);
    n = sum(valid);

    colors = get_color(amp, thresholds);
    sizes = arrayfun(get_marker_size, pain);

    hold on;
    for j = 1:length(amp)
        scatter(pain(j), amp(j), sizes(j), 'filled', 'MarkerFaceColor', colors{j});
    end

    xlabel('Douleur postOP (EVA)');
    ylabel('Amplitude postOP (°)');
    title(sprintf('%s (n = %d)', movement_names{i}, n));
    axis([0 10 0 180]); xticks(0:2:10); yticks(0:20:180); grid on; box on;
end

sgtitle('PostOP : amplitude articulaire vs douleur');

%% ------------------------------------------------------------------------
% FUNCTIONS
% -------------------------------------------------------------------------
get_color = @(amp, seuils) cellfun(@(a) pick_color(a, seuils), num2cell(amp), 'UniformOutput', false);

get_marker_size = @(pain) ...
    (pain <= 3) * 100 + ...
    (pain > 3 & pain <= 6) * 60 + ...
    (pain > 6) * 20;

function rgb = pick_color(a, seuils)
    if a > seuils(4)
        rgb = [0 0.6 0];       % Vert
    elseif a > seuils(3)
        rgb = [1 1 0];         % Jaune
    elseif a > seuils(2)
        rgb = [1 0.5 0];       % Orange
    else
        rgb = [1 0 0];         % Rouge
    end
end