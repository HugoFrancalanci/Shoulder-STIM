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

function Trial = ProcessForceSignals(Trial,Processing)

for i = 1:size(Trial.Force,2)
    if ~isempty(Trial.Force(i).Signal.raw)
        
        % -----------------------------------------------------------------
        % REPLACE NANs BY ZEROs
        % -----------------------------------------------------------------   
        Trial.Force(i).Signal.filt                                    = Trial.Force(i).Signal.raw;
        Trial.Force(i).Signal.filt(isnan(Trial.Force(i).Signal.filt)) = 0;

        % -----------------------------------------------------------------
        % ZEROING Force SIGNAL
        % -----------------------------------------------------------------
        % Method 1: No zeroing
        if strcmp(Processing.Force.fmethod.type,'none')
        % Method 2: Remove mean of the whole recording
        elseif strcmp(Processing.Force.fmethod.type,'mean')
            Trial.Force(i).Signal.filt = Trial.Force(i).Signal.filt-mean(Trial.Force(i).Signal.filt,3,'omitnan');
        % Method 3: Remove mean of a part of the recording
        elseif strcmp(Processing.Force.fmethod.type,'frames')
            Trial.Force(i).Signal.filt = Trial.Force(i).Signal.filt-mean(Trial.Force(i).Signal.filt(:,:,Processing.Force.zmethod.parameter(1):Processing.Force.zmethod.parameter(2)),3,'omitnan');
        end

        % -----------------------------------------------------------------
        % FILTER Force SIGNAL
        % -----------------------------------------------------------------
        % Method 1: No filtering
        if strcmp(Processing.Force.fmethod.type,'none')
            Trial.Force(i).Signal.filt     = Trial.Force(i).Signal.filt;
            Trial.Force(i).Processing.filt = Processing.Force.fmethod.type;
        
        % Method 2: Band pass filter (Butterworth 4nd order, [fmethod.parameter fmethod.parameter] Hz)
        elseif strcmp(Processing.Force.fmethod.type,'butterBand4')
            [B,A]                        = butter(2,[Processing.Force.fmethod.parameter(1) Processing.Force.fmethod.parameter(2)]./(Trial.fanalog/2),'bandpass');
            Trial.Force(i).Signal.filt     = permute(filtfilt(B,A,permute(Trial.Force(i).Signal.filt,[3,1,2])),[2,3,1]);
            Trial.Force(i).Processing.filt = Processing.Force.fmethod.type;
        end
        
        % -----------------------------------------------------------------
        % SMOOTH Force SIGNAL
        % -----------------------------------------------------------------        
        % Method 1: No smoothing
        if strcmp(Processing.Force.smethod.type,'none')
            Trial.Force(i).Signal.smooth     = Trial.Force(i).Signal.filt;
            Trial.Force(i).Processing.smooth = Processing.Force.smethod.type;
        
        % Method 2: Low pass filter (Butterworth 2nd order, [smethod.parameter] Hz)
        elseif strcmp(Processing.Force.smethod.type,'butterLow2')
            [B,A]                          = butter(1,Processing.Force.smethod.parameter/(Trial.fanalog/2),'low');
            Trial.Force(i).Signal.smooth     = permute(filtfilt(B,A,permute(Trial.Force(i).Signal.filt,[3,1,2])),[2,3,1]);
            Trial.Force(i).Processing.smooth = Processing.Force.smethod.type;
        
        % Method 3: Moving average (window of [smethod.parameter] frames)
        elseif strcmp(Processing.Force.smethod.type,'movmean')
            Trial.Force(i).Signal.smooth     = permute(smoothdata(permute(Trial.Force(i).Signal.filt,[3,1,2]),'movmean',Processing.Force.smethod.parameter),[2,3,1]);
            Trial.Force(i).Processing.smooth = 'movmean';
        
        % Method 4: Moving average (window of [smethod.parameter] frames)
        elseif strcmp(Processing.Force.smethod.type,'movmedian')
            Trial.Force(i).Signal.smooth     = permute(smoothdata(permute(Trial.Force(i).Signal.filt,[3,1,2]),'movmedian',Processing.Force.smethod.parameter),[2,3,1]);
            Trial.Force(i).Processing.smooth = 'movmedian';
        
        % Method 5: Signal root mean square (RMS) (window of [smethod.parameter] frames)
        elseif strcmp(Processing.Force.smethod.type,'rms')
            Trial.Force(i).Signal.smooth     = permute(envelope(permute(Trial.Force(i).Signal.filt,[3,1,2]),Processing.Force.smethod.parameter,'rms'),[2,3,1]);
            Trial.Force(i).Processing.smooth = 'rms';
        end
               
    end
end