/*

04_clean_redbooks.do
(called from master_main.do)

Purpose: master file for cleaning Red Books
Inputs: intexcel/redbooks_master, 04a_clean_home_address.do,
	04b_redbooks_errata.do, 04c_clean_schools.do, codes/cr_rb_links/all_years,
	intexcel/updated_class_reports/all_years, keys/occupation_key,
	codes/occupation_codes, codes/senior_class_registers, 
	keys/occupation_intended_key, codes/intended_occupation_codes, keys/college_major_key,
	codes/college_major_codes.csv, 04d_clean_clubs.do, 04e_clean_activities.do,
	04f_clean_leadership.do, intstata/class_rank_pid, intstata/class_rank_index,
	intstata/clubs_frats, codes/harvard_brothers, codes/have_harvard_family,
	raw/Other/unemployment/lebergott_unemp_1900_1928,
	raw/Other/unemployment/SeriesReport-20210506170053_85238a,
	raw/Class_Reports/hand_fixes/spouse-names-suppcodes.csv, 04g_label_order.do
Outputs: intstata/redbooks_raw, intstata/brother_pairs, intstata/harvard_family, 
	intstata/redbooks_clean_norooms, cleaned/redbooks_clean

*/

/////////////////////////////////////////
// make dta version of redbooks_master //
/////////////////////////////////////////

* Set seed
clear
graph drop _all
set seed 33921558
set sortseed 20910

* open up team BYU data product
insheet using "$intexcel/redbooks_master.csv" , clear

drop gender_confidence remarks unnamed_8 service_record next_address engineering age 

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

order index  name  first middle last gender year photo  page home_address high_school college_address  college_adress activities
				
* write to dta
compress
save "$intstata/redbooks_raw" , replace

/////////////////
// quick fixes //
/////////////////

use "$intstata/redbooks_raw" , clear

* year and class
ren year class
gen year = class-4
label var year "Freshman year"

* clean name
replace name = subinstr(name," , ",", ",.)

* dups? 
duplicates tag name class, gen(dup)
//list if dup>0 // most of these are from a record being cut out, the hole making 2 records duplicated
bys name class (photo): keep if _n == 1
drop dup

///////////////////////
// clean dorm coding //
///////////////////////

* fix "college_adress"
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

* freshmen dorms: 

* upperclassmen "apley" "claverly"  "russell"

 * westmorly, weld (weid), thayer, randolph, matthews, little, grays, dunster
 *  walter hastings, russell, perkins, holyoke, claverly, beck, apley, dana chambers
 *    ridgely annex,
 
 * 6 Holyoke Place, 52 Mt, Auburn St,  9 Bow St., 59 Plympton St., 5 Linden St
 
 * Lowell House, Apthrop House, 
 
* create dorm var
cap drop dorm
gen dorm = ""
foreach dd in  "standish" "gore" "persis smith" "james smith" "george smith" /// 
				"drayton" "mckinlock" "shepherd" "little" "dunster" "reed" ///
				"randolph" "westmorly" "dudley" "ridgely" "massachusetts" "wigglesworth" ///
				"stoughton" "straus" "weld" "thayer" "grays" "mower" "holworthy" "matthews" ///
				"hollis" "lionel" "harvard union" "40 quincy" "beck" ///
				"apley" "hastings" "russell" "perkins" "claverly" "dana" "chambers" ///
				"holyoke house" "wadsworth house" "apthrop" "conant" "divinity" "gannett" ///
				"lowell house" "shaler" "fairfax" "hampden"  "craigie" ///
				"senior house" "andover hall" "hamilton" "morris" {
	replace dorm = "`dd'" if strpos(trim(lower(college_address)),"`dd'")>0
}

 * remove from list of dorms
