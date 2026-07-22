# STIM_KC — Pipeline de traitement des données

Projet : Effet de la Stimulation Électrique Fonctionnelle (FES) du deltoïde sur la cinématique scapulaire et l'activité EMG des muscles superficiels de l'épaule.

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
| Min_fatigue | FES intensité minimale |
| Min_stress | FES intensité minimale |
| Random | FES fréquence aléatoire |
| Min_pulse_width | FES largeur d'impulsion minimale |
| Rehab | FES protocole rééducation |
| Min_force | FES force minimale |

**Exceptions patients** (voir `usercommands_conditions.m`) :
- P007 : No FES block 1 absent (`missingCondPositions = [1]`)
- P010 : numérotation C3D 1→23, fichiers 04 et 18 absents du .mat

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

**Figures produites par `preprocess_fes_removal.m` (un patient, toutes conditions FES) :**

Pour chacune des 6 conditions FES (block `VERIFY_BLOCK = 1`), 2 figures :
- **Signal complet** : noir = No FES (référence), gris = brut FES, bleu = nettoyé FES
  — ylim adapté aux signaux d'intérêt (artefacts bruts hors cadre pour lisibilité)
- **Zoom 300ms** : pleine échelle pour voir le retrait pulse par pulse

Soit **12 figures** au total permettant de comparer visuellement l'effet du retrait FES
condition par condition, avec le signal No FES comme référence.

**Références :**
- de Sousa A. et a. (2018) : Seuil MAD
- Hines A.E. et al. (1996) : principe blanking sur signal EMG-FES sur signal rectifié
- Langzam E. et al. (2006) : principe blanking sur signal EMG-FES
- Liu J. et al. (2014) : PCHIP interpolation

> **Note méthodologique :** notre approche travaille sur le signal **brut** (avant rectification),
> contrairement à Hines 1996 (signal rectifié). L'interpolation PCHIP sur signal brut est plus
> précise pour reconstruire la forme du signal ; la rectification intervient ensuite dans le
> pipeline enveloppe. Les paramètres sont identiques dans `preprocess_fes_removal.m` et
> `extract_emg_cycles.m`.

---

### Étape 3 — Vérification batch (`verify_fes_batch.m`)

Pour chaque patient :
- **Fig A** : mapping FES — signal TRAPS complet, toutes conditions (gris = No FES)
  → visualise quand la FES est active dans chaque trial
- **Fig B** : zoom 300ms avant/après retrait sur la condition la plus contaminée (Rehab b1)

---

### Étape 4a — Cinématique scapulaire (`extract_scapular_kinematics_noSEF.m`, `extract_scapular_kinematics_rehab.m`)

Deux variantes du même pipeline, qui ne différent que par la **condition de référence** utilisée pour le post-hoc :

| Script | Référence post-hoc | Conditions comparées (FES_CONDS) | Bonferroni |
|--------|---------------------|-----------------------------------|------------|
| `extract_scapular_kinematics_noSEF.m` | No FES | Min_fatigue, Min_stress, Random, Min_pulse_width, **Rehab**, Min_force (6) | α = 0.05/6 ≈ 0.0083 |
| `extract_scapular_kinematics_rehab.m` | Rehab | Min_fatigue, Min_stress, Random, Min_pulse_width, **No FES**, Min_force (5) | α = 0.05/5 = 0.01 |

La comparaison Rehab ↔ No FES n'est calculée qu'une seule fois (dans `_noSEF.m`, sous la forme « Rehab vs No FES ») — elle est donc exclue de `_rehab.m` pour éviter une duplication statistique (même test, juste inversé).

**Données :** `Trial.Joint(jscap).Euler.rcycle`
 
**Pipeline :**
1. Sélection joint : `Joint(3)` = RST (droite), `Joint(8)` = LST (gauche)
2. `squeeze(rcycle)` → (3, 101, N_cycles)
3. `nanmean` sur N_cycles → (3, 101) par trial
4. `nanmean` sur les blocks valides → courbe moyenne par condition

**DOF (séquence YXZ) :**
- X : Rotation latérale (−) / médiale (+)
- Y : Protraction (+) / Rétraction (−)
- Z : Bascule postérieure (+) / antérieure (−)

