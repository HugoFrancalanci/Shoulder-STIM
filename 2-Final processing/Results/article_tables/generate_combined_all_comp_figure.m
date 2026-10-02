% =========================================================================
% generate_combined_all_comp_figure.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   August 2026
% -------------------------------------------------------------------------
% Description :  Loads BOTH all-pairwise-comparisons caches
%                (cache_glenohumeral_all_comp.mat and
%                cache_scapulothoracic_all_comp.mat) and draws a single combined
%                "Final figure — all pairwise comparisons" via
%                plotCombinedJointsFigure.m : row 1 = glenohumeral, row 2 =
%                scapulo-thoracic, group mean ± SD per condition, group-
%                level significant post-hoc bars only (same visual style as
%                Figure 1 of plotAllCompFigure.m). Significant pairs are
%                recensed across BOTH joints so a pair keeps the same
%                legend colour wherever it is significant. No statistics
%                are (re)computed — both scripts producing the caches
%                (extract_glenohumeral_kinematics_all_comp.m and
%                extract_scapular_kinematics_all_comp.m) must have been run
%                at least once first.
% -------------------------------------------------------------------------
% Parameters :   none
% Outputs    :   1 figure (see plotCombinedJointsFigure.m)
% -------------------------------------------------------------------------
% Dependencies : cache_glenohumeral_all_comp.mat (produced by
%                extract_glenohumeral_kinematics_all_comp.m),
%                cache_scapulothoracic_all_comp.mat (produced by
%                extract_scapular_kinematics_all_comp.m),
%                plotCombinedJointsFigure.m (plotting/ subfolder), spm1dmatlab-master/
% =========================================================================

clear; clc; close all;

HERE = fileparts(fileparts(mfilename('fullpath')));
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end
addpath(fullfile(HERE, 'plotting'));

% EXCL_ZONE : zone grisee (elevation humerothoracique > 90°), absente des
% caches anterieurs a la correction Holm -> relancer les extract_*_all_comp
CACHE_VARS = {'patientMeans', 'CONDITIONS_ORDERED', 'COND_LABELS', 'COLORS', ...
              'DOF_LABELS', 'x', 'spmResults', 'ALL_PAIRS', 'indivSigClusters', 'PATIENT_IDS', 'EXCL_ZONE'};

CACHE_GH = fullfile(HERE, 'cache_glenohumeral_all_comp.mat');
if ~isfile(CACHE_GH)
    error('Cache introuvable');
end
jointGH = load(CACHE_GH, CACHE_VARS{:});
jointGH.rowLabel   = 'Glenohumeral';
jointGH.jointLabel = 'Glenohumeral kinematics';

CACHE_ST = fullfile(HERE, 'cache_scapulothoracic_all_comp.mat');
if ~isfile(CACHE_ST)
    error('Cache introuvable');
end
jointST = load(CACHE_ST, CACHE_VARS{:});
jointST.rowLabel   = 'Scapulothoracic';
jointST.jointLabel = 'Scapular kinematics';

plotCombinedJointsFigure({jointGH, jointST});
