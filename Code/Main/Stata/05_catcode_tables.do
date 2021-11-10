/*

05_catcode_tables.do
(called from master.do)

Purpose: produces category tables from Appendix B
Inputs: keys/high_school_key, keys/activity_key, keys/club_key,
	keys/occupation_key
Outputs: tables/tab_codes_hs_v3, tables/tab_codes_act_v3, tables/tab_codes_clubs_v3,
	tables/tab_codes_clubs_v3, tables/tab_codes_occ_v3

*/

// option to write output as txt files or tex files
global tex=1
if ${tex}==1 local suf="tex"
if ${tex}==0 local suf "txt"

// reads in the following
// * activity_key.xlsx
// * club_key.xlsx" 
// * occupation_key.xlsx
// * high_school_key

///////////////////////////////////////
// Table B.1: Codes for High Schools //
///////////////////////////////////////

import exc using "$keys/high_school_key.xlsx" , first clear

	gen private=inlist(schoolcode,1,3,4,5,6,7,8,9,10,12,13,14,16,17,18,20,21,22,/*
        */ 24,25,26,27,29,30,31,44, 45,46,47,48,49,50,51,52,54,55,56,57,59,60,61,62,63,65,66,68,69,70,72,73,74,75,77,78,80,83,84,85,88,92,97,104,105,106,109,112,113,114)  
    gen public_feeder=1-private
    gen private_feeder=inlist(schoolcode,1,3,4,5,6,8,10,22) 

label var private "Private" 
label var private_feeder "Private feeder"
label var public_feeder "Public feeder"

global samp_list "private_feeder  private public_feeder"
local var "name"

cap file close f 
file open f using "${tables}/tab_codes_hs_v3.`suf'", write replace

     levelsof `var', local(levels) 
	 foreach l of local levels {
	file write f "`l'" 
	
	foreach samp in  $samp_list  {
		qui su `samp' if `var' == "`l'" , meanonly
		if ${tex}==1 file write f " & "
		file write f _tab 
	
		file write f %4.0f ( `r(mean)' ) 
	}
	if ${tex}==1 file write f " \\" 
	file write f _newline
}

file close f

/////////////////////////////////////
// Table B.2: Codes for Activities //
/////////////////////////////////////

import exc using "$keys/activity_key.xlsx" , first clear

gen newcat=(Category!=Category[_n-1])
gen newsub=(Subcategory!=Subcategory[_n-1])
gen new=(newcat==1 | newsub==1)

gen Identifiers=ActivityTitle
lab var Identifiers "Identifiers"

replace  Identifiers="Yardling" if Identifiers==`""Yardling""' // deal with quotes in string that caused error later
replace Identifiers="Circulo Espafiol" if Identifiers=="Circulo Espafiol (just a misspelling)"
replace Identifiers="Harvard Naval Unit" if Identifiers=="Harvard Naval Unit (believe this is an ROTC thing)"

replace Category=proper(Category)

preserve

global samp_list "Category Subcategory Identifiers"

cap file close f 
file open f using "${tables}/tab_codes_act_v3.`suf'", write replace


local N = _N
forvalues i = 1/`N' {
    if new[`i']==1 {
	if `i'!=1 & ${tex}==1 file write f " \\" 
	if `i'!=1  file write f _newline
	
	if newcat[`i']==1{
	levelsof Category if _n==`i', local(cat) 
	foreach c of local cat {
    file write f "`c'" 
	 }
	}
	if ${tex}==1 file write f " & "
	file write f _tab 
	if newsub[`i']==1{	
	levelsof Subcategory if _n==`i', local(subcat) 
	 foreach s of local subcat {
	 file write f "`s'" 
	 }
	}
	if ${tex}==1 file write f " & "
	file write f _tab 
	} 
	 if new[`i']==0{ 
	     file write f ", " 
	 }
     levelsof Identifiers if _n==`i', local(ids) 
	 foreach l of local ids {
	 file write f "`l'" 
	 }
	 
}

	if ${tex}==1 file write f " \\"
file close f

///////////////////////////////////////////////
// Table B.4: adult clubs from class reports //
///////////////////////////////////////////////

import exc using "${keys}/club_key.xlsx" , first clear 
// adjust special characters 
replace member_of="B'nai B'rith" if regex=="b.nai b.rith"
replace member_of="arts professional association [any]" if  member_of=="arts professional association [any}" 

gen social_alt=max(country_club, frat_order, gent_club) 

label var professional "Professional" 
label var honorary_or_political "Honorary/Pol." 
label var social_alt "Social" 
label var country_club "Country Club" 
label var gent_club "Gent. Club" 
label var frat_order "Frat. Order" 

drop if max(social_alt,country_club,gent_club,frat_order,honorary_or_political,professional)!=1
// too long for one page, so split in two (longtable is not compatible with the 'table' environment, so splitting this way)

global samp_list "social_alt country_club gent_club frat_order honorary_or_political  professional"

cap file close f 
file open f using "${tables}/tab_codes_clubs_v3.`suf'", write replace

     levelsof member_of, local(levels) 
	 foreach l of local levels {
	file write f "`l'" 
	
	foreach samp in  $samp_list  {
		qui su `samp' if member_of == "`l'" , meanonly
		if ${tex}==1 file write f " & "
		file write f _tab 
	
		file write f %4.0f ( `r(mean)' ) 
	}
	if ${tex}==1 file write f " \\" 
	file write f _newline
}

file close f

/////////////////////////////////////
// Table B.3: Codes of Occupations //
/////////////////////////////////////

import exc using "$keys/occupation_key.xlsx" , first clear

replace category="Finance" if category=="financial"
replace category="Doctor" if category=="medical"
replace category="Lawyer" if category=="law"
replace category="Retail" if category=="business/corporate"
replace category="Senior management" if subcategory=="high level"
replace category="Low management" if subcategory=="low level"
replace subcategory="" if subcategory=="high level" | subcategory=="low level"
replace category="Higher education" if category=="academics/research"
replace category="Teacher" if category=="education"
replace category="Government" if category=="government"
replace categorycode=8.1 if categorycode==13
replace category="Art/publishing" if category=="publishing/writing"
replace category="" if category=="art/design"
replace category="Accounting/real estate" if categorycode==1 & subcategorycode==3
replace category="Engineer" if category=="engineering"
replace category="Scientist" if subcategory=="research"

replace category=proper(category)

sort categorycode subcategorycode	

cap file close f 
file open f using "${tables}/tab_codes_occ_v3.`suf'", write replace

local N = _N
forvalues i = 1/`N' {
    
	
	levelsof category if _n==`i', local(cat) 
	foreach c of local cat {
    file write f "`c'" 
	 }
	if ${tex}==1 file write f " & "
	file write f _tab 
		
	levelsof subcategory if _n==`i', local(subcat) 
	 foreach s of local subcat {
	 file write f "`s'" 
	 }
	 
	if ${tex}==1 file write f " & "
	file write f _tab 
	 
     levelsof identifiers if _n==`i', local(ids) 
	 foreach l of local ids {
	 file write f "`l'" 
	 }

	if ${tex}==1 file write f " \\" 
	file write f _newline
}

file close f