# -*- coding: utf-8 -*-
"""
Steps:
    Aggregate clubs files
    For each entry in aggregated files:
        Search in corresponding CR year to find PID
        Search in corresponding RB year to find rb_index
        Look up activity code from final_clubs_and_frats_key.xlsx
"""

import os
import re
import pandas as pd

from jellyfish import damerau_levenshtein_distance


REGISTERED_CLUBS = '../../../../Raw Data/Clubs/all_clubs/'
CLASS_REPORTS = '../../../../Intermediate Data/Excel Files/updated_class_reports/all_years.csv'
RED_BOOKS = '../../../../Intermediate Data/Excel Files/redbooks_master.csv'
CR_RB_LINKS = '../../../../Intermediate Data/codes/cr_rb_links/all_years.csv'
CODE_KEY = '../../../../Code/Keys/final_clubs_and_frats_key.xlsx'
OUTPUT = '../../../../Intermediate Data/codes/final_clubs_and_frats.csv'

QUALITY_CHECK = True


def process_year(yr):
    """Takes a year entry and converts it to the format 19XX
    If no valid year is found, returns None
    """
    if not isinstance(yr, str):
        return None
    yr_search = re.search(r'\d\d$', yr)
    if yr_search:
        return int('19' + yr_search.group())
    else:
        return None
    

def load_club_df(filename, root=REGISTERED_CLUBS):
    """Loads the clubs data from a CSV, formats the years, and drops invalid rows
    Returns a pandas DataFrame
    """
    try:
        club_df = pd.read_csv(os.path.join(root, filename))
    except UnicodeDecodeError:
        club_df = pd.read_csv(os.path.join(root, filename), encoding='cp1252')
    club_df['source_year'] = re.search(r'\d{4}_\d{4}(?=\.csv$)', filename).group()
    club_df['class'] = club_df['class'].apply(process_year)
    club_df.dropna(subset=['class'], inplace=True)
    return club_df


def aggregate_club_dfs(root=REGISTERED_CLUBS):
    """Loads all data in the root directory and concatenates them into a single DataFrame
    """
    filenames = (f for f in os.listdir(root) if f.endswith('.csv'))
    return pd.concat((load_club_df(f, root) for f in filenames))


def get_first_cr(name):
    """Extracts the first name from a class report name entry
    """
    try:
        return name.split()[0]
    except IndexError:
        return ''
    

def get_middle_cr(name):
    """Extracts the middle name from a class report name entry
    """
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
    """Extracts the last name from a class report name entry
    """
    search = re.search(r'[A-Za-z\'\-]+(?=$|,.{0,4}$)', name)
    if search:
        return search.group()
    else:
        try:
            return name.split()[-1]
        except IndexError:
            return ''
        

def get_first_middle_last_rb(name):
    """Extracts the first, middle, and last names from a red book name entry
    Returns tuple of (first, middle, last)
    """
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


def get_first_middle_last_clubs(name):
    """Extracts the first, middle, and last names from a final clubs/frats entry
    Returns tuple of (first, middle, last)
    """
    name = re.sub(r', (?:JR\.?|\d\S{0,3}|[A-Z]{1,3})$', '', name.strip(), flags=re.IGNORECASE)
    split = name.split()
    if len(split) > 2:
        return split[0], split[1][0], split[-1]
    elif len(split) == 2:
        return split[0], '', split[1]
    else:
        return '', '', ''
    
    

