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

function [] = CalibrateEMG(Folder)

% Load force EMG calibration file
cd([Folder.data,'\Processed\']);
temp    = dir('*STATIC3*.c3d'); % It is assumed that participant is relaxed during this record
c3dFile = temp.name;
btkFile = btkReadAcquisition(c3dFile);
f       = btkGetAnalogFrequency(btkFile);
Analog  = btkGetAnalogs(btkFile);
nEmg    = fieldnames(Analog);
Event   = btkGetEvents(btkFile);
clear temp;

% Load C3D files
cd([Folder.data,'\Processed\']);
c3dFiles   = dir('*.c3d');
trialTypes = {'ANALYTIC','FUNCTIONAL','ISOMETRIC'};
k          = 1;
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
for itrial = 1:size(Trial,2)
    disp(['  - ',Trial(itrial).file]);
    % Get analogs
    Analog = btkGetAnalogs(Trial(itrial).btk);
    emgNames = fieldnames(Analog);
    % Manual validation of EMG signal
    for iemg = 1:14 % All EMG (right and left)
        fig = figure; hold on;
        title(emgNames{iemg});
        esample = Analog.(nEmg{iemg})(1+fix(end*5/100):end-fix(end*5/100)); % Remove first and last 5% frames to avoid noise
        plot(esample./max(esample),'black');
        rectangle('Position',[length(esample)/2 0 length(esample)/2 1],'FaceColor',[0 1 0 0.2],'EdgeColor','none');
        rectangle('Position',[0 0 length(esample)/2 1],'FaceColor',[1 0 0 0.2],'EdgeColor','none');
        temp = ginput(1);
        if temp(1) > length(esample)/2
            validity(iemg) = 1; % Green area
        else
            validity(iemg) = 0; % Red area
        end
        close(fig);
        clear temp;
    end
    % Apply EMG calibration
    nEmg = fieldnames(Analog);
    threshold = 0.3; % 30% of the signal amplitude (doi: 10.1016/j.proeng.2016.06.208)
    for iemg = 1:14 % All EMG (right and left)
        tEMG(iemg).value = [];
        temp = [];
        if ~isempty(fieldnames(Analog))
            if ~isempty(Analog.(nEmg{iemg}))
                if validity(iemg) == 1
                    esample = Analog.(nEmg{iemg})(1+fix(end*5/100):end-fix(end*5/100)); % Remove first and last 5% frames to avoid noise
                    temp = sort(esample,'descend');
                    for t = 1:size(Analog.(nEmg{iemg}),1)
                        if iemg < 8 % Right
                            if Analog.(nEmg{iemg})(t)-mean(temp(end-100:end)) < threshold*(mean(temp(1:100))-mean(temp(end-100:end)))% - EMG.RCalibration.mean < 3*EMG.RCalibration.std % Baseline set at n SD of the EMG calibration file
                                tEMG(iemg).value(t,1) = 0;
                            else
                                tEMG(iemg).value(t,1) = 1;
                            end
                        else % Left
                            if Analog.(nEmg{iemg})(t)-mean(temp(end-100:end)) < threshold*(mean(temp(1:100))-mean(temp(end-100:end)))% - EMG.LCalibration.mean < 3*EMG.LCalibration.std % Baseline set at n SD of the EMG calibration file
                                tEMG(iemg).value(t,1) = 0;
                            else
                                tEMG(iemg).value(t,1) = 1;
                            end
                        end
                    end
                else
                    tEMG(iemg).value = [];
                end
            else
                tEMG(iemg).value = [];
            end
        end
    end
%     for iemg = 1:14
%     figure; hold on;
%         plot(Analog.(nEmg{iemg}),'blue');
%         plot(tEMG(iemg).value*max(Analog.(nEmg{iemg})),'red');
%     end
    % Update file
    if ~isempty(fieldnames(Analog))
        n  = size(Analog.(nEmg{1}),1);
        k0 = (1:n)';
        k1 = (linspace(1,n,Trial(itrial).n1))';    
        for iemg = 1:14 % All EMG (right and left)
            if ~isempty(tEMG(iemg).value)
                value = interp1(k0,[tEMG(iemg).value,zeros(size(tEMG(iemg).value)),zeros(size(tEMG(iemg).value))],k1,'spline');
            else
                value = nan(Trial(itrial).n1,3);
            end
            try
                btkAppendPoint(Trial(itrial).btk,'scalar',(nEmg{iemg}),value,zeros(length(value),1),'Cleaned EMG signal (mV)');
            catch ME            
                btkSetPoint(Trial(itrial).btk,(nEmg{iemg}),value,zeros(length(value),1),'Cleaned EMG signal (mV)');
            end
            btkWriteAcquisition(Trial(itrial).btk,Trial(itrial).file);
        end
    end
end