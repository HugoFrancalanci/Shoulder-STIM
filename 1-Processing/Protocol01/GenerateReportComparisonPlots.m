% Author     :   F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   March 2023
% -------------------------------------------------------------------------
% Description:   To be defined
% -------------------------------------------------------------------------
% Dependencies : To be defined
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function [] = GenerateReportComparisonPlots(Folder,Session1,Session2)

% -------------------------------------------------------------------------
% Amplitude and EMG /Analytic motions
% -------------------------------------------------------------------------
for imotion = 1:4

    clear motion;

    if imotion > size(Session1.Report.Analytic,2) || imotion > size(Session2.Report.Analytic,2)
        break
    else

        % MOTION SPECIFICITIES
        % -----------------------------------------------------------------
        if imotion == 1
            ieuler = 3;
            motion(1).ititle = 'Elévation sagittale (montée | concentrique)';
            motion(2).ititle = 'Elévation sagittale (descente | excentrique)';
            motion(1).ifile  = 'Comparison_Analytic1_part1';
            motion(2).ifile  = 'Comparison_Analytic1_part2';
            if ~isfield(Session1.Session.Pain,'Rvalue') % Only pathologic side pain stored
                if contains(Session1.Pathology.Diagnosis.side,'Droite')
                    PainR_PRE = Session1.Session.Pain.value(4);
                    PainL_PRE = [];
                elseif contains(Session1.Pathology.Diagnosis.side,'Gauche')
                    PainR_PRE = [];
                    PainL_PRE = Session1.Session.Pain.value(4);
                end
            else
                PainR_PRE  = Session1.Session.Pain.Rvalue(4);
                PainL_PRE  = Session1.Session.Pain.Lvalue(4);
            end
            if ~isfield(Session2.Session.Pain,'Rvalue') % Only pathologic side pain stored
                if contains(Session2.Pathology.Diagnosis.side,'Droite')
                    PainR_POST = Session2.Session.Pain.value(4);
                    PainL_POST = [];
                elseif contains(Session2.Pathology.Diagnosis.side,'Gauche')
                    PainR_POST = [];
                    PainL_POST = Session2.Session.Pain.value(4);
                end
            else
                PainR_POST = Session2.Session.Pain.Rvalue(4);
                PainL_POST = Session2.Session.Pain.Lvalue(4);
            end
        elseif imotion == 2
            ieuler = 1;
            motion(1).ititle = 'Elévation coronale (montée | concentrique)';
            motion(2).ititle = 'Elévation coronale (descente | excentrique)';
            motion(1).ifile  = 'Comparison_Analytic2_part1';
            motion(2).ifile  = 'Comparison_Analytic2_part2';
            if ~isfield(Session1.Session.Pain,'Rvalue') % Only pathologic side pain stored
                if contains(Session1.Pathology.Diagnosis.side,'Droite')
                    PainR_PRE = Session1.Session.Pain.value(5);
                    PainL_PRE = [];
                elseif contains(Session1.Pathology.Diagnosis.side,'Gauche')
                    PainR_PRE = [];
                    PainL_PRE = Session1.Session.Pain.value(5);
                end
            else
                PainR_PRE  = Session1.Session.Pain.Rvalue(5);
                PainL_PRE  = Session1.Session.Pain.Lvalue(5);
            end
            if ~isfield(Session2.Session.Pain,'Rvalue') % Only pathologic side pain stored
                if contains(Session2.Pathology.Diagnosis.side,'Droite')
                    PainR_POST = Session2.Session.Pain.value(5);
                    PainL_POST = [];
                elseif contains(Session2.Pathology.Diagnosis.side,'Gauche')
                    PainR_POST = [];
                    PainL_POST = Session2.Session.Pain.value(5);
                end
            else
                PainR_POST = Session2.Session.Pain.Rvalue(5);
                PainL_POST = Session2.Session.Pain.Lvalue(5);
            end
        elseif imotion == 3
            ieuler = 2;
            motion(1).ititle = 'Rotation externe';
            motion(1).ifile  = 'Comparison_Analytic3_part1';
            if ~isfield(Session1.Session.Pain,'Rvalue') % Only pathologic side pain stored
                if contains(Session1.Pathology.Diagnosis.side,'Droite')
                    PainR_PRE = Session1.Session.Pain.value(6);
                    PainL_PRE = [];
                elseif contains(Session1.Pathology.Diagnosis.side,'Gauche')
                    PainR_PRE = [];
                    PainL_PRE = Session1.Session.Pain.value(6);
                end
            else
                PainR_PRE  = Session1.Session.Pain.Rvalue(6);
                PainL_PRE  = Session1.Session.Pain.Lvalue(6);
            end
            if ~isfield(Session2.Session.Pain,'Rvalue') % Only pathologic side pain stored
                if contains(Session2.Pathology.Diagnosis.side,'Droite')
                    PainR_POST = Session2.Session.Pain.value(6);
                    PainL_POST = [];
                elseif contains(Session2.Pathology.Diagnosis.side,'Gauche')
                    PainR_POST = [];
                    PainL_POST = Session2.Session.Pain.value(6);
                end
            else
                PainR_POST = Session2.Session.Pain.Rvalue(6);
                PainL_POST = Session2.Session.Pain.Lvalue(6);
            end
        elseif imotion == 4
            ieuler = 2;
            motion(1).ititle = 'Rotation interne';
            motion(1).ifile  = 'Comparison_Analytic4_part1';
            if ~isfield(Session1.Session.Pain,'Rvalue') % Only pathologic side pain stored
                if contains(Session1.Pathology.Diagnosis.side,'Droite')
                    PainR_PRE = Session1.Session.Pain.value(7);
                    PainL_PRE = [];
                elseif contains(Session1.Pathology.Diagnosis.side,'Gauche')
                    PainR_PRE = [];
                    PainL_PRE = Session1.Session.Pain.value(7);
                end
            else
                PainR_PRE  = Session1.Session.Pain.Rvalue(7);
                PainL_PRE  = Session1.Session.Pain.Lvalue(7);
            end
            if ~isfield(Session2.Session.Pain,'Rvalue') % Only pathologic side pain stored
                if contains(Session2.Pathology.Diagnosis.side,'Droite')
                    PainR_POST = Session2.Session.Pain.value(7);
                    PainL_POST = [];
                elseif contains(Session2.Pathology.Diagnosis.side,'Gauche')
                    PainR_POST = [];
                    PainL_POST = Session2.Session.Pain.value(7);
                end
            else
                PainR_POST = Session2.Session.Pain.Rvalue(7);
                PainL_POST = Session2.Session.Pain.Lvalue(7);
            end
        end

        for nmotion = 1:size(motion,2)

            clearvars -except Folder Session1 Session2 imotion nmotion ieuler PainR_PRE PainR_POST PainL_PRE PainL_POST motion;

            % MOTION PART i | Upper part
            % -----------------------------------------------------------------
        
            % FIGURE
            img = figure('Position',[50 20 900 900],'Color','white');
            hold on; axis equal;
            text(0,20,['\bf{',motion(nmotion).ititle,'}'], ...
                       'HorizontalAlignment','center','FontSize',16);   
            xlim([-21 21]);
            ylim([-19 19]);
            axis off;
            xshift = 4;
            
            % LEGEND
            fontsize = 9;
            emgLabels = {'    < DELT. ANT.','    < DELT. MED.','    < DELT. POS.','    < TRAP. SUP.','    < TRAP. INF.','    < GD. DENTELE','    < GD. DORSAL', ...
                         '    DELT. ANT. >','    DELT. MED. >','    DELT. POS. >','    TRAP. SUP. >','    TRAP. INF. >','    GD. DENTELE >','    GD. DORSAL >'};
            for iemg = 1:7
                if ~isempty(Session1.Report.Analytic(imotion).Emg.Envelop(iemg).value) || ~isempty(Session2.Report.Analytic(imotion).Emg.Envelop(iemg).value)
                    text(-0.4,2*iemg,emgLabels{iemg},'HorizontalAlignment','center','FontSize',fontsize);
                else
                    text(-0.4,2*iemg,emgLabels{iemg},'HorizontalAlignment','center','FontSize',fontsize,'Color',[0.8 0.8 0.8]);
                end
            end
            text(-0.4,16,'    < \bf{ANGLE}','HorizontalAlignment','center','FontSize',fontsize);
            for iemg = 8:14
                if ~isempty(Session1.Report.Analytic(imotion).Emg.Envelop(iemg).value) || ~isempty(Session2.Report.Analytic(imotion).Emg.Envelop(iemg).value)
                    text(-0.4,-2*(iemg-7),emgLabels{iemg},'HorizontalAlignment','center','FontSize',fontsize);
                else
                    text(-0.4,-2*(iemg-7),emgLabels{iemg},'HorizontalAlignment','center','FontSize',fontsize,'Color',[0.8 0.8 0.8]);
                end
            end
            text(-0.4,-16,'   \bf{ANGLE} >','HorizontalAlignment','center','FontSize',fontsize);
            
            % ANGLE TEXT
            r = 17.8;
            text(r*cosd(0-90)+xshift,r*sind(0-90),'0°','HorizontalAlignment','center','FontSize',14);
            text(r*cosd(20-90)+xshift,r*sind(20-90),'20°','HorizontalAlignment','center','FontSize',14);
            text(r*cosd(40-90)+xshift,r*sind(40-90),'40°','HorizontalAlignment','center','FontSize',14);
            text(r*cosd(60-90)+xshift,r*sind(60-90),'60°','HorizontalAlignment','center','FontSize',14);
            text(r*cosd(80-90)+xshift,r*sind(80-90),'80°','HorizontalAlignment','center','FontSize',14);
            text(r*cosd(100-90)+xshift,r*sind(100-90),'100°','HorizontalAlignment','center','FontSize',14);
            text(r*cosd(120-90)+xshift,r*sind(120-90),'120°','HorizontalAlignment','center','FontSize',14);
            text(r*cosd(140-90)+xshift,r*sind(140-90),'140°','HorizontalAlignment','center','FontSize',14);
            text(r*cosd(160-90)+xshift,r*sind(160-90),'160°','HorizontalAlignment','center','FontSize',14);
            text(r*cosd(180-90)+xshift,r*sind(180-90),'180°','HorizontalAlignment','center','FontSize',14);
            text(-r*cosd(0-90)-xshift,r*sind(0-90),'0°','HorizontalAlignment','center','FontSize',14);
            text(-r*cosd(20-90)-xshift,r*sind(20-90),'20°','HorizontalAlignment','center','FontSize',14);
            text(-r*cosd(40-90)-xshift,r*sind(40-90),'40°','HorizontalAlignment','center','FontSize',14);
            text(-r*cosd(60-90)-xshift,r*sind(60-90),'60°','HorizontalAlignment','center','FontSize',14);
            text(-r*cosd(80-90)-xshift,r*sind(80-90),'80°','HorizontalAlignment','center','FontSize',14);
            text(-r*cosd(100-90)-xshift,r*sind(100-90),'100°','HorizontalAlignment','center','FontSize',14);
            text(-r*cosd(120-90)-xshift,r*sind(120-90),'120°','HorizontalAlignment','center','FontSize',14);
            text(-r*cosd(140-90)-xshift,r*sind(140-90),'140°','HorizontalAlignment','center','FontSize',14);
            text(-r*cosd(160-90)-xshift,r*sind(160-90),'160°','HorizontalAlignment','center','FontSize',14);
            text(-r*cosd(180-90)-xshift,r*sind(180-90),'180°','HorizontalAlignment','center','FontSize',14);
                
            % DRAW EMPTY PLOT
            for r = 0:2:16
                x = r.*cos(linspace(-pi/2,pi/2,1000))+xshift;
                y = r.*sin(linspace(-pi/2,pi/2,1000));
                plot(x,y,'Color',[0.97 0.97 0.97],'Linewidth',10);
                clear x y;
            end
            for r = 0:2:16
                x = -r.*cos(linspace(-pi/2,pi/2,1000))-xshift;
                y = r.*sin(linspace(-pi/2,pi/2,1000));
                plot(x,y,'Color',[0.97 0.97 0.97],'Linewidth',10);
                clear x y;
            end
            r = 17;
            for angle = 0:20:180
                line([1*cosd(angle-90) r*cosd(angle-90)]+xshift,[1*sind(angle-90) r*sind(angle-90)],'Linestyle','-','Linewidth',0.5,'Color',[0.8 0.8 0.8]);
            end
            for angle = 0:-20:-180
                line([1*cosd(angle-90) r*cosd(angle-90)]-xshift,[1*sind(angle-90) r*sind(angle-90)],'Linestyle','-','Linewidth',0.5,'Color',[0.8 0.8 0.8]);
            end  
        
            % NORMAL ANGLE DATA (from Session1)
            r = 15.39;
            x = r.*cosd(linspace(Session1.Normal.Analytic(imotion).mean-Session1.Normal.Analytic(imotion).std-90,Session1.Normal.Analytic(imotion).mean+Session1.Normal.Analytic(imotion).std-90,1000))+xshift;
            y = r.*sind(linspace(Session1.Normal.Analytic(imotion).mean-Session1.Normal.Analytic(imotion).std-90,Session1.Normal.Analytic(imotion).mean+Session1.Normal.Analytic(imotion).std-90,1000));
            plot(x,y,'Color',[0 0 0],'Linewidth',5);
            x = -r.*cosd(linspace(Session1.Normal.Analytic(imotion).mean-Session1.Normal.Analytic(imotion).std-90,Session1.Normal.Analytic(imotion).mean+Session1.Normal.Analytic(imotion).std-90,1000))-xshift;
            y = r.*sind(linspace(Session1.Normal.Analytic(imotion).mean-Session1.Normal.Analytic(imotion).std-90,Session1.Normal.Analytic(imotion).mean+Session1.Normal.Analytic(imotion).std-90,1000));
            plot(x,y,'Color',[0 0 0],'Linewidth',5); 
            
            % LEFT /PRE
            thetaRmax = [];
            thetaRmin = [];
            for icycle = 1:size(Session1.Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,:),3)
                % AMPLITUDE
                if imotion == 3
                    [~,imax] = max(-(Session1.Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle)));
                    if nmotion == 1
                        range = 1:imax;
                    else
                        range = imax:101;
                    end  
                    angleL   = -(Session1.Report.Analytic(imotion).Kinematics.Joint(6).Euler(range,ieuler,icycle));
                else
                    [~,imax] = max((Session1.Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle)));
                    if nmotion == 1
                        range = 1:imax;
                    else
                        range = imax:101;
                    end  
                    angleL   = (Session1.Report.Analytic(imotion).Kinematics.Joint(6).Euler(range,ieuler,icycle));
                end      
                for iframe = 1:size(angleL,1) % We reject negative value = the task was defined not performed in this case
                    if angleL(iframe) < 0
                        angleL(iframe) = 0;
                    end
                end
                thetaL = linspace(deg2rad(-90+round(min(angleL))),deg2rad(-90+round(max(angleL))),size(angleL,1));
                thetaLmax(icycle) = deg2rad(-90+max(angleL));
                thetaLmin(icycle) = deg2rad(-90+min(angleL));
                r = 15.8; % POST 16.2
                x = r.*cos(thetaL)+xshift;
                y = r.*sin(thetaL);
                plot(x,y,'Color',[1 0.5 0 0.2],'Linewidth',3);
                clear angleR thetaL r x y;
        
                % SHR
                if imotion == 1 || imotion == 2    
                    angleL = (Session1.Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle));
                    thetaL = deg2rad(-90+angleL);
                    for t = range
                        x(t) = 3*Session1.Report.Analytic(imotion).Kinematics.SHR(2).tvalue(t,:,icycle).*cos(thetaL(t))+xshift;
                        y(t) = 3*Session1.Report.Analytic(imotion).Kinematics.SHR(2).tvalue(t,:,icycle).*sin(thetaL(t));
    %                     if x(t)-xshift < 7 && y(t) < 7
                            if (rad2deg(thetaL(t))+90 > 30) && (rad2deg(thetaL(t))+90 < 120)                        
                                plot(x(t),y(t),'Color',[1 0.5 0],'Linestyle','none','Marker','.','Markersize',11);
                            else
