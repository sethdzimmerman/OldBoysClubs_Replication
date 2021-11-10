import sys
sys.path.insert(0, './red_book_class_report_linking')
import os
from link import match

# Make missing output directories
links = "../../../Intermediate Data/codes/"
cr_rb_links = "../../../Intermediate Data/codes/cr_rb_links/"
if not os.path.isdir(links):
      os.mkdir(links)
if not os.path.isdir(cr_rb_links):
      os.mkdir(cr_rb_links)


""" Link redbooks and PIDed class reports """
match(r'../../../Intermediate Data/Excel Files/updated_class_reports/all_years.csv',
      r'../../../Intermediate Data/Excel Files/redbooks_master.csv',
      r'./red_book_class_report_linking/training_data_new.csv',
      r'../../../Intermediate Data/codes/cr_rb_links/all_years.csv'      )
