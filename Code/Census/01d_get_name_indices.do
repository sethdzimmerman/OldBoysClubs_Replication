/*

01d_get_name_indices.do
(called from 01_clean_census.do)

Purpose: create name indices from census data
Inputs: CENSUS_PATH1/dta-columns/`year', CENSUS_PATH1/dta-columns/1850/`var',
	cleaned/redbooks_clean, cleaned/lr_series_redbooks_clean
Outputs: intstata/names_`year'_first, intstata/names_`year'_last, intstata/names_first,
	intstata/names_last, intstata/names_1850_last, intstata/harvard_names_person_level,
	intstata/lr_series_harvard_names_person_level, intstata/last_name_indices,
	intstata/lr_series_last_name_indices, intstata/first_name_indices,
	intstata/lr_series_first_name_indices, intstata/harvard_name_indices,
	intstata/lr_series_harvard_name_indices, cleaned/lr_series_redbooks_update
	
*/

foreach year in 1920 1930 {
	cd "$CENSUS_PATH1/dta-columns//`year'//"
	use namefrst, clear
	foreach var in namelast mtongue sex bpl mbpl fbpl { // bpl //  
	merge 1:1 _n using `var'
	drop _merge
	}

	// identify yiddish language speakers
	count if mi(mtongue)
	gen byte mt_yjh=((mtongue>=0300 & mtongue <=0320) | mtongue==5900)
	gen byte mt_noteng=(mtongue!=100 & mtongue!=0)
	drop mtongue

	// identify southern european and irish immigrants: 
	foreach vbpl in bpl mbpl fbpl{
		gen byte `vbpl'_se=(`vbpl'==43400 | `vbpl' == 43800) // Italy + Spain 
		gen byte `vbpl'_ir=(`vbpl'==41400 ) // ireland 
	}

	gen byte cath_immg=(bpl_se==1 | mbpl_se==1 | fbpl_se==1 | bpl_ir==1 | mbpl_ir==1 | fbpl_ir==1)

	gen count=1
	keep count mt_yjh mt_noteng cath_immg namefrst sex namelast 
	tempfile tcens
	save `tcens'

	// first names: 
	collapse (sum) count mt_yjh mt_noteng cath_immg, by(namefrst sex)
	gen year=`year'
	compress
	save "${intstata}/names_`year'_first", replace

	// last names: 
	use `tcens', clear
	collapse (sum) count mt_yjh mt_noteng cath_immg, by(namelast sex)
	gen year=`year'
	compress
	save "${intstata}/names_`year'_last", replace
}

use "$intstata/names_1920_first", clear
append using "$intstata/names_1930_first"
collapse (sum) count mt_yjh mt_noteng cath_immg, by(namefrst sex)
save "$intstata/names_first", replace

use "$intstata/names_1920_last", clear
append using "$intstata/names_1930_last"
collapse (sum) count mt_yjh mt_noteng cath_immg, by(namelast sex)
save "$intstata/names_last", replace

//
//
// OLD SCHOOL WASP NAMES (LAST ONLY)
//
//

