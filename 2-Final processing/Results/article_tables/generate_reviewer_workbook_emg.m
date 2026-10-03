% =========================================================================
% generate_reviewer_workbook_emg.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   October 2026
% -------------------------------------------------------------------------
% Description :  Builds EMG_SPM1D_discrete_results.xlsx — the reviewer
%                workbook summarising ALL EMG amplitude results
%                (_all_comp) : README (signal processing, methods,
%                references), SPM1D group RM-ANOVA clusters, group post-hoc
%                tests with the Holm-Bonferroni decision recomputed by live
%                Excel formulas (+ check against MATLAB), individual SPM1D
%                windows, discrete parameters (RM-ANOVA, the 21 pairwise
%                comparisons per muscle x parameter with Holm decision by
%                formulas, mean ± SD per condition, every participant's
%                values) and every individual / group envelope. Reads the
%                EMG caches only, no statistics rerun.
%                Steps : (1) export the caches to a temporary JSON file,
%                (2) build the formatted workbook with
%                build_reviewer_workbook_emg.py (Python + openpyxl),
%                (3) if Excel is installed, open / recalculate / save the
%                workbook so formula results are stored in the file.
% -------------------------------------------------------------------------
% Parameters :   PYTHON_EXE — Python executable (openpyxl required)
%                OUT_FILE   — output workbook
% Outputs    :   EMG_SPM1D_discrete_results.xlsx (Results/ folder)
% -------------------------------------------------------------------------
% Dependencies : cache_emg_all_comp.mat (Holm, extract_emg_cycles_all_comp.m),
%                cache_emg_discrete_all_comp.mat (extract_emg_discrete_all_comp.m),
%                build_reviewer_workbook_emg.py (same folder),
%                spm1dmatlab-master/, Python 3 + openpyxl, Excel (optional)
% =========================================================================

clear; clc;

PYTHON_EXE = 'python';

HERE = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(HERE, 'helpers'));  % dataDir() : dossier des donnees privees (caches, Excel)
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end

OUT_FILE  = fullfile(dataDir(), 'Electromyography_results.xlsx');
BUILDER   = fullfile(fileparts(mfilename('fullpath')), 'build_reviewer_workbook_emg.py');
JSON_FILE = [tempname '.json'];

% -------------------------------------------------------------------------
% (1) EXPORT DES CACHES
% -------------------------------------------------------------------------
CACHE_EMG  = fullfile(dataDir(), 'cache_emg_all_comp.mat');
CACHE_DISC = fullfile(dataDir(), 'cache_emg_discrete_all_comp.mat');
if ~isfile(CACHE_EMG),  error('Cache introuvable : %s (lance extract_emg_cycles_all_comp.m)', CACHE_EMG); end
if ~isfile(CACHE_DISC), error('Cache introuvable : %s (lance extract_emg_discrete_all_comp.m)', CACHE_DISC); end
S = load(CACHE_EMG);
D = load(CACHE_DISC);
if ~isfield(S, 'POSTHOC_CORRECTION')
    error('%s est un ancien cache (Bonferroni) : relance extract_emg_cycles_all_comp.m.', CACHE_EMG);
end

% Libelles d'affichage des parametres discrets (memes que extract_emg_discrete_all_comp.m)
PARAM_LABELS = {'Peak amplitude (% baseline)', 'Peak timing (% cycle)', ...
                sprintf('Activity duration > %d%% (%% cycle)', D.ACT_THRESHOLD)};

MUS = containers.Map({'TRAPS','TRAPM','TRAPI','SERRA'}, ...
    {'Upper trapezius (UT)', 'Middle trapezius (MT)', 'Lower trapezius (LT)', 'Serratus anterior (SA)'});
out = struct('curves', {{}}, 'anova', {{}}, 'posthoc', {{}}, 'indiv', {{}}, ...
             'disc', {{}}, 'discAnova', {{}}, 'discPairs', {{}});