replace dorm = "" if strpos(trim(lower(college_address)),"st.")>0
replace dorm = "" if strpos(trim(lower(college_address)),"street")>0
replace dorm = "" if strpos(trim(lower(college_address)),"ave")>0  & dorm!="claverly"
replace dorm = "" if strpos(trim(lower(college_address)),"mass.")>0 
replace dorm = "" if strpos(trim(lower(college_address)),"sq.")>0
replace dorm = "" if strpos(trim(lower(college_address)),"circle")>0
replace dorm = "" if strpos(trim(lower(college_address)),"terrace")>0
replace dorm = "" if strpos(trim(lower(college_address)),"institute")>0
* add to list of dorms: Holyoke 45, Andover 3, 
replace dorm="holyoke" if college_address=="Holyoke 45"
replace dorm="andover" if college_address=="Andover 3"
 
foreach dd in "29 holyoke" "31 holyoke" "33 holyoke st" ///
			"6 holyoke" "52 mt. auburn st"  "9 bow st" "59 plympton st" "5 linden st" ///
			"34 dunster st" "54 dunster st" "5 linden st" "36 mt. auburn" "22 plympton st" /// 
			"27 holyoke st" "68 mt. auburn st" "60 mt. auburn st" "28 plympton st" {
	replace dorm = "`dd'" if strpos(trim(lower(college_address)),"`dd'")>0
} 
			
replace dorm = "" if strpos(trim(lower(college_address)),"home address")>0
replace dorm="McKinlock" if dorm=="Mckinlock"

gen havedorm = !mi(dorm) if !mi(college_address)
tab year, su(havedorm)

replace dorm = "off campus" if mi(dorm) & !mi(college_address)

tab dorm , sort

replace dorm = proper(dorm)

* clean room var for merge to rooms data: 
cap drop roomno
gen roomno = ""
replace roomno = subinstr(proper(college_address),dorm,"",.) if dorm!="Off Campus"
replace roomno = subinstr(roomno,"Hall","",.) if dorm!="Off Campus"
replace roomno = subinstr(roomno,".","",.) if dorm!="Off Campus"
replace roomno = subinstr(roomno,",","",.) if dorm!="Off Campus"
replace roomno = subinstr(roomno,"-"," ",.) if dorm!="Off Campus"
replace roomno = proper(trim(itrim(roomno)))

replace dorm="McKinlock" if dorm=="Mckinlock"

////////////////////////
// clean home address //
////////////////////////

replace home_address = proper(home_address)

do 04a_clean_home_address.do

//////////////////////////////
// merge on room price data //
//////////////////////////////

replace roomno = trim(roomno)

* fix typos
do 04b_redbooks_errata.do // cleans room typos in redbooks

* observed room cap
bys dorm roomno year : gen observed_roomcap = _N
replace observed_roomcap = 0 if dorm!="Grays"
replace observed_roomcap = 2 if observed_roomcap==1

////////////////////////
// clean high schools //
////////////////////////

do 04c_clean_schools.do

////////////////////////////
// merge on class reports //
////////////////////////////

// get class ids (pids) //

* open up cb/rb merge file
preserve
	insheet using "$codes/cr_rb_links/all_years.csv" , clear
	
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

////////////////////////
// code occupation 
///////////////////////
*identify individuals with non-missing occupation reports
preserve
	insheet using "${intexcel}/updated_class_reports/all_years.csv", clear 

	keep if !mi(occupation)
	keep pid
	drop if mi(pid)
	tempfile ts
	save `ts'
restore

merge m:1 pid using `ts', keep(match master) gen(_mho)
gen byte have_occ=_mho==3

drop _mho
label var have_occ "Has occupation"

preserve
	* keys
	import exc using "$keys/occupation_key", clear firstrow 
	bys categorycode (subcategorycode): replace category = category[1]
	
	isid categorycode subcategorycode
	keep categorycode subcategorycode category subcategory
	
	tempfile oc_key
	save `oc_key'
	
	* pid x occ data
	insheet using "$codes/occupation_codes.csv", names comma clear
	
	merge m:1 categorycode subcategorycode  using `oc_key', nogen keep(match master) 

	duplicates drop

	sort pid categorycode subcategorycode
	bys pid: gen actn=_n // occupation number
	
	reshape wide categorycode subcategorycode category subcategory, i(pid) j(actn) 
	
	compress
	drop if mi(pid) 
	tempfile oc_match
	save `oc_match'
restore

* merge on occupation codes
merge m:1 pid using `oc_match' , gen(_mocc) keep(match master) 
tab class _mocc if has_pid==1, r