cd "$CENSUS_PATH1/dta-columns/1850/"
use namelast  , clear
foreach var in bpl age { // bpl //  
merge 1:1 _n using `var'
drop _merge
}

keep if age>=50 // born 1800 or earlier 
keep if bpl==2500 // born in massachusetts

gen count_oldMA=1
keep  namelast count_oldMA

// last names: 
collapse (sum) count_oldMA, by(namelast)
compress
save "${intstata}/names_1850_last", replace

//
//
// compute name indices
//
//

//
//
// PREP HARVARD NAME DATA
//
//

foreach version in "" "lr_series_" {
	use "$cleaned//`version'redbooks_clean", clear

	keep name spousename index private_feeder
	ren private_feeder pf_wm

// First and last names formatted for index merges: 
		foreach  name in "name" "spousename" {
		replace `name'=subinstr(upper(`name'),", JR.","",.)
		replace `name'=subinstr(upper(`name'),", JB.","",.) // type for "JR."
		replace `name'=subinstr(upper(`name'),", JR .","",.) // type for "JR."
		
		replace `name'=subinstr(upper(`name'),", III","",.)
		replace `name'=subinstr(upper(`name'),"III","",.)

		replace `name'=subinstr(upper(`name'),", II","",.)
		replace `name'=subinstr(upper(`name'),"II","",.)

		replace `name'=subinstr(upper(`name'),", IV","",.)
		replace `name'=subinstr(upper(`name'),"IV","",.)

		replace `name'=subinstr(upper(`name'),", 3D","",.)
		replace `name'=subinstr(upper(`name'),"3D","",.)

		replace `name'=subinstr(upper(`name'),", 3RD","",.)
		replace `name'=subinstr(upper(`name'),"3RD","",.)		
		
		replace `name'=subinstr(upper(`name'),", 2D","",.)
		replace `name'=subinstr(upper(`name'),"2D","",.)	
		
		replace `name'=subinstr(upper(`name'),", 2ND","",.)
		replace `name'=subinstr(upper(`name'),"2ND","",.)				

		replace `name'=subinstr(upper(`name'),", 4TH","",.)
		replace `name'=subinstr(upper(`name'),"4TH","",.)	
		
		replace `name'=subinstr(upper(`name'),", E.S.","",.)
		replace `name'=subinstr(upper(`name'),"E.S.","",.)			

		replace `name'=subinstr(upper(`name'),", E. S.","",.)
		replace `name'=subinstr(upper(`name'),"E. S.","",.)			
				
		// format: last, first
		gen `name'last=subinstr(word(`name',1),",","",.) if strpos(word(`name',1),",")>0
		gen `name'frst=word(`name',2) if strpos(word(`name',1),",")>0

		// format: first middle last
		replace `name'last=word(`name',wordcount(`name')) if strpos(`name',",")==0
		replace `name'frst=word(`name',1)  if strpos(`name',",")==0
		
		// deal with multi-word last names: -- comma is in the second word
		gen `name'miflag= mi(`name'last)
		replace `name'last=word(`name',1)+" "+subinstr(word(`name',2),",","",.) if strpos(word(`name',2),",")>0 & `name'miflag==1
		replace `name'frst=word(`name',3) if strpos(word(`name',2),",")>0 & `name'miflag==1
	
		// deal with multi-word last names: -- comma is in the third word
		replace `name'last=word(`name',1)+" "+word(`name',2)+" "+ subinstr(word(`name',3),",","",.) ///
			if strpos(word(`name',3),",")>0 & `name'miflag==1
		replace `name'frst=word(`name',4) if strpos(word(`name',3),",")>0 & `name'miflag==1
		
		// format for merge: 
		replace `name'last=trim(upper(`name'last))
		replace `name'frst=trim(upper(`name'frst))
	}

	// individual file for later use: 
	compress
	save "${intstata}//`version'harvard_names_person_level", replace

	gen harvard_count=1
	ren pf_wm pf_count // private feeder count
	// name counts for index computation:
	preserve
		drop if mi(namelast)
		collapse (sum) harvard_count pf_count, by(namelast)
		tempfile hnameslast
		save `hnameslast'
	restore

	drop if mi(namefrst)
	collapse (sum) harvard_count pf_count, by(namefrst)
	gen sex=1 // all are male in this sample
	tempfile hnamesfrst
	save `hnamesfrst'

	//
	//
	// CENSUS DATASETS :
	//
	//

	//
	// last name: 
	//

	use "${intstata}/names_last", clear

	drop if mi(namelast)
	collapse (sum) count mt_yjh mt_noteng cath_immg, by(namelast)

	// harvard data: 
	merge 1:1 namelast using `hnameslast', gen(_mlast)
	drop if _mlast==2
	replace harvard_count=0 if _mlast==1
	replace pf_count=0 if _mlast==1


	// old census data: 
	merge 1:1 namelast using "${intstata}/names_1850_last", gen(_mold)
	drop if _mold==2 // continuing to take Census names as universe
	replace count_oldMA = 0 if _mold == 1 

	// create indices
	foreach var in mt_yjh harvard_count pf_count cath_immg count_oldMA {
		egen total_`var' =total(`var') // across all names
		egen total_n`var'=total(count-`var') // across all names_1930_first
		gen `var'_index=(`var'/total_`var')/((`var'/total_`var')+(count-`var')/total_n`var')	
	}

	ren mt_yjh_index jewish_lnindex
	ren harvard_count_index harvard_lnindex
	ren pf_count_index pf_lnindex
	ren cath_immg_index cath_lnindex
	ren count_oldMA_index oldMA_lnindex

	// Make version for spouses
	gen spousenamelast = namelast
	gen jewish_lnindex_spouse = jewish_lnindex
	gen harvard_lnindex_spouse = harvard_lnindex
	gen pf_lnindex_spouse = pf_lnindex
	gen cath_lnindex_spouse = cath_lnindex
	gen oldMA_lnindex_spouse = oldMA_lnindex

	ren count lncount // count of people in census with this last name
	gen lncount_spouse = lncount
	// keep, sort, save
	keep namelast spousenamelast jewish_lnindex lncount harvard_lnindex pf_lnindex ///
		cath_lnindex oldMA_lnindex *spouse 
	isid namelast
	save "${intstata}//`version'last_name_indices", replace

	//
	// first names-- note conditioning on sex: 
	//

	use "${intstata}/names_first", clear
	drop if mi(namefrst)

	// merge harvard data
	merge 1:1 namefrst sex using `hnamesfrst', gen(_mfirst)

	drop if _mfirst==2 
	replace harvard_count=0 if _mfirst==1
	replace pf_count = 0 if _mfirst == 1

	// generate indices
	// create indices
	foreach var in mt_yjh harvard_count pf_count cath_immg {
		egen total_`var' =total(`var'), by(sex) // across all names within sex
		egen total_n`var'=total(count-`var'), by(sex) // across all names within sex
		gen `var'_index=(`var'/total_`var')/((`var'/total_`var')+(count-`var')/total_n`var')	
	}

	ren count fncount // count of people with this name in census/gender cell
	ren mt_yjh_index jewish_fnindex
	ren harvard_count_index harvard_fnindex
	ren pf_count_index pf_fnindex
	ren cath_immg_index cath_fnindex

	// Get indices for spouses
	gen spousenamefrst = namefrst
	gen spouse_sex = sex
	gen fncount_spouse = fncount if !mi(spousenamefrst)
	gen jewish_fnindex_spouse = jewish_fnindex if !mi(spousenamefrst)
	gen cath_fnindex_spouse = cath_fnindex if !mi(spousenamefrst)

	// keep, sort, save
	keep *namefrst jewish_fnindex sex spouse_sex fncount harvard_fnindex pf_fnindex cath_fnindex *spouse
	isid namefrst sex
	save "${intstata}//`version'first_name_indices", replace

	//
	//
	// compute aggregate name scores: 
	//
	//

	use "${intstata}//`version'harvard_names_person_level", clear
	gen sex=1
	merge m:1 namefrst sex using "${intstata}//`version'first_name_indices", gen(_mnfrst) keep(match master) keepusing(*fnindex fncount)

	gen spouse_sex = 2 if !mi(spousenamefrst)
	merge m:1 spousenamefrst spouse_sex using "${intstata}//`version'first_name_indices", gen(_mspousefrst) keep(match master) keepusing(*spouse)

	merge m:1 namelast using "${intstata}//`version'last_name_indices", gen(_mnlast) keep(match master) keepusing(*lnindex lncount)

	merge m:1 spousenamelast using "${intstata}//`version'last_name_indices", gen(_mspouselast) keep(match master) keepusing(*_spouse)

	foreach var in jewish harvard pf cath {
		gen `var'_index=(`var'_fnindex+`var'_lnindex) / 2
		su `var'_index, det
		gsort -`var'_index
		lis namefrst namelast `var'_index in 1/50
	}

	gen jewish_index_spouse  = (jewish_fnindex_spouse + jewish_lnindex_spouse) / 2
	gen cath_index_spouse  = (cath_fnindex_spouse + cath_lnindex_spouse) / 2
	gen harvard_index_spouse = harvard_lnindex_spouse
	gen pf_index_spouse = pf_lnindex_spouse

	su oldMA_lnindex, det
	gsort -oldMA_lnindex
	lis namefrst namelast oldMA_lnindex in 1/50

	drop sex name pf_wm _mnfrst _mnlast _mspousefrst _mspouselast
	compress
	save "${intstata}//`version'harvard_name_indices", replace

}

