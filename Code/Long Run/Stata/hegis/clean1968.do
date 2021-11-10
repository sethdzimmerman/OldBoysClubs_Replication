// 1968 //

* ingest 1968 data
global icpst_dict "$hegis_raw_data/02056-0001-Setup.dct"

local dir = "$hegis_raw_data/ICPSR_02056/DS0001"
local data = "`dir'" + "/" + "02056-0001-Data.txt"
di "`data'"

qui infile using "$icpst_dict" , ///
	using ( "`data'" ) clear

label data "Higher Education General Information Survey (HEGIS), 1968: Fall Enrollment"

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
isid FICE LINENO

drop PARTID

gen year = 1968

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

gen enrollfull = enrollfullmen + enrollfullwomen
gen enrollpart = enrollpartmen + enrollpartwomen

table ENR_RANGE , c(min ENR_TOTAL max ENR_TOTAL) // size var


// enrollment definition //
/*

Line No - 

1 - Undergrad enroll 
2 - post bacc
3 - 1+2
4 "first-time students who are taking work normally creditable toward a bachelor's degree"
5 - undergrad occupational programs NOT towards BA
6 - First-time students in NOT BA occ. progs

*/
* want total undergrad
keep if LINENO==1 | LINENO==4

gen j = "_total" if LINENO==1
replace j = "_firsttime" if LINENO==4
drop LINENO

reshape wide enrollfull* enrollpart* , i(FICE) j(j) string

qui compress
save "$hegis_in_data/hegis1968.dta" , replace
