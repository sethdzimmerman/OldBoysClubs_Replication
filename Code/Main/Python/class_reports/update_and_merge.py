"""
Tools for updating hand-checked class report data with latest version of parse_text.py
"""

import pandas as pd
import re
import os
from jellyfish import levenshtein_distance

from parse_text import parse_doc

pd.options.mode.chained_assignment = None


def bowdlerize_name(name):
    """Removes all non-alphabet characters from a name, and converts to uppercase.
    The point is to make it easier to determine if two names are the same.
    """
    if not isinstance(name, str):
        return name
    name = re.sub('[^A-Za-z]', '', name.upper())
    return name


def get_last(name):
    if not isinstance(name, str):
        return name
    name = name.upper()
    search = re.search(r"[A-Z\'\-]+(?=$|,.{0,4}$)", name)
    if search:
        return search.group()
    try:
        return name.split()[(-1)]
    except IndexError:
        return name


def string_compare(x, y):
    return 1 - levenshtein_distance(x.upper(), y.upper()) / max(len(x), len(y))


def combine_columns(df):
    """After merging two DataFrames, columns with the same names are affixed with _x and _y.
    This function merges those columns, preferentially keeping the _x ones.
    """
    df_out = pd.DataFrame()
    for column in df.columns:
        column_y = column[:-1] + 'y'
        if column == column_y:
            pass
        elif column_y in df.columns:
            newcol = column.rstrip('_x')
            df_out[newcol] = [ x if (pd.notna(x)) & (x!="") else y for x, y in zip(df[column], df[column_y]) ]
        else:
            df_out[column] = df[column]

    return df_out


def sort_by_last_name(df):
    df['last'] = df['name'].apply(get_last)
    df.sort_values(by='last', inplace=True)
    return df.drop('last', axis=1)


def handle_pathological_cases(df, threshold=0.8, warn=True):
    """Iterates through rows with no PID entry and tries to find matches for them elsewhere in the DataFrame.
    Returns a DataFrame with no NaN values in the PID column.
    """
    matched = df[pd.notna(df['PID'])]
    unmatched = df[pd.isna(df['PID'])].drop_duplicates()
    matches = []
    for i, r in unmatched.iterrows():
        if r['name'] == 'NO OCR FOR THIS PAGE':
            continue
        name_matches = [ (j, string_compare(df.loc[j]['name'], r['name'])) for j in matched.index if isinstance(df.loc[j]['name'], str) and isinstance(r['name'], str) ]
        if not name_matches:
            continue
        best_match = max(name_matches, key=lambda x: x[1])
        if best_match[1] > threshold:
            matches.append((i, best_match[0]))
        elif warn:
            print('No PID found for "{}"'.format(r['name']))

    for match in matches:
        x = matched.loc[match[1]]
        y = unmatched.loc[match[0]]
        matched.loc[match[1]] = x.combine_first(y)

    return matched


#### FUNCTIONS FOR ADDING MANUAL FIXES ####

def get_parents(parents):
    if not isinstance(parents, str):
        return None, None
    parents_search = re.search(r'^(.*?),(?: .\d+,)? (.*?)\.?$', parents.strip())
    if parents_search:
        return parents_search.group(1), parents_search.group(2)  # father, mother
    else:
        return None, None


def get_birth_info(birth, keep_date=False):
    if not isinstance(birth, str):
        return None, None
    birth_search = re.search(r'^(.*?\d{4}), (.*)$', birth.strip())
    if birth_search:
        if keep_date:
            return birth_search.group(1), birth_search.group(2)  # date, place
        else:
            return None, birth_search.group(2)
    else:
        return None, None


def update_columns(df, fixes):
    if not fixes.index.difference(df.index).empty:
        print('Warning:', fixes.index.difference(df.index), 'not in class report')
        fixes = fixes.loc[fixes.index.intersection(df.index)]
    df_f = df.loc[fixes.index]
    fixes_f = pd.DataFrame(columns=df.columns, index=fixes.index)
    fixes_f['birthDate'], fixes_f['birthPlace'] = tuple(zip(*fixes['born'].apply(get_birth_info)))
    fixes_f['degree'] = fixes['degrees']
    fixes_f['fatherName'], fixes_f['motherName'] = tuple(zip(*fixes['parents'].apply(get_parents)))
    fixes_f['harvardBrothers'] = fixes['harvard_brother']
    # fixes_f['high_school_name'] == fixes['prepared_at'] # Skip this for now since we need split name and location
    fixes_f['homeAddress'] = fixes['home_address']
    fixes_f['member_of'] = fixes['member_of']
    fixes_f['name'] = fixes['name']
    fixes_f['occupation'] = fixes['occupation']
    fixes_f['officesHeld'] = fixes['offices_held']
    # publications data not in fixes
    fixes_f['spouseName'] = fixes['married'].apply(lambda x: str(x).split(',')[0])
    fixes_f['work_address'] = fixes['office_address']
    fixes_f['yrs_in_college'] = fixes['years_in_college'].apply(lambda x: x.strip('.') if isinstance(x, str) else x)
    df.loc[fixes.index] = fixes_f.combine_first(df_f)
    return df  # I believe this modifies df in place, but return df anyway



