% Author     :   F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   https://github.com/fmoissenet/Roboshoulder_Toolbox
% Reference  :   To be defined
% Date       :   March 2020
% -------------------------------------------------------------------------
% Description:   Compute kinematics
%                It is part of the toolkit grouping several methods used in 
%                the RoboShoulder project, a joined project with the HEPIA 
%                school at Geneva.
% -------------------------------------------------------------------------
% Dependencies : - 3D Kinematics and Inverse Dynamics toolbox by Raphaël Dumas: https://fr.mathworks.com/matlabcentral/fileexchange/58021-3d-kinematics-and-inverse-dynamics?s_tid=prof_contriblnk
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function Trial = ComputeKinematics(c3dFiles,Trial)

disp('  - Calcul de la cinématique articulaire');
n = fix(Trial.n1);

% -------------------------------------------------------------------------
% RIGHT HUMEROTHORACIC JOINT
% -------------------------------------------------------------------------
% Homogenous matrix of the rigid transformation between segments
Trial.Joint(1).T.full = Mprod_array3(Tinv_array3(Trial.Segment(4).T.full),...
                                     Trial.Segment(1).T.full);
% JCS and motion for the humerus relative to the thorax (XZY order)     
% (Wu et al. 2005)
% (Senk and Chèze 2006, Creveaux et al. 2018, Phadke et al. 2011)
if contains(c3dFiles.name,'ANALYTIC1') || contains(c3dFiles.name,'FUNCTIONAL1') || contains(c3dFiles.name,'FUNCTIONAL2') || contains(c3dFiles.name,'FUNCTIONAL4') % Sagittal elevation
    Trial.Joint(1).sequence            = 'ZXY';
    Euler                              = R2mobileZXY_array3(Trial.Joint(1).T.full(1:3,1:3,:));
    Trial.Joint(1).Euler.full(1,1,:)   = rad2deg(Euler(:,2,:)); % X
    Trial.Joint(1).Euler.full(1,2,:)   = rad2deg(Euler(:,3,:)); % Y
    Trial.Joint(1).Euler.full(1,3,:)   = rad2deg(Euler(:,1,:)); % Z             
    Trial.Joint(1).dj.full             = [];          
    Euler2                             = R2mobileYXY_array3(Trial.Joint(1).T.full(1:3,1:3,:));
    Trial.Joint(1).ElevationPlane.full = 180+rad2deg(unwrap(atan2(Trial.Joint(1).T.full(1,2,:),Trial.Joint(1).T.full(3,2,:))));
    clear Euler dj x y p x1 y1; 
elseif contains(c3dFiles.name,'ANALYTIC2') || contains(c3dFiles.name,'ANALYTIC5') || contains(c3dFiles.name,'FUNCTIONAL3') || contains(c3dFiles.name,'STATIC') || contains(c3dFiles.name,'ISOMETRIC') % Coronal elevation
    Trial.Joint(1).sequence            = 'XZY';
    Euler                              = R2mobileXZY_array3(Trial.Joint(1).T.full(1:3,1:3,:));
    Trial.Joint(1).Euler.full(1,1,:)   = rad2deg(Euler(:,1,:)); % X
    Trial.Joint(1).Euler.full(1,2,:)   = rad2deg(Euler(:,3,:)); % Y
    Trial.Joint(1).Euler.full(1,3,:)   = rad2deg(Euler(:,2,:)); % Z              
    Trial.Joint(1).dj.full             = [];        
    Trial.Joint(1).ElevationPlane.full = 180+rad2deg(unwrap(atan2(Trial.Joint(1).T.full(1,2,:),Trial.Joint(1).T.full(3,2,:))));
    clear Euler dj x y p x1 y1; 
elseif contains(c3dFiles.name,'ANALYTIC3') % External rotation
    Trial.Joint(1).sequence            = 'YXZ';
    Euler                              = R2mobileYXZ_array3(Trial.Joint(1).T.full(1:3,1:3,:));
    Trial.Joint(1).Euler.full(1,1,:)   = rad2deg(Euler(:,2,:)); % X
