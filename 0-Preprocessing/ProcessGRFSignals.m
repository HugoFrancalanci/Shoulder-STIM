% Author       : F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License      : Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code  : https://github.com/fmoissenet/NSLBP-BIOToolbox
% Reference    : To be defined
% Date         : December 2021
% -------------------------------------------------------------------------
% Description  : To be defined
% Inputs       : To be defined
% Outputs      : To be defined
% -------------------------------------------------------------------------
% Dependencies : - Biomechanical Toolkit (BTK): https://github.com/Biomechanical-ToolKit/BTKCore
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function [Trial,Processing] = ProcessGRFSignals(Trial,Calibration,GRF,Processing)

% -------------------------------------------------------------------------
% COMPUTE CALIBRATION 
% -------------------------------------------------------------------------
if isempty(GRF)
    for i = 1:size(Trial.GRF,2)
        Trial.GRF(i).Signal.P.offset = mean(Trial.GRF(i).Signal.P.raw(:,:,...
            Processing.GRF.zmethod.parameter(1):Processing.GRF.zmethod.parameter(2)),3);
        Trial.GRF(i).Signal.F.offset = mean(Trial.GRF(i).Signal.F.raw(:,:,...
            Processing.GRF.zmethod.parameter(1):Processing.GRF.zmethod.parameter(2)),3);
        Trial.GRF(i).Signal.M.offset = mean(Trial.GRF(i).Signal.M.raw(:,:,...
            Processing.GRF.zmethod.parameter(1):Processing.GRF.zmethod.parameter(2)),3);
    end
end

% -------------------------------------------------------------------------
% REPLACE NaN BY ZEROS
% Needed in case of NaN at the end of recordings
% -------------------------------------------------------------------------
if ~isempty(Trial.GRF) && ~isempty(GRF)    
    for i = 1:size(Trial.GRF,2)
        % Replace [0 0 0] by NaN
        for j = 1:size(Trial.GRF(i).Signal.F.raw,3)
            if isnan(Trial.GRF(i).Signal.F.raw(1,:,j))
                Trial.GRF(i).Signal.P.raw(:,:,j) = zeros(3,1,1);
                Trial.GRF(i).Signal.F.raw(:,:,j) = zeros(3,1,1);
                Trial.GRF(i).Signal.M.raw(:,:,j) = zeros(3,1,1);
            end
        end
    end
end

% -------------------------------------------------------------------------
% SIGNAL ZEROING
% -------------------------------------------------------------------------
if ~isempty(Trial.GRF) && ~isempty(GRF)    
    for i = 1:size(Trial.GRF,2)
        % Method 1: No zeroing
        if strcmp(Processing.GRF.zmethod.type,'none')
            Trial.GRF(i).Signal.P.raw    = Trial.GRF(i).Signal.P.raw;
            Trial.GRF(i).Signal.F.raw    = Trial.GRF(i).Signal.F.raw;
            Trial.GRF(i).Signal.M.raw    = Trial.GRF(i).Signal.M.raw;
            Trial.GRF(i).Processing.zero = Processing.GRF.fmethod.type;
        % Method 2: Mean of a set of frames
        % Should be adapted to each type of movement
        elseif strcmp(Processing.GRF.zmethod.type,'frames')
            if isempty(zmethod.backup)
                if ~isempty(Trial.GRF(i).Signal.F.raw)
                    Trial.GRF(i).Signal.P.raw = Trial.GRF(i).Signal.P.raw - ...
                        mean(Trial.GRF(i).Signal.P.raw(:,:,Processing.GRF.zmethod.parameter(1):Processing.GRF.zmethod.parameter(2)),3);
                    Trial.GRF(i).Signal.F.raw = Trial.GRF(i).Signal.F.raw - ...
                        mean(Trial.GRF(i).Signal.F.raw(:,:,Processing.GRF.zmethod.parameter(1):Processing.GRF.zmethod.parameter(2)),3);
                    Trial.GRF(i).Signal.M.raw = Trial.GRF(i).Signal.M.raw - ...
                        mean(Trial.GRF(i).Signal.M.raw(:,:,Processing.GRF.zmethod.parameter(1):Processing.GRF.zmethod.parameter(2)),3);
                end
                Trial.GRF(i).Processing.zero = Processing.GRF.zmethod.type;
                % Store offsets
                Processing.GRF.zmethod.backup.GRF(i).P = mean(Trial.GRF(i).Signal.P.raw(:,:,...
                    Processing.GRF.zmethod.parameter(1):Processing.GRF.zmethod.parameter(2)),3);
                Processing.GRF.zmethod.backup.GRF(i).F = mean(Trial.GRF(i).Signal.F.raw(:,:,...
                    Processing.GRF.zmethod.parameter(1):Processing.GRF.zmethod.parameter(2)),3);
                Processing.GRF.zmethod.backup.GRF(i).M = mean(Trial.GRF(i).Signal.M.raw(:,:,...
                    Processing.GRF.zmethod.parameter(1):Processing.GRF.zmethod.parameter(2)),3);
            else
                if ~isempty(Trial.GRF(i).Signal.F.raw)
                    Trial.GRF(i).Signal.P.raw = Trial.GRF(i).Signal.P.raw - Processing.GRF.zmethod.backup.GRF(i).P;
                    Trial.GRF(i).Signal.F.raw = Trial.GRF(i).Signal.F.raw - Processing.GRF.zmethod.backup.GRF(i).F;
                    Trial.GRF(i).Signal.M.raw = Trial.GRF(i).Signal.M.raw - Processing.GRF.zmethod.backup.GRF(i).M;
                end
                Trial.GRF(i).Processing.zero = Processing.GRF.zmethod.type;
            end
        % Method 3: Remove the offset defined during calibration
        elseif strcmp(Processing.GRF.zmethod.type,'offset')
            if ~isempty(Calibration(1))
                if ~isempty(Trial.GRF(i).Signal.F.raw)
                    Trial.GRF(i).Signal.P.raw = Trial.GRF(i).Signal.P.raw - Calibration.GRF(i).Signal.P.offset;
                    Trial.GRF(i).Signal.F.raw = Trial.GRF(i).Signal.F.raw - Calibration.GRF(i).Signal.F.offset;
                    Trial.GRF(i).Signal.M.raw = Trial.GRF(i).Signal.M.raw - Calibration.GRF(i).Signal.M.offset;
                end
                Trial.GRF(i).Processing.zero = Processing.GRF.zmethod.type;
            end
        end
    end
