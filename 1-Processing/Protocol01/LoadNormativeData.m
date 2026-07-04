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

function Normal = LoadNormativeData(Folder,Session,Patient)

% Maximal angles
% -------------------------------------------------------------------------
tNormals = readtable([Folder.dependencies,'ConstantNormatives.xlsx'],'Range','D5:K16');
% Get normals adjusted by age and gender
patientAge = str2num(datestr(datenum(Session.date)-datenum(Patient.dob),'YYYY'));
patientGender = Patient.gender;
if patientAge < 31
    if strcmp(patientGender,'Homme')
        Normal.Analytic(2).mean = table2array(tNormals(1,3));
        Normal.Analytic(2).std = table2array(tNormals(1,4));
        Normal.Analytic(1).mean = table2array(tNormals(1,1));
        Normal.Analytic(1).std = table2array(tNormals(1,2));
        Normal.Analytic(3).mean = table2array(tNormals(1,5));
        Normal.Analytic(3).std = table2array(tNormals(1,6));
        Normal.Analytic(4).mean = table2array(tNormals(1,7));
        Normal.Analytic(4).std = table2array(tNormals(1,8));
    elseif strcmp(patientGender,'Femme')
        Normal.Analytic(2).mean = table2array(tNormals(2,3));
        Normal.Analytic(2).std = table2array(tNormals(2,4));
        Normal.Analytic(1).mean = table2array(tNormals(2,1));
        Normal.Analytic(1).std = table2array(tNormals(2,2));
        Normal.Analytic(3).mean = table2array(tNormals(2,5));
        Normal.Analytic(3).std = table2array(tNormals(2,6));
        Normal.Analytic(4).mean = table2array(tNormals(2,7));
        Normal.Analytic(4).std = table2array(tNormals(2,8));
    end
end
if patientAge >= 31 && patientAge < 41
    if strcmp(patientGender,'Homme')
        Normal.Analytic(2).mean = table2array(tNormals(3,3));
        Normal.Analytic(2).std = table2array(tNormals(3,4));
        Normal.Analytic(1).mean = table2array(tNormals(3,1));
        Normal.Analytic(1).std = table2array(tNormals(3,2));
        Normal.Analytic(3).mean = table2array(tNormals(3,5));
        Normal.Analytic(3).std = table2array(tNormals(3,6));
        Normal.Analytic(4).mean = table2array(tNormals(3,7));
        Normal.Analytic(4).std = table2array(tNormals(3,8));
    elseif strcmp(patientGender,'Femme')
        Normal.Analytic(2).mean = table2array(tNormals(4,3));
        Normal.Analytic(2).std = table2array(tNormals(4,4));
        Normal.Analytic(1).mean = table2array(tNormals(4,1));
        Normal.Analytic(1).std = table2array(tNormals(4,2));
        Normal.Analytic(3).mean = table2array(tNormals(4,5));
        Normal.Analytic(3).std = table2array(tNormals(4,6));
        Normal.Analytic(4).mean = table2array(tNormals(4,7));
        Normal.Analytic(4).std = table2array(tNormals(4,8));
    end
end
if patientAge >= 41 && patientAge < 51
    if strcmp(patientGender,'Homme')
        Normal.Analytic(2).mean = table2array(tNormals(5,3));
        Normal.Analytic(2).std = table2array(tNormals(5,4));
        Normal.Analytic(1).mean = table2array(tNormals(5,1));
        Normal.Analytic(1).std = table2array(tNormals(5,2));
        Normal.Analytic(3).mean = table2array(tNormals(5,5));
        Normal.Analytic(3).std = table2array(tNormals(5,6));
        Normal.Analytic(4).mean = table2array(tNormals(5,7));
        Normal.Analytic(4).std = table2array(tNormals(5,8));
    elseif strcmp(patientGender,'Femme')
        Normal.Analytic(2).mean = table2array(tNormals(6,3));
        Normal.Analytic(2).std = table2array(tNormals(6,4));
        Normal.Analytic(1).mean = table2array(tNormals(6,1));
        Normal.Analytic(1).std = table2array(tNormals(6,2));
        Normal.Analytic(3).mean = table2array(tNormals(6,5));
        Normal.Analytic(3).std = table2array(tNormals(6,6));
        Normal.Analytic(4).mean = table2array(tNormals(6,7));
        Normal.Analytic(4).std = table2array(tNormals(6,8));
    end
