% FUNCTION
% RBF_3D_Approximation
%__________________________________________________________________________
%
% PURPOSE
% Non-rigid registration and scaling of an initial mesh based on a set of
% control points
%
% SYNOPSIS
% [Meshj,Rotation,Translation,Homothety,Stretch,Model,Centers,SSE] = ...
%    RBF_3D_Approximation(Meshi,Xi,Xj,Lambda_reference,Percentage)
%
% INPUT
% Meshi (i.e., matrix l*3 of the l initial 3D mesh nodes)
% Xi (i.e., matrix n*3 of the n initial 3D control points)
% Xj (i.e., matrix n*3 of the n final 3D control points)
% Lambda_reference (i.e., initial regulalarization parameter)
% Percentage (i.e., minimal improvement of cost function)
%
% OUTPUT
% Meshj (i.e., matrix l*3 of the l final 3D mesh nodes)
% Rotation (i.e., matrix 3*3 of the rigid part of the linear polynomial)
% Translation (i.e., vector 3*1 of the rigid part of the linear polynomial)
% Homothety (i.e., matrix 3*3 of the deformative part of the linear polynomial)
% Stretch (i.e., matrix 3*3 of the deformative part of the linear polynomial)
% Model (i.e., m selected models)
% Centers (i.e., m selected centers)
% SSE (i.e., sum of squared errors)
%
% DESCRIPTION
% Determination of the RBF transformation (forward regularized selection 
% of models and centers) from an initial position i to a final position j,
% extraction of geometrical information and application to the initial mesh
% nodes
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
% RBF.m
% 
% MATLAB VERSION
% Matlab R2007b
%__________________________________________________________________________
%
% CHANGELOG
% Created by Raphaël Dumas
% May 2011
%__________________________________________________________________________

function [Meshj,Rotation,Translation,Homothety,Stretch,Model,Center,SSE] = ...
    RBF_3D_Approximation(Meshi,Xi,Xj,Lambda_reference,Percentage)

% Number of control points
n = size(Xi,1);

%__________________________________________________________________________
%
% Least square polynomials
%__________________________________________________________________________