end

% -------------------------------------------------------------------------
% SIGNAL FILTERING
% -------------------------------------------------------------------------
if ~isempty(Trial.GRF) && ~isempty(GRF)
    for i = 1:size(Trial.GRF,2)
        
        % Method 1: No filtering
        if strcmp(Processing.GRF.fmethod.type,'none') 
            Trial.GRF(i).Signal.P.filt   = Trial.GRF(i).Signal.P.raw;
            Trial.GRF(i).Signal.F.filt   = Trial.GRF(i).Signal.F.raw;
            Trial.GRF(i).Signal.M.filt   = Trial.GRF(i).Signal.M.raw;
            Trial.GRF(i).Processing.filt = Processing.GRF.fmethod.type;
        
        % Method 2: Vertical force threshold ([fmethod.parameter] N)
        elseif strcmp(Processing.GRF.fmethod.type,'threshold') 
            if ~isempty(Trial.GRF(i).Signal.F.raw)
                for j = 1:size(Trial.GRF(i).Signal.F.raw,3)
                    if Trial.GRF(i).Signal.F.raw(3,:,j) < Processing.GRF.fmethod.parameter
                        Trial.GRF(i).Signal.P.filt(:,:,j) = zeros(3,1);
                        Trial.GRF(i).Signal.F.filt(:,:,j) = zeros(3,1);
                        Trial.GRF(i).Signal.M.filt(:,:,j) = zeros(3,1);
                    else
                        Trial.GRF(i).Signal.P.filt(:,:,j) = Trial.GRF(i).Signal.P.raw(:,:,j);
                        Trial.GRF(i).Signal.F.filt(:,:,j) = Trial.GRF(i).Signal.F.raw(:,:,j);
                        Trial.GRF(i).Signal.M.filt(:,:,j) = Trial.GRF(i).Signal.M.raw(:,:,j);
                    end
                end
            end
            Trial.GRF(i).Processing.filt = Processing.GRF.fmethod.type;
        end
        
    end
end

