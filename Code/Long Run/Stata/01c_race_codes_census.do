/*

01c_race_codes_census.do
(called from 01_clean_redbooks.do)

Purpose: clean race (from name) variables
Inputs: raw/Other/names-race-eth/Names_2010Census
Outputs: N/A

*/

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
	
// save file you working with: 
tempfile rb
save `rb'

// insheet 2010 census name file: 
insheet using  "$raw/Other/names-race-eth/Names_2010Census.csv", comma names clear

// basic formatting: 
count
isid name
destring pct*, replace force

// classify names with 80% shares latino, asian, or black as names in the relevant category
gen hispanic_sn=pcthispanic>=80 if !mi(pcthispanic)
gen asian_sn=pctapi>=80 if !mi(pctapi)
gen black_sn=pctblack>=80 if !mi(pctblack)

keep name hispanic_sn asian_sn black_sn
ren name namelast
tempfile names
save `names'

// open up harvard data file: 
use `rb', clear

// merge on name record by last name: 
merge m:1 namelast using `names', keep(match master) nogen

// set racial/ethnic name variables to zero if missing
// this is a variable that says "we can identify your name as one in this group"
foreach var in hispanic_sn asian_sn black_sn {
	replace `var'=0 if mi(`var')
	
}

// add hispanic surnamed individuals to hispanic category
replace hispanic=1 if hispanic_sn==1 &have_race==1

tabstat hispanic_sn asian_sn black_sn, by(year)
drop namelast namefrst  namemiflag 