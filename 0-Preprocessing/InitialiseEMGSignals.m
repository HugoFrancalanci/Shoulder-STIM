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
% Dependencies : None
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function Trial = InitialiseEMGSignals(emgSet,Trial,Analog)

if ~strcmp(cell2mat(emgSet(1,1)),'')
    for i = 1:size(emgSet,1)
        Trial.EMG(i).label             = cell2mat(emgSet(i,2));
        if isfield(Analog, emgSet(i,1))
            Trial.EMG(i).Signal.raw    = permute(Analog.(cell2mat(emgSet(i,1))),[2,3,1]);
        else
            Trial.EMG(i).Signal.raw    = [];
        end
        Trial.EMG(i).Signal.filt       = [];
        Trial.EMG(i).Signal.rect       = [];
        Trial.EMG(i).Signal.smooth     = [];
        Trial.EMG(i).Signal.units      = 'V';
        Trial.EMG(i).Processing.filt   = 'none';
        Trial.EMG(i).Processing.smooth = 'none';
    end
end