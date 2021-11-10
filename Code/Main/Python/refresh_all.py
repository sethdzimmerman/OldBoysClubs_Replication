# -*- coding: utf-8 -*-
"""
Run all code to rebuild data sets to reflect most up-to-date versions of
    raw data and code.
"""

import os
import sys
from time import time
import random

random.seed(10)

def execfile(filepath, globals=None, locals=None):
    """Code to make executing other python scripts easier"""
    if globals is None:
        globals = {}
    globals.update({
        "__file__": filepath,
        "__name__": "__main__",
    })
    with open(filepath, 'rb') as file:
        exec(compile(file.read(), filepath, 'exec'), globals, locals)


time0 = time()

# 1
# create_redbooks_master.py
# input: Raw Data\hand_coded\redbooks\ (only years overlapping with class report data)
# output: Intermediate Data\Excel Files\redbooks_master.csv
# purpose: clean handcoded redbook files & append
execfile('create_redbooks_master.py')

# 2
# update_all_class_reports.py
# input: Raw Data\Class_Reports/OCRed, Raw Data\hand_coded\class_reports
# output: Intermediate Data\Excel Files\updated_class_reports
# purpose: get missing fields for hand-checked class reports, assemble master version of class reports
execfile('update_all_class_reports.py')

# 3
# find_rb_cr_links.py
# input: Intermediate Data\Excel Files\updated_class_reports\all_years.csv, Intermediate Data\Excel Files\redbooks_master.csv
# output: Intermediate Data\Excel Files\Codes\cr_rb_links\all_years.csv
# purpose: find matching records between red books and class reports
execfile('find_rb_cr_links.py')

# 4
# class_ranks.py
# input: Intermediate Data\Excel Files\updated_class_reports\all_years.csv,
    # Intermediate Data\Excel Files\redbooks_master.csv,
    # Raw Data\Class_ranks (all files in that directory)
# output: Intermediate Data\Excel Files\Codes\class_ranks.csv
# purpose: match people in class reports and red books to class ranks data
execfile('class_ranks.py')

os.chdir('./category_codes/')
sys.path.append(os.getcwd())

# 5
# activities.py
# input: Intermediate Data\Excel Files\redbooks_master.csv
# output: Intermediate Data\Excel Files\Codes\category_codes\activity_codes.csv
# purpose: assign activity codes to each red book entry
execfile('activities.py')

# 6
# activity_leadership.py
# input: Intermediate Data\Excel Files\redbooks_master.csv
# output: Intermediate Data\Excel Files\Codes\category_codese\activity_leadership.csv
# purpose: assign codes for people who had leadership positions in activities/clubs
execfile('activity_leadership.py')

# 7
# add_extra_rb_clubs.py
# input: Raw Data\Clubs
# output: Intermediate Data\Excel Files\Codes\category_codes\activity_codes.csv (updates)
# output: Intermediate Data\Excel Files\Codes\category_codes\honor_lists.csv (creates)
# purpose: adds new clubs based on club rosters, also records honor list & dean's list and updates leadership stuff
execfile('add_extra_rb_clubs.py')

# 8
# high_schools.py
# input: Intermediate Data\Excel Files\redbooks_master.csv
# output: Intermediate Data\Excel Files\Codes\category_codes\high_school_codes.csv
# purpose: assign high school codes to each red book entry
execfile('high_schools.py')

# 9
# occupations.py
# input: Intermediate Data\Excel Files\updated_class_reports\all_years.csv
# output: Intermediate Data\Excel Files\Codes\category_codes\occupation_codes.csv
# purpose: assign occupation codes to each class report entry
execfile('occupations.py')

# 10
# clubs.py
# input: Intermediate Data\Excel Files\updated_class_reports\all_years.csv
# output: Intermediate Data\Excel Files\Codes\category_codes\club_codes.csv
# purpose: assign club codes to each class report entry
execfile('clubs.py')

# 11
# offices.py
# input: Intermediate Data\Excel Files\updated_class_reports\all_years.csv
# output: Intermediate Data\Excel Files\Codes\category_codes\offices.csv
# purpose: determines which people held high-ranking positions in some organization
execfile('offices.py')

# 12
# companies.py
# input: Intermediate Data\Excel Files\updated_class_reports\all_years.csv
# output: Intermediate Data\Excel Files\Codes\category_codes\offices.csv
# purpose: determines which people worked at companies on the 1955 Fortune 500 list
execfile('companies.py')

# 13
# final_clubs_and_frats.py
# input: Raw Data\hand_coded\registered_clubs\
# output: Intermediate Data\Excel Files\Codes\category_codes\final_clubs_and_frats.csv
# purpose: links registered clubs data to red books and class reports and categorizes by fraternity & final club
execfile('final_clubs_and_frats.py')

# 14
# senior_class_registers.py
# input: Raw Data\Class_registers\
# output: Intermediate Data\Excel Files\Codes\category_codes\senior_class_registers.csv
    # also updates Intermediate Data\Excel Files\Codes\activity_codes.csv and
    # Intermediate Data\Excel Files\Codes\final_clubs_and_frats.csv
execfile('senior_class_registers.py')

# 15
# harvard_brothers.py
# input: Intermediate Data\Excel Files\updated_class_reports\all_years.csv
# output: Intermediate Data\Excel Files\Codes\category_codes\harvard_brothers.csv
# purpose: identifies brothers within the class report data
execfile('harvard_brothers.py')

# 16
# college_majors.py
# input: Intermediate Data\Excel Files\Codes\category_codes\senior_class_registers.csv
# output: Intermediate Data\Excel Files\Codes\category_codes\college_major_codes.csv
# purpose: assign college major codes to each senior class register entry
execfile('college_majors.py')

os.chdir('../red_book_class_report_linking/')
sys.path.append(os.getcwd())

# 17
# cross_validation.py
# input: training_data_new.csv, class reports, & redbooks
# output: Fugures\precision_recall_tradeoff_cr_rb_linking.png
# purpose: runs a 10-fold cross-validation to estimate precision and recall at different thresholds.
execfile('cross_validation.py')

print(f'Finished in {time() - time0:.2f} seconds.')
