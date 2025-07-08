#!/usr/bin/env python3
# -*- coding: utf-8 -*-
__author__ = "Saül Pascual-Diaz"
__institution__ = "University of Barcelona"
__date__ = "2025/06/08"
__version__ = "1"
__status__ = "Stable"

"""
cytof_physical_qol_model.py

Feature selection and linear modeling pipeline for predicting PedsQL Physical scores
from CyTOF-derived immature neutrophil signaling markers in adolescents.

Steps:
1. Variance Inflation Factor (VIF) filtering to control collinearity
2. Bootstrapped stepwise selection (OLS, based on p-values)
3. Stable feature detection (selected in >50% of bootstraps)
4. Final OLS model fit with selected predictors
5. Optional: summary plot and CSV exports
"""

# Imports
import pandas as pd
import numpy as np
import statsmodels.api as sm
import matplotlib.pyplot as plt
import seaborn as sns
from statsmodels.tools.tools import add_constant
from statsmodels.stats.outliers_influence import variance_inflation_factor
from collections import Counter

# VIF
def filter_by_vif(X, threshold=10.0):
    """
    Iteratively removes variables with VIF above threshold.
    """
    variables = X.columns.tolist()
    while True:
        dropped = False
        X_const = add_constant(X[variables])
        vif = pd.Series(
            [variance_inflation_factor(X_const.values, i) for i in range(X_const.shape[1])],
            index=['const'] + variables
        )
        max_vif = vif[1:].max()
        if max_vif > threshold:
            drop_var = vif[1:].idxmax()
            print(f"⚠️ Dropping '{drop_var}' due to high VIF: {vif[drop_var]:.2f}")
            variables.remove(drop_var)
            dropped = True
        if not dropped:
            break
    return variables

# Stepwise regression
def stepwise_selection(X, y, initial_list=None, threshold_in=0.01, threshold_out=0.05, verbose=False):
    """
    Forward-backward stepwise feature selection using OLS p-values.
    """
    if initial_list is None:
        initial_list = []
    included = list(initial_list)
    while True:
        changed = False
        # Forward step
        excluded = list(set(X.columns) - set(included))
        new_pval = pd.Series(index=excluded, dtype=float)
        for col in excluded:
            model = sm.OLS(y, add_constant(X[included + [col]])).fit()
            new_pval[col] = model.pvalues[col]
        if not new_pval.empty:
            best_p = new_pval.min()
            if best_p < threshold_in:
                best_feat = new_pval.idxmin()
                included.append(best_feat)
                changed = True
                if verbose:
                    print(f"  + Add {best_feat:30} p={best_p:.4f}")
        # Backward step
        if included:
            model = sm.OLS(y, add_constant(X[included])).fit()
            pvalues = model.pvalues.iloc[1:]  # Exclude const
            worst_p = pvalues.max()
            if worst_p > threshold_out:
                worst_feat = pvalues.idxmax()
                included.remove(worst_feat)
                changed = True
                if verbose:
                    print(f"  - Drop {worst_feat:30} p={worst_p:.4f}")
        if not changed:
            break
    return included

# Bootstrap
def bootstrap_selection_vif(df, target_col, vif_thresh=10.0, n_bootstraps=500,
                             threshold_in=0.05, threshold_out=0.1, verbose=True):
    """
    Runs VIF filtering and bootstrapped stepwise selection.
    Returns selection frequencies dictionary.
    """
    X = df.drop(columns=[target_col])
    y = df[target_col]

    keep_vars = filter_by_vif(X, threshold=vif_thresh)
    X = X[keep_vars]
    df_filtered = pd.concat([X, y], axis=1)

    counts = Counter()
    for i in range(n_bootstraps):
        sample_idx = np.random.choice(df_filtered.index, size=len(df_filtered), replace=True)
        X_sample = df_filtered.loc[sample_idx, keep_vars]
        y_sample = df_filtered.loc[sample_idx, target_col]
        selected = stepwise_selection(X_sample, y_sample,
                                      threshold_in=threshold_in,
                                      threshold_out=threshold_out)
        counts.update(selected)
        if verbose and (i + 1) % 50 == 0:
            print(f"Bootstrap {i + 1}/{n_bootstraps}")
    freqs = {var: counts[var] / n_bootstraps for var in keep_vars}
    return freqs

# Main
if __name__ == "__main__":
    # Load or prepare data manually in the notebook context
    # Example:
    # df = pd.read_csv("behavior.csv", index_col="SubjID")
    # df_cytof_filtered = pd.read_csv("cytof_data.csv", index_col="SubjID")

    # Drop unwanted columns
    df_filtered = df_cytof_filtered.drop(columns=['site'], errors='ignore')
    df_filtered['pedsql_physical'] = df['pedsql_physical']

    # Run pipeline
    freqs = bootstrap_selection_vif(
        df_filtered,
        target_col='pedsql_physical',
        vif_thresh=10.0,
        n_bootstraps=500,
        threshold_in=0.05,
        threshold_out=0.10,
        verbose=True
    )

    # Display selection frequencies
    sorted_freqs = dict(sorted(freqs.items(), key=lambda x: x[1], reverse=True))
    print("\nSelection frequencies:")
    for var, f in sorted_freqs.items():
        print(f"  {var:40} {f:.2%}")

    # Identify stable predictors
    stable_vars = [var for var, freq in sorted_freqs.items() if freq > 0.5]
    print("\nStable predictors (freq >50%):", stable_vars)

    # Final model
    if stable_vars:
        X_final = add_constant(df_filtered[stable_vars])
        y_final = df_filtered['pedsql_physical']
        model = sm.OLS(y_final, X_final).fit()
        print("\nFINAL MODEL SUMMARY\n", model.summary())

        # Optional: save coefficients
        model.params.to_csv("final_model_coefficients.csv")

        # Optional: plot
        predictor = stable_vars[0]
        sns.regplot(x=df_filtered[predictor], y=y_final)
        plt.title(f"Effect of {predictor} on PedsQL Physical")
        plt.xlabel(predictor)
        plt.ylabel("PedsQL Physical Score")
        plt.tight_layout()
        plt.savefig("predictor_vs_qol.png", dpi=300)
        plt.show()
    else:
        print("No predictors passed the stability threshold.")
