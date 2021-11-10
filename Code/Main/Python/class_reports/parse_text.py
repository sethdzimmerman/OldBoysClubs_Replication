# -*- coding: utf-8 -*-
"""
Extracts identifiers from documents containing OCRed Harvard class reports
"""

import re
import sys
import pandas as pd
from tqdm import tqdm 

months = {
    'Jan': 'January',
    'Feb': 'February',
    'March': 'March',
    'April': 'April',
    'May': 'May',
    'Afay': 'May',
    'Nfay': 'May',
    'June': 'June',
    'July': 'July',
    'Aug': 'August',
    'Sept': 'September',
    'Oct': 'October',
    'Nov': 'November',
    'Noy': 'November',
    'Dec': 'December',
    'Dee': 'December'
}

flags = re.DOTALL | re.IGNORECASE

profiles_re = re.compile(r'(?<=\n)(?:[^A-Z\d]{2,3})?' +
                         r'((?:(?:D[a-z])?[A-Zac,]{2,}? )(?:(?:D[a-z])?[A-Zace,\-\']+\.? ?){1,4})[^A-Z]{0,2} ?\n(.*?)' +
                         r'(?=\n(?:[^A-Z\d]{2,3})?' +
                         r'(?:(?:D[a-z])?[A-Zac,]{2,}? )(?:(?:D[a-z])?[A-Zace,\-\']+\.? ?){1,4}[^A-Z]{0,2} ?\n|$)',
                         flags=re.DOTALL)
address_re = re.compile(r'(?:^|\n)HOME.{0,30}?: (.+?\.)\n', flags=flags)
work_addr_re = re.compile(r'\n[Oo][Ff][Ff][Ii][Cc][Ee][^Ss].{1,15}?[:!;]\s(.*?)\n+(?:[A-Z ]{3}|\n|$)',
                          flags=re.DOTALL)
birth_re = re.compile(r'[BPG]O\S\S[:;] (\S+\s\d{1,2},\s\S{4})[,.:;]{1,2}(?:\s(.+?[.,:;]))?(?:\sp{1,2}a\S{4,6}[:;]\s' +
                      r'(.+?),(?:\s[\'‘’]?(\d\d),)?\s(.*?)[.,][^A-Za-z]*?)?\n',
                      flags=flags)
married_re = re.compile(r'\nM\S{5,7}[:!;] ([^,]{1,100})', flags=flags)
family_re_old = re.compile(r'\nM(?!OTHER)\S{5,7}[:!;]([^,]{1,100}), (.+?)([^ :]+)' + \
                           r'(\n\n|[:]|$)(([^:]+)([:]|\n\n|$))?', flags=flags)
    
family_re = re.compile(r'\n(?:M(?!OTHER)\S{5,7}|ARRIED)[:!;]([^,]{1,100})' + \
                       r'(?:(?:, )(.+?)|(?:\.|,)\s?\n\n)\n*([^\s:\.]+|HARVARD BROTHERS?)?' + \
                       r'(?:[:]|(?<=CHILDREN);|(?<=OCCUPATION);|(?<=BROTHER);|(?<=[\.\-])\n+|$)' + \
                       r'(?:(.+?)(?:[:]|\n\n|$))?', flags=flags)
    
children_re_old = re.compile(r'^\W?(C.{1,10}EN|C\w*P$|C.{1,3}LD|C.?ID$|C.?IL.?D|CAIL.?$|' + \
                         r'CHIL|(D|(UI)?P)REN|(HARVARD)?SON|CUI?T|C.*(P|O)AR|CIUT|CA(I|T)T|CIUO|CUM$|CNX|CH\s?$|CRIVORRS)',flags=flags)
children_re = re.compile(r'^\W?(C|SON|\w*(P|D)REN|GUIPASS|QUI|\w*PAR\w?$|\w*REN$)',flags=flags)
    
graduated_re = re.compile(r'YEAR.{8,25}[:!;] (\d{4}[-—~]\d{4})(?:\.? {0,2}DEGREES?[:!;] (.*?)[,.]\n)?', flags=flags)
high_school_re = re.compile(r'PREPARED AT[:!;] (.*?)(?:,\s(.*?))?\n', flags=flags)
harvard_bros_re = re.compile(r'HARVARD BROTHERS?[:!;]((?:\s.{1,50}\d\d[,;.]{1,2})+?)', flags=flags)
occupation_re = re.compile(r'[Oo][Cc]{2}.{5,11}[:!;] (.+?)\.?\n+' +
                           r'(?:[A-Z\d ]{2}|[+*]|[oO][rR]?[fF].{9,11}[:!;]|\n[A-Za-z\d ]{3}|$)', flags=re.DOTALL)
