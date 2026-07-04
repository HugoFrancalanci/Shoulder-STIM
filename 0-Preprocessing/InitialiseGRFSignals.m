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

function Trial = InitialiseGRFSignals(grfSet,Trial,GRF,Units)

% Initialise GRF
k = 1;
if ~isempty(GRF)
    for i = grfSet                        
        % Get corner and origin
        temp                 = btkGetForcePlatforms(Trial.btk);
        Trial.GRF(k).corners = temp(i).corners*Units.ratio;
        clear temp;
        % Initialise CoP, force and moment
        Trial.GRF(k).Signal.P.raw(:,1,:) = permute(GRF(i).P,[2,3,1]);
        Trial.GRF(k).Signal.F.raw(:,1,:) = permute(GRF(i).F,[2,3,1]);
        Trial.GRF(k).Signal.M.raw(:,1,:) = permute(GRF(i).M,[2,3,1])*Units.ratio;
        Trial.GRF(k).Signal.P.filt     = [];
        Trial.GRF(k).Signal.F.filt     = [];
        Trial.GRF(k).Signal.M.filt     = [];
        Trial.GRF(k).Signal.P.smooth   = [];
        Trial.GRF(k).Signal.F.smooth   = [];
        Trial.GRF(k).Signal.M.smooth   = [];
        Trial.GRF(k).Signal.P.units    = Units.output;
        Trial.GRF(k).Signal.F.units    = 'N';
        if strcmp(Units.output,'mm')
            Trial.GRF(k).Signal.M.units = 'Nmm';
        elseif strcmp(Units.output,'m')
            Trial.GRF(k).Signal.M.units = 'Nm';
        end
        Trial.GRF(k).Processing.zero   = 'none';
        Trial.GRF(k).Processing.filt   = 'none';
        Trial.GRF(k).Processing.smooth = 'none';  
        Trial.GRF(k).Processing.resamp = 'none'; 
        k                              = k+1; 
    end    
end