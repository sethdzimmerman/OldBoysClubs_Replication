"""
tools for categorizing activities in Harvard red books

When executed (rather than imported), will ask for file path to red books master csv,
will load activities and military service from there, match those activities to codes from the ACTIVITY_KEY
then create a csv showing what activity categories each redbook entry belongs to.
"""


import pandas as pd
import re
import os
from tqdm import tqdm
# Make output directories if necessary
if not os.path.isdir("../../../../Code/Keys/"):
    os.makedirs("../../../../Code/Keys/",exist_ok=True)
    
ACTIVITY_KEY = '../../../../Code/Keys/activity_key.xlsx'


def process_regexes(regex_str):
    """Read 'regex' strings in activity key spreadsheet and compile them as regular expressions."""
    patterns = regex_str.split(', ')
    return [re.compile(p) for p in patterns]


print('Loading activity codes & regexes...')
activity_codes = pd.read_excel(ACTIVITY_KEY, sheet_name=0, index_col=[0,1,2],engine='openpyxl')
activity_codes['regex'] = activity_codes['regex'].apply(process_regexes)

unmatched = []

def get_military(service_record):
    """Extracts the relevant substring from the service_record section of a red book profile"""
    if not isinstance(service_record, str) or service_record == '0':
        return []
    if service_record == '1':
        return ['Veteran']
    search = re.search(r'\(Branch\)[^A-Z]+?(.*?)(?:;|\(|$)', service_record)
    if search:
        return [search.group(1)]
    else:
        # no match
        return []


def get_activities(source_files,data='rb'):
    """
    Load activities from red books master or updated class reports 
    as a pandas Series containing lists of activities
    """
    if not isinstance(source_files, list):
        source_files = [source_files]
    if data == 'rb':
        id = 'index'
    elif data == 'cr':
        id = 'PID'
    all_dfs = pd.concat((pd.read_csv(f, index_col=id) for f in source_files))
    if data == 'cr':
        # Remove year range from activities in new class reports
        all_dfs['activities'] = [
            re.sub(r'(19\d{2}\-(19)?\d{2}|19\d{2})','',x)
            if isinstance(x,str)
            else ''
            for x in all_dfs['activities']
        ]

    activities = all_dfs['activities'].apply(lambda x: re.split(r'(?:, ?|\n|; )', x) if isinstance(x, str) else [])

    # Add military for redbooks
    if data == 'rb':
        military = all_dfs['service_record'].apply(get_military)
        out = activities + military
    else:
        out = activities
    return out  


def get_code(activity):
    """Iterates through activity codes to find which one matches the given activity."""
    if activity is None:
        return None
    activity = activity.lower()
    for i, r in activity_codes.iterrows():
        if any(x.search(activity) for x in r['regex']):
            return i
    # print('Not found:', activity)
    unmatched.append(activity)
    return None


def format_codes(idx, activities):
    """Takes a red book index and list of activities (e.g. from iteritems on a Series returned from get_rb_activities)
    finds activity codes for each activity, then returns a list of tuples, each tuple's first entry being the rb index
    and the other three entries being an activity code.
    """
    codes = (get_code(a) for a in activities)
    return [(idx, *code) for code in codes if code is not None]


def get_codes_for_activities(activities,data='rb'):
    if data == 'rb':
        print('Matching redbooks entries to codes...')
        id = 'index'
    elif data == 'cr':
        print('Matching class reports entries to codes...')
        id = 'PID'

    codes = sum((format_codes(i, x) for i, x in tqdm(
            activities.iteritems(),total=len(activities))), [])
    # codes = [format_codes([get_code(x) for x in entry]) for entry in rb_activities]
    df = pd.DataFrame(codes)
    df.columns = [id, 'category code', 'subcategory code', 'activity code']
    df.set_index(id, drop=True, inplace=True)
    return df


if __name__ == '__main__':
    if os.path.isfile('../../../../Intermediate Data/Excel Files/redbooks_master.csv'):
        redbook_source = '../../../../Intermediate Data/Excel Files/redbooks_master.csv'
    else:
        redbook_source = input('Type the file path to the red books source CSV: ')
    rb_activities = get_activities(redbook_source)
    codes = get_codes_for_activities(rb_activities)


    try:
        codes.to_csv('../../../../Intermediate Data/codes/activity_codes.csv')
    except FileNotFoundError:
        print('Saving to local directory {}...'.format(os.getcwd()))
        codes.to_csv('activity_codes.csv')
