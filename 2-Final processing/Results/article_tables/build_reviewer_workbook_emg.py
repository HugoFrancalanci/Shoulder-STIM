# =========================================================================
# build_reviewer_workbook_emg.py
# =========================================================================
# Author     :   H. Francalanci
#                Biomechanics and Translational Research in Surgery Group
#                University of Geneva
# License    :   Creative Commons Attribution-NonCommercial 4.0 International License
# Date       :   October 2026
# -------------------------------------------------------------------------
# Description :  Builds the reviewer workbook (EMG : SPM1D group/individual, discrete parameters, curves) from the JSON export
#                written by generate_reviewer_workbook_emg.m — never run directly, the
#                MATLAB script calls it :  python build_reviewer_workbook_emg.py <export.json> <out.xlsx>
#                Formatted sheets (Arial), live Excel formulas (Holm-
#                Bonferroni decision recomputed from the p-values, group
#                mean/SD curves, durations...), consistency checks against
#                the MATLAB decisions. fullCalcOnLoad is set so Excel
#                computes every formula when the file is opened.
# Dependencies : Python 3, openpyxl
# =========================================================================
import json, math, sys
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
from openpyxl.comments import Comment

SRC, OUT = sys.argv[1], sys.argv[2]
d = json.load(open(SRC, encoding='utf-8'))

FONT = 'Arial'
F_BASE = Font(name=FONT, size=10)
F_HEAD = Font(name=FONT, size=10, bold=True, color='FFFFFF')
F_TITLE = Font(name=FONT, size=14, bold=True)
F_BOLD = Font(name=FONT, size=10, bold=True)
F_NOTE = Font(name=FONT, size=9, italic=True, color='555555')
F_INPUT = Font(name=FONT, size=10, color='0000FF')
FILL_HEAD = PatternFill('solid', start_color='3F4E66')
FILL_SIG = PatternFill('solid', start_color='E8F1E4')
BORDER = Border(bottom=Side(style='thin', color='BFBFBF'))
P_FMT = '[<0.001]"<0.001";0.000'
P_FMT4 = '[<0.0001]"<0.0001";0.0000'
N1 = '0.0'

def val(x):
    if x is None: return None
    if isinstance(x, float) and math.isnan(x): return None
    return x

def header(ws, row, cols, widths, freeze=True):
    for j, c in enumerate(cols, 1):
        cell = ws.cell(row=row, column=j, value=c)
        cell.font = F_HEAD; cell.fill = FILL_HEAD
        cell.alignment = Alignment(horizontal='center', vertical='center', wrap_text=True)
    ws.row_dimensions[row].height = 42
    for j, w in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(j)].width = w
    if freeze:
        ws.freeze_panes = ws.cell(row=row+1, column=1)
        ws.auto_filter.ref = f"A{row}:{get_column_letter(len(cols))}{row}"

def style_body(ws, r1, r2, ncol):
    for r in range(r1, r2+1):
        for c in range(1, ncol+1):
            cell = ws.cell(row=r, column=c)
            if not cell.font.bold:
                cell.font = F_BASE
            cell.border = BORDER

def title(ws, text, sub):
    ws['A1'] = text; ws['A1'].font = F_TITLE
    ws['A2'] = sub; ws['A2'].font = F_NOTE

wb = Workbook()
th = d['thresholds']

