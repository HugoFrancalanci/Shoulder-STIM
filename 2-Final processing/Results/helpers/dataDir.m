function d = dataDir()
% =========================================================================
% dataDir.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Returns the folder where the derived data (cache_*.mat files)
%               are read and written. These files contain participant data and
%               are kept outside the code repository. Edit DATA_DIR to move
%               them.
% -------------------------------------------------------------------------
% Parameters  : none
% Outputs     : d : absolute path of the data folder (error if missing)
% -------------------------------------------------------------------------
% Dependencies: none
% =========================================================================

DATA_DIR = 'C:\Users\franc\OneDrive - Université de Genève\PhD Hugo\04_Outputs\01_Publications\02_Collaborations\2026_Impact of electrical stimulation\Data';

if ~isfolder(DATA_DIR)
    error('dataDir:missing', ['Dossier des donnees privees introuvable :\n  %s\n' ...
          'Modifier DATA_DIR dans helpers/dataDir.m.'], DATA_DIR);
end
d = DATA_DIR;
end
