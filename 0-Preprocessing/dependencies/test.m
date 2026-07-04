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

function [] = ProcessVideos(Folder,staticTypes,trialTypes,videoSet)

mkdir('temp');
aviFiles = dir('*.avi');
for ifile = 1:size(aviFiles,1)
    inputFile  = ['"',Folder.data,aviFiles(ifile).name,'"'];    
    outputFile1 = ['"',Folder.data,'temp\',aviFiles(ifile).name,'"'];
    outputFile2 = ['"',Folder.data,'\temp\c_',aviFiles(ifile).name,'"'];
    cd(Folder.dependencies);
    if contains(aviFiles(ifile).name,'Miqus_2') || contains(aviFiles(ifile).name,'Miqus_11') || contains(aviFiles(ifile).name,'Miqus_13') || contains(aviFiles(ifile).name,'Oqus_13')
        system(['ffmpeg.exe -i ',inputFile,' -vcodec mjpeg ',outputFile1]);
        system(['ffmpeg.exe -i ',inputFile,' -vcodec libx264 ',outputFile2]); %-vf "transpose=2" 
    elseif contains(aviFiles(ifile).name,'Miqus_12') || contains(aviFiles(ifile).name,'Miqus_14')
        system(['ffmpeg.exe -i ',inputFile,' -vcodec mjpeg ',outputFile1]);
        system(['ffmpeg.exe -i ',inputFile,' -vcodec libx264 ',outputFile2]); %-vf "transpose=1" 
    end
    cd(regexprep(Folder.data,'"',''));
    delete(aviFiles(ifile).name);
    movefile(['temp\',aviFiles(ifile).name],regexprep(Folder.data,'"',''));
    movefile(['temp\c_',aviFiles(ifile).name],regexprep(Folder.data,'"',''));
end
cd(Folder.data);
rmdir('temp');
