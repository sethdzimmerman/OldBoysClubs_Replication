# -*- coding: utf-8 -*-


import pandas as pd
import re
import os 

# Make output directories if necessary
if not os.path.isdir("../../../../Code/Keys/"):
    os.mkdir("../../../../Code/Keys/")
KEY_FILE = '../../../../Code/Keys/activity_leadership_key.xlsx'
RB_FILE = '../../../../Intermediate Data/Excel Files/redbooks_master.csv'
SAVE_LOC = '../../../../Intermediate Data/codes/activity_leadership.csv'


def import_regexes(key_file=KEY_FILE):
    key_sheet = pd.read_excel(key_file,engine='openpyxl')
    regexes = {}
    for i, r in key_sheet.iterrows():
        regex = re.compile(r['regex'], flags=re.IGNORECASE)
        regexes[regex] = r['code']
    return regexes

regexes = import_regexes()


def load_activities(rb_file=RB_FILE):
    rb = pd.read_csv(rb_file, index_col='index')
    return rb['activities']


def check_regexes(activities_entry, regexes=regexes):
    if not isinstance(activities_entry, str):
        return []
    else:
        return [regexes[r] for r in regexes if r.search(activities_entry)]


def check_all(activities):
    correspondencia = []
    for i, x in activities.iteritems():
        codes = check_regexes(x)
        correspondencia += list(zip([i]*len(codes), codes))
    return correspondencia


def main(rb_file=RB_FILE, save_loc=SAVE_LOC):
    activities = load_activities(rb_file)
    correspondencia = check_all(activities)
    pd.DataFrame(correspondencia, columns=['index', 'code']).to_csv(save_loc, index=False)


if __name__ == '__main__':
    main()