end
if patientAge >= 51 && patientAge < 61
    if strcmp(patientGender,'Homme')
        Normal.Analytic(2).mean = table2array(tNormals(7,3));
        Normal.Analytic(2).std = table2array(tNormals(7,4));
        Normal.Analytic(1).mean = table2array(tNormals(7,1));
        Normal.Analytic(1).std = table2array(tNormals(7,2));
        Normal.Analytic(3).mean = table2array(tNormals(7,5));
        Normal.Analytic(3).std = table2array(tNormals(7,6));
        Normal.Analytic(4).mean = table2array(tNormals(7,7));
        Normal.Analytic(4).std = table2array(tNormals(7,8));
    elseif strcmp(patientGender,'Femme')
        Normal.Analytic(2).mean = table2array(tNormals(8,3));
        Normal.Analytic(2).std = table2array(tNormals(8,4));
        Normal.Analytic(1).mean = table2array(tNormals(8,1));
        Normal.Analytic(1).std = table2array(tNormals(8,2));
        Normal.Analytic(3).mean = table2array(tNormals(8,5));
        Normal.Analytic(3).std = table2array(tNormals(8,6));
        Normal.Analytic(4).mean = table2array(tNormals(8,7));
        Normal.Analytic(4).std = table2array(tNormals(8,8));
    end
end
if patientAge >= 61 && patientAge < 71
    if strcmp(patientGender,'Homme')
        Normal.Analytic(2).mean = table2array(tNormals(9,3));
        Normal.Analytic(2).std = table2array(tNormals(9,4));
        Normal.Analytic(1).mean = table2array(tNormals(9,1));
        Normal.Analytic(1).std = table2array(tNormals(9,2));
        Normal.Analytic(3).mean = table2array(tNormals(9,5));
        Normal.Analytic(3).std = table2array(tNormals(9,6));
        Normal.Analytic(4).mean = table2array(tNormals(9,7));
        Normal.Analytic(4).std = table2array(tNormals(9,8));
    elseif strcmp(patientGender,'Femme')
        Normal.Analytic(2).mean = table2array(tNormals(10,3));
        Normal.Analytic(2).std = table2array(tNormals(10,4));
        Normal.Analytic(1).mean = table2array(tNormals(10,1));
        Normal.Analytic(1).std = table2array(tNormals(10,2));
        Normal.Analytic(3).mean = table2array(tNormals(10,5));
        Normal.Analytic(3).std = table2array(tNormals(10,6));
        Normal.Analytic(4).mean = table2array(tNormals(10,7));
        Normal.Analytic(4).std = table2array(tNormals(10,8));
    end
end
if patientAge >= 71
    if strcmp(patientGender,'Homme')
        Normal.Analytic(2).mean = table2array(tNormals(11,3));
        Normal.Analytic(2).std = table2array(tNormals(11,4));
        Normal.Analytic(1).mean = table2array(tNormals(11,1));
        Normal.Analytic(1).std = table2array(tNormals(11,2));
        Normal.Analytic(3).mean = table2array(tNormals(11,5));
        Normal.Analytic(3).std = table2array(tNormals(11,6));
        Normal.Analytic(4).mean = table2array(tNormals(11,7));
        Normal.Analytic(4).std = table2array(tNormals(11,8));
    elseif strcmp(patientGender,'Femme')
        Normal.Analytic(2).mean = table2array(tNormals(12,3));
        Normal.Analytic(2).std = table2array(tNormals(12,4));
        Normal.Analytic(1).mean = table2array(tNormals(12,1));
        Normal.Analytic(1).std = table2array(tNormals(12,2));
        Normal.Analytic(3).mean = table2array(tNormals(12,5));
        Normal.Analytic(3).std = table2array(tNormals(12,6));
        Normal.Analytic(4).mean = table2array(tNormals(12,7));
        Normal.Analytic(4).std = table2array(tNormals(12,8));
    end
end

clear tNormals;
tNormals = readtable([Folder.dependencies,'ConstantNormatives.xlsx'],'Range','D22:G22');
Normal.Analytic(2).SHR.mean = table2array(tNormals(1,3));
Normal.Analytic(2).SHR.std = table2array(tNormals(1,4));
Normal.Analytic(1).SHR.mean = table2array(tNormals(1,1));
Normal.Analytic(1).SHR.std = table2array(tNormals(1,2));