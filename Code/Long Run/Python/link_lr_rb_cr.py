# -*- coding: utf-8 -*-


import sys
print(sys.path)
sys.path.insert(0, './red_book_class_report_linking')
print(sys.path)
import os
from link import match

# Make missing output directories
links = "../../../Intermediate Data/codes/"
cr_rb_links = "../../../Intermediate Data/codes/cr_rb_links/"

if not os.path.isdir(links):
      os.makedirs(links)
if not os.path.isdir(cr_rb_links):
      os.makedirs(cr_rb_links)

""" Link redbooks and PIDed class reports """

match(r'../../../Intermediate Data/Excel Files/updated_class_reports/longrun_series_class_reports.csv',
      r'../../../Intermediate Data/Excel Files/longrun_series_redbooks.csv',
      r'./red_book_class_report_linking/training_data_new.csv',
      r'../../../Intermediate Data/codes/cr_rb_links/longrun_series_rb_cr_links.csv'
      )
