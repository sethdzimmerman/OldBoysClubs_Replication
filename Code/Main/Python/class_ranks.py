# -*- coding: utf-8 -*-
"""
Matches class rank data to people in class reports and red books.
"""


import sys
import os
import re
import pandas as pd

from jellyfish import damerau_levenshtein_distance

sys.path.append('red_book_class_report_linking')


CLASS_RANK_DIR = '../../../Raw Data/Class_ranks'
CLASS_REPORTS = '../../../Intermediate Data/Excel Files/updated_class_reports/all_years.csv'
REDBOOKS = '../../../Intermediate Data/Excel Files/redbooks_master.csv'
CR_RB_LINKS = '../../../Intermediate Data/codes/cr_rb_links/all_years.csv'
OUTPUT = '../../../Intermediate Data/codes/class_ranks.csv'

QUALITY_CHECK = True


def load_ranking_df(filename, root=CLASS_RANK_DIR):
    """Loads the class rank data from a CSV, formats the years, and drops invalid rows
    Returns a pandas DataFrame
    """
    ranking_df = pd.read_excel(os.path.join(root, filename),engine='openpyxl')
    if 'Class' not in ranking_df.columns:
        # add class column for spreadsheets with only freshman data
        startyear = int(re.search(r'Freshmen_(\d{4})', filename).group(1))
        class_of = startyear + 4
        ranking_df['Class'] = class_of
    else:
        # just change to 19XX format
        #endyear = int(re.search(r'(\d{4}).xlsx', filename).group(1))
        def change_format_helper(x):
            x = str(x)
            x = re.sub(r'[^A-Za-z\d]', '', x)
            try:
                if len(x) == 2:
                    return int('19' + x)
                else:
                    return int(x)
            except ValueError:
                # Entries with class years like ocC etc. are just ignored
                return None
        ranking_df['Class'] = ranking_df['Class'].apply(change_format_helper)
        # Keep only rows with valid Class entries
        ranking_df = ranking_df[pd.notna(ranking_df['Class'])]
    # remove invalid chars from Group entries
    ranking_df['Group'] = ranking_df['Group'].apply(lambda x: re.sub(r'[^IV]', '', str(x).upper()))
    return ranking_df.reset_index(drop=True)


