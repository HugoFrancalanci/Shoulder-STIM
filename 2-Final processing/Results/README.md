# STIM_KC: final analyses

Analysis code for the article on the effect of seven deltoid stimulation conditions on shoulder kinematics and scapular muscle activity during arm elevation (10 participants, 3 trials per condition).

## Folder structure

```
Results/
├── usercommands_conditions.m   shared configuration (participants, conditions, paths), loaded with run()
├── README.md
├── pipeline/                   entry-point scripts (7): run these
├── plotting/                   figure functions (9), called by pipeline/
├── helpers/                    utility functions (6), called by pipeline/
├── preprocessing/              checks of the stimulation-artefact removal (4)
└── spm1dmatlab-master/         SPM1D toolbox (Pataky 2010)
```

Each script finds the shared folders from its own location, so it can be run from anywhere as long as this layout is kept.

**Data.** Participant data are not stored in this repository.
- The K-LAB participant files (`P1.mat` to `P10.mat`, produced by `0-Preprocessing/` and `1-Processing/`) are read from the folder set in `usercommands_conditions.m`.
- The derived data (`cache_*.mat`) are read and written in the folder returned by `helpers/dataDir.m`.

## Conditions

| Condition | Label | Description |
|-----------|-------|-------------|
| `No FES` | No FES | Movement without stimulation |
| `Min_fatigue` | Min fatigue | Optimised stimulation command |
| `Min_stress` | Min stress | Optimised stimulation command |
| `Min_pulse_width` | Min PW | Optimised stimulation command |
| `Min_force` | Min force | Optimised stimulation command |
| `Random` | Random | Non-optimised stimulation pattern |
| `Rehab` | Rehab | Non-optimised stimulation pattern |

## Running the analyses

Run the scripts of `pipeline/` in this order. Each script saves its results in a cache; later runs only redraw the figures (set `FORCE_RECOMPUTE = true` at the top of a script to recompute).

| Step | Script | Needs | Produces |
|---|---|---|---|
| 1 | `extract_humerothoracic_elevation_all_comp.m` | K-LAB files | Figure 1 |
| 2 | `extract_scapular_kinematics_all_comp.m` | K-LAB files | scapulothoracic cache |
| 3 | `extract_glenohumeral_kinematics_all_comp.m` | K-LAB files | glenohumeral cache |
| 4 | `extract_scapulohumeral_rhythm_all_comp.m` | steps 1 to 3 | Figure 2 |
| 5 | `extract_emg_cycles_all_comp.m` | K-LAB files | EMG cache |
| 6 | `extract_emg_discrete_all_comp.m` | step 5 | Figure 3 |
| 7 | `extract_kinematics_emg_coupling_all_comp.m` | steps 1, 5, 6 | Figure 4 |

## Article figures

**Figure 1. Humerothoracic elevation.** Elevation of the humerus relative to the thorax over the movement cycle, compared between conditions with SPM1D. Discrete parameters per trial: peak elevation, peak timing and rise time (time to reach half of the elevation range).

**Figure 2. Scapulothoracic kinematics as a function of humerothoracic elevation.** During the ascending phase, scapulothoracic angles are read at each elevation between 20 and 90 deg (1 deg steps) and compared between conditions with SPM1D, using elevation as the domain (N = 9, one participant not covering the range).

**Figure 3. Discrete EMG parameters.** Upper, middle and lower trapezius and serratus anterior. After removal of the stimulation artefact, each cycle gives a linear envelope (rectification and 6 Hz low-pass filter) normalised to 101 points. On each trial's mean envelope: peak timing and activity duration (time above minimum + 50 % of the range, i.e. full width at half maximum). Trial values are averaged per participant.

**Figure 4. Coupling between arm elevation and muscle activity.** EMG envelopes normalised to the peak of each trial, compared between conditions with SPM1D, and repeated-measures correlations between the humerothoracic rise time and the EMG peak timing and activity duration.

## Statistics

- Non-parametric repeated-measures ANOVA across the 7 conditions (10 000 permutations), on curves (SPM1D) or discrete values.
- If significant: paired t-tests on the 21 pairs of conditions, Holm-Bonferroni correction (alpha = 0.05), with `helpers/holmAlphaSPM1D.m` for curves and `helpers/holmAdjust.m` for discrete values.
- Repeated-measures correlation with `helpers/rmCorr.m` (Bakdash & Marusich 2017).

## Key parameters

| Parameter | Value | Script |
|-----------|-------|--------|
| EMG sampling frequency | 2200 Hz | EMG |
| Kinematic sampling frequency | 100 Hz | EMG |
| EMG low-pass filter | 6 Hz | EMG |
| Time normalisation | 101 points (0 to 100 %) | all |
| Family-wise alpha | 0.05 (Holm-Bonferroni) | all |
| Permutations | 10 000 | all |
| Activity threshold | 50 % of the envelope range | EMG discrete |
| Rise-time threshold | 50 % of the elevation range | humerothoracic |
| Elevation range | 20 to 90 deg, 1 deg steps | scapulohumeral rhythm |

## References

- Bakdash JZ, Marusich LR (2017). Repeated measures correlation. Front Psychol 8:456.
- Burden A (2010). How should we normalize electromyograms obtained from healthy participants? J Electromyogr Kinesiol 20:1023-1035.
- Holm S (1979). A simple sequentially rejective multiple test procedure. Scand J Stat 6:65-70.
- Pataky TC (2010). Generalized n-dimensional biomechanical field analysis using statistical parametric mapping. J Biomech 43:1976-1982.
