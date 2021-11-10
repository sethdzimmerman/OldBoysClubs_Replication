# -*- coding: utf-8 -*-
"""
Does k-fold cross validation over training data, computes precision and recall
scores, and creates precision-recall plots
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.model_selection import KFold
from sklearn.metrics import precision_score, recall_score

from link import MatchFinder, train_new_classifier

PROJECT_PATH = '../../../'
CR_MASTER = PROJECT_PATH + 'intermediate_data/updated_class_reports/all_years.csv'
RB_MASTER = PROJECT_PATH + 'intermediate_data/redbooks_master.csv'
TRAINING_DATA = PROJECT_PATH + 'code/clean/red_book_class_report_linking/training_data_new.csv'
CLASSIFIER = PROJECT_PATH + 'code/clean/red_book_class_report_linking/classifier.joblib'
N_FOLDS = 10


training_data = pd.read_csv(TRAINING_DATA, index_col=(0,1))

matchFinder = MatchFinder(CR_MASTER, RB_MASTER,TRAINING_DATA)
# rebuild classifier if necessary
if matchFinder.clf is None:
    print('rebuilding classifier...')
    train_new_classifier(CR_MASTER, RB_MASTER, TRAINING_DATA, CLASSIFIER)
# Use pairs in training data as candidate pairs
matchFinder.candidate_pairs = training_data.index
# Assemble features and do not discard any (use large radius)
matchFinder.assemble_features(radius=2)

features = matchFinder.features.values
labels = training_data['is_match']

kfold = KFold(n_splits=N_FOLDS, shuffle=True, random_state=152)
thresholds = np.linspace(0, 1, 100)
precisions = np.empty((N_FOLDS, len(thresholds)))
recalls = np.empty((N_FOLDS, len(thresholds)))
plt.figure(figsize=(10, 8))
plt.rcParams.update({'font.size': 12})
scoredfs = []
i = 0
for train_indices, test_indices in kfold.split(matchFinder.features, labels):
    X_train, X_test = features[train_indices], features[test_indices]
    y_train, y_test = labels[train_indices], labels[test_indices]
    # refit clf using this fold's X_train & y_train
    matchFinder.clf.fit(X_train, y_train)
    y_pred = matchFinder.clf.predict_proba(X_test)[:, 1]
    precision = []
    recall = []
    for t in thresholds:
        y_pred_bin = (y_pred >= t)
        precision.append(precision_score(y_test, y_pred_bin,
                                         zero_division=1))
        recall.append(recall_score(y_test, y_pred_bin))
    precisions[i] = precision
    recalls[i] = recall
    plt.plot(recall, precision,linewidth=3)
    i += 1
plt.xlabel('Recall', fontsize=14)
plt.ylabel('Precision', fontsize=14)
plt.title(f'Precision-recall curves for {N_FOLDS}-fold cross-validation', fontsize=18)
plt.savefig(PROJECT_PATH + 'output/figures/precision_recall_curves_cr_rb_linking.png')
plt.close()

fig, ax = plt.subplots(figsize=(10, 8))
ax.plot(thresholds, precisions.mean(axis=0), linewidth=3, label='Precision')
ax.plot(thresholds, recalls.mean(axis=0),  linewidth=3, label='Recall')
ax.legend()
ax.minorticks_on()
ax.grid(which='major')
ax.grid(which='minor', linestyle=':')
plt.xlabel('Threshold', fontsize=14)
plt.title(f'Average precision & recall across {N_FOLDS} folds with varying thresholds', fontsize=18)
plt.savefig(PROJECT_PATH + 'output/figures/precision_recall_tradeoff_cr_rb_linking.png')
plt.close()