class Matcher:
    
    def __init__(self, class_report_file=CLASS_REPORTS, redbook_file=RED_BOOKS,
                 cr_rb_links_file=CR_RB_LINKS):
        
        cr_df = pd.read_csv(class_report_file, index_col='PID',
                                 usecols=['PID', 'year', 'name'])
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
        # Group class report data by year
        self.cr_classes = {year: cr_df[cr_df['year'] == year] \
                               for year in cr_df['year'].unique()}
        
        rb_df = pd.read_csv(redbook_file, index_col='index',
                            usecols=['index', 'year', 'name'])
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
    
    
    def find_matches_for_club_entries(self, club_df):
        print('Finding matches for club entries...')
        pids = []
        rb_indices = []
        confs = []
        names = []
        for i, row in club_df.iterrows():
            crconf = 0  # keep track of confidence for class report match
            rbconf = 0  # and for red book match
            year = row['class']
            # Extract first and last names using same method as with redbooks
            name = row['student_name'].replace('.', '').upper()  # remove . and make upper first
            first, middle_init, last = get_first_middle_last_clubs(name)
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
            if len(matches) != 1:
                # it's either ambiguous, or there are no matches
                pid = None
            else:
                if 'edits' in matches.columns:
                    crconf -= 0.5*matches['edits'][0]  # reduce conf by 0.5*number of edits needed
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
            if len(matches) != 1:
                rb_index = None
            else:
                if 'edits' in matches.columns:
                    rbconf -= 0.5*matches['edits'][0]
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
    
    
    def compile_all_clubs(self, registered_clubs=REGISTERED_CLUBS):
        """Does matching on all registered club data
        """
        club_df = aggregate_club_dfs(registered_clubs)
        club_df['PID'], club_df['rb_index'], club_df['confidence'], club_df['name'] \
            = self.find_matches_for_club_entries(club_df)
        club_df.dropna(subset=['confidence'], inplace=True)
        club_df['club_name'] = club_df['club_name'].apply(str.upper)
        cols = ['PID', 'rb_index', 'student_name', 'class', 'source_year', 'club_name', 'role', 'title', 'confidence']
        return club_df[cols].reset_index(drop=True)
    
    
    def quality_check(self, registered_clubs=REGISTERED_CLUBS, use_output=True,
                      size=200):
        """Create an annotated subsample of the data to use for quality checking.
        """
        if use_output:
            df = pd.read_csv(OUTPUT)
        else:
            df = drop_duplicates(self.compile_all_clubs(registered_clubs))
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
    """Don't allow the same PID or red book index to be matched to more than one unique person
    """
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
    df.drop_duplicates(['PID', 'source_year', 'club_name'], keep='first', inplace=True)
    # Do same thing with rb_index dupes
    df.drop_duplicates(['rb_index', 'source_year', 'club_name'], keep='first', inplace=True)
    # Get rid of temporary filler values from before
    missing_pids = missing_pids.intersection(df.index)
    missing_rb_indices = missing_rb_indices.intersection(df.index)
    df.loc[missing_pids, 'PID'] = None
    df.loc[missing_rb_indices, 'rb_index'] = None
    return df.sort_index()


def add_activity_codes(df, code_key=CODE_KEY):
    """Add activity codes to activities found from the final clubs & frats.
    """
    key_df = pd.read_excel(CODE_KEY, index_col=0,engine='openpyxl')
    appears_as = key_df['appears_as'].apply(
            lambda x: x.split(', ')
        )
    codes = []
    for idxs, club in df['club_name'].iteritems():
        found_match = False
        for code, variants in appears_as.iteritems():
            if any(v in club for v in variants):
                codes.append(code)
                found_match = True
                break
        if found_match == False:
            codes.append(None)
    df['code'] = codes
    df.dropna(subset=['code'], inplace=True)
    df.set_index('code', inplace=True)
    return df


if __name__ == '__main__':
    matcher = Matcher()
    df = matcher.compile_all_clubs()
    print(f'length before dedupeing is {len(df)}')
    df = drop_duplicates(df)
    print(f'length after dedupeing is {len(df)}')
    df = add_activity_codes(df)
    print(f'num entries with final club/frat matches is {len(df)}')
    df.to_csv(OUTPUT, index=True)
    if QUALITY_CHECK:
        df = matcher.quality_check()
        df.to_csv(re.sub(r'\.csv', '_qcheck.csv', OUTPUT), index=False)
        