offices_re = re.compile(r'\n[Oo][Ff][Ff][Ii][Cc][Ee][Ss].{1,15}?[:!;]\s(.*?)\n+(?:[A-Z ]{3}|\n[A-Z][A-Za-z ]{2}|$)',
                        flags=re.DOTALL)
member_re = re.compile(r'\n(?:[mM]{1,2}[eE][mM]\S{2,5} [oO][fFVv]|[Mm][Ee][Mm][Bb][Ee][Rr]) ?[:!;]\s(.*?)\.?\n+' +
                       r'(?:\n[A-Z\d ]|[+*]|[pP][uU]\S{9,11}[:!;]|$)', flags=re.DOTALL)
publications_re = re.compile(r'\n[Pp][Uu][^ ]{7,17}[:!;]\s(.*?)\.?\n+(?:[A-Z\d+* ]{2}|\n[A-Z]|$)', flags=re.DOTALL)


def load_doc(filename):
    """Takes a file containing plain text with file name `filename`
    and cleans up the text to prepare for processing.
    """
    with open(filename, 'r', encoding='utf-8') as fh:
        text = fh.read()
    # Remove page breaks
    text = re.sub(r'\n\[|\| ?.{1,4} ?\]|\|.{1,2000}(?:HARVARD C|REPORT)[^\n]*\n', '\n',
                  text, flags=re.DOTALL)
    # Remove "HARVARD CLASS"  and "25TH ANNIVERSARY" stuff
    text = re.sub(r'(?:HARVARD CLASS|\d\dTH ANNIVERSARY)[^\n]*', '\n', text)
    # Join hyphenated line breaks
    text = re.sub(r'-\n', '', text)
    # Remove "UNMARRIED" -- it confuses the name-finding regular expression
    text = re.sub(r'UN ?MARRIED.\n', '', text)
    return text


def split_into_profiles(text):
    profiles = profiles_re.findall(text)
    return profiles


def process_date(date):
    """Convert date into the format that FamilySearch likes
    """
    parts = re.split(r'[\s,.]+', date)
    if len(parts) != 3:
        return date
    try:
        month = months[parts[0]]
    except KeyError:
        #print(parts[0])
        month = parts[0]
    day = parts[1]
    year = parts[2]
    return '{} {} {}'.format(day, month, year)


def remove_newlines(obj):
    if type(obj) is not str:
        return obj
    else:
        return re.sub(r'\s+', ' ', obj)


def parse_children(children_str):
    if children_str is None:
        children_str = ''
    children_str = re.sub(r'\n',' ',children_str)
    children_str = re.sub(r'\(.+?\)','',children_str)
    children_list = children_str.split(";")
    child_re = re.compile(r'((\w+\.?\s?)+)((?:,\s?)((.+?,)\s?(\d{2,4})?))?')
    children = {}
    p = 1
    for child in children_list:
        child_match=child_re.search(child)
        if child_match:
            name = child_match.group(1)
            name = re.sub(r'([A-Z][a-z]+)([A-Z][a-z]+)',r'\g<1> \g<2>',name)
            dob = child_match.group(4)
            if dob is None:
                dob = ''
            if len(dob) > 0:
                dob = process_date(dob)
            children[p] = {
                'name':name,
                'dob': dob
                }
        else:
            children[p] = {
                'name':child,
                'dob': ''
                }
        p += 1
        
    return children


def parse_wedding(wedding_str):
    if wedding_str is None:
        wedding_str = ''
    wedding_re = re.compile(r'(\w+\.?\s?\d{1,2},?\s\d{2,4})([,:]\s?(.+))?')
    wedding_match = wedding_re.search(wedding_str)
    if wedding_match:
        date = process_date(wedding_match.group(1))
        place = wedding_match.group(3)
        
    else:
        date = wedding_str
        place = ''
    if place is None:
        place = ''          
    return date, place


