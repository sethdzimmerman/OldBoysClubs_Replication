# -*- coding: utf-8 -*-

from jellyfish import jaro_winkler
import os
import re
import sys
import pandas as pd
from tqdm import tqdm
sys.path.append('.')
from gender import get_gender

HANDCODED_REPORTS = '../../../Raw Data/Class_Reports/hand_coded'
UPDATED_REPORTS = '../../../Intermediate Data/Excel Files/updated_class_reports'


def rename_columns(df):
    """
    Standardize the format of column names with those of the previously cleaned
    class reports.
    """
    col_dict = {
        'birthDate': r'Born',
        'birthPlace': r'Born',
        'harvardBrothers': r'Harvard brother',
        'homeAddress': r'Home address',
        'work_address': r'(business|office) address',
        'name': r'^name',
        'spouseName': r'(Married|spouse/partner|spouse(_partner)?)$',
        'yrs_in_college': r'(years (at|in) college|years_in_college)',
        'degree': r'Degree',
        'high_school': r'(prepared( |_)at|secondary( |_)school)',
        'occupation': r'^occupation',
        'officesHeld': r'(offices held|offices_held)',
        'member_of': r'(Member of|memberships|member_of)',
        'activities': r'significant( |_)activities',
        'harvardDorm': r'House.* affil',
        'notes': r'Remarks',
        'year': r'Year$'
    }
    
    newcols = {
        col: [c for c in df.columns if re.search(col_dict[col],c,re.I)]
        for col in col_dict
        }
    
    for col in newcols:
        assert len(newcols[col]) <= 1
        
    newcols = {
        col: newcols[col]
        for col in newcols
        if len(newcols[col]) == 1
        }
    
    new_data = pd.DataFrame.from_dict({
        col: df[newcols[col][0]].tolist()
        for col in newcols
        })
    
    return new_data

    
def fix_birth(df):
    """
    Split the birth variable -- if existing -- into data of birth and place of 
    birth and standardize the date format.
    """
    ptrn = r'(\w+)\.? (\d{1,2}),?\s?(\d{2,4}).?\s(.+)'
    def _assign_birth_date(dob_str):
        try:
            month,day,year = re.search(ptrn,dob_str).group(1,2,3)
        except:
            month,day,year = ('','','')
        date = f"{month}-{day}-{year}"
        return date
    
    def _assign_birth_place(dob_str):
        try:
            place = re.search(ptrn,dob_str).group(4)
        except:
            place = ''
        return place
      
    if 'birthDate' in df.columns:
        df['birthDate'] = [_assign_birth_date(x) for x in df['birthDate']]
        df['birthPlace'] = [_assign_birth_place(x) for x in df['birthPlace']]    
    return df        



def fix_highschool(df):
    """
    Split the highschool variable up into school name and place.

    """
    try:
        highschools = df["high_school"].str.split(",", n = 1, expand = True)
        names = highschools[0]
        places = highschools[1]
        
        df['high_school_name'] = names
        df['high_school_place'] = places
        
        df.drop('high_school',axis=1,inplace=True)
    except KeyError:
        df['high_school_name'] = ''
        df['high_school_place'] = ''
        
    
    return df