**Accumulateurs internes :**
- `condData.(cond)` : cell de matrices (3×101), une par block valide : utilisé pour les figures individuelles et le SPM1D individuel
- `globalData.(cond)` : accumulation inter-patients, utilisé pour la figure globale
- `patientMeans.(cond)` : moyenne des blocks par patient (3×101), N=10 pour le SPM1D groupé

**Sorties (par script) :**
- 1 figure par patient : 3 DOF × 7 conditions (moyenne ± ET, courbes colorées)
- 1 figure SPM1D par patient : même layout + barres de significativité (N=3 blocks, exploratoire)
- 1 figure globale P1–P10 : cycle moyen inter-patients ± ET
- 1 figure SPM1D groupée : ANOVA RM + post-hoc vs référence (N=10 participants)
- **Tableaux récap console** (individuel + groupé) : pour chaque cluster significatif, % début/fin du cycle, p-value, valeur angulaire réelle (°) de la condition et de la référence sur cette fenêtre, et leur différence — voir Étape 5 ci-dessous

---

### Étape 4b — Cycles EMG (`extract_emg_cycles.m`)

**Pipeline par trial :**

| Étape | Détail |
|-------|--------|
| 1. Retrait FES | Sur `sig_proc` (signal nettoyé) — détection MAD×6, blanking 8ms, interpolation pchip |
| 2. Segmentation | `Trial.Rcycle(k).range` (frames caméra) → indices EMG (ratio 2200/100 = 22) |
| 3. Normalisation temps | Interpolation `pchip` → 101 points par cycle |
| 4. Enveloppe linéaire | Rectification onde entière + Butterworth passe-bas 2e ordre 6 Hz |
| 5. Normalisation amplitude | `sig_env / (mean + 3×std)` des 50 premières frames cinématiques × 100 → **% baseline** |
| 6. Moyenne | `nanmean` sur les N cycles valides du trial |

**Référence enveloppe :** Winter DA (2009) — *Biomechanics and Motor Control of Human Movement*, 4e éd.

**Normalisation amplitude :** référence = période de repos pré-mouvement (50 premières frames, 100 Hz). Exprimée en % : une valeur de 150 % = 1,5× le niveau de repos. Ce n'est pas un % CMV.

**Canaux analysés :** TRAPS, TRAPM, TRAPI, SERRA 

**Accumulateurs internes :**
- `condData.(cond).(muscle)` : cell de vecteurs (1×101), un par block valide — utilisé pour les figures individuelles et le SPM1D individuel
- `globalData.(cond).(muscle)` : accumulation inter-patients, utilisé pour la figure globale
- `patientMeans.(cond).(muscle)` : moyenne des blocks par patient (1×101), N=10 pour le SPM1D groupé

**Sorties :**
- 1 figure par patient : 4 muscles × 7 conditions (moyenne ± ET, courbes colorées)
- 1 figure SPM1D par patient : même layout + barres de significativité (N=3 blocks, exploratoire)
- 1 figure globale P1–P10 : cycle moyen inter-patients ± ET
- 1 figure SPM1D groupée : ANOVA RM + post-hoc vs No FES (N=10 participants)

---

### Étape 5 — Tableaux récapitulatifs et heatmaps individuelles

Scripts standalone (résultats codés en dur, recopiés depuis la sortie console des scripts `extract_*`) qui résument l'ensemble des résultats SPM1D **individuels** (N=3 blocks, exploratoire) en une poignée de figures, un patient/condition/DOF (ou muscle) à la fois étant illisible sur 10 patients.

| Script | Source | Grille |
|--------|--------|--------|
| `heatmap_spm_individuel_kin_noSEF.m` | `extract_scapular_kinematics_noSEF.m` | 10 patients × 6 conditions (réf. No FES) |
| `heatmap_spm_individuel_kin_rehab.m` | `extract_scapular_kinematics_rehab.m` | 10 patients × 5 conditions (réf. Rehab) |
| `heatmap_spm_individuel_emg.m` | `extract_emg_cycles.m` | 10 patients × 6 conditions, 4 muscles/cellule (réf. No FES) |

