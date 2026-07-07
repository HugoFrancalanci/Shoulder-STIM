% =========================================================================
% compare_fes_nofes.m
% Comparaison signal EMG brut : No FES vs FES
% Objectif : identifier visuellement l'artefact FES dans les bursts de
%            mouvement pour choisir la methode de retrait adaptee.
% =========================================================================

clear; clc; close all;
run(fullfile(fileparts(mfilename('fullpath')), 'usercommands_conditions.m'));

% -------------------------------------------------------------------------
% CONFIGURATION -- ajuster selon le patient et la condition a inspecter
% -------------------------------------------------------------------------
PATIENT_ID = 'P001';
FES_COND   = 'Rehab';   % condition FES a comparer
BLOCK      = 1;
FS         = 2000;

% Fenetres de zoom (secondes) -- ajuster pour cibler un burst de mouvement
% Fig 2 : vue large du burst
ZOOM1_START = 6.0;
ZOOM1_DUR   = 5.0;

% Fig 3 : zoom fin pour voir les pulses individuels (~200ms)
ZOOM2_START = 7.0;
ZOOM2_DUR   = 5.0;

% -------------------------------------------------------------------------
% CHARGEMENT
% -------------------------------------------------------------------------
pnum    = str2double(PATIENT_ID(2:end));
matFile = fullfile(dataFolder, ['P' num2str(pnum) '.mat']);
load(matFile, 'Trial');

isA2 = false(1, length(Trial));
for i = 1:length(Trial)
    if isfield(Trial(i), 'task') && strcmp(Trial(i).task, 'ANALYTIC2'), isA2(i) = true; end
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

condList  = PATIENT_COND.(PATIENT_ID);
noFesSeq  = find(strcmp(condList.condition, 'No FES') & condList.block == BLOCK, 1);
fesSeq    = find(strcmp(condList.condition, FES_COND)  & condList.block == BLOCK, 1);
tNoFES    = Trial(allIdx(noFesSeq));
tFES      = Trial(allIdx(fesSeq));

fprintf('No FES : seq %d\n', noFesSeq);
fprintf('FES    : seq %d  (%s b%d)\n', fesSeq, FES_COND, BLOCK);

% Canaux EMG hors SYNCHRO
emgIdx = find(~strcmp({tFES.Emg.label}, 'SYNCHRO'));
nEmg   = length(emgIdx);

% Couleurs
COL_NOFES = [0.00 0.00 0.00];   % noir  = No FES
COL_FES   = [0.85 0.20 0.10];   % rouge = FES

% =========================================================================
% FIGURE 1 : Signal complet -- No FES (noir) vs FES (rouge)
% =========================================================================
figure('Name', sprintf('%s -- Signal complet No FES vs %s', PATIENT_ID, FES_COND), ...
       'units','normalized','outerposition',[0 0 1 1]);

for ji = 1:nEmg
    j   = emgIdx(ji);
    lbl = tFES.Emg(j).label;
    s0  = double(tNoFES.Emg(j).Signal.full(:));
    s1  = double(tFES.Emg(j).Signal.full(:));
    t0  = (0:length(s0)-1)/FS;
    t1  = (0:length(s1)-1)/FS;

    subplot(nEmg, 1, ji);
    plot(t0, s0, 'Color', COL_NOFES, 'LineWidth', 0.5); hold on;
    plot(t1, s1, 'Color', COL_FES,   'LineWidth', 0.5);
    title(lbl, 'FontSize', 9); ylabel('V'); grid on;
    if ji == 1
        legend({'No FES', sprintf('FES (%s b%d)', FES_COND, BLOCK)}, ...
               'Location','northeast');
    end
    if ji == nEmg, xlabel('Temps (s)'); end
end
sgtitle(sprintf('%s  --  Signal complet  --  No FES vs %s b%d', ...
        PATIENT_ID, FES_COND, BLOCK), 'FontSize', 12, 'FontWeight', 'bold');

% =========================================================================
% FIGURE 2 : Zoom burst de mouvement (ZOOM1)
% =========================================================================
figure('Name', sprintf('%s -- Zoom burst %.1f-%.1fs', PATIENT_ID, ZOOM1_START, ZOOM1_START+ZOOM1_DUR), ...
       'units','normalized','outerposition',[0 0 1 1]);

z1a = max(1, round(ZOOM1_START*FS));
z2a = min(round((ZOOM1_START+ZOOM1_DUR)*FS), round(min(length(double(tNoFES.Emg(emgIdx(1)).Signal.full(:))), ...
                                                        length(double(tFES.Emg(emgIdx(1)).Signal.full(:))))));
t_za = (0:z2a-z1a)/FS;

