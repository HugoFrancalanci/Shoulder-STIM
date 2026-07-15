% =========================================================================
% preprocess_fes_removal.m
%
% VERIFICATION DU RETRAIT DE L'ARTEFACT FES — signal brut EMG
% ------------------------------------------------------------
% Methode : detection de pics + blanking + interpolation cubique
% Parametres identiques a extract_emg_cycles.m
%
% Principe :
%   1. DETECTION  : seuil adaptatif MAD_FACTOR x MAD(signal).
%                   Pics positifs ET negatifs (spike biphasique).
%                   Distance minimale entre pics = 15ms.
%
%   2. BLANKING   : fenetre BLANK_MS = 8ms centree sur chaque pic -> NaN.
%                   (spike ~4ms mesure, marge x2 pour le biphasique)
%
%   3. INTERPOLATION : reconstruction pchip sur 3 points voisins valides.
%                   Trous > MAX_BLANK_MS = 20ms non interpoles.
%
% Figures produites (boucle sur toutes les conditions FES) :
%   Pour chaque condition FES (VERIFY_BLOCK) — 2 figures :
%   - Signal complet : noir = No FES (ref), gris = brut, bleu = nettoye
%     ylim adapte aux signaux d'interet (artefacts exclus de l'echelle)
%   - Zoom 300ms    : pleine echelle — voir le retrait pulse par pulse
%   Soit 12 figures au total (6 conditions x 2).
%
% Limitations connues :
%   - P001 : 4 trials FES avec SYNCHRO inactif — detection directe sur EMG.
%   - Si pic musculaire > seuil : 8ms de signal reel efface (faux positif).
% =========================================================================

clear; clc; close all;
run(fullfile(fileparts(mfilename('fullpath')), 'usercommands_conditions.m'));

% -------------------------------------------------------------------------
% PARAMETRES
% -------------------------------------------------------------------------
PATIENT_ID     = 'P001';
FS             = 2200;          % Hz (verifie via check_fs.m)

BLANK_MS       = 8;             % ms a effacer autour de chaque pic
MAD_FACTOR     = 6;             % seuil = MAD_FACTOR x MAD(signal)
MIN_PERIOD_MS  = 15;            % espacement minimum entre deux pics (ms)
                                % (< periode FES ~22ms pour garder tous les pics)
MAX_BLANK_MS   = 20;            % si trou > MAX_BLANK_MS -> pas d'interpolation

% Trial FES a verifier et trial No FES de reference
VERIFY_COND    = 'Rehab';
VERIFY_BLOCK   = 1;
NOFES_COND     = 'No FES';
NOFES_BLOCK    = 1;

% -------------------------------------------------------------------------
% CHARGEMENT
% -------------------------------------------------------------------------
pnum    = str2double(PATIENT_ID(2:end));
% matFile = fullfile(dataFolder, ['P' num2str(pnum) '.mat']);
matFile = fullfile(dataFolder, 'P5.mat');
load(matFile, 'Trial');

isA2 = false(1, length(Trial));
for i = 1:length(Trial)
    if isfield(Trial(i), 'task') && strcmp(Trial(i).task, 'ANALYTIC2')
        isA2(i) = true;
    end
end
allIdx = find(isA2);
exc = []; skipFirst = 0; skipPos = [];
if isfield(PATIENT_EXCEPTIONS, PATIENT_ID)
    exc = PATIENT_EXCEPTIONS.(PATIENT_ID);
    if isfield(exc, 'skipFirstN'),    skipFirst = exc.skipFirstN;    end
    if isfield(exc, 'skipPositions'), skipPos   = exc.skipPositions; end
end
allIdx = allIdx(skipFirst+1:end);
if ~isempty(skipPos)
    keep = true(1, length(allIdx));
    keep(skipPos(skipPos <= length(allIdx))) = false;
    allIdx = allIdx(keep);
end

condList = PATIENT_COND.(PATIENT_ID);

% -------------------------------------------------------------------------
% FONCTIONS LOCALES
% -------------------------------------------------------------------------

