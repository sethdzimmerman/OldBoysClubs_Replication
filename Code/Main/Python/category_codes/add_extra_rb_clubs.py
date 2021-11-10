# -*- coding: utf-8 -*-


import os
import pandas as pd
import re

from jellyfish import jaro_winkler

from activities import get_codes_for_activities
from activity_leadership import check_all


REDBOOKS_MASTER = '../../../../Intermediate Data/Excel Files/redbooks_master.csv'
CODES_FILE = '../../../../Intermediate Data/codes/activity_codes.csv'
LEADERSHIP_FILE = '../../../../Intermediate Data/codes/activity_leadership.csv'
HONOR_LISTS = '../../../../Intermediate Data/codes/honor_lists.csv'
ROSTER_DIR = '../../../../Raw Data/Clubs/from_Red_Books'


# Load the redbook master and the clubs file

# Ret rb indices for each entry in the clubs file

# Assign club codes to each entry in the clubs file

# Add to the clubs index (concat, drop duplicates[, and sort?])


def longest_starting_substring(s1, s2):
    i = 0
    for (x, y) in zip(s1, s2):
        if x == y:
            i += 1
        else:
            return i
    return i


def get_first_last_rb(name):
    """Given a name in the format they appear in the red books master, return first and last.
    Note, this is the same function used in the cr-rb linking code.
    """
    name = re.sub(r',?\s?\(?e\. ?s\.\)?', '', name, flags=re.IGNORECASE).rstrip(',')
    name = re.sub(r', (?:JR\.?|\d\S{0,3}|[A-Z]{1,3})$', '', name.strip(), flags=re.IGNORECASE)  # Remove suffixes
    # Look for name of form LAST, FIRST(, JR.)
    search = re.search(r'^([^,]+), ?(\S.*?)$', name)
    if search is not None:
        return search.group(2).strip(), search.group(1).strip()
    # Look for name of form FIRST LAST(, JR.)
    search = re.search(r'^(.*?)\s([^\s,]+)$', name)
    if search is not None:
        return search.group(1).strip(), search.group(2)
    # Give up
    return '', ''


def get_first_last_clubs(name):
    # Try the RB function first
    first, last = get_first_last_rb(name)
    # If that doesn't work, try another approach
    if (first, last) == ('', ''):
        name = re.sub(r',.{2,5}$', '', name)
        name = re.sub(r'\. ?', '. ', name)
        chunks = name.split()
        first = ' '.join(chunks[:-1])
        last = chunks[-1]
    return first, last


def get_initials(first):
    return ''.join(x[0] for x in first.split()).upper()


def get_rb_indices(df):
    if df.empty:
        return dict()
    # Load redbook master
    rb = pd.read_csv(REDBOOKS_MASTER, index_col='index')
    # Add first and last name columns
    rb['first'], rb['last'] = tuple(zip(*rb['name'].apply(get_first_last_rb)))
    rb['first'] = rb['first'].apply(get_initials)
    rb['last'] = rb['last'].apply(str.upper)
    # Add first and last name to df
    df['first'], df['last'] = tuple(zip(*df['Name'].apply(get_first_last_clubs)))
    df['first'] = df['first'].apply(get_initials)
    df['last'] = df['last'].apply(str.upper)
    # Match first on year, then on last name, then on first name
    matches = []
    for i, r in df.iterrows():
        rb_index = rb.index[rb['year'] == r['Year']]  # Restrict to same year
        rb_sm = rb.loc[rb_index]
        lname_matches = rb_index[rb_sm['last'] == r['last']]
        if not lname_matches.empty:  # If there are exact lname matches, take the one with the best fname match
            best = max(lname_matches, key=lambda x: longest_starting_substring(r['first'], rb_sm.loc[x]['first']))
            matches.append((i, best))
        else:  # Look for inexact last name matches
            try:
                best = max(rb_index[rb_sm['first'] == r['first']], key=lambda x: jaro_winkler(r['last'], rb_sm.loc[x]['last']))
            except ValueError:
                pass
            else:
                if jaro_winkler(r['last'], rb_sm.loc[best]['last']) > 0.85:
                    matches.append((i, best))
    return dict(matches)


def check_df_format(df):
    # Fix irregular column names
    df.rename(columns=str.strip, inplace=True)
    # Fix irregularities in the Year column
    year = 0
    for i, r in df.iterrows():
        if pd.isna(r['Year']):
            if 'men entitled' in r['Image'].lower():
                df.loc[i, 'Year'] = r['Image']
            else:
                df.loc[i, 'Year'] = year
        elif not isinstance(r['Year'], str):
            year = r['Year']
    return df


