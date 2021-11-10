"""
Code to take transcribed red book data and add to master data set
"""

# index,year,photo,page,name,age,college_address,home_address,next_address,high_school,activities,engineering,remarks

import re
import pandas as pd
import os
import sys
sys.path.append(os.getcwd())
from gender import get_gender, split_name

from datetime import datetime


REDBOOKS_MASTER = '../../../Intermediate Data/Excel Files/redbooks_master.csv'
REDBOOKS_DIR = '../../../Raw Data/Red_Books/hand_coded'
OCR_VERSION = '../../../Raw Data/Red_Books/OCRed/red_books_allyears.csv'


def change_column_name(col_name):
    """
    Takes a column name (str) from an input spreadsheet and changes it to a standardized format

    Parameters
    ----------
    col_name : str
        column header from input spreadsheet

    Returns
    -------
    str
        formatted version of column name

    """
    if re.search(r'(?:College Address \d{4}-\d{2}|next year)',
                 col_name, flags=re.IGNORECASE):
        return 'next_address'
    elif col_name.lower() in ('room', 'school address', 'college_adress'):
        return 'college_address'
    elif col_name.lower().startswith('club'):
        return 'activities'
    elif col_name.lower().startswith('page'):
        return 'page'
    elif re.search(r'(major|concentration)',col_name.lower()):
        return 'intended_major'
    else:
        return col_name.strip().lower().replace(' ', '_')


def combine_name_columns(df):
    """
    Takes data frame with first_name and last_name columns and combines them into a single name column

    Parameters
    ----------
    df : pandas.DataFrame
        data frame containing red book data

    Returns
    -------
    pandas.DataFrame
        data frame with first and last name columns combined

    """
    df['name'] = df['last_name'] + ', ' + df['first_name']
    return df[[c for c in df.columns if c != 'last_name' and c != 'first_name']]


def build_hash(row):
    """
    Generates a 'hash' to be used to construct the unique index for a given row

    Parameters
    ----------
    row : pandas.Series (row from a data frame)
        a row containing the red book data for a single person

    Returns
    -------
    str
        the index hash for that row

    """
    year = str(row['year'])
    try:
        photo = re.search(r'\d+', row['photo']).group()
    except KeyError:
        photo = 'no_photo'
    try:
        page = str(row['page'])
    except KeyError:
        page = 'no_page'
    try:
        first = re.search(r', ?(\S+)', row['name']).group(1).lower()
        last_initial = row['name'][0].lower()
    except AttributeError:
        # Name not in Last, First Middle format
        parts = row['name'].split()
        first = parts[0].lower()
        last_initial = parts[-1].lower()
    except TypeError:
            first = 'no'
            last_initial = 'name'

    out = '_'.join((year, photo, page, first, last_initial))
    # Remove non-alphanumeric characters before returning
    return re.sub(r'[^a-z_\d]', '', out)
    

def create_index(df):
    """
    generates list of unique indices for each row in a data frame of red book data
    runs build_hash() on every row in the df, then fixes duplicates so each index hash is unique

    Parameters
    ----------
    df : pandas.DataFrame
        data frame of red book data

    Returns
    -------
    index : list
        list of unique indices for each row

    """
    index = []
    for _, row in df.iterrows():
        h = build_hash(row)
        # Deal with duplicate indices
        while h in index:
            if h[-1].isdigit():
                h = h[:-1] + str(int(h[-1]) + 1)
            else:
                h += '2'
        index.append(h)
    return index


def new_master(master_filename):
    """Creates a new empty file with given master_filename
    """
    print("\nStart cleaning redbooks now...")
    with open(master_filename, 'w') as fh:
        fh.write('index\n')


def add_to_master(filename, master_filename):
    """Adds the contents of the spreadsheet at 'filename' to the master spreadsheet at 'master_filename'
    """
    df = pd.read_excel(filename,engine='openpyxl').dropna(how='all')
    # Rename columns to match standard format
    df.rename(columns={col: change_column_name(col) for col in df.columns},
              inplace=True)
    # check for pre-1923 format
    if 'name' not in df.columns:
        df = combine_name_columns(df)
    # Assign gender
    df = get_gender(df)
    # Split names
    df['first'],df['middle'],df['last'] = \
        zip(*df['name'].map(split_name))
    # Create unique indices
    df['index'] = create_index(df)
    df.set_index('index', inplace=True)
    if not os.path.isfile(master_filename):
        new_master(master_filename)
    master = pd.read_csv(master_filename, index_col=0, low_memory=False)
    master = pd.concat((master, df), sort=False)
    master.to_csv(master_filename)


