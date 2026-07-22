% =========================================================================
% verify_fes_batch.m
% =========================================================================
% Author     :   H. Francalanci
%                Biomechanics and Translational Research in Surgery Group
%                University of Geneva
%                https://www.unige.ch/medecine/chiru/en/research-groups/nicolas-holzer-et-florent-moissenet
% License    :   Creative Commons Attribution-NonCommercial 4.0 International License
%                https://creativecommons.org/licenses/by-nc/4.0/legalcode
% Source code:   To be defined
% Reference  :   To be defined
% Date       :   July 2026
% -------------------------------------------------------------------------
% Description:   Batch quality-control script for FES artefact removal
%                across all patients. For each patient, produces two figures:
%                (A) FES mapping : full TRAPS signal for all 6 FES conditions
%                    overlaid (grey = No FES reference) — shows when FES is
%                    active across the trial and confirms artefact presence;
%                (B) Removal verification : 300ms zoom before/after artefact
%                    removal on the most contaminated trial (Rehab b1 if
%                    available, otherwise the first available FES condition).
%                Removal parameters are identical to preprocess_fes_removal.m
%                and extract_emg_cycles_noSEF.m (MAD×6, blanking 8ms, PCHIP).
% -------------------------------------------------------------------------
% Parameters :   BLANK_MS=8, MAD_FACTOR=6, MIN_PERIOD_MS=15, MAX_BLANK_MS=20
%                ZOOM_START=7.0s, ZOOM_DUR=0.3s
% Outputs    :   2 figures per patient (10 patients = 20 figures)
% -------------------------------------------------------------------------
% Dependencies : usercommands_conditions.m, K-LAB .mat files (P[n].mat)
% -------------------------------------------------------------------------
% This work is licensed under the Creative Commons Attribution -
% NonCommercial 4.0 International License. To view a copy of this license,
% visit http://creativecommons.org/licenses/by-nc/4.0/
% =========================================================================

clear; clc; close all;
run(fullfile(fileparts(mfilename('fullpath')), 'usercommands_conditions.m'));

% -------------------------------------------------------------------------
% PARAMETRES RETRAIT
% -------------------------------------------------------------------------
FS             = 2200;          % Hz (verifie via check_fs.m)
BLANK_MS       = 8;
MAD_FACTOR     = 6;
MIN_PERIOD_MS  = 15;
MAX_BLANK_MS   = 20;

% Fenetre pour la verification zoom
ZOOM_START     = 7.0;   % secondes -- ajuster si burst pas visible ici
ZOOM_DUR       = 0.3;   % 300ms

ALL_FES_COND   = {'Min_fatigue','Min_stress','Random','Min_pulse_width','Rehab','Min_force'};
REF_LABEL      = 'TRAPS';  % canal de reference pour le mapping
cols_cond      = lines(length(ALL_FES_COND));

