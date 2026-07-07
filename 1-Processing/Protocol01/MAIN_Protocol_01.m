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
% (revised version for STIM)
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

% Note : Change patient ID (deux endroits)

% -------------------------------------------------------------------------
% INIT WORKSPACE
% -------------------------------------------------------------------------
tic
clearvars;
close all;
warning off;
clc;
disp('------------------------------------------------------------------');
disp('KLAB_UpperLimb_toolbox_Kevin_Dev');
disp('------------------------------------------------------------------');
disp(' ');
disp('Lire le README pour voir les changements effectués et le procédé à suivre');
disp('------------------------------------------------------------------');
disp(' ');

% -------------------------------------------------------------------------
% SET FOLDERS
% -------------------------------------------------------------------------
disp('Définition des répertoires de travail');
MainFolder           = 'C:\Users\franc\Desktop\Programming\02_Collaborations\C01_STIM_KC\Stim_Dev\';
Folder.preprocessing = [MainFolder,'0-Preprocessing\'];
Folder.toolbox       = [MainFolder,'1-Processing\Protocol01\'];
Folder.data          = uigetdir(); % Patient folder defined by GUI
Folder.dependencies  = [MainFolder,'1-Processing\dependencies\'];
addpath(genpath(Folder.dependencies));
disp(' ');

% -------------------------------------------------------------------------
% PRE-PROCESS DATA
% -------------------------------------------------------------------------
% - Markers: fill gap (intercor), smoothing (movmean)y
% - EMG: zeroing (mean), filtering (btw bandpass 4th order 30-450 Hz)
% - Force: smoothing (btw lowpass 2nd order 10 Hz)
% -------------------------------------------------------------------------
disp('Pré-traitement des données');
% if ~isfolder('Processed')
    addpath(Folder.preprocessing);
    MAIN_Preprocessing_toolbox('P9','S1','20260612','PROTOCOL01',Folder.preprocessing,[Folder.data,'\Raw\']);
% end
addpath(Folder.toolbox);
cd(Folder.toolbox);

% -------------------------------------------------------------------------
% PROCESS DATA
% -------------------------------------------------------------------------
% Get user commands
Session.markerHeight1 = 0.0095; % m
Session.markerHeight2 = 0.0140; % m
cd(Folder.preprocessing);
txtFile      = 'userCommands.txt';
userCommands = fileread(txtFile);
eval(userCommands);
% Load data
cd([Folder.data,'\Processed\']);
c3dFiles   = dir('*.c3d');
trialTypes = {'CALIBRATION','ANALYTIC','FUNCTIONAL'};
k          = 1;
%%
trialOrder = {'CALIBRATION3','CALIBRATION1','CALIBRATION2','CALIBRATION4', ...
              'CALIBRATION5','CALIBRATION6','ANALYTIC2'};

orderedIdx = zeros(1, length(c3dFiles));
nIdx = 0;
for itype = 1:length(trialOrder)
    for ifile = 1:length(c3dFiles)
        if contains(c3dFiles(ifile).name, trialOrder{itype})
            nIdx = nIdx + 1;
            orderedIdx(nIdx) = ifile;
        end
    end
end
orderedIdx = orderedIdx(1:nIdx);

side = input('Côté découpage cycle (R/L) : ', 's');
threshold = []; 

for i = orderedIdx
    for j = 1:size(trialTypes,2)
        if contains(c3dFiles(i).name,trialTypes{j})  
            disp(' ');
            % Extract data from C3D files 
            if contains(c3dFiles(i).name,'CALIBRATION')
                Trial(k).task = c3dFiles(i).name(end-18:end-7);
            elseif contains(c3dFiles(i).name,'ANALYTIC')
                Trial(k).task = c3dFiles(i).name(end-15:end-7);
            elseif contains(c3dFiles(i).name,'FUNCTIONAL')
                Trial(k).task = c3dFiles(i).name(end-17:end-7);
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
            % Import force data
            % Trial(k).Fsensor     = [];
            % mass                 = 4; % (kg) Mass used for calibration
            % Analog               = btkGetAnalogs(Trial(k).btk);
            % if strcmp(Trial(k).task,'CALIBRATION5') || strcmp(Trial(k).task,'CALIBRATION6')
            %     calibration      = Trial(4).Fsensor.calibration; % from CALIBRATION4
            % else
            %     calibration      = [];
            % end
            % Trial(k)             = InitialiseForceSignals(c3dFiles(i),Trial(k),Analog,Event,mass,calibration);
            % Import EMG signals
            % Import EMG signals
           Analog = btkGetAnalogs(Trial(k).btk);
           Trial(k).Emg = [];
           if strcmp(Trial(k).task,'CALIBRATION3')
              Trial(k) = InitialiseEmgSignals(emgSet, Trial(k), [], Analog);
           else
              Trial(k) = InitialiseEmgSignals(emgSet, Trial(k), Trial(1), Analog);
           end
            % Manage kinematics
            Trial(k).Segment     = [];
            Trial(k).Joint       = [];
            Trial(k).Rcycle      = [];
            Trial(k).Lcycle      = [];
            Trial(k).SHR         = [];
            if ~contains(c3dFiles(i).name, 'CALIBRATION4') % Not applicable to calibrations
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
                btype            = 2; 
                [Trial(k), threshold] = CutCycles(c3dFiles(i), Trial(k), btype, side, threshold);
                % Compute SHR
                Trial(k)         = ComputeSHR(c3dFiles(i),Trial(k),Trial(k)); % Last input is the reference position used for SHR computation
                close all;
            end
            % Update C3D files
            % UpdateC3DFile(Trial(k),c3dFiles(i),0);
            % Increment trial index
            k                    = k+1;
        end
    end
end

% -------------------------------------------------------------------------
% STORE RESULTS
% -------------------------------------------------------------------------
clearvars -except Folder Session Trial;
save([Folder.data,'\P9-',datestr(datetime('today'),'YYYYmmDD'),'.mat']);
% -------------------------------------------------------------------------
% STOP ALL PROCESSES
% -------------------------------------------------------------------------
close all;
cd([Folder.data,'\']);
toc