//
//
// look at desc stats merging on to main data
//
//

use "$cleaned/redbooks_clean", clear

merge 1:1 index using "${intstata}/harvard_name_indices"

tab year, su(jewish_index)
tab year, su(cath_index)

tabstat jewish_index cath_index oldMA_lnindex, by(pf_wm)
tabstat jewish_index cath_index oldMA_lnindex, by(public_feeder)
collapse (mean) jewish_index pf_index cath_index, by(year)


//
//
// Merge name indices onto LR redbooks data
//
//


use "$cleaned/lr_series_redbooks_clean", clear

merge 1:1 index using "$intstata/lr_series_harvard_name_indices", nogen

// label new variables

label var namelast "Last name from Census"
label var namefrst "First name from Census"
label var namemiflag "Name is missing from Census"
label var spousenamelast "Last name of spouse"
label var spousenamefrst "First name of spouse"
label var spousenamemiflag "Spouse name is missing"
label var fncount "Count of first name in Census"
label var jewish_fnindex "Jewish first name index"
label var harvard_fnindex "Harvard first name index"
label var pf_fnindex "Private feeder first name index"
label var cath_fnindex "Catholic first name index"
label var spouse_sex "Spouse sex"
label var fncount_spouse "Spuse first name count"
label var jewish_fnindex_spouse "Jewish spouse first name index"
label var cath_fnindex_spouse "Catholic spouse first name index"
label var lncount "Count of last name in Census"
label var jewish_lnindex "Jewish last name index"
label var harvard_lnindex "Harvard last name index"
label var pf_lnindex "Private feeder last name index"
label var cath_lnindex "Catholic last name index"
label var oldMA_lnindex "Colonial last name index"
label var jewish_lnindex_spouse "Jewish spouse last name index"
label var harvard_lnindex_spouse "Harvard spouse last name index"
label var pf_lnindex_spouse "Private feeder spouse last name index"
label var cath_lnindex_spouse "Catholic spouse last name index"
label var oldMA_lnindex_spouse "Colonial spouse last name index"
label var lncount_spouse "Spouse last name count"
label var jewish_index "Jewish full name index"
label var harvard_index "Harvard full name index"
label var pf_index "Private feeder full name index"
label var cath_index "Catholic full name index"
label var jewish_index_spouse "Jewish spouse full name index"
label var cath_index_spouse "Catholic spouse full name index"
label var harvard_index_spouse "Harvard spouse full name index"
label var pf_index_spouse "Private feeder spouse full name index"

compress
save "$cleaned/lr_series_redbooks_update", replace