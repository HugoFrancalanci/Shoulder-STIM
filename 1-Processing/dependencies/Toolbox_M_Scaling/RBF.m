% FUNCTION
% RBF
%__________________________________________________________________________
%
% PURPOSE
% Determination of the basis function coefficients, cost function and
% refined regularization parameter
%
% SYNOPSIS
% [W,SSE,F,Lambda] = RBF(Xi,Xja,Model,Center,Lambda)
%
% INPUT
% Xi (i.e., matrix n*3 of the n initial 3D control points)
% Xj (i.e., matrix n*3 of the n final 3D control points)
% Model (i.e., m basis functions)
% Center (i.e., m centers) 
% Lambda (i.e., regulalarization parameter)
%
% OUTPUT
% W (i.e., basis function coefficients)
% SSE (i.e., sum of squared errors)
% F (i.e., cost function among the x, y and z axes in column)
% Lambda (i.e., refined regularization parameter)
%
% DESCRIPTION
% Pseudo-inversion of the RBF system and computation of the cost function
% and of the refined regularization parameter
%
% REFERENCES
% R Dumas, L Cheze. Soft tissue artifact compensation by linear 3D 
% interpolation and approximation methods. Journal of Biomechanics
% 2009;42(13):2214–2217.
% MJL Orr. Introduction to Radial Basis Function Networks. 1996
% http://www.anc.ed.ac.uk/rbf/intro/intro.html
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

function [W,SSE,F,Lambda] = RBF(Xi,Xja,Model,Center,Lambda)

% Number of control points
n = size(Xi,1);

% Number of centers
m =  size(Center,1);

for p = 1:n % Index of current control point
    for f = 1:m % Index of current center
        
        % Control point to center 3D Euclidean distance
        d(p,f) = norm(Xi(p,:) - Center(f,:));
        
        % H matrix
        switch Model{f}
            case 'Linear'
                H(p,f) = d(p,f);
            case 'Cubic'
                H(p,f) = d(p,f)^3;
            case 'Gaussian'
                H(p,f) = exp(-d(p,f)^2);
            case 'Multiquadratic'
                H(p,f) = sqrt(d(p,f)^2+1);
            case 'Inverse multiquadratic'
                H(p,f) = 1/(sqrt(d(p,f)^2+1));
            case 'Thin plate spline'
                % Avoid log(0) by replacing 0 by 1
                H(p,f) = (d(p,f)^2)*log(d(p,f) + (d(p,f) == 0));
        end
        
    end
end

% Variance matrix
V = inv(H'*H + eye(m)*Lambda);

% Projection matrix
P = eye(n) - H*V*H';

% Weigth
W = V*H'*Xja;

% SSE
SSE = diag(Xja'*(P*P)*Xja)';

% Diagonal terms of cost F in column
F = diag(Xja'*P*Xja)';

% Refined lambda (with generalized cross validation)
Lambda = mean(diag(Xja'*(P*P)*Xja*trace(V - Lambda*(V*V)))'./ ...
    diag(W'*V*W*trace(P))');

