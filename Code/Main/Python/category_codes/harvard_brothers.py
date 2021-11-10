# -*- coding: utf-8 -*-
"""
Finds all pairs of Harvard brothers from the class report data
Also outputs simple list of individuals with a father or at least one brother reported as having gone to harvard
"""



import pandas as pd
import re

from jellyfish import damerau_levenshtein_distance as dl_dist


CLASS_REPORTS = '../../../../Intermediate Data/Excel Files/updated_class_reports/all_years.csv'
OUTPUT = '../../../../Intermediate Data/codes/harvard_brothers.csv'  # harvard brother output

OUTPUT_SIMPLE = '../../../../Intermediate Data/codes/have_harvard_family.csv'  # has harvard brother or father 

brothers_re = re.compile(r'((?:\S+\s)+?\S+[A-ZÉ)](?:,? \S{2,3}\.?)?) ?,?.{1,3}(\d{2})(?:[;. ,(/]|[^\d]?$)')


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


def load_class_reports(class_reports=CLASS_REPORTS):
    df = pd.read_csv(CLASS_REPORTS, index_col='PID')
    df['name'] = df['name'].apply(lambda x: x.upper() if isinstance(x, str) else '')
    df['first_name'] = df['name'].apply(get_first_cr)
    df['middle_name'] = df['name'].apply(get_middle_cr)
    df['last_name'] = df['name'].apply(get_last_cr)
    df['harvard_brothers'] = df['harvardBrothers'].apply(lambda x: x.upper() if isinstance(x, str) else None)
    return df[['year', 'first_name', 'middle_name', 'last_name', 'harvard_brothers']]



class Matcher:
    
    def __init__(self, class_reports=CLASS_REPORTS):
        df = load_class_reports(class_reports)
        self.w_brothers = df.dropna(subset=['harvard_brothers'])
        self.all_years = {year: df[df['year'] == year] for year in df['year'].unique()}

    def find_match(self, harvard_brothers):
        brothers = brothers_re.findall(harvard_brothers)
        if not brothers:
            return []
        brother_pids = []
        for brother in brothers:
            year = int('19' + brother[1])
            # look for exact year and first & last name matches
            if year in self.all_years.keys():
                first_name = get_first_cr(brother[0])
                middle_name = get_middle_cr(brother[0])
                last_name = get_last_cr(brother[0])
                look_in = self.all_years[year]
                matches = look_in[(look_in['last_name'] == last_name) & (look_in['first_name'] == first_name)]
                if matches.empty:
                    # look for near matches (<= 2 edits)
                    scores = look_in['first_name'].apply(lambda x: dl_dist(x, first_name)) + \
                                look_in['last_name'].apply(lambda x: dl_dist(x, last_name))
                    matches = look_in[scores <= 2]
                    # also require middle names to start with same letter
                    matches = matches[matches['middle_name'].apply(
                        lambda x: (x[0] == middle_name[0]) if (x and middle_name) else True)]
                if len(matches) > 1:
                    # also filter by middle name if necessary
                    matches = matches[matches['middle_name'] == middle_name]
                if len(matches) == 1:
                    brother_pids.append(matches.index[0])
        return brother_pids
    
    def find_all_matches(self):
        family_dict = {}
        next_id = 0
        for PID, row in self.w_brothers.iterrows():
            brother_pids = self.find_match(row['harvard_brothers'])
            if brother_pids:
                all_pids = [PID] + brother_pids
                for pid in all_pids:
                    if pid in family_dict.keys():
                        family_id = family_dict[pid]
                        break
                else:
                    family_id = next_id
                    next_id += 1
                for pid in all_pids:
                    family_dict[pid] = family_id
        df = pd.DataFrame.from_dict(family_dict, orient='index', columns=['family_id'])
        df.index.name = 'PID'
        print(f'Found {len(df)} matches in {next_id} families from {len(self.w_brothers)} entries.')
        return df
    


if __name__ == '__main__':
    # do brother matching
    df = Matcher().find_all_matches()
    df.to_csv(OUTPUT)
    # compile list of PIDs with harvard father or brothers
    have_harvard_brother = df.index
    have_harvard_father = pd.read_csv(CLASS_REPORTS, index_col='PID').dropna(subset=['harvardFather']).index
    df_simple = pd.DataFrame(index=have_harvard_brother.union(have_harvard_father))
    df_simple['harvard_brother'] = df_simple.index.map(lambda x: int(x in have_harvard_brother))
    df_simple['harvard_father'] = df_simple.index.map(lambda x: int(x in have_harvard_father))
    df_simple.to_csv(OUTPUT_SIMPLE)
