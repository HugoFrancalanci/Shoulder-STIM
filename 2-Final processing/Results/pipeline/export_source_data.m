% =========================================================================
% export_source_data.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : October 2026
% -------------------------------------------------------------------------
% Description : Exports the data and the statistical results of the two
%               article figures to one Excel file (one sheet per table).
%               Reads the caches of the pipeline scripts; nothing is
%               recomputed. Participants are recoded P01 to P10.
% -------------------------------------------------------------------------
% Parameters  : OUT_FILE : output Excel file (in the data folder)
% Outputs     : Source_data_Figures1-2.xlsx
% -------------------------------------------------------------------------
% Dependencies: the caches of the pipeline (run the pipeline first),
%               helpers/dataDir.m, spm1dmatlab-master/
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' export_source_data.m');
disp('=========================================');

HERE = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(HERE, 'spm1dmatlab-master')));   % needed to read the SPM results
addpath(fullfile(HERE, 'helpers'));

OUT_FILE = fullfile(dataDir(), 'Source_data_Figures1-2.xlsx');
if isfile(OUT_FILE), delete(OUT_FILE); end

% -------------------------------------------------------------------------
% Caches
% -------------------------------------------------------------------------
H  = load(fullfile(dataDir(), 'cache_humerothoracic_all_comp.mat'), 'patientMeans', 'disc', 'discStats', ...
          'spmResults', 'x', 'PATIENT_IDS', 'CONDITIONS_ORDERED', 'COND_LABELS', 'ALL_PAIRS');
RH = load(fullfile(dataDir(), 'cache_scapulohumeral_rhythm_all_comp.mat'), 'joints', 'ELEV_GRID', 'ALL_PAIRS');
EL = load(fullfile(dataDir(), 'cache_emg_elevation_all_comp.mat'), 'spmPeak', 'elevProf', 'excluded', ...
          'ELEV_GRID', 'ALL_PAIRS', 'EMG_LABELS');

COND  = H.COND_LABELS;
CRAW  = H.CONDITIONS_ORDERED;
nCond = numel(COND);
nPat  = numel(H.PATIENT_IDS);
PID   = arrayfun(@(k) sprintf('P%02d', str2double(H.PATIENT_IDS{k}(2:end))), 1:nPat, 'UniformOutput', false);
MUSCLE = containers.Map({'TRAPS','TRAPM','TRAPI','SERRA'}, ...
    {'Upper trapezius', 'Middle trapezius', 'Lower trapezius', 'Serratus anterior'});
MUS   = EL.EMG_LABELS;
pairA = cellfun(@(c) find(strcmp(CRAW, c)), H.ALL_PAIRS(:,1));
pairB = cellfun(@(c) find(strcmp(CRAW, c)), H.ALL_PAIRS(:,2));
sheets = {};   % {name, description} for the README

