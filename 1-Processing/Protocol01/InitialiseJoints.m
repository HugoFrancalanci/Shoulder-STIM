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
% Description  : Initialise the Joint structure
% Inputs       : Trial (structure)
% Outputs      : Trial (structure)
% -------------------------------------------------------------------------
% Dependencies : None
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function Trial = InitialiseJoints(Trial)

jointLabels = {'RHT','RGH','RST','RAC','RSC', ...
               'LHT','LGH','LST','LAC','LSC'};

for i = 1:length(jointLabels)
    Trial.Joint(i).label        = jointLabels{i};
    Trial.Joint(i).T.full       = [];
    Trial.Joint(i).T.rcycle     = [];
    Trial.Joint(i).T.lcycle     = [];
    Trial.Joint(i).Euler.full   = [];
    Trial.Joint(i).Euler.rcycle = [];
    Trial.Joint(i).Euler.lcycle = [];
    Trial.Joint(i).Euler.units  = '°deg';
    Trial.Joint(i).dj.full      = [];
    Trial.Joint(i).dj.rcycle    = [];
    Trial.Joint(i).dj.lcycle    = [];
    Trial.Joint(i).dj.units     = 'm';
    Trial.Joint(i).sequence     = '';
end