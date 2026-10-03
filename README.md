# RELIEF Project: Impact of optimized functional electrical stimulation pattern on perceptual and kinematic behaviour: a pilot study on healthy participants during arm elevation.

> **Project RELIEF** | Biomechanics and Translational Research in Surgery Group
> University of Geneva: [Research group](https://www.unige.ch/medecine/chiru/en/research-groups/nicolas-holzer-et-florent-moissenet)

## Overview

This repository contains the data processing and analysis code of the **RELIEF** project, which investigates the effect of functional electrical stimulation (FES) of the deltoid on shoulder kinematics and scapular muscle activity in healthy participants.

Ten participants performed repeated arm elevations in the scapular plane under seven conditions (No FES and six stimulation patterns), with three trials per condition (21 trials per participant).

## What this repository covers

- **Humerothoracic elevation** over the movement cycle (time course of the arm elevation)
- **Scapulothoracic kinematics** as a function of humerothoracic elevation (scapulohumeral rhythm)
- **Surface EMG** of the upper, middle and lower trapezius and the serratus anterior: stimulation-artefact removal, linear envelope, peak timing and activity duration
- **Coupling** between the timing of arm elevation and the timing of muscle activity
- **Statistics**: one-dimensional Statistical Parametric Mapping (SPM1D) and discrete-parameter tests across the seven conditions, with Holm-Bonferroni correction

## Repository structure

```
Stim_Dev/
├── 0-Preprocessing/      conversion of the motion-capture files (C3D) and signal preprocessing
├── 1-Processing/         K-LAB upper-limb toolbox (Protocol01): segments, joint kinematics,
│                         movement cycles; produces one .mat file per participant
└── 2-Final processing/
    └── Results/          analyses and figures of the article
```

`0-Preprocessing/` and `1-Processing/` are the K-LAB processing toolbox (Kinesiology Laboratory, University of Geneva), adapted for this protocol. The analyses of the article are in [`2-Final processing/Results/`](2-Final%20processing/Results/README.md), whose README describes the scripts, the order in which to run them and the figures they produce.

## Data

Participant data are not included in this repository. The scripts read the participant files and write the derived data in local folders defined in `2-Final processing/Results/usercommands_conditions.m` and `2-Final processing/Results/helpers/dataDir.m`.

## Dependencies

- MATLAB R2024a (R2023a or later required), with the Signal Processing Toolbox
- [spm1dmatlab](https://spm1d.org/), included in `2-Final processing/Results/spm1dmatlab-master/`: Pataky TC (2010). *Generalized n-dimensional biomechanical field analysis using statistical parametric mapping.* J Biomech 43:1976-1982.
- [Biomechanical ToolKit (btk)](https://biomechanical-toolkit.github.io/), included in `0-Preprocessing/dependencies/btk/`, to read C3D files

## License

This work is licensed under the [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/).
© 2026 H. Francalanci, University of Geneva
