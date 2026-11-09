% =========================================================================
% usercommands_conditions.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : November 2026
% -------------------------------------------------------------------------
% Description : Shared configuration of the analysis pipeline: folder of the
%               K-LAB participant files, dominant side, joint indices and order
%               of the conditions of each participant. Called with run() at the
%               start of the pipeline scripts.
% -------------------------------------------------------------------------
% Parameters  : none
% Outputs     : Workspace variables only (no figure, no file)
%               dataFolder         : folder of the K-LAB .mat files
%               PATIENT_IDS        : participant IDs
%               DOMINANT_SIDE      : Map, participant ID -> 'R' / 'L'
%               SCAPULA_JOINT_IDX, GLENOHUMERAL_JOINT_IDX,
%               HUMEROTHORACIC_JOINT_IDX : Maps, side -> joint index
%               PATIENT_COND       : condition and repetition of each trial
%               PATIENT_EXCEPTIONS : conditions without a recorded trial
% -------------------------------------------------------------------------
% Dependencies: helpers/local_paths.m
% =========================================================================

addpath(fullfile(fileparts(mfilename('fullpath')), 'helpers'));
dataFolder = local_paths();

PATIENT_IDS = {'P001','P002','P003','P004','P005','P006','P007','P008','P009','P010'};

DOMINANT_SIDE = containers.Map(PATIENT_IDS, {'R','R','R','R','R','L','R','L','R','L'});

% Joint indices in the K-LAB files, for each side
SCAPULA_JOINT_IDX        = containers.Map({'R','L'}, {3, 8});   % scapula / thorax
GLENOHUMERAL_JOINT_IDX   = containers.Map({'R','L'}, {2, 7});   % humerus / scapula
HUMEROTHORACIC_JOINT_IDX = containers.Map({'R','L'}, {1, 6});   % humerus / thorax

% Order of the conditions of each participant (three consecutive trials per
% condition), in the order of the trials in the K-LAB file. Encoded by hand
% from the rating table (Data_clean_*.csv keeps the same order).
uc_order = { ...
    'P001', {'No FES','Min_fatigue','Min_stress','Random','Min_pulse_width','Rehab','Min_force'}; ...
    'P002', {'No FES','Min_force','Rehab','Min_pulse_width','Min_stress','Min_fatigue','Random'}; ...
    'P003', {'No FES','Min_pulse_width','Min_stress','Rehab','Min_fatigue','Random','Min_force'}; ...
    'P004', {'No FES','Rehab','Min_pulse_width','Min_force','Min_fatigue','Min_stress','Random'}; ...
    'P005', {'No FES','Random','Min_fatigue','Min_stress','Rehab','Min_force','Min_pulse_width'}; ...
    'P006', {'No FES','Random','Min_fatigue','Min_stress','Min_force','Min_pulse_width','Rehab'}; ...
    'P007', {'No FES','Min_fatigue','Min_stress','Min_force','Random','Min_pulse_width','Rehab'}; ...
    'P008', {'No FES','Min_stress','Min_pulse_width','Rehab','Random','Min_force','Min_fatigue'}; ...
    'P009', {'No FES','Min_pulse_width','Random','Min_fatigue','Min_force','Rehab','Min_stress'}; ...
    'P010', {'No FES','Min_stress','Min_force','Min_pulse_width','Rehab','Random','Min_fatigue'}};
PATIENT_COND = struct();
for uc_k = 1:size(uc_order, 1)
    PATIENT_COND.(uc_order{uc_k, 1}).condition = repelem(uc_order{uc_k, 2}(:), 3);
    PATIENT_COND.(uc_order{uc_k, 1}).block     = repmat((1:3)', numel(uc_order{uc_k, 2}), 1);
end
clear uc_order uc_k

% P007: first No FES trial not recorded, so its 20 trials correspond to the
% positions 2 to 21 of the condition list
PATIENT_EXCEPTIONS = struct();
PATIENT_EXCEPTIONS.P007.missingCondPositions = 1;