drop _mocc

/////////////////////////////
// code intended occupation 
/////////////////////////////
*identify individuals with non-missing occupation reports
preserve
	insheet using "$codes/senior_class_registers.csv", clear 
	keep rb_index occupation
	ren rb_index index
	ren occupation occupation_intended
	keep if !mi(index) 
	isid index
	tempfile ts
	save `ts'
restore

merge 1:1 index using `ts', keep(match master) gen(_mho2)
gen byte has_senior_info=_mho2==3
gen byte have_occ_intended = !mi(occupation_intended)
bys year: egen occ_intended_year = count(occupation_intended)
replace occ_intended_year = occ_intended_year > 50

drop _mho2
label var has_senior_info "Has data from senior class registers"
label var have_occ_intended "Has intended occupation"
label var occ_intended_year "Intended occupation count greater than 50 in year"

preserve
	* keys
	import exc using "$keys/occupation_intended_key", clear firstrow
	bys categorycode (subcategorycode): replace category = category[1]
	
	isid categorycode subcategorycode
	keep categorycode subcategorycode category subcategory
	
	tempfile oc_key
	save `oc_key'
	
	* pid x occ data
	insheet using "$codes/intended_occupation_codes.csv", names comma clear
	
	merge m:1 categorycode subcategorycode  using `oc_key', nogen keep(match master) 

	duplicates drop

	sort rb_index categorycode subcategorycode
	bys rb_index: gen actn=_n // occupation number
	
	foreach var of varlist *cat* {
		ren `var' `var'_intended
	}
	
	reshape wide *_intended, i(rb_index) j(actn) 
	
	ren rb_index index
	compress
	drop if mi(index) 
	tempfile intended_oc_match
	save `intended_oc_match'
restore

* merge on occupation codes
merge 1:1 index using `intended_oc_match' , gen(_mint_occ) keep(match master) 
tab class _mint_occ , r
drop _mint_occ

* coarse occupation and intended occupation classifiers: 
// gen byte have_occ=!mi(categorycode1)

