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

function Trial = InitialiseForceSignals(forceSet,Trial,Analog)
         
% Initialise force signals
if ~strcmp(cell2mat(forceSet(1,1)),'') % Empty list
    for i = 1:size(forceSet,1)
        Trial.Force(i).label              = cell2mat(forceSet(i,2));
        if isfield(Analog,forceSet(i,1))
            Trial.Force(i).Signal.raw     = permute(Analog.(cell2mat(forceSet(i,1))),[2,3,1]);
            Trial.Force(i).Signal.filt    = [];
            Trial.Force(i).Signal.smooth  = [];
            Trial.Force(i).Signal.units   = 'V';
        elseif isfield(Analog,forceSet(i+size(forceSet,1)/2,1)) % Alternative name
            Trial.Force(i).Signal.raw     = permute(Analog.(cell2mat(forceSet(i+size(forceSet,1)/2,1))),[2,3,1]);
            Trial.Force(i).Signal.filt    = [];
            Trial.Force(i).Signal.smooth  = [];
            Trial.Force(i).Signal.units   = 'V';
        else
            Trial.Force(i).Signal.raw     = [];
            Trial.Force(i).Signal.filt    = [];
            Trial.Force(i).Signal.smooth  = [];
            Trial.Force(i).Signal.units   = 'V';
        end
        Trial.Force(i).Processing.filt    = 'none';
        Trial.Force(i).Processing.smooth  = 'none';
    end
end