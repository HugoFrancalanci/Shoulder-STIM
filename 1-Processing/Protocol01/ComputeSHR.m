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

function Trial = ComputeSHR(c3dFiles,Trial,Reference)

if contains(c3dFiles.name,'ANALYTIC2') || contains(c3dFiles.name,'ANALYTIC5') || contains(c3dFiles.name,'ANALYTIC1') % Only applied on elevation tasks
    % Right scapulo humeral rhythm computation        
    for icycle = 1:size(Trial.Joint(1).Euler.rcycle,4)
        % Set frames of interest
        if contains(c3dFiles.name,'ANALYTIC2')
            imax = find(abs(Trial.Joint(1).Euler.rcycle(:,1,:,icycle))==max(abs(Trial.Joint(1).Euler.rcycle(:,1,:,icycle))));
            imin = find(abs(Trial.Joint(1).Euler.full(:,1,:))==min(abs(Trial.Joint(1).Euler.full(:,1,:))));
        elseif contains(c3dFiles.name,'ANALYTIC5')
            imax = find(abs(Trial.Joint(1).Euler.rcycle(:,1,:,icycle))==max(abs(Trial.Joint(1).Euler.rcycle(:,1,:,icycle))));
            imin = find(abs(Trial.Joint(1).Euler.full(:,1,:))==min(abs(Trial.Joint(1).Euler.full(:,1,:))));
        elseif contains(c3dFiles.name,'ANALYTIC1')
            imax = find(abs(Trial.Joint(1).Euler.rcycle(:,3,:,icycle))==max(abs(Trial.Joint(1).Euler.rcycle(:,3,:,icycle))));
            imin = find(abs(Trial.Joint(1).Euler.full(:,3,:))==min(abs(Trial.Joint(1).Euler.full(:,3,:))));
        end 
        % Compute 3D joint contributions and SHR (Robert-Lachaine et al., 2015)       
        for iframe = 1:101 % Cycle frames (%)
            % Define rotation matrices
            R_ICS_T     = Trial.Segment(4).T.rcycle(1:3,1:3,iframe,icycle);
            R_ICS_S     = Trial.Segment(2).T.rcycle(1:3,1:3,iframe,icycle);
            R_ICS_H     = Trial.Segment(1).T.rcycle(1:3,1:3,iframe,icycle);
            R_T_S       = inv(R_ICS_T)*R_ICS_S;
            R_S_H       = inv(R_ICS_S)*R_ICS_H;
            % Define reference rotation matrices
            R_ICS_T_ref = Reference.Segment(4).T.full(1:3,1:3,imin);
            R_ICS_S_ref = Reference.Segment(2).T.full(1:3,1:3,imin);
            R_ICS_H_ref = Reference.Segment(1).T.full(1:3,1:3,imin);
            R_T_S_ref   = inv(R_ICS_T_ref)*R_ICS_S_ref;
            R_S_H_ref   = inv(R_ICS_S_ref)*R_ICS_H_ref;
            % Compute 3D joint contributions
            C_HT        = inv(R_T_S_ref)*R_T_S*inv(R_S_H_ref)*R_S_H;
            C_ST        = inv(R_T_S_ref)*R_T_S*inv(R_S_H_ref)*R_S_H_ref;
            % Store resulting angles
            theta_HT(iframe) = acosd(C_HT(2,2)); % YXY Euler sequence
            theta_ST(iframe) = acosd(C_ST(2,2)); % YXY Euler sequence
            theta_GH(iframe) = theta_HT(iframe)-theta_ST(iframe);
            SHR(iframe)      = theta_GH(iframe)/theta_ST(iframe);
        end
        % ELEVATION
        clear range theta_HT1 theta_ST1 theta_GH1 SHR1;
        % Compute best-fit polynomial curves (3th order) between 30° and 90°
        angleMin              = 30;
        angleMax              = 90;
        range                 = min(find(theta_HT(1:imax)>=angleMin)):max(find(theta_HT(1:imax)<=angleMax));
        [theta_HT1,theta_ST1] = interpoly3(theta_HT(range),theta_ST(range),angleMin,angleMax);
        [~,theta_GH1]         = interpoly3(theta_HT(range),theta_GH(range),angleMin,angleMax);
        [~,SHR1]              = interpoly3(theta_HT(range),SHR(range),angleMin,angleMax);
        % Store results
        Trial.SHR(1).label                             = 'Right scapulo-humeral rhythm';
        Trial.SHR(1).theta_HT(1).rcycle(1,1,:,icycle)  = permute(theta_HT1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(1).theta_ST(1).rcycle(1,1,:,icycle)  = permute(theta_ST1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(1).theta_GH(1).rcycle(1,1,:,icycle)  = permute(theta_GH1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(1).SHR_curve(1).rcycle(1,1,:,icycle) = permute(SHR1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(1).SHR_mean(1).rcycle(1,1,:,icycle)  = mean(SHR1,'omitnan'); % scalar
        % RETURN
        clear range theta_HT1 theta_ST1 theta_GH1 SHR1;
        % Compute best-fit polynomial curves (3th order) between 30° and 90°
        angleMin              = 30;
        angleMax              = 90;
        range                 = imax+min(find(theta_HT(imax:end)<=angleMax))-1:imax+max(find(theta_HT(imax:end)>=angleMin))-1;
        [theta_HT1,theta_ST1] = interpoly3(theta_HT(range),theta_ST(range),angleMin,angleMax);
        [~,theta_GH1]         = interpoly3(theta_HT(range),theta_GH(range),angleMin,angleMax);
        [~,SHR1]              = interpoly3(theta_HT(range),SHR(range),angleMin,angleMax);
        % Store results
        Trial.SHR(1).label                             = 'Right scapulo-humeral rhythm';
        Trial.SHR(1).theta_HT(2).rcycle(1,1,:,icycle)  = permute(theta_HT1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(1).theta_ST(2).rcycle(1,1,:,icycle)  = permute(theta_ST1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(1).theta_GH(2).rcycle(1,1,:,icycle)  = permute(theta_GH1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(1).SHR_curve(2).rcycle(1,1,:,icycle) = permute(SHR1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(1).SHR_mean(2).rcycle(1,1,:,icycle)  = mean(SHR1,'omitnan'); % scalar
    end

    % Left scapulo humeral rhythm computation       
    for icycle = 1:size(Trial.Joint(6).Euler.lcycle,4)
        % Set frames of interest
        if contains(c3dFiles.name,'ANALYTIC2')
            imax = find(abs(Trial.Joint(6).Euler.lcycle(:,1,:,icycle))==max(abs(Trial.Joint(6).Euler.lcycle(:,1,:,icycle))));
            imin = find(abs(Trial.Joint(6).Euler.full(:,1,:))==min(abs(Trial.Joint(6).Euler.full(:,1,:))));
        elseif contains(c3dFiles.name,'ANALYTIC5')
            imax = find(abs(Trial.Joint(6).Euler.lcycle(:,1,:,icycle))==max(abs(Trial.Joint(6).Euler.lcycle(:,1,:,icycle))));
            imin = find(abs(Trial.Joint(6).Euler.full(:,1,:))==min(abs(Trial.Joint(6).Euler.full(:,1,:))));
        elseif contains(c3dFiles.name,'ANALYTIC1')
            imax = find(abs(Trial.Joint(6).Euler.lcycle(:,3,:,icycle))==max(abs(Trial.Joint(6).Euler.lcycle(:,3,:,icycle))));
            imin = find(abs(Trial.Joint(6).Euler.full(:,3,:))==min(abs(Trial.Joint(6).Euler.full(:,3,:))));
        end 
        % Compute 3D joint contributions and SHR (Robert-Lachaine et al., 2015)       
        for iframe = 1:101 % Cycle frames (%)
            % Define rotation matrices
            R_ICS_T     = Trial.Segment(4).T.lcycle(1:3,1:3,iframe,icycle);
            R_ICS_S     = Trial.Segment(6).T.lcycle(1:3,1:3,iframe,icycle);
            R_ICS_H     = Trial.Segment(5).T.lcycle(1:3,1:3,iframe,icycle);
            R_T_S       = inv(R_ICS_T)*R_ICS_S;
            R_S_H       = inv(R_ICS_S)*R_ICS_H;
            % Define reference rotation matrices
            R_ICS_T_ref = Reference.Segment(4).T.full(1:3,1:3,imin);
            R_ICS_S_ref = Reference.Segment(6).T.full(1:3,1:3,imin);
            R_ICS_H_ref = Reference.Segment(5).T.full(1:3,1:3,imin);
            R_T_S_ref   = inv(R_ICS_T_ref)*R_ICS_S_ref;
            R_S_H_ref   = inv(R_ICS_S_ref)*R_ICS_H_ref;
            % Compute 3D joint contributions
            C_HT        = inv(R_T_S_ref)*R_T_S*inv(R_S_H_ref)*R_S_H;
            C_ST        = inv(R_T_S_ref)*R_T_S*inv(R_S_H_ref)*R_S_H_ref;
            % Store resulting angles
            theta_HT(iframe) = acosd(C_HT(2,2)); % YXY Euler sequence
            theta_ST(iframe) = acosd(C_ST(2,2)); % YXY Euler sequence
            theta_GH(iframe) = theta_HT(iframe)-theta_ST(iframe);
            SHR(iframe)      = theta_GH(iframe)/theta_ST(iframe);
        end
        % ELEVATION
        clear range theta_HT1 theta_ST1 theta_GH1 SHR1;
        % Compute best-fit polynomial curves (3th order) between 30° and 90°
        angleMin              = 30;
        angleMax              = 90;
        range                 = min(find(theta_HT(1:imax)>=angleMin)):max(find(theta_HT(1:imax)<=angleMax));
        [theta_HT1,theta_ST1] = interpoly3(theta_HT(range),theta_ST(range),angleMin,angleMax);
        [~,theta_GH1]         = interpoly3(theta_HT(range),theta_GH(range),angleMin,angleMax);
        [~,SHR1]              = interpoly3(theta_HT(range),SHR(range),angleMin,angleMax);
        % Store results
        Trial.SHR(2).label                             = 'Left scapulo-humeral rhythm';
        Trial.SHR(2).theta_HT(1).lcycle(1,1,:,icycle)  = permute(theta_HT1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(2).theta_ST(1).lcycle(1,1,:,icycle)  = permute(theta_ST1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(2).theta_GH(1).lcycle(1,1,:,icycle)  = permute(theta_GH1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(2).SHR_curve(1).lcycle(1,1,:,icycle) = permute(SHR1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(2).SHR_mean(1).lcycle(1,1,:,icycle)  = mean(SHR1,'omitnan'); % scalar
        % RETURN
        clear range theta_HT1 theta_ST1 theta_GH1 SHR1;
        % Compute best-fit polynomial curves (3th order) between 30° and 90°
        angleMin              = 30;
        angleMax              = 90;
        range                 = imax+min(find(theta_HT(imax:end)<=angleMax))-1:imax+max(find(theta_HT(imax:end)>=angleMin))-1;
        [theta_HT1,theta_ST1] = interpoly3(theta_HT(range),theta_ST(range),angleMin,angleMax);
        [~,theta_GH1]         = interpoly3(theta_HT(range),theta_GH(range),angleMin,angleMax);
        [~,SHR1]              = interpoly3(theta_HT(range),SHR(range),angleMin,angleMax);
        % Store results
        Trial.SHR(2).label                             = 'Left scapulo-humeral rhythm';
        Trial.SHR(2).theta_HT(2).lcycle(1,1,:,icycle)  = permute(theta_HT1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(2).theta_ST(2).lcycle(1,1,:,icycle)  = permute(theta_ST1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(2).theta_GH(2).lcycle(1,1,:,icycle)  = permute(theta_GH1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(2).SHR_curve(2).lcycle(1,1,:,icycle) = permute(SHR1,[2,3,1]); % 61 point vector (30° to 90°)
        Trial.SHR(2).SHR_mean(2).lcycle(1,1,:,icycle)  = mean(SHR1,'omitnan'); % scalar
    end
end