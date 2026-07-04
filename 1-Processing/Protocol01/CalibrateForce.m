% Author       : F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License      : Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code  : https://github.com/fmoissenet/NSLBP-BIOToolbox
% Reference    : To be defined
% Date         : May 2022
% -------------------------------------------------------------------------
% Description  : To be defined
% Inputs       : To be defined
% Outputs      : To be defined
% -------------------------------------------------------------------------
% Dependencies : None
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function [] = CalibrateForce(Folder,mass)

% Load force sensor calibration file
cd([Folder.data,'\Raw\']);
temp    = dir('*Calibration_force*.c3d');
if ~isempty(temp)
    c3dFile = temp.name;
    btkFile = btkReadAcquisition(c3dFile);
    f       = btkGetAnalogFrequency(btkFile);
    Analog  = btkGetAnalogs(btkFile);
    Event   = btkGetEvents(btkFile);
    clear temp; 
    % Get calibration values 
    weight = mass*9.81; % (N)
    if isfield(Analog,'CH16_FORCE')
        force.zero        = mean(Analog.CH16_FORCE(fix(Event.Remote(3)*f):fix(Event.Remote(4)*f),1));
%         force.calibration = weight/(mean(Analog.CH16_FORCE(fix(Event.Remote(1)*f):fix(Event.Remote(2)*f),1))-force.zero);
        force.calibration = weight/(mean(Analog.CH16_FORCE(fix(Event.Remote(1)*f):fix(Event.Remote(2)*f),1)));
    else
        force.zero        = 0;
        force.calibration = 0;
    end
    % Load C3D files
    cd([Folder.data,'\Processed\']);
    c3dFiles   = dir('*.c3d');
    trialTypes = {'ISOMETRIC1','ISOMETRIC2'};
    k          = 1;
    Trial      = [];
    for i = 1:size(c3dFiles,1)
        for j = 1:size(trialTypes,2)
            if contains(c3dFiles(i).name,trialTypes{j})    
                Trial(k).file    = c3dFiles(i).name;
                Trial(k).btk     = btkReadAcquisition(c3dFiles(i).name);
                Trial(k).n0      = btkGetFirstFrame(Trial(k).btk);
                Trial(k).n1      = btkGetLastFrame(Trial(k).btk)-Trial(k).n0+1;
                Trial(k).fmarker = btkGetPointFrequency(Trial(k).btk);
                Trial(k).fanalog = btkGetAnalogFrequency(Trial(k).btk);
                k                = k+1;
            end
        end
    end
    % For each file
    if ~isempty(Trial)
        for itrial = 1:size(Trial,2)
            % Get analogs
            Analog = btkGetAnalogs(Trial(itrial).btk);
            % Apply force calibration
            Force = (Analog.FORCE-force.zero) * force.calibration; % N
            % Update file
            n     = size(Force,1);
            k0    = (1:n)';
            k1    = (linspace(1,n,Trial(itrial).n1))';
            value = interp1(k0,[Force,zeros(size(Force)),zeros(size(Force))],k1,'spline');
            try
                btkSetPoint(Trial(itrial).btk,'Force',value,zeros(length(value),1),'Force signal (N)');
            catch ME
                btkAppendPoint(Trial(itrial).btk,'scalar','Force',value,zeros(length(value),1),'Force signal (N)');
            end
            btkWriteAcquisition(Trial(itrial).btk,Trial(itrial).file);
        end
    end
end