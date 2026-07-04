% Author       : F. Moissenet
%                Kinesiology Laboratory (K-LAB)
%                University of Geneva
%                https://www.unige.ch/medecine/kinesiology
% License      : Creative Commons Attribution-NonCommercial 4.0 International License 
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code  : To be defined
% Reference    : To be defined
% Date         : February 2023
% -------------------------------------------------------------------------
% Description  : Video files preprocessing: 1) compress QTM videos, 2)
%                compress with higher image quality videos for analysis
% -------------------------------------------------------------------------
% Dependencies : To be defined
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution - 
% NonCommercial 4.0 International License. To view a copy of this license, 
% visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to 
% Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
% -------------------------------------------------------------------------

function [] = ProcessVideos(Patient_ID,Session_ID,Session_date,Session_protocol,Folder,staticTypes,trialTypes,videoTypes)

% Create temporary folder
% mkdir('temp');

% Find AVI files
aviFiles = dir('*.avi');

% Process AVI files
for ifile = 1:size(aviFiles,1)
    
    % Set input filename
    inputFile  = ['"',Folder.data,aviFiles(ifile).name,'"'];

    % Set output filenames
    for itype = 1:size(staticTypes,1)
        if contains(aviFiles(ifile).name,staticTypes{itype,1})
            task = staticTypes{itype,2};
            for itype2 = 1:size(videoTypes,1)
                if contains(aviFiles(ifile).name,videoTypes{itype2,1})
                    video  = videoTypes{itype2,2};
                    ivideo = itype2;
                end
            end
            temp1 = regexprep(aviFiles(ifile).name,[staticTypes{itype,1},' '],'');
            temp2 = regexprep(temp1,['_',videoTypes{ivideo,1},'.avi'],'');
            num   = str2num(temp2);
            clear temp1 temp2;
        end
    end  
    for itype = 1:size(trialTypes,1)
        if contains(aviFiles(ifile).name,trialTypes{itype,1})
            task = trialTypes{itype,2};
            for itype2 = 1:size(videoTypes,1)
                if contains(aviFiles(ifile).name,videoTypes{itype2,1})
                    video  = videoTypes{itype2,2};
                    ivideo = itype2;
                end
            end
            temp1 = regexprep(aviFiles(ifile).name,[trialTypes{itype,1},' '],'');
            temp2 = regexprep(temp1,['_',videoTypes{ivideo,1},'.avi'],'');
            num   = str2num(temp2);
            clear temp1 temp2;
        end
    end            
    if num < 10
        num = ['0',num2str(num)];
    else
        num = num2str(num);
    end
    outputFile2 = ['C:\temp\',num2str(Patient_ID),'-',Session_ID,'-',Session_date,'-',regexprep(Session_protocol,'KLAB-UPPERLIMB-',''),'-',task,'-',num,'-',video,'.avi"']; % Stored as processed file after high compression
%     outputFile2 = ['"',Folder.data,'\temp\',num2str(Patient_ID),'-',Session_ID,'-',Session_date,'-',regexprep(Session_protocol,'KLAB-UPPERLIMB-',''),'-',task,'-',num,'-',video,'.avi"']; % Stored as processed file after high compression

    % Apply video compression and rotation (only for high compression)
    cd(Folder.dependencies);
    if contains(aviFiles(ifile).name,'Miqus_10')
        system(['ffmpeg.exe -i ',inputFile,' -vf "transpose=3" -vcodec libx264 ',outputFile2]);
    elseif contains(aviFiles(ifile).name,'Miqus_12')
        system(['ffmpeg.exe -i ',inputFile,' -vf "transpose=2" -vcodec libx264 ',outputFile2]);
    elseif contains(aviFiles(ifile).name,'Miqus_11') || contains(aviFiles(ifile).name,'Miqus_13')
        system(['ffmpeg.exe -i ',inputFile,' -vf "transpose=1"  -vcodec libx264 ',outputFile2]);
    end

    % Delete initial video files
    cd(regexprep(Folder.data,'"',''));
    delete(aviFiles(ifile).name);

    % Export files
    cd(regexprep(Folder.data,'"',''));
    cd ..;
    if ~isfolder('Processed')
        mkdir('Processed');
    end
    cd Processed;
    folder = pwd;
    cd(regexprep(Folder.data,'"',''));
%     movefile(['temp\',aviFiles(ifile).name],regexprep(Folder.data,'"',''));
    movefile(['C:\temp\',num2str(Patient_ID),'-',Session_ID,'-',Session_date,'-',regexprep(Session_protocol,'KLAB-UPPERLIMB-',''),'-',task,'-',num,'-',video,'.avi'],[folder,'\']);
%     movefile(['temp\',num2str(Patient_ID),'-',Session_ID,'-',Session_date,'-',regexprep(Session_protocol,'KLAB-UPPERLIMB-',''),'-',task,'-',num,'-',video,'.avi'],[folder,'\']);
end

% Clear temporary folder
cd(Folder.data);
% rmdir('temp');