def parse_profile(profile):
    """Extracts the data fields from the profile text for a single person.
    """
    name = profile[0]
    prof_text = profile[1]
    prof_data = {
        'name': name
    }
    address = address_re.search(prof_text)
    if address:
        prof_data['homeAddress'] = address.group(1)
    
    work_address = work_addr_re.search(prof_text)
    if work_address:
        prof_data['work_address'] = work_address.group(1)

    birth = birth_re.search(prof_text)
    if birth:
        prof_data['birthDate'] = process_date(birth.group(1))
        prof_data['birthPlace'] = birth.group(2)
        father_name = birth.group(3)
        if father_name is not None:
            if len(father_name) > 50: # Something went wrong
                prof_data['fatherName'] = ' '.join(re.split(r'\s', father_name)[:3])
            else:
                prof_data['fatherName'] = father_name
                father_year = birth.group(4)
                if father_year is not None:
                    prof_data['harvardFather'] = ('19' if int(father_year) < 60 else '18') + father_year
                prof_data['motherName'] = birth.group(5)

    married = married_re.search(prof_text)
    if married:
        prof_data['spouseName_old'] = married.group(1).strip()        
    
    # Extract Family info: Spouse, Wedding, Children
    # Remove (single) line breaks
    # prof_text_family = re.sub(r'(?<!\n)(\n)(?!\n)',' ',prof_text)
    family = family_re.search(prof_text)
    if family:
        spouse_full = re.sub(r' \. ','',family.group(1)).strip()
        divorced = 1*bool(re.search(r'divorc\w*',spouse_full,re.I))
        spouse_full = re.sub(r'(.*?)\(',r'\g<1>',spouse_full)
        try:
            spouse_last = spouse_full.split(" ")[-1]
            spouse_first = " ".join(spouse_full.split(" ")[:-1])
        except:
            spouse_last = ''
            spouse_first = ''
        prof_data['spouseName'] = spouse_full
        prof_data['spouseName_ocr'] = spouse_full
        prof_data['divorced'] = divorced
        # prof_data['spouseFirst'] = spouse_first
        # prof_data['spouseLast'] = spouse_last
        prof_data['weddingDate'], prof_data['weddingPlace'] = \
                parse_wedding(family.group(2))
        
        try:
            any_children = bool(children_re.search(family.group(3)))
        except TypeError:
            any_children = False
        if any_children:
            children = re.sub(r'(.*)(\n?(HARVARD|OCC|RECORD).*)?',r'\g<1>',
                family.group(4),flags=re.I|re.DOTALL)
            child_data = parse_children(children)
            for child in child_data:
                prof_data[f'childName{child}'] = child_data[child]['name']
                prof_data[f'childBirth{child}'] = child_data[child]['dob']
        prof_data['children_cat'] = family.group(3)
        prof_data['any_children'] = any_children

    
    graduated = graduated_re.search(prof_text)
    if graduated:
        prof_data['yrs_in_college'] = graduated.group(1)
        prof_data['degree'] = graduated.group(2)

    high_school = high_school_re.search(prof_text)
    if high_school:
        prof_data['high_school_name'] = high_school.group(1)
        prof_data['high_school_place'] = high_school.group(2)

    harvard_bros = harvard_bros_re.search(prof_text)
    if harvard_bros:
        prof_data['harvardBrothers'] = harvard_bros.group(1).strip()

    occupation = occupation_re.search(prof_text)
    if occupation:
        prof_data['occupation'] = occupation.group(1)

    offices_held = offices_re.search(prof_text)
    if offices_held:
        prof_data['officesHeld'] = offices_held.group(1)

    member = member_re.search(prof_text)
    if member:
        prof_data['member_of'] = member.group(1)

    publications = publications_re.search(prof_text)
    if publications:
        prof_data['publications'] = publications.group(1)

    prof_data = {k: remove_newlines(v) for k, v in prof_data.items()}

    return prof_data


def parse_doc(source, save_to=None):
    """Takes a source text file, splits into profiles, extracts data from each profile,
    and collects the data in a pandas DataFrame. Optionally then saves as a CSV with file name `save_to`.
    """
    text = load_doc(source)
    profiles = split_into_profiles(text)
    data = []
    for profile in tqdm(profiles):
        data.append(parse_profile(profile))
    df = pd.DataFrame(data)
    if save_to is not None:
        df.to_csv(save_to)
    return df


if __name__ == '__main__':
    if len(sys.argv) == 3:
        parse_doc(sys.argv[1], sys.argv[2])
    else:
        print('Syntax is "python parse_text.py source_file output_file"')
