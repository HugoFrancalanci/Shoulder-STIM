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

% -------------------------------------------------------------------------
% INIT WORKSPACE
% -------------------------------------------------------------------------
clearvars;
close all;
warning off;
system('taskkill /F /IM EXCEL.EXE'); 
clc;
disp('------------------------------------------------------------------');
disp('KLAB_UpperLimb_toolbox');
disp('Protocole 1');
disp('Auteur : F. Moissenet');
disp('------------------------------------------------------------------');
disp(' ');

% -------------------------------------------------------------------------
% SET FOLDERS
% -------------------------------------------------------------------------
disp('Définition des répertoires de travail');
Folder.preprocessing = 'C:\Users\moissene\OneDrive - unige.ch\_AQMS\Matlab\KLAB_ShoulderAnalysis_Toolbox\0-Preprocessing\';
Folder.toolbox       = 'C:\Users\moissene\OneDrive - unige.ch\_AQMS\Matlab\KLAB_ShoulderAnalysis_Toolbox\1-Processing\Protocol01\';
Folder.dependencies  = 'C:\Users\moissene\OneDrive - unige.ch\_AQMS\Matlab\KLAB_ShoulderAnalysis_Toolbox\1-Processing\dependencies\';
addpath(Folder.toolbox);
addpath(genpath(Folder.dependencies));
disp(' ');

% -------------------------------------------------------------------------
% GET SESSION DATA
% -------------------------------------------------------------------------
% Session 1
disp('Récupération des informations de la première session');
Session1.Folder.data = uigetdir();
cd([Session1.Folder.data,'\Report\']);
matFile = dir('*.mat');
Session1 = load(matFile.name);
disp(['  - Patient   : ',num2str(Session1.Patient.ID),' - ',Session1.Patient.lastname,' ',Session1.Patient.firstname]);
disp(['  - Session   : ',datestr(Session1.Session.date,'yyyyMMdd')]);
disp(['  - Protocole : ',Session1.Session.protocol]);
disp(['  - Objectif  : ',Session1.Session.objective]);
disp(' ');
clear matFile;
% Session 2
disp('Récupération des informations de la seconde sessions');
Session2.Folder.data = uigetdir();
cd([Session2.Folder.data,'\Report\']);
matFile = dir('*.mat');
Session2 = load(matFile.name);
disp(['  - Patient   : ',num2str(Session2.Patient.ID),' - ',Session2.Patient.lastname,' ',Session2.Patient.firstname]);
disp(['  - Session   : ',datestr(Session2.Session.date,'yyyyMMdd')]);
disp(['  - Protocole : ',Session2.Session.protocol]);
disp(['  - Objectif  : ',Session2.Session.objective]);
disp(' ');
clear matFile;

% -------------------------------------------------------------------------
% GENERATE REPORT
% -------------------------------------------------------------------------
disp('Génération du rapport');
cd([Session2.Folder.data,'\Report\']);
if isempty(dir('*Rapport_comparaison.docx'))
    copyfile([Folder.toolbox,'Report\KLAB - Analyse quantifiée du membre supérieur - Rapport comparaison - Template.docx'],[Session2.Folder.data,'\Report\',num2str(Session2.Patient.ID),'-',Session2.Session.ID,'-',datestr(Session2.Session.date,'YYYYmmDD'),'-Rapport_comparaison.docx']);
    copyfile([Folder.toolbox,'Report\Skeleton_left_shoulder.png'],[Session2.Folder.data,'\Report\Skeleton_left_shoulder.png']);
    copyfile([Folder.toolbox,'Report\Skeleton_right_shoulder.png'],[Session2.Folder.data,'\Report\Skeleton_right_shoulder.png']);
    copyfile([Folder.toolbox,'Report\Skeleton_top.png'],[Session2.Folder.data,'\Report\Skeleton_top.png']);
end
GenerateReportComparisonPlots(Folder,Session1,Session2);

% -------------------------------------------------------------------------
% STOP ALL PROCESSES
% -------------------------------------------------------------------------
close all;