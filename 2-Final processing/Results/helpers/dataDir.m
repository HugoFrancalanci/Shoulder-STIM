function d = dataDir()
% =========================================================================
% dataDir.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   October 2026
% -------------------------------------------------------------------------
% Description :  Single place defining where the PRIVATE derived data live :
%                every cache_*.mat (all_comp caches, EMG ratio / discrete
%                caches) and the reviewer workbooks (Kinematics_results.xlsx,
%                Electromyography_results.xlsx). They are kept OUTSIDE the
%                git repository (participant data). All pipeline/ and
%                article_tables/ scripts read and write there through this
%                function. To move the data, edit DATA_DIR below only.
% -------------------------------------------------------------------------
% Outputs    :   d — absolute path of the data folder (must exist)
% -------------------------------------------------------------------------
% Dependencies : none
% =========================================================================

DATA_DIR = 'C:\Users\franc\OneDrive - Université de Genève\PhD Hugo\04_Outputs\01_Publications\02_Collaborations\2026_Impact of electrical stimulation\Data';

if ~isfolder(DATA_DIR)
    error('dataDir:missing', ['Dossier des donnees privees introuvable :\n  %s\n' ...
          'Modifier DATA_DIR dans helpers/dataDir.m.'], DATA_DIR);
end
d = DATA_DIR;
end
