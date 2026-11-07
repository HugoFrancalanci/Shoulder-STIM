% =========================================================================
% export_source_data.m
% =========================================================================
% Author      : H. Francalanci
%               Biomechanics and Translational Research in Surgery Group
%               University of Geneva
% License     : Creative Commons Attribution-NonCommercial 4.0 International
%               https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Date        : November 2026
% -------------------------------------------------------------------------
% Description : Exports the data and the statistical results of the article
%               to one Excel file (one sheet per table): the biomechanical
%               figure (scapulothoracic angles, EMG and their deviation from
%               No FES) and the thoracohumeral results reported in the text.
%               Conditions: No FES, Rehab and the four optimised patterns.
%               Reads the caches of the pipeline scripts; the statistics come
%               from nested_comparison.m and are not recomputed. Participants
%               are recoded P01 to P10.
% -------------------------------------------------------------------------
% Parameters  : OUT_FILE : output Excel file (in the data folder)
% Outputs     : Source_data_Figure5.xlsx
% -------------------------------------------------------------------------
% Dependencies: the caches of the pipeline (run steps 1 to 7 first),
%               helpers/dataDir.m
% =========================================================================

clear; clc; close all;
disp('=========================================');
disp(' export_source_data.m');
disp('=========================================');

HERE = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(HERE, 'helpers'));

OUT_FILE = fullfile(dataDir(), 'Source_data_Figure5.xlsx');
if isfile(OUT_FILE), delete(OUT_FILE); end

% -------------------------------------------------------------------------
% Caches
% -------------------------------------------------------------------------
H  = load(fullfile(dataDir(), 'cache_humerothoracic_all_comp.mat'), 'patientMeans', 'disc', 'x', ...
          'PATIENT_IDS', 'CONDITIONS_ORDERED', 'COND_LABELS');
RH = load(fullfile(dataDir(), 'cache_scapulohumeral_rhythm_all_comp.mat'), 'joints', 'ELEV_GRID');
EL = load(fullfile(dataDir(), 'cache_emg_elevation_all_comp.mat'), 'elevProf', 'ELEV_GRID', 'EMG_LABELS');
NC = load(fullfile(dataDir(), 'cache_nested_comparison.mat'), 'h4', 'emgDev', 'htCurve', 'htDisc', ...
          'OCP_CONDS', 'REF_COND', 'NOFES_COND');

CRAW = H.CONDITIONS_ORDERED;
SHOW = [{NC.NOFES_COND, NC.REF_COND}, NC.OCP_CONDS];            % conditions de l'article (ordre de la legende)
iShow = cellfun(@(c) find(strcmp(CRAW, c)), SHOW);
LAB  = H.COND_LABELS(iShow);
iNo  = strcmp(CRAW, NC.NOFES_COND); iRef = strcmp(CRAW, NC.REF_COND); isOCP = ismember(CRAW, NC.OCP_CONDS);
nPat = numel(H.PATIENT_IDS);
PID  = arrayfun(@(k) sprintf('P%02d', str2double(H.PATIENT_IDS{k}(2:end))), 1:nPat, 'UniformOutput', false);
MUSCLE = containers.Map({'TRAPS','TRAPM','TRAPI','SERRA'}, ...
    {'Upper trapezius', 'Middle trapezius', 'Lower trapezius', 'Serratus anterior'});
MUS  = EL.EMG_LABELS;
OCP_LABEL = 'Optimised (mean)';
sheets = {};   % {name, description} for the README

% -------------------------------------------------------------------------
% Figure 5, rows 1 and 2: scapulothoracic angles and deviation from No FES
% -------------------------------------------------------------------------
J = RH.joints{cellfun(@(j) strcmp(j.name, 'Scapulothoracic'), RH.joints)};
grid = RH.ELEV_GRID(:);
nDof = numel(J.DOF_LABELS);
st = cell(numel(CRAW), nDof);                 % st{ic,id} = (nPat, nGrid)
for ic = 1:numel(CRAW)
    R = J.rhythmMeans.(matlab.lang.makeValidName(CRAW{ic}));
    for id = 1:nDof
        st{ic, id} = cell2mat(cellfun(@(r) r(id, :), R(:), 'UniformOutput', false));
    end