out.conditions = S.COND_LABELS;
out.correction = S.POSTHOC_CORRECTION;
out.threshold = D.ACT_THRESHOLD;
% Muscles rapportes dans l'article (les 4)
REPORT_MUSCLES = {'TRAPS', 'TRAPM', 'TRAPI', 'SERRA'};
for im = find(ismember(S.EMG_LABELS, REPORT_MUSCLES))
    m = S.EMG_LABELS{im}; mn = MUS(m);
    % courbes individuelles
    for ic = 1:numel(S.CONDITIONS_ORDERED)
        fld = matlab.lang.makeValidName(S.CONDITIONS_ORDERED{ic});
        for ip = 1:numel(S.PATIENT_IDS)
            out.curves{end+1} = struct('muscle', mn, 'cond', S.COND_LABELS{ic}, 'patient', S.PATIENT_IDS{ip}, ...
                                       'y', S.patientMeans.(fld).(m){ip}); %#ok<SAGROW>
        end
    end
    % SPM1D : ANOVA
    r = S.spmResults(im);
    if r.anova_sig
        for c = 1:numel(r.anova_clusters)
            ep = r.anova_clusters{c}.endpoints;
            out.anova{end+1} = struct('muscle', mn, 'sig', true, 'start', max(ep(1)-1,0), 'end', min(ep(2)-1,100), 'p', r.anova_clusters{c}.P); %#ok<SAGROW>
        end
    else
        out.anova{end+1} = struct('muscle', mn, 'sig', false, 'start', NaN, 'end', NaN, 'p', NaN); %#ok<SAGROW>
    end
    % SPM1D : post-hoc + fenetres individuelles
    for kp = 1:size(S.ALL_PAIRS,1)
        cA = S.ALL_PAIRS{kp,1}; cB = S.ALL_PAIRS{kp,2};
        fld = matlab.lang.makeValidName(sprintf('%s_vs_%s', cA, cB));
        lA = S.COND_LABELS{strcmp(S.CONDITIONS_ORDERED, cA)}; lB = S.COND_LABELS{strcmp(S.CONDITIONS_ORDERED, cB)};
        row = struct('muscle', mn, 'condA', lA, 'condB', lB, 'tested', false, 'p_test', NaN, 'alpha_holm', NaN, 'sig', false, ...
                     'nPatSig', 0, 'patSig', '');
        if isfield(r.posthoc, fld) && isfield(r.posthoc.(fld), 'p_holm')
            row.tested = true; row.p_test = r.posthoc.(fld).p_holm; row.alpha_holm = r.posthoc.(fld).alpha_holm;
            row.sig = r.posthoc.(fld).sig;
        end
        pats = {};
        pc = S.indivSigClusters{im}.(fld);
        for ip = 1:numel(pc)
            if isempty(pc{ip}), continue; end
            pats{end+1} = S.PATIENT_IDS{ip}; %#ok<SAGROW>
            for c = 1:numel(pc{ip})
                ep = pc{ip}{c}.endpoints;
                out.indiv{end+1} = struct('muscle', mn, 'patient', S.PATIENT_IDS{ip}, 'condA', lA, 'condB', lB, ...
                    'start', max(ep(1)-1,0), 'end', min(ep(2)-1,100), 'p_cluster', pc{ip}{c}.P); %#ok<SAGROW>
            end
        end
        row.nPatSig = numel(pats); row.patSig = strjoin(pats, ', ');
        out.posthoc{end+1} = row; %#ok<SAGROW>
    end
    % Parametres discrets
    allF = [D.PARAMS D.DESCR_ONLY];
    for ic = 1:numel(D.CONDITIONS_ORDERED)
        for ip = 1:numel(D.PATIENT_IDS)
            row = struct('muscle', mn, 'cond', D.COND_LABELS{ic}, 'patient', D.PATIENT_IDS{ip}, 'nBlocks', D.nBlocks(ip, ic, im));
            for k = 1:numel(allF), row.(allF{k}) = D.disc.(allF{k})(ip, ic, im); end
            out.disc{end+1} = row; %#ok<SAGROW>
        end
    end
    for k = 1:numel(D.PARAMS)
        st = D.stats(im).(D.PARAMS{k});
        out.discAnova{end+1} = struct('muscle', mn, 'param', D.PARAMS{k}, 'label', PARAM_LABELS{k}, ...
                                      'n', st.n, 'p', st.anova_p, 'sig', st.anova_sig); %#ok<SAGROW>
        for kp = 1:size(D.pairIdx,1)
            a = D.pairIdx(kp,1); b = D.pairIdx(kp,2);
            vA = D.disc.(D.PARAMS{k})(:, a, im); vB = D.disc.(D.PARAMS{k})(:, b, im);
            out.discPairs{end+1} = struct('muscle', mn, 'param', D.PARAMS{k}, 'label', PARAM_LABELS{k}, ...
                'condA', D.COND_LABELS{a}, 'condB', D.COND_LABELS{b}, ...
                'meanA', mean(vA,'omitnan'), 'sdA', std(vA,'omitnan'), 'meanB', mean(vB,'omitnan'), 'sdB', std(vB,'omitnan'), ...
                'meanDiff', st.meanDiff(kp), 'sdDiff', st.sdDiff(kp), 't', st.t(kp), 'p', st.p(kp), ...
                'pHolm', st.pHolm(kp), 'sig', st.sig(kp), 'anovaSig', st.anova_sig); %#ok<SAGROW>
        end
    end
end
out.discParams = D.PARAMS; out.discDescr = D.DESCR_ONLY; out.discLabels = PARAM_LABELS;
fid = fopen(JSON_FILE, 'w', 'n', 'UTF-8'); fprintf(fid, '%s', jsonencode(out)); fclose(fid);

% -------------------------------------------------------------------------
% (2) CONSTRUCTION DU CLASSEUR (Python + openpyxl) et (3) RECALCUL EXCEL
% -------------------------------------------------------------------------
buildWorkbook(PYTHON_EXE, BUILDER, JSON_FILE, OUT_FILE);
delete(JSON_FILE);


% =========================================================================
% FONCTIONS LOCALES
% =========================================================================

function buildWorkbook(pythonExe, builder, jsonFile, outFile)
    cmd = sprintf('"%s" "%s" "%s" "%s"', pythonExe, builder, jsonFile, outFile);
    [status, msg] = system(cmd);
    if status ~= 0
        error('Echec de la construction du classeur (Python + openpyxl requis) :\n%s', msg);
    end
    fprintf('%s', msg);
    % Recalcul + sauvegarde par Excel (valeurs des formules stockees dans
    % le fichier) — optionnel : le classeur se recalcule aussi a l'ouverture
    try
        xl = actxserver('Excel.Application');
        xl.Visible = false; xl.DisplayAlerts = false;
        wb = xl.Workbooks.Open(outFile);
        xl.CalculateFull();
        wb.Worksheets.Item(1).Activate();
        wb.Save(); wb.Close(false); xl.Quit(); delete(xl);
        fprintf('Classeur recalcule par Excel : %s\n', outFile);
    catch ME
        fprintf('Excel indisponible (%s) : les formules seront calculees a l''ouverture du fichier.\n', ME.message);
    end
end
