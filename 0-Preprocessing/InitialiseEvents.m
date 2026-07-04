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
% Dependencies : None
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function Trial = InitialiseEvents(eventSet,Trial,Event)

% Initialise Events
k = 1;
if ~strcmp(eventSet{1},'') % Empty list
    for i = 1:length(eventSet)
        if isfield(Event,eventSet{i})
            Trial.Event(k).label = eventSet{i};
            Trial.Event(k).value = round(Event.(eventSet{i})*Trial.fmarker)-Trial.n0+1;
            Trial.Event(k).units = 'frame';
            k                    = k+1;
        end
    end
end