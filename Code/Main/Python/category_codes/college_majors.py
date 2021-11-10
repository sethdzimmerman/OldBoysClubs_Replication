"""
tools for categorizing college majors in Harvard class reports
"""

import pandas as pd
import re
import os
from tqdm import tqdm
import sys

COLLEGE_MAJOR_KEY = '../../../../Code/Keys/college_major_key.xlsx'
INPUT = '../../../../Intermediate Data/codes/senior_class_registers.csv'
OUTPUT = '../../../../Intermediate Data/codes/college_major_codes.csv'


def clean_text(text):
    """Remove all non-alphabet characters from a string and split into chunks of alphabet chars"""
    if not isinstance(text, str):
        text = ''
    text = re.sub(r'[^A-Za-z]', ' ', text)
    text = re.sub(r' +', ' ', text).strip()
    text = text.lower()
    return text

def get_majors(file,id_var="rb_index"):
    """Loads college major data from source file CSVs containing class report data.
    :param source_files: either a string or a list of strings, corresponding to filename(s) of CSVs to import
    :param id_var: string variable corresponding to the variable that identifies that data
    :return: a Pandas Series containing the college major column from the imported files. Index is the id_var column
    """
    majors = pd.read_csv(file)[[id_var,'major']].dropna()
    majors = majors.set_index(id_var)['major']
    return majors


def get_classes(ID, major_string, codes):
    """Takes an ID (PID or index) and major string (e.g. from iteritems on a Series returned from get_majors)
    finds college major codes for the input, then returns a list of tuples, each tuple's first entry being the ID
    and the other two entries being a college major code.
    """
    major_string = clean_text(major_string)
    classes = (i for i in codes.index 
            if any(re.search(ptrn,major_string) for ptrn in codes[i]))
        
    return [(ID, *code) for code in classes]


def get_classes_for_majors(majors,id_var='rb_index'):
    """Takes a Series of college majors (from get_majors), gets college major codes for each one, and creates a DataFrame
    whose Index is the redbook index and columns are the corresponding college major codes.
    """
    codes = pd.read_excel(COLLEGE_MAJOR_KEY, index_col=[0,1],engine='openpyxl')['identifiers'].apply(lambda x: set(x.split(', ')))

    classes = sum((get_classes(ID, major_string, codes) for ID, major_string in tqdm(
        majors.iteritems(),
        total=len(majors))), [])
    df = pd.DataFrame(classes)
    df.columns = [id_var, 'category code', 'subcategory code']
    df.set_index(id_var, drop=True, inplace=True)
    return df


def classify_college_majors(file):
    print("Classifying college majors from senior class registers now...")
    try:
        college_majors = get_majors(file)
    except FileNotFoundError:
        print(f'{file} not found')
        file = input("Please specify the path to the correct file.")
        college_majors = get_majors(file)
        
    classes = get_classes_for_majors(college_majors)
    
    try:
        classes.to_csv(OUTPUT)
    except FileNotFoundError:
        print('Saving to local directory {}...'.format(os.getcwd()))
        classes.to_csv('college_major_codes.csv')


if __name__ == '__main__':
    if len(sys.argv) == 2:
        file = sys.argv[1]
    else:
        file = INPUT
    classify_college_majors(file)
