function [participantDir, derivedDir] = local_paths()
% =========================================================================
% local_paths_template.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : November 2026
% -------------------------------------------------------------------------
% Description : Template of the local data folders. Copy this file to
%               helpers/local_paths.m (this name is not tracked by git), rename
%               the function if needed and set the two folders below.
% -------------------------------------------------------------------------
% Parameters  : none
% Outputs     : participantDir : folder of the K-LAB files P1.mat to P10.mat
%               derivedDir     : folder of the derived data (cache_*.mat)
% -------------------------------------------------------------------------
% Dependencies: none
% =========================================================================

participantDir = 'path/to/participant/files';
derivedDir     = 'path/to/derived/data';
end