def get_all_ranking_dfs(root=CLASS_RANK_DIR):
    """Gets a list of DataFrames for each spreadsheet in the root dir
    """
    filenames = [f for f in os.listdir(root) if f.endswith('.xlsx')]
    ranking_dfs = []
    for filename in filenames:
        endyear = int(re.search(r'(\d{4}).xlsx$', filename).group(1))
        ranking_dfs.append((endyear, load_ranking_df(filename, root)))
    return ranking_dfs


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
    """Extracts the middle name from a class report name entry
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


def get_first_middle_last_ranks(name):
    """Extracts name parts from class rank data

    Parameters
    ----------
    name : str

    Returns
    -------
    tuple of str (first, middle_initial, last)
    """
    split_last_first = name.split(', ')
    last = split_last_first[0]
    try:
        split_first_middle = split_last_first[1].strip().split()
    except IndexError:
        print(name, 'did not match expected format.')
        return '', '', ''
    first = split_first_middle[0].strip('.,')
    if len(split_first_middle) > 1:
        middle = split_first_middle[1].strip('.,')
        if middle.upper() == 'JR':
            middle = ''
    else:
        middle = ''
    return first, middle[0] if middle else middle, last


def get_first_char(string):
    """Helper function, just returns the first character of a string if the string is not NA"""
    return string[0] if string else ''



class Matcher:
    
    def __init__(self, class_report_file=CLASS_REPORTS, redbook_file=REDBOOKS,
                 cr_rb_links_file=CR_RB_LINKS):
        
        cr_df = pd.read_csv(class_report_file, index_col='PID',
                                 usecols=['PID', 'year', 'name'])
        # Regularize names
        cr_df['name'] = cr_df['name'].apply(
                lambda x: x.upper() if isinstance(x, str) else ''
            )
        # Separate first and last names, keep just initial also
        cr_df['first'] = cr_df['name'].apply(get_first_cr)
        cr_df['first_init'] = cr_df['first'].apply(get_first_char)
        cr_df['middle'] = cr_df['name'].apply(get_middle_cr)
        cr_df['middle_init'] = cr_df['middle'].apply(get_first_char)
        cr_df['last'] = cr_df['name'].apply(get_last_cr)
        cr_df['last_init'] = cr_df['last'].apply(get_first_char)
        # Group class report data by year
        self.cr_classes = {year: cr_df[cr_df['year'] == year] \
                               for year in cr_df['year'].unique()}
        
        rb_df = pd.read_csv(redbook_file, index_col='index',
                            usecols=['index', 'year', 'name'])
        # do same cleaning for redbook data
        rb_df['name'] = rb_df['name'].apply(lambda x: x.upper() if isinstance(x, str) else '')
        rb_df['first'], rb_df['middle'], rb_df['last'] = tuple(zip(
            *rb_df['name'].apply(get_first_middle_last_rb)
        ))
        rb_df['first_init'] = rb_df['first'].apply(get_first_char)
        rb_df['middle_init'] = rb_df['middle'].apply(get_first_char)
        rb_df['last_init'] = rb_df['last'].apply(get_first_char)
        self.rb_df = rb_df
        self.cr_df = cr_df
        self.rb_classes = {year: rb_df[rb_df['year'] == year] \
                               for year in rb_df['year'].unique()}
        
        # load correspondence between class reports and red books
        self.cr_rb_links = pd.read_csv(cr_rb_links_file, index_col=['PID', 'index'])
        
        # also save full rb_df and cr_df
        self.rb_df = rb_df
        self.cr_df = cr_df


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
    
    
    def find_matches_for_ranking_entries(self, ranking_df):
        pids = []
        rb_indices = []
        confs = []
        names = []
        for i, row in ranking_df.iterrows():
            crconf = 0  # keep track of confidence for class report match
            rbconf = 0  # and for red book match
            year = row['Class']
            # Extract first and last names using same method as with redbooks
            name = row['Name'].replace('.', '').upper()  # remove . and make upper first
            first, middle_init, last = get_first_middle_last_ranks(name)
            if not first or not last:
                # Can't deal with names without both parts
                pids.append(None)
                rb_indices.append(None)
                confs.append(None)
                names.append(None)
                continue
            first = first.split()[0]  # keep only first word of first name
            full_first = (len(first) > 1)  # full first name or just an intial?
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
            pids.append(pid)
            rb_indices.append(rb_index)
            confs.append(conf)
            names.append(name)
            
        print(f'{sum(pd.isna(pids))} / {len(pids)} did not find pid matches')
        print(f'{sum(pd.isna(rb_indices))} / {len(rb_indices)} did not find rb_index matches')
        return pids, rb_indices, confs, names
        
    
    def compile_all_ranks(self, class_rank_dir=CLASS_RANK_DIR):
        """Does matching on all class rank data
        """
        data = []
        num_firstyears = 0
        for endyear, ranking_df in get_all_ranking_dfs(class_rank_dir):
            ranking_df['PID'], ranking_df['rb_index'], \
                ranking_df['confidence'], ranking_df['name'] = self.find_matches_for_ranking_entries(ranking_df)
            # calculate and printfirst year red book match rate
            first_years = ranking_df[endyear - ranking_df['Class'] + 4 == 1].index
            first_years_w_matches = first_years.intersection(ranking_df.index[pd.notna(ranking_df['rb_index'])])
            num_fy = len(first_years)
            num_fywm = len(first_years_w_matches)
            print(f'for {endyear} P(in rb|in ranking) = {num_fywm} / {num_fy} = {num_fywm / num_fy}')
            # drop non-matches and append matches to data
            ranking_df = ranking_df[pd.notna(ranking_df['confidence'])]
            for i, row in ranking_df.iterrows():
                data.append({
                    'PID': row['PID'],
                    'rb_index': row['rb_index'],
                    'year': endyear - row['Class'] + 4,
                    'group': row['Group'],
                    'source_year': endyear,
                    'confidence': row['confidence'],
                    'name': row['name']
                    })
        return pd.DataFrame(data)
    
    
    def quality_check(self, class_rank_dir=CLASS_RANK_DIR, use_output=True,
                      size=200):
        """Create an annotated subsample of the data to use for quality checking.
        """
        if use_output:
            df = pd.read_csv(OUTPUT)
        else:
            df = drop_duplicates(self.compile_all_ranks(class_rank_dir))
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
    df.drop_duplicates(['PID', 'year', 'source_year'], keep='first', inplace=True)
    # If still pid-year dups, drop them
    df.drop_duplicates(['PID', 'year'], keep=False, inplace=True)
    # Do same thing with rb_index dupes
    df.drop_duplicates(['rb_index', 'year', 'source_year'], keep='first', inplace=True)
    df.drop_duplicates(['rb_index', 'year'], keep=False, inplace=True)
    # Get rid of temporary filler values from before
    missing_pids = missing_pids.intersection(df.index)
    missing_rb_indices = missing_rb_indices.intersection(df.index)
    df.loc[missing_pids, 'PID'] = None
    df.loc[missing_rb_indices, 'rb_index'] = None
    return df.sort_index()




if __name__ == '__main__':
    matcher = Matcher()
    df = matcher.compile_all_ranks()
    print(f'length before dedupeing is {len(df)}')
    df = drop_duplicates(df)
    print(f'length after dedupeing is {len(df)}')
    # print backward red book match rate
    num_rb = len(matcher.rb_df)
    num_rbwm = (pd.notna(df['rb_index']) & (df['year'] == 1)).sum()
    print(f'P(in ranking|in rb) = {num_rbwm} / {num_rb} = {num_rbwm / num_rb}')
    df.to_csv(OUTPUT, index=False)
    if QUALITY_CHECK:
        df = matcher.quality_check()
        df.to_csv(re.sub(r'\.csv', '_qcheck.csv', OUTPUT), index=False)
        