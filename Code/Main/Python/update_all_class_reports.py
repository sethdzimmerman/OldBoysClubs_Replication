"""
Runs class_reports/update_and_merge.py on all OCRed and hand-coded class reports
"""

import os
import re
import shutil
import sys
from datetime import datetime

sys.path.append('./class_reports')

from update_and_merge import update_and_merge, concat_all_years

OCRED_REPORTS = '../../../Raw Data/Class_Reports/OCRed'
HANDCODED_REPORTS = '../../../Raw Data/Class_Reports/hand_coded'
FIXES_DIR = '../../../Raw Data/Class_Reports/hand_fixes/'
UPDATED_REPORTS = '../../../Intermediate Data/Excel Files/updated_class_reports'


# Create update_reports directory if it does not exist
if not os.path.isdir(UPDATED_REPORTS):
    os.mkdir(UPDATED_REPORTS)

# Archive old files
now = datetime.now()
archive_dir = os.path.join(UPDATED_REPORTS, now.strftime('old_%Y-%m-%d'))
if not os.path.isdir(archive_dir):
    os.mkdir(archive_dir)
    for f in os.listdir(UPDATED_REPORTS):
        if f.endswith('.csv'):
            try:
                shutil.move(os.path.join(UPDATED_REPORTS, f), archive_dir)
            except PermissionError:
                print(f'Failed to move {f} to {archive_dir}. This is probably because that file is open in Excel.')


# Merge ocred and parsed files with hand-coded files
hand_coded_files = os.listdir(HANDCODED_REPORTS)

years = (re.search(r'(\d{4}).csv', x) for x in hand_coded_files)
years = [x.group(1) for x in years if x is not None]

    
for year in years:
    print(f"Now parsing profiles for year {year}")
    ocr_file = os.path.join(OCRED_REPORTS, '{}_optimized.txt'.format(year))
    hand_coded_file = os.path.join(HANDCODED_REPORTS, 'Harvard Cohorts - {}.csv'.format(year))
    save_as = os.path.join(UPDATED_REPORTS, '{}.csv'.format(year))
    try:
        update_and_merge(ocr_file,hand_coded_file,FIXES_DIR,save_as)
    except FileNotFoundError:
        print('One of\n{}\n{}\ndoes not exist. Skipping...'.format(ocr_file, hand_coded_file))

# Merge all files together and write to csv
df_out = concat_all_years(UPDATED_REPORTS,os.path.join(OCRED_REPORTS,"parsed"))
try:
    df_out.to_csv(os.path.join(UPDATED_REPORTS, 'all_years.csv'), index=False)
except PermissionError:
    print('Failed to write new class report master file because a user is currently accessing it (probably in Excel).',
          'Saving as "all_years-new.csv" instead. Rename this to "all_years.csv" when that file is no longer being used.')
    df_out.to_csv(os.path.join(UPDATED_REPORTS, 'all_years-new.csv'), index=False)