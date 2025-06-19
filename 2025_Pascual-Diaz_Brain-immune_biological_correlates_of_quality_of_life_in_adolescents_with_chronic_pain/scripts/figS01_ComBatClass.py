#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__author__ = "Saül Pascual-Diaz"
__institution__ = "University of Barcelona"
__date__ = "2025/06/19"
__version__ = "1.1"  # added robust Excel export
__status__ = "Stable"

import os
import matplotlib.pyplot as plt
from sklearn.metrics import ConfusionMatrixDisplay
import numpy as np
import nibabel as nib
import matplotlib.pyplot as plt
from sklearn.pipeline import Pipeline
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import cross_val_score, StratifiedKFold, cross_val_predict
from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

main_dir = '/Users/spascual/data/SPRINT/bids_derivatives/PedsQL_analyses/ComBat_whole_sample/SPM_firstlevels'
main_dir_combat = '/Users/spascual/data/SPRINT/bids_derivatives/PedsQL_analyses/ComBat_whole_sample/SPM_firstlevels_ComBat_CON_maps'
f_list = {}
f_list_combat = {}
for s in sorted(os.listdir(main_dir)):
    if not os.path.isfile(f'{main_dir}/{s}/con_0001.nii'): continue
    f_list[s[4:]] = f'{main_dir}/{s}/con_0001.nii'
    
for f in sorted(os.listdir(main_dir_combat)):
    if f[-3:] != 'nii': continue
    f_list_combat[f[4:8]] = f'{main_dir_combat}/{f}'
    
#%%

# -- Preprocessing utilities --
def get_site_label(sub_id):
    return int(str(sub_id)[0])  # Extract site from subject ID

def load_images(f_dict):
    data = []
    labels = []
    for sub_id, path in f_dict.items():
        img = nib.load(path)
        img_data = img.get_fdata()
        img_data = np.nan_to_num(img_data, nan=0.0)  # Replace NaNs with 0
        flattened = img_data.flatten()
        data.append(flattened)
        labels.append(get_site_label(sub_id))
    return np.array(data), np.array(labels)

# -- Load data --
X_orig, y = load_images(f_list)
X_combat, _ = load_images(f_list_combat)

# -- Define classifier pipeline --
clf = Pipeline([
    ('scaler', StandardScaler()),
    ('rf', RandomForestClassifier(n_estimators=100, random_state=42))
])
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)

# -- Classification scores --
scores_orig = cross_val_score(clf, X_orig, y, cv=cv)
scores_combat = cross_val_score(clf, X_combat, y, cv=cv)

print(f"Original data accuracy: {np.mean(scores_orig):.3f} ± {np.std(scores_orig):.3f}")
print(f"ComBat-corrected data accuracy: {np.mean(scores_combat):.3f} ± {np.std(scores_combat):.3f}")

# -- Accuracy Bar Plot --
plt.bar(['Original', 'ComBat'], [np.mean(scores_orig), np.mean(scores_combat)],
        yerr=[np.std(scores_orig), np.std(scores_combat)], capsize=5)
plt.ylabel('Accuracy')
plt.title('Site Classification Accuracy')
plt.grid(axis='y')
plt.show()

# -- PCA Visualization --
def plot_pca(X, y, title):
    pca = PCA(n_components=2)
    X_pca = pca.fit_transform(X)
    plt.figure()
    for site in np.unique(y):
        idx = y == site
        plt.scatter(X_pca[idx, 0], X_pca[idx, 1], label=f"Site {site}", alpha=0.6)
    plt.title(title)
    plt.xlabel("PC1")
    plt.ylabel("PC2")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.show()

plot_pca(X_orig, y, "PCA: Original Data")
plot_pca(X_combat, y, "PCA: ComBat-Corrected Data")

# -- Confusion Matrices --
y_pred_orig = cross_val_predict(clf, X_orig, y, cv=cv)
y_pred_combat = cross_val_predict(clf, X_combat, y, cv=cv)

ConfusionMatrixDisplay.from_predictions(y, y_pred_orig, display_labels=['Site 1', 'Site 2', 'Site 3'], cmap='Blues')
plt.title('Original Data')
plt.show()

ConfusionMatrixDisplay.from_predictions(y, y_pred_combat, display_labels=['Site 1', 'Site 2', 'Site 3'], cmap='Blues')
plt.title('ComBat-Corrected Data')
plt.show()

#%% Paper figures:
# First, generate each of your figures again but save them to axes in a combined figure

fig, axs = plt.subplots(1, 3, figsize=(15, 5))  # Wide layout for side-by-side display

# --- 1. Accuracy bar plot ---
axs[0].bar(['Original', 'ComBat'], [np.mean(scores_orig), np.mean(scores_combat)],
           yerr=[np.std(scores_orig), np.std(scores_combat)], capsize=5)
axs[0].set_ylabel('Accuracy')
axs[0].set_title('Site Classification Accuracy')
axs[0].grid(axis='y')

# --- 2. Confusion matrix: Original data ---
ConfusionMatrixDisplay.from_predictions(y, y_pred_orig,
    display_labels=['Stanford', 'Cincinnati', 'Toronto'],
    cmap='Blues',
    ax=axs[1])
axs[1].set_title('Original Data')

# --- 3. Confusion matrix: ComBat-corrected data ---
ConfusionMatrixDisplay.from_predictions(y, y_pred_combat,
    display_labels=['Stanford', 'Cincinnati', 'Toronto'],
    cmap='Blues',
    ax=axs[2])
axs[2].set_title('ComBat-Corrected Data')

# Save the final figure with high resolution
plt.tight_layout()
plt.savefig("combat_validation_figure.png", dpi=600, bbox_inches='tight')  # high-res PNG
plt.savefig("combat_validation_figure.tiff", dpi=600, bbox_inches='tight')  # good for journals
plt.show()
