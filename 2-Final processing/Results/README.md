# STIM_KC: final analyses

Analysis code for the article on the effect of seven deltoid stimulation conditions on shoulder kinematics and scapular muscle activity during arm elevation (10 participants, 3 trials per condition).

## Folder structure

```
Results/
├── usercommands_conditions.m   shared configuration (participants, conditions, paths), loaded with run()
├── README.md
├── pipeline/                   entry-point scripts (7): run these
├── plotting/                   figure functions (5), called by pipeline/
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
| 4 | `extract_scapulohumeral_rhythm_all_comp.m` | steps 1 to 3 | scapulohumeral rhythm cache |
| 5 | `extract_emg_cycles_all_comp.m` | K-LAB files | EMG cache |
| 6 | `extract_emg_elevation_all_comp.m` | steps 1, 4, 5 | Figure 2 |
| 7 | `export_source_data.m` | steps 1 to 6 | `Source_data_Figures1-2.xlsx`: data and statistics of the 2 figures |

## Article figures

**Figure 1. Humerothoracic elevation.** Elevation of the humerus relative to the thorax over the movement cycle, compared between conditions with SPM1D. Discrete parameters per trial: peak elevation, peak timing, rise time (time to reach half of the elevation range), and plane of elevation (orientation of the humerus in the transverse plane of the thorax, 0 deg = frontal plane) at peak elevation and averaged between 20 and 90 deg of elevation during the ascending phase. These parameters are also compared across the 6 FES conditions only.

**Figure 2. Scapulothoracic kinematics and scapular muscle activity as a function of humerothoracic elevation.** Both rows use the ascending phase, from 20 to 90 deg of elevation (1 deg steps). Curves are compared between conditions with SPM1D, using elevation as the domain.
- First row: scapulothoracic angles read at each elevation.
- Second row: EMG of the upper, middle and lower trapezius and serratus anterior. After removal of the stimulation artefact, each cycle gives a linear envelope (rectification and 6 Hz low-pass filter) normalised to 101 points. Each trial's envelope is expressed as a percentage of its own peak, the trials are averaged per participant, and the envelopes are read at each elevation as for the angles.

## Statistics

- Non-parametric repeated-measures ANOVA across the 7 conditions (10 000 permutations), on curves (SPM1D) or discrete values.
- If significant: paired t-tests on the 21 pairs of conditions, Holm-Bonferroni correction (alpha = 0.05), with `helpers/holmAlphaSPM1D.m` for curves and `helpers/holmAdjust.m` for discrete values.
- Discrete humerothoracic parameters: the same ANOVA is also run across the 6 FES conditions only.

## Key parameters

| Parameter | Value | Script |
|-----------|-------|--------|
| EMG sampling frequency | 2200 Hz | EMG |
| Kinematic sampling frequency | 100 Hz | EMG |
| EMG low-pass filter | 6 Hz | EMG |
| Time normalisation | 101 points (0 to 100 %) | all |
| Family-wise alpha | 0.05 (Holm-Bonferroni) | all |
| Permutations | 10 000 | all |
| Rise-time threshold | 50 % of the elevation range | humerothoracic |
| Elevation range | 20 to 90 deg, 1 deg steps | scapulohumeral rhythm, EMG elevation |
| EMG normalisation | % of the peak of each trial | EMG elevation |

## References

- Burden A (2010). How should we normalize electromyograms obtained from healthy participants? J Electromyogr Kinesiol 20:1023-1035.
- Holm S (1979). A simple sequentially rejective multiple test procedure. Scand J Stat 6:65-70.
- Pataky TC (2010). Generalized n-dimensional biomechanical field analysis using statistical parametric mapping. J Biomech 43:1976-1982.
