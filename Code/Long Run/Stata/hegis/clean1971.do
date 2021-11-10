// 1970-1971 //

// set up // 
set more off

global icpst_dict "$hegis_raw_data/02059-0001-Setup.dct"

// loop //
local series = 2058

forv year = 1971/1972 {
local series = `series'+1

* ingest data
local dir = "$hegis_raw_data/ICPSR_0`series'/DS0001"
local data = "`dir'" + "/" + "0`series'-0001-Data.txt"
di "`data'"

qui infile using "$icpst_dict" , ///
	using ( "`data'" ) clear

label data "Higher Education General Information Survey (HEGIS), `year': Fall Enrollment"

* label vars
destring INSTITUTE, replace

#delimit ;
cap label define RACE      1 "WHITE" 2 "BLACK" ;
cap label define CONTROL   0 "COMBINATION PUBLIC AND PRIVATE" 1 "PUBLIC ONLY"
                       2 "PRIVATE ONLY" ;
cap label define INSTITUTE 1 "University" 2 "Other four-year" 3 "Two year";
cap label define SEX       1 "MALE" 2 "FEMALE" 3 "COEDUCATIONAL" 4 "COORDINATE" ;
cap label define RESTRICT  0 "NOT RESTRICTED" 1 "RESTRICTED" ;
cap label define IMPUTATION 0 "UNIMPUTED" 1 "ENTIRE INSTITUTION IMPUTED" ;
#delimit cr

foreach var in RACE CONTROL INSTITUTE SEX RESTRICT IMPUTATION {
label var `var' `var'
}

* clean data
bys FICE LINENO (COMPUTID) : keep if _n == _N // keep updated records
drop ENTRY UPDATE COMPUTID

isid FICE LINENO

drop PARTID

gen year = `year'

* clean var names
gen four_year = INSTITUTE == 1 | INSTITUTE == 2 if !mi(INSTITUTE)
drop INSTITUTE

ren SEX institution_sex

ren SURVEYA1 enrollfullmen
ren SURVEYA2 enrollpartmen
ren SURVEYA3 enrollfullwomen
ren SURVEYA4 enrollpartwomen
ren SURVEYA5 enroll_rowtotal
drop enroll_rowtotal
drop SURVEY_GEN*
drop SURVEYA6

gen enrollfull = enrollfullmen + enrollfullwomen
gen enrollpart = enrollpartmen + enrollpartwomen

table ENR_RANGE , c(min ENR_TOTAL max ENR_TOTAL) // size var


// enrollment definition //
/*

Line No - 

1 - lower division, frosh and soph
2 - upper division
3 - 1+2
4 - professional students
5 - graduate
6 - unclassified
7 - 3+4+5+6
8 - extension undergrads
9 - extension graduate/first prof level
10 - unclassified ext. 
11 - 8+9+10
12 - 7 + 11
13 - first time degree credit students excl. transfers
14 - nondegree resident
15 - nondegree extension
16 - 14+15
17 - first time nondegree excl. transfers
18 - grand total

*/

* want total undergrad
keep if LINENO==3 | LINENO==13

gen j = "_total" if LINENO==3
replace j = "_firsttime" if LINENO==13
drop LINENO

reshape wide enrollfull* enrollpart* , i(FICE) j(j) string

qui compress
save "$hegis_in_data/hegis`year'.dta" , replace
}