function cleaned = removeFESArtifact(sig, fs, blank_ms, mad_factor, min_period_ms, max_blank_ms)
    % Retourne le signal avec artefacts FES retires par blanking+spline.
    sig = sig(:);
    n   = length(sig);
    blank_s  = round(blank_ms / 1000 * fs);
    min_dist = round(min_period_ms / 1000 * fs);
    max_blank_s = round(max_blank_ms / 1000 * fs);

    % Seuil adaptatif sur valeur absolue
    mad_val  = median(abs(sig - median(sig)));
    thresh   = mad_factor * mad_val;

    % Detection des pics positifs ET negatifs (spike biphasique)
    [~, locs_pos] = findpeaks( sig, 'MinPeakHeight', thresh, 'MinPeakDistance', min_dist);
    [~, locs_neg] = findpeaks(-sig, 'MinPeakHeight', thresh, 'MinPeakDistance', min_dist);
    locs = sort([locs_pos; locs_neg]);

    % Fusionner les pics trop proches (meme spike biphasique)
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

    % Blanking : mettre NaN autour de chaque pic
    mask = true(n, 1);
    half = floor(blank_s / 2);
    for k = 1:length(locs)
        i1 = max(1,   locs(k) - half);
        i2 = min(n,   locs(k) + half);
        mask(i1:i2) = false;
    end

    % Interpolation cubique sur les trous <= max_blank_s
    cleaned = sig;
    valid_idx = find(mask);
    if length(valid_idx) < 4, cleaned = sig; return; end

    % Trouver les segments de NaN
    invalid_idx = find(~mask);
    if isempty(invalid_idx), return; end

    % Grouper les indices invalides en segments continus
    breaks = [0; find(diff(invalid_idx) > 1); length(invalid_idx)];
    for b = 1:length(breaks)-1
        seg = invalid_idx(breaks(b)+1 : breaks(b+1));
        if length(seg) > max_blank_s, continue; end  % trou trop large -> ne pas interpoler
        i1 = seg(1); i2 = seg(end);
        % Points d'ancrage : 3 points valides de chaque cote
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

% -------------------------------------------------------------------------
% CHARGEMENT No FES (reference commune)
% -------------------------------------------------------------------------
seqN = find(strcmp(condList.condition, NOFES_COND) & condList.block == NOFES_BLOCK, 1);
if isempty(seqN)
    warning('Condition %s b%d introuvable pour %s — courbe de reference omise.', NOFES_COND, NOFES_BLOCK, PATIENT_ID);
    tN = [];
else
    tN = Trial(allIdx(seqN));
end
nofes_labels = {};
if ~isempty(tN), nofes_labels = {tN.Emg.label}; end

% -------------------------------------------------------------------------
% BOUCLE SUR TOUTES LES CONDITIONS FES
% -------------------------------------------------------------------------
ALL_FES_CONDS = {'Min_fatigue','Min_stress','Random','Min_pw','Rehab','Min_force'};
ZOOM_V_START  = 7.0;
ZOOM_V_DUR    = 0.3;

