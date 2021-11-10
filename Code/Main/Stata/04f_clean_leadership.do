/*

04f_clean_leadership.do
(called from 04_clean_redbooks.do)

Purpose: clean and code college leadership activities
Inputs: keys/activity_leadership_key, codes/activity_leadership
Outputs: N/A

*/
preserve 
	* ingest keys
	import exc "$keys/activity_leadership_key.xlsx" , clear first
	keep code description
	ren description title

	tempfile akl
	save `akl' , replace

	* ingest coding
	insheet using  "$codes/activity_leadership.csv" , clear

	* merge on keys to get strings
	merge m:1 code using `akl' , keep(1 3) nogen

	* multiple entries per person -- go wide
	bys index (code) : gen j = _n

	foreach var in code title {
		ren `var' aclead`var'
	}

	reshape wide acleadtitle acleadcode, i(index) j(j)

	isid index
	
	compress
	tempfile acl
	save `acl' , replace
restore 

// merge on leadership data
merge 1:1 index using `acl' , nogen keep(1 3)

gen aclead=!mi(acleadcode1) // flag for any leadership position
drop acleadcode* acleadtitle*