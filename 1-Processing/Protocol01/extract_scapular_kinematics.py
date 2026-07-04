"""
extract_scapular_kinematics.py
Extraction de la cinématique scapulaire (3 DOF) par patient et par condition.
Projet STIM_KC | K-LAB toolbox Protocol01

Pipeline :
  1. Lecture Data_clean.xlsx → ordre des conditions par patient
  2. Lecture .mat → filtrage des 21 trials ANALYTIC2 (avec exceptions patient)
  3. Pour chaque trial : moyenne des 3 cycles → vecteur (3 DOF × 101 pts)
  4. Export DataFrame tidy → CSV

Sortie (colonnes CSV) :
  patient | condition | block | trial_seq | dof | frame | angle_deg
  - block     : répétition 1/2/3 au sein de la condition (colonne 'Block' de l'Excel)
  - trial_seq : position 1-21 dans la séquence ANALYTIC2 du patient
  - dof       : 1=rotation haut/bas (Y), 2=bascule ant/post (X), 3=rot int/ext (Z)
  - frame     : 0–100 (cycle normalisé 101 pts)
  - angle_deg : valeur en degrés
"""

import sys
import os
import numpy as np
import pandas as pd
import scipy.io as sio
from pathlib import Path

# Ajouter le dossier courant au path pour importer usercommands_conditions
sys.path.insert(0, os.path.dirname(__file__))
from usercommands_conditions import (
    DOMINANT_SIDE, SCAPULA_JOINT_IDX, EMPTY_ANALYTIC2_POS,
    PATIENT_EXCEPTIONS, DATA_FOLDER, EXCEL_PATH, MAT_FILES,
)


# ---------------------------------------------------------------------------
# CHARGEMENT EXCEL — mapping condition pour chaque patient
# ---------------------------------------------------------------------------

def load_condition_map(excel_path):
    """
    Retourne un dict :
      { 'P001': [(condition, block), ...],  # liste de 21 tuples dans l'ordre d'enregistrement
        'P002': [...], ... }
    Si le fichier est verrouillé (ouvert dans Excel), une copie temporaire est utilisée.
    """
    import shutil, tempfile
    try:
        df = pd.read_excel(excel_path, header=0)
    except PermissionError:
        tmp = tempfile.NamedTemporaryFile(suffix='.xlsx', delete=False)
        tmp.close()
        shutil.copy2(excel_path, tmp.name)
        df = pd.read_excel(tmp.name, header=0)
        os.unlink(tmp.name)
    df.columns = [
        'participant_id', 'session_date', 'condition', 'Block', 'Repetition',
        'pain', 'assistance', 'current_da', 'current_dm', 'current_dp', 'Pattern_seed',
    ]
    df['participant_id'] = df['participant_id'].ffill()

    condition_map = {}
    for pid, group in df.groupby('participant_id', sort=False):
        condition_map[pid] = list(zip(group['condition'], group['Block'].astype(int)))

    return condition_map


# ---------------------------------------------------------------------------
# CHARGEMENT .MAT ET FILTRAGE ANALYTIC2
# ---------------------------------------------------------------------------

def load_analytic2_trials(mat_path, patient_id):
    """
    Charge le .mat, filtre les trials ANALYTIC2, et applique les exceptions patient.
    Retourne une liste de dicts (21 trials attendus).
    """
    mat = sio.loadmat(str(mat_path), simplify_cells=True)
    all_trials = mat['Trial']

    # Filtrer ANALYTIC2 uniquement
    analytic = [t for t in all_trials if t.get('task', '') == 'ANALYTIC2']

    exc = PATIENT_EXCEPTIONS.get(patient_id, {})

    # Skip des N premiers (P004, P006 — décalage de fichiers)
    skip_first = exc.get('skip_first_n', 0)
    if skip_first:
        analytic = analytic[skip_first:]

    # Skip des positions spécifiques (P010 — fichiers en surnombre)
    skip_pos = exc.get('skip_positions', set())
    if skip_pos:
        analytic = [t for i, t in enumerate(analytic) if i not in skip_pos]

    return analytic


# ---------------------------------------------------------------------------
# EXTRACTION CINÉMATIQUE SCAPULAIRE
# ---------------------------------------------------------------------------

def extract_scapula_mean(trial, side):
    """
    Extrait la moyenne des cycles scapulaires pour un trial.

    Retourne array (3, 101) ou None si données absentes.
    - dim 0 : 3 DOF (Y, X, Z selon séquence YXZ)
    - dim 1 : 101 frames normalisées (0–100%)
    """
    joint_idx  = SCAPULA_JOINT_IDX[side]
    cycle_key  = 'rcycle' if side == 'R' else 'lcycle'

    try:
        euler = trial['Joint'][joint_idx]['Euler']
        data  = euler.get(cycle_key, None)

        if data is None:
            return None
        if not isinstance(data, np.ndarray) or data.size == 0 or data.shape == (0,):
            return None
        if data.ndim < 2:
            return None

        # Forme attendue : (3, 101, n_cycles)
        # Moyenne sur l'axe des cycles (axe 2)
        if data.ndim == 3:
            return np.nanmean(data, axis=2)   # → (3, 101)
        elif data.ndim == 2:
            return data                         # déjà moyenné ou 1 seul cycle
        else:
            return None

    except (KeyError, IndexError, TypeError, AttributeError):
        return None


