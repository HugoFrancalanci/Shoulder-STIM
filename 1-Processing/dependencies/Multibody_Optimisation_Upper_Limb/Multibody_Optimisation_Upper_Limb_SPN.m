% FUNCTION
% Multibody_Optimisation_Upper_Limb_SPN.m
%__________________________________________________________________________
%
% PURPOSE
% Multibody kinematics optimisation : minimisation of the sum of the square distances 
% between measured and model-determined marker positions subject to 
% kinematic and rigid body constraints (Gauss-Newton algorithm)
%
% SYNOPSIS
% Segment = Multibody_Optimisation_Upper_Limb_PPN(Segment,Joint)
%
% INPUT
% Segment (cf. data structure in user guide)
% Joint (model parameters)
%
% OUTPUT
% Segment (cf. data structure in user guide)
%
% DESCRIPTION
% Computation of Q by minimisation under constraints (open loop)
% 'S': spherical (3 degrees of freedom) at glenohumeral
% 'P': constant clavicle
% 'N': no constraint (6 degrees of freedom) at scapulothoracic
%__________________________________________________________________________
%
% CALLED FUNCTIONS
% (from 3D kinematics and inverse dynamics toolbox) 
% Vnop_array3.m
% Mprod_array3.m
% Minv_array3.m
%
% MATLAB VERSION
% Matlab R2016b
%__________________________________________________________________________
%
% CHANGELOG
% Created by Raphaël Dumas
% April 2017
%
%__________________________________________________________________________

function [Segment] = Multibody_Optimisation_Upper_Limb_PPN(Segment,Joint)

% Segment
% i = 1: humerus
% i = 2: scapula
% i = 3: thorax
% Joint
% i = 1: glenohumeral
% i = 2: scapulothoracic including clavicle

% Number of frames
n = size(Segment(1).rM,3);


%% ------------------------------------------------------------------------
% Segment parameters
% -------------------------------------------------------------------------

% % Mean segment geometry and markers coordinates
% for i = 1:3 % From i = 1 (humerus) to i = 3 (thorax)
%     
%     % Segment length
%     Segment(i).L = mean(sqrt(sum((Segment(i).Q(4:6,1,:) - ...
%         Segment(i).Q(7:9,1,:)).^2)),3);
%     
%     % Alpha angle between (rP - rD) and w
%     Segment(i).alpha = mean(acosd(dot(Segment(i).Q(4:6,1,:) - ...
%         Segment(i).Q(7:9,1,:), Segment(i).Q(10:12,1,:))./...
%         sqrt(sum((Segment(i).Q(4:6,1,:) - ...
%         Segment(i).Q(7:9,1,:)).^2))),3);
%     
%     % Beta angle between u and w
%     Segment(i).beta = mean(acosd(dot(Segment(i).Q(10:12,1,:), ...
%         Segment(i).Q(1:3,1,:))),3);
%     
%     % Gamma angle between u and (rP - rD)
%     Segment(i).gamma = mean(acosd(dot(Segment(i).Q(1:3,1,:), ...
%         Segment(i).Q(4:6,1,:) - Segment(i).Q(7:9,1,:))./...
%         sqrt(sum((Segment(i).Q(4:6,1,:) - ...
%         Segment(i).Q(7:9,1,:)).^2))),3);
%     
%     % Matrix B from SCS to NSCS (matrix Buv)
%     Segment(i).B = [1, ...
%         Segment(i).L*cosd(Segment(i).gamma), ...
%         cosd(Segment(i).beta); ...
%         0, ...
%         Segment(i).L*sind(Segment(i).gamma), ...
%         (cosd(Segment(i).alpha) - cosd(Segment(i).beta)*cosd(Segment(i).gamma))/sind(Segment(i).gamma); ...
%         0, ...
%         0, ...
%         sqrt(1 - cosd(Segment(i).beta)^2 - ((cosd(Segment(i).alpha) - cosd(Segment(i).beta)*cosd(Segment(i).gamma))/sind(Segment(i).gamma))^2)];
%     
%     % Mean coordinates of markers in (u, rP-rD, w)
%     for j = 1:size(Segment(i).rM,2)
%         % Projection in a non orthonormal coordinate system
%         Segment(i).nM(:,j) = mean(Vnop_array3(...
%             Segment(i).rM(:,j,:) - Segment(i).Q(4:6,1,:),...
%             Segment(i).Q(1:3,1,:),...
%             Segment(i).Q(4:6,1,:) - Segment(i).Q(7:9,1,:),...
%             Segment(i).Q(10:12,1,:)),3);
%     end
% 
% 
% end


