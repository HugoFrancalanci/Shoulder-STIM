# STIM_KC — Pipeline de traitement des données

Projet : Effet de la Stimulation Électrique Fonctionnelle (FES) du deltoïde sur la cinématique scapulaire et l'activité EMG de la coiffe des rotateurs.
Toolbox : K-LAB ShoulderAnalysis (Protocol01) — fichiers `.mat` par patient.

---

## Structure des dossiers

```
Results/
├── usercommands_conditions.m   ← configuration centrale (patients, conditions, exceptions)
├── compare_fes_nofes.m         ← exploration artefact FES (étape 1)
├── preprocess_fes_removal.m    ← vérification retrait FES sur un patient (étape 2)
├── verify_fes_batch.m          ← vérification retrait FES tous patients (étape 3)
├── check_fs.m                  ← utilitaire : vérifier FS_EMG et FS_KIN
├── check_synchro.m             ← utilitaire : vérifier signal SYNCHRO par patient
├── extract_scapular_kinematics.m   ← cycles scapulaires 
└── extract_emg_cycles.m            ← cycles EMG traités (étape 4b)
```

---

## Données source (.mat)

Chaque fichier `P[n].mat` contient un tableau `Trial`. Seuls les trials `ANALYTIC2` sont analysés (élévation du bras, 7 conditions × 3 blocks = 21 trials par patient).

| Champ | Description |
|-------|-------------|
| `Trial(i).task` | Nom de la tâche (`'ANALYTIC2'`, ...) |
| `Trial(i).Emg(j).label` | Nom du muscle : TRAPS, TRAPM, TRAPI, SYNCHRO, SERRA |
| `Trial(i).Emg(j).Signal.full` | Signal EMG brut complet — 2200 Hz |
| `Trial(i).Emg(j).Signal.cycle.raw` | Signal brut découpé en cycles — shape `1×1×101×N` |
| `Trial(i).Joint(j).Euler.rcycle` | Angles scapulaires normalisés — shape `3×1×101×N` |
| `Trial(i).Rcycle(k).range` | Indices frames caméra (100 Hz) du cycle k |

> **SYNCHRO** : électrode de stimulation quadriceps (pas un trigger deltoïde FES). Signal utilisé uniquement pour contrôle qualité.

---

## Conditions expérimentales

7 conditions, 3 blocks chacune :

| Condition | Description |
|-----------|-------------|
| No FES | Mouvement sans stimulation (référence) |
| Min_fatigue | FES intensité minimale — protocole anti-fatigue |
| Min_stress | FES intensité minimale — protocole bas stress |
| Random | FES fréquence aléatoire |
| Min_pw | FES largeur d'impulsion minimale |
| Rehab | FES protocole rééducation |
| Min_force | FES force minimale |

**Exceptions patients** (voir `usercommands_conditions.m`) :
- P007 : No FES block 1 absent (`missingCondPositions = [1]`)
- P010 : numérotation C3D 1→23, fichiers 04 et 18 absents du .mat — 21 trials directs

---

## Pipeline de traitement

### Étape 1 — Exploration de l'artefact FES (`compare_fes_nofes.m`)

Script d'exploration visuelle permettant de confirmer la présence et la forme de l'artefact FES dans le signal EMG brut.

**Figures produites :**
- Fig 1 : signal complet No FES vs FES (une condition)
- Fig 2 : zoom burst de mouvement (5s)
- Fig 3 : zoom fin 100ms (voir les spikes individuels)
- Fig 4 : zoom fin toutes conditions FES — canal TRAPS (vérifier cohérence fréquence)
- Fig 5 : zoom 50ms sur un pulse unique (mesurer largeur pour calibrer le blanking)

**Résultats observés (P001) :**
- Artefact présent dans toutes les conditions FES, timing variable
- Spikes biphasiques, période ~22ms (~45 Hz)
- Largeur spike : ~4ms → blanking 8ms choisi
- Amplitude : forte sur TRAPS/TRAPM/TRAPI, faible sur SERRA

---

### Étape 2 — Algorithme de retrait FES (`preprocess_fes_removal.m`, `verify_fes_batch.m`)

**Méthode : détection de pics + blanking + interpolation cubique**

Appliqué sur `Signal.full` (signal brut 2200 Hz) pour chaque canal EMG, chaque trial FES.

