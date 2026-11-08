# STIM_KC: final analyses

Analysis code for the article on the effect of deltoid stimulation patterns on shoulder kinematics and scapular muscle activity during arm elevation (10 participants, 7 conditions, 3 trials per condition).

## Folder structure

```
Results/
├── usercommands_conditions.m   shared configuration (participants, conditions, paths), loaded with run()
├── README.md
├── pipeline/                   entry-point scripts (8): run these
├── plotting/                   figure functions (6), called by pipeline/
├── helpers/                    utility functions (10), called by pipeline/ and plotting/
├── preprocessing/              checks of the stimulation-artefact removal (4)
└── spm1dmatlab-master/         SPM1D toolbox (Pataky 2010)
```

Each script finds the shared folders from its own location, so it can be run from anywhere as long as this layout is kept.

**Data.** Participant data are not stored in this repository.
- The K-LAB participant files (`P1.mat` to `P10.mat`, produced by `0-Preprocessing/` and `1-Processing/`) are read from the folder set in `usercommands_conditions.m`.
- The derived data (`cache_*.mat`) are read and written in the folder returned by `helpers/dataDir.m`.
- The article figure is exported at high resolution (PNG 600 dpi and vector PDF, fixed paper size, light theme) in the `Figures` subfolder of the same folder (`helpers/exportFigure.m`, `EXPORT_FIGURE = true` at the top of `nested_comparison.m`). The PNG written by MATLAB can misplace a few tick labels; the vector PDF is exact.

## Conditions

| Condition | Label | Description |
|-----------|-------|-------------|
| `No FES` | No FES | Movement without stimulation (reference) |
| `Rehab` | Rehab | Rehabilitation-like pattern, constant pulse width |
| `Min_pulse_width` | Min PW | Optimised pattern |
| `Min_force` | Min force | Optimised pattern |
| `Min_stress` | Min stress | Optimised pattern |
| `Min_fatigue` | Min fatigue | Optimised pattern |
| `Random` | Random | Non-optimised pattern, kept in the extraction scripts but not used in the article analyses |

## Running the analyses

Run the scripts of `pipeline/` in this order. Each extraction script saves its results in a cache; later runs only redraw the figures (set `FORCE_RECOMPUTE = true` at the top of a script to recompute).

| Step | Script | Needs | Produces |
|---|---|---|---|
| 1 | `extract_humerothoracic_elevation_all_comp.m` | K-LAB files | thoracohumeral cache (curves and discrete parameters) |
| 2 | `extract_scapular_kinematics_all_comp.m` | K-LAB files | scapulothoracic cache |
| 3 | `extract_glenohumeral_kinematics_all_comp.m` | K-LAB files | glenohumeral cache (used by step 4) |
| 4 | `extract_scapulohumeral_rhythm_all_comp.m` | steps 1 to 3 | scapulothoracic angles as a function of elevation |
| 5 | `extract_emg_cycles_all_comp.m` | K-LAB files | EMG cache |
| 6 | `extract_emg_elevation_all_comp.m` | steps 1, 4, 5 | EMG as a function of elevation |
| 7 | `nested_comparison.m` | steps 1, 4, 6 | article analyses and figure: console tables, `cache_nested_comparison.mat` |
| 8 | `export_source_data.m` | steps 1 to 7 | `Source_data_Figure5.xlsx`: data and statistics of the article figure and of the thoracohumeral results (text) |

Steps 1 to 6 also compare the 7 conditions (ANOVA and 21 pairs, see Statistics) and draw the corresponding figures. These secondary results are not used in the article and are not exported.

## Article analyses (`nested_comparison.m`)

