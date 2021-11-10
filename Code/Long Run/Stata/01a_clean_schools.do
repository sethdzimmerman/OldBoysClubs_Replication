/*

01a_clean_schools.do
(called from 01_clean_redbooks.do)

Purpose: cleans and codes high school information
Inputs: keys/lr_high_school_key, codes/long-run/high_school_codes
Outputs: N/A

*/

preserve
    * hs key 
    import exc using "$keys/lr_high_school_key" , first clear

    ren name schoolname

    gen private_feeder=inlist(schoolcode,1,3,4,5,6,8,10,22) 
	ren public public_feeder
    tempfile hk 
    save `hk' , replace

    ** hs codes **
    * some students list, e.g., "Groton and Exeter"
    * -> assign them to the more populous school
    insheet using "$codes/long-run/high_school_codes.csv" , clear

    gen n = 1
    collapse (rawsum) n , by(schoolcode)
    replace n = -n

    tempfile hn
    save `hn' , replace

    insheet using "$codes/long-run/high_school_codes.csv" , clear

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


// fix Andover/Exeter issue, where some schools are coded as both
replace schoolname2 = "" if high_school == "Exeter, Phillips Academy" | high_school == "Phillips Academy Exeter" | high_school == "Phillips Academy, Exeter"

foreach var in schoolcode2 public_feeder2 private2 private_feeder2 {
	
	replace `var' = . if high_school == "Exeter, Phillips Academy" | high_school == "Phillips Academy Exeter" | high_school == "Phillips Academy, Exeter"
	
	
}


// note: we have classifed about 60% of students by high school
// remaining high schools are either "true missing" with no data on the high school name
// or they are simply unclassified, which means they are sufficiently rare that we did not attempt to code. 
tab hc
drop hc

* private/public distinction:
gen have_hs_rec=!mi(high_school)


gen have_hs = !mi(schoolcode1)

gen private = private1==1 | private2==1 if have_hs==1
gen private_wm=private==1 if !mi(high_school) // includes unclassified schools; missing for non-labeled
gen private_feeder = private_feeder1==1 | private_feeder2==1 if !mi(high_school)
gen private_other = private
replace private_other = 0 if private_feeder == 1
gen public_feeder = 1-private if !mi(high_school)
gen nonfeeder = !mi(high_school) & mi(private) & mi(public_feeder)