%                                 plot(x(t),y(t),'Color',[0 0 0],'Linestyle','none','Marker','.','Markersize',4);
                            end
    %                     end
                    end
                    clear thetaL r x y;
                end
            
                % EMG
                for iemg = 1:7
                    r = iemg*2-0.2; % POST +0.2
                    if ~isempty(Session1.Report.Analytic(imotion).Emg.Envelop(iemg+7).value) % +7 for left sensors
                        value = Session1.Report.Analytic(imotion).Emg.Envelop(iemg+7).value(:,1,icycle); % +7 for left sensors
                        if imotion == 3
                            angleEMG = -(Session1.Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle));
                        else
                            angleEMG = (Session1.Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle));
                        end
                        for iframe = 1:size(angleEMG,1) % We reject negative value = the task was defined not performed in this case
                            if angleEMG(iframe) < 0
                                angleEMG(iframe) = 0;
                                value(iframe)    = 0;
                            end
                        end
                        thetaEMG = [];
                        start = 0;
                        stop = 0;
                        for ivalue = range
                            value(ivalue)
                            if start == 0
                                if value(ivalue) > 0.5
                                    start = ivalue;
                                end
                            end
                            if start > 0
                                if value(ivalue) < 0.5 || ivalue == range(end)
                                    stop = ivalue;
                                end
                            end
                            if start > 0 && stop > 0
                                thetaEMG = linspace(deg2rad(-90-min(angleEMG(start:stop))), ...
                                                    deg2rad(-90-max(angleEMG(start:stop))), ...
                                                    size(angleEMG,1));
                                start = 0;
                                stop = 0;
                                x = -r.*cos(thetaEMG)+xshift;
                                y = r.*sin(thetaEMG);
                                plot(x,y,'Color',[0 0 0 0.2],'Linewidth',3);
                                clear x y;
                            end
                        end
                    end
                end
            end
            clear range angleL thetaL r x y;
            r = 18;
            line([1*cos(max(thetaLmax)) r*cos(max(thetaLmax))]+xshift,[1*sin(max(thetaLmax)) r*sin(max(thetaLmax))],'Linestyle','-','Linewidth',1.5,'Color',[1 0.5 0]);
            line([1*cos(min(thetaLmin)) r*cos(min(thetaLmin))]+xshift,[1*sin(min(thetaLmin)) r*sin(min(thetaLmin))],'Linestyle','-','Linewidth',1.5,'Color',[1 0.5 0]);
            r = 19;
            text(r*cos(max(thetaLmax))+xshift,r*sin(max(thetaLmax)),[num2str(fix(rad2deg(max(thetaLmax))+90)),'°'],'HorizontalAlignment','center','Color',[1 0.5 0],'FontSize',14);
            text(r*cos(min(thetaLmin))+xshift,r*sin(min(thetaLmin)),[num2str(fix(rad2deg(min(thetaLmin))+90)),'°'],'HorizontalAlignment','center','Color',[1 0.5 0],'FontSize',14);   
                        
            % LEFT /POST
            thetaRmax = [];
            thetaRmin = [];
            for icycle = 1:size(Session2.Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,:),3)
                % AMPLITUDE
                if imotion == 3
                    [~,imax] = max(-(Session2.Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle)));
                    if nmotion == 1
                        range = 1:imax;
                    else
                        range = imax:101;
                    end  
                    angleL   = -(Session2.Report.Analytic(imotion).Kinematics.Joint(6).Euler(range,ieuler,icycle));
                else
                    [~,imax] = max((Session2.Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle)));
                    if nmotion == 1
                        range = 1:imax;
                    else
                        range = imax:101;
                    end  
                    angleL   = (Session2.Report.Analytic(imotion).Kinematics.Joint(6).Euler(range,ieuler,icycle));
                end      
                for iframe = 1:size(angleL,1) % We reject negative value = the task was defined not performed in this case
                    if angleL(iframe) < 0
                        angleL(iframe) = 0;
                    end
                end
                thetaL = linspace(deg2rad(-90+round(min(angleL))),deg2rad(-90+round(max(angleL))),size(angleL,1));
                thetaLmax(icycle) = deg2rad(-90+max(angleL));
                thetaLmin(icycle) = deg2rad(-90+min(angleL));
                r = 16.2;
                x = r.*cos(thetaL)+xshift;
                y = r.*sin(thetaL);
                plot(x,y,'Color',[1 0 0 0.2],'Linewidth',5);
                clear angleR thetaL r x y;
        
                % SHR
                if imotion == 1 || imotion == 2    
                    angleL = (Session2.Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle));
                    thetaL = deg2rad(-90+angleL);
                    for t = range
                        x(t) = 3*Session2.Report.Analytic(imotion).Kinematics.SHR(2).tvalue(t,:,icycle).*cos(thetaL(t))+xshift;
                        y(t) = 3*Session2.Report.Analytic(imotion).Kinematics.SHR(2).tvalue(t,:,icycle).*sin(thetaL(t));
    %                     if x(t)-xshift < 7 && y(t) < 7
                            if (rad2deg(thetaL(t))+90 > 30) && (rad2deg(thetaL(t))+90 < 120)                        
                                plot(x(t),y(t),'Color',[1 0 0],'Linestyle','none','Marker','.','Markersize',11);
                            else
