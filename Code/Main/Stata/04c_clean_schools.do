/*

04c_clean_schools.do
(called from 04_clean_redbooks.do)

Purpose: cleans and codes high school information
Inputs: keys/high_school_key, codes/high_school_codes
Outputs: N/A

*/

preserve
    * hs key 
    import exc using "$keys/high_school_key" , first clear

    ren name schoolname

	gen private=inlist(schoolcode,1,3,4,5,6,7,8,9,10,12,13,14,16,17,18,20,21,22,/*
      */ 24,25,26,27,29,30,31,44, 45,46,47,48,49,50,51,52,54,55,56,57,59,60,61,62,63,65,66,68,69,70,72,73,74,75,77,78,80,83,84,85,88,92,97,104,105,106,109,112,113,114) 

	gen public_feeder=1-private
    gen private_feeder=inlist(schoolcode,1,3,4,5,6,8,10,22) 

    tempfile hk 
    save `hk' , replace

    ** hs codes **
    * some students list, e.g., "Groton and Exeter"
    * -> assign them to the more populous school
    insheet using "$codes/high_school_codes.csv" , clear

    gen n = 1
    collapse (rawsum) n , by(schoolcode)
    replace n = -n

    tempfile hn
    save `hn' , replace

    insheet using "$codes/high_school_codes.csv" , clear

    merge m:1 schoolcode using `hn' , nogen keep(1 3)

    * merge on school names
    merge m:1 schoolcode using `hk' , nogen keep(1 3) keepusing(schoolname private* public*)

    bys index (n) : gen hsn = _n // place multiple hs students at bigger school
    drop n

    reshape wide schoolcode schoolname private private_feeder public_feeder ///
        , i(index) j(hsn) 

    isid index

    tempfile hc 
    save `hc' , replace
restore

merge 1:1 index using `hc' , keep(1 3) gen(hc)

// note: we have classifed about 60% of students by high school
// remaining high schools are either "true missing" with no data on the high school name
// or they are simply unclassified, which means they are sufficiently rare that we did not attempt to code. 
tab hc
drop hc

* private/public distinction:
gen have_hs = !mi(schoolcode1) 

gen private = private1==1 | private2==1 if have_hs==1
gen private_wm=private==1 if !mi(high_school) // includes unclassified schools; missing for non-labeled

gen private_feeder = private_feeder1==1 | private_feeder2==1 if !mi(high_school)
gen public_feeder = 1-private if !mi(high_school)