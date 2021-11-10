# -*- coding: utf-8 -*-
"""
Steps:
    Aggregate class register files
    For each entry in aggregated files:
        Search in corresponding CR year to find PID
        Search in corresponding RB year to find rb_index
        Merge with existing activity and final club/frat data
"""


import os
import re
import pandas as pd

from datetime import datetime
from jellyfish import damerau_levenshtein_distance

from activities import get_codes_for_activities
from occupations import get_classes_for_occupations, get_occupations

REGISTER_DIR = '../../../../Raw Data/Class_registers/'
CLASS_REPORTS = '../../../../Intermediate Data/Excel Files/updated_class_reports/all_years.csv'
RED_BOOKS = '../../../../Intermediate Data/Excel Files/redbooks_master.csv'
CR_RB_LINKS = '../../../../Intermediate Data/codes/cr_rb_links/all_years.csv'
OUTPUT = '../../../../Intermediate Data/codes/senior_class_registers.csv'
INTENDED_OCCUPATION_CODES = '../../../../Intermediate Data/codes/intended_occupation_codes.csv'
ACTIVITIES_OUT = '../../../../Intermediate Data/codes/activity_codes_from_senior_registers.csv'
FINAL_AND_FRATS = '../../../../Intermediate Data/codes/final_clubs_and_frats.csv'
FINAL_AND_FRATS_KEY = '../../../../Code/Keys/final_clubs_and_frats_key.xlsx'
FINAL_AND_FRATS_OUT = '../../../../Intermediate Data/codes/final_clubs_and_frats_from_senior_registers.csv'

QUALITY_CHECK = True
    

def load_register_df(filename, root=REGISTER_DIR):
    register_df = pd.read_excel(os.path.join(root, filename),engine='openpyxl')
    register_df = register_df.rename(str.lower, axis='columns').rename(
            {'birth date': 'birth_date',
             'place of birth': 'birth_place',
             'activites_and_honors': 'activities_and_honors',
             'intended_vocation': 'occupation',
             'field_of_concentration': 'major'},
            axis='columns'
        )
    register_df['class'] = int(re.search(r'(\d{4})\.xlsx$', filename).group(1))
    return register_df


def aggregate_register_dfs(root=REGISTER_DIR):
    filenames = (f for f in os.listdir(root) if f.endswith('.xlsx'))
    return pd.concat((load_register_df(f, root) for f in filenames))


def get_first_cr(name):
    try:
        return name.split()[0]
    except IndexError:
        return ''
    

def get_middle_cr(name):
    try:
        name = re.sub(r',.{0,4}$', '', name) # remove suffix
        parts = name.split()
        if len(parts) > 2:
            return parts[1]
        else:
            return ''
    except IndexError:
        return ''


def get_last_cr(name):
    search = re.search(r'[A-Za-z\'\-]+(?=$|,.{0,4}$)', name)
    if search:
        return search.group()
    else:
        try:
            return name.split()[-1]
        except IndexError:
            return ''
        

def get_first_middle_last_rb(name):
    name = re.sub(r',?\s?\(?e\. ?s\.\)?', '', name, flags=re.IGNORECASE).rstrip(', ')
    name = re.sub(r', (?:JR\.?|\d\S{0,3}|[A-Z]{1,3})$', '', name.strip(), flags=re.IGNORECASE)
    # Look for name of form LAST, FIRST(, JR.)
    search = re.search(r'^([^,]+), ?(\S.*?)$', name)
    if search is not None:
        first_parts = search.group(2).strip().split()
        if len(first_parts) > 1:
            return first_parts[0], first_parts[1], search.group(1).strip()
        else:
            return first_parts[0], '', search.group(1).strip()
    # Look for name of form FIRST LAST(, JR.)
    search = re.search(r'^(.*?)\s([^\s,]+)$', name)
    if search is not None:
        first_parts = search.group(1).strip().split()
        if len(first_parts) > 1:
            return first_parts[0], first_parts[1], search.group(2)
        else:
            return first_parts[0], '', search.group(2)
    # Give up
    return '', '', ''


