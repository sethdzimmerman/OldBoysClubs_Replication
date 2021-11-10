import pandas as pd
import re
import os 
from jellyfish import damerau_levenshtein_distance
from tqdm import tqdm

NAME_DIR = "../../../Raw Data/Other/names"

years = range(1880, 2020)

name_data = {
    year: pd.read_table(os.path.join(NAME_DIR,f"yob{year}.txt"),sep=",",
                        names=['name','gender','frequency'])
    for year in years
}

def bowdlerize_name(name):
    """Removes all non-alphabet characters from a name, and converts to uppercase.
    The point is to make it easier to determine if two names are the same.
    """
    if not isinstance(name, str):
        return name
    name = re.sub(r'[^A-Za-z,\s\.\-]', '', name.upper())

    return name


def split_name(name):

    if not isinstance(name, str):
        return ('','','')

    name = bowdlerize_name(name)
    
    # Remove Suffixes
    name = re.sub(r',? (Jr|II+)\.?$','',name,flags=re.I)
    
    #Add space after dot
    name = re.sub(r'(\w+\.)(\w)',r'\g<1> \g<2>', name)
    
    # Bring into First Middle Last Structure instead of Last, First Middle
    name = re.sub(r'(\w+), ((\w+\s?)+)',r'\g<2> \g<1>',name)
    
    # Remove leading and trailing white space
    name = name.strip()
    
    # Split into parts
    parts = re.split(r'\s', name)
    first = str.capitalize(parts[0])
    last = str.capitalize(parts[-1])
    middle = str.capitalize(" ".join(parts[1:-1]))
    
    for name in [first,middle,last]:
        # Replace dash with space
        name = re.sub(r'(\w+)\-(\w+)',r'\g<1> \g<2>',name)

    return (first, middle, last)


def assign_gender(name,birth_year):
    
    ## Clean name
    first, middle, last = split_name(name)

    ## Check whether middle name is just an initial or full name
    try:
        middle_initial =  bool(re.search(r'\.',middle))
    except:
        middle_initial = True
    
    ## Load candidates
    candidates = pd.concat(
        [name_data[y] for y in range(birth_year - 5, birth_year + 6)]
        )
    candidates = candidates.groupby(['name','gender']).sum()
    candidates.sort_values(by=['name','frequency'],inplace=True)
    candidates.reset_index(inplace=True)

    # Try to find exact matches
    exact_matches = candidates.loc[candidates.name==first]

    # Exactly one perfect match found
    if len(exact_matches) == 1:
        gender = list(exact_matches['gender'])[0]
        confidence = 1
    
    # Ambigious matches, i.e. same name is given to boys and girls
    elif len(exact_matches) > 1:
        # Check for exact and unambigious match in middle name (if recorded)
        exact_middle_matches = candidates.loc[candidates.name == middle]
        if (len(exact_middle_matches) == 1) & (not middle_initial):
            gender = list(exact_middle_matches['gender'])[0]
            confidence = 1
        # Otherwise assign gender of the more common name and document confidence
        else:
            match_confidence = exact_matches.copy()
            match_confidence['confidence'] = exact_matches.groupby('name')['frequency']\
                                        .transform(lambda x: x / x.sum())
            match_confidence.sort_values('confidence',ascending=False,inplace=True)
            match_confidence.reset_index(inplace=True)
            
            gender = match_confidence['gender'][0]
            confidence= match_confidence['confidence'][0]
            

    # No exact matches
    # Get Damerau Levenshtein distance and calculate share of aggregate counts 
    # by gender for acceptable matches
    # Assign gender based on larger count among acceptable matches and confidence
    # as the share of counts of that gender of overall counts of acceptable matches
    else:
        first_edits = candidates['name'].\
                    apply(lambda x: damerau_levenshtein_distance(x, first))
        acceptable_matches = candidates[first_edits < 3]
        
        if len(acceptable_matches) >= 1:
            match_confidence = acceptable_matches.groupby('gender').\
                                agg({'frequency':'sum'})
            match_confidence['confidence'] = match_confidence['frequency'] \
                    / match_confidence['frequency'].sum()
            match_confidence.sort_values('confidence',ascending=False,inplace=True)
            match_confidence.reset_index(inplace=True)
            
            gender = match_confidence['gender'][0]
            confidence= match_confidence['confidence'][0]
        else:
            gender = ''
            confidence = pd.NaT

    return gender, confidence


def get_gender(df):
    """
    Assign gender based on first and middle name and birth name info from 
    https://www.ssa.gov/oact/babynames/limits.html .
    """
    df['ID_TEMP'] = df.index
    workdf = df.copy()
    workdf['birth_year'] = workdf.year - 22

    if len(workdf.index) > 0:
        print("\nStart assigning gender now...")
        gender_list = [
            assign_gender(n,y) for n,y in 
            tqdm(zip(workdf.name,workdf.birth_year),total=len(workdf.index))
            ]
        
        workdf['gender'] = [x[0] for x in gender_list]
        workdf['gender_confidence'] = [x[1] for x in gender_list]
        
        workdf = workdf[['ID_TEMP','gender','gender_confidence']]
        df = df.merge(workdf,on='ID_TEMP',how='left')
    
    df.drop(columns='ID_TEMP', axis=1, inplace=True)
    
    return df
    
    
    

