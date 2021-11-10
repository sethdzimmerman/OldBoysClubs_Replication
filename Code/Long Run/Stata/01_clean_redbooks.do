/*

01_clean_redbooks.do
(called from master_longrun.do)

Purpose: master file for cleaning Red Books
Inputs: intexcel/longrun_series_redbooks.csv,
	01a_clean_schools.do, codes/cr_rb_links/longrun_series_rb_cr_links,
	intexcel/updated_class_reports/longrun_series_class_reports,
	keys/lr_occupation_key, codes/long-run/occupation_codes,
	01b_race_codes.do, 0ce_race_codes_census.do, 01d_clean_adclub.do, 
	raw/Class_Reports/hand_fixes/spouse-names-suppcodes.csv, 01e_label_order.do
Outputs: intstata/lr_series_redbooks_raw, cleaned/lr_series_redbooks_clean

*/

/////////////////////////////////////////
// make dta version of redbooks_master //
/////////////////////////////////////////

* open up python cleaning product
insheet using "$intexcel/longrun_series_redbooks.csv" , clear		

drop gender_confidence language* remark* unnamed_8 service_record next_address engineering age unnamed* fall activities_line activites_line_2 activities_*

label var index "ID (from Red Books)"
label var year "Class year"
label var photo "Red Books photo"
label var page "Red Books page"
label var name "Full name"
label var college_address "College residential address"
label var home_address "Home address"
label var high_school "Raw high school"
label var activities "Activities list"
label var gender "Gender (string)"
label var first "First name"
label var middle "Middle name"
label var last "Last name"
label var college_adress "College residential address"
label var intended_major "Intended major (from Red Books)"

order index  name  first middle last gender year photo  page home_address high_school college_address  college_adress 

* write to dta
compress
save "$intstata/lr_series_redbooks_raw" , replace

/////////////////
// quick fixes //
/////////////////

use "$intstata/lr_series_redbooks_raw" , clear

** destrings **
* year and class
ren year class
gen year = class-4

* Gender
gen male = gender == "M"
// set male variable to one in classes before 1975 (before co-education)
replace male = 1 if class <= 1974
// set male to missing when gender is missing and class is at least 1975
replace male = . if gender == "" & class > 1974

* clean name
replace name = subinstr(name," , ",", ",.)

* dups? 
duplicates tag name class, gen(dup)
//list if dup>0 // most of these are from a record being cut out, the hole making 2 records duplicated
bys name class (photo): keep if _n == 1
drop dup
duplicates tag name class, gen(dup)
assert dup == 0 
drop dup

///////////////////////
// clean dorm coding //
///////////////////////

* fix "college address"
replace college_address = college_adress if !mi(college_adress) & mi(college_address)
drop college_adress

* clean dorm var for merge to rooms data; typos in street address:   
replace college_address = subinstr(college_address,"Grays7-8","Grays 7-8",.)
replace college_address = subinstr(college_address,"Gray, D-31","Grays D-31",.)
replace college_address = subinstr(college_address,"Gravs","Grays",.) 
replace college_address = subinstr(college_address,"Gray, 29.30","Grays 29-30",.) 

replace college_address = subinstr(college_address,"Gere","Gore",.)
replace college_address = subinstr(college_address,"Gorc","Gore",.)

replace college_address = subinstr(college_address,"Dravton","Drayton",.)

replace college_address = subinstr(college_address,"Holsworthy","Holworthy",.)

replace college_address = subinstr(college_address,"Masschusetts","Massachusetts",.)

replace college_address = subinstr(college_address,"McKilock","McKinlock",.)
replace college_address = subinstr(college_address,"McKinloc ","McKinlock ",.)
replace college_address = subinstr(college_address,"Mc.Kinlock ","McKinlock ",.)

replace college_address = subinstr(college_address,"Shapherd","Shepherd",.)
replace college_address = subinstr(college_address,"Shepard","Shepherd",.)
replace college_address = subinstr(college_address,"Shepards","Shepherd",.)
replace college_address = subinstr(college_address,"Shepherd21","Shepherd 21",.)