% -------------------------------------------------------------------------
% BOUCLE PATIENTS
% -------------------------------------------------------------------------
for ip = 1:length(PATIENT_IDS)
    patientID = PATIENT_IDS{ip};
    pnum      = str2double(patientID(2:end));
    matFile   = fullfile(dataFolder, ['P' num2str(pnum) '.mat']);
    if ~isfile(matFile)
        fprintf('%s : fichier manquant, ignore.\n', patientID);
        continue;
    end

    load(matFile, 'Trial');
    fprintf('\n=== %s ===\n', patientID);

    % Filtrage ANALYTIC2
    isA2 = false(1, length(Trial));
    for i = 1:length(Trial)
        if isfield(Trial(i), 'task') && strcmp(Trial(i).task, 'ANALYTIC2')
            isA2(i) = true;
        end
    end
    allIdx = find(isA2);
    exc = []; skipFirst = 0; skipPos = [];
    if isfield(PATIENT_EXCEPTIONS, patientID)
        exc = PATIENT_EXCEPTIONS.(patientID);
        if isfield(exc, 'skipFirstN'),    skipFirst = exc.skipFirstN;    end
        if isfield(exc, 'skipPositions'), skipPos   = exc.skipPositions; end
    end
    allIdx = allIdx(skipFirst+1:end);
    if ~isempty(skipPos)
        keep = true(1, length(allIdx));
        keep(skipPos(skipPos <= length(allIdx))) = false;
        allIdx = allIdx(keep);
    end

    condList = PATIENT_COND.(patientID);

    % No FES reference (block 1)
    noFesSeq = find(strcmp(condList.condition, 'No FES') & condList.block == 1, 1);
    if isempty(noFesSeq)
        noFesSeq = find(strcmp(condList.condition, 'No FES'), 1);
    end
    tNoFES = Trial(allIdx(noFesSeq));
    refChIdx = find(strcmp({tNoFES.Emg.label}, REF_LABEL), 1);
    if isempty(refChIdx)
        refChIdx = find(~strcmp({tNoFES.Emg.label}, 'SYNCHRO'), 1);
        refLabelUsed = tNoFES.Emg(refChIdx).label;
    else
        refLabelUsed = REF_LABEL;
    end
    s_nofes = double(tNoFES.Emg(refChIdx).Signal.full(:));
    t_full  = (0:length(s_nofes)-1) / FS;

    % =====================================================================
    % FIGURE A : MAPPING FES (signal complet, toutes conditions, canal ref)
    % =====================================================================
    nCond = length(ALL_FES_COND);
    figA = figure('Name', sprintf('%s -- Mapping FES', patientID), ...
                  'units','normalized','outerposition',[0 0 1 1]);

    for ci = 1:nCond
        cond = ALL_FES_COND{ci};
        seq  = find(strcmp(condList.condition, cond) & condList.block == 1, 1);

        subplot(nCond, 1, ci);

        % Reference No FES (gris)
        plot(t_full, s_nofes, 'Color', [0.75 0.75 0.75], 'LineWidth', 0.4); hold on;

        if isempty(seq)
            title(sprintf('%s b1  [ABSENT]', cond), 'FontSize', 8, 'Color', [0.5 0.5 0.5]);
        else
            tC   = Trial(allIdx(seq));
            chC  = find(strcmp({tC.Emg.label}, refLabelUsed), 1);
            if isempty(chC)
                title(sprintf('%s b1  [canal absent]', cond), 'FontSize', 8);
            else
                sig_c = double(tC.Emg(chC).Signal.full(:));
                t_c   = (0:length(sig_c)-1) / FS;
                plot(t_c, sig_c, 'Color', cols_cond(ci,:), 'LineWidth', 0.5);

                % Detecter presence artefact (max > 3 x MAD de No FES)
                mad_ref = median(abs(s_nofes - median(s_nofes)));
                hasArt  = max(abs(sig_c)) > 3 * mad_ref * MAD_FACTOR;
                artStr  = '';
                if hasArt, artStr = '  [artefact detecte]'; end
                title(sprintf('%s b1%s', cond, artStr), 'FontSize', 8);
            end
        end

        ylabel('V', 'FontSize', 7); grid on;
        if ci == 1
            legend({'No FES (ref)', cond}, 'Location','northeast', 'FontSize', 7);
        end
        if ci == nCond, xlabel('Temps (s)'); end
        set(gca, 'FontSize', 7);
    end

    sgtitle(sprintf('%s  --  Mapping FES  --  Canal: %s  (gris=No FES, couleur=FES)', ...
            patientID, refLabelUsed), 'FontSize', 11, 'FontWeight', 'bold');

    % =====================================================================
    % FIGURE B : VERIFICATION RETRAIT -- condition la plus contaminee
    % =====================================================================

    % Choisir la condition a verifier : Rehab b1 si dispo, sinon premiere FES
    verifSeq = []; verifCond = '';
    priority = {'Rehab','Random','Min_fatigue','Min_stress','Min_pulse_width','Min_force'};
    for ci = 1:length(priority)
        s = find(strcmp(condList.condition, priority{ci}) & condList.block == 1, 1);
        if ~isempty(s), verifSeq = s; verifCond = priority{ci}; break; end
    end
    if isempty(verifSeq)
        fprintf('%s : aucune condition FES trouvee pour verification\n', patientID);
        continue;
    end

    tV    = Trial(allIdx(verifSeq));
    emgIdx = find(~strcmp({tV.Emg.label}, 'SYNCHRO'));
    nEmg  = length(emgIdx);

    z1v = max(1, round(ZOOM_START * FS));
    t_zv = (0:round(ZOOM_DUR*FS)) / FS * 1000;

    figB = figure('Name', sprintf('%s -- Verification retrait FES : %s b1', patientID, verifCond), ...
                  'units','normalized','outerposition',[0 0 1 1]);

    for ji = 1:nEmg
        j    = emgIdx(ji);
        lbl  = tV.Emg(j).label;
        sig  = double(tV.Emg(j).Signal.full(:));
        nS   = min(length(sig)-z1v+1, length(t_zv));

        cleaned = removeFESArtifact(sig, FS, BLANK_MS, MAD_FACTOR, MIN_PERIOD_MS, MAX_BLANK_MS);

        subplot(nEmg, 1, ji);
        plot(t_zv(1:nS), sig(z1v:z1v+nS-1),     'Color', [0.80 0.80 0.80], 'LineWidth', 1.0); hold on;
        plot(t_zv(1:nS), cleaned(z1v:z1v+nS-1), 'Color', [0.10 0.45 0.75], 'LineWidth', 1.2);
        title(lbl, 'FontSize', 9); ylabel('V'); grid on;
        if ji == 1
            legend({'Brut', 'Nettoye'}, 'Location','northeast');
        end
        if ji == nEmg, xlabel('Temps (ms)'); end
    end

    sgtitle(sprintf('%s  --  Zoom %.0fms  --  Retrait FES  --  %s b1  (gris=brut, bleu=nettoye)', ...
            patientID, ZOOM_DUR*1000, verifCond), 'FontSize', 11, 'FontWeight', 'bold');

    fprintf('%s : mapping + verification OK\n', patientID);
