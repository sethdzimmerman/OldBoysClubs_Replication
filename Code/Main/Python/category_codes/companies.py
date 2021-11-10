# -*- coding: utf-8 -*-
"""
tools for determining what companines individuals in class reports worked for
"""


import pandas as pd
import re
import os


COMPANY_KEY = '../../../../Code/Keys/company_key.xlsx'


company_codes = pd.read_excel(COMPANY_KEY, sheet_name=0, index_col=0,engine='openpyxl')
company_codes['regex'] = company_codes['regex'].apply(re.compile)


def get_occupations(source_files):
    """Loads occupation data from source file CSVs containing class report data.

    :param source_files: either a string or a list of strings, corresponding to filename(s) of CSVs to import
    :return: a Pandas Series containing the occupations column from the imported files. Index is the PIDs column
    """
    if not isinstance(source_files, list):
        source_files = [source_files]
    occupations = pd.concat([pd.read_csv(f, index_col='PID')['occupation'].dropna() for f in source_files])
    return occupations


def get_code(occupation):
    """iterates through company codes to find one that matches the given occupation string"""
    if not isinstance(occupation, str):
        return []
    occupation = occupation.lower()
    matches = [i for i, r in zip(company_codes.index, company_codes['regex']) \
               if r.search(occupation)]
    return matches


def get_all_codes(occupations):
    """iterates through occupations Series and returns df with all company matches"""
    all_matches = [(pid, get_code(occupation)) for pid, occupation in occupations.iteritems()]
    all_matches = sum([list(zip([pid]*len(codes), codes)) for pid, codes in all_matches], [])
    df = pd.DataFrame(all_matches)
    df.columns = ['PID', 'rank']
    df.set_index('PID', drop=True, inplace=True)
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
    '''Classifying companies'''
    df = get_all_codes(occupations)
    try:
        df.to_csv('../../../../Intermediate Data/codes/company_codes.csv')
    except FileNotFoundError:
        print('Saving to local directory {}...'.format(os.getcwd()))
        df.to_csv('company_codes.csv')