def add_directory_to_master(directory, master_filename):
    """Runs add_to_master() on all .xlsx files in a given directory
    """
    files = [os.path.join(directory, f) for f in os.listdir(directory) \
             if os.path.splitext(f)[1].lower() == '.xlsx']
    for f in files:
        print('Adding {} to master...'.format(f))
        add_to_master(f, master_filename)


def bowdlerize_name(name):
    """Removes all non-alphabet characters from a name, and converts to uppercase.
    The point is to make it easier to determine if two names are the same.
    """
    if not isinstance(name, str):
        return name
    name = re.sub(r'[^A-Za-z]', '', name.upper())
    return name


def merge_w_ocr_version(master_filename, ocr_filename, save=True):
    """
    Takes the spreadsheets at master_filename and ocr_filename and merges them
    Information in the master version will be preferred to the ocr version if available

    Parameters
    ----------
    master_filename : str
        path to the master spreadsheet
    ocr_filename : str
        path to the ocr spreadsheet
    save : bool, optional
        If True, will save merged version to master_filename. The default is True.

    Returns
    -------
    master : pandas.DataFrame
        the merged version of the two spreadsheets.

    """
    master = pd.read_csv(master_filename, index_col=0)
    ocr = pd.read_csv(ocr_filename, index_col=0)
    master['picture'] = master['photo'].apply(lambda x: int(x[-4:]) if isinstance(x, str) else x)
    ocr.rename({'Full Name': 'name', 'Prepared at': 'high_school'}, axis=1, inplace=True)
    ocr.rename(lambda x: x.lower().replace(' ', '_') if isinstance(x, str) else x, axis=1, inplace=True)
    master['name_lower'] = master['name'].apply(bowdlerize_name)
    ocr['name_lower'] = ocr['name'].apply(bowdlerize_name)
    merged = master.merge(ocr, 'left', on=['year', 'picture', 'name_lower'])
    master['high_school'] = list(merged['high_school_x'].combine_first(merged['high_school_y']))  # Just high schools for now
    master.drop(['picture', 'name_lower'], axis=1, inplace=True)
    # Drop duplicates by name and year
    master.sort_values(by=['year','name','photo','page'], inplace=True)
    master.drop_duplicates(subset=['name','year'],keep='first',inplace=True)
    if save:
        master.to_csv(master_filename)
    return master



def clean_rb_file(filename,data_dict):
    """
    Loads the raw redbooks file, cleans it and assigns gender and room information.
    Stores to the data_dict that is passed as an argument to allow for parallel execution
    for multiple files instead of writing directly to the output file.
    """
    year = re.search(r'(\d{4})',str(filename)).group(1)
    print(f"\nNow cleaning redbooks file for year {year}...")

    df = pd.read_excel(filename,engine='openpyxl').dropna(how='all')
    # Rename columns to match standard format
    df.rename(columns={col: change_column_name(col) for col in df.columns},
              inplace=True)
    df.columns = map(str.lower, df.columns)
    # check for pre-1923 format
    if 'name' not in df.columns:
        df = combine_name_columns(df)
    # Split name    
    df['first'],df['middle'],df['last'] = \
            zip(*df['name'].map(split_name))
    # Assign gender
    df = get_gender(df)
    # Create unique indices
    df['index'] = create_index(df)
    df.set_index('index', inplace=True,drop=True)

    data_dict[filename] = df

    return data_dict


if __name__ == '__main__':
    if os.path.isfile(REDBOOKS_MASTER):
        try:
            # Rename the old redbook master file
            os.rename(REDBOOKS_MASTER, os.path.splitext(REDBOOKS_MASTER)[0] + datetime.now().strftime('_old_%Y-%m-%d.csv'))
        except FileExistsError:
            pass
    # Remake the red book master using the files in the red books directory
    new_master(REDBOOKS_MASTER)
    add_directory_to_master(REDBOOKS_DIR, REDBOOKS_MASTER)
    merge_w_ocr_version(REDBOOKS_MASTER, OCR_VERSION)
