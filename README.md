% -------------------------------------------------------------------------
% CHANGEMENTS PAR RAPPORT A LA TOOLBOX ORIGINALE
% -------------------------------------------------------------------------
%
% 1. EMG — Nouveau mapping des canaux (userCommands.txt)
%    emgSet = {
%      'CH1_EMG_1', 'TRAPS';    % Trapèze supérieur
%      'CH2_EMG_1', 'TRAPM';    % Trapèze moyen
%      'CH3_EMG_1', 'TRAPI';    % Trapèze inférieur
%      'CH4_EMG_1', 'SYNCHRO';  % Canal de synchronisation
%      'CH7_EMG_1', 'SERRA';    % Dentelé antérieur
%    }
%
% 2. TRIALS — Seulement ANALYTIC2 (21 mouvements d'élévation coronale)
%    trialOrder = {'CALIBRATION3','CALIBRATION1','CALIBRATION2',
%                  'CALIBRATION4','CALIBRATION5','CALIBRATION6','ANALYTIC2'}
%
% 3. MAIN_Protocol_01 — Modifications
%    - ImportSessionData supprimé (données simplifiées hardcodées)
%    - Session.markerHeight1 = 0.0095 m (hardcodé)
%    - Session.markerHeight2 = 0.0140 m (hardcodé)
%    - MAIN_Preprocessing_toolbox appelé avec strings fixes ('P1','S1',...)
%    - ProcessVideos commenté (ffmpeg non installé)
%    - InitialiseForceSignals commenté (pas de capteur force)
%    - UpdateC3DFile commenté (non nécessaire)
%    - GenerateReport commenté (non nécessaire)
%    - Save simplifié : 'P1-S1-YYYYMMDD.mat'
%
% -------------------------------------------------------------------------
% PROCÉDÉ À SUIVRE
% -------------------------------------------------------------------------
%
% ÉTAPE 1 — Préparer le dossier patient
%   - Créer un dossier patient avec sous-dossier \Raw\ contenant les C3D
%   - Placer Session.xlsx dans le dossier patient
%   - Vérifier userCommands.txt dans le dossier preprocessing
%
% ÉTAPE 2 — Lancer MAIN_Protocol_01.m
%   - Sélectionner le dossier patient via GUI (uigetdir)
%   - Renseigner le côté : R ou L (une seule fois)
%   - Le preprocessing EMG/marqueurs se lance automatiquement
%
% ÉTAPE 3 — Découpage cinématique (automatique + validation)
%   Pour chaque trial ANALYTIC2 :
%   - Premier trial uniquement : une figure s'ouvre avec le signal
%     cinématique, saisir le seuil de détection en degrés (défaut : 30°)
%     Ce seuil est conservé pour tous les trials suivants
%   - Une figure s'ouvre avec les 3 cycles détectés (zones vertes)
%   - Entrée = valider  |  m + Entrée = mode manuel (6 clics)
%   Total cas nominal : 1 saisie seuil + 21 × 1 Entrée
%
% ÉTAPE 4 — Vérification EMG (automatique + validation visuelle)
%   Pour chaque canal EMG (TRAPS, TRAPM, TRAPI, SYNCHRO, SERRA) :
%   - Traitement automatique (filtre, rectification, enveloppe, normalisation)
%   - Une figure s'ouvreavec le signal et les fenêtres de cycles en vert
%   - Entrée pour passer au canal suivant
%   Total : 21 × 5 × 1 Entrée = 105 frappes (vs 525 clics originaux)
%
% ÉTAPE 5 — Résultats
%   - Fichier .mat sauvegardé dans le dossier patient
%     Nom : P1-S1-YYYYMMDD.mat
%   - Contient : Trial, Session, Folder
%
% -------------------------------------------------------------------------
% MISE A JOUR — Gestion EMG (CutCycles, suppression OnsetDetection)
% -------------------------------------------------------------------------
%
% Objectif :
%   Supprimer toute interaction manuelle liée à l'EMG. Seul le découpage
%   des cycles cinématiques reste manuel en fallback (m dans CutCycles).
%   Une vérification visuelle par canal est conservée (Entrée pour valider).
%
% Modifications apportées :
%
% 1. OnsetDetection.m — PLUS UTILISÉE
%    - Fonction supprimée du workflow
%    - Plus aucun appel depuis CutCycles
%
% 2. detectCycles.m — NOUVELLE FONCTION
%    - Détection automatique des cycles par passage de seuil (défaut 30°)
%    - Seuil demandé en console au premier trial, conservé pour les suivants
%    - Validation visuelle : Entrée = valider | m = mode manuel (6 clics)
%    - Côté non choisi : copie directe des ranges du côté choisi
%
% 3. CutCycles.m — Signature mise à jour
%    function [Trial, threshold] = CutCycles(c3dFiles, Trial, btype, side, threshold)
%    - side      : 'R' ou 'L', défini une fois dans MAIN_Protocol_01
%    - threshold : [] au premier trial, retourné et réutilisé ensuite
%
%    Dans MAIN_Protocol_01 :
%        side      = input('Côté opéré (R/L) : ', 's');
%        threshold = [];
%        for i = ... (boucle trials)
%            [Trial(k), threshold] = CutCycles(c3dFiles(i), Trial(k), btype, side, threshold);
%        end
%
% 4. CutCycles.m — Bloc EMG réécrit
%    Prétraitement automatique :
%    - Suppression outliers (5 SD)
%    - Filtre passe-bande Butterworth ordre 1 (10-500 Hz) + rectification
%    - Enveloppe RMS (fenêtre 20 ms, pas 10 ms)
%    - Enveloppe lissée gaussienne (fenêtre 100 ms)
%    - Baseline : 50 premières frames cinématiques, normFactor = mean + 3 SD
%
% 5. CutCycles.m — Vérification visuelle EMG 
%    Pour chaque canal, figure plein écran avec :
%    - Gris    : signal brut
%    - Bleu    : signal filtré rectifié
%    - Vert    : enveloppe RMS
%    - Magenta : enveloppe lissée (= signal découpé)
%    - Rouge   : seuil baseline (mean + 3 SD des 50 premières frames)
%    - Vert semi-transparent : fenêtres des cycles cinématiques
%    → Entrée pour passer au canal suivant
%
% -------------------------------------------------------------------------
% STRUCTURE DE SORTIE PAR CANAL EMG
% -------------------------------------------------------------------------
%
%   Trial.Emg(iemg).Signal.full                    → brut C3D, trial complet
%   Trial.Emg(iemg).Signal.envelop                 → enveloppe normalisée, trial complet
%   Trial.Emg(iemg).Signal.cycle.raw               → brut (outliers supprimés), 101 pts × N cycles
%   Trial.Emg(iemg).Signal.cycle.filtered          → filtré 10-500 Hz, 101 pts × N cycles
%   Trial.Emg(iemg).Signal.cycle.rectified         → rectifié, 101 pts × N cycles
%   Trial.Emg(iemg).Signal.cycle.rms               → enveloppe RMS, 101 pts × N cycles
%   Trial.Emg(iemg).Signal.cycle.envelop           → enveloppe gaussienne 100 ms, 101 pts × N cycles
%   Trial.Emg(iemg).Signal.cycle.normalized        → normalisée par baseline, 101 pts × N cycles
%
% -------------------------------------------------------------------------
% MISE A JOUR — Gestion EMG (InitialiseEmgSignals)
% -------------------------------------------------------------------------
%
% Problème identifié :
%   Les fichiers C3D preprocessés renomment les canaux EMG
%   (CH1_EMG_1 -> TRAPS, etc.) — InitialiseEmgSignals cherchait
%   la colonne 1 (CH1_EMG_1) au lieu de la colonne 2 (TRAPS).
%
% Corrections apportées :
%
% 1. InitialiseEmgSignals.m
%    - Remplacer EmgSet{iemg,1} par EmgSet{iemg,2} dans les isfield
%      et les accès Emg.() — dans les deux blocs CALIBRATION3 et ANALYTIC
%    - Le label EmgSet{iemg,2} pour Trial.Emg(iemg).label reste inchangé
%
% 2. InitialiseEMGSignals.m (preprocessing)
%    - Supprimer le bloc elseif qui supposait un nombre pair de canaux
%    - Remplacer par une boucle simple sur tous les canaux
%
% 3. MAIN_Protocol_01.m
%    - Appel InitialiseEmgSignals avec Analog (btkGetAnalogs)
%    - CALIBRATION3 : Trial(k) = InitialiseEmgSignals(emgSet,Trial(k),[],Analog)
%    - ANALYTIC     : Trial(k) = InitialiseEmgSignals(emgSet,Trial(k),Trial(1),Analog)
%
% -------------------------------------------------------------------------
% NOTES — Extraction des données EMG en post-traitement
% -------------------------------------------------------------------------
%
% Signal retenu pour l'analyse : Trial.Emg(iemg).Signal.cycle.normalized
% (enveloppe gaussienne 100 ms, normalisée par mean + 3SD baseline,
%  interpolée à 101 points sur le cycle cinématique du côté opéré)
%
% Justification :
%   - Normalisation par baseline → comparaison inter-sujets indépendante
%     du placement d'électrode et de l'impédance cutanée
%   - Fenêtre de lissage 100 ms adaptée aux mouvements analytiques lents
%   - 101 points → moyenne inter-cycles et inter-sujets directe
%
% Attention : Signal.full est toujours disponible pour tout retraitement
% personnalisé à partir du signal brut C3D.
%
% Le canal SYNCHRO (CH4) passe dans la boucle EMG sans traitement
% différencié — à ignorer en post-traitement.
% -------------------------------------------------------------------------
