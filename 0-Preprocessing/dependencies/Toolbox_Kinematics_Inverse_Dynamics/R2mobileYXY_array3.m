% FUNCTION
% R2mobileYXY_array3.m
%__________________________________________________________________________
%
% PURPOSE
% Computation of Euler angles from rotation matrix (with YXY mobile sequence
% for joint kinematics) 
%
% SYNOPSIS
% Joint_Euler_Angles = R2mobileYXY_array3(R)
%
% INPUT
% R (i.e., rotation matrix) 
%
% OUTPUT
% Joint_Euler_Angles (i.e., tetha1, tetha2, tetha3, in line)
%
% DESCRIPTION
% Computation, for all frames (i.e., in 3rd dimension, cf. data structure
% in user guide), of the Euler angles (tetha1, tetha2, tetha3) from the
% rotation matrix (R) using a sequence of mobile axes YXY
%
% REFERENCES
%__________________________________________________________________________
%
% CALLED FUNCTIONS (FROM 3D INVERSE DYNAMICS TOOLBOX) 
% None
% 
% MATLAB VERSION
% Matlab R2007b
%__________________________________________________________________________
%
% CHANGELOG
% Created by Raphaël Dumas
% November 2012
% Correction by Florent Moissenet
% September 2021
% Joint_Euler_Angles(1,3,:) = atan2(R(2,1,:),-R(3,2,:)) > Joint_Euler_Angles(1,3,:) = atan2(R(2,1,:),-R(2,3,:));
% Correction by Florent Moissenet and Pierre Puchaud
% July 2024 - Manage the ambiguity where theta2 = acos(R(2,2,:)) fails to
% distinguish between theta2 and -theta2
% if mean(R(2,1,:)) < 0 || mean(R(2,3,:)) > 0 % Case where Theta2 < 0
%     Joint_Euler_Angles(1,2,:) = -acos(R(2,2,:));
% else % Case where Theta2 > 0
%     Joint_Euler_Angles(1,2,:) = acos(R(2,2,:));
% end
% Extra +pi correction on first and third angles if beta negative.
%_________________________________________________________________________

function Joint_Euler_Angles = R2mobileYXY_array3(R)
% Theta1: Orientation of plane of elevation (about Y proximal SCS axis)
Joint_Euler_Angles(1,1,:) = atan2(R(1,2,:),R(3,2,:));

% Theta3: Internal-External Rotation (about Y distal SCS axis)
Joint_Euler_Angles(1,3,:) = atan2(R(2,1,:),-R(2,3,:));

% Theta2: Elevation (about X floating axis)
if mean(R(2,1,:)) < 0 || mean(R(2,3,:)) > 0 % Case where Theta2 < 0
    Joint_Euler_Angles(1,2,:) = -acos(R(2,2,:));
    % Add pi to Theta1 and Theta3
    Joint_Euler_Angles(1,1,:) = Joint_Euler_Angles(1,1,:) + pi;
    Joint_Euler_Angles(1,3,:) = Joint_Euler_Angles(1,3,:) + pi;
else % Case where Theta2 > 0
    Joint_Euler_Angles(1,2,:) = acos(R(2,2,:));
end