replace college_address = subinstr(college_address,"Sotoughton","Stoughton",.)

replace college_address = subinstr(college_address,"Staandish","Standish",.)
replace college_address = subinstr(college_address,"Stamdish","Standish",.)
replace college_address = subinstr(college_address,"Standisli","Standish",.)
replace college_address = subinstr(college_address,"Satandish","Standish",.)

replace college_address = subinstr(college_address,"Struas","Straus",.)
replace college_address = subinstr(college_address,"Steaus","Straus",.)
replace college_address = subinstr(college_address,"Stratus","Straus",.)

replace college_address = subinstr(college_address,"Tharyer","Thayer",.)
replace college_address = subinstr(college_address,"Thaver","Thayer",.)

replace college_address = subinstr(college_address,"Linnel","Lionel",.)

replace college_address = subinstr(college_address,"Mathews","Matthews",.)
replace college_address = subinstr(college_address,"Matthwes","Matthews",.)

replace college_address = subinstr(college_address,"Weld4","Weld 4",.)

replace college_address = subinstr(college_address,"Wiggleworth","Wigglesworth",.)

replace college_address=subinstr(proper(college_address), "Goerge Smith","George Smith",.) 

replace college_address=subinstr(proper(college_address), "Jams Smith","James Smith",.) 
replace college_address=subinstr(proper(college_address), "Janies Smith","James Smith",.) 
* by looking at room capacity determined that these two generic "Smith" dorm rooms must be "James Smith"
replace college_address="James Smith A 22" if  college_address=="Smith A 22"
replace college_address="James Smith A 42" if  college_address=="Smith A 42"

replace college_address=subinstr(proper(college_address),"Pesis Smith","Persis Smith", .) 
replace college_address=subinstr(proper(college_address),"Presis Smith","Persis Smith", .) 
replace college_address=subinstr(proper(college_address),"Persia Smith","Persis Smith", .) 
replace college_address=subinstr(proper(college_address),"Peris Smith","Persis Smith", .) 
replace college_address=subinstr(proper(college_address),"Parsis Smith","Persis Smith", .) 

replace college_address=subinstr(proper(college_address), "Cragie","Craigie",.) 

replace college_address=subinstr(proper(college_address), "Russel 3","Russell 3",.) 

////////////////////////
// clean high schools //
////////////////////////

do 01a_clean_schools.do

////////////////////////////
// merge on class reports //
////////////////////////////

// get class ids (pids) //

* open up cb/rb merge file
preserve
	insheet using "$codes/cr_rb_links/longrun_series_rb_cr_links.csv" , clear
	
	* some individuals matched to multiple CB entries
	duplicates report index

	* keep duplicates w/ highest confidence
	bys index (confidence) : keep if _n == _N

	tempfile x 
	save `x' , replace
restore

merge 1:1 index using `x' , nogen keep(1 3)

label var pid "ID (from Class Reports)"
drop confidence

gen has_pid = !mi(pid)

/////////////////////////////////////////
/// Additional sample identifiers
/////////////////////////////////////////

* Flag which years have corresponding Class report files
gen cr_year = class < 1939 | ///
	class == 1940 | class == 1945 | class == 1950 | class == 1955 | class == 1960 | ///
	class == 1965 | class == 1970 | class == 1975 | class == 1980 | class == 1985 | ///
	class == 1990

* Bin classes for 5 years, such that 1980-1984 have class_bin=1980 and 1985-1989 class_bin=1985
gen class_bin = round(class -2.4 ,5)

////////////////////////
// code occupation 
///////////////////////
*identify individuals with non-missing occupation reports
preserve
	insheet using "${intexcel}/updated_class_reports/longrun_series_class_reports.csv", clear 

	keep if !mi(occupation)
	keep pid
	drop if mi(pid)
	tempfile ts
	save `ts'
restore

merge m:1 pid using `ts', keep(match master) gen(_mho)
gen byte have_occ=_mho==3
drop _mho