def fix_degree(df):
    """
    Extract type of degree, honors supplement, institution and year of degree
    from the degree string. Keep only the first degree from Harvard and merge
    back on the original dataset.
    """
    print("\nStart cleaning degrees & honors now...")

    def _categorize_honors(honor_str):
        if not isinstance(honor_str,str):
            honor_str = ''
            
        honor_types = ['summa cum laude','magna cum laude','cum laude', 'highest honors']
        
        honor_dict = {
            h: jaro_winkler(h, honor_str)
            for h in honor_types
            }
        
        # Only clean the honor if sufficiently confident
        if max(honor_dict.values()) > 0.75:
            honor_str = max(honor_dict,key=honor_dict.get)
        return honor_str
        
    
    def _categorize_degree(degree):
        if not isinstance(degree,str):
            degree = ''
        deg_map = {
            'MBA': r'M\W?\s?B\W?\s?A\W?\s?',
            'AB': r'(A\W?\s?B\W?\s?|B\W?\s?A\W?\s?)',
            'JD': r'(J\W?\s?D\W?\s?|(M|J|PH)JD\.)',
            'MD': r'M\W?\s?D\W?\s?',
            'PHD': r'P\W?\s?H\W?\s?D\W?\s?',
            'LLB': r'L\W?\s?L\W?\s?B\W?\s?',
            'SB': r'(S\W?\s?B\W?\s?|B\W?\s?S\W?\s?)',
            'AM': r'(A\W?\s?M\W?\s?|M\W?\s?A\W?\s?)',
            'SM': r'(S\W?\s?M\W?\s?|M\W?\s?SC?\W?\s?)',
            'EDM': r'E\W?\s?D\W?\s?M\W?\s?',
            'EDD': r'E\W?\s?D\W?\s?D\W?\s?',
            'MFA': r'M\W?\s?F\W?\s?A\W?\s?',
            'MPA': r'M\W?\s?P\W?\s?A\W?\s?',
            'other': r'\S+'
        }
        
        for deg in deg_map:
            if re.search(deg_map[deg],degree,re.I):
                degree = deg
                break

        return degree


    def _extract_degree_info(degree_str):
        ### Set relevant patterns for extraction
        prof_grad_ptrn = r'(PHD|MD|JD|LLB)'
        other_grad_ptrn = r'(AM|SM|MBA|MFA|MPA|EDM|EDD|MARCH|MDIV)'
        laude_ptrn = (r'((\w+\s?)?(cum )?laude(.? (with (\w+\s)*honors?|(in )?' + \
                      'general.?( .?st\w+s| es)?|(highest )?in .*fiel\w{1,2})?)?)(,|\s|\.|\|)')
        year_ptrn = r'(19|\'|’)(\d{2})(\s?\((\'|’)\d{2}\))?\.?'        
        multi_degree_ptrn = r'(.+?' + year_ptrn + r')' 
        
        degree_patterns = {
            'MBA': r'(?:^|[^A-Z])M\s?\W?\s?B\s?\W?\s?A\s?\W?\s?(?=[^A-Z]|$)',
            'AB': r'(?:^|[^A-Z])(A\W?\s?b?B\W?\s?|B\W?\s?A\W?\s?)(?=[^A-Z]|$)',
            'JD': r'(?:^|[^A-Z])(J\W?\s?D\W?\s?|(M|J|PH)J\.?D\.)(?=[^A-Z]|$)',
            'MD': r'(?:^|[^A-Z])M\W?\s?D\W?\s?(?=[^A-Z]|$)',
            'PHD': r'(?:^|[^A-Z])P\W?\s?H\W?\s?D\W?\s?(?=[^A-Z]|$)',
            'LLB': r'(?:^|[^A-Z])L\W?\s?L\W?\s?(B|M|D)\W?\s?(?=[^A-Z]|$)',
            'SB': r'(?:^|[^A-Z])(S\W?\s?B\W?\s?|B\W?\s?S\W?\s?|(\s|^)S.\.B\.)(?=[^A-Z]|$)',
            'AM': r'(?:^|[^A-Z])(A\W?\s?M\W?\s?|(?<!SUM)M\W?\s?A\W?\s?)(?:\W(?!CUM LAUDE)|$)',
            'SM': r'(?:^|[^A-Z])(S\W?\s?M\W?\s?|M\W?\s?SC?\W?\s?)(?=[^A-Z]|$)',
            'EDM': r'(?:^|[^A-Z])E\W?\s?D\W?\s?M\W?\s?(?=[^A-Z]|$)',
            'EDD': r'(?:^|[^A-Z])E\W?\s?D\W?\s?D\W?\s?(?=[^A-Z]|$)',
            'MFA': r'(?:^|[^A-Z])M\W?\s?F\W?\s?A\W?\s?(?=[^A-Z]|$)',
            'MPA': r'(?:^|[^A-Z])M\s?\W?\s?P\s?\W?\s?A\W?\s?(?=[^A-Z]|$)',
            'MARCH': r'(?:^|[^A-Z])M\s?\.\s?A\W?\s?R\W?\s?C\W?\s?(H|U)\W?\s?(?=[^A-Z]|$)',
            'MDIV': r'(?:^|[^A-Z])M\W?\s?D\W?\s?I\W?\s?V\W?\s?(?=[^A-Z]|$)'
        }    
            
        ### Fix common spelling mistakes
        if not isinstance(degree_str, str):
            degree_str = ''
        
        # Odd Characters in degree
        degree_str = re.sub(r'(^|\s)(\$|\&|\?|\§|\d)(\.?(B|M)\.[^A-Z])',r'\g<1>A\g<3>',degree_str)
        degree_str = re.sub(r'(A|S)\.8\.','\g<1>.B.',degree_str,flags=re.I)
        # Spelling mistakes with honors string bit        
        degree_str = re.sub(
        r'(.?c\w+\?? laude|cum (alude|l\w+e|laud\W|Icuide|lauder)|cumlaude|cum, laude|cu7m laudse)',
        ' cum laude', degree_str, flags=re.I)
        # No space before cum laude
        degree_str = re.sub(r'(\.)((\w+\s)?(cum laude))',r'\g<1> \g<2>',degree_str,flags=re.I)
        # In earlier years, the major is documented in caps after degree
        # degree_str = re.sub(r'IN\.? ([A-Z]+\.?\s)+',' ',degree_str)
        # No space between year from previous degree and next degree
        degree_str = re.sub(r'(\d{2}\((19|\'|’)\d{2}\)\.)(\w)', 
                        r'\g<1> \g<3>',degree_str,flags=re.I)
        # Letter instead of digit in year
        degree_str = re.sub(r'((19|\'|’)\d)O',r'\g<1>0',degree_str)
        degree_str = re.sub(r'((19|\'|’)\d)(l|I)',r'\g<1>1',degree_str)
        # Missing second dot after degree
        degree_str = re.sub(r'([A-Z]\.\s?[A-Z]\s)([^\.])',r'\g<1>.\g<2>',degree_str)
        # Spaces between degree with dots
        degree_str = re.sub(r'([A-Z]\.)\s([A-Z]\.)',r'\g<1>\g<2>',degree_str)
        # Switch apostroph to before year
        degree_str = re.sub(r'([^\'(19)’])(\d{2})(\'|·|’|\.)',r"\g<1>'\g<2>", degree_str)
        # Add apostroph to year if missing
        degree_str = re.sub(r'(\s|\(|\.|,|\:|\;)(\d{2})(,|\s|\(|\;|\:|\]|\||\)|$)',
                        r"\g<1>'\g<2>\g<3>",degree_str)
        # No space before year
        degree_str = re.sub(r'([^\s\(])((19|\'|’)\d{2})',r'\g<1> \g<2>',degree_str,flags=re.I)
        # Too many digits in year (remove last digit)
        degree_str = re.sub(r'(19\d{2})(\d)(\D)',r'\g<1> \g<3>',degree_str)
        # No space after year
        degree_str = re.sub(r'((19|\'|’)\d{2})(\S)',r'\g<1> \g<3>',degree_str)
        # Wrong character in year
        degree_str = re.sub(r'(\D)(9\d{2,3})',r'1\g<2>',degree_str)
        # No Space before parantheses
        degree_str = re.sub(r'(\S)(\(.?[^0-9]+.?\))',r'\g<1> \g<2>',degree_str)
        # Remove literal backslashes
        degree_str = re.sub(r'\\',' ', degree_str)
        # Unnecessary field of degree after degree
        degree_str = re.sub(r' IN (([A-Z]+\.(\s|,|;|\|))+(AND )?)+(ENG\w*[^A-Z])?',' ', degree_str)
        degree_str = re.sub(
            (r'\WIN (([A-Z]E\.?|[A-Z](\.\s?|[A-Z]+\W?\s)E(\.|[A-Z]+\.?)|ENG\w+\.?)' + \
            r'( AND BUS\.? AD\w+\.?)?|CHEM\.|ADM(IN)?\.)(\sIN(\.|\w+)?)?\W'),
            ' ',degree_str,flags=re.I)
        # Also for typo in field description
        degree_str = re.sub(r' IN [A-Z]+\.\s?\w+\.',' ',degree_str)
        if re.search(r'\((\D+)\)',degree_str):
            para_contents = re.findall(r'\((\D+?)\)',degree_str)
            for p in para_contents:
                # Make parantheses if they are nested in parantheses literal
                p = p.replace('(','\(')
                p = p.replace(')','\)')
                
                # Remove parantheses only if they contain institution info
                if re.search(r'(Uni|College|School|Institute)',p):
                    degree_str = re.sub(r'\((' + p + r')\)',r'\g<1>',degree_str)
                # Otherwise remove contents of parantheses as well
                else:
                    degree_str = re.sub(r'\(' + p + r'\)','',degree_str)
        # Delete divorce announcement
        degree_str = re.sub(r'\(divorced .*\)','',degree_str,flags=re.I)
        # Delete multiple whitespaces
        degree_str = re.sub(r'\s+',' ',degree_str)
        # Delete quotes
        degree_str = re.sub(r'\"','',degree_str)
        # Delete trailing letter after commong degrees
        degree_str = re.sub((r'\w?(M\.?\s?B\.?\s?A\.?|LL\.?\s?B\.?|' + \
                             'M\.?\s?D\.?|A\.?\s?M\.?|' + \
                             r'P\.?\s?H\.?\s?D\.?)\w{0,2}'),r'\g<1>',degree_str,flags=re.I)
        
        
        ### Split up degrees by ;
        try:
            degrees = re.split(r';|\:|\]',degree_str)
        except:
            degrees = []
        
        # Set degrees to empty list if degree_str is missing
        if len(degree_str) == 0:
            degrees = []
        ### Fix entries for which two different degrees ended up in the same 
        ### list item
        else: 
            for d in range(0,len(degrees)):
                full = degrees[d]
                try:
                    multi = re.findall(multi_degree_ptrn,full)
                    if len(multi) > 0:
                        del degrees[d]
                        p = 0
                        for x in multi:
                            temp = str.strip(x[0])
                            full = str.strip(full.replace(temp,''))
                            degrees.insert(d+p,temp)
                            p +=1
                            
                        if len(full) > 1:
                            degrees.insert(d+p,full)
                except:
                    continue
            
        
        ### Extract degree type, honors, institution and year of degree for  
        ### each listed degree item
        degree_data = {}
        for d in range(0,len(degrees)):
            temp = degrees[d]
            if (not isinstance(temp,str)) | (len(temp)==0):
                continue
            
            ## Degree
            degree = ''            
            for deg in degree_patterns:
                if re.search(degree_patterns[deg],temp,re.I):
                    if len(degree)==0:
                        degree = deg
                    else:
                        degree = ", ".join([degree,deg])
                    temp = re.sub(degree_patterns[deg],'',temp,flags=re.I)
                    
            
            # Treat an AB as the default degree, if not degree pattern can be matchedd
            if len(degree) == 0:
                degree = 'AB'
                
            ## Honors
            try:
                honors = re.search(laude_ptrn,temp,re.I).group(1)
                # Clean honors
                honors = _categorize_honors(honors)
                honors = re.sub(r'^([^A-Z]+)','',honors,flags=re.I)
                # Remove honors string bit from string
                temp = re.sub(laude_ptrn,'',temp,flags=re.I)
                temp = re.sub(r'h\w+st honors','',temp,flags=re.I)
            except:
                honors = ''
            
            ## Year
            try:
                year = 1900 + int(re.search(year_ptrn,temp).group(2))
                # Remove degree bit from string
                temp = re.sub(year_ptrn,'',temp,flags=re.I)
            
            except:
                year = None
            
            ## Institution = Remainer of string
            institution = str.strip(temp)
            re.sub(r'^([^A-Z]+)','',institution,flags=re.I)
            # Replace Harvard as the default institution if no instution is listed
            if not re.search(r'[A-Za-z]',institution):
                institution = 'Harvard'
            # Replace institution with Harvard as default if honors string bit 
            # accidentically was not extracted
            if re.search(r'(cum laude|honors)',institution,re.I):
                honors = institution
                institution = 'Harvard'
            
            degree_data[d] = {
                'degree': degree,
                'honors': honors,
                'degree_year': year,
                'institution': institution
                }
            
        if len(degrees) > 0:
            degdf = pd.DataFrame.from_dict(degree_data,orient='index')

            # Only keep the first degree from Harvard
            harvard_deg = degdf.loc[[bool(re.search('Harvard',x,re.I))
                                     for x in degdf.institution]]
            try:
                harvard_deg = harvard_deg.iloc[0]
                harvard_deg['harvard_degree'] = 1
                harvard = (harvard_deg.degree,harvard_deg.honors,
                           harvard_deg.degree_year,harvard_deg.harvard_degree)
            except:
                harvard = ('','','',0)

            # Graduate degrees
            ## Professional degrees (PhD, MD, JD, LLB, MBA)
            ## Other grad. degrees (MA, MS, EdM, EdD, MFA, MPA)
            prof_grad_degrees = []
            other_grad_degrees = []
            for x in degdf['degree']:
                prof_grad_degrees += re.findall(prof_grad_ptrn,str(x),re.I)
                other_grad_degrees += re.findall(other_grad_ptrn,str(x),re.I)               

            grad_degrees = prof_grad_degrees + other_grad_degrees
            grad_deg = {
                'any_prof_grad': 1* bool(len(prof_grad_degrees) > 0),
                'any_other_grad': 1* bool(len(other_grad_degrees) > 0),
                'N_grad': len(grad_degrees),
                'grad_degrees': ', '.join(grad_degrees)
            }
            grad = tuple((grad_deg[col] for col in grad_deg))

            out = harvard + grad
        else:
            out = ('','','','','','','','')
        
        return out
        
    deg_info = pd.DataFrame(
        [_extract_degree_info(x) 
        for x in tqdm(df['degree'],total=len(df.degree))],
        columns=['degree','honors','degree_year','harvard_degree','any_prof_grad','any_other_grad','N_grad','grad_degrees']
        )

    df = df.rename(columns={'degree':'degree_str'})
    df = df.join(deg_info,how='left')
    
    return df   
    


