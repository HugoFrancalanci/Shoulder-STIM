
## Folder structure

```
Results/
├── usercommands_conditions.m   — shared config (patients, conditions, paths), loaded via run()
├── cache_*.mat                 — _all_comp caches (scapulothoracic / glenohumeral / emg)
├── README.md
├── pipeline/                   — extract_*.m entry-point scripts (9): run these
├── article_tables/             — generate_*.m scripts (10): article tables + combined figure
├── plotting/                   — plot*.m functions (9): called by pipeline/, never run directly
├── heatmaps/                   — heatmap_spm_individuel_*.m (4): standalone, hard-coded values
├── preprocessing/               — compare_fes_nofes.m, preprocess_fes_removal.m,
│                                  verify_fes_batch.m, check_synchro.m (4): run before pipeline/
└── spm1dmatlab-master/          — SPM1D toolbox (Pataky 2010)
```

Every script in `pipeline/`, `article_tables/`, and `preprocessing/` locates the shared root (`usercommands_conditions.m`, cache files, `spm1dmatlab-master/`, `plotting/`) via `fileparts(fileparts(mfilename('fullpath')))` — i.e. "my own folder's parent" — so scripts can be run from anywhere without editing paths, as long as this folder layout is kept intact. Moving a script to a different depth (or out of its subfolder) breaks that assumption.

---

## Experimental conditions

7 conditions, 3 blocks each, 10 patients (P001–P010).

| Condition | Display label | Description |
|-----------|--------------|-------------|
| `No FES` | No FES | Movement without stimulation |
| `Min_fatigue` | Min fatigue | Minimal-intensity FES |
| `Min_stress` | Min stress | Minimal-intensity FES |
| `Random` | Random | Random-frequency FES |
| `Min_pulse_width` | Min PW | Minimal pulse-width FES |
| `Rehab` | Rehab | Rehabilitation-protocol FES |
| `Min_force` | Min force | Minimal-force FES |

---

## Pipeline

1. **`preprocessing/compare_fes_nofes.m`** — visual check that the FES artefact is present and well characterised in the raw EMG (biphasic spikes, ~22 ms period, ~4 ms width → 8 ms blanking chosen).
2. **`preprocessing/preprocess_fes_removal.m` / `verify_fes_batch.m`** — FES artefact removal: peak detection (MAD×6 threshold) → 8 ms blanking → PCHIP cubic interpolation (gaps > 20 ms left untouched). Run on the raw signal, before rectification (more accurate reconstruction than filtering the rectified signal).
3. **Kinematics extraction** (`pipeline/`) — squeeze `Trial.Joint(j).Euler.rcycle` → (3 DOF, 101 pts, N cycles) → per-trial mean → per-patient mean (N=10 for group SPM1D). Two joints, same pipeline shape:
   - Scapulo-thoracic — `extract_scapular_kinematics_noSEF.m` / `_rehab.m` / `_all_comp.m` (`jscap` = RST/LST, YXZ sequence).
   - Glenohumeral (humerus relative to scapula) — `extract_glenohumeral_kinematics_noSEF.m` / `_rehab.m` / `_all_comp.m` (`jgh` = RGH/LGH, XZY sequence). 
4. **EMG extraction** (`pipeline/`) — `extract_emg_cycles_noSEF.m` / `_rehab.m` / `_all_comp.m` — same FES removal, then per-cycle linear envelope (full-wave rectification + 6 Hz Butterworth low-pass, Winter 2009), amplitude normalised to `mean + 3×SD` of the pre-movement baseline (expressed as % baseline, not %MVC). Channels: TRAPS, TRAPM, TRAPI, SERRA.
5. **Heatmaps** (`heatmaps/`) — `heatmap_spm_individuel_kin/emg_noSEF/rehab.m` — standalone scripts summarising individual-level (N=3 blocks, exploratory) SPM1D results across all 10 patients in a few compact figures (significance + order-of-passage, % significant patients, and for kinematics only, angular-difference + dumbbell charts). Values are hard-coded from the console output of the matching `extract_*` script — must be updated manually if the underlying data changes.

### Three reference schemes per pipeline (scapulo-thoracic, glenohumeral, EMG)

