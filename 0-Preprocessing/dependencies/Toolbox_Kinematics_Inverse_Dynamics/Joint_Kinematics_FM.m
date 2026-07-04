% Author       : F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License      : Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code  : https://github.com/fmoissenet/NSLBP-BIOToolbox
% Reference    : To be defined
% Date         : June 2020
% -------------------------------------------------------------------------
% Description  : To be defined
% Inputs       : To be defined
% Outputs      : To be defined
% -------------------------------------------------------------------------
% Dependencies : None
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function Trial = Joint_Kinematics_FM(Trial,segment1,segment2)

% Number of frames
n = size(Trial.Segment(segment1).Q.smooth,3);

% Segment and joint kinematics
for i = segment1:segment2-1
    
    % Segment kinematics
    Trial.Segment(i).T.smooth     = Q2Tuv_array3(Trial.Segment(i).Q.smooth);
    if i == 5 || i == 10 || i == 11 || i == 12 || i == 13 || i == 14 || ...
       i == 15 || i == 16 || i == 17 || i == 18 || i == 19
        Trial.Segment(i).Euler.smooth = R2fixedYXZ_array3(Trial.Segment(i).T.smooth(1:3,1:3,:)); % (Wren and Mitiguy 2007)
        Trial.Segment(i).sequence     = 'YXZ';
    else
        Trial.Segment(i).Euler.smooth = R2fixedZYX_array3(Trial.Segment(i).T.smooth(1:3,1:3,:));
        Trial.Segment(i).sequence     = 'ZYX';
    end
    
    % Joint kinematics
    
    if contains(Trial.Segment(i).label,'foot')
        % ZYX sequence of mobile axis (JCS system for ankle and wrist)
        % Ankle adduction-abduction (or wrist interal-external rotation) on floating axis
        % Transformation from the proximal to the distal SCS
        % Proximal SCS: origin at endpoint D and Z=w and  Y=(w×u)/||w×u||
        % Distal SCS: origin at endpoint P and X=u and Y =(w×u)/||w×u||  
        Trial.Joint(i).T.smooth = Mprod_array3(Tinv_array3(Q2Twu_array3(Trial.Segment(i+1).Q.smooth)),...
            Q2Tuw_array3(Trial.Segment(i).Q.smooth));
        
        % Euler angles
        Trial.Joint(i).Euler.smooth = R2mobileZYX_array3(Trial.Joint(i).T.smooth(1:3,1:3,:));
        % Joint displacement about the Euler angle axes
        Trial.Joint(i).dj.smooth = Vnop_array3(...
            Trial.Joint(i).T.smooth(1:3,4,:),... Di+1 to Pi in SCS of Segment i+1
            repmat([0;0;1],[1 1 n]),... % Zi+1 in SCS of Segment i+1
            Vnorm_array3(cross(repmat([0;0;1],[1 1 n]),Trial.Joint(i).T.smooth(1:3,1,:))),... Y = ZxX
            Trial.Joint(i).T.smooth(1:3,1,:)); % Xi in SCS of Segment i
        Trial.Joint(i).sequence = 'ZYX';
        
    else
        % ZXY sequence of mobile axis
        % Transformation from the proximal to the distal SCS
        % Proximal SCS: origin at endpoint D and Z=w and  Y=(w×u)/||w×u||
        % Distal SCS: origin at endpoint P and X=u and Z=(u×v)/||u×v||  
        Trial.Joint(i).T.smooth = Mprod_array3(Tinv_array3(Q2Twu_array3(Trial.Segment(i+1).Q.smooth)),...
            Q2Tuv_array3(Trial.Segment(i).Q.smooth));
        if contains(Trial.Segment(i).label,'femur')
            % Special case for i = 4 thigh (or arm)
            % Origin of proximal Segment at mean position of Pi
            % in proximal SCS (rather than endpoint Di+1)
            Trial.Joint(4).T.smooth(1:3,4,:) = Trial.Joint(4).T.smooth(1:3,4,:) - ...
                repmat(mean(Trial.Joint(4).T.smooth(1:3,4,:),3),[1 1 n]);
        end
        
        % Euler angles
        Trial.Joint(i).Euler.smooth = R2mobileZXY_array3(Trial.Joint(i).T.smooth(1:3,1:3,:));
        % Joint displacement about the Euler angle axes
        Trial.Joint(i).dj.smooth = Vnop_array3(...
            Trial.Joint(i).T.smooth(1:3,4,:),... Di+1 to Pi in SCS of Segment i+1
            repmat([0;0;1],[1 1 n]),... % Zi+1 in SCS of Segment i+1
            Vnorm_array3(cross(Trial.Joint(i).T.smooth(1:3,2,:),repmat([0;0;1],[1 1 n]))),... X = YxZ
            Trial.Joint(i).T.smooth(1:3,2,:)); % Yi in SCS of Segment i
        Trial.Joint(i).sequence = 'ZXY';
        
    end
    
end