for ji = 1:nEmg
    j   = emgIdx(ji);
    lbl = tFES.Emg(j).label;
    s0  = double(tNoFES.Emg(j).Signal.full(:));
    s1  = double(tFES.Emg(j).Signal.full(:));

    subplot(nEmg, 1, ji);
    plot(t_za, s0(z1a:z1a+length(t_za)-1), 'Color', COL_NOFES, 'LineWidth', 0.7); hold on;
    plot(t_za, s1(z1a:z1a+length(t_za)-1), 'Color', COL_FES,   'LineWidth', 0.7);
    title(lbl, 'FontSize', 9); ylabel('V'); grid on;
    if ji == 1
        legend({'No FES', sprintf('FES (%s b%d)', FES_COND, BLOCK)}, 'Location','northeast');
    end
    if ji == nEmg, xlabel(sprintf('Temps relatif (s)  [signal original a %.1fs]', ZOOM1_START)); end
end
sgtitle(sprintf('%s  --  Zoom %.1f-%.1fs  --  No FES vs %s b%d', ...
        PATIENT_ID, ZOOM1_START, ZOOM1_START+ZOOM1_DUR, FES_COND, BLOCK), ...
        'FontSize', 12, 'FontWeight', 'bold');

% =========================================================================
% FIGURE 3 : Zoom fin (~200ms) pour voir les pulses individuels
% =========================================================================
figure('Name', sprintf('%s -- Zoom fin %.1f-%.1fs', PATIENT_ID, ZOOM2_START, ZOOM2_START+ZOOM2_DUR), ...
       'units','normalized','outerposition',[0 0 1 1]);

z1b = max(1, round(ZOOM2_START*FS));
z2b = min(round((ZOOM2_START+ZOOM2_DUR)*FS), round(min(length(double(tNoFES.Emg(emgIdx(1)).Signal.full(:))), ...
                                                        length(double(tFES.Emg(emgIdx(1)).Signal.full(:))))));
t_zb = (0:z2b-z1b)/FS * 1000; % en ms

for ji = 1:nEmg
    j   = emgIdx(ji);
    lbl = tFES.Emg(j).label;
    s0  = double(tNoFES.Emg(j).Signal.full(:));
    s1  = double(tFES.Emg(j).Signal.full(:));

    subplot(nEmg, 1, ji);
    plot(t_zb, s0(z1b:z1b+length(t_zb)-1), 'Color', COL_NOFES, 'LineWidth', 1.0); hold on;
    plot(t_zb, s1(z1b:z1b+length(t_zb)-1), 'Color', COL_FES,   'LineWidth', 1.0);
    title(lbl, 'FontSize', 9); ylabel('V'); grid on;
    if ji == 1
        legend({'No FES', sprintf('FES (%s b%d)', FES_COND, BLOCK)}, 'Location','northeast');
    end
    if ji == nEmg, xlabel('Temps (ms)'); end
end
sgtitle(sprintf('%s  --  Zoom fin %.0fms  --  No FES vs %s b%d  (chercher spikes periodiques en rouge)', ...
        PATIENT_ID, ZOOM2_DUR*1000, FES_COND, BLOCK), ...
        'FontSize', 12, 'FontWeight', 'bold');

fprintf('\nAjuster ZOOM1_START et ZOOM2_START pour cibler le burst de mouvement.\n');
fprintf('Fig 3 : si spikes rouges periodiques visibles -> artefact FES detectable.\n');
fprintf('        si signaux identiques -> pas d''artefact sur ce canal.\n');

% =========================================================================
% FIGURE 4 : Zoom fin 300ms pour TOUTES les conditions FES (canal TRAPS)
%            Objectif : verifier si la frequence d'artefact est constante
% =========================================================================
ALL_FES_COND = {'Min_fatigue','Min_stress','Random','Min_pw','Rehab','Min_force'};

% Canal de reference : TRAPS (le plus contamine)
refLabel = 'TRAPS';
noFesChIdx = find(strcmp({tNoFES.Emg.label}, refLabel), 1);
if isempty(noFesChIdx)
    % fallback : premier canal non-SYNCHRO
    noFesChIdx = emgIdx(1);
    refLabel = tNoFES.Emg(noFesChIdx).label;
end
s_nofes_ref = double(tNoFES.Emg(noFesChIdx).Signal.full(:));

nCond = length(ALL_FES_COND);
cols_cond = lines(nCond);  % couleurs distinctes par condition

figure('Name', sprintf('%s -- Zoom fin toutes conditions FES -- %s', PATIENT_ID, refLabel), ...
       'units','normalized','outerposition',[0 0 1 1]);

z1c = max(1, round(ZOOM2_START*FS));
t_zc = (0:round(ZOOM2_DUR*FS))/FS * 1000;  % en ms

