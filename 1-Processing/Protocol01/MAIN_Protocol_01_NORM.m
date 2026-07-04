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
% Description:   MAIN routine for the instrumented Constant Shoulder Test
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% INIT WORKSPACE
% -------------------------------------------------------------------------
tic
clearvars;
close all;
warning off;
clc;
disp('------------------------------------------------------------------');
disp('KLAB_UpperLimb_toolbox');
disp('Protocole 1 - Norme');
disp('Auteur : F. Moissenet');
disp('Version : 2 (July 2024)');
disp('------------------------------------------------------------------');
disp(' ');

% -------------------------------------------------------------------------
% SET PARTICIPANT
% -------------------------------------------------------------------------
participantID = 'LP27';

% -------------------------------------------------------------------------
% SET FOLDERS
% -------------------------------------------------------------------------
disp('Définition des répertoires de travail');
MainFolder           = 'C:\Users\Florent\OneDrive - Université de Genève\';
Folder.preprocessing = [MainFolder,'_CLINIQUE\Matlab\KLAB_ShoulderAnalysis_Toolbox\0-Preprocessing\'];
Folder.toolbox       = [MainFolder,'_CLINIQUE\Matlab\KLAB_ShoulderAnalysis_Toolbox\1-Processing\Protocol01\'];
Folder.data          = [MainFolder,'_CLINIQUE\Données\KLAB-UPPERLIMB-PROTOCOL01\Data\_NORME\Lyon_STAPS\'];
Folder.dependencies  = [MainFolder,'_CLINIQUE\Matlab\KLAB_ShoulderAnalysis_Toolbox\1-Processing\dependencies\'];
addpath(genpath(Folder.dependencies));
cd([Folder.data,participantID])
disp(' ');

% -------------------------------------------------------------------------
% GET SESSION DATA
% -------------------------------------------------------------------------
disp('Récupération des informations de la session');
addpath(Folder.toolbox);
[Patient,Session,Pathology] = ImportSessionData_NORM(participantID);
rmpath(Folder.toolbox);
disp(['  - Patient   : ',num2str(Patient.ID)]);
disp(' ');

% -------------------------------------------------------------------------
% PRE-PROCESS DATA
% -------------------------------------------------------------------------
% - Markers: fill gap (intercor), smoothing (movmean)
% - EMG: zeroing (mean), filtering (btw bandpass 4th order 30-450 Hz)
% - Force: smoothing (btw lowpass 2nd order 10 Hz)
% -------------------------------------------------------------------------
disp('Pré-traitement des données');
% if ~isfolder('Processed')
    addpath(Folder.preprocessing);
    MAIN_Preprocessing_toolbox_NORM(Patient.ID,Session.ID,Session.date,Session.protocol,Folder.preprocessing,[Folder.data,participantID,'\Raw\']);
    rmpath(Folder.preprocessing);
% end
addpath(Folder.toolbox);
cd(Folder.toolbox);

% -------------------------------------------------------------------------
% PROCESS DATA
% -------------------------------------------------------------------------
% Get user commands
cd(Folder.preprocessing);
txtFile      = 'userCommands_normative.txt';
userCommands = fileread(txtFile);
eval(userCommands);
% Load data
cd([Folder.data,participantID,'\Processed\']);
c3dFiles   = dir('*.c3d');
trialTypes = {'CALIBRATION','ANALYTIC','FUNCTIONAL'};
k          = 1;
%%
for i = [8,6,7,1,2,3,4,5] % [7,5,6,1,2,3,4] WARNING CHANGE ALSO INDEX AT LINE 153
    for j = 1:size(trialTypes,2)
        if contains(c3dFiles(i).name,trialTypes{j})  
            disp(' ');
            % Extract data from C3D files 
            if contains(c3dFiles(i).name,'CALIBRATION')
                Trial(k).task    = c3dFiles(i).name(end-16:end-5);
            elseif contains(c3dFiles(i).name,'ANALYTIC')
                Trial(k).task    = c3dFiles(i).name(end-13:end-5);
            elseif contains(c3dFiles(i).name,'FUNCTIONAL')
                Trial(k).task    = c3dFiles(i).name(end-15:end-5);
            end
            Trial(k).file        = c3dFiles(i).name;
            Trial(k).btk         = btkReadAcquisition(c3dFiles(i).name);
            Trial(k).n0          = btkGetFirstFrame(Trial(k).btk);
            Trial(k).n1          = btkGetLastFrame(Trial(k).btk)-Trial(k).n0+1;
            Trial(k).fmarker     = btkGetPointFrequency(Trial(k).btk);
            Trial(k).fanalog     = btkGetAnalogFrequency(Trial(k).btk);       
            disp(['Chargement du fichier : ',Trial(k).task]);
            % Set units
            Units                = SetUnits(Trial);
            % Import events
            Event                = btkGetEvents(Trial(k).btk);
            % Import marker trajectories
            Marker               = btkGetMarkers(Trial(k).btk);
            Trial(k).Marker      = [];
            Trial(k)             = InitialiseMarkerTrajectories(markerSet,Trial(k),Marker,Units);
            % Initialise virtual marker trajectories
            Trial(k).Vmarker     = [];
            Trial(k)             = InitialiseVmarkerTrajectories(Trial(k));            
            % Add pointed landmarks as virtual markers
%             pointList            = {'SXS'}; % List of virtual markers pointed with stylus (the order must be the same than the events stored in C3D file)
            if contains(c3dFiles(i).name,'CALIBRATION3')
                Vmarker          = [];
            end
%             [Trial(k),Vmarker]   = AddPointedLandmarks(Trial(k),Marker,Vmarker,Event,pointList,'Stylusb');
            % Add acromial cluster landmarks as virtual markers
            [Trial(k),Vmarker]   = AddACMLandmarks(Session,Trial(k),Marker,Vmarker);
            % Import force data
            Trial(k).Fsensor     = [];
            mass                 = 4; % (kg) Mass used for calibration
            Analog               = btkGetAnalogs(Trial(k).btk);
            if strcmp(Trial(k).task,'CALIBRATION5') || strcmp(Trial(k).task,'CALIBRATION6')
                calibration      = Trial(2).Fsensor.calibration; % from CALIBRATION4
            else
                calibration      = [];
            end
            Trial(k)             = InitialiseForceSignals(c3dFiles(i),Trial(k),Analog,Event,mass,calibration);
            % Import EMG signals
            Trial(k).Emg         = [];
            if strcmp(Trial(k).task,'CALIBRATION3')                
                Trial(k)         = InitialiseEmgSignals(emgSet,Trial(k),[],Analog);
            else                
                Trial(k)         = InitialiseEmgSignals(emgSet,Trial(k),Trial(1),Analog); % Load Trial(1) as reference baseline container
            end
            % Manage kinematics
            Trial(k).Segment     = [];
            Trial(k).Joint       = [];
            Trial(k).Rcycle      = [];
            Trial(k).Lcycle      = [];
            Trial(k).SHR         = [];
            if i ~= 8 % 7
                % Initialise segments
                Trial(k)         = InitialiseSegments(Trial(k));
                % Initialise joints
                Trial(k)         = InitialiseJoints(Trial(k));
                % Define body segments (and joint centres)
                Trial(k)         = DefineSegments(c3dFiles(i),Session,Trial(k));   
                % Compute inverse kinematics
                Trial(k)         = ComputeKinematics(c3dFiles(i),Trial(k));
                % Define and cut movement cycles
                % Based on humerothoracic kinematics
                figure;       
                btype            = 2; % Manual baseline selection
                Trial(k)         = CutCycles(c3dFiles(i),Trial(k),btype);
                % Compute SHR
                if i == 1 || i == 2 || i == 5 
                    Trial(k)     = ComputeSHR(c3dFiles(i),Trial(k),Trial(k)); % Last input is the reference position used for SHR computation
                end
                close all;
            end
            % Update C3D files
            UpdateC3DFile(Trial(k),c3dFiles(i));
            % Increment trial index
            k                    = k+1;
        end
    end
end
%%
% -------------------------------------------------------------------------
% GENERATE REPORT
% -------------------------------------------------------------------------
disp('Génération du rapport');
% cd(Folder.data);
% mkdir('Report');
% cd('Report');
% close all;
% if isempty(dir('*.docx'))
%     copyfile([Folder.toolbox,'Report\KLAB - Analyse quantifiée du membre supérieur - Rapport - Template.docx'],[Folder.data,'\Report\',num2str(Patient.ID),'-',Session.ID,'-',datestr(Session.date,'YYYYmmDD'),'-Rapport.docx']);
%     copyfile([Folder.toolbox,'Report\Skeleton_left_shoulder.png'],[Folder.data,'\Report\Skeleton_left_shoulder.png']);
%     copyfile([Folder.toolbox,'Report\Skeleton_right_shoulder.png'],[Folder.data,'\Report\Skeleton_right_shoulder.png']);
%     copyfile([Folder.toolbox,'Report\Skeleton_top.png'],[Folder.data,'\Report\Skeleton_top.png']);
% end
Report = GenerateReportData(Trial);
% Normal = LoadNormativeData(Folder,Session,Patient);
% GenerateReportPlots(Folder,Session,Report,Normal);

% -------------------------------------------------------------------------
% STORE RESULTS
% -------------------------------------------------------------------------
clearvars -except Folder Patient Session Pathology Processing Trial Report Normal participantID;
save([Folder.data,participantID,'\',num2str(Patient.ID),'-',Session.ID,'-',Session.date,'-',datestr(datetime('today'),'YYYYmmDD'),'.mat']);

% -------------------------------------------------------------------------
% STOP ALL PROCESSES
% -------------------------------------------------------------------------
close all;
cd([Folder.data,'\']);
toc