% -------------------------------------------------------------------------
% Figure 1: humerothoracic elevation
% -------------------------------------------------------------------------
x = H.x(:);
curves = cell(nCond, 1);              % curves{ic} = (nPat, 101)
rows = {};
for ic = 1:nCond
    curves{ic} = cat(1, H.patientMeans.(matlab.lang.makeValidName(CRAW{ic})){:});
    for ip = 1:nPat
        rows(end+1, :) = {PID{ip}, COND{ic}, x, round(curves{ic}(ip, :)', 2)}; %#ok<SAGROW>
    end
end
T = longTable(rows, {'Participant', 'Condition', 'Cycle (%)', 'Elevation (deg)'});
writeSheet(T, OUT_FILE, 'Fig1_curves');
sheets(end+1, :) = {'Fig1_curves', 'Figure 1. Humerothoracic elevation of each participant and condition over the movement cycle (mean of the 3 trials).'};

T = table();
for ic = 1:nCond
    for ip = 1:nPat
        T = [T; {PID{ip}, COND{ic}, round(H.disc.peakElev(ip, ic), 1), round(H.disc.peakTime(ip, ic), 1), ...
                 round(H.disc.riseTime(ip, ic), 1), round(H.disc.planeAtPeak(ip, ic), 1), ...
                 round(H.disc.planeMean2090(ip, ic), 1)}]; %#ok<AGROW>
    end
end
T.Properties.VariableNames = {'Participant', 'Condition', 'Peak elevation (deg)', 'Peak timing (% cycle)', 'Rise time (% cycle)', ...
    'Plane of elevation at peak (deg)', 'Mean plane of elevation 20-90 deg (deg)'};
writeSheet(T, OUT_FILE, 'Fig1_parameters');
sheets(end+1, :) = {'Fig1_parameters', ['Figure 1. Peak elevation, peak timing, rise time (time to reach half of the elevation range), ' ...
    'plane of elevation at peak elevation, and mean plane of elevation between 20 and 90 deg of elevation (ascending phase) ' ...
    'of each participant and condition. Plane of elevation: 0 deg = frontal plane, + = anterior.']};

T = spmTable(H.spmResults, curves, x, CRAW, COND, @(ep) ep, 'Start (% cycle)', 'End (% cycle)', 'Elevation (deg)');
writeSheet(T, OUT_FILE, 'Fig1_SPM');
sheets(end+1, :) = {'Fig1_SPM', 'Figure 1. SPM1D results: parts of the cycle where the ANOVA is significant, and pairs of conditions that differ after Holm-Bonferroni correction, with the mean elevation of each condition over the window.'};

T = table();
pnames = {'peakElev', 'Peak elevation (deg)'; 'peakTime', 'Peak timing (% cycle)'; 'riseTime', 'Rise time (% cycle)'; ...
          'planeAtPeak', 'Plane of elevation at peak (deg)'; 'planeMean2090', 'Mean plane of elevation 20-90 deg (deg)'};
for k = 1:size(pnames, 1)
    T = [T; discreteStats(H.disc.(pnames{k,1}), H.discStats.(pnames{k,1}), pnames{k,2}, '', pairA, pairB, COND)]; %#ok<AGROW>
end
writeSheet(T, OUT_FILE, 'Fig1_parameters_stats');
sheets(end+1, :) = {'Fig1_parameters_stats', 'Figure 1. Comparison of the parameters between conditions: ANOVA p-value across the 7 conditions and across the 6 FES conditions only, then the 21 pairs of conditions (p-value before and after Holm-Bonferroni correction).'};

% -------------------------------------------------------------------------
% Figure 2, first row: scapulothoracic angles as a function of
% humerothoracic elevation
% -------------------------------------------------------------------------
J = RH.joints{cellfun(@(j) contains(lower(j.name), 'scap'), RH.joints)};
grid = RH.ELEV_GRID(:);
keepP = ~ismember(H.PATIENT_IDS, J.excluded);
dofNames = strcat(J.DOF_LABELS, ' (deg)');
rows = {};
st = cell(nCond, numel(J.DOF_LABELS));       % st{ic,id} = (nPat, nGrid)
for ic = 1:nCond
    R = J.rhythmMeans.(matlab.lang.makeValidName(CRAW{ic}));
    for id = 1:numel(J.DOF_LABELS)
        st{ic, id} = cell2mat(cellfun(@(r) r(id, :), R(:), 'UniformOutput', false));
    end
    for ip = find(keepP)
        rows(end+1, :) = [{PID{ip}, COND{ic}, grid}, arrayfun(@(id) round(R{ip}(id, :)', 2), ...
                          1:numel(J.DOF_LABELS), 'UniformOutput', false)]; %#ok<SAGROW>
    end
end
T = longTable(rows, [{'Participant', 'Condition', 'Humerothoracic elevation (deg)'}, dofNames]);
writeSheet(T, OUT_FILE, 'Fig2_ST_curves');
sheets(end+1, :) = {'Fig2_ST_curves', sprintf(['Figure 2, first row. Scapulothoracic angles of each participant and condition at each humerothoracic ' ...
    'elevation from 20 to 90 deg (ascending phase).'])};

T = table();
for id = 1:numel(J.DOF_LABELS)
    Td = spmTable(J.spmResults(id), st(:, id), grid, CRAW, COND, @(ep) grid(1) + ep * (grid(2) - grid(1)), ...
                  'Start (deg elevation)', 'End (deg elevation)', 'Angle (deg)', keepP);
    Td = addvars(Td, repmat(J.DOF_LABELS(id), height(Td), 1), 'Before', 1, 'NewVariableNames', 'Angle');
    T = [T; Td]; %#ok<AGROW>
end
writeSheet(T, OUT_FILE, 'Fig2_ST_SPM');
sheets(end+1, :) = {'Fig2_ST_SPM', 'Figure 2, first row. SPM1D results for each angle: elevation ranges where the ANOVA is significant, and pairs of conditions that differ after Holm-Bonferroni correction, with the mean angle of each condition over the range.'};

% -------------------------------------------------------------------------
% Figure 2, second row: EMG as a function of humerothoracic elevation
% -------------------------------------------------------------------------
gridE = EL.ELEV_GRID(:);
keepE = ~ismember(H.PATIENT_IDS, EL.excluded);
rows = {};
for im = 1:numel(MUS)
    for ic = 1:nCond
        for ip = find(keepE)
            rows(end+1, :) = {PID{ip}, COND{ic}, MUSCLE(MUS{im}), gridE, round(EL.elevProf{im}{ic}(ip, :)', 2)}; %#ok<SAGROW>
        end
    end
end
T = longTable(rows, {'Participant', 'Condition', 'Muscle', 'Humerothoracic elevation (deg)', 'EMG (% of peak)'});
writeSheet(T, OUT_FILE, 'Fig2_EMG_curves');
sheets(end+1, :) = {'Fig2_EMG_curves', sprintf(['Figure 2, second row. EMG envelope of each participant, condition and muscle, expressed as a ' ...
    'percentage of the peak of each trial (mean of the 3 trials), at each humerothoracic elevation from 20 to 90 deg ' ...
    '(ascending phase).'])};

T = table();
for im = 1:numel(MUS)
    sp = EL.spmPeak(im);
    for c = 1:size(sp.anovaClusters, 1)
        T = [T; {MUSCLE(MUS{im}), 'ANOVA (7 conditions)', "", "", round(sp.anovaClusters(c,1), 1), ...
                 round(sp.anovaClusters(c,2), 1), NaN, NaN, NaN, NaN, fmtP(sp.anovaClusters(c,3))}]; %#ok<AGROW>
    end
    for kp = find(sp.pairSig(:))'
        a = EL.ALL_PAIRS(kp, 1); b = EL.ALL_PAIRS(kp, 2);
        C = sp.pairClusters{kp};
        for c = 1:size(C, 1)
            [ma, sa] = windowMean(EL.elevProf{im}{a}(keepE, :), gridE, C(c, 1:2));
            [mb, sb] = windowMean(EL.elevProf{im}{b}(keepE, :), gridE, C(c, 1:2));
            T = [T; {MUSCLE(MUS{im}), 'Paired t-test (Holm)', string(COND{a}), string(COND{b}), round(C(c,1), 1), ...
                     round(C(c,2), 1), round(ma, 1), round(sa, 1), round(mb, 1), round(sb, 1), fmtP(C(c,3))}]; %#ok<AGROW>
        end
    end
    if ~sp.anovaSig
        T = [T; {MUSCLE(MUS{im}), 'ANOVA (7 conditions)', "", "", NaN, NaN, NaN, NaN, NaN, NaN, "Not significant"}]; %#ok<AGROW>
    end
end
T.Properties.VariableNames = {'Muscle', 'Test', 'Condition A', 'Condition B', 'Start (deg elevation)', 'End (deg elevation)', ...
    'Mean A (% of peak)', 'SD A', 'Mean B (% of peak)', 'SD B', 'p'};
writeSheet(T, OUT_FILE, 'Fig2_EMG_SPM');
noPair = '';
if ~any(arrayfun(@(s) any(s.pairSig), EL.spmPeak)), noPair = ' No pair of conditions differs after correction.'; end
sheets(end+1, :) = {'Fig2_EMG_SPM', ['Figure 2, second row. SPM1D results for each muscle: elevation ranges where the ANOVA is significant, ' ...
    'and pairs of conditions that differ after Holm-Bonferroni correction, with the mean value of each condition over the range.' noPair]};

% -------------------------------------------------------------------------
% README (first sheet)
% -------------------------------------------------------------------------
info = {
 'Study',        'Effect of seven deltoid stimulation conditions on shoulder kinematics and scapular muscle activity during arm elevation in the scapular plane.';
 'Participants', sprintf('%d healthy participants (P01 to P%02d), 3 trials per condition. Each value is the mean of the 3 trials.', nPat, nPat);
 'Conditions',   strjoin(COND, ', ');
 'Muscles',      'Upper trapezius, middle trapezius, lower trapezius, serratus anterior.';
 'Units',        'Angles and humerothoracic elevation in degrees. Time in % of the movement cycle (0 = start, 100 = end). EMG in % of the peak of each trial.';
 'Statistics',   'Non-parametric repeated-measures ANOVA across the 7 conditions (10 000 permutations). If significant, paired t-tests on the 21 pairs of conditions with Holm-Bonferroni correction (alpha = 0.05). Curves were compared with SPM1D. The humerothoracic parameters were also compared across the 6 FES conditions only (same ANOVA).';
 'Pairs',        'Condition A and Condition B give the two compared conditions. Mean and SD are given across participants.';
 'Empty cells',  'Empty cells mean "not applicable".';
 '',             ''};
T = cell2table([info; [{'Sheet'}, {'Content'}]; sheets], 'VariableNames', {'Item', 'Description'});
writetable(T, OUT_FILE, 'Sheet', 'README');
moveReadmeFirst(OUT_FILE);

fprintf('\nFichier ecrit : %s\n', OUT_FILE);
disp('Termine.');


% =========================================================================
% LOCAL FUNCTIONS
% =========================================================================

function T = longTable(rows, names)
    % rows: {id, condition, [muscle,] axis (n,1), values (n,1) ...} -> one line per point
    n = numel(rows{1, end});
    nFixed = find(cellfun(@(v) isnumeric(v) && numel(v) > 1, rows(1, :)), 1) - 1;
    cols = cell(1, size(rows, 2));
    for c = 1:size(rows, 2)
        if c <= nFixed
            cols{c} = repelem(string(rows(:, c)), n, 1);
        else
            cols{c} = cell2mat(rows(:, c));
        end
    end
    T = table(cols{:}, 'VariableNames', names);
end

function T = spmTable(res, curves, x, CRAW, COND, toUnit, startName, endName, valueName, keepP)
    % ANOVA clusters and significant post-hoc pairs of one SPM1D result
    if nargin < 10, keepP = true(size(curves{1}, 1), 1); end
    T = table();
    for c = 1:numel(res.anova_clusters)
        ep = res.anova_clusters{c}.endpoints;
        T = [T; {'ANOVA (7 conditions)', "", "", round(toUnit(max(ep(1), 0)), 1), round(toUnit(min(ep(2), numel(x) - 1)), 1), ...
                 NaN, NaN, NaN, NaN, fmtP(res.anova_clusters{c}.P)}]; %#ok<AGROW>
    end
    if isstruct(res.posthoc)
        f = fieldnames(res.posthoc);
        for k = 1:numel(f)
            ph = res.posthoc.(f{k});
            if ~ph.sig, continue; end
            a = find(strcmp(CRAW, ph.condA)); b = find(strcmp(CRAW, ph.condB));
            for c = 1:numel(ph.clusters)
                ep = ph.clusters{c}.endpoints;
                w = [toUnit(max(ep(1), 0)), toUnit(min(ep(2), numel(x) - 1))];
                [ma, sa] = windowMean(curves{a}(keepP, :), x, w);
                [mb, sb] = windowMean(curves{b}(keepP, :), x, w);
                T = [T; {'Paired t-test (Holm)', string(COND{a}), string(COND{b}), round(w(1), 1), round(w(2), 1), ...
                         round(ma, 1), round(sa, 1), round(mb, 1), round(sb, 1), fmtP(ph.clusters{c}.P)}]; %#ok<AGROW>
            end
        end
    end
    unit = regexp(valueName, '\(.*\)', 'match', 'once');
    T.Properties.VariableNames = {'Test', 'Condition A', 'Condition B', startName, endName, ...
        ['Mean A ' unit], 'SD A', ['Mean B ' unit], 'SD B', 'p'};
end

function [m, s] = windowMean(M, x, w)
    % mean over the window for each participant, then mean and SD across participants
    idx = x >= w(1) - 1e-9 & x <= w(2) + 1e-9;
    if ~any(idx), [~, i] = min(abs(x - mean(w))); idx(i) = true; end
    v = mean(M(:, idx), 2);
    v = v(~isnan(v));
    m = mean(v); s = std(v);
end

function T = discreteStats(Y, st, paramName, muscleName, pairA, pairB, COND)
    % ANOVA line(s), then the 21 pairs if the ANOVA is significant
    T = {muscleName, paramName, 'ANOVA (7 conditions)', "", "", NaN, NaN, NaN, NaN, fmtP(st.anova_p), "", yesNo(st.anova_sig)};
    if isfield(st, 'anova_p_fes')
        T = [T; {muscleName, paramName, 'ANOVA (6 FES conditions)', "", "", NaN, NaN, NaN, NaN, fmtP(st.anova_p_fes), "", yesNo(st.anova_sig_fes)}];
    end
    if st.anova_sig
        for kp = 1:numel(pairA)
            a = pairA(kp); b = pairB(kp);
            T = [T; {muscleName, paramName, 'Paired t-test', string(COND{a}), string(COND{b}), ...
                     round(mean(Y(:, a), 'omitnan'), 1), round(std(Y(:, a), 'omitnan'), 1), ...
                     round(mean(Y(:, b), 'omitnan'), 1), round(std(Y(:, b), 'omitnan'), 1), ...
                     fmtP(st.p(kp)), fmtP(st.pHolm(kp)), yesNo(st.sig(kp))}]; %#ok<AGROW>
        end
    end
    T = cell2table(T, 'VariableNames', {'Muscle', 'Parameter', 'Test', 'Condition A', 'Condition B', ...
        'Mean A', 'SD A', 'Mean B', 'SD B', 'p', 'p (Holm)', 'Significant'});
    if isempty(muscleName), T.Muscle = []; end
end

function s = fmtP(p)
    if isnan(p), s = ""; elseif p < 0.001, s = "< 0.001"; else, s = string(sprintf('%.3f', p)); end
end

function s = yesNo(b)
    if b, s = "Yes"; else, s = "No"; end
end

function writeSheet(T, file, name)
    writetable(T, file, 'Sheet', name);
    fprintf('  %-24s %6d lignes\n', name, height(T));
end

function moveReadmeFirst(file)
    % puts the README sheet first and widens the columns (Excel, if available)
    try
        xl = actxserver('Excel.Application'); xl.DisplayAlerts = false;
        wb = xl.Workbooks.Open(file);
        ws = wb.Worksheets.Item('README');
        ws.Move(wb.Worksheets.Item(1));
        ws.Columns.Item(1).ColumnWidth = 16;
        ws.Columns.Item(2).ColumnWidth = 120;
        ws.Columns.Item(2).WrapText = true;
        for k = 2:wb.Worksheets.Count
            wb.Worksheets.Item(k).UsedRange.Columns.AutoFit;
        end
        wb.Save; wb.Close; xl.Quit; delete(xl);
    catch
        fprintf('  (Excel indisponible : README non deplace en premier)\n');
    end
end
