% Author     :   F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   June 2022
% -------------------------------------------------------------------------
% Description:   To be defined
% -------------------------------------------------------------------------
% Dependencies : To be defined
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function Units = SetUnits(Trial)

% Get units used in the input C3D files
Units.input = btkGetPointsUnit(Trial(1).btk,'Marker');
% Set units used in the output C3D files
Units.output = 'm'; % To be adapted to your needs
% Set the units required in the output C3D files
if strcmp(Units.input,'mm')
    if strcmp(Units.output,'mm')
        Units.ratio = 1;
    elseif strcmp(Units.output,'m')
        Units.ratio = 1e-3;
    end
elseif strcmp(Units.input,'m')
    if strcmp(Units.output,'mm')
        Units.ratio = 1e3;
    elseif strcmp(Units.output,'m')
        Units.ratio = 1;
    end
end 