# =====================================================================
# README
# =====================================================================
ws = wb.active; ws.title = 'README'
lines = [
    ('EMG — SPM1D and discrete-parameter results (group and individual)', F_TITLE),
    ('Project STIM_KC — surface EMG of upper (UT, TRAPS), middle (MT, TRAPM) and lower (LT, TRAPI) trapezius and serratus anterior (SA, SERRA), 10 participants (P001–P010), 7 FES conditions, ANALYTIC2 task (coronal-plane arm elevation).', F_BASE),
    ('Source: cache_emg_all_comp.mat (extract_emg_cycles_all_comp.m) and cache_emg_discrete_all_comp.mat (extract_emg_discrete_all_comp.m), 2-Final processing/Results. No value in this workbook was typed by hand.', F_NOTE),
    ('', F_BASE),
    ('Signal processing', F_BOLD),
    ('• FES artefact removal on the raw signal (conditions with stimulation): peak detection (MAD × 6), 8 ms blanking, PCHIP interpolation. Per cycle: full-wave rectification + 2nd-order Butterworth low-pass 6 Hz (linear envelope, Winter 2009), time-normalised to 101 points (0–100 % of the movement cycle).', F_BASE),
    ('• Amplitude normalisation: envelope / (mean + 3 SD of the pre-movement rest) × 100 → % baseline (not % MVC). Per trial: mean over cycles; per participant and condition: mean over the 3 trials (sheet Curves_Individual).', F_BASE),
    ('', F_BASE),
    ('Continuous analysis (SPM1D, Pataky 2010)', F_BOLD),
    ('• Group level (N = 10): non-parametric one-way repeated-measures ANOVA across the 7 conditions per muscle (permutation, 10 000 iterations, α = 0.05). If significant: two-tailed paired SPM{t} t-tests (random field theory inference) on all 21 condition pairs, Holm-Bonferroni step-down over the 21 pairs (family-wise α = 0.05). Test-level p = RFT probability of the observed max |t|; rejected tests are thresholded at their own Holm α. Sheet SPM1D_PostHoc_Holm reproduces the Holm decision with live Excel formulas.', F_BASE),
    ('• Individual level (exploratory): same design within each participant using the 3 trials as observations (df = 2).', F_BASE),
    ('', F_BASE),
    ('Discrete parameters (secondary, exploratory analysis)', F_BOLD),
    (f'• Computed on each trial\'s mean envelope, then averaged over the trials of each condition per participant: peak amplitude (% baseline), peak timing (% cycle), activity duration = total % of the cycle where the envelope exceeds min + X % × (peak − min), X = {th[0]} (full width at half maximum, FWHM — Cappellini et al. 2006, J Neurophysiol; Martino et al. 2014, J Neurophysiol) and X = {th[1]} (sensitivity analysis); crossing points linearly interpolated. Onset/offset of the main burst (window containing the peak, X = {th[0]}) are descriptive only. Peak timing is preferred to onset/offset detection for continuous shoulder elevation (Hawkes et al. 2019, PLoS One).', F_BASE),
    ('• Statistics per muscle × parameter: non-parametric RM-ANOVA (permutation, 10 000 iterations, α = 0.05); if significant, paired t-tests on the 21 pairs with Holm-Bonferroni (family-wise α = 0.05). Pairwise results are interpreted only when the ANOVA is significant. Sheet Discrete_Stats reproduces the Holm decision with live Excel formulas.', F_BASE),
    ('• Caution: peak amplitude is sensitive to isolated extreme values (possible residual stimulation artefacts in some trials); activity duration and peak timing are threshold-relative and independent of amplitude normalisation.', F_BASE),
    ('', F_BASE),
    ('Sheets', F_BOLD),
]
r = 1
for text, font in lines:
    c = ws.cell(row=r, column=1, value=text); c.font = font
    c.alignment = Alignment(wrap_text=True, vertical='top')
    ws.merge_cells(start_row=r, start_column=1, end_row=r, end_column=3)
    ws.row_dimensions[r].height = 20 if r == 1 else 14 * max(1, math.ceil(len(text) / 125)) + 2
    r += 1
for name, desc in [
    ('SPM1D_ANOVA', 'Group RM-ANOVA supra-threshold clusters (window, p) per muscle.'),
    ('SPM1D_PostHoc_Holm', 'All group post-hoc tests performed (muscles with a significant ANOVA × 21 pairs): test-level p, Holm rank/threshold/decision (formulas), SPM1D decision and check.'),
    ('SPM1D_Individual', 'Significant individual post-hoc windows (exploratory, N = 3 trials).'),
    ('Discrete_ANOVA', 'RM-ANOVA p-value per muscle × discrete parameter.'),
    ('Discrete_Stats', 'All 21 pairwise comparisons per muscle × parameter: means ± SD, paired difference, t, raw p, Holm decision (formulas) and Holm-adjusted p.'),
    ('Discrete_Summary', 'Mean ± SD per muscle × condition × parameter (formulas over Discrete_Participants).'),
    ('Discrete_Participants', 'Discrete parameters of every participant × condition × muscle (mean over trials), with the number of trials used.'),
    ('Curves_Individual', 'Mean envelope (101 points, % baseline) of every participant × condition × muscle.'),
    ('Curves_Group', 'Group mean and SD envelopes (formulas over Curves_Individual).'),
]:
    ws.cell(row=r, column=1, value=name).font = F_BOLD
    ws.cell(row=r, column=2, value=desc).font = F_BASE
    ws.merge_cells(start_row=r, start_column=2, end_row=r, end_column=3)
    r += 1
