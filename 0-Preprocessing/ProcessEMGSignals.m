% Author       : F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License      : Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code  : https://github.com/fmoissenet/NSLBP-BIOToolbox
% Reference    : To be defined
% Date         : June 2020
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

function Trial = ProcessEMGSignals(Trial,Processing)

for i = 1:size(Trial.EMG,2)
    if ~isempty(Trial.EMG(i).Signal.raw)
              
        % -----------------------------------------------------------------
        % REPLACE NANs BY ZEROs
        % -----------------------------------------------------------------   
        Trial.EMG(i).Signal.filt                                  = Trial.EMG(i).Signal.raw;
        Trial.EMG(i).Signal.filt(isnan(Trial.EMG(i).Signal.filt)) = 0;

        % -----------------------------------------------------------------
        % ZEROING EMG SIGNAL
        % -----------------------------------------------------------------
        % Method 1: No zeroing
        if strcmp(Processing.EMG.zmethod.type,'none')
        % Method 2: Remove mean of the whole recording
        elseif strcmp(Processing.EMG.zmethod.type,'mean')
            Trial.EMG(i).Signal.filt = Trial.EMG(i).Signal.filt-mean(Trial.EMG(i).Signal.filt,3,'omitnan');
        % Method 3: Remove mean of a part of the recording
        elseif strcmp(Processing.EMG.zmethod.type,'frames')
            Trial.EMG(i).Signal.filt = Trial.EMG(i).Signal.filt-mean(Trial.EMG(i).Signal.filt(:,:,Processing.EMG.zmethod.parameter(1):Processing.EMG.zmethod.parameter(2)),3,'omitnan');
        end

        % -----------------------------------------------------------------
        % FILTER EMG SIGNAL
        % -----------------------------------------------------------------
        % Method 1: No filtering
        if strcmp(Processing.EMG.fmethod.type,'none')
            Trial.EMG(i).Signal.filt     = Trial.EMG(i).Signal.filt;
            Trial.EMG(i).Processing.filt = Processing.EMG.fmethod.type;
        
        % Method 2: Band pass filter (Butterworth 4nd order, [fmethod.parameter fmethod.parameter] Hz)
        elseif strcmp(Processing.EMG.fmethod.type,'butterBand4')
            if ~isempty(Trial.EMG(i).Signal.filt)
                [B,A]                        = butter(2,[Processing.EMG.fmethod.parameter(1) Processing.EMG.fmethod.parameter(2)]./(Trial.fanalog/2),'bandpass');
                Trial.EMG(i).Signal.filt     = permute(filtfilt(B,A,permute(Trial.EMG(i).Signal.filt,[3,1,2])),[2,3,1]);
                Trial.EMG(i).Processing.filt = Processing.EMG.fmethod.type;
            end
        end

        % -----------------------------------------------------------------
        % RECTIFY EMG SIGNAL
        % -----------------------------------------------------------------
        % Method 1: No rectification
        if strcmp(Processing.EMG.rmethod.type,'none')
            Trial.EMG(i).Signal.rect = Trial.EMG(i).Signal.filt;
        % Method 2: Absolute value
        elseif strcmp(Processing.EMG.fmethod.type,'abs')
            Trial.EMG(i).Signal.rect = abs(Trial.EMG(i).Signal.filt);
        end
        
        % -----------------------------------------------------------------
        % SMOOTH EMG SIGNAL
        % -----------------------------------------------------------------        
        % Method 1: No smoothing
        if strcmp(Processing.EMG.smethod.type,'none')
            Trial.EMG(i).Signal.smooth     = Trial.EMG(i).Signal.rect;
            Trial.EMG(i).Processing.smooth = Processing.EMG.smethod.type;
        
        % Method 2: Low pass filter (Butterworth 2nd order, [smethod.parameter] Hz)
        elseif strcmp(Processing.EMG.smethod.type,'butterLow2')
            [B,A]                          = butter(1,Processing.EMG.smethod.parameter/(Trial.fanalog/2),'low');
            Trial.EMG(i).Signal.smooth     = permute(filtfilt(B,A,permute(Trial.EMG(i).Signal.rect,[3,1,2])),[2,3,1]);
            Trial.EMG(i).Processing.smooth = Processing.EMG.smethod.type;
        
        % Method 3: Moving average (window of [smethod.parameter] frames)
        elseif strcmp(Processing.EMG.smethod.type,'movmean')
            Trial.EMG(i).Signal.smooth     = permute(smoothdata(permute(Trial.EMG(i).Signal.rect,[3,1,2]),'movmean',Processing.EMG.smethod.parameter),[2,3,1]);
            Trial.EMG(i).Processing.smooth = 'movmean';
        
        % Method 4: Moving average (window of [smethod.parameter] frames)
        elseif strcmp(Processing.EMG.smethod.type,'movmedian')
            Trial.EMG(i).Signal.smooth     = permute(smoothdata(permute(Trial.EMG(i).Signal.rect,[3,1,2]),'movmedian',Processing.EMG.smethod.parameter),[2,3,1]);
            Trial.EMG(i).Processing.smooth = 'movmedian';

        % Method 5: Signal root mean square (RMS) (window of [smethod.parameter] frames)
        elseif strcmp(Processing.EMG.smethod.type,'rms')
            Trial.EMG(i).Signal.smooth     = permute(envelope(permute(Trial.EMG(i).Signal.filt,[3,1,2]),Processing.EMG.smethod.parameter,'rms'),[2,3,1]);
            Trial.EMG(i).Processing.smooth = 'rms';
        end  

    end
end