/*

01a_extract_harvard_census.do
(called from 01_clean_census.do)

Purpose: extract census records for Harvard students
Inputs: intstata/harvard_full_v4_histid_all, CENSUS_PATH1/dta/`year'
Outputs: intstata/histids_`year', intstata/extract_`year', intstata/hh_only_extract_`year',
	intstata/hh_extract_`year'
	
*/

foreach year in 1900 1910 1920 1930 1940 { 
   use "$intstata/harvard_full_v4_histid_all.dta", clear
   keep histid`year'
   keep if !mi(histid`year')
   sort histid`year'
   save "$intstata/histids_`year'.dta", replace

   use "$CENSUS_PATH1/dta/`year'.dta", clear
   foreach var of varlist _all {
      rename `var' `var'`year'_nber
   }
   
	
   drop if mi(histid`year'_nber)
   rename histid`year'_nber histid`year'
   sort histid`year'

   merge 1:1 histid`year' using "$intstata/histids_`year'.dta", keep(2 3)  gen(_merge`year')
   save "$intstata/extract_`year'.dta", replace
 }
 
*** extract the full household records for Harvard students

foreach year in 1900 1910 1920 1930 1940 { 
   use "$intstata/extract_`year'.dta", clear
   keep serial`year'_nber histid`year' pernum`year'_nber
   rename serial`year'_nber serial 
   rename histid`year' hs_histid`year' 
   rename pernum`year'_nber hs_pernum`year'_nber 
   sort serial
   tempfile students
   save `students'

   * select one obs per household id to pull records, (will merge back into multiple brothers later)
   keep serial
   duplicates drop 

   // run on half the households at a time to try to deal with I/O errors
   keep if serial<=11100000
   tempfile students1
   save `students1'
   use "$CENSUS_PATH1/dta/`year'.dta" , clear
   keep if serial<=11100000
   merge m:1 serial using `students1', keep(2 3) gen(_hh`year')

   tempfile hh1
   save `hh1'

   use `students', clear
   keep serial
   duplicates drop 
   keep if serial>11100000
   tempfile students2
   save `students2'
   use "$CENSUS_PATH1/dta/`year'.dta" , clear
   keep if serial>11100000
   merge m:1 serial using `students2', keep(2 3) gen(_hh`year')

   append using `hh1'

   save "$intstata/hh_only_extract_`year'.dta", replace

   joinby serial using `students', _merge(_hh_hs`year')

   save "$intstata/hh_extract_`year'.dta", replace
}