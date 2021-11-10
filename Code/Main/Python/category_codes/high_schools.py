"""
tools for categorizing high schools in Harvard red books

When executed (rather than imported), will ask for file path to red books master csv,
will load high schools from there, match those schools to codes from the HIGH_SCHOOL_KEY
then create a csv showing what high schools each redbook entry belongs to.
"""


import pandas as pd
import regex as re
import os
from tqdm import tqdm

HIGH_SCHOOL_KEY = {
    'main': '../../../../Code/Keys/high_school_key.xlsx',
    'longrun': '../../../../Code/Keys/lr_high_school_key.xlsx'
}

def process_regexes(regex_str):
    """Read 'regex' strings in high school key spreadsheet and compile them as regular expressions."""
    patterns = regex_str.split(', ')
    return [re.compile(p) for p in patterns]


unmatched = []


def get_rb_high_schools(source_files):
    if not isinstance(source_files, list):
        source_files = [source_files]
    return pd.concat((pd.read_csv(f, index_col='index')['high_school'] for f in source_files))


def get_codes(high_school,high_school_codes):
    """Iterates through high school codes to find which one matches the given school."""
    if not isinstance(high_school, str):
        return []
    high_school = high_school.lower()
    matches = []
    for i, r in high_school_codes.iterrows():
        if any(x.search(high_school) for x in r['regex']):
            matches.append(i)
    if not matches:
        unmatched.append(high_school)
    return matches


def format_codes(idx, high_school, high_school_codes):
    """Takes a red book index and list of high schools (e.g. from iteritems on a Series returned from get_rb_high_schools)
    finds high school codes for each high school, then returns a list of tuples, each tuple's first entry being the rb index
    and the other entry being a high school code.
    """
    codes = get_codes(high_school, high_school_codes)
    return [(idx, code) for code in codes]


def get_codes_for_rb_high_schools(rb_high_schools,key_type='main'):

    print('Loading high school codes & regexes...')
    # Category codes must be in first three cols of high school key spreadsheet
    code_file = HIGH_SCHOOL_KEY[key_type]
    high_school_codes = pd.read_excel(code_file, sheet_name=0, index_col=0,engine='openpyxl')
    high_school_codes['regex'] = high_school_codes['regex'].apply(process_regexes)

    print('Matching red book entries to codes...')
    codes = sum((format_codes(i, x, high_school_codes) for i, x in tqdm(
        rb_high_schools.iteritems(),
        total=len(rb_high_schools))), [])
    df = pd.DataFrame(codes)
    df.columns = ['index', 'school code']
    df.set_index('index', drop=True, inplace=True)
    return df


if __name__ == '__main__':
    if os.path.isfile('../../../../Intermediate Data/Excel Files/redbooks_master.csv'):
        redbook_source = '../../../../Intermediate Data/Excel Files/redbooks_master.csv'
    else:
        redbook_source = input('Type the file path to the red books source CSV: ')
    rb_high_schools = get_rb_high_schools(redbook_source)
    codes = get_codes_for_rb_high_schools(rb_high_schools)
    try:
        codes.to_csv('../../../../Intermediate Data/codes/high_school_codes.csv')
    except FileNotFoundError:
        print('Saving to local directory {}...'.format(os.getcwd()))
        codes.to_csv('high_school_codes.csv')