%                                 plot(x(t),y(t),'Color',[0 0 0],'Linestyle','none','Marker','.','Markersize',4);
                            end
    %                     end
                    end
                    clear thetaL r x y;
                end
            
                % EMG
                for iemg = 1:7
                    r = iemg*2+0.2;
                    if ~isempty(Session2.Report.Analytic(imotion).Emg.Envelop(iemg+7).value) % +7 for left sensors
                        value = Session2.Report.Analytic(imotion).Emg.Envelop(iemg+7).value(:,1,icycle); % +7 for left sensors
                        if imotion == 3
                            angleEMG = -(Session2.Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle));
                        else
                            angleEMG = (Session2.Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle));
                        end
                        for iframe = 1:size(angleEMG,1) % We reject negative value = the task was defined not performed in this case
                            if angleEMG(iframe) < 0
                                angleEMG(iframe) = 0;
                                value(iframe)    = 0;
                            end
                        end
                        thetaEMG = [];
                        start = 0;
                        stop = 0;
                        for ivalue = range
                            value(ivalue)
                            if start == 0
                                if value(ivalue) > 0.5
                                    start = ivalue;
                                end
                            end
                            if start > 0
                                if value(ivalue) < 0.5 || ivalue == range(end)
                                    stop = ivalue;
                                end
                            end
                            if start > 0 && stop > 0
                                thetaEMG = linspace(deg2rad(-90-min(angleEMG(start:stop))), ...
                                                    deg2rad(-90-max(angleEMG(start:stop))), ...
                                                    size(angleEMG,1));
                                start = 0;
                                stop = 0;
                                x = -r.*cos(thetaEMG)+xshift;
                                y = r.*sin(thetaEMG);
                                plot(x,y,'Color',[0 0 0 0.2],'Linewidth',5);
                                clear x y;
                            end
                        end
                    end
                end
            end
            clear range angleL thetaL r x y;
            r = 18;
            line([1*cos(max(thetaLmax)) r*cos(max(thetaLmax))]+xshift,[1*sin(max(thetaLmax)) r*sin(max(thetaLmax))],'Linestyle','-','Linewidth',1.5,'Color',[1 0 0]);
            line([1*cos(min(thetaLmin)) r*cos(min(thetaLmin))]+xshift,[1*sin(min(thetaLmin)) r*sin(min(thetaLmin))],'Linestyle','-','Linewidth',1.5,'Color',[1 0 0]);
            r = 19;
            text(r*cos(max(thetaLmax))+xshift,r*sin(max(thetaLmax)),[num2str(fix(rad2deg(max(thetaLmax))+90)),'°'],'HorizontalAlignment','center','Color',[1 0 0],'FontSize',14);
            text(r*cos(min(thetaLmin))+xshift,r*sin(min(thetaLmin)),[num2str(fix(rad2deg(min(thetaLmin))+90)),'°'],'HorizontalAlignment','center','Color',[1 0 0],'FontSize',14);   
            
            % SHR lines
            if imotion == 1 || imotion == 2
                x = [3*(Session1.Normal.Analytic(imotion).SHR.mean-Session1.Normal.Analytic(imotion).SHR.std).*cos(linspace(min(thetaLmin),max(thetaLmax),1000))+xshift ...
                     3*(Session1.Normal.Analytic(imotion).SHR.mean+Session1.Normal.Analytic(imotion).SHR.std).*cos(linspace(max(thetaLmax),min(thetaLmin),1000))+xshift];
                y = [3*(Session1.Normal.Analytic(imotion).SHR.mean-Session1.Normal.Analytic(imotion).SHR.std).*sin(linspace(min(thetaLmin),max(thetaLmax),1000)) ...
                     3*(Session1.Normal.Analytic(imotion).SHR.mean+Session1.Normal.Analytic(imotion).SHR.std).*sin(linspace(max(thetaLmax),min(thetaLmin),1000))];
                fill(x,y,'red','LineStyle','none','FaceAlpha',0.15);
                clear x y;
            end  
            clear thetaLmax thetaLmin;
    
            % RIGHT /PRE
            thetaRmax = [];
            thetaRmin = [];
            for icycle = 1:size(Session1.Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,:),3)
                % AMPLITUDE
                if imotion == 3
                    [~,imax] = max(-(Session1.Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle)));
                    if nmotion == 1
                        range = 1:imax;
                    else
                        range = imax:101;
                    end  
                    angleR   = -(Session1.Report.Analytic(imotion).Kinematics.Joint(1).Euler(range,ieuler,icycle));
                else
                    [~,imax] = max((Session1.Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle)));
                    if nmotion == 1
                        range = 1:imax;
                    else
                        range = imax:101;
                    end  
                    angleR   = (Session1.Report.Analytic(imotion).Kinematics.Joint(1).Euler(range,ieuler,icycle));
                end         
                for iframe = 1:size(angleR,1) % We reject negative value = the task was defined not performed in this case
                    if angleR(iframe) < 0
                        angleR(iframe) = 0;
                    end
                end      
                thetaR = linspace(deg2rad(-90-round(min(angleR))),deg2rad(-90-round(max(angleR))),size(angleR,1));        
                thetaRmax(icycle) = deg2rad(-90-min(angleR));
                thetaRmin(icycle) = deg2rad(-90-max(angleR));
                r = 15.8;
                x = r.*cos(thetaR)-xshift;
                y = r.*sin(thetaR);
                plot(x,y,'Color',[0 81/128 128/128 0.2],'Linewidth',3);
                clear angleR thetaR r x y;
        
                % SHR
                if imotion == 1 || imotion == 2     
                    angleR = (Session1.Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle));
                    thetaR = deg2rad(-90-angleR);
                    for t = range
                        x(t) = 3*Session1.Report.Analytic(imotion).Kinematics.SHR(1).tvalue(t,:,icycle).*cos(thetaR(t))-xshift;
                        y(t) = 3*Session1.Report.Analytic(imotion).Kinematics.SHR(1).tvalue(t,:,icycle).*sin(thetaR(t));     
    %                     if x(t)-xshift < 7 && y(t) < 7
                            if (-rad2deg(thetaR(t))-90 > 30) && (-rad2deg(thetaR(t))-90 < 120)
                                plot(x(t),y(t),'Color',[0 81/128 128/128],'Linestyle','none','Marker','.','Markersize',11);
                            else