end
keepP = true(nPat, 1);   % courbes completes dans toutes les conditions de l'article
for q = 1:numel(st(iShow, :))
    S = st(iShow, :); keepP = keepP & all(~isnan(S{q}), 2);
end
dofNames = strcat(J.DOF_LABELS, ' (deg)');

rows = {};
for k = 1:numel(iShow)
    for ip = find(keepP)'
        rows(end+1, :) = [{PID{ip}, LAB{k}, grid}, arrayfun(@(id) round(st{iShow(k), id}(ip, :)', 2), ...
                          1:nDof, 'UniformOutput', false)]; %#ok<SAGROW>
    end
end
writeSheet(longTable(rows, [{'Participant', 'Condition', 'Thoracohumeral elevation (deg)'}, dofNames]), OUT_FILE, 'Fig5_ST_angles');
sheets(end+1, :) = {'Fig5_ST_angles', ['Figure 5, first row. Scapulothoracic angles of each participant and condition at each ' ...
    'thoracohumeral elevation from 20 to 90 deg (ascending phase).']};

rows = {};
for ip = find(keepP)'
    devR = arrayfun(@(id) round(abs(st{iRef, id}(ip, :) - st{iNo, id}(ip, :))', 2), 1:nDof, 'UniformOutput', false);
    devO = arrayfun(@(id) round(ocpDeviation(st(isOCP, id), st{iNo, id}, ip), 2), 1:nDof, 'UniformOutput', false);
    rows(end+1, :) = [{PID{ip}, NC.REF_COND, grid}, devR]; %#ok<SAGROW>
    rows(end+1, :) = [{PID{ip}, OCP_LABEL, grid}, devO]; %#ok<SAGROW>
end
writeSheet(longTable(rows, [{'Participant', 'Pattern', 'Thoracohumeral elevation (deg)'}, dofNames]), OUT_FILE, 'Fig5_ST_deviation');
sheets(end+1, :) = {'Fig5_ST_deviation', ['Figure 5, second row. Absolute deviation of each scapulothoracic angle from No FES, ' ...
    'for Rehab and for the mean of the four optimised patterns (deviation of each pattern, then mean).']};

writeSheet(curveStats(NC.h4, 'Deviation from No FES (deg)'), OUT_FILE, 'Fig5_ST_stats');
sheets(end+1, :) = {'Fig5_ST_stats', ['Figure 5, second row. Hypothesis test for each angle: deviation from No FES of Rehab vs ' ...
    'mean of the optimised patterns. p-value of the curve, p-value after Holm-Bonferroni correction across the 3 angles, ' ...
    'elevation ranges that differ, and mean values over each range. Signed difference with No FES: + = more than No FES.']};

% -------------------------------------------------------------------------
% Figure 5, rows 3 and 4: EMG and deviation from No FES
% -------------------------------------------------------------------------
gridE = EL.ELEV_GRID(:);
keepE = all(cell2mat(cellfun(@(P) all(~isnan(cat(2, P{iShow})), 2), EL.elevProf, 'UniformOutput', false)), 2);
rows = {};
for im = 1:numel(MUS)
    for k = 1:numel(iShow)
        for ip = find(keepE)'
            rows(end+1, :) = {PID{ip}, LAB{k}, MUSCLE(MUS{im}), gridE, round(EL.elevProf{im}{iShow(k)}(ip, :)', 2)}; %#ok<SAGROW>
        end
    end
end
writeSheet(longTable(rows, {'Participant', 'Condition', 'Muscle', 'Thoracohumeral elevation (deg)', 'EMG (% of peak)'}), ...
           OUT_FILE, 'Fig5_EMG');
sheets(end+1, :) = {'Fig5_EMG', ['Figure 5, third row. EMG envelope of each participant, condition and muscle, expressed as a ' ...
    'percentage of the peak of each trial (mean of the 3 trials), at each thoracohumeral elevation from 20 to 90 deg ' ...
    '(ascending phase).']};

rows = {};
for im = 1:numel(MUS)
    P = EL.elevProf{im};
    for ip = find(keepE)'
        rows(end+1, :) = {PID{ip}, NC.REF_COND, MUSCLE(MUS{im}), gridE, round(abs(P{iRef}(ip, :) - P{iNo}(ip, :))', 2)}; %#ok<SAGROW>
        rows(end+1, :) = {PID{ip}, OCP_LABEL, MUSCLE(MUS{im}), gridE, round(ocpDeviation(P(isOCP), P{iNo}, ip), 2)}; %#ok<SAGROW>
    end
end
writeSheet(longTable(rows, {'Participant', 'Pattern', 'Muscle', 'Thoracohumeral elevation (deg)', 'Deviation from No FES (% of peak)'}), ...
           OUT_FILE, 'Fig5_EMG_deviation');
sheets(end+1, :) = {'Fig5_EMG_deviation', ['Figure 5, fourth row. Absolute deviation of the EMG envelope from No FES, for Rehab ' ...
    'and for the mean of the four optimised patterns (deviation of each pattern, then mean).']};

writeSheet(emgStats(NC.emgDev, 'Deviation from No FES (% of peak)'), OUT_FILE, 'Fig5_EMG_stats');
sheets(end+1, :) = {'Fig5_EMG_stats', ['Figure 5, fourth row (exploratory). For each muscle, deviation from No FES of Rehab vs ' ...
    'mean of the optimised patterns. p-value of the curve, p-value after Holm-Bonferroni correction across the 4 muscles, ' ...
    'elevation ranges that differ, and mean values over each range.']};

% -------------------------------------------------------------------------
% Thoracohumeral elevation (reported in the text)
% -------------------------------------------------------------------------
x = H.x(:);
rows = {};
for k = 1:numel(iShow)
    Y = cat(1, H.patientMeans.(matlab.lang.makeValidName(CRAW{iShow(k)})){:});
    for ip = 1:nPat
        rows(end+1, :) = {PID{ip}, LAB{k}, x, round(Y(ip, :)', 2)}; %#ok<SAGROW>
    end
end
writeSheet(longTable(rows, {'Participant', 'Condition', 'Cycle (%)', 'Elevation (deg)'}), OUT_FILE, 'TH_curves');
sheets(end+1, :) = {'TH_curves', 'Text. Thoracohumeral elevation of each participant and condition over the movement cycle (mean of the 3 trials).'};

T = table();
for k = 1:numel(iShow)
    for ip = 1:nPat
        T = [T; {PID{ip}, string(LAB{k}), round(H.disc.peakElev(ip, iShow(k)), 1), round(H.disc.peakTime(ip, iShow(k)), 1), ...
                 round(H.disc.planeMean2090(ip, iShow(k)), 1)}]; %#ok<AGROW>
    end
end
for ip = 1:nPat
    T = [T; {PID{ip}, string(OCP_LABEL), round(mean(H.disc.peakElev(ip, isOCP)), 1), round(mean(H.disc.peakTime(ip, isOCP)), 1), ...
             round(mean(H.disc.planeMean2090(ip, isOCP)), 1)}]; %#ok<AGROW>
end
T.Properties.VariableNames = {'Participant', 'Condition', 'Peak elevation (deg)', 'Peak timing (% cycle)', ...
    'Mean plane of elevation 20-90 deg (deg)'};
writeSheet(T, OUT_FILE, 'TH_parameters');
sheets(end+1, :) = {'TH_parameters', ['Text. Peak elevation, peak timing and mean plane of elevation between 20 and 90 deg of ' ...
    'elevation (ascending phase) of each participant and condition, and their mean over the four optimised patterns. ' ...
    'Plane of elevation: 0 deg = frontal plane, + = anterior.']};

c = NC.htCurve;
T = table("Elevation curve", "Rehab vs optimised (mean)", fmtP(c.pTest), "", rangeText(c, '%'), ...
          'VariableNames', {'Outcome', 'Contrast', 'p', 'p (Holm)', 'Ranges that differ'});
for k = 1:numel(NC.htDisc)
    r = NC.htDisc(k);
    vals = {r.ref, r.ocp; r.ref, r.nofes; r.ocp, r.nofes};
    for q = 1:3
        T = [T; {string(r.label), string(strrep(r.contrasts{q}, 'OCP', 'optimised (mean)')), fmtP(r.p(q)), fmtP(r.pHolm(q)), ...
                 string(sprintf('%.1f ± %.1f vs %.1f ± %.1f', mean(vals{q,1}), std(vals{q,1}), mean(vals{q,2}), std(vals{q,2})))}]; %#ok<AGROW>
    end
end
T.Properties.VariableNames{end} = 'Ranges that differ / mean ± SD (A vs B)';
writeSheet(T, OUT_FILE, 'TH_stats');
sheets(end+1, :) = {'TH_stats', ['Text. Elevation curve: Rehab vs mean of the optimised patterns (single test). Discrete parameters: ' ...
    'three contrasts, p-values adjusted with Holm-Bonferroni across the 3 contrasts of each parameter.']};

% -------------------------------------------------------------------------
% README (first sheet)
% -------------------------------------------------------------------------
info = {
 'Study',        'Effect of deltoid stimulation patterns on shoulder kinematics and scapular muscle activity during arm elevation in the scapular plane.';
 'Participants', sprintf('%d healthy participants (P01 to P%02d), 3 trials per condition. Each value is the mean of the 3 trials.', nPat, nPat);
 'Conditions',   [strjoin(LAB, ', ') '. Optimised (mean): mean of the four optimised patterns for each participant.'];
 'Muscles',      'Upper trapezius, middle trapezius, lower trapezius, serratus anterior.';
 'Units',        'Angles and thoracohumeral elevation in degrees. Time in % of the movement cycle (0 = start, 100 = end). EMG in % of the peak of each trial.';
 'Statistics',   ['Rehab compared with the mean of the four optimised patterns, and with No FES for the thoracohumeral parameters. ' ...
                  'Paired, two-tailed tests with all sign permutations: SPM1D t-test for curves (one p-value per curve, from the ' ...
                  'maximum |t|), t-test for discrete values. Holm-Bonferroni correction (alpha = 0.05) across the 3 angles, ' ...
                  'across the 4 muscles, and across the 3 contrasts of each thoracohumeral parameter.'];
 'Values',       'Mean and SD are given across participants.';
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

function T = curveStats(C, valueName)
    % One line per significant range (or one line if none): curve p-values,
    % range, mean values of Rehab and of the optimised patterns, signed
    % differences with No FES
    T = table();
    for k = 1:numel(C)
        c = C(k);
        if ~c.sig || isempty(c.clusters)
            T = [T; {string(c.label), fmtP(c.pTest), fmtP(c.pHolm), "No", NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}]; %#ok<AGROW>
            continue;
        end
        for r = 1:size(c.clusters, 1)
            v = num2cell(round(c.clusters(r, :), 1));
            T = [T; [{string(c.label), fmtP(c.pTest), fmtP(c.pHolm), "Yes"}, v]]; %#ok<AGROW>
        end
    end
    unit = regexp(valueName, '\(.*\)', 'match', 'once');
    T.Properties.VariableNames = {'Curve', 'p', 'p (Holm)', 'Significant', 'Start (deg elevation)', 'End (deg elevation)', ...
        ['Rehab, ' valueName], 'Rehab SD', ['Optimised, ' valueName], 'Optimised SD', ...
        ['Rehab - No FES, signed ' unit], ['Optimised - No FES, signed ' unit]};
end

function T = emgStats(C, outcome)
    T = curveStats(C, 'value (% of peak)');
    T = addvars(T, repmat(string(outcome), height(T), 1), 'Before', 1, 'NewVariableNames', 'Outcome');
    T.Properties.VariableNames{2} = 'Muscle';
end

function d = ocpDeviation(Yocp, yNo, ip)
    % Ecart absolu a No FES de chaque patron optimise, puis moyenne (colonne)
    M = cell2mat(cellfun(@(y) y(ip, :), Yocp(:), 'UniformOutput', false));   % (nOCP, nGrid)
    d = mean(abs(M - yNo(ip, :)), 1)';
end

function s = rangeText(c, unit)
    if ~c.sig || isempty(c.clusters), s = "None"; return; end
    s = strjoin(arrayfun(@(r) sprintf('%.1f-%.1f %s (Rehab %.1f ± %.1f vs optimised %.1f ± %.1f deg)', ...
                c.clusters(r, 1), c.clusters(r, 2), unit, c.clusters(r, 3:6)), 1:size(c.clusters, 1), 'UniformOutput', false), '; ');
    s = string(s);
end

function s = fmtP(p)
    if isnan(p), s = ""; elseif p < 0.001, s = "< 0.001"; else, s = string(sprintf('%.3f', p)); end
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
