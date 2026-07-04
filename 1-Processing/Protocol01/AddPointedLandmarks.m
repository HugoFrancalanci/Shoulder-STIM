% Author     :   F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   August 2023
% -------------------------------------------------------------------------
% Description:   Define pointed landmarks in the inertial coordinate system
% -------------------------------------------------------------------------
% Dependencies : To be defined
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function [Trial,Vmarker] = AddPointedLandmarks(Trial,Marker,Vmarker,Event,pointList,stylus)

disp('  - Ajout des marqueurs pointés');
if contains(Trial.file,'CALIBRATION3')       
	Vmarker   = [];
	if strcmp(stylus,'Stylus1')
		% Set local position of the stylus tip 
		STY06 = [0.00101827958486882; -0.230005152480007; -0.000106002004537661];     
		% Define stylus coordinate system
		Os = Marker.STY04;
		Ys = (Marker.STY02-Marker.STY05);
		Ys = Ys./sqrt(Ys(:,1).^2+Ys(:,2).^2+Ys(:,3).^2);
		Xs = cross((Marker.STY03-Marker.STY05),(Marker.STY01-Marker.STY05));
		Xs = Xs./sqrt(Xs(:,1).^2+Xs(:,2).^2+Xs(:,3).^2);   
		Zs = cross(Xs,Ys);
		Xs = cross(Ys,Zs);
		Rs = [permute(Xs,[2,3,1]) permute(Ys,[2,3,1]) permute(Zs,[2,3,1])];
		ds = permute(Os,[2,3,1]);
		% Get the global position of the stylus tip at each event
		for ievent = 1:length(Event.Remote)
			temp(:,:,ievent) = Rs(:,:,fix(Event.Remote(ievent)*Trial.fmarker))*STY06+ds(:,:,fix(Event.Remote(ievent)*Trial.fmarker));
		end
	elseif strcmp(stylus,'Stylusb')
		% Set local position of the stylus tip 
		STY05 = [-7*1e-3; -80*1e-3; 0];     
		% Define stylus coordinate system
		Os = Marker.STY04;
		Ys = (Marker.STY02-Marker.STY04);
		Ys = Ys./sqrt(Ys(:,1).^2+Ys(:,2).^2+Ys(:,3).^2);
		Xs = cross((Marker.STY03-Marker.STY04),(Marker.STY01-Marker.STY04));
		Xs = Xs./sqrt(Xs(:,1).^2+Xs(:,2).^2+Xs(:,3).^2);   
		Zs = cross(Xs,Ys);
		Xs = cross(Ys,Zs);
		Rs = [permute(Xs,[2,3,1]) permute(Ys,[2,3,1]) permute(Zs,[2,3,1])];
		ds = permute(Os,[2,3,1]);
		% Get the global position of the stylus tip at each event
		for ievent = 1:length(Event.Remote)
			temp(:,:,ievent) = Rs(:,:,fix(Event.Remote(ievent)*Trial.fmarker))*STY05+ds(:,:,fix(Event.Remote(ievent)*Trial.fmarker));
		end
	end
    % Store in local coordinate system
    for ievent = 1:length(Event.Remote)
        if strcmp(pointList{ievent,1},'SXS')
            % Store the virtual marker in a thorax technical coordinate system
            frame                         = fix(Event(ievent).Remote*Trial.fmarker);
            Ot                            = Marker.SJN(frame,:);
            Yt                            = (Marker.SJN(frame,:)-Marker.SME(frame,:));
            Yt                            = Yt./sqrt(Yt(:,1).^2+Yt(:,2).^2+Yt(:,3).^2);
            Zt                            = cross((Marker.SME(frame,:)-Marker.TV5(frame,:)),(Marker.CV7(frame,:)-Marker.TV5(frame,:)));
            Zt                            = Zt./sqrt(Zt(:,1).^2+Zt(:,2).^2+Zt(:,3).^2);   
            Xt                            = cross(Yt,Zt); 
            Zt                            = cross(Xt,Yt);
            T_ics_t                       = [[Xt' Yt' Zt'] Ot'; 0 0 0 1]; % from t to ics
            temp2                         = inv(T_ics_t)*[temp(:,:,ievent);1];
            Vmarker.(pointList{ievent,1}) = temp2(1:3);
        end
    end
    % Add virtual markers in calibration trial
    for ivmarker = 1:length(fieldnames(Vmarker))
        for ipoint = 1:length(pointList)
            if strcmp(pointList{ivmarker,1},'SXS')
                % Store the virtual marker in the inertial coordinate system
                Ot = Marker.SJN;
                Yt = (Marker.SJN-Marker.SME);
                Yt = Yt./sqrt(Yt(:,1).^2+Yt(:,2).^2+Yt(:,3).^2);
                Zt = cross((Marker.SME-Marker.TV5),(Marker.CV7-Marker.TV5));
                Zt = Zt./sqrt(Zt(:,1).^2+Zt(:,2).^2+Zt(:,3).^2);   
                Xt = cross(Yt,Zt); 
                Zt = cross(Xt,Yt);
                for t = 1:size(Ot,1)
                    clear T_ics_t;
                    T_ics_t                                 = [[Xt(t,:)' Yt(t,:)' Zt(t,:)'] Ot(t,:)'; 0 0 0 1]; % from t to ics
                    temp                                    = T_ics_t*[Vmarker.(pointList{ipoint,1});1];
                    Trial.Vmarker(1).type                   = 'pointed landmark';
                    Trial.Vmarker(1).Body.Segment.label     = 'Thorax';
                    Trial.Vmarker(1).Trajectory.full(:,:,t) = temp(1:3);
                end
            end
        end
    end
else
    for ivmarker = 1:length(fieldnames(Vmarker))
        for ipoint = 1:length(pointList)
            if strcmp(pointList{ipoint,1},'SXS')
                % Store the virtual marker in the inertial coordinate system
                Ot = Marker.SJN;
                Yt = (Marker.SJN-Marker.SME);
                Yt = Yt./sqrt(Yt(:,1).^2+Yt(:,2).^2+Yt(:,3).^2);
                Zt = cross((Marker.SME-Marker.TV5),(Marker.CV7-Marker.TV5));
                Zt = Zt./sqrt(Zt(:,1).^2+Zt(:,2).^2+Zt(:,3).^2);   
                Xt = cross(Yt,Zt); 
                Zt = cross(Xt,Yt);
                for t = 1:size(Ot,1)
                    clear T_ics_t;
                    T_ics_t                                 = [[Xt(t,:)' Yt(t,:)' Zt(t,:)'] Ot(t,:)'; 0 0 0 1]; % from t to ics
                    temp                                    = T_ics_t*[Vmarker.(pointList{ipoint,1});1];
                    Trial.Vmarker(1).type                   = 'pointed landmark';
                    Trial.Vmarker(1).Body.Segment.label     = 'Thorax';
                    Trial.Vmarker(1).Trajectory.full(:,:,t) = temp(1:3);
                end
            end
        end
    end    
end