The rehabilitation-like pattern (Rehab) is compared with the mean of the four optimised patterns (OCP). Each participant gives one value or curve per group, so that a participant counts only once.
- **Scapulothoracic kinematics (hypothesis):** for each angle, absolute deviation from No FES at each degree of thoracohumeral elevation, from 20 to 90 deg during the ascending phase. The deviation of Rehab is compared with the mean of the four OCP deviations.
- **EMG (exploratory):** upper, middle and lower trapezius and serratus anterior. After attenuation of the stimulation artefact, each cycle gives a linear envelope (rectification and 6 Hz low-pass filter) normalised to 101 points; each trial's envelope is expressed as a percentage of its own peak, averaged per participant and read at each elevation as for the angles. The deviation of the envelopes from No FES is compared as for the angles, and Rehab is compared directly with the mean of the OCP envelopes.
- **Thoracohumeral elevation (check of the movement performed, reported in the text):** curve over the movement cycle, Rehab vs OCP. Discrete parameters (peak elevation, peak timing, plane of elevation averaged between 20 and 90 deg), three contrasts: Rehab vs OCP, Rehab vs No FES and OCP vs No FES.

**Article figure.** Four rows, against thoracohumeral elevation (20 to 90 deg):
1. scapulothoracic angles of No FES, Rehab and the four OCP;
2. their absolute deviation from No FES, Rehab and mean of the OCP;
3. EMG envelopes normalised to the peak;
4. absolute deviation of the EMG envelopes from No FES.

**Figure layout.**
- Colours by condition (`helpers/conditionColors.m`): No FES in dark grey, Rehab in red, optimised patterns in blues and greens.
- Lines show the mean of each condition. Shaded bands show the mean +/- SD across participants for No FES, Rehab and the optimised patterns (rows 2 and 4: Rehab and the mean of the OCP, dashed).
- Row 1 is descriptive. On rows 2, 3 and 4, each significant range of the Rehab vs OCP comparison is shown as a bicoloured bar under the curves: upper half red (Rehab), lower half teal (optimised patterns).

## Statistics

**Article analyses (`nested_comparison.m`).**
- Paired, two-tailed tests with all sign permutations: SPM1D t-test for curves, t-test for discrete values.
- Holm-Bonferroni correction (alpha = 0.05) across the 3 scapulothoracic angles, across the 4 muscles, and across the 3 contrasts of each discrete parameter.
- For curves, each curve gets one p-value (maximum |t| over the curve, permutation distribution), and its significant ranges are computed at its Holm threshold.
- Sensitivity analysis: the scapulothoracic and EMG tests are repeated on all participants, over the elevation range common to all of them (34 to 90 deg).

**Secondary analyses (steps 1 to 6, not used in the article).**
- Non-parametric repeated-measures ANOVA across the 7 conditions (10 000 permutations), on curves (SPM1D) or discrete values.
- If significant: paired t-tests on the 21 pairs of conditions, Holm-Bonferroni correction, with `helpers/holmAlphaSPM1D.m` for curves and `helpers/holmAdjust.m` for discrete values.

## Key parameters

| Parameter | Value | Script |
|-----------|-------|--------|
| EMG sampling frequency | 2200 Hz | EMG |
| Kinematic sampling frequency | 100 Hz | EMG |
| EMG low-pass filter | 6 Hz | EMG |
| Time normalisation | 101 points (0 to 100 %) | all |
| Family-wise alpha | 0.05 (Holm-Bonferroni) | all |
| Permutations | all sign permutations (article analyses), 10 000 (ANOVA) | all |
| Elevation range | 20 to 90 deg, 1 deg steps | scapulohumeral rhythm, EMG elevation, nested comparison |
| EMG normalisation | % of the peak of each trial | EMG elevation |

## References

- Burden A (2010). How should we normalize electromyograms obtained from healthy participants? J Electromyogr Kinesiol 20:1023-1035.
- Holm S (1979). A simple sequentially rejective multiple test procedure. Scand J Stat 6:65-70.
- Pataky TC (2010). Generalized n-dimensional biomechanical field analysis using statistical parametric mapping. J Biomech 43:1976-1982.
