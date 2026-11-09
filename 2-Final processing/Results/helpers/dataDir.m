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
%               are kept outside the code repository. The folder is set in
%               helpers/local_paths.m.
% -------------------------------------------------------------------------
% Parameters  : none
% Outputs     : d : absolute path of the data folder (error if missing)
% -------------------------------------------------------------------------
% Dependencies: helpers/local_paths.m
% =========================================================================

[~, DATA_DIR] = local_paths();

if ~isfolder(DATA_DIR)
    error('dataDir:missing', ['Private data folder not found:\n  %s\n' ...
          'Edit helpers/local_paths.m.'], DATA_DIR);
end
d = DATA_DIR;
end
