% Author       : F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License      : Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code  : To be defined
% Reference    : To be defined
% Date         : July 2022
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

function Trial = InitialiseEmgSignals(EmgSet,Trial,Trial2,Emg)

if contains(Trial.file,'CALIBRATION3') % May be used to defined EMG baselines
    for iemg = 1:length(EmgSet)
        Trial.Emg(iemg).label = EmgSet{iemg,2};
        Trial.Emg(iemg).type  = '';
if isfield(Emg, EmgSet{iemg,2})
if ~isnan(sum(sum(Emg.(EmgSet{iemg,2}))))
Trial.Emg(iemg).baseline    = Emg.(EmgSet{iemg,2});
Trial.Emg(iemg).Signal.full = permute(Emg.(EmgSet{iemg,2}),[2,3,1]);
                Trial.Emg(iemg).Signal.envelop = [];
                Trial.Emg(iemg).Signal.onset = [];
            else
                Trial.Emg(iemg).baseline = [];
                Trial.Emg(iemg).Signal.full = [];
                Trial.Emg(iemg).Signal.envelop = [];
                Trial.Emg(iemg).Signal.onset = [];
            end
            Trial.Emg(iemg).Signal.rcycle = [];
            Trial.Emg(iemg).Signal.lcycle = [];
            Trial.Emg(iemg).Signal.units = '%';            
        end
    end
elseif contains(Trial.file,'ANALYTIC')
    for iemg = 1:length(EmgSet)
        Trial.Emg(iemg).label = EmgSet{iemg,2};
        Trial.Emg(iemg).type  = '';
if isfield(Emg, EmgSet{iemg,2})
if ~isnan(sum(sum(Emg.(EmgSet{iemg,2}))))
Trial.Emg(iemg).baseline    = Emg.(EmgSet{iemg,2});
Trial.Emg(iemg).Signal.full = permute(Emg.(EmgSet{iemg,2}),[2,3,1]);
                Trial.Emg(iemg).Signal.envelop = [];
                Trial.Emg(iemg).Signal.onset = [];
            else
                Trial.Emg(iemg).baseline = [];
                Trial.Emg(iemg).Signal.full = [];
                Trial.Emg(iemg).Signal.envelop = [];
                Trial.Emg(iemg).Signal.onset = [];
            end
            Trial.Emg(iemg).Signal.rcycle = [];
            Trial.Emg(iemg).Signal.lcycle = [];
            Trial.Emg(iemg).Signal.units = '%';            
        end
    end
end