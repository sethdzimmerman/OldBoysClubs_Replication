/*

01_clean_census.do
(called from master_census.do)

Purpose: clean Census data
Inputs: 01a_extract_harvard_census.do, 01b_clean_census_extract_1940.do, 
	01c_clean_census_extract_preHarvard.do, 01d_get_name_indices.do
Outputs: N/A
	
*/

* Takes the hand-made pid -> histid cross walk and produces the following:
*	1. "$intstata/extract_`year'.dta": full census records for each student for each census year 1900-1940
* 	2.  "$intstata/hh_extract_`year'.dta"
do 01a_extract_harvard_census.do

* Constructs post-Harvard (1940) census records for:
* 	1. all men 27-37 and our Harvard sample: "$intstata/all_indv_1940_desc.dta" 
* 	2. Harvard sample only: "$intstata/harvard_indv_and_all_dist_1940_desc.dta" 
do 01b_clean_census_extract_1940.do

* Constructs info about the households of our sample in 1900-1930 
*	the program produces a data set with variables about the household and father
* the relevent output file is: "$intstata/harvard_only_indv_preH_desc.dta" 
do 01c_clean_census_extract_preHarvard.do

*construct name indices for race/ethnic classification
	*key input is lr_series_redbooks_clean.dta
do 01d_get_name_indices.do