preserve
	* keys
	import exc using "$keys/lr_occupation_key", clear firstrow 
	bys categorycode (subcategorycode): replace category = category[1]
	
	isid categorycode subcategorycode
	keep categorycode subcategorycode category subcategory
	
	tempfile oc_key
	save `oc_key'
	
	* pid x occ data
	insheet using "$codes/long-run/occupation_codes.csv", names comma clear
	
	merge m:1 categorycode subcategorycode  using `oc_key', nogen keep(match master) 

	duplicates drop

	sort pid categorycode subcategorycode
	bys pid: gen actn=_n // occupation number
	
	reshape wide categorycode subcategorycode ///
		category subcategory, i(pid) j(actn) 
	
	compress
	drop if mi(pid) 
	tempfile oc_match
	save `oc_match'
restore

* merge on occupation codes
merge m:1 pid using `oc_match' , gen(_mocc) keep(match master) 
tab class _mocc if has_pid==1, r
drop _mocc

* coarse occupation classifiers: 
// gen byte have_occ=!mi(categorycode1)

foreach var in finance finance_ext doctor law bus manage_high manage_low hed teach gov ///
	art_pub engineer sci bookkeep tech consulting consulting_ext {
	gen `var'=0 if have_occ==1
}

forv j=1/9 {
	replace finance=1 if categorycode`j'==1 & subcategorycode`j'<=2 & have_occ`version'==1
	replace finance_ext=1 if categorycode`j'==1 & ///
		(subcategorycode`j'<=2 | subcategorycode`j' == 11) & have_occ`version'==1 // incl. firm names
	replace doctor=1 if categorycode`j'==4 & have_occ`version'==1
	replace law=1 if categorycode`j'==2 & have_occ`version'==1
	replace bus=1 if categorycode`j'==3 & (subcategorycode`j'<=6) & have_occ`version'==1 // this excludes sales, advertising, hr, secretarial, consulting strings
	replace consulting = 1 if categorycode`j' == 3 & subcategorycode`j'==6 & have_occ`version'==1
	replace consulting_ext = 1 if categorycode`j' == 3 & /// 
		(subcategorycode`j'==6 | subcategorycode`j' == 61) & have_occ`version'==1 // incl. firm names
	replace manage_high=1 if categorycode`j'==0 & subcategorycode`j'==1 & have_occ`version'==1
	replace manage_low=1 if categorycode`j'==0 & subcategorycode`j'==2 & have_occ`version'==1
	replace hed=1 if categorycode`j'==6 & ///
		(subcategorycode`j'==1 | subcategorycode`j'==9) & have_occ`version'==1
	replace teach=1 if categorycode`j'==7 & have_occ`version'==1
	replace gov=1 if categorycode`j'==10 & have_occ`version'==1
	replace art_pub=1 if categorycode`j'==13 | categorycode`j'==8 & have_occ`version'==1 
	replace engineer=1 if categorycode`j'==5 & have_occ`version'==1
	replace sci=1 if categorycode`j'==6 & (subcategorycode`j'>=2 & subcategorycode`j'<=8) & have_occ`version'==1
	replace bookkeep=1 if categorycode`j'==1  & (subcategorycode`j'>=3 & subcategorycode`j'<=6) & have_occ`version'==1
	replace tech = 1 if categorycode`j'==19 | ///
		categorycode`j' == 5 & have_occ`version'==1
}

//  slightly aggregated occupation codes for condensed reporting: 

// this aggregates the accounting, management, and retail categories from older versions of 
// main peer effects LR results tab
gen bus_agg=(bookkeep==1 | manage_high==1 | manage_low==1 |bus==1) if have_occ==1 

///////////
// supplementary occupation codes
//////////