for ci = 1:nCond
    cond = ALL_FES_COND{ci};
    seq  = find(strcmp(condList.condition, cond) & condList.block == BLOCK, 1);

    subplot(nCond, 1, ci);

    % Reference No FES (gris)
    nSamples = min(length(s_nofes_ref) - z1c + 1, length(t_zc));
    plot(t_zc(1:nSamples), s_nofes_ref(z1c:z1c+nSamples-1), ...
         'Color', [0.6 0.6 0.6], 'LineWidth', 0.8); hold on;

    if isempty(seq)
        title(sprintf('%s b%d  [ABSENT]', cond, BLOCK), 'FontSize', 8, 'Color', [0.5 0.5 0.5]);
    else
        tFES_ci   = Trial(allIdx(seq));
        chIdx_ci  = find(strcmp({tFES_ci.Emg.label}, refLabel), 1);
        if isempty(chIdx_ci)
            title(sprintf('%s b%d  [canal absent]', cond, BLOCK), 'FontSize', 8);
        else
            s_fes_ci = double(tFES_ci.Emg(chIdx_ci).Signal.full(:));
            nS2 = min(length(s_fes_ci) - z1c + 1, length(t_zc));
            plot(t_zc(1:nS2), s_fes_ci(z1c:z1c+nS2-1), ...
                 'Color', cols_cond(ci,:), 'LineWidth', 1.0);
            title(sprintf('%s b%d', cond, BLOCK), 'FontSize', 8);
        end
    end

    ylabel('V', 'FontSize', 7); grid on;
    if ci == 1
        legend({'No FES (ref)', cond}, 'Location','northeast', 'FontSize', 7);
    end
    if ci == nCond, xlabel('Temps (ms)'); end
    set(gca, 'FontSize', 7);
end

sgtitle(sprintf('%s  --  Zoom fin %.0fms  --  Toutes conditions FES  --  Canal: %s', ...
        PATIENT_ID, ZOOM2_DUR*1000, refLabel), ...
        'FontSize', 12, 'FontWeight', 'bold');

fprintf('Fig 4 : comparer la periode des spikes entre conditions (doit etre ~constante si meme frequence FES).\n');

% =========================================================================
% FIGURE 5 : Zoom ultra-fin (~50ms) sur un seul pulse FES
%            Objectif : mesurer la largeur exacte du spike pour choisir
%            la duree du blanking dans l'algorithme de retrait
% =========================================================================
% Parametres : ajuster PULSE_START pour centrer sur un spike visible
PULSE_START = 7.05;   % secondes -- pointer juste avant un spike de Rehab
PULSE_DUR   = 0.05;   % 50ms

% Utiliser la condition Rehab (la plus contaminee) comme reference
seqRehab = find(strcmp(condList.condition, 'Rehab') & condList.block == BLOCK, 1);
if isempty(seqRehab)
    % fallback sur la premiere condition FES disponible
    for ci = 1:length(ALL_FES_COND)
        seqRehab = find(strcmp(condList.condition, ALL_FES_COND{ci}) & condList.block == BLOCK, 1);
        if ~isempty(seqRehab), break; end
    end
end
tRef = Trial(allIdx(seqRehab));

z1p = max(1, round(PULSE_START * FS));
z2p = min(round((PULSE_START + PULSE_DUR) * FS), length(double(tRef.Emg(1).Signal.full(:))));
t_p = (0:z2p-z1p) / FS * 1000;  % en ms

figure('Name', sprintf('%s -- Pulse unique %.3f-%.3fs (Rehab)', PATIENT_ID, PULSE_START, PULSE_START+PULSE_DUR), ...
       'units','normalized','outerposition',[0 0 1 1]);

for ji = 1:nEmg
    j    = emgIdx(ji);
    lbl  = tRef.Emg(j).label;
    sig  = double(tRef.Emg(j).Signal.full(:));
    s0   = double(tNoFES.Emg(j).Signal.full(:));
    nS   = min(length(sig)-z1p+1, length(t_p));

    subplot(nEmg, 1, ji);
    plot(t_p(1:nS), s0(z1p:z1p+nS-1), 'Color', [0.6 0.6 0.6], 'LineWidth', 1.2); hold on;
    plot(t_p(1:nS), sig(z1p:z1p+nS-1), 'Color', COL_FES, 'LineWidth', 1.5);

    % Marquer le zero-crossing pour estimer la largeur visuellement
    yline(0, '--k', 'LineWidth', 0.5);
    title(lbl, 'FontSize', 9); ylabel('V'); grid on;
    if ji == 1
        legend({'No FES (ref)', 'FES Rehab'}, 'Location','northeast');
    end
    if ji == nEmg, xlabel('Temps (ms)'); end
end

sgtitle(sprintf('%s  --  Zoom pulse unique %.0fms  --  Rehab b%d  (mesurer largeur spike -> duree blanking)', ...
        PATIENT_ID, PULSE_DUR*1000, BLOCK), 'FontSize', 12, 'FontWeight', 'bold');

fprintf('Fig 5 : mesurer la largeur du spike (debut du pic positif -> retour a zero).\n');
fprintf('        Cette duree = duree du blanking a appliquer dans l''algorithme de retrait.\n');
fprintf('        Ajuster PULSE_START pour centrer sur un spike net.\n');