%                                 plot(x(t),y(t),'Color',[0 0 1],'Linestyle','none','Marker','.','Markersize',4);
                            end
    %                     end
                    end
                    clear thetaR r x y;
                end        
            
                % EMG
                for iemg = 1:7
                    r = iemg*2-0.2;
                    if ~isempty(Session1.Report.Analytic(imotion).Emg.Envelop(iemg).value)
                        value = Session1.Report.Analytic(imotion).Emg.Envelop(iemg).value(:,1,icycle);
                        if imotion == 3
                            angleEMG = -(Session1.Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle));
                        else
                            angleEMG = (Session1.Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle));
                        end
                        for iframe = 1:size(angleEMG,1) % We reject negative value = the task was defined not performed in this case
                            if angleEMG(iframe) < 0
                                angleEMG(iframe) = 0;
                                value(iframe)    = 0;
                            end
                        end
                        thetaEMG = [];
                        start = 0;
                        stop = 0;
                        for ivalue = range
                            value(ivalue)
                            if start == 0
                                if value(ivalue) > 0.5
                                    start = ivalue;
                                end
                            end
                            if start > 0
                                if value(ivalue) < 0.5 || ivalue == range(end)
                                    stop = ivalue;
                                end
                            end
                            if start > 0 && stop > 0
                                thetaEMG = linspace(deg2rad(-90-abs(min(Session1.Report.Analytic(imotion).Kinematics.Joint(1).Euler(start:stop,ieuler,icycle)))), ...
                                                    deg2rad(-90-abs(max(Session1.Report.Analytic(imotion).Kinematics.Joint(1).Euler(start:stop,ieuler,icycle)))), ...
                                                    size(angleEMG,1));
                                start = 0;
                                stop = 0;
                                x = r.*cos(thetaEMG)-xshift;
                                y = r.*sin(thetaEMG);
                                plot(x,y,'Color',[0 0 0 0.2],'Linewidth',3);
                                clear x y;
                            end
                        end
                    end
                end
            end
            clear range angleR thetaR r x y;
            r = 18;
            line([1*cos(max(thetaRmax)) r*cos(max(thetaRmax))]-xshift,[1*sin(max(thetaRmax)) r*sin(max(thetaRmax))],'Linestyle','-','Linewidth',1.5,'Color',[0 81/128 128/128]);
            line([1*cos(min(thetaRmin)) r*cos(min(thetaRmin))]-xshift,[1*sin(min(thetaRmin)) r*sin(min(thetaRmin))],'Linestyle','-','Linewidth',1.5,'Color',[0 81/128 128/128]);
            r = 19;
            text(r*cos(max(thetaRmax))-xshift,r*sin(max(thetaRmax)),[num2str(-fix(rad2deg(max(thetaRmax))+90)),'°'],'HorizontalAlignment','center','Color',[0 81/128 128/128],'FontSize',14);
            text(r*cos(min(thetaRmin))-xshift,r*sin(min(thetaRmin)),[num2str(-fix(rad2deg(min(thetaRmin))+90)),'°'],'HorizontalAlignment','center','Color',[0 81/128 128/128],'FontSize',14);
    
            % RIGHT /POST
            thetaRmax = [];
            thetaRmin = [];
            for icycle = 1:size(Session2.Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,:),3)
                % AMPLITUDE
                if imotion == 3
                    [~,imax] = max(-(Session2.Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle)));
                    if nmotion == 1
                        range = 1:imax;
                    else
                        range = imax:101;
                    end  
                    angleR   = -(Session2.Report.Analytic(imotion).Kinematics.Joint(1).Euler(range,ieuler,icycle));
                else
                    [~,imax] = max((Session2.Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle)));
                    if nmotion == 1
                        range = 1:imax;
                    else
                        range = imax:101;
                    end  
                    angleR   = (Session2.Report.Analytic(imotion).Kinematics.Joint(1).Euler(range,ieuler,icycle));
                end         
                for iframe = 1:size(angleR,1) % We reject negative value = the task was defined not performed in this case
                    if angleR(iframe) < 0
                        angleR(iframe) = 0;
                    end
                end      
                thetaR = linspace(deg2rad(-90-round(min(angleR))),deg2rad(-90-round(max(angleR))),size(angleR,1));        
                thetaRmax(icycle) = deg2rad(-90-min(angleR));
                thetaRmin(icycle) = deg2rad(-90-max(angleR));
                r = 16.2;
                x = r.*cos(thetaR)-xshift;
                y = r.*sin(thetaR);
                plot(x,y,'Color',[0 0 1 0.2],'Linewidth',5);
                clear angleR thetaR r x y;
        
                % SHR
                if imotion == 1 || imotion == 2     
                    angleR = (Session2.Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle));
                    thetaR = deg2rad(-90-angleR);
                    for t = range
                        x(t) = 3*Session2.Report.Analytic(imotion).Kinematics.SHR(1).tvalue(t,:,icycle).*cos(thetaR(t))-xshift;
                        y(t) = 3*Session2.Report.Analytic(imotion).Kinematics.SHR(1).tvalue(t,:,icycle).*sin(thetaR(t));     
    %                     if x(t)-xshift < 7 && y(t) < 7
                            if (-rad2deg(thetaR(t))-90 > 30) && (-rad2deg(thetaR(t))-90 < 120)
                                plot(x(t),y(t),'Color',[0 0 1],'Linestyle','none','Marker','.','Markersize',11);
                            else
