import pandas as pd
import os
import sys

from activities import get_activities, get_codes_for_activities
from high_schools import get_rb_high_schools, get_codes_for_rb_high_schools
from occupations import get_occupations, get_classes_for_occupations
sys.path.insert(0, '.')
from clubs import get_clubs, get_codes_for_clubs

if os.path.isfile('../../../../Intermediate Data/Excel Files/longrun_series_redbooks.csv'):
    redbook_source = '../../../../Intermediate Data/Excel Files/longrun_series_redbooks.csv'
else:
    redbook_source = input('Type the file path to the red books source CSV: ')

if os.path.isfile('../../../../Intermediate Data/Excel Files/updated_class_reports/longrun_series_class_reports.csv'):
    class_report_source = '../../../../Intermediate Data/Excel Files/updated_class_reports/longrun_series_class_reports.csv'
else:
    class_report_source = input('Type the file path to the class reports source CSV: ')

# Make sure the output directory exists and create otherwise
OUT_DIR = "../../../../Intermediate Data/codes/long-run"
if not os.path.isdir(OUT_DIR):
    os.makedirs(OUT_DIR,exist_ok=True)



# High Schools
print("\nCategorizing high schools now...")
rb_high_schools = get_rb_high_schools(redbook_source)
codes = get_codes_for_rb_high_schools(rb_high_schools,key_type='longrun')
codes.to_csv(os.path.join(OUT_DIR,'high_school_codes.csv'))



## Occupations
print("\nCategorizing occupations now...")
occupations = get_occupations(class_report_source)
classes = get_classes_for_occupations(occupations,key_type='longrun')
classes.to_csv(os.path.join(OUT_DIR,'occupation_codes_tokenize.csv'))

classes = get_classes_for_occupations(occupations,key_type='longrun',method='regex')
classes.to_csv(os.path.join(OUT_DIR,'occupation_codes.csv'))


## Adult Clubs and Associations
# print("\nCategorizing adult clubs and associations now...")
# clubs = get_clubs(class_report_source)
# codes = get_codes_for_clubs(clubs)
# codes.to_csv(os.path.join(OUT_DIR,'club_codes.csv'))
