# -*- coding: utf-8 -*-
 

import sys
sys.path.append(".")
import os
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime

from create_redbooks_master import new_master, add_directory_to_master, merge_w_ocr_version
from class_ranks import Matcher, drop_duplicates

MASTER = '../../../Intermediate Data/Excel Files/redbooks_w_all_years.csv'
REDBOOKS_DIR = '../../../Raw Data/Red_Books/hand_coded'
PRE_1923_DIR = '../../../Raw Data/Red_Books/hand_coded/pre_1923'
POST_1939_DIR = '../../../Raw Data/Red_Books/hand_coded/post_1939'
OCR_VERSION = '../../../Raw Data/Red_Books/OCRed/red_books_allyears.csv'

# Create master containing all rb data
if os.path.isfile(MASTER):
    try:
        os.rename(MASTER, os.path.splitext(MASTER)[0] + datetime.now().strftime('_old_%Y-%m-%d.csv'))
    except FileExistsError:
        pass
new_master(MASTER)
add_directory_to_master(PRE_1923_DIR, MASTER)
add_directory_to_master(REDBOOKS_DIR, MASTER)
add_directory_to_master(POST_1939_DIR, MASTER)
merge_w_ocr_version(MASTER, OCR_VERSION)

# Add class rank links
matcher = Matcher(redbook_file=MASTER)
df = matcher.compile_all_ranks()
print(f'length before dedupeing is {len(df)}')
df = drop_duplicates(df)
print(f'length after dedupeing is {len(df)}')
df.to_csv('../../../Intermediate Data/codes/class_ranks_w_all_years.csv', index=False)
df = matcher.quality_check()
df.to_csv('../../../Intermediate Data/codes/class_ranks_w_all_years_qcheck.csv', index=False)


# Change context to category codes directory
os.chdir('category_codes')

from category_codes.activities import get_activities, get_codes_for_activities
from category_codes.activity_leadership import main
from category_codes.add_extra_rb_clubs import add_new_clubs
from category_codes.high_schools import get_rb_high_schools, get_codes_for_rb_high_schools

CAT_CODES_DIR = '../../../Intermediate Data/codes/w_all_years'
if not os.path.isdir(CAT_CODES_DIR):
    os.mkdir(CAT_CODES_DIR)

MASTER = os.path.join('../', MASTER)
# Add activities
rb_activities = get_activities(MASTER)
activity_codes = get_codes_for_activities(rb_activities)
activity_codes.to_csv(os.path.join(CAT_CODES_DIR, 'activity_codes.csv'))

# Add activity leadership
main(MASTER, os.path.join(CAT_CODES_DIR, 'activity_leadership.csv'))


# Add high schools
rb_high_schools = get_rb_high_schools(MASTER)
high_school_codes = get_codes_for_rb_high_schools(rb_high_schools)
high_school_codes.to_csv(os.path.join(CAT_CODES_DIR, 'high_school_codes.csv'))


# Compile match rates for each year
rb_df = pd.read_csv(MASTER, index_col='index')
act_df = pd.read_csv(os.path.join(CAT_CODES_DIR, 'activity_codes.csv'),
                     index_col='index')
hs_df = pd.read_csv(os.path.join(CAT_CODES_DIR, 'high_school_codes.csv'),
                    index_col='index')
years = []
act_match_rates = []
hs_match_rates = []
for year in rb_df['year'].unique():
    years.append(year)
    rb_thisyear = rb_df[rb_df['year'] == year]
    total_act = (pd.notna(rb_thisyear['activities']) | rb_thisyear['service_record'].apply(lambda x: pd.notna(x) and x != '0')).sum()
    indices = rb_thisyear.index.intersection(act_df.index)
    matches = (~indices.duplicated()).sum()
    act_match_rates.append(matches / total_act)
    total_hs = pd.notna(rb_thisyear['high_school']).sum()
    indices = rb_thisyear.index.intersection(hs_df.index)
    matches = (~indices.duplicated()).sum()
    hs_match_rates.append(matches / total_hs)
pd.DataFrame({
    'year': years,
    'activity_match_rates': act_match_rates,
    'high_school_match_rates': hs_match_rates
    }).to_csv(os.path.join(CAT_CODES_DIR, 'match_rates.csv'), index=False)
# save plots of match rates by year
plt.plot(years, act_match_rates)
plt.title('activity match rates by year')
plt.xlabel('year')
plt.savefig(os.path.join(CAT_CODES_DIR, 'activity_match_rates.png'))
plt.close()
plt.plot(years, hs_match_rates)
plt.title('high school match rates by year')
plt.xlabel('year')
plt.savefig(os.path.join(CAT_CODES_DIR, 'high_school_match_rates.png'))
plt.close()


# Add extra clubs, leadership, and honor lists
# This needs to be after the match rate analysis so we don't get >100% match rates
ROSTER_DIR = '../../../Raw Data/Clubs/from_Red_Books'
clubs_files = [os.path.join(ROSTER_DIR, f) for f in os.listdir(ROSTER_DIR) if os.path.splitext(f)[1] == '.xlsx']
for clubs_file in clubs_files:
    try:
        print(f'Updating activities from {clubs_file}...')
        add_new_clubs(clubs_file, os.path.join(CAT_CODES_DIR, 'activity_codes.csv'),
                      os.path.join(CAT_CODES_DIR, 'honor_lists.csv'),
                      os.path.join(CAT_CODES_DIR, 'activity_leadership.csv'))
    except FileNotFoundError:
        print(f'File {clubs_file} was not found. Most likely this was a temporary file.')