%% ------------------------------------------------------------------------
% Run optimisation
% -------------------------------------------------------------------------

% Initial guess for Lagrange multipliers
lambdakG = zeros(3,1,n); % Parallel constraint
lambdakC = zeros(1,1,n); % Parallel constraint
lambdakT = []; % No constraint (to be concatenate)
lambdar = zeros(18,1,n); % 3 segments x 6 constraints per segment

% Interpolation matrices
NV13 = [Segment(3).nV(1,1)*eye(3),...
    (1 + Segment(3).nV(2,1))*eye(3), ...
    - Segment(3).nV(2,1)*eye(3), ...
    Segment(3).nV(3,1)*eye(3)]; % Sternocalvicular joint
% Position of virtual markers
rV13 = Mprod_array3(repmat(NV13,[1,1,n]),Segment(3).Q); % Sternocalvicular joint

% Initial value of the objective function
F = 1;
% Iteration number
step = 0;

% -------------------------------------------------------------------------
% Newton-Raphson
while max(permute(sqrt(sum(F.^2)),[3,2,1])) > 10e-12 && step < 20
    
    % Iteration number
    step = step + 1   % Display
    
    % Initialisation
    phik = []; % Vector of kinematic constraints
    Kk = [];  % Jacobian of kinematic constraints
    phir = []; % Vector of rigid body constraints
    Kr = []; % Jacobian of rigid body constraints
    dKlambdardQ = []; % Partial derivative of Jacobian * Lagrange multipliers
    phim = []; % Vector of driving constraints
    Km = []; % Jacobian of driving constraints
    
    % Glenohumeral
    % Vector of kinematic constraints
    % rD2 - rP1 = 0
    phikG = Segment(2).Q(7:9,1,:) - Segment(1).Q(4:6,1,:);
    % Jacobian of kinematic constraints
    KkG = zeros(3,3*12,n); % Initialisation
    KkG(1:3,4:6,:) = -repmat(eye(3),[1,1,n]);
    KkG(1:3,19:21,:) = repmat(eye(3),[1,1,n]);
    % Partial derivative of Jacobian * Lagrange multipliers
    dKlambdakGdQ = zeros(3*12,3*12,n); % Initialisation

    % Clavicle
    % Vector of kinematic constraints
    % (rP2 - rV13)^2 - (d2)^2 = 0
    phikC = dot(Segment(2).Q(4:6,1,:) - rV13,Segment(2).Q(4:6,1,:) - rV13) - repmat((Joint(2).d(1,1))^2,[1,1,n]);
    % Jacobian of kinematic constraints
    KkC = zeros(1,3*12,n); % Initialisation
    KkC(1,16:18,:) = Mprod_array3(permute(Segment(2).Q(4:6,1,:) - rV13,[2,1,3]), repmat(2*eye(3),[1,1,n]));
    KkC(1,25:36,:) = Mprod_array3(permute((Segment(2).Q(4:6,1,:) - rV13),[2,1,3]), repmat(-2*NV13,[1,1,n]));
    % with transpose = permute( ,[2,1,3])
    % Partial derivative of Jacobian * Lagrange multipliers
    dKlambdakCdQ = zeros(3*12,3*12,n); % Initialisation
    dKlambdakCdQ(16:18,25:36,:) = Mprod_array3(lambdakC,repmat(-2*NV13,[1,1,n]));
    dKlambdakCdQ(25:36,16:18,:) = Mprod_array3(lambdakC,repmat(-2*NV13',[1,1,n]));
    dKlambdakCdQ(16:18,16:18,:) = Mprod_array3(lambdakC,repmat(2*eye(3),[1,1,n]));
    dKlambdakCdQ(25:36,25:36,:) = Mprod_array3(lambdakC,repmat(2*NV13'*NV13,[1,1,n]));
    
    % Scapulothoracic
    phikT = []; % To be concatenated
    % Jacobian of kinematic constraints
    KkT = [];  % To be concatenated
    % Partial derivative of Jacobian * Lagrange multipliers
    dKlambdakTdQ = zeros(3*12,3*12,n);  % To be summed up
    
   % Assembly
    phik = [phikG;phikC;phikT];
    Kk = [KkG;KkC;KkT];
    lambdak = [lambdakG;lambdakC;lambdakT];
    dKlambdakdQ = dKlambdakGdQ + dKlambdakCdQ + dKlambdakTdQ;
    
    
    % ---------------------------------------------------------------------
    % Rigid body constraints and driving constraints
    for i = 1:3 % From i = 1 (humerus) to i = 3 (thorax)
        
        % Vector of rigid body constraints
        ui = Segment(i).Q(1:3,1,:);
        vi = Segment(i).Q(4:6,1,:) - Segment(i).Q(7:9,1,:);
        wi = Segment(i).Q(10:12,1,:);
        phiri = [dot(ui,ui) - ones(1,1,n);...
            dot(ui,vi) - repmat(Segment(i).L*cosd(Segment(i).gamma),[1,1,n]); ...
            dot(ui,wi) - repmat(cosd(Segment(i).beta),[1,1,n]); ...
            dot(vi,vi) - repmat(Segment(i).L^2,[1,1,n]);
            dot(vi,wi) - repmat(Segment(i).L*cosd(Segment(i).alpha),[1,1,n]);
            dot(wi,wi) - ones(1,1,n)];
        
        % Jacobian of rigid body constraints
        Kri = zeros(6,3*12,n); % Initialisation
        Kri(1:6,(i-1)*12+1:(i-1)*12+12,:) = permute(...
            [    2*ui,       vi,           wi,     zeros(3,1,n),zeros(3,1,n),zeros(3,1,n); ...
            zeros(3,1,n),    ui,      zeros(3,1,n),    2*vi,         wi,     zeros(3,1,n); ...
            zeros(3,1,n),   -ui,      zeros(3,1,n),   -2*vi,        -wi,     zeros(3,1,n); ...
            zeros(3,1,n),zeros(3,1,n),     ui,     zeros(3,1,n),     vi,         2*wi],[2,1,3]);
        % with transpose = permute( ,[2,1,3])
        % Segment structure
        Segment(i).Kr = Kri;
        
        % Partial derivative of Jacobian * Lagrange multipliers
        dKlambdaridQ = zeros(12,3*12,n); % Initialisation
        lambdari = lambdar((i-1)*6+1:(i-1)*6+6,1,:); % Extraction
        dKlambdaridQ(1:12,(i-1)*12+1:(i-1)*12+12,:) = ...
            [Mprod_array3(lambdari(1,1,:),repmat(2*eye(3),[1,1,n])), ...
            Mprod_array3(lambdari(2,1,:),repmat(eye(3),[1,1,n])), ...
            Mprod_array3(lambdari(2,1,:),repmat(-1*eye(3),[1,1,n])), ...
            Mprod_array3(lambdari(3,1,:),repmat(eye(3),[1,1,n])); ...
            Mprod_array3(lambdari(2,1,:),repmat(eye(3),[1,1,n])), ...
            Mprod_array3(lambdari(4,1,:),repmat(2*eye(3),[1,1,n])), ...
            Mprod_array3(lambdari(4,1,:),repmat(-2*eye(3),[1,1,n])), ...
            Mprod_array3(lambdari(5,1,:),repmat(eye(3),[1,1,n])); ...
            Mprod_array3(lambdari(2,1,:),repmat(-1*eye(3),[1,1,n])), ...
            Mprod_array3(lambdari(4,1,:),repmat(-2*eye(3),[1,1,n])), ...
            Mprod_array3(lambdari(4,1,:),repmat(2*eye(3),[1,1,n])), ...
            Mprod_array3(lambdari(5,1,:),repmat(-1*eye(3),[1,1,n])); ...
            Mprod_array3(lambdari(3,1,:),repmat(eye(3),[1,1,n])), ...
            Mprod_array3(lambdari(5,1,:),repmat(eye(3),[1,1,n])), ...
            Mprod_array3(lambdari(5,1,:),repmat(-1*eye(3),[1,1,n])), ...
            Mprod_array3(lambdari(6,1,:),repmat(2*eye(3),[1,1,n]))];
        
        % Vector and Jacobian of driving constraints
        Kmi = zeros(size(Segment(i).rM,2)*3,3*12,n); % Initialisation
        phimi = []; % Initialisation
        for j = 1:size(Segment(i).rM,2)
            % Interpolation matrix
            NMij = [Segment(i).nM(1,j)*eye(3),...
                (1 + Segment(i).nM(2,j))*eye(3), ...
                - Segment(i).nM(2,j)*eye(3), ...
                Segment(i).nM(3,j)*eye(3)];
            % Vector of driving constraints
            phimi((j-1)*3+1:(j-1)*3+3,1,:) = Segment(i).rM(:,j,:) ...
                - Mprod_array3(repmat(NMij,[1,1,n]),Segment(i).Q);
            % Jacobian of driving contraints
            Kmi((j-1)*3+1:(j-1)*3+3,(i-1)*12+1:(i-1)*12+12,:) = ...
                repmat(-NMij,[1,1,n]);
        end
        
        % Assembly
        phir = [phir;phiri];
        Kr = [Kr;Kri];
        dKlambdardQ = [dKlambdardQ;dKlambdaridQ];
        phim = [phim;phimi];
        Km = [Km;Kmi];
        
    end
    
    % Display errors
    Mean_phik = mean(Mprod_array3(permute(phik,[2,1,3]),phik),3)
    Mean_phir = mean(Mprod_array3(permute(phir,[2,1,3]),phir),3)
    Mean_phim = mean(Mprod_array3(permute(phim,[2,1,3]),phim),3)
    
    
    % ---------------------------------------------------------------------
    % Solution
    
    % Compute dX
    % dX = inv(-dF/dx)*F(X)
    % F(X) = [Km'*phim + [Kk;Kr]'*[lambdak;lambdar];[phik;phir]]
    % X = [Q;[lambdak;lambdar]]
    F = [Mprod_array3(permute(Km,[2,1,3]),phim) + ...
        Mprod_array3(permute([Kk;Kr],[2,1,3]), [lambdak;lambdar]); ...
        [phik;phir]]; % with transpose = permute( ,[2,1,3])
    dKlambdadQ = dKlambdakdQ + dKlambdardQ;
    dFdX = [Mprod_array3(permute(Km,[2,1,3]),Km) + ...
        dKlambdadQ, permute([Kk;Kr],[2,1,3]); ...
        [Kk;Kr],zeros(size([Kk;Kr],1),size([Kk;Kr],1),n)];
    dX = Mprod_array3(Minv_array3(-dFdX),F);
    
    
    % ---------------------------------------------------------------------
    % Extraction from X
    Segment(1).Q = Segment(1).Q + dX(1:12,1,:);
    Segment(2).Q = Segment(2).Q + dX(13:24,1,:);
    Segment(3).Q = Segment(3).Q + dX(25:36,1,:);
    
    lambdakG = lambdakG + dX(37:39,1,:);
    lambdakC = lambdakC + dX(40,1,:);
    % lambdakT: no constraint
    lambdar = lambdar + dX(41:end,1,:);
    
end
