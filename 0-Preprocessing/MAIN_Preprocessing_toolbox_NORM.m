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
% Description  : Main routine used to launch the C3D files pre-processing
%                toolbox
% -------------------------------------------------------------------------
% Dependencies : To be defined
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function [] = MAIN_Preprocessing_toolbox_NORM(Patient_ID,Session_ID,Session_date,Session_protocol,folder1,folder2)

% -------------------------------------------------------------------------
% SET FOLDERS
% -------------------------------------------------------------------------
Folder.toolbox      = folder1;
Folder.data         = folder2;
Folder.dependencies = [Folder.toolbox,'dependencies\'];
addpath(Folder.toolbox);
addpath(genpath(Folder.dependencies));

% -------------------------------------------------------------------------
% GET USER COMMANDS
% -------------------------------------------------------------------------
txtFile      = 'userCommands_normative.txt';
userCommands = fileread(txtFile);
eval(userCommands);

% -------------------------------------------------------------------------
% LOAD C3D FILES
% -------------------------------------------------------------------------
% Extract data from C3D files
cd(Folder.data);
c3dFiles = dir('*.c3d');
k1       = 1;
k2       = 1;
for i = 1:size(c3dFiles,1)
    for j = 1:size(staticTypes,1)
        if contains(c3dFiles(i).name,staticTypes{j,1})
            Static(k1).type    = staticTypes{j,1};
            Static(k1).file    = c3dFiles(i).name;
            Static(k1).btk     = btkReadAcquisition(c3dFiles(i).name);
            Static(k1).n0      = btkGetFirstFrame(Static(k1).btk);
            Static(k1).n1      = btkGetLastFrame(Static(k1).btk)-Static(k1).n0+1;
            Static(k1).fmarker = btkGetPointFrequency(Static(k1).btk);
            Static(k1).fanalog = btkGetAnalogFrequency(Static(k1).btk);
            k1                 = k1+1;
        end
    end
    for j = 1:size(trialTypes,1)
        if contains(c3dFiles(i).name,trialTypes{j,1})
            Trial(k2).type    = trialTypes{j,1};
            Trial(k2).file    = c3dFiles(i).name;
            Trial(k2).btk     = btkReadAcquisition(c3dFiles(i).name);
            Trial(k2).n0      = btkGetFirstFrame(Trial(k2).btk);
            Trial(k2).n1      = btkGetLastFrame(Trial(k2).btk)-Trial(k2).n0+1;
            Trial(k2).fmarker = btkGetPointFrequency(Trial(k2).btk);
            Trial(k2).fanalog = btkGetAnalogFrequency(Trial(k2).btk);
            k2                = k2+1;
        end
    end
end
clear i j k1 k2 c3dFiles;

% -------------------------------------------------------------------------
% SET UNITS
% -------------------------------------------------------------------------
% Get units used in the input C3D files
Units.input = btkGetPointsUnit(Static(1).btk,'Marker');
% Set units used in the output C3D files
% Defined by the user in Units.output
% Set the units required in the output C3D files
if strcmp(Units.input,'mm')
    if strcmp(Units.output,'mm')
        Units.ratio = 1;
    elseif strcmp(Units.output,'m')
        Units.ratio = 1e-3;
    end
elseif strcmp(Units.input,'m')
    if strcmp(Units.output,'mm')
        Units.ratio = 1e3;
    elseif strcmp(Units.output,'m')
        Units.ratio = 1;
    end
end

% -------------------------------------------------------------------------
% PRE-PROCESS DATA
% -------------------------------------------------------------------------
% Video files
% ProcessVideos(Patient_ID,Session_ID,Session_date,Session_protocol,Folder,staticTypes,trialTypes,videoTypes);

% Static data
for i = 1:size(Static,2)
    disp(['  - ',Static(i).file]);    
    % Get manually defined events
    if event == 1
        Static(i).Event = [];
    end    
    % Process marker trajectories
    if marker == 1
        Marker            = btkGetMarkers(Static(i).btk);
        Static(i).Marker  = [];
        Static(i).Vmarker = [];
        Static(i).Segment = [];
        Static(i).Joint   = [];
        Static(i)         = InitialiseMarkerTrajectories(markerSet,Static(i),Marker,Units);
        Static(i)         = ProcessMarkerTrajectories([],Static(i));
        clear Marker;
    end    
    % Process EMG signals
    if emg == 1
        Static(i).EMG = [];
    end    
    % Process Force signals
    if emg == 1
        Static(i).Force = [];
    end    
    % Process forceplate signals
    if grf == 1
        Static(i).GRF = [];   
    end
    % Export preprocessed C3D
    ExportC3D(Patient_ID,Session_ID,Session_date,Session_protocol,Folder,Static(i),Processing,Units,staticTypes,trialTypes,event,marker,emg,force,grf);
end

% Trial data
for i = 1:size(Trial,2)    
    disp(['  - ',Trial(i).file]);
    % Get events (no pre-processing)
    if event == 1
        Trial(i).Event = [];
        Event          = btkGetEvents(Trial(i).btk);
        Trial(i)       = InitialiseEvents(eventSet,Trial(i),Event);
        clear Event;   
    end
    % Process marker trajectories   
    if marker == 1
        Trial(i).Marker = [];
        Marker          = btkGetMarkers(Trial(i).btk);
        Trial(i)        = InitialiseMarkerTrajectories(markerSet,Trial(i),Marker,Units);       
        Trial(i)        = ProcessMarkerTrajectories(Static(1),Trial(i),Processing);   
        clear Marker;
    end    
    % Process EMG signals
    if emg == 1
        Trial(i).EMG = [];
        Analog       = btkGetAnalogs(Trial(i).btk);
        Trial(i)     = InitialiseEMGSignals(emgSet,Trial(i),Analog);
        Trial(i)     = ProcessEMGSignals(Trial(i),Processing);
        clear Analog;
    end    
    % Process force sensor signals
    if force == 1
        Trial(i).Force = [];
        Analog         = btkGetAnalogs(Trial(i).btk);
        Trial(i)       = InitialiseForceSignals(forceSet,Trial(i),Analog);
        Trial(i)       = ProcessForceSignals(Trial(i),Processing);
        clear Analog;
    end
    % Process forceplate signals
    if grf == 1
        Trial(i).GRF          = [];
        Trial(i).btk          = Correct_FP_C3D_Mokka(Trial(i).btk);
        GRF                   = btkGetForcePlatformWrenches(Trial(i).btk);
        Trial(i)              = InitialiseGRFSignals(grfSet,Trial(i),GRF,Units);
        [Trial(i),Processing] = ProcessGRFSignals(Trial(i),[],GRF,Processing);
        clear GRF;
    end
    % Export preprocessed C3D
    ExportC3D(Patient_ID,Session_ID,Session_date,Session_protocol,Folder,Trial(i),Processing,Units,staticTypes,trialTypes,event,marker,emg,force,grf);
end
clear staticTypes trialTypes;