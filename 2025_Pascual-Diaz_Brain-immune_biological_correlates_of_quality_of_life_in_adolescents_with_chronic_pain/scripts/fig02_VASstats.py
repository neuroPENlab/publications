#!/usr/bin/env python3
# -*- coding: utf-8 -*-
__author__ = "Saül Pascual-Diaz"
__institution__ = "University of Barcelona"
__date__ = "2025/05/28"
__version__ = "1"
__status__ = "Stable"
# ---------------------------------------------------------------------------
#  Build VAS-ratings dataframe 
# ---------------------------------------------------------------------------

import os, re, glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.stats import pearsonr, ttest_1samp

main_dir = '/path/to/VAS'

# ---------------------------------------------------------------------------
# Step 1 ─ find every …/SPRINT-####(_V2)/SPRINT-####_*StimuliRatings.txt file
# ---------------------------------------------------------------------------
pattern = os.path.join(main_dir,
                       'SPRINT-*',
                       'SPRINT-*_Multisensory_StimuliRatings.txt')

files = glob.glob(pattern)                 # one level deep → fast

# ---------------------------------------------------------------------------
# Step 2 ─ choose ONE file per subject, preferring the *_V2 version
# ---------------------------------------------------------------------------
chosen = {}                                # sid:int → (is_v2:bool, path:str)

for path in files:
    folder = os.path.basename(os.path.dirname(path))      # e.g. SPRINT-3047_V2
    m = re.match(r'SPRINT-(\d+)(?:_V2)?$', folder)
    if not m:
        continue                                        # safety-net

    sid = int(m.group(1))

    is_v2 = folder.endswith('_V2')
    # keep first file seen, but overwrite if we meet a *_V2 one
    if (sid not in chosen) or is_v2:
        chosen[sid] = (is_v2, path)

# ---------------------------------------------------------------------------
# Step 3 ─ read each chosen file, grab the last 4 numeric answers
# ---------------------------------------------------------------------------
rows = []

for sid, (_, path) in sorted(chosen.items()):
    with open(path, encoding='utf-8') as f:
        lines = [ln.strip() for ln in f if ln.strip()]

    vals = []
    for ln in reversed(lines):             # scan upward from bottom
        try:
            vals.append(float(ln))
            if len(vals) == 4:             # got the last four → stop
                break
        except ValueError:
            continue                       # skip headers / dates

    if len(vals) < 4:                      # incomplete / malformed
        print(f'⚠️  SPRINT-{sid}: only {len(vals)} numeric lines – skipped')
        continue

    rows.append([f'SPRINT-{sid}'] + list(reversed(vals)))  # restore original order

# ---------------------------------------------------------------------------
# Step 4 ─ build tidy dataframe
# ---------------------------------------------------------------------------
df = (pd.DataFrame(rows,
                   columns=['sid', 'r1', 'r2', 'r3', 'r4'])
        .set_index('sid')
        .sort_index())

df_clin = pd.read_excel('/path/to/selfreports.xlsx', index_col='sid')

#%%

rows = []
for s in df.index:
    if df_clin.loc[s].cohort != 1:
        continue
    rows.append({
        'sid': s,
        'r1': df.loc[s].r1,
        'r2': df.loc[s].r2,
        'r3': df.loc[s].r3,
        'r4': df.loc[s].r4,
        'rmean': (df.loc[s].r1 + df.loc[s].r2 + df.loc[s].r3 + df.loc[s].r4) / 4,
        'pedsql_physical': df_clin.loc[s].pedsq_physical,
        'pedsql_psychosocial': (df_clin.loc[s].pedsq_emotion + df_clin.loc[s].pedsq_school + df_clin.loc[s].pedsq_social) / 3
    })
df_disc = pd.DataFrame(rows)

#%%

# Set seaborn style
sns.set(style="whitegrid", context="talk")

# === 1️⃣ Figure 1: Boxplot + Swarmplot + One-sample t-tests ===
df_long = df_disc.melt(id_vars=['sid'], value_vars=['r1', 'r2', 'r3', 'r4', 'rmean'],
                       var_name='response', value_name='value')

# === Adjusted Figure 1: Boxplot + Swarmplot + One-sample t-tests (with extra space) ===
plt.figure(figsize=(12, 12))
box_colors = sns.color_palette("pastel", 5)
swarm_colors = sns.color_palette("dark", 5)

sns.boxplot(data=df_long, x='response', y='value', palette=box_colors)
sns.swarmplot(data=df_long, x='response', y='value', palette=swarm_colors, alpha=0.6, size=5)

# Calculate a common higher y position for stars
y_max = df_long['value'].max() + 0.5  # lifted slightly more
for i, measure in enumerate(['r1', 'r2', 'r3', 'r4', 'rmean']):
    values = df_disc[measure].dropna()
    t_stat, p_val = ttest_1samp(values, 0)
    if p_val < 0.001:
        star = '***'
    elif p_val < 0.01:
        star = '**'
    elif p_val < 0.05:
        star = '*'
    else:
        star = 'ns'
    plt.text(i, y_max, star, ha='center', fontsize=16, color='black')

plt.title('VAS Unpleasantness (r1–r4 and Mean)', fontsize=18, pad=40)  # increased pad
plt.ylabel('VAS Unpleasantness')
plt.xlabel('Measure')
plt.show()


# === 2️⃣ Figure 2: Correlation Scatterplots (fixed axis) ===
qol_measures = ['pedsql_physical', 'pedsql_psychosocial']

for qol in qol_measures:
    plt.figure(figsize=(10, 10))
    sns.regplot(data=df_disc, x='rmean', y=qol, scatter_kws={'s': 60, 'alpha': 0.7}, line_kws={'color': 'red'})
    clean_data = df_disc[['rmean', qol]].replace([np.inf, -np.inf], np.nan).dropna()
    r_val, p_val = pearsonr(clean_data['rmean'], clean_data[qol])
    plt.title(f'rmean vs {qol}\nPearson r = {r_val:.3f}, p = {p_val:.4f}', fontsize=16, pad=20)
    plt.xlabel('Mean Response (rmean)')
    plt.ylabel(qol.replace('_', ' ').title())
    plt.xlim(0, 10)
    plt.ylim(0, 100)
    plt.show()
