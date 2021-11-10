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


if __name__ == '__main__':
    time0 = time()

    # 1
    # clean_lr_redbooks.py
    # input: Raw Data\raw_facebooks\long-run\ 
    # output: Intermediate Data\Excel Files\longrun_series_redbooks.csv
    # purpose: clean handcoded redbook files & append
    execfile('clean_lr_redbooks.py')

    # 2
    # clean_lr_clasreports.py
    # input: Raw Data\handcoded\class_reports, Intermediate Data\Excel Files\updated_class_reports\all_years.csv
    # # output: Intermediate Data\Excel Files\longrun_series_class_reports.csv
    # purpose: Clean Birth Info, highschool and degree for newer class reports and join with the pre-cleaned old files
    execfile('clean_lr_classreports.py')

    # 3
    # link_lr_rb_cr.py
    # input: Intermediate Data\Excel Files\updated_class_reports\longrun_series_class_reports.csv, Intermediate Data\Excel Files\longrun_series_redbooks.csv
    # output: Intermediate Data\Excel Files\links\cr_rb_links\longrun_series_rb_cr_links.csv
    # purpose: find matching records between red books and class reports
    execfile('link_lr_rb_cr.py')

    # 4
    # clean_lr_rooms.py
    # input: Raw Data\Room_assignments\ 
    # output: Intermediate Data\Excel Files\longrun_series_rooms.csv
    # purpose: clean scraped room assignments for the longrun series
    execfile('clean_lr_rooms.py')

    os.chdir('./category_codes/')
    sys.path.append(os.getcwd())

    # 5
    # classify_categories.py
    # input: Intermediate Data\Excel Files\longrun_series_redbooks.csv, \Intermediate Data\Excel Files\updated_class_reports\longrun_series_class_reports.csv
    # output: Intermediate Data\Excel Files\links\category_codes\long-run\activity_codes.csv, high_school_codes.csv, occupation_codes.csv, club_codes.csv
    # purpose: assign codes for activities, highschools, occupations and adult clubs
    execfile('classify_categories.py')



    print(f'Finished in {time() - time0:.2f} seconds.')
