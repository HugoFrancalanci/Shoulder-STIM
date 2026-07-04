% FUNCTION
% R2mobileZXY_array3.m
%__________________________________________________________________________
%
% PURPOSE
% Computation of Euler angles from rotation matrix (with ZXY mobile sequence
% for joint kinematics) 
%
% SYNOPSIS
% Joint_Euler_Angles = R2mobileZXY_array3(R)
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
% rotation matrix (R) using a sequence of mobile axes ZXY
%
% REFERENCES
% G Wu, S Siegler, P Allard, C Kirtley, A Leardini, D Rosenbaum, M Whittle,
% DD D'Lima, L Cristofolini, H Witte, O Schmid, I Stokes. ISB 
% recommendation on definitions of joint coordinate system of various 
% joints for the reporting of human joint motion - Part I: ankle, hip, and
% spine. Journal of Biomechanics 2002;35(4):543-8.
% G Wu, FC van der Helm, HE Veeger, M Makhsous, P Van Roy, C Anglin, 
% J Nagels, AR Karduna, K McQuade, X Wang, FW Werner, B Buchholz. ISB
% recommendation on definitions of joint coordinate systems of various
% joints for the reporting of human joint motion - Part II: shoulder, 
% elbow, wrist and hand. Journal of Biomechanics 2005;38(5):981-92.
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

function Joint_Euler_Angles = R2mobileZXY_array3(R)

% Tetha1 (about Z proximal SCS axis): e.g., flexion-extension at the knee
Joint_Euler_Angles(1,1,:) = atan2(-R(1,2,:),R(2,2,:));
% Tetha2 (about X floating axis): e.g., abduction-adduction at the knee
Joint_Euler_Angles(1,2,:) = asin(R(3,2,:)); 
% Tetha3 (about Y distal SCS axis): e.g., internal-external rotation at the knee
Joint_Euler_Angles(1,3,:) = atan2(-R(3,1,:),R(3,3,:)); 
