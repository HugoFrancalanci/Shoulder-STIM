% FUNCTION
% Kriging
%__________________________________________________________________________
%
% PURPOSE
% Determination of the drift and fluctuation coefficients and of the
% Kriging variance
%
% SYNOPSIS
% [BA,Var] = Kriging(Xi,Xj,Model)
%
% INPUT
% Xi (i.e., matrix n*3 of the n initial 3D control points)
% Xj (i.e., matrix n*3 of the n final 3D control points)
% Model (i.e., generalized covariance)
%
% OUTPUT
% BA (i.e., matrix of the drift and fluctuation coefficients)
% Var (i.e., Kriging variances among the x, y and z axes in line)
%
% DESCRIPTION
% Inversion of the Kriging system and computation of the Kriging variance
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
% None
%
% MATLAB VERSION
% Matlab R2007b
%__________________________________________________________________________
%
% CHANGELOG
% Created by Raphaël Dumas
% May 2011
%__________________________________________________________________________

function [BA,Var] = Kriging(Xi,Xj,Model)

% Number of control points
n = size(Xi,1);

% Initialization
d = []; % 3D distance between control points
K = []; % Function of d

% Control point to control point 3D Euclidean distance
for p = 1:n % Index of first control point
    for q = 1:n % Index of second control point
        % 3D norm
        d(p,q) = norm(Xi(p,:) - Xi(q,:));
    end
end

% Generalized covariance
switch Model
    case 'Linear'
        K = d;
    case 'Cubic'
        K = d.^3;
    case 'Gaussian'
        K = exp(-(d.^2));
    case 'Multiquadratic'
        K = (d.^2 + ones(n,n)).^0.5;
    case 'Inverse multiquadratic'
        K = (d.^2 + ones(n,n)).^-0.5;
    case 'Logarithmic'
        % Avoid log(0) by replacing by 1
        K = (d.^2).*log(d + (d == 0)); 
end

% Kriging
% [K  Xi  [B    [Xj
%  Xit 0]  A] =  0]
KXiXit0 = zeros(n+4,n+4); % Initialization
KXiXit0(1:n,1:n) = K;
KXiXit0(1:n,n+1:end) = [ones(n,1),Xi];
KXiXit0(n+1:end,1:n) = [ones(1,n);Xi'];
Xj0 = [Xj;zeros(4,3)];

% System inversion
BA = inv(KXiXit0)*Xj0;

% Coefficients a
A = BA(n+1:end,:);

% Kriging variance
sigma2 = (1/n) * ...
    (Xj - [ones(n,1),Xi] * A)' * ...
    (inv(KXiXit0(1:n,1:n))) * ...
    (Xj - [ones(n,1),Xi] * A);

% Diagonal terms of Kriging variance in line
Var = diag(abs(sigma2))';
