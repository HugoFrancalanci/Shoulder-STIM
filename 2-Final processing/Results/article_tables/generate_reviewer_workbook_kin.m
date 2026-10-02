% =========================================================================
% generate_reviewer_workbook_kin.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
% Date       :   October 2026
% -------------------------------------------------------------------------
% Description :  Builds Kinematics_SPM1D_results.xlsx — the reviewer
%                workbook summarising ALL kinematics results (glenohumeral
%                + scapulo-thoracic, _all_comp) : README (methods, sign
%                conventions), group RM-ANOVA clusters, the 126 group
%                post-hoc tests with the Holm-Bonferroni decision
%                recomputed by live Excel formulas (+ check against
%                MATLAB), significant group windows with window-averaged
%                angles (mean ± SD), individual windows, every individual
%                and group curve, and the non-interpretable zone
%                (humerothoracic elevation > 90 deg). Reads the two
%                kinematics caches only, no statistics rerun.
%                Steps : (1) export the caches to a temporary JSON file,
%                (2) build the formatted workbook with
%                build_reviewer_workbook_kin.py (Python + openpyxl),
%                (3) if Excel is installed, open / recalculate / save the
%                workbook so formula results are stored in the file (the
%                file also recalculates itself when opened in Excel).
% -------------------------------------------------------------------------
% Parameters :   PYTHON_EXE — Python executable (openpyxl required)
%                OUT_FILE   — output workbook
% Outputs    :   Kinematics_SPM1D_results.xlsx (Results/ folder)
% -------------------------------------------------------------------------
% Dependencies : cache_glenohumeral_all_comp.mat and
%                cache_scapulothoracic_all_comp.mat (Holm + EXCL_ZONE,
%                produced by extract_*_kinematics_all_comp.m),
%                build_reviewer_workbook_kin.py (same folder),
%                spm1dmatlab-master/, Python 3 + openpyxl, Excel (optional)
% =========================================================================

clear; clc;

PYTHON_EXE = 'python';

HERE = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(HERE, 'helpers'));  % dataDir() : dossier des donnees privees (caches, Excel)
SPM1D_PATH = fullfile(HERE, 'spm1dmatlab-master');
if exist(SPM1D_PATH, 'dir'), addpath(genpath(SPM1D_PATH)); end

OUT_FILE  = fullfile(dataDir(), 'Kinematics_results.xlsx');
BUILDER   = fullfile(fileparts(mfilename('fullpath')), 'build_reviewer_workbook_kin.py');
JSON_FILE = [tempname '.json'];

