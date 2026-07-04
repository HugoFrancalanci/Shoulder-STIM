% MAIN PROGRAM
% Main_Joint_Kinematics.m
%__________________________________________________________________________
%
% PURPOSE
% Computation and plotting of 3D joint angles and displacements
%
% SYNOPSIS
% N/A (i.e., main program)
%
% DESCRIPTION
% Data loading, call of functions and plotting of joint coordinate system
% angles and displacements
%__________________________________________________________________________
%
% CALLED FUNCTIONS (FROM 3D INVERSE DYNAMICS TOOLBOX)
% Mprod_array3.m
% Tinv_array3.m
% Q2Twu_array3.m
% Q2Tuv_array3.m
% R2mobileZXY_array3.m
% R2mobileZYX_array3.m
% R2mobileXZY_array3.m
% R2mobileYXZ_array3.m
% Vnop_array3
%
% MATLAB VERSION
% Matlab R2012a
%__________________________________________________________________________
%
% CHANGELOG
% Created by Raphaël Dumas
% March 2010
%
% Modified by Raphaël Dumas
% June 2012
% Adaptation to upper limb with scapula
%
% Modified by Raphaël Dumas
% May 2017
% Adaptation to upper limb with scapula
%
%__________________________________________________________________________

% Number of frames
n = size(Segment(1).Q,3);

% Joint angles and displacements
for i = 1:2 % From i = 1 glenohumeral to i = 2 scapulo-thoracic
    
    if i == 2 % scapulo-thoracic
        % Transformation from the proximal segment axes
        % (with origin at endpoint P and with X = u)
        % to the distal segment axes
        % (with origin at point D and with Z = w)
        Joint(i).T = Mprod_array3(Tinv_array3(Q2Tuv_array3(Segment(i+1).Q)),...
            Q2Twu_array3(Segment(i).Q)); % Aligned on w axis of scapula
        % Displacements (from P of thorax to D of scapula) are not studied
    else
        % Transformation from the proximal segment axes
        % (with origin at endpoint D and with Z = w)
        % to the distal segment axes
        % (with origin at point P and with X = u)
        Joint(i).T = Mprod_array3(Tinv_array3(Q2Twu_array3(Segment(i+1).Q)),...
            Q2Tuv_array3(Segment(i).Q));
    end
    
end

% i = 1: glenohumeral
% XZY sequence of mobile axis in case of abduction movement
% Euler angles
Joint(1).Euler = R2mobileXZY_array3(Joint(1).T(1:3,1:3,:));
% Joint displacement about the Euler angle axes
Joint(1).tj = Vnop_array3(...
    Joint(1).T(1:3,4,:),... Di+1 to Pi in SCS of segment i+1
    repmat([1;0;0],[1 1 n]),... % Xi+1 in SCS of segment i+1
    Vnorm_array3(cross(repmat([1;0;0],[1 1 n]),Joint(1).T(1:3,2,:))),...
    Joint(1).T(1:3,2,:)); % Yi in SCS of segment i
% % Joint displacement about the XYZ axes of scapula
% Joint(1).tj = Joint(1).T(1:3,4,:);


% i = 2 scapulo-thoracic
% YXZ sequence of mobile axis
% Euler angles
Joint(2).Euler = R2mobileYXZ_array3(Joint(2).T(1:3,1:3,:));


% Gleno-humeral joint angles and displacements in case of abduction movement
AA1 = permute(Joint(1).Euler(1,1,:),[3,2,1])*180/pi;
FE1 = permute(Joint(1).Euler(1,2,:),[3,2,1])*180/pi;
IER1 = permute(Joint(1).Euler(1,3,:),[3,2,1])*180/pi;
AP1 = permute(Joint(1).tj(1,1,:),[3,2,1]);
LM1 = permute(Joint(1).tj(2,1,:),[3,2,1]);
PD1 = permute(Joint(1).tj(3,1,:),[3,2,1]);