def get_first_middle_last_registers(name):
    name = re.sub(r', (?:JR\.?|\d\S{0,3}|[A-Z]{1,3})$', '', name.strip(), flags=re.IGNORECASE)
    split = name.split()
    if len(split) > 2:
        return split[0], split[1][0], split[-1]
    elif len(split) == 2:
        return split[0], '', split[1]
    else:
        return '', '', ''
    

def get_date_cr(date):
    if not isinstance(date, str):
        return None
    # fix common mistakes in date
    date = date[:-4] + date[-4:].replace('o', '0')\
                                .replace('g', '9')\
                                .replace('r', '1')\
                                .replace('i', '1')\
                                .replace('I', '1')
    try:
        return datetime.strptime(date, '%d %B %Y')
    except ValueError:
        try:
            return datetime.strptime(date, '%d %b %Y')
        except ValueError:
            return None


def get_date_register(date):
    if not isinstance(date, str):
        return None
    date = date.replace(';', ',')\
               .replace(',1', ', 1')
    try:
        return datetime.strptime(date, '%B %d, %Y')
    except ValueError:
        try:
            return datetime.strptime(date, '%B %Y')
        except ValueError:
            print(date)
            # TODO: Address still existing alternate formats
            return None
        

def regularized_dam_lev(s1, s2):
    try:
        return 1 - damerau_levenshtein_distance(s1, s2) / max(len(s1), len(s2))
    except TypeError:
        # In case one is not valid, make agnostic guess of 0.5
        return 0.5
    
    

