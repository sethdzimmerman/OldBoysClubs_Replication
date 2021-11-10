# -*- coding: utf-8 -*-


import re
import pandas as pd


REGEX_FILE = '../../../../Code/Keys/offices_key.xlsx'
CLASS_REPORTS = '../../../../Intermediate Data/Excel Files/updated_class_reports/all_years.csv'
SAVE_LOC = '../../../../Intermediate Data/codes/offices.csv'

regexes = pd.read_excel(REGEX_FILE, sheet_name=None,engine='openpyxl')

#head_regexes = [
#        r'assistant(?: to)?(?: the)? president|(president)',
#        r'assistant(?: to)?(?: the)? vice.?president|(vice.?president)',
#        r'assistant(?: to)?(?: the)? past.president|(past.president)',
#        r'assistant(?: to)?(?: the)? chair(?:man)?|(chair(?:man)?)',
#        r'assistant(?: to)?(?: the)? director|directors|(director)',
#        r'assistant(?: to)?(?: the)? governor|governor.?s|(governor)',
#        r'assistant(?: to)?(?: the)? chief(?:[ -]of|,)|(chief(?:[ -]of|,))'
#        r'assistant(?: to)?(?: the)? head of |(head of )',
#        r'assistant(?: to)?(?: the)? dean|(dean)'
#        ]
head_regexes = [re.compile(regex, flags=re.IGNORECASE) for regex in regexes['HeadOfOrg']['regex']]

#comm_regexes = [
#        r'board of (?:directors|governors|managers)',
#        r'member of board,',
#        r'member(?:,| of) \S+ (?:board|committee)',
#        r'trustee'
#        ]
comm_regexes = [re.compile(regex, flags=re.IGNORECASE) for regex in regexes['BoardMember']['regex']]

#gov_regexes = [
#        r'(senator)',
#        r'(house of representatives)',
#        r'(legislature)',
#        r'(?:assistant|deputy)(?: to)?(?: the)? attorney general|(attorney general)',
#        r'(?:to |for |-)mayor,|(mayor,)',
#        r'(?:^| )((?:town|city) council)'
#        ]
gov_regexes = [re.compile(regex, flags=re.IGNORECASE) for regex in regexes['Government']['regex']]


def head_of_org(office):
    if not isinstance(office, str):
        return False
    for regex in head_regexes:
        search = regex.search(office)
        if search is not None and search.group(1) is not None:
            return True
    return False
    

def on_committee(office):
    if not isinstance(office, str):
        return False
    for regex in comm_regexes:
        search = regex.search(office)
        if search is not None:
            return True
    return False


def gov_office(office):
    if not isinstance(office, str):
        return False
    for regex in gov_regexes:
        search = regex.search(office)
        if search is not None and search.group(1) is not None:
            return True
    return False


def load_offices_from_csv(filename=CLASS_REPORTS):
    # Initialize data frame with only offices from the input CSV
    df = pd.read_csv(filename, index_col='PID', usecols=['PID', 'officesHeld']).dropna()
    # Add column for head of organization
    df['head_of_org'] = df['officesHeld'].apply(head_of_org).astype('int')
    df['on_committee'] = df['officesHeld'].apply(on_committee).astype('int')
    df['gov_office'] = df['officesHeld'].apply(gov_office).astype('int')
    return df


if __name__ == '__main__':
    df = load_offices_from_csv()
    df.to_csv(SAVE_LOC)