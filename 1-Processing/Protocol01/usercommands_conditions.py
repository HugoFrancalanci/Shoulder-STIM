"""
usercommands_conditions.py
Configuration patient-spécifique pour l'extraction cinématique scapulaire.
Projet STIM_KC | K-LAB toolbox Protocol01

Référence structure .mat : CutCycles.m, MAIN_Protocol_01_NORM.m
Données conditions       : Data_clean.xlsx
"""

# ---------------------------------------------------------------------------
# CÔTÉ DOMINANT — détermine quel cycle (rcycle/lcycle) et quel joint (RST/LST)
# ---------------------------------------------------------------------------
DOMINANT_SIDE = {
    'P001': 'R',
    'P002': 'R',
    'P003': 'R',
    'P004': 'R',
    'P005': 'R',
    'P006': 'L',
    'P007': 'R',
    'P008': 'L',
    'P009': 'R',
    'P010': 'L',
}

# ---------------------------------------------------------------------------
# INDEX DU JOINT SCAPULO-THORACIQUE
# Vérifié dans P1.mat : Joint[2]=RST (seq YXZ), Joint[7]=LST (seq YXZ)
# DOF : angle[0]=rotation vers le haut/bas (Y), angle[1]=bascule ant/post (X),
#        angle[2]=rotation interne/externe (Z)
# ---------------------------------------------------------------------------
SCAPULA_JOINT_IDX = {'R': 2, 'L': 7}

# ---------------------------------------------------------------------------
# 8ÈME ANALYTIC2 TOUJOURS VIDE (tous patients)
# Confirmé : Trial[11] dans P1.mat → Rcycles=0, Signal.cycle vide
# Position 7 (0-based) dans la séquence ANALYTIC2 après application des skips patient
# ---------------------------------------------------------------------------
EMPTY_ANALYTIC2_POS = 7  # 0-based

# ---------------------------------------------------------------------------
# CAS PARTICULIERS PAR PATIENT
# ---------------------------------------------------------------------------
# 'skip_first_n'  : ignorer les N premiers ANALYTIC2 du .mat (avant le mapping)
# 'skip_positions': set d'indices (0-based, après skip_first_n) à exclure du mapping
# 'note'          : documentation
PATIENT_EXCEPTIONS = {
    # Fichiers ANALYTIC2 numérotés 2→22 au lieu de 1→21
    # → 1 fichier supplémentaire en tête dans le .mat → on saute le premier
    # → l'ordre des conditions (Excel) reste correct
    'P004': {
        'skip_first_n': 1,
        'note': 'ANALYTIC2 décalé de 1 (fichiers 2→22) — skip index 0 du .mat',
    },
    'P006': {
        'skip_first_n': 1,
        'note': 'ANALYTIC2 décalé de 1 (fichiers 2→22) — skip index 0 du .mat',
    },
    # Elevation_coronal 1 absent → remplacé par Elevation_sagittal 1 en position 0
    # Cinématique disponible, mouvement différent (sagittal≠coronal)
    # Aucun skip nécessaire, données utilisables pour l'analyse scapulaire
    'P007': {
        'note': 'ANALYTIC2[0] = Elevation_sagittal_1 (coronal manquant) — '
                'cinématique présente, mouvement sagittal au lieu de coronal',
    },
    # Deux fichiers Elevation_coronal en surnombre (n°4 et 18) dans le .mat
    # → skip positions 3 et 17 (0-based, après skip_first_n=0) pour revenir à 21 trials
    # HYPOTHÈSE : le .mat contient 23 ANALYTIC2 et les positions 3 et 17 sont les extra
    # → À VÉRIFIER sur P10.mat si mapping incorrect
    'P010': {
        'skip_positions': {3, 17},
        'note': 'Elevation_coronal 4 et 18 en surnombre — skip positions 3 et 17 (0-based)',
    },
}

# ---------------------------------------------------------------------------
# CHEMINS (à adapter selon l'environnement)
# ---------------------------------------------------------------------------
import os

DATA_FOLDER = r"C:\Users\franc\OneDrive - Université de Genève\PhD Hugo\02_Collaborations\C01_STIM_KC\Data"
EXCEL_PATH  = os.path.join(DATA_FOLDER, "Data_clean.xlsx")

# Mapping ID patient → nom de fichier .mat
MAT_FILES = {f'P{i:03d}': os.path.join(DATA_FOLDER, f'P{i}.mat') for i in range(1, 11)}
