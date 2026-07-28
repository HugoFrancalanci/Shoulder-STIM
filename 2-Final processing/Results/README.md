
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

1. **`compare_fes_nofes.m`** — visual check that the FES artefact is present and well characterised in the raw EMG (biphasic spikes, ~22 ms period, ~4 ms width → 8 ms blanking chosen).
2. **`preprocess_fes_removal.m` / `verify_fes_batch.m`** — FES artefact removal: peak detection (MAD×6 threshold) → 8 ms blanking → PCHIP cubic interpolation (gaps > 20 ms left untouched). Run on the raw signal, before rectification (more accurate reconstruction than filtering the rectified signal).
3. **Kinematics extraction** — `extract_scapular_kinematics_noSEF.m` / `_rehab.m` / `_all_comp.m` — squeeze `Trial.Joint(jscap).Euler.rcycle` → (3 DOF, 101 pts, N cycles) → per-trial mean → per-patient mean (N=10 for group SPM1D).
4. **EMG extraction** — `extract_emg_cycles_noSEF.m` / `_rehab.m` / `_all_comp.m` — same FES removal, then per-cycle linear envelope (full-wave rectification + 6 Hz Butterworth low-pass, Winter 2009), amplitude normalised to `mean + 3×SD` of the pre-movement baseline (expressed as % baseline, not %MVC). Channels: TRAPS, TRAPM, TRAPI, SERRA.
5. **Heatmaps** — `heatmap_spm_individuel_kin/emg_noSEF/rehab.m` — standalone scripts summarising individual-level (N=3 blocks, exploratory) SPM1D results across all 10 patients in a few compact figures (significance + order-of-passage, % significant patients, and for kinematics only, angular-difference + dumbbell charts). Values are hard-coded from the console output of the matching `extract_*` script — must be updated manually if the underlying data changes.

### Three reference schemes per pipeline (kinematics and EMG)

| Script suffix | Post-hoc reference | Compared conditions | Bonferroni α |
|---|---|---|---|
| `_noSEF` | No FES | 6 others (incl. Rehab) | 0.05/6 ≈ 0.0083 |
| `_rehab` | Rehab | 5 others (No FES excluded — already covered, inverted, by `_noSEF`) | 0.05/5 = 0.01 |
| `_all_comp` | none — all pairwise | all C(7,2) = 21 pairs | 0.05/21 ≈ 0.0024 |

Each `extract_*` script outputs, per patient: a raw mean±SD figure, an individual (N=3) SPM1D figure, plus group-level (N=10) figures and console recap tables. `_all_comp` additionally caches its inputs to a `.mat` file so the final figure can be redrawn in seconds without rerunning the whole statistical pipeline (set `FORCE_RECOMPUTE=true` to bypass the cache).

---

## Statistics (SPM1D)

**Group level (N=10):** repeated-measures ANOVA across all 7 conditions — `spm1d.stats.nonparam.anova1rm`, non-parametric (Monte Carlo permutation, 10000 iterations, `rng(0)` for reproducibility; exact enumeration is infeasible since `nPermTotal = factorial(70)`). Post-hoc: `spm1d.stats.ttest_paired`, parametric, Bonferroni-corrected (see table above).

**Individual level (N=3 blocks per patient, exploratory):** same non-parametric ANOVA design per patient, followed by the same parametric post-hoc if significant. Degrees of freedom are very low here, so these results are exploratory only, not a formal analysis.

**Reference:** Pataky TC (2010), *Generalized n-dimensional biomechanical field analysis using statistical parametric mapping*, J Biomech.

---

## Final figures

Each `extract_*` script calls dedicated plotting functions to build a compact "final figure" family (group means, no per-trial clutter):

- **`plotCombinedFigure*.m`** (`_noSEF`/`_rehab`, kinematics + EMG) — group mean ± individual patient curves, one panel per compared condition, with group- and patient-level post-hoc significance bars.
- **`plotPatientIdentityFigure*.m`** — same grid, colour-coded by patient (P1–P10) instead of by significance, to trace one patient across panels.
- **`plotCombinedFigureLabeled*.m`** — same as `plotCombinedFigure*` but with "P#" labels next to each patient's individual significance bar.
- **`plotAllCompFigure*.m`** (`_all_comp` variant) — one panel per DOF/muscle showing all 7 conditions at once; produces 3 figures (mean±SD, individual patients, and mean±SD with labelled per-patient bars for every significant pair). Only pairs found significant get a colour and a legend entry — no clutter from the other ~15 non-significant pairs.

**Excel export:** every `extract_*` script writes a `recap_*.xlsx` (via `exportSpmRecapExcel.m`) with two sheets — `Group_PostHoc` (one row per comparison, significant or not, plus % of patients individually significant) and `Individual_PostHoc` (one row per actual significant patient cluster).

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

`spm1dmatlab-master/` (Pataky 2010) lives inside this `Results/` folder.