r += 1
ws.cell(row=r, column=1, value='p-values below 0.001 are displayed as "<0.001" (cell format; the exact value is kept). Cluster p-values reported as 0 by SPM1D correspond to p < 1e-4.').font = F_NOTE
ws.column_dimensions['A'].width = 24; ws.column_dimensions['B'].width = 60; ws.column_dimensions['C'].width = 60

# =====================================================================
# SPM1D_ANOVA
# =====================================================================
wa = wb.create_sheet('SPM1D_ANOVA')
title(wa, 'SPM1D group repeated-measures ANOVA (7 conditions, N = 10)', 'spm1d.stats.nonparam.anova1rm — permutation (10 000 iterations), α = 0.05. One row per supra-threshold cluster.')
cols = ['Muscle', 'Significant', 'Window start (% cycle)', 'Window end (% cycle)', 'Duration (% cycle)', 'p (permutation)']
header(wa, 4, cols, [26, 12, 14, 14, 13, 14])
row = 5
for a in d['anova']:
    wa.cell(row=row, column=1, value=a['muscle']); wa.cell(row=row, column=2, value='Yes' if a['sig'] else 'No')
    if a['sig']:
        wa.cell(row=row, column=3, value=val(a['start'])).number_format = N1
        wa.cell(row=row, column=4, value=val(a['end'])).number_format = N1
        wa.cell(row=row, column=5, value=f'=D{row}-C{row}').number_format = N1
        wa.cell(row=row, column=6, value=val(a['p'])).number_format = P_FMT
    row += 1
style_body(wa, 5, row-1, len(cols))

# =====================================================================
# SPM1D_PostHoc_Holm
# =====================================================================
wh = wb.create_sheet('SPM1D_PostHoc_Holm')
title(wh, 'SPM1D group post-hoc — Holm-Bonferroni decision (N = 10)',
      'Only muscles with a significant ANOVA are tested (serratus anterior: ANOVA n.s., no post-hoc). Columns F–J: live formulas; K: MATLAB decision; L: agreement check.')
wh['A3'] = 'Family-wise α'; wh['A3'].font = F_BOLD
wh['B3'] = 0.05; wh['B3'].font = F_INPUT
wh['B3'].comment = Comment('Family-wise alpha of the Holm-Bonferroni correction (study design value).', 'pipeline')
cols = ['Muscle', '', 'Condition A', 'Condition B', 'Test-level p (RFT, max |t|)', 'Family size m', 'Rank k', 'Holm threshold α/(m−k+1)',
        'p − threshold', 'Holm decision (Excel)', 'SPM1D decision (MATLAB)', 'Check', 'Participants individually significant (n)', 'Participant IDs']