preserve
	insheet using "${intexcel}/updated_class_reports/longrun_series_class_reports.csv", clear 
	keep pid occupation publications

	global schol_art_list `"science scientific journal patent review quarterly technical statistics psychology research medicine  surgery psychology psychiatry neurology physic chemistry biology mathematics economic sociology history anthropology classics latin greek manuscript monograph literature poetry architecture textbook engineer"'	

	gen pub_or_patent=0
	foreach  s in $schol_art_list {
		replace pub_or_patent=1 if strpos(lower(publications),lower("`s'"))>0
		
	}
	drop if mi(pid)
	tempfile ts
	save `ts'

restore

merge m:1 pid using `ts', keep(match master) nogen

// Consider occupations at a LLP as lawyers if they are not classified as finance, consultants or doctors
gen law_ext = law==1 | ( finance == 0 & consulting == 0 & doctor == 0 & ///
	regexm(lower(occupation)," llp") )
	
/////////////////////////////////////////
// Degrees and honors //
/////////////////////////////////////////

preserve
	insheet using "${intexcel}/updated_class_reports/longrun_series_class_reports.csv", clear 
	
	keep pid *degree* *grad honors
	
	tempfile degrees
	save `degrees', replace
restore

merge m:1 pid using `degrees', keep(match master) nogen

gen have_degree = !mi(degree_str) if cr_year == 1
gen have_honors = !mi(honors) if have_degree == 1

gen summa_cum = regexm(lower(honors),"^sum") if have_degree == 1
gen magna_cum = regexm(lower(honors),"^ma") if have_degree == 1
gen magna_summa = magna_cum == 1 | summa_cum == 1 if have_degree == 1
gen other_laude = have_honors == 1 & magna_summa == 0 if have_degree == 1

replace any_prof_grad = 0 if mi(any_prof_grad) & have_degree == 1
replace any_other_grad = 0 if mi(any_prof_grad) & have_degree == 1
drop n_grad

gen phd_grad = strpos(upper(grad_degrees),"PHD") > 0 if have_degree == 1
gen md_grad = strpos(upper(grad_degrees),"MD") > 0 if have_degree == 1
gen jd_grad = regexm(upper(grad_degrees),"(JD|LLB)") if have_degree == 1
gen mba_grad = strpos(upper(grad_degrees),"MBA") > 0 if have_degree == 1

/////////////////////////////////////////
// Clubs, race, leadership
/////////////////////////////////////////

// race codes //

// BYU hand-codes
do 01b_race_codes.do

// name indices from 2010 census
do 01c_race_codes_census.do 

// AD club membership info
do 01d_clean_adclub.do 

//////////////////////////////////////////////////////
// Wedding and Children info
//////////////////////////////////////////////////////
preserve
	insheet using "$intexcel/updated_class_reports/longrun_series_class_reports.csv",  clear

	keep pid spousename
 	gen married  = !mi(spousename)
	
	label var married "Have spouse"
	label var spousename "Spouse"
	tempfile wedding
	save `wedding'
	
restore
merge m:1 pid using `wedding', nogen keep(1 3)

preserve
	insheet using "$raw/Class_Reports/hand_fixes/spouse-names-suppcodes.csv", clear
	tempfile suppcodes
	save `suppcodes'
restore

merge 1:1 index using `suppcodes', keep(1 3)
replace married = 0 if strunm == 1
replace spousename = spouse_altcode if _merge == 3
drop _merge strunm spouse_altcode

////////////////////
// variable labels
///////////////////

// label and order everything
do 01e_label_order.do

gen all=1
label var all "In Red Books data"

forv i = 1/9 {
	rename category`i' occCategory`i'
	rename categorycode`i' occCategorycode`i'
	rename subcategory`i' occSubcategory`i'
	rename subcategorycode`i' occSubcategorycode`i'
}
compress

// drop unused variables
drop home_address high_school activities intended_major degree_str occupation publications 

save "$cleaned/lr_series_redbooks_clean", replace