end

fprintf('\nTermine. Verifier Fig A (mapping) pour identifier les trials contamines.\n');
fprintf('Verifier Fig B (zoom) pour valider la qualite du retrait par patient.\n');
fprintf('Si retrait insuffisant sur un patient : ajuster MAD_FACTOR localement.\n');

% =========================================================================
% FONCTION LOCALE
% =========================================================================
function cleaned = removeFESArtifact(sig, fs, blank_ms, mad_factor, min_period_ms, max_blank_ms)
    sig = sig(:);
    n   = length(sig);
    blank_s     = round(blank_ms / 1000 * fs);
    min_dist    = round(min_period_ms / 1000 * fs);
    max_blank_s = round(max_blank_ms / 1000 * fs);

    mad_val = median(abs(sig - median(sig)));
    thresh  = mad_factor * mad_val;

    [~, locs_pos] = findpeaks( sig, 'MinPeakHeight', thresh, 'MinPeakDistance', min_dist);
    [~, locs_neg] = findpeaks(-sig, 'MinPeakHeight', thresh, 'MinPeakDistance', min_dist);
    locs = sort([locs_pos; locs_neg]);

    if length(locs) > 1
        merged = locs(1);
        for k = 2:length(locs)
            if locs(k) - merged(end) < min_dist
                merged(end) = round((merged(end) + locs(k)) / 2);
            else
                merged(end+1) = locs(k); %#ok<AGROW>
            end
        end
        locs = merged(:);
    end

    mask = true(n, 1);
    half = floor(blank_s / 2);
    for k = 1:length(locs)
        i1 = max(1, locs(k) - half);
        i2 = min(n, locs(k) + half);
        mask(i1:i2) = false;
    end

    cleaned     = sig;
    valid_idx   = find(mask);
    invalid_idx = find(~mask);
    if length(valid_idx) < 4 || isempty(invalid_idx), return; end

    breaks = [0; find(diff(invalid_idx) > 1); length(invalid_idx)];
    for b = 1:length(breaks)-1
        seg = invalid_idx(breaks(b)+1 : breaks(b+1));
        if length(seg) > max_blank_s, continue; end
        i1 = seg(1); i2 = seg(end);
        left  = valid_idx(valid_idx < i1);
        right = valid_idx(valid_idx > i2);
        if length(left) < 2 || length(right) < 2, continue; end
        left  = left(max(1,end-2):end);
        right = right(1:min(end,3));
        xi = [left; right];
        yi = sig(xi);
        xq = (i1:i2)';
        cleaned(xq) = interp1(xi, yi, xq, 'pchip');
    end
end