def check_honor_list(activities_entry):
    for a in activities_entry:
        if 'honor list' in a.lower():
            return 1
    return 0

def check_deans_list(activities_entry):
    for a in activities_entry:
        if re.search(r'dean.?s list', a.lower()):
            return 1
    return 0
    

def add_honor_lists(activities, men_entitled_indices, honor_lists=HONOR_LISTS):
    honor_list = activities.apply(check_honor_list)
    hl_indices = honor_list[honor_list == 1].index.drop_duplicates()
    deans_list = activities.apply(check_deans_list)
    dl_indices = deans_list[deans_list == 1].index.drop_duplicates()
    men_entitled_indices = men_entitled_indices.drop_duplicates()
    all_indices = hl_indices.union(dl_indices).union(men_entitled_indices)
    df = pd.DataFrame(index=all_indices)
    df['honor_list'] = pd.Series(df.index.map(lambda x: x in hl_indices), dtype='int', index=df.index)
    df['deans_list'] = pd.Series(df.index.map(lambda x: x in dl_indices), dtype='int', index=df.index)
    df['men_entitled'] = pd.Series(df.index.map(lambda x: x in men_entitled_indices), dtype='int', index=df.index)
    # Merge with data from other years and save to CSV
    if os.path.isfile(honor_lists):
        preexisting = pd.read_csv(honor_lists, index_col=0)
        df = pd.concat((preexisting, df), axis=0)
        df = df.loc[~df.index.duplicated(keep='last')]
    df.to_csv(honor_lists)
    return df


def add_leadership(activities, leadership_file=LEADERSHIP_FILE):
    activities = activities.apply(lambda x: x[0])
    correspondencia = check_all(activities)
    new_df = pd.DataFrame(correspondencia, columns=['index', 'code'])
    old_df = pd.read_csv(leadership_file)
    new_df = pd.concat((old_df, new_df))
    new_df = new_df.drop_duplicates().sort_values('index')
    new_df.to_csv(leadership_file, index=False)
    


def add_new_clubs(clubs_file, codes_file=CODES_FILE,
                  honor_lists=HONOR_LISTS, leadership_file=LEADERSHIP_FILE):
    if os.path.splitext(clubs_file)[1] == '.xlsx':
        clubs = pd.read_excel(clubs_file,engine='openpyxl')
    else:
        clubs = pd.read_csv(clubs_file)
    # Fix formatting irregularities
    clubs = check_df_format(clubs)
    # Figure out where the "men entitled" section starts
    try:
        split_at = clubs[clubs['Year'].apply(lambda x: isinstance(x, str) and 'men entitled' in x.lower())].index[0]
    except (KeyError, IndexError):
        split_at = len(clubs)
    men_entitled = clubs.iloc[split_at+1:].reset_index(drop=True)
    clubs = clubs.iloc[:split_at].dropna(subset=['Name']).reset_index(drop=True)
    # Match to redbook master data
    index_matches = get_rb_indices(clubs)
    if not index_matches:
        return  # activity id-ing will fail if you try with an empty df
    men_entitled_indices = pd.Index(get_rb_indices(men_entitled).values())
    # Get activities for each entry
    activities = pd.Series(([clubs.loc[i]['Club']] for i in index_matches.keys()), index=index_matches.values())
    # Create csv for honor list, dean's list, and "men entitled"
    add_honor_lists(activities, men_entitled_indices, honor_lists)
    # Get activity codes
    codes = get_codes_for_activities(activities[:split_at])
    # Combine with already-existing data and save
    old_codes = pd.read_csv(codes_file, index_col=0)
    codes = pd.concat((old_codes, codes)).reset_index()  # Reset index so it's counted in the de-duplication step
    codes = codes.drop_duplicates().sort_values('index')
    codes.to_csv(codes_file, index=False)
    # Add leadership data and save
    add_leadership(activities[:split_at], leadership_file)



if __name__ == '__main__':
    clubs_files = [os.path.join(ROSTER_DIR, f) for f in os.listdir(ROSTER_DIR) if os.path.splitext(f)[1] == '.xlsx']
    for clubs_file in clubs_files:
        try:
            print(f'Updating activities from {clubs_file}...')
            add_new_clubs(clubs_file)
        except FileNotFoundError:
            print(f'File {clubs_file} was not found. Most likely this was a temporary file.')