% Scapulo-thoracic joint angles and displacements
IER2 = permute(Joint(2).Euler(1,1,:),[3,2,1])*180/pi;
AA2 = permute(Joint(2).Euler(1,2,:),[3,2,1])*180/pi;
FE2 = permute(Joint(2).Euler(1,3,:),[3,2,1])*180/pi;




if isempty(findobj('type','figure','name','p1'))
    
    h1 = figure('name','p1');
    hold on;
    
    % Figure for gleno-humeral
    
    % Flexion Extension
    hFE1 = subplot(3,3,1);
    hold on;
    plot(FE1);
    title('Gleno-Humeral Flexion (+) / Extension (-)');
    xlabel('Posture');
    ylabel('Angle (in degree)');
    % Adduction Abduction
    hAA1 = subplot(3,3,2);
    hold on;
    plot(AA1);
    title('Gleno-Humeral Adduction (+) / Abduction (-)');
    xlabel('Posture');
    ylabel('Angle (in degree)');
    % Internal External Rotation
    hIER1 = subplot(3,3,3);
    hold on;
    plot(IER1);
    title('Gleno-Humeral Internal (+) / External (-) Rotation');
    xlabel('Posture');
    ylabel('Angle (in degree)');
    % Lateral Medial
    hLM1 = subplot(3,3,4);
    hold on;
    plot(LM1*1000); % mm
    title('Gleno-Humeral Lateral (+) / Medial (-)');
    xlabel('Posture');
    ylabel('Displacement (in mm)');
    % Anterior Posterior
    hAP1 = subplot(3,3,5);
    hold on;
    plot(AP1*1000); % mm
    title('Gleno-Humeral Anterior (+) / Posterior (-)');
    xlabel('Posture');
    ylabel('Displacement (in mm)');
    % Proximal Distal
    hPD1 = subplot(3,3,6);
    hold on;
    plot(PD1*1000); % mm
    title('Gleno-Humeral Proximal (+) / Distal (-)');
    xlabel('Posture');
    ylabel('Displacement (in mm)');
    
    % Figure for scapulo-thoracic
    
    % Flexion Extension
    hFE2 = subplot(3,3,7);
    hold on;
    plot(FE2);
    title ('Scapulo-Thoracic Posterior Tilt (+) / Anterior Tilt (-)'); % 'Scapulo-Thoracic Flexion (+) / Extension (-)'
    xlabel('Posture');
    ylabel('Angle (in degree)');
    % Adduction Abduction
    hAA2 = subplot(3,3,8);
    hold on;
    plot(AA2);
    title ('Scapulo-Thoracic Downward Rotation (+) / Upward Rotation (-)'); % 'Scapulo-Thoracic Medial Rotation (+) / Lateral Rotation (-)'
    xlabel('Posture');
    ylabel('Angle (in degree)');
    % Internal External Rotation
    hIER2 = subplot(3,3,9);
    hold on;
    plot(IER2);
    title ('Scapulo-Thoracic Internal Rotation (+) / External Rotation (-)'); % 'Scapulo-Thoracic Protaction (+) / Retraction (-)'
    xlabel('Posture');
    ylabel('Angle (in degree)');
    
    
    
else % Overwrite
    
    figure(h1); hold on;
    
    % Figure for gleno-humeral
    subplot(hFE1); hold on; plot(FE1); % Flexion-extension
    subplot(hAA1); hold on; plot(AA1); % Adduction-abduction
    subplot(hIER1); hold on; plot(IER1); % Internal-external rotation
    subplot(hLM1); hold on; plot(LM1*1000); % Lateral-medial
    subplot(hAP1); hold on; plot(AP1*1000); % Anterior-posterior
    subplot(hPD1); hold on; plot(PD1*1000); % Proximal-distal
    
    % Figure for scapulo-thoracic
    subplot(hFE2); hold on; plot(FE2); % Flexion-extension
    subplot(hAA2); hold on; plot(AA2); % Adduction-abduction
    subplot(hIER2); hold on; plot(IER2); % Internal-external rotation
    
end