header(wh, 4, cols, [26, 2, 13, 13, 15, 10, 9, 15, 13, 14, 14, 9, 15, 20])
tests = [t for t in d['posthoc'] if t['tested']]
r1, r2 = 5, 5 + len(tests) - 1
rng = lambda col: f'${col}${r1}:${col}${r2}'
for i, t in enumerate(tests):
    rr = r1 + i
    wh.cell(row=rr, column=1, value=t['muscle'])
    wh.cell(row=rr, column=3, value=t['condA']); wh.cell(row=rr, column=4, value=t['condB'])
    wh.cell(row=rr, column=5, value=val(t['p_test'])).number_format = P_FMT4
    wh.cell(row=rr, column=6, value=f'=COUNTIFS({rng("A")},A{rr})')
    wh.cell(row=rr, column=7, value=f'=COUNTIFS({rng("A")},A{rr},{rng("E")},"<"&E{rr})+1')
    wh.cell(row=rr, column=8, value=f'=$B$3/(F{rr}-G{rr}+1)').number_format = '0.00000'
    wh.cell(row=rr, column=9, value=f'=E{rr}-H{rr}').number_format = '0.00000'
    wh.cell(row=rr, column=10, value=f'=IF(_xlfn.MAXIFS({rng("I")},{rng("A")},A{rr},{rng("E")},"<="&E{rr})<0,"Significant","n.s.")')
    wh.cell(row=rr, column=11, value='Significant' if t['sig'] else 'n.s.')
    wh.cell(row=rr, column=12, value=f'=IF(J{rr}=K{rr},"OK","CHECK")')
    wh.cell(row=rr, column=13, value=t['nPatSig']); wh.cell(row=rr, column=14, value=t['patSig'] or None)
style_body(wh, r1, r2, len(cols))
wh.cell(row=r2+2, column=1, value='No group post-hoc comparison reached significance after Holm-Bonferroni (nor with the former Bonferroni correction).').font = F_NOTE

# =====================================================================
# SPM1D_Individual
# =====================================================================
wi = wb.create_sheet('SPM1D_Individual')
title(wi, 'SPM1D individual post-hoc — significant windows (exploratory, N = 3 trials)', 'Within-participant RM-ANOVA + Holm-corrected paired SPM{t} tests (df = 2).')
cols = ['Participant', 'Muscle', 'Condition A', 'Condition B', 'Window start (% cycle)', 'Window end (% cycle)', 'Duration (% cycle)', 'Cluster p']
header(wi, 4, cols, [11, 26, 13, 13, 13, 13, 12, 11])
row = 5
for p in d['indiv']:
    for c, v in enumerate([p['patient'], p['muscle'], p['condA'], p['condB'], p['start'], p['end']], 1):
        wi.cell(row=row, column=c, value=val(v))
    wi.cell(row=row, column=7, value=f'=F{row}-E{row}')
    for c in (5, 6, 7): wi.cell(row=row, column=c).number_format = '0.0'
    wi.cell(row=row, column=8, value=val(p['p_cluster'])).number_format = P_FMT
    row += 1
style_body(wi, 5, row-1, len(cols))

# =====================================================================
# Discrete_Participants
# =====================================================================
PARAMS = d['discParams']; DESCR = d['discDescr']; LABELS = d['discLabels']
allF = PARAMS + DESCR
FLABEL = dict(zip(PARAMS, LABELS))
FLABEL[DESCR[0]] = f'Main-burst onset > {th[0]}% (% cycle)'
FLABEL[DESCR[1]] = f'Main-burst offset > {th[0]}% (% cycle)'
wp = wb.create_sheet('Discrete_Participants')
title(wp, 'Discrete EMG parameters — every participant × condition × muscle', 'Each value = mean over the participant\'s trials of that condition (column "Trials used").')
cols = ['Muscle', 'Condition', 'Participant', 'Trials used'] + [FLABEL[f] for f in allF]
header(wp, 4, cols, [26, 13, 11, 9] + [15]*len(allF))
row = 5
blocks = []; cur = None
for rec in d['disc']:
    key = (rec['muscle'], rec['cond'])
    if key != cur:
        if cur: blocks.append((*cur, first, row-1))
        cur = key; first = row
    for c, v in enumerate([rec['muscle'], rec['cond'], rec['patient'], rec['nBlocks']], 1):
        wp.cell(row=row, column=c, value=v)
    for k, f in enumerate(allF):
        cell = wp.cell(row=row, column=5+k, value=val(rec[f])); cell.number_format = N1
    row += 1
blocks.append((*cur, first, row-1))
style_body(wp, 5, row-1, len(cols))

