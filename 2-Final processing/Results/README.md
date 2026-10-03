
## Folder structure

```
Results/
├── usercommands_conditions.m   — shared config (patients, conditions, paths), loaded via run()
├── cache_*.mat                 — _all_comp caches (scapulothoracic / glenohumeral / emg / emg ratio / emg discrete)
├── README.md
├── pipeline/                   — extract_*.m entry-point scripts (14): run these
├── article_tables/             — generate_*.m scripts (13): article tables + combined figure + reviewer workbooks
│                                  (+ 2 build_reviewer_workbook_*.py, called by the reviewer-workbook scripts)
├── plotting/                   — plot*.m functions (10) + drawExclusionZone.m: called by pipeline/, never run directly
├── helpers/                    — holmAlphaSPM1D.m, holmAdjust.m, extractHTElevation.m, computeExclusionZone.m: called by
│                                  the pipeline/ scripts, never run directly
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
5. **EMG ratio analysis** (`pipeline/`) — `extract_emg_ratio_all_comp.m` — post-processes `cache_emg_all_comp.mat` only, no raw K-LAB data re-read and no FES removal/filtering redone. Computes every pairwise inter-muscle amplitude ratio (all C(4,2)=6 muscle pairs, e.g. UT/LT = TRAPS/TRAPI, UT/SA = TRAPS/SERRA — generated automatically from `EMG_LABELS`, not hard-coded), point-by-point across the 101-pt cycle per patient, then reruns the same ANOVA RM + 21-pair post-hoc design as the amplitude pipeline on the ratio curves. `_all_comp` only, group level (N=10) only — the source cache stores block-averaged data, so there is nothing left to support an individual-level (N=3) analysis for the ratio. Also prints a plain console recap of the ratio values themselves (mean ± SD across patients, cycle-averaged) per ratio × condition, independent of significance.
**Reported EMG muscles:** all 4 muscles, all trials kept (an outlier-exclusion variant and a stricter FES-removal variant were tested and discarded — same conclusions). `REPORT_MUSCLES = {'TRAPS','TRAPM','TRAPI','SERRA'}` in `extract_emg_cycles_all_comp.m`, `extract_emg_discrete_all_comp.m` and `generate_reviewer_workbook_emg.m` selects the muscles shown in figures, console tables and the reviewer workbook. Display-level filter only: statistics are still computed for the 4 muscles in the caches (Holm families are per muscle, so the other muscles' results are unchanged and no permutation is redrawn). The EMG ratio analysis (3 of its 6 ratios involve the upper trapezius) is not part of the final article.

6. **EMG discrete parameters** (`pipeline/`) — `extract_emg_discrete_all_comp.m` — post-processes `cache_emg_all_comp.mat` (`patientBlocks`) only. For each block's mean envelope: peak amplitude (% baseline), peak timing (% cycle), activity duration = total % of the cycle where the envelope exceeds min + 50 % × (peak − min), i.e. the full width at half maximum (FWHM — Cappellini et al. 2006, J Neurophysiol; Martino et al. 2014), plus onset/offset of the main burst (descriptive). Peak timing rather than onset/offset is the usual choice for continuous shoulder elevation (Hawkes et al. 2019, PLoS One). The threshold is relative to each curve's own peak and minimum, so it does not depend on the amplitude normalisation. Block values are averaged per patient (N = 10). Statistics: non-parametric RM-ANOVA (spm1d 0D, 10 000 permutations) then paired t-tests on the 21 pairs with Holm-Bonferroni per muscle × parameter (`helpers/holmAdjust.m`, interpreted only if the ANOVA is significant). Prints descriptive and statistical tables plus a targeted check of the hypotheses suggested by the SPM1D curves (`TARGET_CHECKS`), draws two figures — supplementary grid reported muscles × 3 parameters (`plotting/plotDiscreteEMGFigure.m`) and the manuscript figure (`plotting/plotDiscreteEMGManuscript.m`, reported muscles × peak timing and activity duration > 50 % — peak amplitude left out of the article because FES artefact removal may bias amplitude in stimulated conditions — set by `MANUSCRIPT_MUSCLES` / `MANUSCRIPT_PARAMS`, metric names and units (Normalised EMG (%), Cycle (%)) written vertically on the left of each row and a bottom legend (conditions, individual participants, meaning of the stars) as in `plotCombinedJointsFigure.m`) — both marking Holm-significant pairs (only when the ANOVA is significant) with brackets and stars (* p < 0.05, ** p < 0.01, *** p < 0.001, Holm-adjusted), packed on as few levels as possible — and writes `cache_emg_discrete_all_comp.mat`. Figures are redrawn from the cache in seconds.
6b. **Kinematics × EMG coupling** (`pipeline/`) — `extract_kinematics_emg_coupling_all_comp.m` — post-processes `cache_humerothoracic_all_comp.mat`, `cache_emg_all_comp.mat` and `cache_emg_discrete_all_comp.mat` only (seconds). Repeated-measures correlation (Bakdash & Marusich 2017, `helpers/rmCorr.m`) between the HT rise time / peak timing and each muscle's EMG peak timing / activity duration > 50 % (console table, all muscles). For `COUPLING_MUSCLE` (upper trapezius) it also reports the correlation after removing subject AND condition means, and the number of participants in whom the optimal "Min" commands both slow the HT rise and shift the EMG parameter in the group direction. Figure (`plotting/plotKinEmgCouplingFigure.m`): top — HT elevation (mean rise time marked on each curve) and the muscle envelope normalised to each trial's own peak (dotted line = 50 % threshold); bottom — HT rise time vs EMG peak timing and vs activity duration (one dot per participant × condition, condition mean ± SD on both axes, dashed common within-subject slope, r_rm and p in the title). It also runs SPM1D on the peak-normalised envelopes (each trial divided by its own peak, Burden 2010; same design: non-parametric RM-ANOVA, 10 000 permutations, then 21 paired SPM{t} with Holm-Bonferroni; own cache `cache_emg_peaknorm_spm_all_comp.mat`, `FORCE_RECOMPUTE_SPM` to redo) — tests the shape/timing of activation independently of amplitude and of the uniform amplitude loss caused by FES blanking. A second figure (`plotting/plotKinEmgCouplingAllMuscles.m`, significant pairs drawn as bars under the row-1 curves) shows the same panels for all 4 muscles (one column per muscle, no HT panel since HT elevation has its own article figure; metric names on the left and bottom legend as in the discrete EMG figure). Caveat: the coupling supports a physiological link but does not exclude crosstalk from the stimulated deltoid, whose timing would follow the same stimulation profile.
7. **Humerothoracic elevation** (`pipeline/`) — `extract_humerothoracic_elevation_all_comp.m` — exploratory follow-up testing whether the stimulation pattern changes the time course of the global arm elevation (humerus relative to thorax, `helpers/extractHTElevation.m`), re-reading the K-LAB files. Group level (N = 10): SPM1D over the full cycle (same ANOVA + Holm design as GH/ST) and discrete parameters per block averaged per patient — peak elevation, peak timing, rise time (% cycle at which elevation first exceeds min + 50 % × (peak − min)) — tested with the 0D ANOVA + Holm design of the EMG discrete analysis. Prints the window mean (default 28–38 %) and the per-patient contrast optimal commands (Min) vs {No FES, Random, Rehab}. Cache `cache_humerothoracic_all_comp.mat` in `dataDir()`; figure via `plotCombinedJointsFigure.m`, same style as the GH/ST article figure (no grey zone: HT elevation defines it).
8. **Scapulohumeral rhythm** (`pipeline/`) — `extract_scapulohumeral_rhythm_all_comp.m` — GH and ST angles expressed as a function of humerothoracic elevation (ascending phase, 20–90° grid as requested for the article, capped at 90°; curves starting ≤ 2.5° above 20° are prolonged with their first value, and P005 — arm never below ~36° — is excluded, N = 9; figure restricted to ST via `FIGURE_JOINTS`) instead of % cycle, to separate a change in the time course of the movement from a change in joint coordination. Post-processes the GH, ST and HT caches only; for each grid elevation the first time the arm reaches it is interpolated and the GH/ST angles read at that time. SPM1D with HT elevation as the 1D domain (same ANOVA + Holm design), console table of mean angles at 50/70/90°, figure `plotting/plotRhythmFigure.m`, cache `cache_scapulohumeral_rhythm_all_comp.mat` in `dataDir()`.

### Three reference schemes per pipeline (scapulo-thoracic, glenohumeral, EMG)

| Script suffix | Post-hoc reference | Compared conditions | Family size m | Holm-Bonferroni thresholds (kinematics + EMG) |
|---|---|---|---|---|
| `_noSEF` | No FES | 6 others (incl. Rehab) | 6 | 0.05/6 … 0.05/1 |
| `_rehab` | Rehab | 5 others (No FES excluded — already covered, inverted, by `_noSEF`) | 5 | 0.05/5 … 0.05/1 |
| `_all_comp` | none — all pairwise | all C(7,2) = 21 pairs | 21 | 0.05/21 … 0.05/1 |

Each `extract_*` script outputs, per patient: a raw mean±SD figure, an individual (N=3) SPM1D figure, plus group-level (N=10) figures and console recap tables. `_all_comp` additionally caches its inputs to a `.mat` file (`cache_scapulothoracic_all_comp.mat`, `cache_glenohumeral_all_comp.mat`, `cache_emg_all_comp.mat`) so the final figure can be redrawn in seconds without rerunning the whole statistical pipeline (set `FORCE_RECOMPUTE=true` to bypass the cache — the glenohumeral cache also auto-invalidates itself if `APPLY_LGH_SIGN_CORRECTION` changes; both kinematics caches also auto-invalidate if they were not built with `POSTHOC_CORRECTION = 'holm'` or have no `EXCL_ZONE`). **Quick redraw of the kinematics final figures:** just rerun `pipeline/extract_glenohumeral_kinematics_all_comp.m` / `extract_scapular_kinematics_all_comp.m` (console shows "Cache trouve … Regeneration rapide"), or `article_tables/generate_combined_all_comp_figure.m` for the combined GH + ST figure — seconds, no SPM1D rerun (a full recompute takes ~7 min per joint). Cosmetic changes made in `plotting/` are picked up by this fast path.

The EMG ratio analysis (`extract_emg_ratio_all_comp.m`) only exists as an `_all_comp` variant — it reads `cache_emg_all_comp.mat` and writes its own `cache_emg_ratio_all_comp.mat`, same `FORCE_RECOMPUTE` fast-path convention. There is no `_noSEF`/`_rehab` ratio script.

---

## Statistics (SPM1D)

**Group level (N=10):** repeated-measures ANOVA across all 7 conditions — `spm1d.stats.nonparam.anova1rm`, non-parametric (Monte Carlo permutation, 10000 iterations, `rng(0)` for reproducibility; exact enumeration is infeasible since `nPermTotal = factorial(70)`). Post-hoc: `spm1d.stats.ttest_paired`, parametric, multiple-comparison corrected over the post-hoc family of each DOF (see table above):

- **Holm-Bonferroni for every SPM1D post-hoc (kinematics, EMG amplitude, EMG ratio)** step-down (Holm 1979), family-wise α = 0.05 — `helpers/holmAlphaSPM1D.m`. Each SPM{t} gets one test-level p-value: the RFT probability that the max of the 1D t field exceeds the observed max |t| (two-tailed, same survival function as spm1d's own inference, so `p < a` ⇔ `inference(a)` has a supra-threshold cluster). P-values are ranked; the k-th smallest is compared to α/(m−k+1), stopping at the first non-rejected one. Rejected tests are then drawn with `inference(α/(m−k+1))`, so their clusters are those at their own Holm threshold. Uniformly more powerful than plain Bonferroni, same FWER control. Group-level `spmResults(idof).posthoc.(fld)` also stores `p_holm` / `alpha_holm`. The `_all_comp` caches store `POSTHOC_CORRECTION = 'holm'` — an older (Bonferroni) cache is ignored and fully recomputed automatically.
- The EMG `_all_comp` / ratio caches also store `POSTHOC_CORRECTION = 'holm'` (an older Bonferroni cache is ignored and recomputed). `cache_emg_all_comp.mat` additionally stores `patientBlocks` (per-block mean envelopes, `(n_blocks, 101)` per patient × condition × muscle) for the discrete analysis below.

**Glenohumeral / scapulo-thoracic "not interpretable" zone (kinematics only):** above 90° of humerothoracic elevation, GH and ST angles are greyed out on every kinematics figure (transparent grey vertical band, `plotting/drawExclusionZone.m`, plus one legend entry on the final figures). The zone is where the mean humerothoracic elevation (`Trial.Joint(1/6)` = RHT/LHT, dim 1, sign flipped so + = elevation — `helpers/extractHTElevation.m`) exceeds `EXCL_ELEV_THRESHOLD = 90°`, with edges linearly interpolated (`helpers/computeExclusionZone.m`): group figures use the mean over the 10 patients (all conditions pooled), per-patient figures use that patient's own curve. Visual only — SPM1D still runs on the full 0–100 % cycle, so clusters falling inside the grey band are computed but should not be interpreted. Saved as `EXCL_ZONE` in the `_all_comp` caches.

- *Why humerothoracic and not GH/ST angles themselves:* GH elevation peaks at ~70–88° and ST angles never approach 90° in this dataset, so a threshold on their own angles would grey out nothing. The limit is the arm elevation: beyond ~90° humerothoracic elevation, skin-marker tracking of the scapula (hence ST, and GH which depends on it) becomes unreliable.
- *Current result (group):* mean humerothoracic elevation peaks at 102° at 56 % of the cycle → grey zone **38.1 % → 70.9 %**, identical on the GH and ST figures (same humerothoracic signal). Printed in the console of each kinematics script ("Zone d'exclusion").
- *Design choices:* one zone for all conditions pooled (elevation curves are very close between conditions, one band keeps figures readable); group zone from the mean curve over patients, not the union of individual crossings (which would be wider/more conservative).
- *Changing the threshold:* edit `EXCL_ELEV_THRESHOLD` in each kinematics script; for `_all_comp` the zone is stored in the cache, so rerun once with `FORCE_RECOMPUTE=true`.

**Individual level (N=3 blocks per patient, exploratory):** same non-parametric ANOVA design per patient, followed by the same parametric post-hoc if significant. Degrees of freedom are very low here, so these results are exploratory only, not a formal analysis.

**Reference:** Pataky TC (2010), *Generalized n-dimensional biomechanical field analysis using statistical parametric mapping*, J Biomech.

---

## Final figures

Each `extract_*` script (in `pipeline/`) calls dedicated plotting functions to build a compact "final figure" family (group means, no per-trial clutter). All of them live in the `plotting/` subfolder — every `pipeline/` script adds it to the path itself (`addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'plotting'))`), so nothing needs to be added manually:

- **`plotCombinedFigure*.m`** (`_noSEF`/`_rehab`, scapulo-thoracic + glenohumeral kinematics, and EMG) — group mean ± individual patient curves, one panel per compared condition, with group- and patient-level post-hoc significance bars. The kinematics variants take a `jointLabel` argument (`'Scapular kinematics'` / `'Glenohumeral kinematics'`) so the same function serves both joints.
- **`plotPatientIdentityFigure*.m`** — same grid, colour-coded by patient (P1–P10) instead of by significance, to trace one patient across panels.
- **`plotCombinedFigureLabeled*.m`** — same as `plotCombinedFigure*` but with "P#" labels next to each patient's individual significance bar.
- **`plotAllCompFigure*.m`** (`_all_comp` variant) — one panel per DOF/muscle showing all 7 conditions at once; produces 3 figures (mean±SD, individual patients, and mean±SD with labelled per-patient bars for every significant pair). Only pairs found significant get a colour and a legend entry — no clutter from the other ~15 non-significant pairs.
- **`plotAllCompFigureEMGRatio.m`** — ratio counterpart of `plotAllCompFigureEMG.m`, one panel per muscle-pair ratio (6). Produces only 2 figures, not 3: the labelled per-patient variant is dropped since the ratio cache has no individual-level clusters to draw (see "EMG ratio analysis" above). Y-axis in ratio units (a.u.), with a dashed reference line at ratio = 1 in every panel.
- **`plotCombinedJointsFigure.m`** (driven by `article_tables/generate_combined_all_comp_figure.m`) — stacks the scapulo-thoracic and glenohumeral "group mean ± SD" `_all_comp` figure into ONE figure, one row per joint, so both can be read side by side. Significant pairs are recensed across BOTH joints so a pair keeps the same legend colour wherever it's significant. Reads both `_all_comp` `.mat` caches directly, no statistics rerun.

**Article tables** (`article_tables/`): `generate_article_table_kin/gh/emg.m` (group-significant comparisons), `_individual.m` (every individually significant cluster, all 21 pairs), and `_combined.m` (both, merged) read the corresponding `_all_comp` `.mat` cache and print a Markdown table to the console, without rerunning any statistics. For the kinematics group rows (`generate_article_table_kin/gh.m` and the group rows of `_combined.m`), `Mean_A/Mean_B` = mean ± SD across the 10 patients of each patient's own angle averaged over the significant window (from `patientMeans`), and `Diff` = paired difference B − A, mean ± SD (previously the midpoint of the group-mean curve's min/max over the window). Individual rows keep the single patient's window-averaged value. `generate_article_table_emg_ratio.m` is the ratio counterpart of `generate_article_table_emg.m` — group-significant comparisons only, no `_individual`/`_combined` variant (same reason: no per-patient significance data in the ratio cache) and no "patients significant" column.

**Reviewer workbooks** (`article_tables/`): `generate_reviewer_workbook_kin.m` → `Kinematics_SPM1D_results.xlsx` (GH + ST: README with methods and sign conventions, group ANOVA clusters, the 126 group post-hoc tests, significant group windows with window-averaged angles, individual windows, all individual/group curves, non-interpretable zone) and `generate_reviewer_workbook_emg.m` → `EMG_SPM1D_discrete_results.xlsx` (SPM1D ANOVA/post-hoc/individual windows, discrete-parameter ANOVA, the 336 pairwise comparisons, means ± SD, per-participant values, all envelopes). Both read the `_all_comp` caches only (no statistics rerun), export them to a temporary JSON, build the formatted workbook with `build_reviewer_workbook_kin/emg.py` (Python 3 + openpyxl, `PYTHON_EXE` at the top of the script) and, if Excel is installed, recalculate and save it. The Holm-Bonferroni decisions are recomputed by live Excel formulas from the p-values, with a check column against the MATLAB decision; group mean/SD curves and summaries are formulas too. Output written to `Results/`.

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
| `DENOM_EPS` | 1e-6 (% baseline) | EMG ratio script — denominator below this → NaN, not Inf |
| Cycle normalisation | 101 points (0–100%) | all scripts |
| `ALPHA_FWER` | 0.05 (Holm-Bonferroni) | kinematics + EMG scripts |
| `ACT_THRESHOLD` | 50 % of (peak − min) — full width at half maximum (FWHM) | `extract_emg_discrete_all_comp.m` |
| `EXCL_ELEV_THRESHOLD` | 90° humerothoracic elevation | kinematics scripts |

See "Folder structure" above for where everything lives.