class Matcher:
    
    def __init__(self, class_report_file=CLASS_REPORTS, redbook_file=RED_BOOKS,
                 cr_rb_links_file=CR_RB_LINKS):
        
        cr_df = pd.read_csv(class_report_file, index_col='PID',
                                 usecols=['PID', 'year', 'name', 'birthDate', 'high_school_name'])
        # Regularize names
        cr_df['name'] = cr_df['name'].apply(
                lambda x: x.upper() if isinstance(x, str) else ''
            )
        # Separate first, middle, and last names, keep just initial also
        cr_df['first'] = cr_df['name'].apply(get_first_cr)
        cr_df['first_init'] = cr_df['first'].apply(lambda x: x[0] if x else '')
        cr_df['middle'] = cr_df['name'].apply(get_middle_cr)
        cr_df['middle_init'] = cr_df['middle'].apply(lambda x: x[0] if x else '')
        cr_df['last'] = cr_df['name'].apply(get_last_cr)
        cr_df['last_init'] = cr_df['last'].apply(lambda x: x[0] if x else '')
        # convert birth dates to datetime object
        cr_df['birth_date'] = cr_df['birthDate'].apply(get_date_cr)
        # Group class report data by year
        self.cr_classes = {year: cr_df[cr_df['year'] == year] \
                               for year in cr_df['year'].unique()}
        
        rb_df = pd.read_csv(redbook_file, index_col='index',
                            usecols=['index', 'year', 'name', 'high_school'])
        # do same cleaning for redbook data
        rb_df['name'] = rb_df['name'].apply(lambda x: x.upper() if isinstance(x, str) else '')
        rb_df['first'], rb_df['middle'], rb_df['last'] = tuple(zip(*rb_df['name'].apply(get_first_middle_last_rb)))
        rb_df['first_init'] = rb_df['first'].apply(lambda x: x[0] if x else '')
        rb_df['middle_init'] = rb_df['middle'].apply(lambda x: x[0] if x else '')
        rb_df['last_init'] = rb_df['last'].apply(lambda x: x[0] if x else '')
        self.rb_classes = {year: rb_df[rb_df['year'] == year] \
                               for year in rb_df['year'].unique()}
        # also save full rb_df and cr_df
        self.rb_df = rb_df
        self.cr_df = cr_df
        # load correspondence between class reports and red books
        self.cr_rb_links = pd.read_csv(cr_rb_links_file, index_col=['PID', 'index'])
    
    
    def look_for_matches(self, classes_df, year, first, last, full_first):
        look_in = classes_df.get(year)
        if look_in is None:
            return pd.DataFrame()
        if full_first:
            matches = look_in[(look_in['first'] == first) & (look_in['last'] == last)]
        else:
            matches = look_in[(look_in['first_init'] == first) & (look_in['last'] == last)]
        return matches
    
    
    def look_for_matches_typo_robust(self, classes_df, year, first, last, full_first):
        look_in = classes_df.get(year)
        if look_in is None:
            return pd.DataFrame()
        candidates = look_in[(look_in['first_init'] == first[0]) \
                                & (look_in['last_init'] == last[0])]
        if full_first:
            first_edits = candidates['first'].apply(lambda x: damerau_levenshtein_distance(x, first))
            last_edits = candidates['last'].apply(lambda x: damerau_levenshtein_distance(x, last))
            acceptable = (first_edits < 3) & (last_edits < 3)
            matches = candidates[acceptable].copy()
            matches['edits'] = first_edits[acceptable] + last_edits[acceptable]
        else:
            # If the last names differ by only 1 or 2 edits, treat it as a candidate match
            last_edits = candidates['last'].apply(lambda x: damerau_levenshtein_distance(x, last))
            acceptable = (last_edits < 3)
            matches = candidates[acceptable].copy()
            matches['edits'] = last_edits[acceptable]  # record number of edits needed
        # return whichever has/have least total edits
        if len(matches) > 1:
            return matches[matches['edits'] == matches['edits'].min()]
        else:
            return matches
    
    
    def look_for_cr_matches(self, year, first, last, full_first):
        return self.look_for_matches(self.cr_classes,
                                     year, first, last, full_first)
    
    def look_for_cr_matches_typo_robust(self, year, first, last, full_first):
        return self.look_for_matches_typo_robust(self.cr_classes,
                                                 year, first, last, full_first)
    
    def look_for_rb_matches(self, year, first, last, full_first):
        return self.look_for_matches(self.rb_classes,
                                     year, first, last, full_first)
    
    def look_for_rb_matches_typo_robust(self, year, first, last, full_first):
        return self.look_for_matches_typo_robust(self.rb_classes,
                                                 year, first, last, full_first)
    
    
    def find_matches_for_entries(self, register_df):
        print('Finding matches for club entries...')
        pids = []
        rb_indices = []
        confs = []
        names = []
        for i, row in register_df.iterrows():
            crconf = 0  # keep track of confidence for class report match
            rbconf = 0  # and for red book match
            year = row['class']
            # Extract first and last names using same method as with redbooks
            name = row['name'].replace('.', '').upper()  # remove . and make upper first
            first, middle_init, last = get_first_middle_last_registers(name)
            birth_date = get_date_register(row['birth_date'])
            high_school = row['prepared_at']
            if not first or not last:
                # Can't deal with names without both first and last
                pids.append(None)
                rb_indices.append(None)
                confs.append(None)
                names.append(None)
                continue
            full_first = (len(first) > 1)  # full first name or just an initial?
            if full_first:
                crconf += 1
                rbconf += 1
            
            # first look for class report match
            matches = self.look_for_cr_matches(year, first, last, full_first)
            if len(matches) == 0:
                # look for matches in surrounding years
                matches = pd.concat((self.look_for_cr_matches(year-1, first, last, full_first),
                                     self.look_for_cr_matches(year+1, first, last, full_first)))
                # if still no matches, try looking for typos, just in current year
                if len(matches) == 0:
                    matches = self.look_for_cr_matches_typo_robust(year, first, last, full_first)
                else:
                    crconf -= 1
            if len(matches) > 1:
                # filter to ones with matching middle initial
                matches = matches[matches['middle_init'] == middle_init]
                crconf += 1
            elif len(matches) > 0 and matches['middle_init'][0] == middle_init:
                crconf += 1
            # add hs and birth date scores
            matches['birth_date_same'] = matches['birth_date'].apply(
                lambda x: int(x == birth_date))
            matches['hs_similarity'] = matches['high_school_name'].apply(
                lambda x: regularized_dam_lev(x, high_school))
            if len(matches) > 1:
                # sift using birth date and high school
                matches = matches[
                    matches['birth_date_same'] == matches['birth_date_same'].max()]
                matches = matches[
                    matches['hs_similarity'] == matches['hs_similarity'].max()]
            if len(matches) != 1:
                # it's either ambiguous, or there is no match
                pid = None
            else:
                if 'edits' in matches.columns:
                    crconf -= 0.5*matches['edits'][0]  # reduce conf by 0.5*number of edits needed
                crconf += (2*matches['birth_date_same'][0] - 1)
                crconf += matches['hs_similarity'][0]
                pid = matches.index[0]
                
            # now look for red book match
            matches = self.look_for_rb_matches(year, first, last, full_first)
            if len(matches) == 0:
                matches = pd.concat((self.look_for_rb_matches(year-1, first, last, full_first),
                                     self.look_for_rb_matches(year+1, first, last, full_first)))
                if len(matches) == 0:
                    matches = self.look_for_rb_matches_typo_robust(year, first, last, full_first)
                else:
                    rbconf -= 1
            if len(matches) > 1:
                matches = matches[matches['middle_init'] == middle_init]
                rbconf += 1
            elif len(matches) > 0 and matches['middle_init'][0] == middle_init:
                rbconf += 1
            matches['hs_similarity'] = matches['high_school'].apply(
                lambda x: regularized_dam_lev(x, high_school))
            if len(matches) > 1:
                matches = matches[
                    matches['hs_similarity'] == matches['hs_similarity'].max()]
            if len(matches) != 1:
                rb_index = None
            else:
                if 'edits' in matches.columns:
                    rbconf -= 0.5*matches['edits'][0]
                rbconf += matches['hs_similarity'][0]
                rb_index = matches.index[0]
            
            # now compute combined confidence
            if not (pid is None or rb_index is None):
                try:
                    conf = crconf + rbconf \
                        + 4*(self.cr_rb_links.loc[(pid, rb_index)]['confidence'] - 0.5)
                except KeyError:
                    # pid and rb_index not identified as belonging to the same person
                    conf = crconf + rbconf - 2
            elif not (pid is None and rb_index is None):
                conf = crconf*(pid is None) + rbconf*(rb_index is None) - 1
            else:
                conf = None
            if conf is not None:
                # transform conf to range [0,1]
                conf = 2.0**conf / (2.0**conf + 1)
                # get rid of very uncertain matches
                if conf < 0.2:
                    pid, rb_index, conf, name = None, None, None, None
            pids.append(pid)
            rb_indices.append(rb_index)
            confs.append(conf)
            names.append(name)
            
        print(f'{sum(pd.isna(pids))} / {len(pids)} did not find pid matches')
        print(f'{sum(pd.isna(rb_indices))} / {len(rb_indices)} did not find rb_index matches')
        return pids, rb_indices, confs, names
    
    
    def compile_all(self, register_dir=REGISTER_DIR):
        register_df = aggregate_register_dfs(register_dir)
        register_df['PID'], register_df['rb_index'], register_df['confidence'], register_df['name'] \
            = self.find_matches_for_entries(register_df)
        register_df.dropna(subset=['confidence'], inplace=True)
        cols = ['PID', 'rb_index', 'confidence', 'name', 'class', 'birth_date', 'birth_place',
                'prepared_at', 'in_college', 'activities_and_honors', 'occupation', 'major']
        return register_df[cols].reset_index(drop=True)
    
    
    def quality_check(self, register_dir=REGISTER_DIR, use_output=True,
                      size=200):
        if use_output:
            df = pd.read_csv(OUTPUT)
        else:
            df = drop_duplicates(self.compile_all_clubs(register_dir))
        df = df.sample(size)
        df = df.reindex(df.columns.tolist() \
                        + ['rb_name', 'cr_name', 'rb_year', 'cr_year'], axis=1)
        df[['rb_name', 'cr_name', 'rb_year', 'cr_year']] \
            = df[['rb_name', 'cr_name', 'rb_year', 'cr_year']].astype(str)
        for i, r in df.iterrows():
            if pd.notna(r['PID']):
                df.at[i,'cr_name'] = self.cr_df.at[r['PID'], 'name']
                df.at[i,'cr_year'] = self.cr_df.at[r['PID'], 'year']
            if pd.notna(r['rb_index']):
                df.at[i,'rb_name'] = self.rb_df.at[r['rb_index'], 'name']
                df.at[i,'rb_year'] = self.rb_df.at[r['rb_index'], 'year']
        return df



