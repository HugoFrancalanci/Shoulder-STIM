function  acq=Correct_FP_C3D_Mokka(acq)
%CREATEC3DFILE Summary of this function goes here
%   Detailed explanation goes here
%Update S. ARMAND 05.11.2020
%Correct FP type 5 for Mokka.
%Correction for btkGetForcePlatformWrenches that was not working

%acq=btkReadAcquisition('Gait 4o.c3d');

%% Force PLATE
load('CalMatFP1.mat');
load('CalMatFP2.mat');

%FP1.center=[-251 249 0.0163389];
%FP2.center=[249 249 0.0202672];
L2N=4.44822162825;
P2M=25.4 ;
[forceplates, forceplatesInfo] = btkGetForcePlatforms(acq);
METADATA = btkGetMetaData(acq);
Analog=btkGetAnalogs(acq);
F=fieldnames(Analog);

if length(forceplates)==2 % case with 2 PF
    Cal(1).Mat=CalMatFP1;
    Cal(2).Mat=CalMatFP2;
    forceplates(1).type=5; %ForcePlate AMTI Accugait 1 - owerwrite in case of multiple runs of the programs
    forceplates(2).type=5; %ForcePlate AMTI Accugait 2- owerwrite in case of multiple runs of the programs
end

if length(forceplates)==3  % case with 3 PF
    Cal(1).Mat=CalMatFP1;
    Cal(3).Mat=CalMatFP2;
    forceplates(1).type=5; %ForcePlate AMTI Accugait 1- owerwrite in case of multiple runs of the programs
    forceplates(3).type=5; %ForcePlate AMTI Accugait 2- owerwrite in case of multiple runs of the programs
    forceplates(2).type=2; %ForcePlate AMTI Accugait OPTIMA- owerwrite in case of multiple runs of the programs
end
Channel_name_FP={'Fx';'Fy';'Fz';'Mx';'My';'Mz'};
Channel_OPTIMA_matlab={'Amti_Optima_ACG_O_3028_Fx';'Amti_Optima_ACG_O_3028_Fy';'Amti_Optima_ACG_O_3028_Fz';'Amti_Optima_ACG_O_3028_Mx';'Amti_Optima_ACG_O_3028_My';'Amti_Optima_ACG_O_3028_Mz'};
Channel_OPTIMA_BTK={'Amti Optima ACG-O 3028_Fx';'Amti Optima ACG-O 3028_Fy';'Amti Optima ACG-O 3028_Fz';'Amti Optima ACG-O 3028_Mx';'Amti Optima ACG-O 3028_My';'Amti Optima ACG-O 3028_Mz'};
if isempty(F)==0
    if isfield(METADATA.children,'MANUFACTURER')==1
        if isfield(METADATA.children.MANUFACTURER.children,'COMPANY')==1
            if strfind(char(METADATA.children.MANUFACTURER.children.COMPANY.info.values),'Qualisys')==1
                if isfield(METADATA.children,'FORCE_PLATFORM')==1
                    %fpw = btkGetForcePlatformWrenches(acq);
                    btkRemoveMetaData(acq, 'FORCE_PLATFORM');
                    for p=1:length(forceplates) % remove analog channel linked to forceplates
                        for c=1:length(Channel_name_FP)
                            label=[Channel_name_FP{c} num2str(p)];
                            if isfield(Analog,label);
                                [analogs analogsInfo] = btkRemoveAnalog(acq, label);
                            end
                        end
                    end
                    for c=1:length(Channel_OPTIMA_matlab) % remove analog channel linked to OPTIMA forceplate because already in Fx2....
                        label=Channel_OPTIMA_matlab{c};
                        if isfield(Analog,label);
                            [analogs analogsInfo] = btkRemoveAnalog(acq, Channel_OPTIMA_BTK{c});
                        end
                    end
                    
                    for p=1:length(forceplates)
                        passe=0;R=[];F=[]; Force=[];Moment=[];corners=[];
                        if forceplates(p).type==5 % AMTI Accugait
                            if p==1
                                if isfield(Analog,'Pin_1')
                                    passe=1;
                                    for i=1:8
                                        R(i,:)=btkGetAnalog(acq,(['Pin ' num2str(i)]));
                                    end
                                end
                            end
                            if p==2 | p==3 % for forceplate 2 (old config), for  forceplate 3 (new config: 3 forceplates)
                                if isfield(Analog,'Pin_9')
                                    passe=1;
                                    for i=1:8
                                        R(i,:)=btkGetAnalog(acq,(['Pin ' num2str(i+8)]));
                                    end
                                end
                            end
                        end
                        if passe ==1
                            F=-Cal(p).Mat*(R)*L2N;%compute Force and moment
                            F=F';
                            F=[F(:,1:3) F(:,4:6).*P2M];% transform moment in mm (pouce before)
                            Force=-F(:,1:3);
                            Force(:,2)=F(:,2);
                            Moment=-F(:,4:6);
                            Moment(:,2)=F(:,5);
                            btkAppendForcePlatformType2(acq, Force, Moment, forceplates(p).corners', forceplates(p).origin, 0);
                            FP(p).F=Force;
                            FP(p).M=Moment;
                        end
                        if forceplates(p).type==2 % AMTI OPTIMNA
                            % get Force from analog for PF2
                            FP2.F = NaN(size(FP(1).F));
                            FP2.M = NaN(size(FP(1).M));
                            if isfield(Analog,Channel_OPTIMA_matlab{1})
                                FP2.F(:,1)=-Analog.(Channel_OPTIMA_matlab{1});
                                FP2.F(:,2)=Analog.(Channel_OPTIMA_matlab{2});
                                FP2.F(:,3)=-Analog.(Channel_OPTIMA_matlab{3});
                                
                                FP2.M(:,1)=-Analog.(Channel_OPTIMA_matlab{4});
                                FP2.M(:,2)=Analog.(Channel_OPTIMA_matlab{5});
                                FP2.M(:,3)=-Analog.(Channel_OPTIMA_matlab{6});
                            else
                                if isfield(Analog,'Fx2')
                                    label=[Channel_name_FP{c} num2str(p)];
                                    FP2.F(:,1)=-Analog.Fx2;
                                    FP2.F(:,2)=Analog.Fy2;
                                    FP2.F(:,3)=-Analog.Fz2;
                                    
                                    FP2.M(:,1)=-Analog.Mx2;
                                    FP2.M(:,2)=Analog.My2;
                                    FP2.M(:,3)=-Analog.Mz2;
                                end
                            end
                            btkAppendForcePlatformType2(acq, FP2.F, FP2.M, forceplates(p).corners', forceplates(p).origin, 0);
                            %FP(p).F=fpw(p).F;
                            %FP(p).M=fpw(p).M;
                        end
                    end
                else disp(['No force plate ' path C3D_file]);
                end
            end
        end
    end
else
    if isfield(METADATA.children,'FORCE_PLATFORM')==1
        btkRemoveMetaData(acq, 'FORCE_PLATFORM');
    end
end
% btkWriteAcquisition(acq,('test.c3d'));
%close all

% Check with original QTM data
% A=load('Gait 4.mat');
% for p=2%1:length(forceplates)
%     for i=1:3
%     figure;plot(FP(p).F(:,i));hold on;plot(A.Gait_4.Force(p).Force(i,:),'--r')
%     %figure;plot(FP(p).M(:,i)./1000);hold on;plot(A.Gait_4.Force(p).Moment(i,:),'--r')
%     end
% end

