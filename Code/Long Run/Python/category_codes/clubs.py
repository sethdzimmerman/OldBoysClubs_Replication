"""
When executed (rather than imported), will ask for file path to class reports csv(s),
will load clubs and military service from there, match those clubs to codes from the ACTIVITY_KEY
then create a csv showing what club categories each class report entry belongs to.
"""


import pandas as pd
import re
import os
from tqdm import tqdm

ACTIVITY_KEY = '../../../../Code/Keys/club_key.xlsx'

CODE_COLS = ['code', 'social', 'honorary_or_political', 'obs15', 'professional', 'professional', 'gent_club', 'country_club', 'frat_order', 'hereditary', 'undergrad_club']


def process_regexes(regex_str):
    """Read 'regex' strings in club key spreadsheet and compile them as regular expressions."""
    return re.compile(regex_str)


print('Loading club codes & regexes...')
club_codes = pd.read_excel(ACTIVITY_KEY, sheet_name=0, index_col=list(range(len(CODE_COLS))),engine='openpyxl')
club_codes['regex'] = club_codes['regex'].apply(process_regexes)

unmatched = []


def get_clubs(source_files):
    """Load clubs from class reports as a pandas Series containing lists of clubs"""
    if not isinstance(source_files, list):
        source_files = [source_files]
    all_dfs = pd.concat((pd.read_csv(f, index_col='PID') for f in source_files))
    return all_dfs['member_of']


def get_codes(club):
    """Iterates through club codes to find which one matches the given club."""
    if pd.isna(club):
        return None
    club = club.lower()
    matches = []
    for i, r in club_codes.iterrows():
        if r['regex'].search(club):
            matches.append(i)
    if not matches:
        unmatched.append(club)
    return matches


def format_codes(idx, clubs):
    """Takes a PID and list of clubs (e.g. from iteritems on a Series returned from get_clubs)
    finds club codes for each club, then returns a list of tuples, each tuple's first entry being the rb index
    and the other three entries being a club code.
    """
    codes = get_codes(clubs)
    if codes:
        return [(idx, *code) for code in codes if code is not None]
    else:
        return []


def get_codes_for_clubs(clubs):
    print('Matching class report entries to codes...')
    codes = sum((format_codes(i, x) for i, x in tqdm(
        clubs.iteritems(),
        total=len(clubs))), [])
    df = pd.DataFrame(codes)
    df.columns = ['PID'] + CODE_COLS
    df.set_index('PID', drop=True, inplace=True)
    return df


if __name__ == '__main__':
    try:
        file = '../../../../Intermediate Data/Excel Files/updated_class_reports/all_years.csv'
        clubs = get_clubs(file)
    except FileNotFoundError:
        print('all_years.csv not found')
        filedir = input('Type the path to the folder that contains the class reports you want to match from: ')
        files = [os.path.join(filedir, f) for f in os.listdir(filedir) if f[-4:] == '.csv']
        clubs = get_clubs(files)
    codes = get_codes_for_clubs(clubs)
    try:
        codes.to_csv('../../../../Intermediate Data/codes/club_codes.csv')
    except FileNotFoundError:
        print('Saving to local directory {}...'.format(os.getcwd()))
        codes.to_csv('club_codes.csv')