%                                 plot(x(t),y(t),'Color',[0 0 1],'Linestyle','none','Marker','.','Markersize',4);
                            end
    %                     end
                    end
                    clear thetaR r x y;
                end        
            
                % EMG
                for iemg = 1:7
                    r = iemg*2+0.2;
                    if ~isempty(Session2.Report.Analytic(imotion).Emg.Envelop(iemg).value)
                        value = Session2.Report.Analytic(imotion).Emg.Envelop(iemg).value(:,1,icycle);
                        if imotion == 3
                            angleEMG = -(Session2.Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle));
                        else
                            angleEMG = (Session2.Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle));
                        end
                        for iframe = 1:size(angleEMG,1) % We reject negative value = the task was defined not performed in this case
                            if angleEMG(iframe) < 0
                                angleEMG(iframe) = 0;
                                value(iframe)    = 0;
                            end
                        end
                        thetaEMG = [];
                        start = 0;
                        stop = 0;
                        for ivalue = range
                            value(ivalue)
                            if start == 0
                                if value(ivalue) > 0.5
                                    start = ivalue;
                                end
                            end
                            if start > 0
                                if value(ivalue) < 0.5 || ivalue == range(end)
                                    stop = ivalue;
                                end
                            end
                            if start > 0 && stop > 0
                                thetaEMG = linspace(deg2rad(-90-abs(min(Session2.Report.Analytic(imotion).Kinematics.Joint(1).Euler(start:stop,ieuler,icycle)))), ...
                                                    deg2rad(-90-abs(max(Session2.Report.Analytic(imotion).Kinematics.Joint(1).Euler(start:stop,ieuler,icycle)))), ...
                                                    size(angleEMG,1));
                                start = 0;
                                stop = 0;
                                x = r.*cos(thetaEMG)-xshift;
                                y = r.*sin(thetaEMG);
                                plot(x,y,'Color',[0 0 0 0.2],'Linewidth',5);
                                clear x y;
                            end
                        end
                    end
                end
            end
            clear range angleR thetaR r x y;
            r = 18;
            line([1*cos(max(thetaRmax)) r*cos(max(thetaRmax))]-xshift,[1*sin(max(thetaRmax)) r*sin(max(thetaRmax))],'Linestyle','-','Linewidth',1.5,'Color',[0 0 1]);
            line([1*cos(min(thetaRmin)) r*cos(min(thetaRmin))]-xshift,[1*sin(min(thetaRmin)) r*sin(min(thetaRmin))],'Linestyle','-','Linewidth',1.5,'Color',[0 0 1]);
            r = 19;
            text(r*cos(max(thetaRmax))-xshift,r*sin(max(thetaRmax)),[num2str(-fix(rad2deg(max(thetaRmax))+90)),'°'],'HorizontalAlignment','center','Color',[0 0 1],'FontSize',14);
            text(r*cos(min(thetaRmin))-xshift,r*sin(min(thetaRmin)),[num2str(-fix(rad2deg(min(thetaRmin))+90)),'°'],'HorizontalAlignment','center','Color',[0 0 1],'FontSize',14);
    
            % SHR lines
            if imotion == 1 || imotion == 2
                x = [3*(Session1.Normal.Analytic(imotion).SHR.mean-Session1.Normal.Analytic(imotion).SHR.std).*cos(linspace(min(thetaRmin),max(thetaRmax),1000))-xshift ...
                     3*(Session1.Normal.Analytic(imotion).SHR.mean+Session1.Normal.Analytic(imotion).SHR.std).*cos(linspace(max(thetaRmax),min(thetaRmin),1000))-xshift];
                y = [3*(Session1.Normal.Analytic(imotion).SHR.mean-Session1.Normal.Analytic(imotion).SHR.std).*sin(linspace(min(thetaRmin),max(thetaRmax),1000)) ...
                     3*(Session1.Normal.Analytic(imotion).SHR.mean+Session1.Normal.Analytic(imotion).SHR.std).*sin(linspace(max(thetaRmax),min(thetaRmin),1000))];
                fill(x,y,[0 0 1],'LineStyle','none','FaceAlpha',0.15);
                clear x y;
            end
            clear thetaRmax thetaRmin;
        
            % SAVE
            exportgraphics(img,[motion(nmotion).ifile,'_range.png'],'BackgroundColor','none','Resolution',600);
            close all;
    
            % MOTION PART i | Lower part, right elevation plane
            % -----------------------------------------------------------------
            if imotion == 1 || imotion == 2  
                img = figure('Position',[50 20 900 400],'Color','white');
                hold on;
                axis off;
                ax = polaraxes;
                grid off;
                if nmotion == 1
                    angle1 = deg2rad([0 mean(Session1.Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value1)]);
                    angle2 = deg2rad([0 mean(Session2.Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value1)]);
                elseif nmotion == 2
                    angle1 = deg2rad([0 mean(Session1.Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value2)]);
                    angle2 = deg2rad([0 mean(Session2.Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value2)]);
                end
                pimg = polarplot(ax,angle1,[0 1],'Color',[0 81/128 128/128 0.2],'LineStyle','--','LineWidth',3);
                hold on;
                grid off;
                pimg = polarplot(ax,angle2,[0 1],'Color',[0 0 1 0.2],'LineStyle','--','LineWidth',3);
                hold on;
                grid off;
                angle = deg2rad([0 0]);
                pimg = polarplot(ax,angle,[0 1],'Color',[0.7 0.7 0.7],'LineStyle','-','LineWidth',2);
                hold on;
                grid off;
                angle = deg2rad([0 90]);
                pimg = polarplot(ax,angle,[0 1],'Color',[0.7 0.7 0.7],'LineStyle','-','LineWidth',2);
                hold on;
                grid off;
                angle = deg2rad([0 270]);
                pimg = polarplot(ax,angle,[0 1],'Color',[0.7 0.7 0.7],'LineStyle','-','LineWidth',2);
                hold on;
                grid off;
                polarfill(ax,deg2rad(180+30):0.01:deg2rad(180+45),0,1,'blue',0.1); % Normal scapular plane 30-45°
                hold on;
                grid off;
                ax.ThetaZeroLocation = 'left';
                ax.RTickLabel = {};
                ax.ThetaTick = [];
                set(ax,'LineWidth',3); 
                set(gca,'color','none');
                ha = gca;
                haPos = get(ha,'position');
                ha2 = axes('position',[0.49,0.34,0.22,0.29]);
                [I,~,alphachannel] = imread([Folder.toolbox,'Report\Skeleton_top.png']);
                test = image(I,'AlphaData',alphachannel);
                axis off;
                text(-180,50,'0°','FontSize',24);
                text(8,280,'90°','FontSize',24);  
                exportgraphics(img,[motion(nmotion).ifile,'_elevationR.png'],'BackgroundColor','none','Resolution',600);
                close all;
            end
    
            % MOTION PART i | Lower part, left elevation plane
            % -----------------------------------------------------------------
            if imotion == 1 || imotion == 2  
                img = figure('Position',[50 20 900 400],'Color','white');
                hold on;
                axis off;
                ax = polaraxes;
                grid off;
                if nmotion == 1
                    angle1 = deg2rad([0 -mean(Session1.Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value1)]);
                    angle2 = deg2rad([0 -mean(Session2.Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value1)]);
                elseif nmotion == 2
                    angle1 = deg2rad([0 -mean(Session1.Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value2)]);
                    angle2 = deg2rad([0 -mean(Session2.Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value2)]);
                end
                pimg = polarplot(ax,angle1,[0 1],'Color',[1 0.5 0 0.2],'LineStyle','--','LineWidth',3);
                hold on;
                grid off;
                pimg = polarplot(ax,angle2,[0 1],'Color',[1 0 0 0.2],'LineStyle','--','LineWidth',3);
                hold on;
                grid off;
                angle = deg2rad([0 0]);
                pimg = polarplot(ax,angle,[0 1],'Color',[0.7 0.7 0.7],'LineStyle','-','LineWidth',2);
                hold on;
                grid off;
                angle = deg2rad([0 90]);
                pimg = polarplot(ax,angle,[0 1],'Color',[0.7 0.7 0.7],'LineStyle','-','LineWidth',2);
                hold on;
                grid off;
                angle = deg2rad([0 270]);
                pimg = polarplot(ax,angle,[0 1],'Color',[0.7 0.7 0.7],'LineStyle','-','LineWidth',2);
                hold on;
                grid off;
                polarfill(ax,deg2rad(360-45):0.01:deg2rad(360-30),0,1,'red',0.1); % Normal scapular plane 30-45°
                hold on;
                grid off;
                ax.ThetaZeroLocation = 'right';
                ax.RTickLabel = {};
                ax.ThetaTick = [];
                set(ax,'LineWidth',3); 
                set(gca,'color','none');
                ha = gca;
                haPos = get(ha,'position');
                ha2 = axes('position',[0.32,0.34,0.22,0.29]);
                [I,~,alphachannel] = imread([Folder.toolbox,'Report\Skeleton_top.png']);
                test = image(I,'AlphaData',alphachannel);
                axis off;
                text(360,50,'0°','FontSize',24);
                text(165,280,'90°','FontSize',24);  
                exportgraphics(img,[motion(nmotion).ifile,'_elevationL.png'],'BackgroundColor','none','Resolution',600);
                close all;
            end
    
            % MOTION PART i | Lower part, right and left plane of elevation
            if imotion == 1 || imotion == 2  
                img = figure('Position',[50 20 900 400],'Color','white');
                hold on;
                axis off;
                if nmotion == 1
                    text(0,1,[num2str(round(mean(Session1.Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value1),1)),' +/- ',num2str(round(std(Session1.Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value1),1))]);
                elseif nmotion == 2
                    text(0,1,[num2str(round(mean(Session1.Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value2),1)),' +/- ',num2str(round(std(Session1.Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value2),1))]);
                end                
                exportgraphics(img,[motion(nmotion).ifile,'_elevationPlaneR_PRE.png'],'BackgroundColor','none','Resolution',600);
                close all; 
                img = figure('Position',[50 20 900 400],'Color','white');
                hold on;
                axis off;
                if nmotion == 1
                    text(0,1,[num2str(round(mean(Session2.Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value1),1)),' +/- ',num2str(round(std(Session2.Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value1),1))]);
                elseif nmotion == 2
                    text(0,1,[num2str(round(mean(Session2.Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value2),1)),' +/- ',num2str(round(std(Session2.Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value2),1))]);
                end                
                exportgraphics(img,[motion(nmotion).ifile,'_elevationPlaneR_POST.png'],'BackgroundColor','none','Resolution',600);
                close all; 
                img = figure('Position',[50 20 900 400],'Color','white');
                hold on;
                axis off;
                if nmotion == 1
                    text(0,1,[num2str(round(mean(Session1.Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value1),1)),' +/- ',num2str(round(std(Session1.Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value1),1))]);
                elseif nmotion == 2
                    text(0,1,[num2str(round(mean(Session1.Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value2),1)),' +/- ',num2str(round(std(Session1.Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value2),1))]);
                end                   
                exportgraphics(img,[motion(nmotion).ifile,'_elevationPlaneL_PRE.png'],'BackgroundColor','none','Resolution',600);
                close all;
                img = figure('Position',[50 20 900 400],'Color','white');
                hold on;
                axis off;
                if nmotion == 1
                    text(0,1,[num2str(round(mean(Session2.Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value1),1)),' +/- ',num2str(round(std(Session2.Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value1),1))]);
                elseif nmotion == 2
                    text(0,1,[num2str(round(mean(Session2.Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value2),1)),' +/- ',num2str(round(std(Session2.Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value2),1))]);
                end                   
                exportgraphics(img,[motion(nmotion).ifile,'_elevationPlaneL_POST.png'],'BackgroundColor','none','Resolution',600);
                close all;
            end
    
            % MOTION PART i | Lower part, right and left mean scapular rhythm
            if imotion == 1 || imotion == 2  
                img = figure('Position',[50 20 900 400],'Color','white');
                hold on;
                axis off;
                if nmotion == 1
                    text(0,1,[num2str(round(mean(Session1.Report.Analytic(imotion).Kinematics.SHR(1).value1),1)),' +/- ',num2str(round(std(Session1.Report.Analytic(imotion).Kinematics.SHR(1).value1),1))]);
                elseif nmotion == 2
                    text(0,1,[num2str(round(mean(Session1.Report.Analytic(imotion).Kinematics.SHR(1).value2),1)),' +/- ',num2str(round(std(Session1.Report.Analytic(imotion).Kinematics.SHR(1).value2),1))]);
                end                
                exportgraphics(img,[motion(nmotion).ifile,'_rhythmR_PRE.png'],'BackgroundColor','none','Resolution',600);
                close all;
                img = figure('Position',[50 20 900 400],'Color','white');
                hold on;
                axis off;
                if nmotion == 1
                    text(0,1,[num2str(round(mean(Session2.Report.Analytic(imotion).Kinematics.SHR(1).value1),1)),' +/- ',num2str(round(std(Session2.Report.Analytic(imotion).Kinematics.SHR(1).value1),1))]);
                elseif nmotion == 2
                    text(0,1,[num2str(round(mean(Session2.Report.Analytic(imotion).Kinematics.SHR(1).value2),1)),' +/- ',num2str(round(std(Session2.Report.Analytic(imotion).Kinematics.SHR(1).value2),1))]);
                end                
                exportgraphics(img,[motion(nmotion).ifile,'_rhythmR_POST.png'],'BackgroundColor','none','Resolution',600);
                close all;
                img = figure('Position',[50 20 900 400],'Color','white');
                hold on;
                axis off;
                if nmotion == 1
                    text(0,1,[num2str(round(mean(Session1.Report.Analytic(imotion).Kinematics.SHR(2).value1),1)),' +/- ',num2str(round(std(Session1.Report.Analytic(imotion).Kinematics.SHR(2).value1),1))]);
                elseif nmotion == 2
                    text(0,1,[num2str(round(mean(Session1.Report.Analytic(imotion).Kinematics.SHR(2).value2),1)),' +/- ',num2str(round(std(Session1.Report.Analytic(imotion).Kinematics.SHR(2).value2),1))]);
                end                    
                exportgraphics(img,[motion(nmotion).ifile,'_rhythmL_PRE.png'],'BackgroundColor','none','Resolution',600);
                close all;
                img = figure('Position',[50 20 900 400],'Color','white');
                hold on;
                axis off;
                if nmotion == 1
                    text(0,1,[num2str(round(mean(Session2.Report.Analytic(imotion).Kinematics.SHR(2).value1),1)),' +/- ',num2str(round(std(Session2.Report.Analytic(imotion).Kinematics.SHR(2).value1),1))]);
                elseif nmotion == 2
                    text(0,1,[num2str(round(mean(Session2.Report.Analytic(imotion).Kinematics.SHR(2).value2),1)),' +/- ',num2str(round(std(Session2.Report.Analytic(imotion).Kinematics.SHR(2).value2),1))]);
                end                    
                exportgraphics(img,[motion(nmotion).ifile,'_rhythmL_POST.png'],'BackgroundColor','none','Resolution',600);
                close all;
            end
    
            % MOTION PART i | Lower part, right pain | PRE
            img = figure('Position',[50 20 900 400],'Color','white');
            hold on;
            axis off;
            axis equal;
            r0 = rectangle('Position',[0,0,1,1]); text(0.4,0.5,'0','FontSize',24);
            r1 = rectangle('Position',[1,0,1,1]); text(1.4,0.5,'1','FontSize',24);
            r2 = rectangle('Position',[2,0,1,1]); text(2.4,0.5,'2','FontSize',24);
            r3 = rectangle('Position',[3,0,1,1]); text(3.4,0.5,'3','FontSize',24);
            r4 = rectangle('Position',[4,0,1,1]); text(4.4,0.5,'4','FontSize',24);
            r5 = rectangle('Position',[5,0,1,1]); text(5.4,0.5,'5','FontSize',24);
            r6 = rectangle('Position',[6,0,1,1]); text(6.4,0.5,'6','FontSize',24);
            r7 = rectangle('Position',[7,0,1,1]); text(7.4,0.5,'7','FontSize',24);
            r8 = rectangle('Position',[8,0,1,1]); text(8.4,0.5,'8','FontSize',24);
            r9 = rectangle('Position',[9,0,1,1]); text(9.4,0.5,'9','FontSize',24);
            r10 = rectangle('Position',[10,0,1,1]); text(10.2,0.5,'10','FontSize',24);
            fcolor = [0.7 0.7 0.7];
            if fix(PainR_PRE) == 0
                set(r0,'FaceColor',fcolor);
            elseif fix(PainR_PRE) == 1
                set(r1,'FaceColor',fcolor);
            elseif fix(PainR_PRE) == 2
                set(r2,'FaceColor',fcolor);
            elseif fix(PainR_PRE) == 3
                set(r3,'FaceColor',fcolor);
            elseif fix(PainR_PRE) == 4
                set(r4,'FaceColor',fcolor);
            elseif fix(PainR_PRE) == 5
                set(r5,'FaceColor',fcolor);
            elseif fix(PainR_PRE) == 6
                set(r6,'FaceColor',fcolor);
            elseif fix(PainR_PRE) == 7
                set(r7,'FaceColor',fcolor);
            elseif fix(PainR_PRE) == 8
                set(r8,'FaceColor',fcolor);
            elseif fix(PainR_PRE) == 9
                set(r9,'FaceColor',fcolor);
            elseif fix(PainR_PRE) == 10
                set(r10,'FaceColor',fcolor);
            end
            exportgraphics(img,[motion(nmotion).ifile,'_painR_PRE.png'],'BackgroundColor','none','Resolution',600);
            close all;
    
            % MOTION PART i | Lower part, right pain | POST
            img = figure('Position',[50 20 900 400],'Color','white');
            hold on;
            axis off;
            axis equal;
            r0 = rectangle('Position',[0,0,1,1]); text(0.4,0.5,'0','FontSize',24);
            r1 = rectangle('Position',[1,0,1,1]); text(1.4,0.5,'1','FontSize',24);
            r2 = rectangle('Position',[2,0,1,1]); text(2.4,0.5,'2','FontSize',24);
            r3 = rectangle('Position',[3,0,1,1]); text(3.4,0.5,'3','FontSize',24);
            r4 = rectangle('Position',[4,0,1,1]); text(4.4,0.5,'4','FontSize',24);
            r5 = rectangle('Position',[5,0,1,1]); text(5.4,0.5,'5','FontSize',24);
            r6 = rectangle('Position',[6,0,1,1]); text(6.4,0.5,'6','FontSize',24);
            r7 = rectangle('Position',[7,0,1,1]); text(7.4,0.5,'7','FontSize',24);
            r8 = rectangle('Position',[8,0,1,1]); text(8.4,0.5,'8','FontSize',24);
            r9 = rectangle('Position',[9,0,1,1]); text(9.4,0.5,'9','FontSize',24);
            r10 = rectangle('Position',[10,0,1,1]); text(10.2,0.5,'10','FontSize',24);
            fcolor = [0.7 0.7 0.7];
            if fix(PainR_POST) == 0
                set(r0,'FaceColor',fcolor);
            elseif fix(PainR_POST) == 1
                set(r1,'FaceColor',fcolor);
            elseif fix(PainR_POST) == 2
                set(r2,'FaceColor',fcolor);
            elseif fix(PainR_POST) == 3
                set(r3,'FaceColor',fcolor);
            elseif fix(PainR_POST) == 4
                set(r4,'FaceColor',fcolor);
            elseif fix(PainR_POST) == 5
                set(r5,'FaceColor',fcolor);
            elseif fix(PainR_POST) == 6
                set(r6,'FaceColor',fcolor);
            elseif fix(PainR_POST) == 7
                set(r7,'FaceColor',fcolor);
            elseif fix(PainR_POST) == 8
                set(r8,'FaceColor',fcolor);
            elseif fix(PainR_POST) == 9
                set(r9,'FaceColor',fcolor);
            elseif fix(PainR_POST) == 10
                set(r10,'FaceColor',fcolor);
            end
            exportgraphics(img,[motion(nmotion).ifile,'_painR_POST.png'],'BackgroundColor','none','Resolution',600);
            close all;
    
            % MOTION PART i | Lower part, left pain | PRE
            img = figure('Position',[50 20 900 400],'Color','white');
            hold on;
            axis off;
            axis equal;
            r0 = rectangle('Position',[0,0,1,1]); text(0.4,0.5,'0','FontSize',24);
            r1 = rectangle('Position',[1,0,1,1]); text(1.4,0.5,'1','FontSize',24);
            r2 = rectangle('Position',[2,0,1,1]); text(2.4,0.5,'2','FontSize',24);
            r3 = rectangle('Position',[3,0,1,1]); text(3.4,0.5,'3','FontSize',24);
            r4 = rectangle('Position',[4,0,1,1]); text(4.4,0.5,'4','FontSize',24);
            r5 = rectangle('Position',[5,0,1,1]); text(5.4,0.5,'5','FontSize',24);
            r6 = rectangle('Position',[6,0,1,1]); text(6.4,0.5,'6','FontSize',24);
            r7 = rectangle('Position',[7,0,1,1]); text(7.4,0.5,'7','FontSize',24);
            r8 = rectangle('Position',[8,0,1,1]); text(8.4,0.5,'8','FontSize',24);
            r9 = rectangle('Position',[9,0,1,1]); text(9.4,0.5,'9','FontSize',24);
            r10 = rectangle('Position',[10,0,1,1]); text(10.2,0.5,'10','FontSize',24);
            fcolor = [0.7 0.7 0.7];
            if fix(PainL_PRE) == 0
                set(r0,'FaceColor',fcolor);
            elseif fix(PainL_PRE) == 1
                set(r1,'FaceColor',fcolor);
            elseif fix(PainL_PRE) == 2
                set(r2,'FaceColor',fcolor);
            elseif fix(PainL_PRE) == 3
                set(r3,'FaceColor',fcolor);
            elseif fix(PainL_PRE) == 4
                set(r4,'FaceColor',fcolor);
            elseif fix(PainL_PRE) == 5
                set(r5,'FaceColor',fcolor);
            elseif fix(PainL_PRE) == 6
                set(r6,'FaceColor',fcolor);
            elseif fix(PainL_PRE) == 7
                set(r7,'FaceColor',fcolor);
            elseif fix(PainL_PRE) == 8
                set(r8,'FaceColor',fcolor);
            elseif fix(PainL_PRE) == 9
                set(r9,'FaceColor',fcolor);
            elseif fix(PainL_PRE) == 10
                set(r10,'FaceColor',fcolor);
            end
            exportgraphics(img,[motion(nmotion).ifile,'_painL_PRE.png'],'BackgroundColor','none','Resolution',600);
            close all;
    
            % MOTION PART i | Lower part, left pain | POST
            img = figure('Position',[50 20 900 400],'Color','white');
            hold on;
            axis off;
            axis equal;
            r0 = rectangle('Position',[0,0,1,1]); text(0.4,0.5,'0','FontSize',24);
            r1 = rectangle('Position',[1,0,1,1]); text(1.4,0.5,'1','FontSize',24);
            r2 = rectangle('Position',[2,0,1,1]); text(2.4,0.5,'2','FontSize',24);
            r3 = rectangle('Position',[3,0,1,1]); text(3.4,0.5,'3','FontSize',24);
            r4 = rectangle('Position',[4,0,1,1]); text(4.4,0.5,'4','FontSize',24);
            r5 = rectangle('Position',[5,0,1,1]); text(5.4,0.5,'5','FontSize',24);
            r6 = rectangle('Position',[6,0,1,1]); text(6.4,0.5,'6','FontSize',24);
            r7 = rectangle('Position',[7,0,1,1]); text(7.4,0.5,'7','FontSize',24);
            r8 = rectangle('Position',[8,0,1,1]); text(8.4,0.5,'8','FontSize',24);
            r9 = rectangle('Position',[9,0,1,1]); text(9.4,0.5,'9','FontSize',24);
            r10 = rectangle('Position',[10,0,1,1]); text(10.2,0.5,'10','FontSize',24);
            fcolor = [0.7 0.7 0.7];
            if fix(PainL_POST) == 0
                set(r0,'FaceColor',fcolor);
            elseif fix(PainL_POST) == 1
                set(r1,'FaceColor',fcolor);
            elseif fix(PainL_POST) == 2
                set(r2,'FaceColor',fcolor);
            elseif fix(PainL_POST) == 3
                set(r3,'FaceColor',fcolor);
            elseif fix(PainL_POST) == 4
                set(r4,'FaceColor',fcolor);
            elseif fix(PainL_POST) == 5
                set(r5,'FaceColor',fcolor);
            elseif fix(PainL_POST) == 6
                set(r6,'FaceColor',fcolor);
            elseif fix(PainL_POST) == 7
                set(r7,'FaceColor',fcolor);
            elseif fix(PainL_POST) == 8
                set(r8,'FaceColor',fcolor);
            elseif fix(PainL_POST) == 9
                set(r9,'FaceColor',fcolor);
            elseif fix(PainL_POST) == 10
                set(r10,'FaceColor',fcolor);
            end
            exportgraphics(img,[motion(nmotion).ifile,'_painL_POST.png'],'BackgroundColor','none','Resolution',600);
            close all;
        end

    end

end