%     Trial.Joint(1).Euler.full(1,2,:)   = rad2deg(Euler(:,1,:)); % Y
    if mean(unwrap(abs(rad2deg(Euler(:,1,:))))) > 120
        Trial.Joint(1).Euler.full(1,2,:) = unwrap(squeeze(-180+rad2deg(Euler(:,1,:)))); % Y  
    else
        Trial.Joint(1).Euler.full(1,2,:) = rad2deg(Euler(:,1,:)); % Y
    end
    Trial.Joint(1).Euler.full(1,3,:)   = rad2deg(Euler(:,3,:)); % Z 
    Trial.Joint(1).dj.full             = [];   
    Trial.Joint(1).ElevationPlane.full = [];     
    clear Euler dj x y p x1 y1; 
%     figure; plot(squeeze(Trial.Joint(1).Euler.full(1,2,:))');
elseif contains(c3dFiles.name,'ANALYTIC4') % Internal rotation
    Trial.Joint(1).sequence            = 'YXZ';
    Euler                              = R2mobileYXZ_array3(Trial.Joint(1).T.full(1:3,1:3,:));
    Trial.Joint(1).Euler.full(1,1,:)   = rad2deg(Euler(:,2,:)); % X
%     Trial.Joint(1).Euler.full(1,2,:)   = rad2deg(Euler(:,1,:)); % Y
    if mean(unwrap((rad2deg(Euler(:,1,:))))) > 120
        Trial.Joint(1).Euler.full(1,2,:) = unwrap(squeeze(-180+rad2deg(Euler(:,1,:)))); % Y  
    elseif mean(unwrap((rad2deg(Euler(:,1,:))))) > 160
        Trial.Joint(1).Euler.full(1,2,:) = unwrap(squeeze(-180+rad2deg(Euler(:,1,:))))-180; % Y 
    elseif mean(unwrap((rad2deg(Euler(:,1,:))))) < -120
        Trial.Joint(1).Euler.full(1,2,:) = unwrap(squeeze(180+rad2deg(Euler(:,1,:)))); % Y 
    elseif mean(unwrap((rad2deg(Euler(:,1,:))))) < -160
        Trial.Joint(1).Euler.full(1,2,:) = unwrap(squeeze(180+rad2deg(Euler(:,1,:))))+180; % Y 
    else
        Trial.Joint(1).Euler.full(1,2,:) = rad2deg(Euler(:,1,:)); % Y
    end
    Trial.Joint(1).Euler.full(1,3,:)   = rad2deg(Euler(:,3,:)); % Z              
    Trial.Joint(1).dj.full             = [];        
    Trial.Joint(1).ElevationPlane.full = [];
    clear Euler dj x y p x1 y1; 
    figure; plot(squeeze(Trial.Joint(1).Euler.full(1,2,:))');
end

% -------------------------------------------------------------------------
% RIGHT GLENOHUMERAL JOINT
% -------------------------------------------------------------------------
% Homogenous matrix of the rigid transformation between segments
Trial.Joint(2).T.full = Mprod_array3(Tinv_array3(Trial.Segment(2).T.full),...
                                     Trial.Segment(1).T.full);
% JCS and motion for the humerus relative to the scapula (XZY order)     
% (Senk and Chèze 2006, Creveaux et al. 2018, Phadke et al. 2011)
if contains(c3dFiles.name,'ANALYTIC1') || contains(c3dFiles.name,'FUNCTIONAL1') || contains(c3dFiles.name,'FUNCTIONAL2') || contains(c3dFiles.name,'FUNCTIONAL4') % Sagittal elevation
    Trial.Joint(2).sequence          = 'ZXY';
    Euler                            = R2mobileZXY_array3(Trial.Joint(2).T.full(1:3,1:3,:));
    Trial.Joint(2).Euler.full(1,1,:) = rad2deg(Euler(:,2,:)); % X
    Trial.Joint(2).Euler.full(1,2,:) = rad2deg(Euler(:,3,:)); % Y
    Trial.Joint(2).Euler.full(1,3,:) = rad2deg(Euler(:,1,:)); % Z             
    Trial.Joint(2).dj.full           = [];        
    clear Euler dj x y p x1 y1; 
elseif contains(c3dFiles.name,'ANALYTIC2') || contains(c3dFiles.name,'ANALYTIC5') || contains(c3dFiles.name,'FUNCTIONAL3') || contains(c3dFiles.name,'STATIC') || contains(c3dFiles.name,'ISOMETRIC') % Coronal elevation
    Trial.Joint(2).sequence          = 'XZY';
    Euler                            = R2mobileXZY_array3(Trial.Joint(2).T.full(1:3,1:3,:));
    Trial.Joint(2).Euler.full(1,1,:) = rad2deg(Euler(:,1,:)); % X
    Trial.Joint(2).Euler.full(1,2,:) = rad2deg(Euler(:,3,:)); % Y
    Trial.Joint(2).Euler.full(1,3,:) = rad2deg(Euler(:,2,:)); % Z              
    Trial.Joint(2).dj.full           = [];        
    clear Euler dj x y p x1 y1; 
elseif contains(c3dFiles.name,'ANALYTIC3') % External rotation
    Trial.Joint(2).sequence          = 'YXZ';
    Euler                            = R2mobileYXZ_array3(Trial.Joint(2).T.full(1:3,1:3,:));
    Trial.Joint(2).Euler.full(1,1,:) = rad2deg(Euler(:,2,:)); % X
%     Trial.Joint(2).Euler.full(1,2,:)   = rad2deg(Euler(:,1,:)); % Y
    if mean(unwrap(abs(rad2deg(Euler(:,1,:))))) > 100
        Trial.Joint(2).Euler.full(1,2,:) = unwrap(squeeze(-180+rad2deg(Euler(:,1,:)))); % Y  
    else
        Trial.Joint(2).Euler.full(1,2,:) = rad2deg(Euler(:,1,:)); % Y
    end
    Trial.Joint(2).Euler.full(1,3,:) = rad2deg(Euler(:,3,:)); % Z     
    Trial.Joint(2).dj.full           = [];        
    clear Euler dj x y p x1 y1; 
%     figure; plot(squeeze(Trial.Joint(2).Euler.full(1,2,:))');
elseif contains(c3dFiles.name,'ANALYTIC4') % Internal rotation
    Trial.Joint(2).sequence          = 'YXZ';
    Euler                            = R2mobileYXZ_array3(Trial.Joint(2).T.full(1:3,1:3,:));    
    Trial.Joint(2).Euler.full(1,1,:) = rad2deg(Euler(:,2,:)); % X
%     Trial.Joint(2).Euler.full(1,2,:) = rad2deg(Euler(:,1,:)); % Y
    if mean(unwrap(abs(rad2deg(Euler(:,1,:))))) > 100
        Trial.Joint(2).Euler.full(1,2,:) = unwrap(squeeze(-180+rad2deg(Euler(:,1,:)))); % Y  
    else
        Trial.Joint(2).Euler.full(1,2,:) = rad2deg(Euler(:,1,:)); % Y
    end
    Trial.Joint(2).Euler.full(1,3,:) = rad2deg(Euler(:,3,:)); % Z  
    Trial.Joint(2).dj.full           = [];        
    clear Euler dj x y p x1 y1; 
%     figure; plot(squeeze(Trial.Joint(2).Euler.full(1,2,:))');
end

% -------------------------------------------------------------------------
% RIGHT SCAPULOTHORACIC JOINT
% -------------------------------------------------------------------------
% Homogenous matrix of the rigid transformation between segments
Trial.Joint(3).T.full = Mprod_array3(Tinv_array3(Trial.Segment(4).T.full),...
                                     Trial.Segment(2).T.full);
% JCS and motion for the scapula relative to the thorax (YXZ order) 
% (Wu et al. 2005)
if contains(c3dFiles.name,'ANALYTIC') || contains(c3dFiles.name,'FUNCTIONAL')
    Trial.Joint(3).sequence          = 'YXZ';
    Euler                            = R2mobileYXZ_array3(Trial.Joint(3).T.full(1:3,1:3,:));
    Trial.Joint(3).Euler.full(1,1,:) = rad2deg(Euler(:,2,:)); % X
    Trial.Joint(3).Euler.full(1,2,:) = rad2deg(Euler(:,1,:)); % Y
    Trial.Joint(3).Euler.full(1,3,:) = rad2deg(Euler(:,3,:)); % Z           
    Trial.Joint(3).dj.full           = [];        
    clear Euler dj x y p x1 y1; 
end

% -------------------------------------------------------------------------
% LEFT HUMEROTHORACIC JOINT
% -------------------------------------------------------------------------
% Homogenous matrix of the rigid transformation between segments
Trial.Joint(6).T.full = Mprod_array3(Tinv_array3(Trial.Segment(4).T.full),...
                                     Trial.Segment(5).T.full);
% JCS and motion for the humerus relative to the thorax (XZY order)     
% (Wu et al. 2005)
% (Senk and Chèze 2006, Creveaux et al. 2018, Phadke et al. 2011)
if contains(c3dFiles.name,'ANALYTIC1') || contains(c3dFiles.name,'FUNCTIONAL1') || contains(c3dFiles.name,'FUNCTIONAL2') || contains(c3dFiles.name,'FUNCTIONAL4') % Sagittal elevation
    Trial.Joint(6).sequence            = 'ZXY';
    Euler                              = R2mobileZXY_array3(Trial.Joint(6).T.full(1:3,1:3,:));
    Trial.Joint(6).Euler.full(1,1,:)   = rad2deg(Euler(:,2,:)); % X
    Trial.Joint(6).Euler.full(1,2,:)   = -rad2deg(Euler(:,3,:)); % Y
    Trial.Joint(6).Euler.full(1,3,:)   = -rad2deg(Euler(:,1,:)); % Z             
    Trial.Joint(6).dj.full             = [];                           
    Trial.Joint(6).ElevationPlane.full = -rad2deg(unwrap(atan2(Trial.Joint(6).T.full(1,2,:),Trial.Joint(6).T.full(3,2,:))));
    clear Euler dj x y p x1 y1; 
elseif contains(c3dFiles.name,'ANALYTIC2') || contains(c3dFiles.name,'ANALYTIC5') || contains(c3dFiles.name,'FUNCTIONAL3') || contains(c3dFiles.name,'STATIC') || contains(c3dFiles.name,'ISOMETRIC') % Coronal elevation
    Trial.Joint(6).sequence            = 'XZY';
    Euler                              = R2mobileXZY_array3(Trial.Joint(6).T.full(1:3,1:3,:));
    Trial.Joint(6).Euler.full(1,1,:)   = -rad2deg(Euler(:,1,:)); % X % Sign adaptation to fullfill ISB convention  
    Trial.Joint(6).Euler.full(1,2,:)   = rad2deg(Euler(:,3,:)); % Y
    Trial.Joint(6).Euler.full(1,3,:)   = rad2deg(Euler(:,2,:)); % Z              
    Trial.Joint(6).dj.full             = [];                         
    Trial.Joint(6).ElevationPlane.full = -rad2deg(unwrap(atan2(Trial.Joint(6).T.full(1,2,:),Trial.Joint(6).T.full(3,2,:))));
    clear Euler dj x y p x1 y1; 
elseif contains(c3dFiles.name,'ANALYTIC3') % External rotation
    Trial.Joint(6).sequence            = 'YXZ';
    Euler                              = R2mobileYXZ_array3(Trial.Joint(6).T.full(1:3,1:3,:));
    Trial.Joint(6).Euler.full(1,1,:)   = rad2deg(Euler(:,2,:)); % X
%     Trial.Joint(6).Euler.full(1,2,:)   = rad2deg(Euler(:,1,:)); % Y
    if mean(unwrap(abs(rad2deg(Euler(:,1,:))))) > 100
        Trial.Joint(6).Euler.full(1,2,:) = -unwrap(squeeze(180+rad2deg(Euler(:,1,:)))); % Y % Sign adaptation to fullfill ISB convention 
    else
        Trial.Joint(6).Euler.full(1,2,:) = -rad2deg(Euler(:,1,:)); % Y % Sign adaptation to fullfill ISB convention 
    end
    Trial.Joint(6).Euler.full(1,3,:)   = rad2deg(Euler(:,3,:)); % Z          
    Trial.Joint(6).dj.full             = [];                         
    Trial.Joint(6).ElevationPlane.full = [];
    clear Euler dj x y p x1 y1; 
%     figure; plot(squeeze(Trial.Joint(6).Euler.full(1,2,:))');
elseif contains(c3dFiles.name,'ANALYTIC4') % Internal rotation
    Trial.Joint(6).sequence            = 'YXZ';
    Euler                              = R2mobileYXZ_array3(Trial.Joint(6).T.full(1:3,1:3,:));
    Trial.Joint(6).Euler.full(1,1,:)   = rad2deg(Euler(:,2,:)); % X
%     Trial.Joint(6).Euler.full(1,2,:)   = rad2deg(Euler(:,1,:)); % Y
    if mean(unwrap((rad2deg(Euler(:,1,:))))) > 120
        Trial.Joint(6).Euler.full(1,2,:) = -unwrap(squeeze(-180+rad2deg(Euler(:,1,:)))); % Y  
    elseif mean(unwrap((rad2deg(Euler(:,1,:))))) > 160
        Trial.Joint(6).Euler.full(1,2,:) = -unwrap(squeeze(-180+rad2deg(Euler(:,1,:))))-180; % Y 
    elseif mean(unwrap((rad2deg(Euler(:,1,:))))) < -120
        Trial.Joint(6).Euler.full(1,2,:) = -unwrap(squeeze(180+rad2deg(Euler(:,1,:)))); % Y 
    elseif mean(unwrap((rad2deg(Euler(:,1,:))))) < -160
        Trial.Joint(6).Euler.full(1,2,:) = -unwrap(squeeze(180+rad2deg(Euler(:,1,:))))+180; % Y 
    else
        Trial.Joint(6).Euler.full(1,2,:) = -rad2deg(Euler(:,1,:)); % Y
    end    
    Trial.Joint(6).Euler.full(1,3,:)   = rad2deg(Euler(:,3,:)); % Z              
    Trial.Joint(6).dj.full             = [];                           
    Trial.Joint(6).ElevationPlane.full = [];
    clear Euler dj x y p x1 y1; 
    figure; plot(squeeze(Trial.Joint(6).Euler.full(1,2,:))');
end

% -------------------------------------------------------------------------
% LEFT GLENOHUMERAL JOINT
% -------------------------------------------------------------------------
% Homogenous matrix of the rigid transformation between segments
Trial.Joint(7).T.full = Mprod_array3(Tinv_array3(Trial.Segment(6).T.full),...
                                     Trial.Segment(5).T.full);
% JCS and motion for the humerus relative to the scapula (XZY order)     
% (Senk and Chèze 2006, Creveaux et al. 2018, Phadke et al. 2011)
if contains(c3dFiles.name,'ANALYTIC1') || contains(c3dFiles.name,'FUNCTIONAL1') || contains(c3dFiles.name,'FUNCTIONAL2') || contains(c3dFiles.name,'FUNCTIONAL4') % Sagittal elevation
    Trial.Joint(7).sequence          = 'ZXY';
    Euler                            = R2mobileZXY_array3(Trial.Joint(7).T.full(1:3,1:3,:));
    Trial.Joint(7).Euler.full(1,1,:) = rad2deg(Euler(:,2,:)); % X
    Trial.Joint(7).Euler.full(1,2,:) = -rad2deg(Euler(:,3,:)); % Y
    Trial.Joint(7).Euler.full(1,3,:) = -rad2deg(Euler(:,1,:)); % Z              
    Trial.Joint(7).dj.full           = [];        
    clear Euler dj x y p x1 y1; 
elseif contains(c3dFiles.name,'ANALYTIC2') || contains(c3dFiles.name,'ANALYTIC5') || contains(c3dFiles.name,'FUNCTIONAL3') || contains(c3dFiles.name,'STATIC') || contains(c3dFiles.name,'ISOMETRIC') % Coronal elevation
    Trial.Joint(7).sequence          = 'XZY';
    Euler                            = R2mobileXZY_array3(Trial.Joint(7).T.full(1:3,1:3,:));
    Trial.Joint(7).Euler.full(1,1,:) = rad2deg(Euler(:,1,:)); % X % Sign adaptation to fullfill ISB convention  
    Trial.Joint(7).Euler.full(1,2,:) = -rad2deg(Euler(:,3,:)); % Y
    Trial.Joint(7).Euler.full(1,3,:) = -rad2deg(Euler(:,2,:)); % Z    
    Trial.Joint(7).dj.full           = [];        
    clear Euler dj x y p x1 y1; 
elseif contains(c3dFiles.name,'ANALYTIC3') % External rotation
    Trial.Joint(7).sequence          = 'YXZ';
    Euler                            = R2mobileYXZ_array3(Trial.Joint(7).T.full(1:3,1:3,:));
    Trial.Joint(7).Euler.full(1,1,:) = -rad2deg(Euler(:,2,:)); % X
%     Trial.Joint(7).Euler.full(1,2,:)   = rad2deg(Euler(:,1,:)); % Y
    if mean(unwrap(abs(rad2deg(Euler(:,1,:))))) > 120
        Trial.Joint(7).Euler.full(1,2,:) = -unwrap(squeeze(180+rad2deg(Euler(:,1,:)))); % Y % Sign adaptation to fullfill ISB convention 
    else
        Trial.Joint(7).Euler.full(1,2,:) = -rad2deg(Euler(:,1,:)); % Y % Sign adaptation to fullfill ISB convention 
    end
    Trial.Joint(7).Euler.full(1,3,:) = rad2deg(Euler(:,3,:)); % Z         
    Trial.Joint(7).dj.full           = [];       
    clear Euler dj x y p x1 y1; 
%     figure; plot(squeeze(Trial.Joint(7).Euler.full(1,2,:))');
elseif contains(c3dFiles.name,'ANALYTIC4') % Internal rotation
    Trial.Joint(7).sequence          = 'YXZ';
    Euler                            = R2mobileYXZ_array3(Trial.Joint(7).T.full(1:3,1:3,:));
    Trial.Joint(7).Euler.full(1,1,:) = -rad2deg(Euler(:,2,:)); % X
%     Trial.Joint(7).Euler.full(1,2,:) = rad2deg(Euler(:,1,:)); % Y
    if mean(unwrap(abs(rad2deg(Euler(:,1,:))))) > 120
        Trial.Joint(7).Euler.full(1,2,:) = -unwrap(squeeze(-180+rad2deg(Euler(:,1,:)))); % Y % Sign adaptation to fullfill ISB convention   
    else
        Trial.Joint(7).Euler.full(1,2,:) = -rad2deg(Euler(:,1,:)); % Y % Sign adaptation to fullfill ISB convention 
    end    
    Trial.Joint(7).Euler.full(1,3,:) = rad2deg(Euler(:,3,:)); % Z                  
    Trial.Joint(7).dj.full           = [];        
    clear Euler dj x y p x1 y1; 
%     figure; plot(squeeze(Trial.Joint(7).Euler.full(1,2,:))');
end

% -------------------------------------------------------------------------
% LEFT SCAPULOTHORACIC JOINT
% -------------------------------------------------------------------------
% Homogenous matrix of the rigid transformation between segments
Trial.Joint(8).T.full = Mprod_array3(Tinv_array3(Trial.Segment(4).T.full),...
                                     Trial.Segment(6).T.full);
% JCS and motion for the scapula relative to the thorax (YXZ order) 
% (Wu et al. 2005)
if contains(c3dFiles.name,'ANALYTIC') || contains(c3dFiles.name,'FUNCTIONAL')
    Trial.Joint(8).sequence          = 'YXZ';
    Euler                            = R2mobileYXZ_array3(Trial.Joint(8).T.full(1:3,1:3,:));
    Trial.Joint(8).Euler.full(1,1,:) = rad2deg(Euler(:,2,:)); % X
    Trial.Joint(8).Euler.full(1,2,:) = -rad2deg(Euler(:,1,:))+180; % Y % Rotation adaptation to fullfill ISB convention 
    Trial.Joint(8).Euler.full(1,3,:) = -rad2deg(Euler(:,3,:)); % Z % Sign adaptation to fullfill ISB convention   
    Trial.Joint(8).dj.full           = [];        
    clear Euler dj x y p x1 y1; 
end