def get_first_last(fullnames):
    firstnames = []
    lastnames = []

    for name in fullnames:
        if isinstance(name,str):
            allnames = name.split(" ")
            last = allnames[-1]
            first = " ".join(allnames[:-1])
        else:
            last = ''
            first = ''
        firstnames.append(first)
        lastnames.append(last)
    
    return firstnames, lastnames

        
    
#### #### #### #### #### #### #### ####


def update_and_merge(load_from, merge_with, fixes_dir, save_as=None):
    """Parses a text document (load_from), merges the resulting data with a preexisting data set (merge_with)
    :param load_from: the file name (str) of the text document to parse
    :param merge_with: the file name (str) of the CSV to merge with
    :param save_as: the file name to save the merged data set at
    :return: a Pandas DataFrame that is the merged data set
    """
    print(f'Updating {load_from} with {merge_with}...')
    new = parse_doc(load_from)
    old = pd.read_csv(merge_with)
    old['PID'] = old['PID'].combine_first(old['pid'])
    new['name_upper'] = new['name'].apply(bowdlerize_name)
    old['name_upper'] = old['name'].apply(bowdlerize_name)
    new = new.merge(old, how='outer', on='name_upper').drop('name_upper', axis=1)
    new = combine_columns(new)
    new = sort_by_last_name(new)
    print('Handling pathological cases...')
    new = handle_pathological_cases(new)
    if 'year' not in new.columns:
        yr_txt = re.search(r'\d{4}', load_from[-30:]).group()
        yr_csv = re.search(r'\d{4}', load_from[-30:]).group()
        assert yr_txt == yr_csv
        new['year'] = [yr_csv] * len(new)
    # Drop duplicated PIDs; keep the entry with more non-NaN entries
    newcol_ptrn = re.compile(r'(spouse(Name_old|Name_ocr|First|Last).*|wedding.*|child(Name|Birth).*|children_cat|any_children)')
    oldcols = [col for col in new.columns if not bool(newcol_ptrn.search(col))]
    new['notnans'] = new[oldcols].count(axis=1)
    new = new.sort_values('notnans', ascending=False).drop_duplicates('PID').drop(columns='notnans')
    # If entry is the same but more than one PID provided, take the one that has nonempty "pid" (lowercase) column
    new = new.sort_values('pid', na_position='last').drop_duplicates(list(new.columns)[:16])
    new.sort_values(['year', 'name'], inplace=True)
    new.set_index('PID', drop=True, inplace=True)
    try:
        fixes = pd.read_csv(os.path.join(fixes_dir, f'data_for_fix_{yr_csv}.csv'), index_col='pid').rename(columns=str.lower)
        fixes.dropna(how='all', inplace=True)
        new = update_columns(new, fixes)
    except FileNotFoundError:
        print(f'No fixes found for {merge_with}')
    except UnicodeDecodeError:  # The CSVs are sometimes encoded w/ANSI for some reason
        fixes = pd.read_csv(os.path.join(fixes_dir, f'data_for_fix_{yr_csv}.csv'), index_col='pid', encoding='cp1252')
        fixes.dropna(how='all', inplace=True)
        new = update_columns(new, fixes)
    if save_as:
        new.to_csv(save_as)
    return new


def get_class_reports_wout_pids(pided_dir, unpided_dir):
    pided_files = os.listdir(pided_dir)
    unpided_files = os.listdir(unpided_dir)
    to_link = [f for f in unpided_files if f not in pided_files]
    dfs = []
    for f in to_link:
        df = pd.read_csv(os.path.join(unpided_dir, f),index_col=0)
        df['year'] = [int(os.path.splitext(f)[0])]*len(df)
        dfs.append(df)
    df = pd.concat(dfs, sort=True).reset_index(drop=True)
    # Assign PID if there is a good one suggested by familysearch find, else assign an arbitrary index
    df['PID'] = [r['pid'] if (pd.notna(r['pid']) and r['confidence'] > 0.8) else f'no_pid_{i}' \
                   for i, r in df.iterrows()]
    df = df[~df['PID'].duplicated()]
    return df


def concat_all_years(in_dir, in_dir_unpided,include_no_pids=True):
    files = (x for x in os.listdir(in_dir) if re.search(r'\d{4}', x) and x.endswith('.csv'))
    df = pd.concat((pd.read_csv(os.path.join(in_dir, f)) for f in files), sort=False)
    if include_no_pids:
        df = pd.concat((df, get_class_reports_wout_pids(in_dir,in_dir_unpided)), sort=False)
    df['spouseFirst'], df['spouseLast'] = get_first_last(df['spouseName'])
    return df[[c for c in df.columns if c[:4] != 'http']]


if __name__ == '__main__':
    year = input('What year? ')
    source_txt = ('../../../../Raw Data/Class_Reports/OCRed/{}_optimized.txt').format(year)
    cr_csv = ('../../../../Raw Data/Class_Reports/hand_coded/Harvard Cohorts - {}.csv').format(year)
    out = ('../../../../Intermediate Data/Excel Files/updated_class_reports/{}.csv').format(year)
    update_and_merge(source_txt, cr_csv, out)