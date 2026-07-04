% Function: SCoRE_array3
% Version: 1
% Software : Matlab R14
% OS: PC Windows XP
%__________________________________________________________________________
%
% Function description:
% Computation of the averaged Center of Rotation (CoR) between two segments
% (e.g. proximal and distal) by Symmetrical Centre of Rotation Estimation
% (SCoRE) method
%
% References:
% RM Ehrig, WR Taylor, GN Duda, MO Heller. A survey of formal methods for 
% determining the centre of rotation of ball joints. Journal of Biomechanics
% 2006; 39:  2798–2809.
%__________________________________________________________________________
%
% Inputs:
% Ti        (4*4*n) = Homogenous matrix of transformation
%                     from Rglobal to Rsegment i (e.g. proximal)
% Tj        (4*4*n) = Homogenous matrix of transformation
%                     from Rglobal to Rsegment j (e.g. distal)
%
% Outputs:
% rC        (3*1*n) = Position of CoR expressed in Rglobal
% rCsi      (3*1) = Position of CoR expressed 
%                   in Rsegment i (e.g. proximal)
% rCsj      (3*1) = Position of CoR expressed 
%                   in Rsegment j (e.g. distal)
%
%__________________________________________________________________________
%
% Called functions:
% Mprod_array3.m
%__________________________________________________________________________
%
% Author: Raphael DUMAS
% Date of creation: February 2009
% Projet:
% Supervisor:
%__________________________________________________________________________
%
% Modified by:
% Date of modification:
% Modification:
%__________________________________________________________________________

function [rC,rCsi,rCsj] = SCoRE_array3(Ti,Tj)

% Number of frames
n = size(Ti,3);

% Matrices of least square system [Ri - Rj]*[rCsi;rCsj] = [rPj-rPi]
Ri(1:3:3*n-2,1:3) = permute(Ti(1,1:3,:), [3,2,1]);
Ri(2:3:3*n-1,1:3) = permute(Ti(2,1:3,:), [3,1,2]);
Ri(3:3:3*n,1:3) = permute(Ti(3,1:3,:), [3,1,2]);
Rj(1:3:3*n-2,1:3) = permute(Tj(1,1:3,:), [3,2,1]);
Rj(2:3:3*n-1,1:3) = permute(Tj(2,1:3,:), [3,1,2]);
Rj(3:3:3*n,1:3) = permute(Tj(3,1:3,:), [3,1,2]);
R = [Ri -Rj];

p(1:3:3*n-2,1) = permute(Tj(1,4,:) - Ti(1,4,:), [3,2,1]);
p(2:3:3*n-1,1) = permute(Tj(2,4,:) - Ti(2,4,:), [3,1,2]);
p(3:3:3*n,1) = permute(Tj(3,4,:) - Ti(3,4,:), [3,1,2]);

% Pseudo-inversion
c = pinv(R)*p;

% Position of CoR expressed in Rglobal
rC = mean([Mprod_array3(Ti,repmat([c(1:3,1);1],[1,1,n])), ...
    Mprod_array3(Tj,repmat([c(4:6,1);1],[1,1,n]))],2);
rC(4,:,:) = [];

if nargout == 3
    % Position of CoR expressed in Rsegment i and j
    rCsi = c(1:3,1);
    rCsj = c(4:6,1);
end

