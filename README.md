# RELIEF Project: Functional Electrical Stimulation of the Deltoid : Scapulothoracic and Electromyography analysis

> **Project RELIEF** | Biomechanics and Translational Research in Surgery Group  
> University of Geneva : [Research group](https://www.unige.ch/medecine/chiru/en/research-groups/nicolas-holzer-et-florent-moissenet)

## Overview

This repository contains the data processing pipeline developed for the **RELIEF** project, investigating the effect of Functional Electrical Stimulation (FES) of the deltoid on scapular kinematics and superficial scapular stabilizator EMG activity in asymptomatic patients.

Ten patients performed repeated arm elevation tasks (scapular plane) across seven FES conditions (No FES + 6 stimulation protocols), each repeated over 3 blocks, for a total of 21 trials per patient.

## What this repository covers

- **FES artefact removal** from raw EMG signals (adaptive MAD threshold, blanking, PCHIP interpolation)
- **Scapular kinematics** extraction and analysis (3 DOF, YXZ sequence, ISB convention)
- **Surface EMG** cycle extraction, linear envelope, and % baseline normalisation
- **SPM1D statistical analysis** at two levels: grouped (N=10 patients) and individual (N=3 blocks, exploratory)
- Summary heatmaps of individual SPM1D results for kinematics and EMG

## Repository structure

Stim_Dev/
├── 2-Final processing/
│ └── Results/ ← MATLAB analysis scripts
│ ├── usercommands_conditions.m ← central configuration
│ ├── compare_fes_nofes.m ← FES artefact exploration
│ ├── preprocess_fes_removal.m ← FES removal verification
│ ├── verify_fes_batch.m ← batch quality control
│ ├── extract_scapular_kinematics.m
│ ├── extract_emg_cycles.m
│ ├── heatmap_spm_individuel_kin.m
│ └── heatmap_spm_individuel_emg.m
└── README.md

See [`2-Final processing/Results/README.md`](2-Final%20processing/Results/README.md) for the full pipeline documentation.

## Dependencies
- MATLAB R2024a
- [spm1dmatlab](https://spm1d.org/) : Pataky TC (2010). *Generalized n-dimensional biomechanical field analysis using statistical parametric mapping.* J Biomechanics.

## License
This work is licensed under the [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/).
© 2026 H. Francalanci : University of Geneva