% -------------------------------------------------------------------------
% (1) EXPORT DES CACHES
% -------------------------------------------------------------------------
joints = {'Glenohumeral', 'cache_glenohumeral_all_comp.mat'; 'Scapulothoracic', 'cache_scapulothoracic_all_comp.mat'};
out = struct();
out.curves = {}; out.anova = {}; out.posthoc = {}; out.indiv = {}; out.zone = struct();
for j = 1:size(joints, 1)
    cacheFile = fullfile(dataDir(), joints{j,2});
    if ~isfile(cacheFile)
        error('Cache introuvable : %s (lance d''abord le script extract_*_all_comp.m correspondant)', cacheFile);
    end
    S  = load(cacheFile);
    jn = joints{j,1};
    if ~isfield(S, 'EXCL_ZONE') || ~isfield(S, 'POSTHOC_CORRECTION')
        error('%s est un ancien cache (sans Holm / zone d''exclusion) : relance le script extract_* correspondant.', cacheFile);
    end
    out.conditions = S.COND_LABELS;
    out.zone.(jn).windows     = S.EXCL_ZONE.windows;
    out.zone.(jn).threshold   = S.EXCL_ZONE.threshold;
    out.zone.(jn).htGroupMean = S.htGroupMean;
    out.zone.(jn).correction  = S.POSTHOC_CORRECTION;
    for idof = 1:numel(S.DOF_LABELS)
        % courbes individuelles (moyenne des blocs par patient)
        for ic = 1:numel(S.CONDITIONS_ORDERED)
            fld = matlab.lang.makeValidName(S.CONDITIONS_ORDERED{ic});
            for ip = 1:numel(S.PATIENT_IDS)
                out.curves{end+1} = struct('joint', jn, 'dof', S.DOF_LABELS{idof}, 'cond', S.COND_LABELS{ic}, ...
                                           'patient', S.PATIENT_IDS{ip}, 'y', S.patientMeans.(fld){ip}(idof,:)); %#ok<SAGROW>
            end
        end
        % ANOVA
        r = S.spmResults(idof);
        if r.anova_sig
            for c = 1:numel(r.anova_clusters)
                ep = r.anova_clusters{c}.endpoints;
                out.anova{end+1} = struct('joint', jn, 'dof', S.DOF_LABELS{idof}, 'sig', true, ...
                    'start', max(ep(1)-1,0), 'end', min(ep(2)-1,100), 'p', r.anova_clusters{c}.P); %#ok<SAGROW>
            end
        else
            out.anova{end+1} = struct('joint', jn, 'dof', S.DOF_LABELS{idof}, 'sig', false, 'start', NaN, 'end', NaN, 'p', NaN); %#ok<SAGROW>
        end
        % post-hoc : toutes les paires (+ fenetres individuelles)
        for kp = 1:size(S.ALL_PAIRS,1)
            cA = S.ALL_PAIRS{kp,1}; cB = S.ALL_PAIRS{kp,2};
            fld = matlab.lang.makeValidName(sprintf('%s_vs_%s', cA, cB));
            lblA = S.COND_LABELS{strcmp(S.CONDITIONS_ORDERED, cA)};
            lblB = S.COND_LABELS{strcmp(S.CONDITIONS_ORDERED, cB)};
            ph = struct();
            if isfield(r.posthoc, fld), ph = r.posthoc.(fld); end
            base = struct('joint', jn, 'dof', S.DOF_LABELS{idof}, 'condA', lblA, 'condB', lblB, ...
                          'tested', isfield(ph, 'p_holm'), 'p_test', NaN, 'alpha_holm', NaN, 'sig', false, ...
                          'start', NaN, 'end', NaN, 'p_cluster', NaN, 'nPatSig', 0, 'patSig', '');
            if isfield(ph, 'p_holm'), base.p_test = ph.p_holm; base.alpha_holm = ph.alpha_holm; end
            pats = {};
            if isfield(S.indivSigClusters{idof}, fld)
                pc = S.indivSigClusters{idof}.(fld);
                for ip = 1:numel(pc)
                    if ~isempty(pc{ip}), pats{end+1} = S.PATIENT_IDS{ip}; end %#ok<SAGROW>
                    for c = 1:numel(pc{ip})
                        ep = pc{ip}{c}.endpoints;
                        [mA, ~, mB, ~, d, ~] = winStats(S, cA, cB, idof, ep, ip);
                        out.indiv{end+1} = struct('joint', jn, 'dof', S.DOF_LABELS{idof}, 'patient', S.PATIENT_IDS{ip}, ...
                            'condA', lblA, 'condB', lblB, 'start', max(ep(1)-1,0), 'end', min(ep(2)-1,100), ...
                            'p_cluster', pc{ip}{c}.P, 'meanA', mA, 'meanB', mB, 'diff', d); %#ok<SAGROW>
                    end
                end
            end
            base.nPatSig = numel(pats); base.patSig = strjoin(pats, ', ');
            if isfield(ph, 'sig') && ph.sig
                for c = 1:numel(ph.clusters)
                    ep = ph.clusters{c}.endpoints;
                    row = base; row.sig = true;
                    row.start = max(ep(1)-1,0); row.end = min(ep(2)-1,100); row.p_cluster = ph.clusters{c}.P;
                    [row.meanA, row.sdA, row.meanB, row.sdB, row.diff, row.sdDiff] = winStats(S, cA, cB, idof, ep, []);
                    out.posthoc{end+1} = row; %#ok<SAGROW>
                end
            else
                row = base; row.meanA = NaN; row.sdA = NaN; row.meanB = NaN; row.sdB = NaN; row.diff = NaN; row.sdDiff = NaN;
                out.posthoc{end+1} = row; %#ok<SAGROW>
            end
        end
    end
end
fid = fopen(JSON_FILE, 'w', 'n', 'UTF-8'); fprintf(fid, '%s', jsonencode(out)); fclose(fid);

% -------------------------------------------------------------------------
% (2) CONSTRUCTION DU CLASSEUR (Python + openpyxl) et (3) RECALCUL EXCEL
% -------------------------------------------------------------------------
buildWorkbook(PYTHON_EXE, BUILDER, JSON_FILE, OUT_FILE);
delete(JSON_FILE);


% =========================================================================
% FONCTIONS LOCALES
% =========================================================================

function [mA, sA, mB, sB, d, sD] = winStats(S, cA, cB, idof, ep, ip)
    % Angle moyen sur la fenetre, par patient (meme definition que
    % groupWindowStats des generate_article_table_*.m : round(ep))
    idx1 = max(1, round(ep(1))); idx2 = min(101, round(ep(2)));
    stA = cat(3, S.patientMeans.(matlab.lang.makeValidName(cA)){:});
    stB = cat(3, S.patientMeans.(matlab.lang.makeValidName(cB)){:});
    wA = squeeze(mean(stA(idof, idx1:idx2, :), 2)); wB = squeeze(mean(stB(idof, idx1:idx2, :), 2));
    if ~isempty(ip), wA = wA(ip); wB = wB(ip); end
    dd = wB - wA;
    mA = mean(wA,'omitnan'); sA = std(wA,'omitnan'); mB = mean(wB,'omitnan'); sB = std(wB,'omitnan');
    d = mean(dd,'omitnan'); sD = std(dd,'omitnan');
end


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