def assign_pid(df):
    
    pids = [
        f"no_pid_{index+100000}" if pd.isna(row['PID'])
        else row['PID'] 
        for index,row in df.iterrows()
        ]
    
    df['PID'] = pids
    
    return df



def clean_data(to_clean_dir=HANDCODED_REPORTS,cleaned_dir=UPDATED_REPORTS,
               out_dir=UPDATED_REPORTS):
    """
    Clean and join all new datafile in clean_dir and add the existing/old
    cleaned class reports. Make unified PID without matching new records to 
    Family Search for new records and export to out_dir.

    """
    # Load Handcoded Class-Report Data
    new_class_reports = [os.path.join(to_clean_dir,f) 
                         for f in os.listdir(to_clean_dir)
                         if re.search('template',f,re.I)]
        
    existing_file = os.path.join(cleaned_dir,'all_years.csv')
    
    data = {}
    for file in new_class_reports:
        year = re.search(r'(\d{4})',file).group(1)
        print(f"Now cleaning class reports for year {year}")
        # Load handcoded data
        df = pd.read_excel(file,engine='openpyxl')
        
        # Rename columns and clean relevant information
        df = rename_columns(df)
        if 'year' not in df.columns:
            df['year'] = int(year)
        df = fix_birth(df)
        df = fix_highschool(df)
        df = fix_degree(df)
    
        data[year] = df
    
    long = pd.concat([data[year] for year in data])
    
    # Add old file and fix degree columns
    old = pd.read_csv(existing_file)
    old = fix_degree(old)
    
    ## Combine new and existing class reports
    final = pd.concat([old,long])
    final = final.sort_values(by=['year','PID','name'])  
    final.reset_index(inplace=True,drop=True)

    
    ### Assign ID based on no_pid_x pattern
    final = assign_pid(final)
    
    ## Export 
    final.to_csv(os.path.join(out_dir,'longrun_series_class_reports.csv'),index=False)



if __name__ == '__main__':
    
    # Clean, merge with existing class report data and 
    # export to final long-run series
    clean_data(HANDCODED_REPORTS,UPDATED_REPORTS,UPDATED_REPORTS)
        



