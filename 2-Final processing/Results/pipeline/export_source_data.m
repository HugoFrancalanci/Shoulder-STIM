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
% Description : Exports the data and the statistical results of the four
%               article figures to one Excel file (one sheet per table).
%               Reads the caches of the pipeline scripts; nothing is
%               recomputed except the peak-normalised EMG profiles and the
%               repeated-measures correlations, which are fast.
%               Participants are recoded P01 to P10.
% -------------------------------------------------------------------------
% Parameters  : OUT_FILE : output Excel file (in the data folder)
% Outputs     : Source_data_Figures1-4.xlsx
% -------------------------------------------------------------------------
% Dependencies: the 7 caches of the pipeline (run the pipeline first),
%               helpers/dataDir.m, helpers/rmCorr.m, spm1dmatlab-master/
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' export_source_data.m');
disp('=========================================');

HERE = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(HERE, 'spm1dmatlab-master')));   % needed to read the SPM results
addpath(fullfile(HERE, 'helpers'));

OUT_FILE = fullfile(dataDir(), 'Source_data_Figures1-4.xlsx');
if isfile(OUT_FILE), delete(OUT_FILE); end

% -------------------------------------------------------------------------
% Caches
% -------------------------------------------------------------------------
H  = load(fullfile(dataDir(), 'cache_humerothoracic_all_comp.mat'), 'patientMeans', 'disc', 'discStats', ...
          'spmResults', 'x', 'PATIENT_IDS', 'CONDITIONS_ORDERED', 'COND_LABELS', 'ALL_PAIRS');
RH = load(fullfile(dataDir(), 'cache_scapulohumeral_rhythm_all_comp.mat'), 'joints', 'ELEV_GRID', 'ALL_PAIRS');
E  = load(fullfile(dataDir(), 'cache_emg_all_comp.mat'), 'patientBlocks', 'EMG_LABELS');
D  = load(fullfile(dataDir(), 'cache_emg_discrete_all_comp.mat'), 'disc', 'stats', 'pairIdx', 'EMG_LABELS', 'ACT_THRESHOLD');
P  = load(fullfile(dataDir(), 'cache_emg_peaknorm_spm_all_comp.mat'), 'spmPeak', 'ALL_PAIRS');

COND  = H.COND_LABELS;
CRAW  = H.CONDITIONS_ORDERED;
nCond = numel(COND);
nPat  = numel(H.PATIENT_IDS);
PID   = arrayfun(@(k) sprintf('P%02d', str2double(H.PATIENT_IDS{k}(2:end))), 1:nPat, 'UniformOutput', false);
MUSCLE = containers.Map({'TRAPS','TRAPM','TRAPI','SERRA'}, ...
    {'Upper trapezius', 'Middle trapezius', 'Lower trapezius', 'Serratus anterior'});
MUS   = D.EMG_LABELS;
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
                 round(H.disc.riseTime(ip, ic), 1)}]; %#ok<AGROW>
    end
end
T.Properties.VariableNames = {'Participant', 'Condition', 'Peak elevation (deg)', 'Peak timing (% cycle)', 'Rise time (% cycle)'};
writeSheet(T, OUT_FILE, 'Fig1_parameters');
sheets(end+1, :) = {'Fig1_parameters', 'Figure 1. Peak elevation, peak timing and rise time (time to reach half of the elevation range) of each participant and condition.'};

T = spmTable(H.spmResults, curves, x, CRAW, COND, @(ep) ep, 'Start (% cycle)', 'End (% cycle)', 'Elevation (deg)');
writeSheet(T, OUT_FILE, 'Fig1_SPM');
sheets(end+1, :) = {'Fig1_SPM', 'Figure 1. SPM1D results: parts of the cycle where the ANOVA is significant, and pairs of conditions that differ after Holm-Bonferroni correction, with the mean elevation of each condition over the window.'};

T = table();
pnames = {'peakElev', 'Peak elevation (deg)'; 'peakTime', 'Peak timing (% cycle)'; 'riseTime', 'Rise time (% cycle)'};
for k = 1:size(pnames, 1)
    T = [T; discreteStats(H.disc.(pnames{k,1}), H.discStats.(pnames{k,1}), pnames{k,2}, '', pairA, pairB, COND)]; %#ok<AGROW>
end
writeSheet(T, OUT_FILE, 'Fig1_parameters_stats');
sheets(end+1, :) = {'Fig1_parameters_stats', 'Figure 1. Comparison of the parameters between conditions: ANOVA p-value, then the 21 pairs of conditions (p-value before and after Holm-Bonferroni correction).'};

% -------------------------------------------------------------------------
% Figure 2: scapulothoracic angles as a function of humerothoracic elevation
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
writeSheet(T, OUT_FILE, 'Fig2_curves');
sheets(end+1, :) = {'Fig2_curves', sprintf(['Figure 2. Scapulothoracic angles of each participant and condition at each humerothoracic ' ...
    'elevation from 20 to 90 deg (ascending phase). %s is not included (elevation range not covered), N = %d.'], ...
    strjoin(PID(~keepP), ', '), sum(keepP))};