def drop_duplicates(df):
    # allow matches to be filename or df
    if isinstance(df, str):
        df = pd.read_csv(df)
    # sort so most confident matches are kept when dropping duplicates
    df.sort_values('confidence', ascending=False, inplace=True)
    # Temporarily assign missing PIDs and rb_indices unique values to protect them from deletion
    missing_pids = df.index[pd.isna(df['PID'])]
    df.loc[missing_pids, 'PID'] = missing_pids
    missing_rb_indices = df.index[pd.isna(df['rb_index'])]
    df.loc[missing_rb_indices, 'rb_index'] = missing_rb_indices
    # Keep most confident of identical pid dupes
    df.drop_duplicates(['PID'], keep='first', inplace=True)
    # Do same thing with rb_index dupes
    df.drop_duplicates(['rb_index'], keep='first', inplace=True)
    # Get rid of temporary filler values from before
    missing_pids = missing_pids.intersection(df.index)
    missing_rb_indices = missing_rb_indices.intersection(df.index)
    df.loc[missing_pids, 'PID'] = None
    df.loc[missing_rb_indices, 'rb_index'] = None
    return df.sort_index()


def update_activities(df):
    activities = df.dropna(subset=['rb_index']).set_index('rb_index')['activities_and_honors'].apply(
        lambda x: re.split(r'(?:, ?|\n|; )', x) if isinstance(x, str) else [])
    codes = get_codes_for_activities(activities).reset_index().drop_duplicates().set_index('index')
    codes.to_csv(ACTIVITIES_OUT)