# =====================================================================
# Discrete_Summary
# =====================================================================
wsum = wb.create_sheet('Discrete_Summary')
title(wsum, 'Discrete EMG parameters — mean ± SD across participants (N = 10)', 'Live formulas over Discrete_Participants.')
cols = ['Muscle', 'Condition']
for f in allF: cols += [f'{FLABEL[f]} — mean', 'SD']
header(wsum, 4, cols, [26, 13] + [14, 9]*len(allF))
row = 5
for (mus, cond, fr, lr) in blocks:
    wsum.cell(row=row, column=1, value=mus); wsum.cell(row=row, column=2, value=cond)
    for k in range(len(allF)):
        col = get_column_letter(5+k)
        wsum.cell(row=row, column=3+2*k, value=f'=AVERAGE(Discrete_Participants!{col}{fr}:{col}{lr})').number_format = N1
        wsum.cell(row=row, column=4+2*k, value=f'=STDEV(Discrete_Participants!{col}{fr}:{col}{lr})').number_format = N1
    row += 1
style_body(wsum, 5, row-1, len(cols))

# =====================================================================
# Discrete_ANOVA
# =====================================================================
wda = wb.create_sheet('Discrete_ANOVA')
title(wda, 'Discrete parameters — repeated-measures ANOVA (7 conditions)', 'Non-parametric (permutation, 10 000 iterations), α = 0.05; spm1d 0D.')
cols = ['Muscle', 'Parameter', 'N', 'p (permutation)', 'Significant (α = 0.05)']
header(wda, 4, cols, [26, 36, 6, 14, 14])
row = 5
for a in d['discAnova']:
    for c, v in enumerate([a['muscle'], a['label'], a['n'], val(a['p'])], 1):
        wda.cell(row=row, column=c, value=v)
    wda.cell(row=row, column=4).number_format = P_FMT
    wda.cell(row=row, column=5, value=f'=IF(D{row}<0.05,"Yes","No")')
    row += 1
style_body(wda, 5, row-1, len(cols))
wda.cell(row=row+1, column=1, value='p = 1e-4 is the resolution limit of 10 000 permutations (displayed "<0.001").').font = F_NOTE

# =====================================================================
# Discrete_Stats
# =====================================================================
wds = wb.create_sheet('Discrete_Stats')
title(wds, 'Discrete parameters — pairwise comparisons (paired t-tests, Holm-Bonferroni per muscle × parameter)',
      'Diff = B − A (paired, mean ± SD). Columns M–Q are live formulas (Holm step-down); final decision requires a significant ANOVA. R = Holm-adjusted p from MATLAB; T checks agreement.')
wds['A3'] = 'Family-wise α'; wds['A3'].font = F_BOLD
wds['B3'] = 0.05; wds['B3'].font = F_INPUT
wds['B3'].comment = Comment('Family-wise alpha of the Holm-Bonferroni correction (study design value).', 'pipeline')
cols = ['Muscle', 'Parameter', 'Condition A', 'Condition B', 'A mean', 'A SD', 'B mean', 'B SD', 'Diff B − A mean', 'Diff SD', 't (df = N−1)',
        'p (raw)', 'Family size m', 'Rank k', 'Holm threshold', 'Holm decision (Excel)', 'ANOVA significant', 'Holm-adjusted p (MATLAB)',
        'Final decision (MATLAB)', 'Check']