foreach version in "" "_intended" {
	foreach var in finance doctor law bus manage_high manage_low hed hed_ext teach gov art_pub engineer sci bookkeep {
		gen `var'`version'=0 if have_occ`version'==1
	}

	forv j=1/9 {
		replace finance`version'=1 ///
			if categorycode`version'`j'==1 & subcategorycode`version'`j'<=2 & have_occ`version'==1
		replace doctor`version'=1 if categorycode`version'`j'==4 & have_occ`version'==1
		replace law`version'=1 if categorycode`version'`j'==2 & have_occ`version'==1
		replace bus`version'=1 ///
			if categorycode`version'`j'==3 & (subcategorycode`version'`j'<=3) & have_occ`version'==1 // this excludes hr, secretarial, consulting strings
		replace manage_high`version'=1 ///
			if categorycode`version'`j'==0 & subcategorycode`version'`j'==1 & have_occ`version'==1
		replace manage_low`version'=1 ///
			if categorycode`version'`j'==0 & subcategorycode`version'`j'==2 & have_occ`version'==1
		replace hed`version'=1 ///
			if categorycode`version'`j'==6 & subcategorycode`version'`j'==1 & have_occ`version'==1
		// Extended hed version for which any research occupation refers to hed
		replace hed_ext`version'=1 if categorycode`version'`j'==6 & have_occ`version'==1
		replace teach`version'=1 if categorycode`version'`j'==7 & have_occ`version'==1
		replace gov`version'=1 if categorycode`version'`j'==10  & have_occ`version'==1
		replace art_pub`version'=1 ///
			if categorycode`version'`j'==13 | categorycode`version'`j'==8 & have_occ`version'==1
		replace engineer`version'=1 if categorycode`version'`j'==5  & have_occ`version'==1
		replace sci`version'=1 ///
			if categorycode`version'`j'==6 & (subcategorycode`version'`j'>=2 & have_occ`version'==1 ///
			& subcategorycode`version'`j'<=8)
		replace bookkeep`version'=1 ///
			if categorycode`version'`j'==1  & (subcategorycode`version'`j'>=3 ///
			& subcategorycode`version'`j'<=6) & have_occ`version'==1
	}
}

// remove extra intended variables
forv i = 4/36 {
	
	drop category_intended`i' categorycode_intended`i' subcategory_intended`i' subcategorycode_intended`i'
	
}

// this aggregates the accounting, management, and retail categories from older versions of 
// main peer effects LR results tab
gen bus_agg=(bookkeep==1 | manage_high==1 | manage_low==1 |bus==1) if have_occ==1 

// generate occupation private share and merge back on //
preserve
	* create index*occupation level data
	keep index year categorycode? subcategorycode? private_wm 
	
	reshape long  categorycode subcategorycode , i(index) 
	
	drop if mi(categorycode) | mi(subcategorycode)
	
	tempfile micro
	save `micro'

restore

///////////
// supplementary occupation codes
//////////

preserve
	insheet using "$intexcel/updated_class_reports/all_years.csv", clear 
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

//////////////////////////////////////
// College Majors 
//////////////////////////////////////
*identify individuals with non-missing college major reports
preserve
	insheet using "$codes/senior_class_registers.csv", clear 
	keep rb_index major
	ren rb_index index
	ren major college_major
	keep if !mi(index) & !mi(college_major)
	isid index
	tempfile ts
	save `ts'
restore

merge 1:1 index using `ts', keep(match master) nogen
gen byte have_major = !mi(college_major)

bys year: egen major_year = count(college_major)
replace major_year = major_year > 50

preserve
	* keys
	import exc using "$keys/college_major_key", clear firstrow 
	bys categorycode (subcategorycode): replace category = category[1]
	
	isid categorycode subcategorycode
	keep categorycode subcategorycode category subcategory
	
	ren *code major*code
	ren *category major*category
	
	tempfile major_key
	save `major_key'
	
	* index x college major data
	insheet using "$codes/college_major_codes.csv", names comma clear
	ren *code major*code
	
	merge m:1 majorcategorycode majorsubcategorycode  using `major_key', nogen keep(match master)

	duplicates drop

	sort rb_index majorcategorycode majorsubcategorycode
	bys rb_index: gen majorn=_n // college major number
	
	qui su majorn
	local max_major = `r(max)'
	reshape wide *category* , i(rb_index) j(majorn) 
	
	ren rb_index index
	compress
	drop if mi(index) 
	tempfile major_match
	save `major_match'
restore

* merge on college major codes
merge 1:1 index using `major_match' , gen(_mcollege_major) keep(match master) 
tab class _mcollege_major , r
drop _mcollege_major

* Coarse classification of college majors

foreach var in econ stem humanities social_science {
		gen `var'_major=0 if have_major==1
	}

forv j=1/`max_major' {
	replace econ_major=1 if majorcategorycode`j'==0 
	replace stem_major=1 if majorcategorycode`j'==1
	replace social_science_major=1 if majorcategorycode`j'==3
	replace humanities_major=1 if majorcategorycode`j'==2 
}

// Make a coarse, mutually exclusive categorical major variable
// Hierachy of classification is econ > stem > social science > humanities
gen coarse_major = 4 if econ_major == 1
replace coarse_major = 3 if stem_major == 1  & mi(coarse_major)
replace coarse_major = 2 if social_science_major == 1 & mi(coarse_major)
replace coarse_major = 1 if humanities_major == 1 & mi(coarse_major)
replace coarse_major = 0 if have_major== 1 & mi(coarse_major)

label define major_lab 0 "Other major" 1 "Humanities" 2 "Soc. Science" 3 "STEM/Eng." 4 "Economics"
label values coarse_major major_lab

egen double_major = rowtotal(econ_major stem_major social_science_major humanities_major) if have_major == 1
replace double_major = double_major > 1 if have_major == 1
	
/////////////////////////////////////////
// Social acitivites, clubs, leadership
/////////////////////////////////////////

// clubs //
do 04d_clean_clubs.do

// activities //
do 04e_clean_activities.do

// leadership (in any activity)  //
do 04f_clean_leadership.do

////////////////////////
// class ranks: 
///////////////////////

// merge main file with pids: 
merge m:1 pid using  "${intstata}/class_rank_pid", keep(match master) nogen

// merge supplemental data based on index, update missing: 
merge 1:1 index using  "${intstata}/class_rank_index", keep(match master match_update match_conflict) nogen update

//////////////////////////////////
// senior societies +fraternities
/////////////////////////////////
merge 1:1 index using  "${intstata}/clubs_frats", keep(match master) gen (_sx) 
label var _sx "Merge with clubs and frats data"

tab year _sx
foreach var in hasty final_club final_tier2 $clubs {
replace `var'=0 if  _sx==1 // code missing obs to zero-- you're not in the club
replace `var'=. if year==1935 // we do not have systematic coverage in this year. 
}

drop _sx

//////////////////////////////////////////////////////
// family identiers (family_id is key variable here)
//////////////////////////////////////////////////////

preserve
	insheet using  "${codes}/harvard_brothers.csv", clear
	isid pid
	drop if mi(pid)
	label var family_id "Family ID (from Class Reports)"
	compress
	save "${intstata}/brother_pairs", replace
restore

merge m:1 pid using "${intstata}/brother_pairs", nogen keep(match  master)

//////////////////////////////////////////////////////
// legacy and multiple family member identifiers
//////////////////////////////////////////////////////
preserve
	insheet using  "${codes}/have_harvard_family.csv", clear
	isid pid
	drop if mi(pid)
	label var harvard_brother "Has brother from Harvard"
	label var harvard_father "Has brother from Harvard"
	compress
	save "${intstata}/harvard_family", replace
restore

merge m:1 pid using "${intstata}/harvard_family", keep(match master) gen(_mfam)
label var _mfam "Merge with family data"

tab year _mfam
replace harvard_brother=0 if mi(harvard_brother) & year>1919 & has_pid==1 // not matched this 1919
replace harvard_father=0 if mi(harvard_father) & year>1919  & has_pid==1 // not matched 1919

drop _mfam

//////////////////////////////////////////////////////
// Unemployment rate in graduating year 
// from Lebergott for 1923-1928 and BLS from 1929-1940
//////////////////////////////////////////////////////
preserve
	import excel using "$raw/Other/unemployment/lebergott_unemp_1900_1928.xlsx", first clear

	keep year unemp 
	drop if mi(year)

	tempfile unemp1
	save `unemp1', replace

	import excel using "$raw/Other/unemployment/SeriesReport-20210506170053_85238a.xlsx", ///
		cellrange(A17:B29) first clear
		
	ren Year year
	ren Annual unemp

	append using `unemp1'
	
	ren year class 
	
	replace unemp = unemp / 100
	
	label var unemp "Unemployment rate"
	
	sort class
	keep if class >= 1923
	twoway (connected unemp class), scheme(s1color)
	graph export "$figures/us_unemployment_rate.png", as(png) width(2400) replace
	graph drop _all
	tempfile unemp
	save `unemp' , replace
restore
merge m:1 class using `unemp', nogen keep(1 3)

//////////////////////////////////////////////////////
// Wedding and Children info
//////////////////////////////////////////////////////
preserve
	insheet using "$intexcel/updated_class_reports/all_years.csv",  clear

	keep pid spousename
 	gen married  = !mi(spousename)
	
	label var married "Have spouse"
	label var spousename "Spouse"
	tempfile wedding
	save `wedding'
	
restore
merge m:1 pid using `wedding', nogen keep(1 3)

// hand fixes to some spouse names and marraige status
preserve
	insheet using "$raw/Class_Reports/hand_fixes/spouse-names-suppcodes.csv", clear
	tempfile suppcodes
	save `suppcodes'
restore

merge 1:1 index using `suppcodes', keep(1 3)
replace married = 0 if strunm == 1
replace spousename = spouse_altcode if _merge == 3
drop _merge strunm spouse_altcode

// label and order everything
do 04g_label_order.do

compress
save "$intstata/redbooks_clean_norooms", replace

*** One more step: use the redbook dorm info to 
do 04h_rooms.do

gen all=1
label var all "In Red Books data"

// create missing flags for category codes conditional on occupation data:  
forv j=1/9 {
	replace categorycode`j'=99 if mi(categorycode`j') & have_occ==1
	replace subcategorycode`j'=99 if mi(subcategorycode`j') & have_occ==1
}

