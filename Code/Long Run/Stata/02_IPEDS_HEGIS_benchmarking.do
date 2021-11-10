/*

02_IPEDS_HEGIS_benchmarking.do
(called from master_longrun.do)

Purpose: clean and benchmark IPEDS/HEGIS data
Inputs: raw/IPEDS/highered_panel, 02a_clean_hegis.do, 02b_clean_ipeds.do,
	intstata/ipeds_full, intstata/hegis_full
Outputs: intstata/IPEDS_HEGIS_harvard_enrollment

*/

use "$raw/IPEDS_HEGIS/highered_panel", clear
keep if instnm == "HARVARD UNIVERSITY"

gen class_bin = year + 4
keep if class <= 1994

replace enrollfull_firsttime = . if enrollfull_firsttime < 150
replace enrollfullwomen_firsttime = . if mi(enrollfull_firsttime)
replace enrollfullmen_firsttime = . if mi(enrollfull_firsttime)

gen diff = abs(enrollfullwomen_firsttime + enrollfullmen_firsttime - enrollfull_firsttime)
assert diff == 0 if !mi(diff)

// First year enrollment is missing/oddly small for year 1986 onwards
* Calculate as the difference between last years total enrollment and this years

ren enrollfull* en_*
ren *__* *_*
ren en*firsttime en*first

gen male_ipeds = en_men_first / en_first

keep year class_bin male en*

save "$intstata/ipeds_enrollment", replace

//
//
// this code constructs enrollment records using HEGIS and IPEDS data 
// goal is to benchmark LR data series to public records where available
//
//

// clean IPEDS and HEGIS files
clear
do "02a_clean_hegis.do"
do "02b_clean_ipeds.do"

// append files
clear
append using "${intstata}/ipeds_full"
append using "${intstata}/hegis_full"

// keep only Harvard and Radcliffe: 
// note that formats vary-- split in some years, joint in others, in 1982 as "combined harvard-radcliffe"	
li instnm unitid year fice city OESTATE if strpos(instnm,"RADCLIFFE")>0
li instnm unitid year fice city OESTATE if strpos(instnm,"HARVARD")>0

keep if (fice==2155 | unitid==166027) | (unitid==167561 | fice==2156) | fice==29339
tab instnm

// in 1985 and 1980 we have *both* HEGIS *and* IPEDS
// keep IPEDS in these years
drop if data=="HEGIS" & (year==1980 | year==1985) 

// radcliffe appears to be included in harvard recs in 1986 and later, so drop dupilcated records
drop if  strpos(instnm,"RADCLIFFE")>0 & year>=1986

// collapse over harvard and radcliffe: 
collapse (sum) enrollfullmen_firsttime enrollfullwomen_firsttime ///
 enrollfullint_firsttime enrollfullblack_firsttime ///
 enrollfullai_firsttime enrollfullasian_firsttime enrollfullhisp_firsttime ///
 enrollfullwhite_firsttime enrollfull_firsttime ///
 , by(year)

// don't have data in 1969:
drop if year==1969

// race data are reported only in a set of years in the 1980s, so set to missing in non-reported years. 
// also set to missing in 08/09 as race codes change. 
foreach y of numlist  1968/1979 1981/1983 1985(2)1989 2008 2009 {
    foreach var in  enrollfullint_firsttime enrollfullblack_firsttime ///
 enrollfullai_firsttime enrollfullasian_firsttime enrollfullhisp_firsttime ///
 enrollfullwhite_firsttime {
     replace `var'=. if year==`y'
 }
}
	

gen share_male=enrollfullmen_firsttime/enrollfull_firsttime
gen share_asian=enrollfullasian_firsttime/enrollfull_firsttime
gen share_urm=(enrollfullhisp_firsttime+enrollfullblack_firsttime+enrollfullai_firsttime)/ enrollfull_firsttime
gen share_int=enrollfullint_firsttime/enrollfull_firsttime

/* some optional graphs to view
twoway (connect enrollfullmen_firsttime year) (connect enrollfullwomen_firsttime year)
twoway (connect enrollfullasian_firsttime year) (connect enrollfullblack_firsttime year)
twoway (connect share_asian year) (connect share_urm year)
*/

compress
save "${intstata}/IPEDS_HEGIS_harvard_enrollment", replace