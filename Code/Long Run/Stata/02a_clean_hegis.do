/*

02a_clean_hegis.do
(called from 02_IPEDS_HEGIS_benchmarking.do)

Purpose: clean HEGIS data
Inputs: code/hegis/clean`year'.do, intstata/hegis`year'
Outputs: intstata/hegis_full

*/

// set up // 
set more off

global hegis_code "$code/hegis"
global hegis_raw_data "$raw/IPEDS_HEGIS/hegis"
global hegis_in_data "$intstata"

* hand-clean each year (fix many coding inconsistencies across surveys)
do "$hegis_code/clean1968.do"
do "$hegis_code/clean1969.do" // loops thru 1970
do "$hegis_code/clean1971.do" // loops thru 1972
do "$hegis_code/clean1973.do"
do "$hegis_code/clean1974.do"
do "$hegis_code/clean1975.do"
do "$hegis_code/clean1976.do"
do "$hegis_code/clean1978.do" // loops thru 1980
do "$hegis_code/clean1981.do"
do "$hegis_code/clean1982.do"
do "$hegis_code/clean1983.do"
do "$hegis_code/clean1985.do" // 84 missing from hegis records

* glue together
clear

forv year = 1968/1983 {
	append using "$hegis_in_data/hegis`year'.dta" , force
}
append using "$hegis_in_data/hegis1985.dta" , force

* sanity checks
//reg enrollfull_total enrollfullwomen_total enrollfullmen_total

/* (optional graph)
sort yeay 
graph twoway (connected enrollfull_total year if FICE==2155 /* harvard*/ ) ///
			(connected enrollfull_total year if FICE== 2178 /* MIT */ ) ///
			/*(connected enrollfull_total year if FICE== 2130 /* BU */ )*/ /// 
			(connected enrollfull_total year if FICE ==  1305 /* stanford */ ) ///
			(connected enrollfull_total year if FICE ==  2219 /* tufts */ ) ///
			(connected enrollfull_total year if FICE == 2707 /* columbia */ ) 
			/* 1978 harvard record decides not to list women -- thats why it looks weird. 
			seem to all be at radcliffe -- radcliffe listed separately in '78*/
*/

* clean
gen instnm = INSTNAME 
replace instnm = INST_NAME if mi(instnm)			
replace instnm = NAME85 if mi(instnm)

* code ivies etc

gen data = "HEGIS"

ren institution_sex sex
cap label define SEXCODE   1 "Male" 2 "Female" 3 "Coeducational" 4 "Coordinate" ;
label values sex SEXCODE

ren FICE fice

isid fice year
sort fice year
compress
save "${intstata}/hegis_full.dta" , replace