def update_final_clubs_and_frats(df):
    appears_as = pd.read_excel(FINAL_AND_FRATS_KEY, index_col=0,engine='openpyxl')['appears_as'].apply(
            lambda x: x.split(', ')
        )
    matches = []
    for i, r in df.iterrows():
        all_acts = r['activities_and_honors']
        activities = [x.upper().rstrip('.') for x in (re.split(r'(?:, ?|\n|; )', all_acts) if isinstance(all_acts, str) else [])]
        for a in activities:
            for code, variants in appears_as.iteritems():
                if any(v in a for v in variants):
                    matches.append(
                        {'code': code,
                         'PID': r['PID'],
                         'rb_index': r['rb_index'],
                         'student_name': r['name'],
                         'class': r['class'],
                         'source_year': 'NA',
                         'club_name': a,
                         'role': None,
                         'title': None,
                         'confidence': r['confidence']}
                    )
                    break
    codes = pd.DataFrame(matches)
    old_codes = pd.read_csv(FINAL_AND_FRATS)
    df_out = pd.concat((old_codes, codes)
                       ).sort_values(by='confidence'
                                     ).drop_duplicates(subset=['code', 'PID', 'rb_index'], keep='first'
                                                       ).sort_values(by=['class', 'student_name'])
    print(f'Number of new final club/frat entries is {len(df_out) - len(old_codes)}.')
    df_out.to_csv(FINAL_AND_FRATS, index=False)



if __name__ == '__main__':
    matcher = Matcher()
    df = matcher.compile_all()
    print(f'length before dedupeing is {len(df)}')
    df = drop_duplicates(df)
    print(f'length after dedupeing is {len(df)}')
    df.to_csv(OUTPUT, index=False)
    print("Classifying intended occupations from senior class registers now...")
    intended_occ = get_occupations(OUTPUT,id_var='rb_index')
    classes = get_classes_for_occupations(intended_occ,key_type='intended',method='regex',id_var='rb_index')
    try:
        classes.to_csv(INTENDED_OCCUPATION_CODES)
    except FileNotFoundError:
        print('Saving to local directory {}...'.format(os.getcwd()))
        classes.to_csv('intended_occupation_codes.csv')
    update_activities(df)
    update_final_clubs_and_frats(df)
    if QUALITY_CHECK:
        df = matcher.quality_check()
        df.to_csv(re.sub(r'\.csv', '_qcheck.csv', OUTPUT), index=False)