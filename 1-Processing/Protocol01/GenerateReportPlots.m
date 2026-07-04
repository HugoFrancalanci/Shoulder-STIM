% Author     :   F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   June 2022
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

function [] = GenerateReportPlots(Folder,Session,Report,Normal)

% -------------------------------------------------------------------------
% Amplitude and EMG /Analytic motions
% -------------------------------------------------------------------------
for imotion = 1:4

    clear motion;

    if imotion > size(Report.Analytic,2)
        break
    else

        % MOTION SPECIFICITIES
        % -----------------------------------------------------------------
        if imotion == 1
            ieuler = 3;
            motion(1).ititle = 'Elévation sagittale (montée | concentrique)';
            motion(2).ititle = 'Elévation sagittale (descente | excentrique)';
            motion(1).ifile  = 'Analytic1_part1';
            motion(2).ifile  = 'Analytic1_part2';
            if ~isnan(Session.Pain.Rvalue)
                PainR            = Session.Pain.Rvalue(4);
            else
                PainR            = nan;
            end
            if ~isnan(Session.Pain.Lvalue)
                PainL            = Session.Pain.Lvalue(4);
            else
                PainL            = nan;
            end
        elseif imotion == 2
            ieuler = 1;
            motion(1).ititle = 'Elévation coronale (montée | concentrique)';
            motion(2).ititle = 'Elévation coronale (descente | excentrique)';
            motion(1).ifile  = 'Analytic2_part1';
            motion(2).ifile  = 'Analytic2_part2';
            if ~isnan(Session.Pain.Rvalue)
                PainR            = Session.Pain.Rvalue(5);
            else
                PainR            = nan;
            end
            if ~isnan(Session.Pain.Lvalue)
                PainL            = Session.Pain.Lvalue(5);
            else
                PainL            = nan;
            end
        elseif imotion == 3
            ieuler = 2;
            motion(1).ititle = 'Rotation externe';
            motion(1).ifile  = 'Analytic3_part1';
            if ~isnan(Session.Pain.Rvalue)
                PainR            = Session.Pain.Rvalue(6);
            else
                PainR            = nan;
            end
            if ~isnan(Session.Pain.Lvalue)
                PainL            = Session.Pain.Lvalue(6);
            else
                PainL            = nan;
            end
        elseif imotion == 4
            ieuler = 2;
            motion(1).ititle = 'Rotation interne';
            motion(1).ifile  = 'Analytic4_part1';
            if ~isnan(Session.Pain.Rvalue)
                PainR            = Session.Pain.Rvalue(7);
            else
                PainR            = nan;
            end
            if ~isnan(Session.Pain.Lvalue)
                PainL            = Session.Pain.Lvalue(7);
            else
                PainL            = nan;
            end
        end

        for nmotion = 1:size(motion,2)

            clearvars -except Folder Session Report Normal imotion nmotion ieuler PainR PainL motion;

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
%             emgLabels = {'    < TRAP. SUP.','    < TRAP. MED.','    < TRAP. INF.','    < INFRA. EP.','    < GD. DORSAL.','    < NA','    < GD. DENTELE', ...
%                          '    TRAP. SUP. >','    TRAP. MED. >','    TRAP. INF. >','    INFRA. EP. >','    GD. DORSAL. >','    NA >','    GD. DENTELE >'};            
            emgLabels = {'    < DELT. ANT.','    < DELT. MED.','    < DELT. POS.','    < TRAP. SUP.','    < TRAP. MED.','    < TRAP. INF.','    < DENTELE ANT.', ...
                         '    DELT. ANT. >','    DELT. MED. >','    DELT. POS. >','    TRAP. SUP. >','    TRAP. MED. >','    TRAP. INF. >','    DENTELE ANT. >'};
            for iemg = 1:7
                if ~isempty(Report.Analytic(imotion).Emg(iemg).onset)
                    text(-0.4,2*iemg,emgLabels{iemg},'HorizontalAlignment','center','FontSize',fontsize);
                else
                    text(-0.4,2*iemg,emgLabels{iemg},'HorizontalAlignment','center','FontSize',fontsize,'Color',[0.8 0.8 0.8]);
                end
            end
            text(-0.4,16,'    < \bf{ANGLE}','HorizontalAlignment','center','FontSize',fontsize);
            for iemg = 8:14
                if ~isempty(Report.Analytic(imotion).Emg(iemg).onset)
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
        
            % NORMAL ANGLE DATA
            r = 15.39;
            x = r.*cosd(linspace(Normal.Analytic(imotion).mean-Normal.Analytic(imotion).std-90,Normal.Analytic(imotion).mean+Normal.Analytic(imotion).std-90,1000))+xshift;
            y = r.*sind(linspace(Normal.Analytic(imotion).mean-Normal.Analytic(imotion).std-90,Normal.Analytic(imotion).mean+Normal.Analytic(imotion).std-90,1000));
            plot(x,y,'Color',[0 0 0],'Linewidth',6);
            x = -r.*cosd(linspace(Normal.Analytic(imotion).mean-Normal.Analytic(imotion).std-90,Normal.Analytic(imotion).mean+Normal.Analytic(imotion).std-90,1000))-xshift;
            y = r.*sind(linspace(Normal.Analytic(imotion).mean-Normal.Analytic(imotion).std-90,Normal.Analytic(imotion).mean+Normal.Analytic(imotion).std-90,1000));
            plot(x,y,'Color',[0 0 0],'Linewidth',6); 
            
            % LEFT
            thetaRmax = [];
            thetaRmin = [];
            for icycle = 1:size(Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,:),3)
                % AMPLITUDE
                if imotion == 3
                    [~,imax] = max(-(Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle)));
                    if nmotion == 1
                        range = 1:imax;
                    else
                        range = imax:101;
                    end  
                    angleL   = -(Report.Analytic(imotion).Kinematics.Joint(6).Euler(range,ieuler,icycle));
                elseif  imotion == 1 || imotion == 2
                    [~,imax] = max(abs(Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle)));
                    if nmotion == 1
                        range = 1:imax;
                    else
                        range = imax:101;
                    end  
                    angleL   = abs(Report.Analytic(imotion).Kinematics.Joint(6).Euler(range,ieuler,icycle));
                else
                    [~,imax] = max((Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle)));
                    if nmotion == 1
                        range = 1:imax;
                    else
                        range = imax:101;
                    end  
                    angleL   = (Report.Analytic(imotion).Kinematics.Joint(6).Euler(range,ieuler,icycle));
                end      
                for iframe = 1:size(angleL,1) % We reject negative value = the task was defined not performed in this case
                    if angleL(iframe) < 0
                        angleL(iframe) = 0;
                    end
                end
                thetaL = linspace(deg2rad(-90+round(min(angleL))),deg2rad(-90+round(max(angleL))),size(angleL,1));
                thetaLmax(icycle) = deg2rad(-90+max(angleL));
                thetaLmin(icycle) = deg2rad(-90+min(angleL));
                r = 16;
                x = r.*cos(thetaL)+xshift;
                y = r.*sin(thetaL);
                plot(x,y,'Color',[1 0 0 0.2],'Linewidth',10);
                clear angleR thetaL r x y;
        
                % SHR
                if imotion == 1 || imotion == 2   
                    r      = 17; % Full radius of the circular plot 
                    maxshr = 5; % Maximal reported SHR value
                    if nmotion == 1
                        angleL = Report.Analytic(imotion).Kinematics.SHR(2).theta_HT1(:,:,icycle); % Elevation
                        SHRL   = Report.Analytic(imotion).Kinematics.SHR(2).SHR_curve1(:,:,icycle);
                    else
                        angleL = Report.Analytic(imotion).Kinematics.SHR(2).theta_HT2(:,:,icycle); % Return
                        SHRL   = Report.Analytic(imotion).Kinematics.SHR(2).SHR_curve2(:,:,icycle);
                    end
                    thetaL = deg2rad(-90+angleL);
                    for t = 1:size(SHRL,1)
                        x(t) = r/maxshr*SHRL(t).*cos(thetaL(t))+xshift;
                        y(t) = r/maxshr*SHRL(t).*sin(thetaL(t));
                        if SHRL(t) < maxshr
                            plot(x(t),y(t),'Color',[1 0 0],'Linestyle','none','Marker','.','Markersize',11);
                        end
                    end
                    clear angleL SHRL thetaL r maxshr x y;
                end
            
                % EMG
                for iemg = 1:7
                    r = iemg*2;
                    if size(Report.Analytic(imotion).Emg(iemg+7).onset,1) == 101 % +7 for left sensors
                        if size(Report.Analytic(imotion).Emg(iemg+7).onset,1) > 1
                            value = Report.Analytic(imotion).Emg(iemg+7).onset(:,1,icycle); % +7 for left sensors
                        else
                            value = [];
                        end
                        if imotion == 3
                            angleEMG = -(Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle));
                        else
                            angleEMG = abs(Report.Analytic(imotion).Kinematics.Joint(6).Euler(:,ieuler,icycle));
                        end
                        for iframe = 1:size(angleEMG,1) % We reject negative value = the task was defined "not performed" in this case
                            if angleEMG(iframe) < 0
                                angleEMG(iframe) = 0;
                                value(iframe)    = 0;
                            end
                        end
                        thetaEMG = [];
                        start = 0;
                        stop = 0;
                        for ivalue = range                            
                            if start == 0
                                if ivalue <= length(value)
                                    if value(ivalue) > 0.5
                                        start = ivalue;
                                    end
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
                                plot(x,y,'Color',[0 0 0 0.2],'Linewidth',10);
                                clear x y;
                            end
                        end
                    end
                end
            end
            clear range angleL thetaL r x y;
            r = 18;
            line([1*cos(max(thetaLmax)) r*cos(max(thetaLmax))]+xshift,[1*sin(max(thetaLmax)) r*sin(max(thetaLmax))],'Linestyle','-','Linewidth',1.5,'Color','red');
            line([1*cos(min(thetaLmin)) r*cos(min(thetaLmin))]+xshift,[1*sin(min(thetaLmin)) r*sin(min(thetaLmin))],'Linestyle','-','Linewidth',1.5,'Color','red');
            r = 19;
            text(r*cos(max(thetaLmax))+xshift,r*sin(max(thetaLmax)),[num2str(fix(rad2deg(max(thetaLmax))+90)),'°'],'HorizontalAlignment','center','Color','red','FontSize',14);
            text(r*cos(min(thetaLmin))+xshift,r*sin(min(thetaLmin)),[num2str(fix(rad2deg(min(thetaLmin))+90)),'°'],'HorizontalAlignment','center','Color','red','FontSize',14);     
            
            % SHR lines
            if imotion == 1 || imotion == 2
                x = [3*(Normal.Analytic(imotion).SHR.mean-Normal.Analytic(imotion).SHR.std).*cos(linspace(min(thetaLmin),max(thetaLmax),1000))+xshift ...
                     3*(Normal.Analytic(imotion).SHR.mean+Normal.Analytic(imotion).SHR.std).*cos(linspace(max(thetaLmax),min(thetaLmin),1000))+xshift];
                y = [3*(Normal.Analytic(imotion).SHR.mean-Normal.Analytic(imotion).SHR.std).*sin(linspace(min(thetaLmin),max(thetaLmax),1000)) ...
                     3*(Normal.Analytic(imotion).SHR.mean+Normal.Analytic(imotion).SHR.std).*sin(linspace(max(thetaLmax),min(thetaLmin),1000))];
                fill(x,y,'red','LineStyle','none','FaceAlpha',0.15);
                clear x y;
            end
    
            % RIGHT
            thetaRmax = [];
            thetaRmin = [];
            for icycle = 1:size(Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,:),3)
                % AMPLITUDE
                if imotion == 3
                    [~,imax] = max(-(Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle)));
                    if nmotion == 1
                        range = 1:imax;
                    else
                        range = imax:101;
                    end  
                    angleR   = -(Report.Analytic(imotion).Kinematics.Joint(1).Euler(range,ieuler,icycle));
                elseif imotion == 1 || imotion == 2
                    [~,imax] = max(abs(Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle)));
                    if nmotion == 1
                        range = 1:imax;
                    else
                        range = imax:101;
                    end  
                    angleR   = abs(Report.Analytic(imotion).Kinematics.Joint(1).Euler(range,ieuler,icycle));
                else
                    [~,imax] = max((Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle)));
                    if nmotion == 1
                        range = 1:imax;
                    else
                        range = imax:101;
                    end  
                    angleR   = (Report.Analytic(imotion).Kinematics.Joint(1).Euler(range,ieuler,icycle));
                end         
                for iframe = 1:size(angleR,1) % We reject negative value = the task was defined not performed in this case
                    if angleR(iframe) < 0
                        angleR(iframe) = 0;
                    end
                end      
                thetaR = linspace(deg2rad(-90-round(min(angleR))),deg2rad(-90-round(max(angleR))),size(angleR,1));        
                thetaRmax(icycle) = deg2rad(-90-min(angleR));
                thetaRmin(icycle) = deg2rad(-90-max(angleR));
                r = 16;
                x = r.*cos(thetaR)-xshift;
                y = r.*sin(thetaR);
                plot(x,y,'Color',[0 0 1 0.2],'Linewidth',10);
                clear angleR thetaR r x y;
        
                % SHR    
                if imotion == 1 || imotion == 2
                    r      = 17; % Full radius of the circular plot 
                    maxshr = 5; % Maximal reported SHR value
                    if nmotion == 1
                        angleR = Report.Analytic(imotion).Kinematics.SHR(1).theta_HT1(:,:,icycle); % Elevation
                        SHRR   = Report.Analytic(imotion).Kinematics.SHR(1).SHR_curve1(:,:,icycle);
                    else
                        angleR = Report.Analytic(imotion).Kinematics.SHR(1).theta_HT2(:,:,icycle); % Return
                        SHRR   = Report.Analytic(imotion).Kinematics.SHR(1).SHR_curve2(:,:,icycle);
                    end
                    thetaR = deg2rad(-90-angleR);
                    for t = 1:size(SHRR,1)
                        x(t) = r/maxshr*SHRR(t).*cos(thetaR(t))-xshift;
                        y(t) = r/maxshr*SHRR(t).*sin(thetaR(t));
                        if SHRR(t) < maxshr
                            plot(x(t),y(t),'Color',[0 0 1],'Linestyle','none','Marker','.','Markersize',11);
                        end
                    end
                    clear angleR SHRR thetaR r maxshr x y;
                end       
            
                % EMG
                for iemg = 1:7
                    r = iemg*2;
                    if size(Report.Analytic(imotion).Emg(iemg+7).onset,1) == 101
                        if size(Report.Analytic(imotion).Emg(iemg).onset,1) > 1
                            value = Report.Analytic(imotion).Emg(iemg).onset(:,1,icycle);
                        else
                            value = [];
                        end
                        if imotion == 3
                            angleEMG = -(Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle));
                        else
                            angleEMG = abs(Report.Analytic(imotion).Kinematics.Joint(1).Euler(:,ieuler,icycle));
                        end
                        for iframe = 1:size(angleEMG,1) % We reject negative value = the task was defined "not performed in this case
                            if angleEMG(iframe) < 0
                                angleEMG(iframe) = 0;
                                value(iframe)    = 0;
                            end
                        end
                        thetaEMG = [];
                        start = 0;
                        stop = 0;
                        for ivalue = range                       
                            if start == 0
                                if ivalue <= length(value)
                                    if value(ivalue) > 0.5
                                        start = ivalue;
                                    end
                                end
                            end
                            if start > 0
                                if value(ivalue) < 0.5 || ivalue == range(end)
                                    stop = ivalue;
                                end
                            end
                            if start > 0 && stop > 0
                                thetaEMG = linspace(deg2rad(-90-abs(min(Report.Analytic(imotion).Kinematics.Joint(1).Euler(start:stop,ieuler,icycle)))), ...
                                                    deg2rad(-90-abs(max(Report.Analytic(imotion).Kinematics.Joint(1).Euler(start:stop,ieuler,icycle)))), ...
                                                    size(angleEMG,1));
                                start = 0;
                                stop = 0;
                                x = r.*cos(thetaEMG)-xshift;
                                y = r.*sin(thetaEMG);
                                plot(x,y,'Color',[0 0 0 0.2],'Linewidth',10);
                                clear x y;
                            end
                        end
                    end
                end
            end
            clear range angleR thetaR r x y;
            r = 18;
            line([1*cos(max(thetaRmax)) r*cos(max(thetaRmax))]-xshift,[1*sin(max(thetaRmax)) r*sin(max(thetaRmax))],'Linestyle','-','Linewidth',1.5,'Color','blue');
            line([1*cos(min(thetaRmin)) r*cos(min(thetaRmin))]-xshift,[1*sin(min(thetaRmin)) r*sin(min(thetaRmin))],'Linestyle','-','Linewidth',1.5,'Color','blue');
            r = 19;
            text(r*cos(max(thetaRmax))-xshift,r*sin(max(thetaRmax)),[num2str(-fix(rad2deg(max(thetaRmax))+90)),'°'],'HorizontalAlignment','center','Color','blue','FontSize',14);
            text(r*cos(min(thetaRmin))-xshift,r*sin(min(thetaRmin)),[num2str(-fix(rad2deg(min(thetaRmin))+90)),'°'],'HorizontalAlignment','center','Color','blue','FontSize',14);
            
            % SHR lines
            if imotion == 1 || imotion == 2
                x = [3*(Normal.Analytic(imotion).SHR.mean-Normal.Analytic(imotion).SHR.std).*cos(linspace(min(thetaRmin),max(thetaRmax),1000))-xshift ...
                     3*(Normal.Analytic(imotion).SHR.mean+Normal.Analytic(imotion).SHR.std).*cos(linspace(max(thetaRmax),min(thetaRmin),1000))-xshift];
                y = [3*(Normal.Analytic(imotion).SHR.mean-Normal.Analytic(imotion).SHR.std).*sin(linspace(min(thetaRmin),max(thetaRmax),1000)) ...
                     3*(Normal.Analytic(imotion).SHR.mean+Normal.Analytic(imotion).SHR.std).*sin(linspace(max(thetaRmax),min(thetaRmin),1000))];
                fill(x,y,'blue','LineStyle','none','FaceAlpha',0.15);
                clear x y;
            end
        
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
                    angle = deg2rad([0 mean(Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value1)]);
                elseif nmotion == 2
                    angle = deg2rad([0 mean(Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value2)]);
                end
                pimg = polarplot(ax,angle,[0 1],'Color','black','LineStyle','--','LineWidth',2);
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
                    angle = deg2rad([0 -mean(Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value1)]);
                elseif nmotion == 2
                    angle = deg2rad([0 -mean(Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value2)]);
                end
                pimg = polarplot(ax,angle,[0 1],'Color','black','LineStyle','--','LineWidth',2);
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
                    text(0,1,[num2str(round(mean(Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value1),1)),' +/- ',num2str(round(std(Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value1),1))]);
                elseif nmotion == 2
                    text(0,1,[num2str(round(mean(Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value2),1)),' +/- ',num2str(round(std(Report.Analytic(imotion).Kinematics.Joint(1).ElevationPlane.value2),1))]);
                end                
                exportgraphics(img,[motion(nmotion).ifile,'_elevationPlaneR.png'],'BackgroundColor','none','Resolution',600);
                close all;
                img = figure('Position',[50 20 900 400],'Color','white');
                hold on;
                axis off;
                if nmotion == 1
                    text(0,1,[num2str(round(mean(Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value1),1)),' +/- ',num2str(round(std(Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value1),1))]);
                elseif nmotion == 2
                    text(0,1,[num2str(round(mean(Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value2),1)),' +/- ',num2str(round(std(Report.Analytic(imotion).Kinematics.Joint(6).ElevationPlane.value2),1))]);
                end                   
                exportgraphics(img,[motion(nmotion).ifile,'_elevationPlaneL.png'],'BackgroundColor','none','Resolution',600);
                close all;
            end
    
            % MOTION PART i | Lower part, right and left mean scapular rhythm
            if imotion == 1 || imotion == 2  
                img = figure('Position',[50 20 900 400],'Color','white');
                hold on;
                axis off;
                if nmotion == 1
                    text(0,1,[num2str(round(mean(Report.Analytic(imotion).Kinematics.SHR(1).SHR_mean1,'omitnan'),1)),' +/- ',num2str(round(std(Report.Analytic(imotion).Kinematics.SHR(1).SHR_mean1),1))]);
                elseif nmotion == 2
                    text(0,1,[num2str(round(mean(Report.Analytic(imotion).Kinematics.SHR(1).SHR_mean2,'omitnan'),1)),' +/- ',num2str(round(std(Report.Analytic(imotion).Kinematics.SHR(1).SHR_mean2),1))]);
                end                
                exportgraphics(img,[motion(nmotion).ifile,'_rhythmR.png'],'BackgroundColor','none','Resolution',600);
                close all;
                img = figure('Position',[50 20 900 400],'Color','white');
                hold on;
                axis off;
                if nmotion == 1
                    text(0,1,[num2str(round(mean(Report.Analytic(imotion).Kinematics.SHR(2).SHR_mean1,'omitnan'),1)),' +/- ',num2str(round(std(Report.Analytic(imotion).Kinematics.SHR(2).SHR_mean1),1))]);
                elseif nmotion == 2
                    text(0,1,[num2str(round(mean(Report.Analytic(imotion).Kinematics.SHR(2).SHR_mean2,'omitnan'),1)),' +/- ',num2str(round(std(Report.Analytic(imotion).Kinematics.SHR(2).SHR_mean2),1))]);
                end                    
                exportgraphics(img,[motion(nmotion).ifile,'_rhythmL.png'],'BackgroundColor','none','Resolution',600);
                close all;
            end
    
            % MOTION PART i | Lower part, right pain
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
            if ~isnan(PainR)
                if fix(PainR) == 0
                    set(r0,'FaceColor',fcolor);
                elseif fix(PainR) == 1
                    set(r1,'FaceColor',fcolor);
                elseif fix(PainR) == 2
                    set(r2,'FaceColor',fcolor);
                elseif fix(PainR) == 3
                    set(r3,'FaceColor',fcolor);
                elseif fix(PainR) == 4
                    set(r4,'FaceColor',fcolor);
                elseif fix(PainR) == 5
                    set(r5,'FaceColor',fcolor);
                elseif fix(PainR) == 6
                    set(r6,'FaceColor',fcolor);
                elseif fix(PainR) == 7
                    set(r7,'FaceColor',fcolor);
                elseif fix(PainR) == 8
                    set(r8,'FaceColor',fcolor);
                elseif fix(PainR) == 9
                    set(r9,'FaceColor',fcolor);
                elseif fix(PainR) == 10
                    set(r10,'FaceColor',fcolor);
                end
            end
            exportgraphics(img,[motion(nmotion).ifile,'_painR.png'],'BackgroundColor','none','Resolution',600);
            close all;
    
            % MOTION PART i | Lower part, left pain
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
            if ~isnan(PainL)
                if fix(PainL) == 0
                    set(r0,'FaceColor',fcolor);
                elseif fix(PainL) == 1
                    set(r1,'FaceColor',fcolor);
                elseif fix(PainL) == 2
                    set(r2,'FaceColor',fcolor);
                elseif fix(PainL) == 3
                    set(r3,'FaceColor',fcolor);
                elseif fix(PainL) == 4
                    set(r4,'FaceColor',fcolor);
                elseif fix(PainL) == 5
                    set(r5,'FaceColor',fcolor);
                elseif fix(PainL) == 6
                    set(r6,'FaceColor',fcolor);
                elseif fix(PainL) == 7
                    set(r7,'FaceColor',fcolor);
                elseif fix(PainL) == 8
                    set(r8,'FaceColor',fcolor);
                elseif fix(PainL) == 9
                    set(r9,'FaceColor',fcolor);
                elseif fix(PainL) == 10
                    set(r10,'FaceColor',fcolor);
                end
            end
            exportgraphics(img,[motion(nmotion).ifile,'_painL.png'],'BackgroundColor','none','Resolution',600);
            close all;
        end

    end

end