% -------------------------------------------------------------------------
% SIGNAL SMOOTHING
% -------------------------------------------------------------------------
if ~isempty(Trial.GRF) && ~isempty(GRF)
    for i = 1:size(Trial.GRF,2)

        % Method 1: No smoothing
        if strcmp(Processing.GRF.smethod.type,'none') 
            if ~isempty(Trial.GRF(i).Signal.F.raw)
                Trial.GRF(i).Signal.P.smooth = Trial.GRF(i).Signal.P.filt;
                Trial.GRF(i).Signal.F.smooth = Trial.GRF(i).Signal.F.filt;
                Trial.GRF(i).Signal.M.smooth = Trial.GRF(i).Signal.M.filt;
            end
            Trial.GRF(i).Processing.smooth = Processing.GRF.smethod.type;

        % Method 2: Low pass filter (Butterworth 2nd order, [smethod.parameter] Hz)
        elseif strcmp(Processing.GRF.smethod.type,'butterLow2') 
            if ~isempty(Trial.GRF(i).Signal.F.raw)
                [B,A] = butter(1,Processing.GRF.smethod.parameter/(Trial.fanalog/2),'low');
                for j = 1:3
                    if sum(Trial.GRF(i).Signal.P.filt(j,:,:),3) ~= 0
                        Trial.GRF(i).Signal.P.smooth(j,1,:) = permute(filtfilt(B,A,permute(Trial.GRF(i).Signal.P.filt(j,:,:),[3,1,2])),[2,3,1]);
                    else
                        Trial.GRF(i).Signal.P.smooth(j,1,:) = zeros(1,1,size(Trial.GRF(i).Signal.P.filt,3));
                    end
                end
                for j = 1:3
                    if sum(Trial.GRF(i).Signal.F.filt(j,:,:),3) ~= 0
                        Trial.GRF(i).Signal.F.smooth(j,1,:) = permute(filtfilt(B,A,permute(Trial.GRF(i).Signal.F.filt(j,:,:),[3,1,2])),[2,3,1]);
                    else
                        Trial.GRF(i).Signal.F.smooth(j,1,:) = zeros(1,1,size(Trial.GRF(i).Signal.F.filt,3));
                    end
                end
                for j = 1:3
                    if sum(Trial.GRF(i).Signal.M.filt(j,:,:),3) ~= 0
                        Trial.GRF(i).Signal.M.smooth(j,1,:) = permute(filtfilt(B,A,permute(Trial.GRF(i).Signal.M.filt(j,:,:),[3,1,2])),[2,3,1]);
                    else
                        Trial.GRF(i).Signal.M.smooth(j,1,:) = zeros(1,1,size(Trial.GRF(i).Signal.M.filt,3));
                    end
                end
            end
            Trial.GRF(i).Processing.smooth = Processing.GRF.smethod.type;
        end

    end
end

% -------------------------------------------------------------------------
% SIGNAL RESAMPLING
% -------------------------------------------------------------------------
if ~isempty(Trial.GRF) && ~isempty(GRF)
    for i = 1:size(Trial.GRF,2)
        
        % Method 1: No resampling
        if strcmp(Processing.GRF.rmethod.type,'none') 
            Trial.GRF(i).Signal.P.smooth   = Trial.GRF(i).Signal.P.smooth;
            Trial.GRF(i).Signal.F.smooth   = Trial.GRF(i).Signal.F.smooth;
            Trial.GRF(i).Signal.M.smooth   = Trial.GRF(i).Signal.M.smooth;
            Trial.GRF(i).Processing.resamp = Processing.GRF.rmethod.type;
        
        % Method 2: Resampling to the n frames of marker trajectories
        elseif strcmp(Processing.GRF.rmethod.type,'marker') 
            if ~isempty(Trial.GRF(i).Signal.F.raw)
                Trial.GRF(i).Signal.P.smooth   = permute(interp1((1:size(Trial.GRF(i).Signal.P.smooth,3))',...
                                                                 permute(Trial.GRF(i).Signal.P.smooth,[3,1,2]),...
                                                                 (linspace(1,size(Trial.GRF(i).Signal.P.smooth,3),size(Trial.Marker(1).Trajectory.smooth,3)))',...
                                                                 'spline'),[2,3,1]);
                Trial.GRF(i).Signal.F.smooth   = permute(interp1((1:size(Trial.GRF(i).Signal.F.smooth,3))',...
                                                                 permute(Trial.GRF(i).Signal.F.smooth,[3,1,2]),...
                                                                 (linspace(1,size(Trial.GRF(i).Signal.F.smooth,3),size(Trial.Marker(1).Trajectory.smooth,3)))',...
                                                                 'spline'),[2,3,1]);
                Trial.GRF(i).Signal.M.smooth   = permute(interp1((1:size(Trial.GRF(i).Signal.M.smooth,3))',...
                                                                 permute(Trial.GRF(i).Signal.M.smooth,[3,1,2]),...
                                                                 (linspace(1,size(Trial.GRF(i).Signal.M.smooth,3),size(Trial.Marker(1).Trajectory.smooth,3)))',...
                                                                 'spline'),[2,3,1]);
                Trial.GRF(i).Processing.resamp = Processing.GRF.rmethod.type;
            end
        end
    end
end