*parse_text.py*
Uses regular expressions to parse a text version of a class report and create a CSV containing its information.

*parse_and_find.py*
Runs parse_text.py, then runs familysearch find code to suggest PIDs for the people in the class report.

*update_and_merge.py*
This code is meant to be run once you have hand-checked class report data with PIDs assigned to each entry. You can use this code to rerun parse_text.py and then merge that data with the hand-checked data you have.