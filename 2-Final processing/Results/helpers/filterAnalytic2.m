function idx = filterAnalytic2(Trial)
% =========================================================================
% filterAnalytic2.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : November 2026
% -------------------------------------------------------------------------
% Description : Positions of the arm elevation trials (task ANALYTIC2) in the
%               Trial structure of a K-LAB participant file.
% -------------------------------------------------------------------------
% Parameters  : Trial : Trial structure of a K-LAB file
% Outputs     : idx   : positions of the ANALYTIC2 trials (row vector)
% -------------------------------------------------------------------------
% Dependencies: none
% =========================================================================

idx = find(reshape(strcmp({Trial.task}, 'ANALYTIC2'), 1, []));
end
