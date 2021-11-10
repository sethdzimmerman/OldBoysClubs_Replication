"""
tools for categorizing occupations in Harvard class reports
"""

import pandas as pd
import re
import os
from tqdm import tqdm

OCCUPATION_KEY = {
    'main': '../../../../Code/Keys/occupation_key.xlsx',
    'longrun': '../../../../Code/Keys/lr_occupation_key.xlsx',
    'intended': '../../../../Code/Keys/occupation_intended_key.xlsx'
}


def get_occupations(source_files,id_var="PID"):
    """Loads occupation data from source file CSVs containing class report data.

    :param source_files: either a string or a list of strings, corresponding to filename(s) of CSVs to import
    :param id_var: string variable corresponding to the variable that identifies that data
    :return: a Pandas Series containing the occupations column from the imported files. Index is the id_var column
    """
    if not isinstance(source_files, list):
        source_files = [source_files]
    occupations = pd.concat([pd.read_csv(f, index_col=id_var)['occupation'].dropna() for f in source_files])
    return occupations


def tokenize(text):
    """Remove all non-alphabet characters from a string and split into chunks of alphabet chars"""
    text = re.sub(r'[^A-Za-z]', ' ', text)
    text = re.sub(r' +', ' ', text).strip()
    tokens = [x.lower() for x in text.split()]
    return tokens

def clean_text(text):
    """Remove all non-alphabet characters from a string and split into chunks of alphabet chars"""
    text = re.sub(r'[^A-Za-z]', ' ', text)
    text = re.sub(r' +', ' ', text).strip()
    text = text.lower()
    return text


def get_classes(ID, occ_string,codes,method):
    """Takes an ID (PID or index) and occupation string (e.g. from iteritems on a Series returned from get_occupations)
    finds occupation codes for the input, then returns a list of tuples, each tuple's first entry being the ID
    and the other two entries being an occupation code.
    """
    ## Method 1: The intersection onf one-word elements in the occ_string and set of identifiers is non-empty
    if method == 'tokenize':
        tokens = set(tokenize(occ_string))
        classes = (i for i in codes.index if (tokens & codes[i]))
    
    ## Method 2: The identifier regex of a code can be found in the occ_string 
    if method == 'regex':
        occ_string = clean_text(occ_string)
        classes = (i for i in codes.index 
                if any(re.search(r'(\s|^)' + ptrn + r'(\s|$)',occ_string) for ptrn in codes[i]))
        
    return [(ID, *code) for code in classes]


def get_classes_for_occupations(occupations,key_type='main',method='tokenize',id_var='PID'):
    """Takes a Series of occupations (from get_occupations), gets occupation codes for each one, and creates a DataFrame
    whose Index is the PIDs and columns are the corresponding occupation codes.
    """
    # Category codes must be in first two cols of occupation key spreadsheet
    occ_code_file = OCCUPATION_KEY[key_type]

    # Determine which column to use as occupation identifier codes
    if method == 'tokenize':
        id_col = 'identifiers'
    if method == 'regex':
        id_col = 'identifiers_regex'
    codes = pd.read_excel(occ_code_file, index_col=[0,1],engine='openpyxl')[id_col].apply(lambda x: set(x.split(', ')))

    classes = sum((get_classes(ID, occ_string, codes, method) for ID, occ_string in tqdm(
        occupations.iteritems(),
        total=len(occupations))), [])
    df = pd.DataFrame(classes)
    df.columns = [id_var, 'category code', 'subcategory code']
    df.set_index(id_var, drop=True, inplace=True)
    return df


if __name__ == '__main__':
    try:
        file = '../../../../Intermediate Data/Excel Files/updated_class_reports/all_years.csv'
        occupations = get_occupations(file)
    except FileNotFoundError:
        print('all_years.csv not found')
        filedir = input('Type the path to the folder that contains the class reports you want to match from: ')
        files = [os.path.join(filedir, f) for f in os.listdir(filedir) if f[-4:] == '.csv']
        occupations = get_occupations(files)
    classes = get_classes_for_occupations(occupations)
    try:
        classes.to_csv('../../../../Intermediate Data/codes/occupation_codes.csv')
    except FileNotFoundError:
        print('Saving to local directory {}...'.format(os.getcwd()))
        classes.to_csv('occupation_codes.csv')