% Xj = [1,Xi]*[A]
% Least square
A = inv([ones(n,1),Xi]' * [ones(n,1),Xi])*[ones(n,1),Xi]' * Xj;

% Final control points minus transformed initial control points
Xja =  Xj - [ones(n,1),Xi]*A;

% Sum of squared errors (residual)
SSEa = diag(Xja'*Xja)'; % 3 values on x,y,z

%__________________________________________________________________________
%
% Regularized forward selection
%__________________________________________________________________________

% Reference mean (among x,y,z) cost F
mean_F_reference = mean(SSEa); % Affine residual

% Reference regularization parameter
Lambda(1) = Lambda_reference;

% Trial models
M = {'Linear','Cubic','Gaussian','Multiquadratic', ...
    'Inverse multiquadratic','Thin plate spline'};

% Trial centers
C_trial = Xi;

% Initial values of trial
trial = 0; % Counter
Lambda_trial = [];
F_trial = []; % No cost (3 values on x,y,z)
mean_F_trial = []; % No mean (among x,y,z) cost
mean_F_trial_min = []; % No minimal mean cost

% Initial selection
Center = []; % No center
Model = {}; % No model


% Selection
while trial < n

    % New selection
    trial = trial + 1;

    for f = 1:size(C_trial,1)  % Index of current center
        for s = 1:length(M) % Index of current model

            % SEE, F and lambda
            [W,SSE_trial(f,:,s),F_trial(f,:,s),Lambda_trial(f,s)] = ...
                RBF(Xi,Xja,[Model,M(s)], ...
                [Center; C_trial(f,:)],Lambda(end));

            % Mean (along x,y,z) cost F
            mean_F_trial(f,s) = mean(F_trial(f,:,s),2);

        end
    end

    % Best Cost
    mean_F_trial_min(trial) = min(min(mean_F_trial));
    [Ind_C,Ind_M] = find(mean_F_trial == mean_F_trial_min(trial));

    % Cost improvement ?
    if (mean_F_reference - mean_F_trial_min(trial))/...
            mean_F_reference*100 > Percentage

        % Selected center lambda and model
        Center = [Center; C_trial(Ind_C,:)];
        Model = [Model, M(Ind_M)];

        % Preparing next lambda and cost F
        Lambda = [Lambda,Lambda_trial(Ind_C,Ind_M)];
        mean_F_reference = mean_F_trial_min(trial);

        % Removing selected center from trial centers
        not_Ind_C = find(C_trial(:,1) ~= C_trial(Ind_C,1));
        C_trial = C_trial(not_Ind_C,:);

    end

end

% Removing last lambda
Lambda = Lambda(1:end-1);


%__________________________________________________________________________
%
% Polynomials coefficients and weights re-estimation
%__________________________________________________________________________

% Dimension
m = size(Center,1);

% Initialization
d = [];
H = [];

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

% RBF
% [H  Xi  [W    [Xj
%  Ct  0]  A] =  0]
HXiCt0 = zeros(n+4,m+4); % Initialization
HXiCt0(1:n,1:m) = H;
HXiCt0(1:n,m+1:end) = [ones(n,1),Xi];
HXiCt0(n+1:end,1:m) = [ones(1,m);Center'];
Xj0 = [Xj;zeros(4,3)];

% System inversion
WA = pinv(HXiCt0)*Xj0;

% Coeffiencients a and w
W = WA(1:m,:);
A = WA(m+1:end,:);


%__________________________________________________________________________
%
% 3D approximation
%__________________________________________________________________________

% Mesh nodes control points and centers
% (may eventually consider control points three times if
% if control point are part of the mesh nodes and if
% centers have been selected out of control points)
Datai = [Center;Xi;Meshi];

% Number of data points
ln =  size(Datai,1);

% Initialization
d = []; % 3D distance between points
K = []; % Function of d

for r = 1:ln % Index of current data point
    for f = 1:m % Index of current center
        
        % Data point to center 3D Euclidean distance
        d(r,f) = norm(Datai(r,:) - Center(f,:));
        
        % RBF
        switch Model{f}
            case 'Linear'
                H(r,f) = d(r,f);
            case 'Cubic'
                H(r,f) = d(r,f).^3;
            case 'Gaussian'
                H(r,f) = exp(-(d(r,f).^2));
            case 'Multiquadratic'
                H(r,f) = (d(r,f).^2 + 1).^0.5;
            case 'Inverse multiquadratic'
                H(r,f) = (d(r,f).^2 + 1).^-0.5;
            case 'Thin plate spline'
                % Avoid log(0) by replacing 0 by 1
                H(r,f) = (d(r,f).^2).*log(d(r,f) + (d(r,f) == 0));
        end
    end

    % First coordinate of Dataf for data point r
    Dataj(r,1) = A(1,1) + A(2,1)*Datai(r,1) + ...
        A(3,1)*Datai(r,2) + A(4,1)*Datai(r,3) + ... % Polynomials
        sum(W(:,1).*H(r,:)'); % RBFs

    % Second coordinate of Dataf for data point r
    Dataj(r,2) = A(1,2) + A(2,2)*Datai(r,1) + ...
        A(3,2)*Datai(r,2) + A(4,2)*Datai(r,3) + ... % Polynomials
        sum(W(:,2).*H(r,:)'); % RBFs

    % Third function: Z_f(x,y,z)
    Dataj(r,3) = A(1,3) + A(2,3)*Datai(r,1) + ...
        A(3,3)*Datai(r,2) + A(4,3)*Datai(r,3) + ... % Polynomials
        sum(W(:,3).*H(r,:)'); % RBFs

end

% Extract final mesh nodes from data points
Meshj = Dataj(m+n+1:end,:);

%__________________________________________________________________________
%
% Sum of squared errors (on control points)
%__________________________________________________________________________

SSE = sum((Xj - Dataj(m+1:m+n,:)).^2,1);

%__________________________________________________________________________
%
% Interpetration of the polynomials
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

