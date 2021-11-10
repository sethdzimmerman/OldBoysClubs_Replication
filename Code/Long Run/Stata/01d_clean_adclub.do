/*

01d_clean_adclub.do
(called from 01_clean_redbooks.do)

Purpose: format historical AD membership data
Inputs: raw/Clubs/AD_club/ad_club_data_1837-2015
Outputs: intstata/ad-club-dat

*/

// hold onto Red Book data for later use
tempfile redbooks
save `redbooks'

// now clean AD club data and then merge: 
// start with digitized records from 2015 AD club catalog
// these are lists of members in each year

import excel using "$raw/Clubs/AD_club/ad_club_data_1837-2015.xlsx", clear firstrow

// very little missing data: 
count
count if mi(Cohortyear)
count if mi(Name)
count if mi(Birthplace) 

keep Cohortyear Name 

// typos: 
replace Name=subinstr(Name,"*","",.) // this denotes deceased people

drop if Name=="Gerald Boardnab Church" // duplicate record with typo in one copy
drop if Name=="Robert Armistead Woodridge Brauns, Jr." // duplicate record with typo in one copy

// clean out  duplicate records--- these are cases where photographer took multiple photos of same page
replace Name=upper(Name)

duplicates  tag, gen(dup)
tab Cohortyear dup // you can see runs across years for same-page records
drop dup
duplicates drop

// cohort years are class years
ren  Cohortyear class // 

// format names
// note that all names are in format first (middle) last, suffix

gen Namelast=""
gen Namefrst=""

replace Name=subinstr(upper(Name),", JR.","",.)
replace Name=subinstr(upper(Name),", JB.","",.) // type for "JR."
replace Name=subinstr(upper(Name),", JR .","",.) // type for "JR."
	
replace Name=subinstr(upper(Name),", III","",.)
replace Name=subinstr(upper(Name),"III","",.)

replace Name=subinstr(upper(Name),", II","",.)
replace Name=subinstr(upper(Name),"II","",.)

replace Name=subinstr(upper(Name),", IV","",.)
replace Name=subinstr(upper(Name),"IV","",.)

replace Name=subinstr(upper(Name),", 3D","",.)
replace Name=subinstr(upper(Name),"3D","",.)

replace Name=subinstr(upper(Name),", 3RD","",.)
replace Name=subinstr(upper(Name),"3RD","",.)		

replace Name=subinstr(upper(Name),", 2D","",.)
replace Name=subinstr(upper(Name),"2D","",.)	

replace Name=subinstr(upper(Name),", 2ND","",.)
replace Name=subinstr(upper(Name),"2ND","",.)				

replace Name=subinstr(upper(Name),", 4TH","",.)
replace Name=subinstr(upper(Name),"4TH","",.)	

replace Name=subinstr(upper(Name),", E.S.","",.)
replace Name=subinstr(upper(Name),"E.S.","",.)			

replace Name=subinstr(upper(Name),", E. S.","",.)
replace Name=subinstr(upper(Name),"E. S.","",.)		

replace Namelast=word(Name,wordcount(Name)) if strpos(Name,",")==0
replace Namefrst=word(Name,1)  if strpos(Name,",")==0

replace Name=subinstr(upper(Name),"'","",.) // kill apostrophe
replace Name=subinstr(upper(Name),"’","",.) // kill apostrophe

gen idu=_n

keep class Namelast Namefrst idu

// temp data set for test 
preserve
gen Ntotal=1
collapse (sum) Ntotal, by(class)

keep Ntotal class
tempfile yearcounts
save `yearcounts'
restore

tempfile adclub

label var class "Graduating class"
label var Namelast "Last name"
label var Namefrst "First name"
label var idu "Student ID (from clubs data)"

order idu Namelast Namefrst class

save "${intstata}/ad-club-dat", replace

//
//
// now bring red book data back: 
//
//

use `redbooks', clear

// First and last names formatted for index merges: 
replace name=subinstr(upper(name),", JR.","",.)
replace name=subinstr(upper(name),", JB.","",.) // type for "JR."
replace name=subinstr(upper(name),", JR .","",.) // type for "JR."

replace name=subinstr(upper(name),", III","",.)
replace name=subinstr(upper(name),"III","",.)

replace name=subinstr(upper(name),", II","",.)
replace name=subinstr(upper(name),"II","",.)

replace name=subinstr(upper(name),", IV","",.)
replace name=subinstr(upper(name),"IV","",.)

replace name=subinstr(upper(name),", 3D","",.)
replace name=subinstr(upper(name),"3D","",.)

replace name=subinstr(upper(name),", 3RD","",.)
replace name=subinstr(upper(name),"3RD","",.)		

replace name=subinstr(upper(name),", 2D","",.)
replace name=subinstr(upper(name),"2D","",.)	

replace name=subinstr(upper(name),", 2ND","",.)
replace name=subinstr(upper(name),"2ND","",.)				

replace name=subinstr(upper(name),", 4TH","",.)
replace name=subinstr(upper(name),"4TH","",.)	

replace name=subinstr(upper(name),", E.S.","",.)
replace name=subinstr(upper(name),"E.S.","",.)			

replace name=subinstr(upper(name),", E. S.","",.)
replace name=subinstr(upper(name),"E. S.","",.)			

replace name=subinstr(upper(name),"'","",.) // kill apostrophe
replace name=subinstr(upper(name),"’","",.) // kill apostrophe

// format: last, first
gen namelast=subinstr(word(name,1),",","",.) if strpos(word(name,1),",")>0
gen namefrst=word(name,2) if strpos(word(name,1),",")>0

// format: first middle last
replace namelast=word(name,wordcount(name)) if strpos(name,",")==0
replace namefrst=word(name,1)  if strpos(name,",")==0

// deal with multi-word last names: -- comma is in the second word
gen namemiflag= mi(namelast)
replace namelast=word(name,1)+" "+subinstr(word(name,2),",","",.) if strpos(word(name,2),",")>0 & namemiflag==1
replace namefrst=word(name,3) if strpos(word(name,2),",")>0 & namemiflag==1

// deal with multi-word last names: -- comma is in the third word
replace namelast=word(name,1)+" "+word(name,2)+" "+ subinstr(word(name,3),",","",.) ///
	if strpos(word(name,3),",")>0 & namemiflag==1
replace namefrst=word(name,4) if strpos(word(name,3),",")>0 & namemiflag==1

// format for merge: 
replace namelast=trim(upper(namelast))
replace namefrst=trim(upper(namefrst))
	
ren namelast Namelast
ren namefrst Namefrst

gen idm=_n

count
local c=`r(N)'
reclink2 Namelast Namefrst class using  "${intstata}/ad-club-dat", ///
		idm(idm) idu(idu) gen(pmatch_ad) required(class) minscore(.8) npairs(1)
	
isid idm
count
assert `r(N)'==`c'

gen ad_club=_merge==3 
drop Namelast UNamelast Namefrst UNamefrst namemiflag idm pmatch_ad idu _merge Uclass

/* run check (optional)
preserve
collapse (sum) ad_club, by(class)

merge 1:1 class using `yearcounts'
keep if class>=1923 & class<=2015
su ad_club Ntotal
su ad_club Ntotal if class<=1980
su ad_club Ntotal if class>1980
gen share=ad_club/Ntotal
l
twoway (connect share class)
restore
*/