| Script suffix | Post-hoc reference | Compared conditions | Bonferroni α |
|---|---|---|---|
| `_noSEF` | No FES | 6 others (incl. Rehab) | 0.05/6 ≈ 0.0083 |
| `_rehab` | Rehab | 5 others (No FES excluded — already covered, inverted, by `_noSEF`) | 0.05/5 = 0.01 |
| `_all_comp` | none — all pairwise | all C(7,2) = 21 pairs | 0.05/21 ≈ 0.0024 |

Each `extract_*` script outputs, per patient: a raw mean±SD figure, an individual (N=3) SPM1D figure, plus group-level (N=10) figures and console recap tables. `_all_comp` additionally caches its inputs to a `.mat` file (`cache_scapulothoracic_all_comp.mat`, `cache_glenohumeral_all_comp.mat`, `cache_emg_all_comp.mat`) so the final figure can be redrawn in seconds without rerunning the whole statistical pipeline (set `FORCE_RECOMPUTE=true` to bypass the cache — the glenohumeral cache also auto-invalidates itself if `APPLY_LGH_SIGN_CORRECTION` changes).

---

## Statistics (SPM1D)

**Group level (N=10):** repeated-measures ANOVA across all 7 conditions — `spm1d.stats.nonparam.anova1rm`, non-parametric (Monte Carlo permutation, 10000 iterations, `rng(0)` for reproducibility; exact enumeration is infeasible since `nPermTotal = factorial(70)`). Post-hoc: `spm1d.stats.ttest_paired`, parametric, Bonferroni-corrected (see table above).

**Individual level (N=3 blocks per patient, exploratory):** same non-parametric ANOVA design per patient, followed by the same parametric post-hoc if significant. Degrees of freedom are very low here, so these results are exploratory only, not a formal analysis.

**Reference:** Pataky TC (2010), *Generalized n-dimensional biomechanical field analysis using statistical parametric mapping*, J Biomech.

---

## Final figures

Each `extract_*` script (in `pipeline/`) calls dedicated plotting functions to build a compact "final figure" family (group means, no per-trial clutter). All of them live in the `plotting/` subfolder — every `pipeline/` script adds it to the path itself (`addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'plotting'))`), so nothing needs to be added manually:

- **`plotCombinedFigure*.m`** (`_noSEF`/`_rehab`, scapulo-thoracic + glenohumeral kinematics, and EMG) — group mean ± individual patient curves, one panel per compared condition, with group- and patient-level post-hoc significance bars. The kinematics variants take a `jointLabel` argument (`'Scapular kinematics'` / `'Glenohumeral kinematics'`) so the same function serves both joints.
- **`plotPatientIdentityFigure*.m`** — same grid, colour-coded by patient (P1–P10) instead of by significance, to trace one patient across panels.
- **`plotCombinedFigureLabeled*.m`** — same as `plotCombinedFigure*` but with "P#" labels next to each patient's individual significance bar.
- **`plotAllCompFigure*.m`** (`_all_comp` variant) — one panel per DOF/muscle showing all 7 conditions at once; produces 3 figures (mean±SD, individual patients, and mean±SD with labelled per-patient bars for every significant pair). Only pairs found significant get a colour and a legend entry — no clutter from the other ~15 non-significant pairs.
- **`plotCombinedJointsFigure.m`** (driven by `article_tables/generate_combined_all_comp_figure.m`) — stacks the scapulo-thoracic and glenohumeral "group mean ± SD" `_all_comp` figure into ONE figure, one row per joint, so both can be read side by side. Significant pairs are recensed across BOTH joints so a pair keeps the same legend colour wherever it's significant. Reads both `_all_comp` `.mat` caches directly, no statistics rerun.

**Article tables** (`article_tables/`): `generate_article_table_kin/gh/emg.m` (group-significant comparisons), `_individual.m` (every individually significant cluster, all 21 pairs), and `_combined.m` (both, merged) read the corresponding `_all_comp` `.mat` cache and print a Markdown table to the console, without rerunning any statistics.

---

## Key parameters

| Parameter | Value | Where |
|-----------|-------|-------|
| `FS_EMG` | 2200 Hz | EMG scripts |
| `FS_KIN` | 100 Hz | EMG scripts |
| `BLANK_MS` | 8 ms | preprocess / EMG scripts |
| `MAD_FACTOR` | 6 | preprocess / EMG scripts |
| `MIN_PERIOD_MS` | 15 ms | preprocess / EMG scripts |
| `LP_FREQ` | 6 Hz | EMG scripts |
| Cycle normalisation | 101 points (0–100%) | all scripts |

See "Folder structure" above for where everything lives.