T = table();
for id = 1:numel(J.DOF_LABELS)
    Td = spmTable(J.spmResults(id), st(:, id), grid, CRAW, COND, @(ep) grid(1) + ep * (grid(2) - grid(1)), ...
                  'Start (deg elevation)', 'End (deg elevation)', 'Angle (deg)', keepP);
    Td = addvars(Td, repmat(J.DOF_LABELS(id), height(Td), 1), 'Before', 1, 'NewVariableNames', 'Angle');
    T = [T; Td]; %#ok<AGROW>
end
writeSheet(T, OUT_FILE, 'Fig2_SPM');
sheets(end+1, :) = {'Fig2_SPM', 'Figure 2. SPM1D results for each angle: elevation ranges where the ANOVA is significant, and pairs of conditions that differ after Holm-Bonferroni correction, with the mean angle of each condition over the range.'};

% -------------------------------------------------------------------------
% Figure 3: discrete EMG parameters
% -------------------------------------------------------------------------
T = table();
for im = 1:numel(MUS)
    for ic = 1:nCond
        for ip = 1:nPat
            T = [T; {PID{ip}, COND{ic}, MUSCLE(MUS{im}), round(D.disc.peakTime(ip, ic, im), 1), ...
                     round(D.disc.dur50(ip, ic, im), 1)}]; %#ok<AGROW>
        end
    end
end
T.Properties.VariableNames = {'Participant', 'Condition', 'Muscle', 'Peak timing (% cycle)', 'Activity duration (% cycle)'};
writeSheet(T, OUT_FILE, 'Fig3_values');
sheets(end+1, :) = {'Fig3_values', sprintf(['Figure 3. Peak timing and activity duration (time above minimum + %d %% of the range) ' ...
    'of each participant, condition and muscle (mean of the 3 trials).'], D.ACT_THRESHOLD)};

T = table();
for im = 1:numel(MUS)
    T = [T; discreteStats(D.disc.peakTime(:, :, im), D.stats(im).peakTime, 'Peak timing (% cycle)', MUSCLE(MUS{im}), pairA, pairB, COND)]; %#ok<AGROW>
    T = [T; discreteStats(D.disc.dur50(:, :, im), D.stats(im).dur50, 'Activity duration (% cycle)', MUSCLE(MUS{im}), pairA, pairB, COND)]; %#ok<AGROW>
end
writeSheet(T, OUT_FILE, 'Fig3_stats');
sheets(end+1, :) = {'Fig3_stats', 'Figure 3. Comparison between conditions for each muscle and parameter: ANOVA p-value, then the 21 pairs of conditions when the ANOVA is significant (p-value before and after Holm-Bonferroni correction).'};