forv j=1/20 {
	replace  clubcode`j'=99 if mi(clubcode`j') & has_pid==1
}

forv j=1/11 {
	replace  accategorycode`j'=99 if mi(accategorycode`j') 
	replace  acsubcategorycode`j'=99 if mi(acsubcategorycode`j') 	
}

// create indices that predict covariates based on private feeder dummy

gen phat_oc=. 
gen zphat_oc=. 

gen phat_cl=. 
gen zphat_cl=. 

gen phat_ac=.
gen zphat_ac=. 

gen phat_uac=.
gen zphat_uac=.

gen phat_maj=.
gen zphat_maj=.

gen phat_intent=.
gen zphat_intent=.

gen phat_maj_intent=.
gen zphat_maj_intent=.

gen fin_index = .

global intent_list "finance_intended bus_intended hed_ext_intended doctor_intended law_intended"

levelsof year, local(levels)
foreach l of local levels {
	
	// occupations: 
	lasso2 pf_wm manage_high manage_low bus bookkeep finance doctor law  hed teach gov art_pub engineer sci ///
		i.year if year!=`l' , long 
	predict double phat_oc`l' if have_occ==1  , lic(ebic)
	
	su phat_oc`l' if year==`l'
	gen zphat_oc`l'=(phat_oc`l'-`r(mean)')/`r(sd)'
	
	replace phat_oc=phat_oc`l' if year==`l' & have_occ==1
	replace zphat_oc=zphat_oc`l' if year==`l' & have_occ==1
	
	drop phat_oc`l' zphat_oc`l'
	
	// activities: 
	lasso2 pf_wm have_ac nac aclead social sports music redbook dorm_com language ///
		drama politics  other_club ///		
		i.year if year!=`l' , long 
	predict double phat_ac`l'  , lic(ebic)
	
	su phat_ac`l' if year==`l'
	gen zphat_ac`l'=(phat_ac`l'-`r(mean)')/`r(sd)'
	
	replace phat_ac=phat_ac`l' if year==`l' 
	replace zphat_ac=zphat_ac`l' if year==`l'  
	drop phat_ac`l' zphat_ac`l'

	// upper-year clubs: 
	if `l'<1935 {
		lasso2 pf_wm  final_tier2 hasty final_club ///		
			i.year if year!=`l' , long 
		predict double phat_uac`l'  , lic(ebic)
		
		su phat_uac`l' if year==`l'
		gen zphat_uac`l'=(phat_uac`l'-`r(mean)')/`r(sd)'
		
		replace phat_uac=phat_uac`l' if year==`l' 
		replace zphat_uac=zphat_uac`l' if year==`l'  
		drop phat_uac`l' zphat_uac`l'
	} 
	
	// clubs: 
	lasso2 pf_wm have_country_club have_gent_club have_frat_order  ///
		have_prof_assoc have_hon_club /// 
		i.year if year!=`l' & has_pid==1, long 
	predict double phat_cl`l' if has_pid==1  , lic(ebic)
	
	su phat_cl`l' if year==`l'
	gen zphat_cl`l'=(phat_cl`l'-`r(mean)')/`r(sd)'
	
	replace phat_cl=phat_cl`l' if year==`l' & has_pid==1
	replace zphat_cl=zphat_cl`l' if year==`l' &  has_pid==1
	
	drop phat_cl`l' zphat_cl`l'
	
	//  major
	* only for years where college major is available
	qui su year if major_year == 1
	if inrange(`l',`r(min)',`r(max)') {
		lasso2 pf_wm econ_major humanities_major social_science_major double_major i.year ///
			if year != `l' &  major_year == 1 & has_senior_info ==1, long
			
		predict double phat_maj`l' if major_year == 1 & has_senior_info ==1 , lic(ebic)
		su phat_maj`l' if year == `l' & major_year == 1
		gen zphat_maj`l' = (phat_maj`l' - `r(mean)') / `r(sd)'
		
		replace phat_maj = phat_maj`l' ///
			if year == `l' & has_senior_info ==1 & major_year == 1
		replace zphat_maj = zphat_maj`l' ///
			if year == `l' & has_senior_info ==1 & major_year == 1
		
		drop phat_maj`l' zphat_maj`l'
	}
	
	// intent 
	* only for years where intended occupation is available
	qui su year if occ_intended_year == 1

	if inrange(`l',`r(min)',`r(max)') {
		lasso2 pf_wm $intent_list i.year ///
			if year != `l' & occ_intended_year == 1 & has_senior_info ==1, long
		
		predict double phat_intent`l' ///
			if has_senior_info ==1 & occ_intended_year == 1, lic(ebic)
		
		su phat_intent`l' if year == `l' & occ_intended_year == 1
		gen zphat_intent`l' = (phat_intent`l' - `r(mean)') / `r(sd)'
		
		replace phat_intent = phat_intent`l' ///
			if year == `l' & has_senior_info ==1 & occ_intended_year == 1
		replace zphat_intent = zphat_intent`l' ///
			if year == `l' & has_senior_info ==1 & occ_intended_year == 1
		
		drop phat_intent`l' zphat_intent`l'
	}
	
	// major + intent
	* only for years where college major AND intended occupation are available
	qui su year if major_year == 1 & occ_intended_year == 1
	if inrange(`l',`r(min)',`r(max)') {
		lasso2 pf_wm $intent_list ///
			econ_major humanities_major social_science_major double_major ///
			i.year if year != `l' ///
			& occ_intended_year == 1 & major_year == 1 & has_senior_info ==1, long
			
		predict double phat_maj_intent`l' ///
			if occ_intended_year == 1 & major_year == 1 & has_senior_info ==1 , lic(ebic)
		su phat_maj_intent`l' if year == `l' & occ_intended_year == 1 & major_year == 1
		gen zphat_maj_intent`l' = (phat_maj_intent`l' - `r(mean)') / `r(sd)'
		
		replace phat_maj_intent = phat_maj_intent`l' if year == `l' ///
			& occ_intended_year == 1 & major_year == 1 & has_senior_info ==1
		replace zphat_maj_intent = zphat_maj_intent`l' if year == `l' ///
			& occ_intended_year == 1 & major_year == 1 & has_senior_info ==1
		
		drop phat_maj_intent`l' zphat_maj_intent`l'
		
		// Finance index (don't normalize)
		lasso2 finance stem_major econ_major humanities_major social_science_major double_major ///
			$intent_list i.year if year != `l' ///
			& occ_intended_year == 1 & major_year == 1 & has_senior_info ==1 , long
		predict fin_index`l' if has_senior_info ==1 & ///
			occ_intended_year == 1 & major_year == 1, lic(ebic)
		
		replace fin_index = fin_index`l' if year == `l' ///
			& has_senior_info ==1 & occ_intended_year == 1 & major_year == 1
		
		drop fin_index`l'
	}
	
}

drop major_year occ_intended_year

// rank group categories 
	forv j=1/6 {
		gen rg`j'=rankgroup1==`j' if !mi(rankgroup1)
		label var rg`j' "Rank group `j'"
		gen rg`j'_wm=rg`j'
		replace rg`j'_wm=0 if year!=1919 & mi(rg`j')
		label var rg`j'_wm "Rank group `j'"
	}
