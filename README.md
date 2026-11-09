# Effects of functional electrical stimulation task-specific optimised patterns on perceptual and biomechanical outcomes during arm elevation

> **Project RELIEF** | Biomechanics and Translational Research in Surgery Group, University of Geneva
> [Research group](https://www.unige.ch/medecine/chiru/en/research-groups/nicolas-holzer-et-florent-moissenet)

## Overview

This repository contains the code used to process and analyse the biomechanical data of the article above. The study compares a rehabilitation-like functional electrical stimulation (FES) pattern of the deltoid with four optimised patterns, in healthy participants, during arm elevation in the scapular plane.

Ten participants performed three trials per condition, each trial comprising three arm elevations. Conditions: no stimulation (No FES), rehabilitation-like pattern (Rehab), optimised patterns (Min PW, Min force, Min stress, Min fatigue) and a non-optimised pattern (Random), which is kept in the extraction scripts but not used in the article analyses. One No FES trial was not recorded for one participant, which gives 209 trials. Scapulothoracic and EMG analyses include nine participants, as one participant did not reach elevation angles below approximately 30 degrees; a sensitivity analysis includes all ten.

## What this repository covers

- **Thoracohumeral elevation**: curve over the movement cycle and discrete parameters, to check the movement performed
- **Scapulothoracic kinematics**: angles against thoracohumeral elevation and their deviation from No FES (main hypothesis)
- **Surface EMG** of the upper, middle and lower trapezius and the serratus anterior: stimulation-artefact attenuation, linear envelope normalised to its peak, against thoracohumeral elevation (exploratory)
- **Statistics**: paired permutation tests, with one-dimensional Statistical Parametric Mapping (SPM1D) for curves and Holm-Bonferroni correction

The perceptual ratings of the article (discomfort and assistance) are analysed separately and are not part of this repository.

## Repository structure

```
.
├── 0-Preprocessing/       conversion of the motion-capture files (C3D) and signal preprocessing
├── 1-Processing/          K-LAB upper-limb toolbox (Protocol01): segments, joint kinematics and
│                          movement cycles; produces one .mat file per participant
└── 2-Final processing/
    └── Results/           analyses and figure of the article
```

`0-Preprocessing/` and `1-Processing/` are the K-LAB processing toolbox (Kinesiology Laboratory, University of Geneva), adapted for this protocol. The analyses of the article are in [`2-Final processing/Results/`](2-Final%20processing/Results/README.md), whose README describes the scripts, the order in which to run them and what they produce.

## Getting started

1. Install MATLAB (see Dependencies).
2. Copy `2-Final processing/Results/helpers/local_paths_template.m` to `helpers/local_paths.m` and set your two data folders. This file is not tracked by git.
3. Run the scripts of `2-Final processing/Results/pipeline/` in the order given in its [README](2-Final%20processing/Results/README.md).

## Data

Participant data are not included in this repository.

## Dependencies

- MATLAB R2026a (R2023a or later required), with the Signal Processing Toolbox
- [spm1dmatlab](https://spm1d.org/), included in `2-Final processing/Results/spm1dmatlab-master/`: Pataky TC (2010). *Generalized n-dimensional biomechanical field analysis using statistical parametric mapping.* J Biomech 43:1976-1982.
- [Biomechanical ToolKit (btk)](https://biomechanical-toolkit.github.io/), included in `0-Preprocessing/dependencies/btk/`, to read C3D files

## License

This work is licensed under the [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/).
© 2026 H. Francalanci, University of Geneva