% -------------------------------------------------------------------------
% Figure 4: kinematics x EMG coupling
% -------------------------------------------------------------------------
rows = {};
prof = cell(numel(MUS), 1);                  % prof{im}{ic} = (nPat, 101)
for im = 1:numel(MUS)
    prof{im} = cell(nCond, 1);
    for ic = 1:nCond
        Bk = E.patientBlocks.(matlab.lang.makeValidName(CRAW{ic})).(MUS{im});
        M = NaN(nPat, numel(x));
        for ip = 1:nPat
            B = Bk{ip};
            if ~isempty(B), M(ip, :) = mean(100 * B ./ max(B, [], 2), 1); end
            rows(end+1, :) = {PID{ip}, COND{ic}, MUSCLE(MUS{im}), x, round(M(ip, :)', 2)}; %#ok<SAGROW>
        end
        prof{im}{ic} = M;
    end
end
T = longTable(rows, {'Participant', 'Condition', 'Muscle', 'Cycle (%)', 'EMG (% of peak)'});
writeSheet(T, OUT_FILE, 'Fig4_profiles');
sheets(end+1, :) = {'Fig4_profiles', 'Figure 4, row 1. EMG envelope of each participant, condition and muscle, expressed as a percentage of the peak of each trial (mean of the 3 trials).'};

T = table();
for im = 1:numel(MUS)
    sp = P.spmPeak(im);
    for c = 1:size(sp.anovaClusters, 1)
        T = [T; {MUSCLE(MUS{im}), 'ANOVA (7 conditions)', "", "", round(sp.anovaClusters(c,1), 1), ...
                 round(sp.anovaClusters(c,2), 1), NaN, NaN, NaN, NaN, fmtP(sp.anovaClusters(c,3))}]; %#ok<AGROW>
    end
    for kp = find(sp.pairSig(:))'
        a = P.ALL_PAIRS(kp, 1); b = P.ALL_PAIRS(kp, 2);
        C = sp.pairClusters{kp};
        for c = 1:size(C, 1)
            [ma, sa] = windowMean(prof{im}{a}, x, C(c, 1:2));
            [mb, sb] = windowMean(prof{im}{b}, x, C(c, 1:2));
            T = [T; {MUSCLE(MUS{im}), 'Paired t-test (Holm)', string(COND{a}), string(COND{b}), round(C(c,1), 1), ...
                     round(C(c,2), 1), round(ma, 1), round(sa, 1), round(mb, 1), round(sb, 1), fmtP(C(c,3))}]; %#ok<AGROW>
        end
    end
end
T.Properties.VariableNames = {'Muscle', 'Test', 'Condition A', 'Condition B', 'Start (% cycle)', 'End (% cycle)', ...
    'Mean A (% of peak)', 'SD A', 'Mean B (% of peak)', 'SD B', 'p'};
writeSheet(T, OUT_FILE, 'Fig4_SPM');
sheets(end+1, :) = {'Fig4_SPM', 'Figure 4, row 1. SPM1D results on the peak-normalised EMG profiles: parts of the cycle where the ANOVA is significant, and pairs of conditions that differ after Holm-Bonferroni correction, with the mean value of each condition over the window. The lower trapezius has no significant result.'};

T = table();
for im = 1:numel(MUS)
    for ic = 1:nCond
        for ip = 1:nPat
            T = [T; {PID{ip}, COND{ic}, MUSCLE(MUS{im}), round(H.disc.riseTime(ip, ic), 1), ...
                     round(D.disc.peakTime(ip, ic, im), 1), round(D.disc.dur50(ip, ic, im), 1)}]; %#ok<AGROW>
        end
    end
end
T.Properties.VariableNames = {'Participant', 'Condition', 'Muscle', 'Humerothoracic rise time (% cycle)', ...
    'EMG peak timing (% cycle)', 'EMG activity duration (% cycle)'};
writeSheet(T, OUT_FILE, 'Fig4_scatter');
sheets(end+1, :) = {'Fig4_scatter', 'Figure 4, rows 2 and 3. Humerothoracic rise time and EMG peak timing and activity duration of each participant, condition and muscle (one dot of the figure per row).'};

T = table();
emgP = {'peakTime', 'Peak timing'; 'dur50', 'Activity duration'};
for im = 1:numel(MUS)
    for k = 1:2
        Y = D.disc.(emgP{k,1})(:, :, im);
        [r, p, df, slope] = rmCorr(H.disc.riseTime, Y);
        T = [T; {MUSCLE(MUS{im}), emgP{k,2}, 'Repeated-measures correlation', round(r, 2), fmtP(p), df, round(slope, 2), yesNo(p < 0.05)}]; %#ok<AGROW>
    end
end
% upper trapezius: same correlation after removing participant and condition means
imUT = find(strcmp(MUS, 'TRAPS'));
for k = 1:2
    [r, p, df] = residualCorr(H.disc.riseTime, D.disc.(emgP{k,1})(:, :, imUT));
    T = [T; {MUSCLE('TRAPS'), emgP{k,2}, 'Correlation after removing participant and condition means', ...
             round(r, 2), fmtP(p), df, NaN, yesNo(p < 0.05)}]; %#ok<AGROW>
end
T.Properties.VariableNames = {'Muscle', 'EMG parameter', 'Test', 'r', 'p', 'df', 'Slope', 'Significant'};
writeSheet(T, OUT_FILE, 'Fig4_correlations');
sheets(end+1, :) = {'Fig4_correlations', 'Figure 4, rows 2 and 3. Correlation between the humerothoracic rise time and each EMG parameter, within participants. Slope: change in the EMG parameter (% cycle) per 1 % cycle of rise time.'};

% -------------------------------------------------------------------------
% README (first sheet)
% -------------------------------------------------------------------------
info = {
 'Study',        'Effect of seven deltoid stimulation conditions on shoulder kinematics and scapular muscle activity during arm elevation in the scapular plane.';
 'Participants', sprintf('%d healthy participants (P01 to P%02d), 3 trials per condition. Each value is the mean of the 3 trials.', nPat, nPat);
 'Conditions',   strjoin(COND, ', ');
 'Muscles',      'Upper trapezius, middle trapezius, lower trapezius, serratus anterior.';
 'Units',        'Angles in degrees. Time in % of the movement cycle (0 = start, 100 = end). EMG in % of the peak of each trial.';
 'Statistics',   'Non-parametric repeated-measures ANOVA across the 7 conditions (10 000 permutations). If significant, paired t-tests on the 21 pairs of conditions with Holm-Bonferroni correction (alpha = 0.05). Curves were compared with SPM1D.';
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
    % ANOVA line, then the 21 pairs if the ANOVA is significant
    T = {muscleName, paramName, 'ANOVA (7 conditions)', "", "", NaN, NaN, NaN, NaN, fmtP(st.anova_p), "", yesNo(st.anova_sig)};
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

function [r, p, df] = residualCorr(X, Y)
    % correlation after removing the participant and the condition means
    xc = X - mean(X, 2, 'omitnan'); xc = xc - mean(xc, 1, 'omitnan');
    yc = Y - mean(Y, 2, 'omitnan'); yc = yc - mean(yc, 1, 'omitnan');
    ok = ~isnan(xc) & ~isnan(yc);
    r  = sum(xc(ok) .* yc(ok)) / sqrt(sum(xc(ok).^2) * sum(yc(ok).^2));
    df = sum(ok(:)) - size(X, 1) - size(X, 2) - 1;
    t  = r * sqrt(df / (1 - r^2));
    p  = betainc(df / (df + t^2), df / 2, 0.5);
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