gen have_grade=!mi(rankgroup1) 
label var have_grade "Have grade data"

gen rg_notlisted1=1-have_grade
replace rg_notlisted1=. if year==1919
label var rg_notlisted1 "Not ranked year 1"
gen rg_listed1=have_grade
replace rg_listed1=. if year==1919
label var rg_listed1 "Rank listed year 1"

gen rg_notlisted3=mi(rankgroup3)
replace rg_notlisted3=. if year>1930
label var rg_notlisted3 "Not ranked year 3"
gen rg_listed3=1-rg_notlisted3
label var rg_listed3 "Rank listed year 3"

gen not_ssm=(redbook==1 | outdoors==1 | dorm_com==1 |  politics==1 | politics==1 | language==1 | drama==1 | pubs==1 | other_club==1 )
label var not_ssm "Other activities"

rename psuedo_nbdranki_entryway nbdranki_entryway
rename psuedo_nbdranki_nearest nbdranki_nearest

label var have_campus_address "Has campus address"
label var oncampus "Lives on campus"
label var roomatts "Has data on room attributes"
label var have_hs_rec "Has high school record"
label var pf_wm "Private feeder high school (including unclassfied schools)"
label var phat_oc "Occupation index"
label var zphat_oc "Occupation index (normalized)"
label var phat_cl "Adult association index"
label var zphat_cl"Adult association index (normalized"
label var phat_ac "Freshman activity index"
label var zphat_ac "Freshman activity index (normalized)"
label var phat_uac "Upper-year index"
label var zphat_uac "Upper-year index (normalized)"
label var phat_maj "Major index"
label var zphat_maj "Major index (normalized)"
label var phat_intent "Intended occupation index"
label var zphat_intent "Intended occupation index (normalized)"
label var phat_maj_intent "Intended major index"
label var zphat_maj_intent "Intended major index (normalized)"
label var fin_index "Finance index"

