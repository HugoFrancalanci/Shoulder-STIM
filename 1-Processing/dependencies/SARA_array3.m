% Function: SARA_array3
% Version: 1
% Software : Matlab R14
% OS: PC Windows XP
%__________________________________________________________________________
%
% Function description:
% Computation of the averaged Axis of Rotation (AoR) between two segments
% (e.g. proximal and distal) by Symmetrical Axis of Rotation Approach
% (SARA) method
%
% References:
% JF O'Brien, BE Bodenheimer, GJ Brostow, JK Hodgins. Automatic joint
% parameter estimation from magnetic motion capture data. In Proceedings
% of Graphics Interface Conference. S Fels, P Poulin (Eds). Montréal,
% Canada: Canadian Human-Computer Communications Society, 2000: 53-60.
% RM Ehrig, WR Taylor, GN Duda, MO Heller. A survey of formal methods for
% determining functional joint axes. Journal of Biomechanics
% 2007; 40: 2150–2157.
%__________________________________________________________________________
%
% Inputs:
% Ti        (4*4*n) = Homogenous matrix of transformation
%                     from Rglobal to Rsegment i (e.g. proximal)
% Tj        (4*4*n) = Homogenous matrix of transformation
%                     from Rglobal to Rsegment j (e.g. distal)
%
% Outputs:
% a        (3*1*n) = Orientation of AoR expressed in Rglobal
% asi      (3*1) = Orientation of AoR expressed
%                  in Rsegment i (e.g. proximal)
% asj      (3*1) = Orientation of AoR expressed
%                  in Rsegment j (e.g. distal)
% rA        (3*1*n) = Position of a point A of AoR
%                     expressed in Rglobal
% rAsi      (3*1) = Position of a point A of AoR
%                   expressed in Rsegment i (e.g. proximal)
% rAsj      (3*1) = Position of a point A of AoR
%                   expressed in Rsegment j (e.g. distal)
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

function [a,asi,asj,rA,rAsi,rAsj] = SARA_array3(Ti,Tj)

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

% Singular Value Decomposition
[U,S,V] = svd(R);

% Orientation of AoR expressed in Rglobal
a = mean([Mprod_array3(Ti(1:3,1:3,:),...
    repmat(V(1:3,6)/norm(V(1:3,6)),[1,1,n])), ...
    Mprod_array3(Tj(1:3,1:3,:),...
    repmat(V(4:6,6)/norm(V(4:6,6)),[1,1,n]))],2);

if nargout == 3
    
    % Orientation of AoR expressed in Rsegment i and j
    asi = V(1:3,6)/norm(V(1:3,6)); % Normalized
    asj = V(4:6,6)/norm(V(4:6,6)); % Normalized
    
elseif nargout == 6
    
    % Orientation of AoR expressed in Rsegment i and j
    asi = V(1:3,6)/norm(V(1:3,6)); % Normalized
    asj = V(4:6,6)/norm(V(4:6,6)); % Normalized
    
    % Solution of the least square system with minimal norm
    for i = 1:5
        xi(:,i) = U(:,i)'*p*V(:,i)/S(i,i);
    end
    x = sum(xi,2);
    
    % Position of a point A of AoR in Rsegment i and j
    % First three components of x orthogonalised relative to ai
    rAsi = x(1:3,1) - (x(1:3,1)'*asi)*asi;
    % Last three components of x orthogonalised  relative to aj
    rAsj = x(4:6,1) - (x(4:6,1)'*asj)*asj;
    
    % Position of a point A of AoR expressed in Rglobal
    rA = mean([Mprod_array3(Ti,repmat([rAsi;1], [1,1,n])), ...
        Mprod_array3(Tj,repmat([rAsj;1], [1,1,n]))],2);
    rA(4,:,:) = [];
    
end