header(wds, 4, cols, [26, 34, 13, 13, 10, 9, 10, 9, 11, 9, 9, 10, 9, 8, 11, 13, 11, 13, 13, 8])
pairs = d['discPairs']
r1, r2 = 5, 5 + len(pairs) - 1
rng = lambda col: f'${col}${r1}:${col}${r2}'
for i, p in enumerate(pairs):
    rr = r1 + i
    vals = [p['muscle'], p['label'], p['condA'], p['condB'], p['meanA'], p['sdA'], p['meanB'], p['sdB'], p['meanDiff'], p['sdDiff'], p['t'], p['p']]
    for c, v in enumerate(vals, 1):
        wds.cell(row=rr, column=c, value=val(v))
    for c in range(5, 11): wds.cell(row=rr, column=c).number_format = N1
    wds.cell(row=rr, column=11).number_format = '0.00'
    wds.cell(row=rr, column=12).number_format = P_FMT
    wds.cell(row=rr, column=13, value=f'=COUNTIFS({rng("A")},A{rr},{rng("B")},B{rr},{rng("L")},"<>")')
    wds.cell(row=rr, column=14, value=f'=COUNTIFS({rng("A")},A{rr},{rng("B")},B{rr},{rng("L")},"<"&L{rr})+1')
    wds.cell(row=rr, column=15, value=f'=$B$3/(M{rr}-N{rr}+1)').number_format = '0.0000'
    # marge p - seuil dans une colonne cachee (U) pour la regle step-down
    wds.cell(row=rr, column=21, value=f'=L{rr}-O{rr}')
    wds.cell(row=rr, column=16, value=f'=IF(_xlfn.MAXIFS({rng("U")},{rng("A")},A{rr},{rng("B")},B{rr},{rng("L")},"<="&L{rr})<0,"Significant","n.s.")')
    wds.cell(row=rr, column=17, value='Yes' if p['anovaSig'] else 'No')
    wds.cell(row=rr, column=18, value=val(p['pHolm'])).number_format = P_FMT
    wds.cell(row=rr, column=19, value='Significant' if p['sig'] else 'n.s.')
    wds.cell(row=rr, column=20, value=f'=IF(IF(AND(P{rr}="Significant",Q{rr}="Yes"),"Significant","n.s.")=S{rr},"OK","CHECK")')
style_body(wds, r1, r2, len(cols))
wds.column_dimensions['U'].hidden = True
for i, p in enumerate(pairs):
    if p['sig']:
        for c in range(1, len(cols)+1):
            wds.cell(row=r1+i, column=c).fill = FILL_SIG
wds.cell(row=r2+2, column=1, value='Green rows = significant after Holm-Bonferroni with a significant RM-ANOVA. Holm-adjusted p = max over lower ranks of min(1, (m−j+1)·p(j)).').font = F_NOTE

# =====================================================================
# Curves
# =====================================================================
wc = wb.create_sheet('Curves_Individual')
title(wc, 'Individual mean envelopes (% baseline), 101 points per cycle', 'One row per participant × condition × muscle. Columns = % of the movement cycle.')
cols = ['Muscle', 'Condition', 'Participant'] + [str(i) for i in range(101)]
header(wc, 4, cols, [26, 13, 11] + [7]*101)
row = 5; cblocks = []; cur = None
for c in d['curves']:
    key = (c['muscle'], c['cond'])
    if key != cur:
        if cur: cblocks.append((*cur, first, row-1))
        cur = key; first = row
    for k, v in enumerate([c['muscle'], c['cond'], c['patient']], 1):
        wc.cell(row=row, column=k, value=v).font = F_BASE
    for i, v in enumerate(c['y']):
        cell = wc.cell(row=row, column=4+i, value=val(v)); cell.number_format = N1; cell.font = F_BASE
    row += 1
cblocks.append((*cur, first, row-1))
wc.freeze_panes = 'D5'

wq = wb.create_sheet('Curves_Group')
title(wq, 'Group mean and SD envelopes (% baseline), N = 10', 'Live formulas: AVERAGE / STDEV over Curves_Individual.')
cols = ['Muscle', 'Condition', 'Statistic'] + [str(i) for i in range(101)]
header(wq, 4, cols, [26, 13, 10] + [7]*101)
row = 5
for (mus, cond, fr, lr) in cblocks:
    for stat, fn in (('Mean', 'AVERAGE'), ('SD', 'STDEV')):
        for k, v in enumerate([mus, cond, stat], 1):
            wq.cell(row=row, column=k, value=v).font = F_BASE
        for i in range(101):
            col = get_column_letter(4+i)
            cell = wq.cell(row=row, column=4+i, value=f'={fn}(Curves_Individual!{col}{fr}:{col}{lr})')
            cell.number_format = N1; cell.font = F_BASE
        row += 1
wq.freeze_panes = 'D5'

wb.calculation.fullCalcOnLoad = True  # Excel recalcule toutes les formules a l'ouverture
wb.save(OUT)
print('saved', OUT, 'spm tests', len(tests), 'disc pairs', len(pairs), 'disc blocks', len(blocks), 'curve blocks', len(cblocks))
