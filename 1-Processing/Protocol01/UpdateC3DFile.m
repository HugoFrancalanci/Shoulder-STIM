% Author     :   F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   June 2023
% -------------------------------------------------------------------------
% Description:   Update C3D file
% -------------------------------------------------------------------------
% Dependencies : To be defined
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function [] = UpdateC3DFile(Trial,c3dFiles,patch)

% Markers
if ~contains(c3dFiles.name,'CALIBRATION3')
    Marker = btkGetMarkers(Trial.btk);
    markerNames = fieldnames(Marker);
    if isfield(markerNames,'STY01')
        btkRemovePoint(Trial.btk,'STY01');
        btkRemovePoint(Trial.btk,'STY02');
        btkRemovePoint(Trial.btk,'STY03');
        btkRemovePoint(Trial.btk,'STY04');
        btkRemovePoint(Trial.btk,'STY05');
    end
    clear Marker markerNames;
end
% Virtual markers
for ivmarker = 1:length(Trial.Vmarker)
    try
        btkAppendPoint(Trial.btk,'marker',Trial.Vmarker(ivmarker).label,permute(Trial.Vmarker(ivmarker).Trajectory.full,[3,2,1]),zeros(size(permute(Trial.Vmarker(ivmarker).Trajectory.full,[3,2,1]),1),1),['Units: ',Trial.Vmarker(ivmarker).Trajectory.units]);
    catch ME
        if ~isempty(Trial.Vmarker(ivmarker).Trajectory.full)
            btkSetPoint(Trial.btk,Trial.Vmarker(ivmarker).label,permute(Trial.Vmarker(ivmarker).Trajectory.full,[3,2,1]),zeros(size(permute(Trial.Vmarker(ivmarker).Trajectory.full,[3,2,1]),1),1),['Units: ',Trial.Vmarker(ivmarker).Trajectory.units]);            
        end
    end
end
if patch == 0
    % Joints
    if contains(c3dFiles.name,'ANALYTIC')
        for ijoint = [1,2,3,6,7,8]
            try
                btkAppendPoint(Trial.btk,'angle',Trial.Joint(ijoint).label,permute(Trial.Joint(ijoint).Euler.full,[3,2,1]),zeros(size(permute(Trial.Joint(ijoint).Euler.full,[3,2,1]),1),1),['Units: ',Trial.Joint(ijoint).Euler.units,', Euler sequence: ',Trial.Joint(ijoint).sequence]);
            catch ME
                if ~isempty(Trial.Joint(ijoint).Euler.full)
                    btkSetPoint(Trial.btk,Trial.Joint(ijoint).label,permute(Trial.Joint(ijoint).Euler.full,[3,2,1]),zeros(size(permute(Trial.Joint(ijoint).Euler.full,[3,2,1]),1),1),['Units: ',Trial.Joint(ijoint).Euler.units,', Euler sequence: ',Trial.Joint(ijoint).sequence]);
                end
            end
        end
    end
    % Emgs
    if ~isempty(Trial.Emg)
        for iemg = 1:size(Trial.Emg,2)
            if ~isempty(Trial.Emg(iemg).Signal)
                if ~isempty(Trial.Emg(iemg).Signal.full)
                    btkRemoveAnalog(Trial.btk,Trial.Emg(iemg).label);
                    btkAppendAnalog(Trial.btk,Trial.Emg(iemg).label,permute(Trial.Emg(iemg).Signal.full,[3,2,1]));
                    if ~isempty(Trial.Emg(iemg).Signal.envelop)
                        btkAppendAnalog(Trial.btk,[Trial.Emg(iemg).label,'_envelop'],permute(Trial.Emg(iemg).Signal.envelop,[3,2,1]));
                        btkAppendAnalog(Trial.btk,[Trial.Emg(iemg).label,'_onset'],permute(Trial.Emg(iemg).Signal.onset(1,1,1:length(Trial.Emg(iemg).Signal.envelop)),[3,2,1])*max(Trial.Emg(iemg).Signal.envelop));
                    end
                end
            end
        end
    end
    % Force
    if ~isempty(Trial.Fsensor.Force.value)
        btkRemoveAnalog(Trial.btk,'FORCE');
        btkAppendAnalog(Trial.btk,'FORCE',permute(Trial.Fsensor.Force.value,[3,2,1]),'');
        btkSetAnalogUnit(Trial.btk,'FORCE',Trial.Fsensor.Force.units);
    end
    % Events
    for icycle = 1:size(Trial.Rcycle,2)
        if contains(Trial.task,'ANALYTIC1') || contains(c3dFiles.name,'FUNCTIONAL3')
            ieuler = 3;
            sign   = 1; 
        elseif contains(Trial.task,'ANALYTIC2') || contains(Trial.task,'ANALYTIC5') || contains(c3dFiles.name,'FUNCTIONAL1') || contains(c3dFiles.name,'FUNCTIONAL2') || contains(c3dFiles.name,'FUNCTIONAL4')
            ieuler = 1;
            sign   = -1; 
        elseif contains(Trial.task,'ANALYTIC3')
            ieuler = 2;
            sign   = -1; 
        elseif contains(Trial.task,'ANALYTIC4')
            ieuler = 2;
            sign   = 1; 
        end    
        btkAppendEvent(Trial.btk,'Start',Trial.Rcycle(icycle).range(1)/Trial.fmarker,''); % Start frame
        [~,ind]  = max(sign*Trial.Joint(1).Euler.full(1,ieuler,Trial.Rcycle(icycle).range));
        maxAngle = ind+Trial.Rcycle(icycle).range(1)-1;
        btkAppendEvent(Trial.btk,'Max right',maxAngle/Trial.fmarker,''); % Max right angle frame
        btkAppendEvent(Trial.btk,'Stop',Trial.Rcycle(icycle).range(end)/Trial.fmarker,''); % Stop frame
    end
    for icycle = 1:size(Trial.Lcycle,2)
        if contains(Trial.task,'ANALYTIC1') || contains(c3dFiles.name,'FUNCTIONAL3')
            ieuler = 3;
            sign   = 1; 
        elseif contains(Trial.task,'ANALYTIC2') || contains(Trial.task,'ANALYTIC5') || contains(c3dFiles.name,'FUNCTIONAL1') || contains(c3dFiles.name,'FUNCTIONAL2') || contains(c3dFiles.name,'FUNCTIONAL4')
            ieuler = 1;
            sign   = -1; 
        elseif contains(Trial.task,'ANALYTIC3')
            ieuler = 2;
            sign   = -1; 
        elseif contains(Trial.task,'ANALYTIC4')
            ieuler = 2;
            sign   = 1; 
        end    
        btkAppendEvent(Trial.btk,'Start',Trial.Lcycle(icycle).range(1)/Trial.fmarker,''); % Start frame
        [~,ind]  = max(sign*Trial.Joint(6).Euler.full(1,ieuler,Trial.Lcycle(icycle).range));
        maxAngle = ind+Trial.Lcycle(icycle).range(1)-1;
        btkAppendEvent(Trial.btk,'Max right',maxAngle/Trial.fmarker,''); % Max right angle frame
        btkAppendEvent(Trial.btk,'Stop',Trial.Lcycle(icycle).range(end)/Trial.fmarker,''); % Stop frame
    end
end
% Write file
btkWriteAcquisition(Trial.btk,Trial.file);   