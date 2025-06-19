#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Saül Pascual-Diaz"
__institution__ = "University of Barcelona"
__date__ = "2025/06/19"
__version__ = "1" 
__status__ = "Stable"

import pandas as pd
from scipy import stats
import statsmodels.stats.multitest as smm

df_results = pd.read_excel('/Users/spascual/Documents/projects/2025_SPRINT_QoL_manuscript/manuscript_covariates.xlsx')

# Define variables
predictors = ['vas_ps', 'vas_pu', 'fdi', 'promiss_dep', 'age', 'PubertyDev']
outcomes = ['pedsql_physical', 'pedsql_psychosocial']

# -----------------------------
# 1. Descriptive Statistics
# -----------------------------
descriptive = []
for var in predictors + outcomes:
    values = df_results[var].dropna()
    descriptive.append({
        'Variable': var,
        'Mean': round(values.mean(), 2),
        'SD': round(values.std(), 2),
        'N': values.count()
    })

df_desc = pd.DataFrame(descriptive)

# -----------------------------
# 2. Correlation Function
# -----------------------------
def run_correlation_with_homoscedasticity_check(df, x_var, y_var):
    data = df[[x_var, y_var]].dropna()

    # Levene's test (based on median split of predictor)
    median_split = data[x_var].median()
    group1 = data[data[x_var] <= median_split][y_var]
    group2 = data[data[x_var] > median_split][y_var]
    levene_stat, levene_p = stats.levene(group1, group2)

    if levene_p > 0.05:
        test = 'Pearson'
        r, p = stats.pearsonr(data[x_var], data[y_var])
    else:
        test = 'Spearman'
        r, p = stats.spearmanr(data[x_var], data[y_var])

    return {
        'Predictor': x_var,
        'Outcome': y_var,
        'Effect size (r)': round(r, 3),
        'p-value': p,
        'Test used': test,
        'Levene p': round(levene_p, 4)
    }

# -----------------------------
# 3. Run Correlations
# -----------------------------
correlation_results = []
for y in outcomes:
    for x in predictors:
        correlation_results.append(run_correlation_with_homoscedasticity_check(df_results, x, y))

df_corrs = pd.DataFrame(correlation_results)

# -----------------------------
# 4. FDR Correction
# -----------------------------
df_corrs['FDR-corrected p'] = smm.multipletests(df_corrs['p-value'], method='fdr_bh')[1].round(4)

# -----------------------------
# 5. Sort for readability
# -----------------------------
df_corrs.sort_values(by=['Outcome', 'p-value'], inplace=True)

# Final outputs
df_desc, df_corrs