# ---------------------------------------------------------------------------
# EXTRACTION COMPLÈTE — tous patients
# ---------------------------------------------------------------------------

def extract_all(output_csv=None):
    """
    Extrait la cinématique scapulaire pour tous les patients.

    Retourne un DataFrame tidy (voir docstring module).
    Sauvegarde en CSV si output_csv est fourni.
    """
    condition_map = load_condition_map(EXCEL_PATH)
    records = []
    warnings = []

    for patient_id in sorted(DOMINANT_SIDE.keys()):
        mat_path = MAT_FILES.get(patient_id)
        side = DOMINANT_SIDE[patient_id]

        if not mat_path or not Path(mat_path).exists():
            warnings.append(f'[SKIP] {patient_id} : fichier .mat introuvable ({mat_path})')
            continue

        if patient_id not in condition_map:
            warnings.append(f'[SKIP] {patient_id} : absent du fichier Excel')
            continue

        conditions = condition_map[patient_id]    # liste de 21 (condition, block)
        print(f'Traitement {patient_id} (côté {side})...')

        try:
            analytic_trials = load_analytic2_trials(mat_path, patient_id)
        except Exception as e:
            warnings.append(f'[ERROR] {patient_id} : erreur chargement .mat — {e}')
            continue

        if len(analytic_trials) != len(conditions):
            warnings.append(
                f'[WARNING] {patient_id} : {len(analytic_trials)} trials ANALYTIC2 '
                f'vs {len(conditions)} lignes Excel — vérifier les exceptions patient'
            )

        n_trials = min(len(analytic_trials), len(conditions))

        for seq_idx in range(n_trials):
            condition, block = conditions[seq_idx]
            trial_seq = seq_idx + 1  # 1-based pour lisibilité

            # 8ème ANALYTIC2 toujours vide — on enregistre NaN pour garder la trace
            if seq_idx == EMPTY_ANALYTIC2_POS:
                for dof in range(1, 4):
                    for frame in range(101):
                        records.append({
                            'patient':    patient_id,
                            'condition':  condition,
                            'block':      block,
                            'trial_seq':  trial_seq,
                            'dof':        dof,
                            'frame':      frame,
                            'angle_deg':  np.nan,
                            'flag':       'empty_8th_analytic2',
                        })
                continue

            data = extract_scapula_mean(analytic_trials[seq_idx], side)

            if data is None:
                warnings.append(
                    f'[WARNING] {patient_id} trial {trial_seq} ({condition} block {block}) : '
                    f'cinématique absente'
                )
                for dof in range(1, 4):
                    for frame in range(101):
                        records.append({
                            'patient':    patient_id,
                            'condition':  condition,
                            'block':      block,
                            'trial_seq':  trial_seq,
                            'dof':        dof,
                            'frame':      frame,
                            'angle_deg':  np.nan,
                            'flag':       'no_data',
                        })
                continue

            # Vérification forme
            if data.shape != (3, 101):
                warnings.append(
                    f'[WARNING] {patient_id} trial {trial_seq} : shape inattendu {data.shape}'
                )
                continue

            for dof in range(3):
                for frame in range(101):
                    records.append({
                        'patient':    patient_id,
                        'condition':  condition,
                        'block':      block,
                        'trial_seq':  trial_seq,
                        'dof':        dof + 1,
                        'frame':      frame,
                        'angle_deg':  data[dof, frame],
                        'flag':       '',
                    })

    # Résumé
    print(f'\n--- Extraction terminée : {len(records)} lignes ---')
    for w in warnings:
        print(w)

    df = pd.DataFrame(records)

    if output_csv:
        df.to_csv(output_csv, index=False)
        print(f'Sauvegardé : {output_csv}')

    return df


# ---------------------------------------------------------------------------
# RÉSUMÉ PAR PATIENT × CONDITION (moyenne des 3 reps)
# ---------------------------------------------------------------------------

def summarize_by_condition(df):
    """
    Calcule la moyenne et l'écart-type des 3 répétitions par patient × condition × DOF.

    Retourne un DataFrame avec shape_résumée :
      patient | condition | dof | frame | mean_angle | std_angle
    """
    df_valid = df[df['flag'] == '']
    summary = (
        df_valid
        .groupby(['patient', 'condition', 'dof', 'frame'], sort=False)['angle_deg']
        .agg(mean_angle='mean', std_angle='std')
        .reset_index()
    )
    return summary


# ---------------------------------------------------------------------------
# POINT D'ENTRÉE
# ---------------------------------------------------------------------------

if __name__ == '__main__':
    output_csv = os.path.join(DATA_FOLDER, 'scapular_kinematics_tidy.csv')
    df = extract_all(output_csv=output_csv)

    print('\nAperçu (5 premières lignes) :')
    print(df.head())

    print('\nNombre de lignes valides par patient :')
    print(df[df['flag'] == ''].groupby('patient').size())

    summary = summarize_by_condition(df)
    summary_path = os.path.join(DATA_FOLDER, 'scapular_kinematics_summary.csv')
    summary.to_csv(summary_path, index=False)
    print(f'\nRésumé par condition sauvegardé : {summary_path}')