| Étape | Détail |
|-------|--------|
| Détection | Seuil adaptatif : `MAD_FACTOR × MAD(signal)` avec `MAD_FACTOR = 6` |
| | Pics positifs ET négatifs (spike biphasique) — `findpeaks` |
| | Distance minimale entre pics : 15ms (< période FES ~22ms) |
| Blanking | Fenêtre de 8ms centrée sur chaque pic détecté → NaN |
| Interpolation | Spline cubique (`pchip`) sur les 3 points voisins valides de chaque côté |
| | Trous > 20ms non interpolés (artefact trop large) |

**Références :**
- Cliquet A. et al. (1989) : principe blanking sur signal EMG-FES
- Langzam E. et al. (2006) : gated sampling + interpolation
- Mak J.N. et al. (2011) : seuil adaptatif MAD pour transitoires EMG

**Limitation connue :**
- P001 : 4 trials FES avec SYNCHRO inactif — traitement identique, à vérifier manuellement

---

### Étape 3 — Vérification batch (`verify_fes_batch.m`)

Pour chaque patient :
- **Fig A** : mapping FES — signal TRAPS complet, toutes conditions (gris = No FES)
  → visualise quand la FES est active dans chaque trial
- **Fig B** : zoom 300ms avant/après retrait sur la condition la plus contaminée (Rehab b1)

---

### Étape 4a — Cinématique scapulaire (`extract_scapular_kinematics.m`)

**Données :** `Trial.Joint(jscap).Euler.rcycle` — angles déjà normalisés en temps par K-LAB (101 pts/cycle)

**Pipeline :**
1. Sélection joint : `Joint(3)` = RST (droite), `Joint(8)` = LST (gauche)
2. `squeeze(rcycle)` → (3, 101, N_cycles)
3. `nanmean` sur N_cycles → (3, 101) par trial
4. `nanmean` sur les blocks valides → courbe moyenne par condition

**DOF (séquence YXZ) :**
- X : Rotation latérale (−) / médiale (+)
- Y : Protraction (+) / Rétraction (−)
- Z : Bascule postérieure (+) / antérieure (−)

**Sorties :**
- 1 figure par patient : 3 DOF × 7 conditions
- 1 figure globale P1–P10 : cycle moyen inter-patients ± ET

---

### Étape 4b — Cycles EMG (`extract_emg_cycles.m`)

**Pipeline par trial :**

| Étape | Détail |
|-------|--------|
| 1. Retrait FES | Sur `Signal.full` — identique à l'étape 2 (conditions FES uniquement) |
| 2. Segmentation | `Trial.Rcycle(k).range` (frames caméra) → indices EMG (ratio 2200/100 = 22) |
| 3. Normalisation temps | Interpolation `pchip` → 101 points par cycle |
| 4. Enveloppe linéaire | Rectification onde entière + Butterworth passe-bas 2e ordre 6 Hz |
| 5. Normalisation amplitude | Enveloppe / (mean + 3×std) des 50 premières frames cinématiques |
| 6. Moyenne | `nanmean` sur les N cycles valides du trial |

**Référence enveloppe :** Winter DA (2009) — *Biomechanics and Motor Control of Human Movement*, 4e éd.

**Canaux analysés :** TRAPS, TRAPM, TRAPI, SERRA

**Sorties :**
- 1 figure par patient : 4 muscles × 7 conditions (moyenne ± ET en bande semi-transparente)

---

## Ordre d'exécution recommandé

```
1. usercommands_conditions.m     ← toujours chargé en premier (run automatique)
2. compare_fes_nofes.m           ← exploration (optionnel si déjà validé)
3. preprocess_fes_removal.m      ← vérifier retrait sur P001
4. verify_fes_batch.m            ← vérifier retrait tous patients
5. extract_scapular_kinematics.m ← résultats cinématique
6. extract_emg_cycles.m          ← résultats EMG
```

---

## Paramètres clés

| Paramètre | Valeur | Fichier |
|-----------|--------|---------|
| `FS_EMG` | 2200 Hz | extract_emg_cycles.m |
| `FS_KIN` | 100 Hz | extract_emg_cycles.m |
| `BLANK_MS` | 8 ms | preprocess / extract_emg |
| `MAD_FACTOR` | 6 | preprocess / extract_emg |
| `MIN_PERIOD_MS` | 15 ms | preprocess / extract_emg |
| `LP_FREQ` | 6 Hz | extract_emg_cycles.m |
| Cycles normalisés | 101 points (0–100%) | tous scripts |