for ifc = 1:length(ALL_FES_CONDS)
    cur_cond = ALL_FES_CONDS{ifc};

    seqV = find(strcmp(condList.condition, cur_cond) & condList.block == VERIFY_BLOCK, 1);
    if isempty(seqV)
        fprintf('  [SKIP] %s b%d introuvable\n', cur_cond, VERIFY_BLOCK);
        continue;
    end
    tV     = Trial(allIdx(seqV));
    emgIdx = find(~strcmp({tV.Emg.label}, 'SYNCHRO'));
    nEmg   = length(emgIdx);

    % --- Figure signal complet ---
    figure('Name', sprintf('%s -- Retrait FES : %s b%d', PATIENT_ID, cur_cond, VERIFY_BLOCK), ...
           'units','normalized','outerposition',[0 0 1 1]);

    for ji = 1:nEmg
        j    = emgIdx(ji);
        lbl  = tV.Emg(j).label;
        sig  = double(tV.Emg(j).Signal.full(:));
        t_s  = (0:length(sig)-1) / FS;
        cleaned = removeFESArtifact(sig, FS, BLANK_MS, MAD_FACTOR, MIN_PERIOD_MS, MAX_BLANK_MS);

        subplot(nEmg, 1, ji); hold on;

        ref_vals = cleaned;
        if ~isempty(tN)
            jN = find(strcmp(nofes_labels, lbl), 1);
            if ~isempty(jN)
                sig_n = double(tN.Emg(jN).Signal.full(:));
                t_n   = (0:length(sig_n)-1) / FS;
                plot(t_n, sig_n, 'Color', [0.10 0.10 0.10], 'LineWidth', 0.6);
                ref_vals = [ref_vals; sig_n];
            end
        end

        plot(t_s, sig,     'Color', [0.88 0.88 0.88], 'LineWidth', 0.4);
        plot(t_s, cleaned, 'Color', [0.10 0.45 0.75], 'LineWidth', 0.9);

        y_lim = max(abs(ref_vals)) * 1.4;
        if y_lim > 0, ylim([-y_lim, y_lim]); end

        title(lbl, 'FontSize', 9); ylabel('V'); grid on;
        if ji == 1
            if ~isempty(tN)
                legend({'No FES', 'Brut (FES)', 'Nettoye (FES)'}, 'Location','northeast');
            else
                legend({'Brut', 'Nettoye'}, 'Location','northeast');
            end
        end
        if ji == nEmg, xlabel('Temps (s)'); end
    end

    sgtitle(sprintf('%s  --  %s b%d  (noir=No FES, gris=brut, bleu=nettoye)', ...
            PATIENT_ID, cur_cond, VERIFY_BLOCK), 'FontSize', 11, 'FontWeight', 'bold');

    % --- Figure zoom 300ms ---
    figure('Name', sprintf('%s -- Zoom : %s b%d', PATIENT_ID, cur_cond, VERIFY_BLOCK), ...
           'units','normalized','outerposition',[0 0 1 1]);

    z1v  = max(1, round(ZOOM_V_START * FS));
    t_zv = (0:round(ZOOM_V_DUR*FS)) / FS * 1000;

    for ji = 1:nEmg
        j    = emgIdx(ji);
        lbl  = tV.Emg(j).label;
        sig  = double(tV.Emg(j).Signal.full(:));
        cleaned = removeFESArtifact(sig, FS, BLANK_MS, MAD_FACTOR, MIN_PERIOD_MS, MAX_BLANK_MS);
        nS   = min(length(sig)-z1v+1, length(t_zv));

        subplot(nEmg, 1, ji); hold on;

        if ~isempty(tN)
            jN = find(strcmp(nofes_labels, lbl), 1);
            if ~isempty(jN)
                sig_n = double(tN.Emg(jN).Signal.full(:));
                if length(sig_n) >= z1v
                    nS_n = min(length(sig_n)-z1v+1, length(t_zv));
                    plot(t_zv(1:nS_n), sig_n(z1v:z1v+nS_n-1), 'Color', [0.10 0.10 0.10], 'LineWidth', 0.9);
                end
            end
        end

        plot(t_zv(1:nS), sig(z1v:z1v+nS-1),     'Color', [0.80 0.80 0.80], 'LineWidth', 1.0);
        plot(t_zv(1:nS), cleaned(z1v:z1v+nS-1), 'Color', [0.10 0.45 0.75], 'LineWidth', 1.4);

        title(lbl, 'FontSize', 9); ylabel('V'); grid on;
        if ji == 1
            if ~isempty(tN)
                legend({'No FES', 'Brut (FES)', 'Nettoye (FES)'}, 'Location','northeast');
            else
                legend({'Brut', 'Nettoye'}, 'Location','northeast');
            end
        end
        if ji == nEmg, xlabel('Temps (ms)'); end
    end

    sgtitle(sprintf('%s  --  Zoom 300ms  --  %s b%d', PATIENT_ID, cur_cond, VERIFY_BLOCK), ...
            'FontSize', 11, 'FontWeight', 'bold');

end % ifc

fprintf('\n--- Parametres utilises ---\n');
fprintf('  Blanking     : %d ms (%d samples)\n', BLANK_MS, round(BLANK_MS/1000*FS));
fprintf('  Seuil        : %.0f x MAD\n', MAD_FACTOR);
fprintf('  Dist. min    : %d ms entre pics\n', MIN_PERIOD_MS);
fprintf('  Max trou     : %d ms (au-dela = pas d''interpolation)\n', MAX_BLANK_MS);
fprintf('\nSi trop de signal efface : diminuer MAD_FACTOR ou augmenter MIN_PERIOD_MS.\n');
fprintf('Si des spikes restent     : diminuer MAD_FACTOR ou augmenter BLANK_MS.\n');
