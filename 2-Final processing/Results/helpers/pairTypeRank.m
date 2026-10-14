function rk = pairTypeRank(condA, condB)
% =========================================================================
% pairTypeRank.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Display order of a significant pair of conditions in the
%               article figures, by type of comparison: 1 = no stimulation
%               vs non-optimised, 2 = no stimulation vs optimised,
%               3 = non-optimised vs optimised, 4 = within a group.
% -------------------------------------------------------------------------
% Parameters  : condA, condB : condition names (code names)
% Outputs     : rk : rank (1 to 4)
% -------------------------------------------------------------------------
% Dependencies: none
% =========================================================================

g = sort({conditionGroup(condA), conditionGroup(condB)});
switch strjoin(g, '-')
    case 'non-none', rk = 1;   % no stimulation vs non-optimised
    case 'none-opt', rk = 2;   % no stimulation vs optimised
    case 'non-opt',  rk = 3;   % non-optimised vs optimised
    otherwise,       rk = 4;   % within a group
end
end


function g = conditionGroup(cond)
    switch cond
        case 'No FES',            g = 'none';
        case {'Rehab', 'Random'}, g = 'non';
        otherwise,                g = 'opt';
    end
end