** re-org the uyclub variables
gen any_fc_hasty=(final_club==1 | hasty==1)
gen fc_hasty_nottier2=(any_fc_hasty==1 & final_tier2==0)
gen fc_nottier2=(final_club==1 & final_tier2==0)
label var any_fc_hasty "In final club or Hasty"
label var fc_hasty_nottier2 "In non-selective final club or Hasty"
label var fc_nottier2 "In non-selective final club"

order have_hs_rec ///
have_hs ///
high_school ///
schoolcode1 ///
schoolname1 ///
private1 ///
public_feeder1 ///
private_feeder1 ///
schoolcode2 ///
schoolname2 ///
private2 ///
public_feeder2 ///
private_feeder2 ///
private ///
private_wm ///
private_feeder ///
pf_wm ///
public_feeder ///
have_campus_address ///
oncampus ///
college_address ///
havedorm ///
dorm ///
roomatts ///
roomno ///
room_id ///
bedrooms ///
floor ///
stairwell ///
suite ///
roomcap ///
price ///
price_per_student ///
dorm_nbd ///
nearest_nbd ///
entryway_nbd ///
dorm_nbd_id ///
n_dorm_nbd ///
mp_dorm_nbd ///
nearest_nbd_id ///
n_nearest_nbd ///
entryway_nbd_id ///
n_entryway_nbd ///
mpi_dorm_nbd ///
mpi_entryway_nbd ///
topshare ///
eliteaccess ///
pq ///
nbdrank ///
nbdranki ///
nbdranki_entryway ///
nbdranki_nearest, before(clubname1)

order all, last
order phat_oc-all, before(unemp)
order all, last

order any_fc_hasty - fc_nottier2, after(final_tier2)
order rg1 - rg_listed3, after(rankgroup3)

forv i = 1/9 {
	rename category`i' occCategory`i'
	rename categorycode`i' occCategorycode`i'
	rename subcategory`i' occSubcategory`i'
	rename subcategorycode`i' occSubcategorycode`i'
}

// drop unused variables for final, cleaned dataset
drop home_address high_school activities occupation_intended occupation publications 

compress
save "$cleaned/redbooks_clean", replace