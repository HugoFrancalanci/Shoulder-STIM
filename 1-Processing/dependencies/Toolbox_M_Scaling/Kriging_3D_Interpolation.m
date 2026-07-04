% FUNCTION
% Kriging_3D_Interpolation
%__________________________________________________________________________
%
% PURPOSE
% Non-rigid registration and scaling of an initial mesh based on a set of 
% control points
%
% SYNOPSIS
% [Meshj,Rotation,Translation,Homothety,Stretch,Model,SSE] = ...
%    Kriging_3D_Interpolation (Meshi,Xi,Xj)
%
% INPUT
% Meshi (i.e., matrix l*3 of the l initial 3D mesh nodes)
% Xi (i.e., matrix n*3 of the n initial 3D control points)
% Xj (i.e., matrix n*3 of the n final 3D control points)
%
% OUTPUT
% Meshj (i.e., matrix l*3 of the l final 3D mesh nodes)
% Rotation (i.e., matrix 3*3 of the rigid part of the drift)
% Translation (i.e., vector 3*1 of the rigid part of the drift)
% Homothety (i.e., matrix 3*3 of the deformative part of the drift)
% Stretch (i.e., matrix 3*3 of the deformative part of the drift)
% Model (i.e., selected generalized covariance)
% SSE (i.e., sum of squared errors)
%
% DESCRIPTION
% Determination of the Kriging transformation (generalized covariance with
% the lower Kriging variance) from an initial position i to a final 
% position j, extraction of geometrical information and application to
% the initial mesh nodes
%
% REFERENCES
% R Dumas, L Cheze. Soft tissue artifact compensation by linear 3D 
% interpolation and approximation methods. Journal of Biomechanics
% 2009;42(13):2214–2217.
% F Trochu. A contouring program based on dual kriging interpolation.
% Engineering Computation 1993;9:160-177.
% JD Martin, TW Simpson. Use of kriging models to approximate deterministic
% computer models. American Institute of Aeronautics and Astronautics
% Journal 2005;43(4):853–863.
%__________________________________________________________________________
%
% CALLED FUNCTIONS (FROM 3D SCALING TOOLBOX) 
% Kriging.m
% 
% MATLAB VERSION
% Matlab R2007b
%__________________________________________________________________________
%
% CHANGELOG
% Created by Raphaël Dumas
% May 2011
%__________________________________________________________________________

function [Meshj,Rotation,Translation,Homothety,Stretch,Model,SSE] = ...
    Kriging_3D_Interpolation (Meshi,Xi,Xj)

% Number of control points
n = size(Xi,1);

%__________________________________________________________________________
%
% Generalized covariance selection
%__________________________________________________________________________

% Possible generalized covariance
M = {'Linear','Cubic','Gaussian','Multiquadratic', ...
    'Inverse multiquadratic','Logarithmic'};

% Initialization
BA_trial = [];

% Kriging
% [K  Xi  [B    [Xj
%  Xit 0]  A] =  0]
for s = 1:length(M) % Index of current model
    % Coefficients a, b and Kriging variance 
    [BA_trial(:,:,s),Var_trial(s,:)] = Kriging(Xi,Xj,M{s}); 
end

% Minimal mean (among x,y,z) of Kriging variance 
[mean_Var_min,Ind_min]= min(mean(Var_trial,2)); % Lower value
% Corresponding Kriging variance
Var = Var_trial(Ind_min,:); % 3 values on x,y,z
% Corresponding generalized covariance
Model = M(Ind_min);
% Corresponding coefficients a and b
B = BA_trial(1:n,:,Ind_min);
A = BA_trial(n+1:end,:,Ind_min);

%__________________________________________________________________________
%
% 3D interpolation
%__________________________________________________________________________

% Mesh nodes and control points 
% (may eventually consider control points twice
% if control point are part of the mesh nodes)
Datai = [Xi;Meshi]; % Data point

% Number of data points
ln =  size(Datai,1);

% Initialization
d = []; % 3D distance between points
K = []; % Function of d

for r = 1:ln % Index of current data point

    % Data point to control point 3D Euclidean distance
    for p = 1:n % Index of current control point
        d(r,p) = norm(Datai(r,:) - Xi(p,:));
    end
    
    % Generalized covariance
    switch Model{1}
        case 'Linear'
            K(r,:) = d(r,:);
        case 'Cubic'
            K(r,:) = d(r,:).^3;
        case 'Gaussian'
            K(r,:) = exp(-(d(r,:).^2));
        case 'Multiquadratic'
            K(r,:) = (d(r,:).^2 + ones(1,n)).^0.5;
        case 'Inverse multiquadratic'
            K(r,:) = (d(r,:).^2 + ones(1,n)).^-0.5;
        case 'Logarithmic'
            % Avoid log(0) by replacing 0 by 1
            K(r,:) = (d(r,:).^2).*log(d(r,:) + (d(r,:) == 0));
    end
    
    % First coordinate of Dataf for data point r
    Dataj(r,1) = ...
        A(1,1) + A(2,1)*Datai(r,1) + A(3,1)*Datai(r,2) + A(4,1)*Datai(r,3) + ... % Drift
        sum(B(:,1).*K(r,:)'); % Fluctuation
    
    % Second coordinate of Dataf for data point r
    Dataj(r,2) = A(1,2) + A(2,2)*Datai(r,1) + A(3,2)*Datai(r,2) + A(4,2)*Datai(r,3) + ... % Drift
        sum(B(:,2).*K(r,:)'); % Fluctuation
    
    % Third coordinate of Dataf for data point r
    Dataj(r,3) = A(1,3) + A(2,3)*Datai(r,1) + A(3,3)*Datai(r,2) + A(4,3)*Datai(r,3) + ... % Drift
        sum(B(:,3).*K(r,:)'); % Fluctuation
    
end

% Extract final mesh nodes from data points
Meshj = Dataj(n+1:end,:);

%__________________________________________________________________________
%
% Sum of squared errors (on control points)
%__________________________________________________________________________

SSE = sum((Xj - Dataj(1:n,:)).^2,1); % Should be negligible

%__________________________________________________________________________
%
% Interpetration of the drift
%__________________________________________________________________________

% Translation of the global origin considered as fixed
% with regards to the initial control points
Translation = A(1,1:3)'; % Parameters a0

% Singular Value Decomposition of matrix of parameters a1 a2 a3
[U,S,V] = svd(A(2:4,1:3)');

% Polar decomposition
% Rotation
Rotation = U*V';
% Homothety
Homothety = diag(diag(V*S*V'));
% Stretch
Stretch = inv(Homothety)*(V*S*V');