Les deux scripts kinématique (`_noSEF` et `_rehab`) produisent chacun **4 figures** :
1. **Significativité + ordre de passage** : marqueurs DOF (X/Y/Z) — grand plein = post-hoc significatif, moyen creux = ANOVA sig. mais post-hoc n.s., petit gris = n.s. Fond de cellule = gradient encodant le rang relatif de passage de la condition dans la séquence du patient.
2. **Différence angulaire** : mêmes marqueurs (bordure = DOF), remplissage coloré par une colormap divergente représentant la différence angulaire moyenne (condition − référence, en °) sur la fenêtre du cluster significatif.
3. **% patients significatifs** : bar chart par condition et par DOF, % de patients (sur 10) avec un post-hoc significatif.
4. **Dumbbell chart** : une ligne par cluster significatif, valeur angulaire réelle (°) de la condition (marqueur plein) et de la référence (marqueur creux), reliées par un trait, colorées par DOF — permet de lire les deux valeurs d'angle sans recalculer la différence.

`heatmap_spm_individuel_emg.m` (issu d'une session précédente) ne produit que la figure 1 (significativité), à 4 marqueurs par cellule (un par muscle) au lieu de 3 (DOF).

> **Maintenance :** ces scripts sont volontairement standalone (aucune dépendance aux `.mat`) — si les résultats statistiques changent (nouveaux patients, seuils, corrections), les matrices `sig`/`warn`/`order`/`diffDeg` et les listes `entry*` doivent être remises à jour manuellement à partir de la sortie console du script `extract_*` correspondant.

---

## Analyses SPM1D

Les scripts `extract_emg_cycles.m`, `extract_scapular_kinematics_noSEF.m` et `extract_scapular_kinematics_rehab.m` intègrent chacun deux niveaux d'analyse SPM1D.

### SPM1D groupé (N=10 participants)

**Design :** ANOVA à mesures répétées à 1 facteur (7 conditions) sur les courbes moyennes par patient.

| Étape | Détail |
|-------|--------|
| Données | `patientMeans` — 1 vecteur (ou matrice 3×101 pour kin) par patient par condition |
| Test omnibus | `spm1d.stats.anova1rm(all_mat, group_vec, subj_vec)` — inférence α=0.05 RFT |
| Post-hoc | `spm1d.stats.ttest_paired` — chaque condition comparée vs la référence du script (No FES pour `extract_emg_cycles.m` et `extract_scapular_kinematics_noSEF.m` ; Rehab pour `extract_scapular_kinematics_rehab.m`) |
| Correction | Bonferroni : α = 0.05/6 ≈ 0.0083 (EMG, kin noSEF — 6 comparaisons) ou α = 0.05/5 = 0.01 (kin rehab — 5 comparaisons, No FES vs Rehab exclue car déjà couverte par `_noSEF.m`) |
| Résultat | Barres colorées sous chaque subplot (une couleur par condition comparée) aux instants significatifs |

**Référence :** Pataky TC (2010). *Generalized n-dimensional biomechanical field analysis using statistical parametric mapping.* Journal of Biomechanics.

### SPM1D individuel (N=3 blocks, exploratoire)

**Design :** ANOVA à mesures répétées sur les 3 blocks d'un même patient, traités comme observations indépendantes.

| Étape | Détail |
|-------|--------|
| Données | `condData` — jusqu'à 3 vecteurs (ou matrices) par condition, pour le patient courant |
| Test omnibus | `spm1d.stats.anova1rm` — même logique que le groupé |
| Post-hoc | `ttest_paired` vs la référence du script, uniquement si ANOVA significative |
| Correction | Bonferroni identique au niveau groupé (0.0083 ou 0.01 selon le script) |

> **Limitation :** N=3 implique des degrés de liberté très faibles. Le seuil RFT est élevé et la puissance statistique insuffisante pour détecter la plupart des effets. Ces figures sont à interpréter comme **exploratoires** (visualisation des tendances intra-patient) et non comme une analyse formelle.

**Tableaux récap console (kin uniquement) :** pour chaque cluster significatif (individuel et groupé), les deux scripts `extract_scapular_kinematics_*.m` impriment un tableau donnant, en plus du % début/fin et de la p-value, la valeur angulaire réelle (°) de la condition et de la référence sur cette fenêtre (range), et leur différence moyenne. Ces valeurs alimentent directement les heatmaps de l'Étape 5 (`diffDeg` + les listes `entry*` : nommées `entryFes`/`entryRehab` dans `heatmap_spm_individuel_kin_rehab.m`, `entryCond`/`entryRef` dans `heatmap_spm_individuel_kin_noSEF.m`).

### Librairie

`spm1dmatlab-master/` dans le dossier Results

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
