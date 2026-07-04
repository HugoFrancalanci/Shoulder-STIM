% Author     :   F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   April 2025
% -------------------------------------------------------------------------
% Description:   Patch for SXS virtual landmark placement from CALIBRATION3
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% INIT WORKSPACE
% -------------------------------------------------------------------------
clearvars;
close all;
warning off;
clc;

% -------------------------------------------------------------------------
% SET FOLDERS
% -------------------------------------------------------------------------
MainFolder           = 'C:\Users\Florent\OneDrive - Université de Genève\';
Folder.preprocessing = [MainFolder,'_CLINIQUE\Matlab\KLAB_ShoulderAnalysis_Toolbox\0-Preprocessing\'];
Folder.toolbox       = [MainFolder,'_CLINIQUE\Matlab\KLAB_ShoulderAnalysis_Toolbox\1-Processing\Protocol01\'];
Folder.data          = uigetdir(); % Patient folder defined by GUI
Folder.dependencies  = [MainFolder,'_CLINIQUE\Matlab\KLAB_ShoulderAnalysis_Toolbox\1-Processing\dependencies\'];
addpath(genpath(Folder.dependencies));
disp(' ');
addpath(Folder.toolbox);
cd(Folder.toolbox);

% Load data
cd([Folder.data,'\Processed\']);
c3dFiles   = dir('*.c3d');
trialTypes = {'CALIBRATION','ANALYTIC','FUNCTIONAL'};
k          = 1;

% Correct SXS
for i = [7,8,5,6,9,10,1,2,3,4,11,12,13,14]
    for j = 1:size(trialTypes,2)
        if contains(c3dFiles(i).name,trialTypes{j})  
            disp(' ');
            % Extract data from C3D files 
            Trial(k).file        = c3dFiles(i).name;
            Trial(k).btk         = btkReadAcquisition(c3dFiles(i).name);
            Trial(k).n0          = btkGetFirstFrame(Trial(k).btk);
            Trial(k).n1          = btkGetLastFrame(Trial(k).btk)-Trial(k).n0+1;
            Trial(k).fmarker     = btkGetPointFrequency(Trial(k).btk);
            Trial(k).fanalog     = btkGetAnalogFrequency(Trial(k).btk);       
            % Set units
            Units                = SetUnits(Trial);
            % Import events
            Event                = btkGetEvents(Trial(k).btk);
            % Import marker trajectories
            Marker               = btkGetMarkers(Trial(k).btk);
            % Initialise virtual marker trajectories
            Trial(k).Vmarker     = [];
            Trial(k)             = InitialiseVmarkerTrajectories(Trial(k));            
            % Add pointed landmarks as virtual markers
            pointList            = {'SXS'}; % List of virtual markers pointed with stylus (the order must be the same than the events stored in C3D file)
            if contains(c3dFiles(i).name,'CALIBRATION3')
                Vmarker          = [];
            end
            [Trial(k),Vmarker]   = AddPointedLandmarks(Trial(k),Marker,Vmarker,Event,pointList,'Stylusb');
            % Update C3D files
            patch = 1;
            UpdateC3DFile(Trial(k),c3dFiles(i),patch);
            % Increment trial index
            k                    = k+1;
        end
    end
end