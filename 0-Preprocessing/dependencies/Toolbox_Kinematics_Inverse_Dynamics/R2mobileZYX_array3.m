% FUNCTION
% R2mobileZYX_array3.m
%__________________________________________________________________________
%
% PURPOSE
% Computation of Euler angles from rotation matrix (with ZYX mobile sequence
% for joint kinematics) 
%
% SYNOPSIS
% Joint_Euler_Angles = R2mobileZYX_array3(R)
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
% rotation matrix (R) using a sequence of mobile axes ZYX
%
% REFERENCE
% GK Cole, BM Nigg, JL Ronsky MR Yeadon. Application of the joint 
% coordinate system to three-dimensional joint attitude and movement 
% representation: a standardisation proposal. Journal of Biomechanical 
% Engineering 1993; 115(4): 344-349
% R Dumas, T Robert, V Pomero, L Cheze. Joint and segment coordinate 
% systems revisited. Computer Methods in Biomechanics and Biomedical 
% Engineering 2012;15(Suppl 1):183-5
%__________________________________________________________________________
%
% CALLED FUNCTIONS
% (from 3D kinematics and inverse dynamics toolbox) 
% None
% 
% MATLAB VERSION
% Matlab R2016a
%__________________________________________________________________________
%
% CHANGELOG
% Created by Raphaël Dumas
% March 2010
%
% Modified by Raphaël Dumas
% July 2016
% Last updates for Matlab Central
%__________________________________________________________________________
%
% Licence
% Toolbox distributed under BSD license
%__________________________________________________________________________

function Joint_Euler_Angles = R2mobileZYX_array3(R)

% Tetha1 (about Z proximal SCS axis): e.g., flexion-extension at the ankle
Joint_Euler_Angles(1,1,:) = atan2(R(2,1,:),R(1,1,:));
 % Tetha2 (about Y floating axis): e.g., abduction-adduction at the ankle
Joint_Euler_Angles(1,2,:) = asin(-R(3,1,:));
% Tetha3 (about X distal SCS axis): e.g., internal-external rotation at the ankle 
Joint_Euler_Angles(1,3,:) = atan2(R(3,2,:),R(3,3,:)); 
