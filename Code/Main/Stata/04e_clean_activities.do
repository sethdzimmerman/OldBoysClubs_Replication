/*

04e_clean_activities.do
(called from 04_clean_redbooks.do)

Purpose: cleans and codes college activities
Inputs: keys/activity_key, codes/activity_codes
Outputs: N/A

*/

* ingest keys and codes to merge on cleaned activity coding
preserve
	* ingest keys
	import exc "$keys/activity_key.xlsx" , clear first

	keep categorycode subcategorycode activitycode Category Subcategory ActivityTitle

	tempfile ak
	save `ak' , replace

	* ingest coding
	insheet using  "$codes/activity_codes.csv" , clear

	* merge on keys to get strings
	merge m:1 categorycode subcategorycode activitycode using `ak' , keep(1 3) nogen

	* multiple entries per person -- go wide
	bys index (categorycode subcategorycode activitycode) : gen j = _n

	foreach var in categorycode subcategorycode Category Subcategory {
		ren `var' ac`var'
	}

	reshape wide accategorycode acsubcategorycode activitycode ///
				acCategory acSubcategory ActivityTitle , i(index) j(j)

	isid index
	
	compress
	tempfile ac
	save `ac' , replace
restore

merge 1:1 index using `ac' , nogen keep(1 3)

* how many activities have we failed to code?
* some people list their scholarships (e.g., harvard club of maine scholarship)
* as an activity -- not counting these.
count if !mi(activities) & mi(accategorycode1) & strpos(lower(activities),"scholarship")==0
list activities if !mi(activities) & mi(accategorycode1) & strpos(lower(activities),"scholarship")==0

* gen indicators for "have activity #"
forv i = 1/11 {
	gen hac_`i' = !mi(accategorycode`i')
}

* any activity/count of activities: 
gen have_ac = hac_1==1
egen nac=rowtotal(hac_*)

* code activities
foreach var in dorm_com sports music redbook language social outdoors ///
	politics stem  drama pubs jewish military hs_club other_club ///
	catholic_club jewish_club christian_club {
	gen `var'=0
	
}

forv j=1/11 {
	replace dorm_com=1 if accategorycode`j'==1
	replace sports=1 if accategorycode`j'==2
	replace music=1 if accategorycode`j'==3
	replace redbook=1 if accategorycode`j'==4
	replace language=1 if accategorycode`j'==5
	replace outdoors=1 if accategorycode`j'==6
	replace politics=1 if accategorycode`j'==7
	replace drama=1 if accategorycode`j'==9
	replace pubs=1 if accategorycode`j'==10
	replace social=1 if accategorycode`j'==11
	replace catholic_club = 1 if accategorycode`j'==13 & acsubcategorycode`j'==4&activitycode`j'==2
	replace christian_club= 1 if accategorycode`j'==13 & acsubcategorycode`j'==4
	replace jewish_club = 1 if accategorycode`j'==12 
	// other category includes jewish clubs, stem clubs, military clubs, all of which 
	// have shares <0.005. 
	replace other_club=1 if accategorycode`j'==13 | accategorycode`j'==8 | accategorycode`j'==12 ///
		| accategorycode`j'==14 
}

// Classify sport types
preserve
	keep index year ac*code* ActivityTitle*
	reshape long accategorycode acsubcategorycode activitycode ActivityTitle , i(index) j(actn)

	ren accat* cat*
	ren acsub* sub*
	ren ActivityTitle sport_type

	tab cat
	tab subcat if cat == 2

	// Only sports
	keep if categorycode == 2
	assert !mi(activitycode)
	tab sport_type, sort
/*

                         Activity Title |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                                 rowing |      1,021       14.00       14.00
                             track team |        849       11.64       25.64
                         football squad |        736       10.09       35.73
                         baseball squad |        482        6.61       42.34
                    Intramural Football |        416        5.70       48.05
                                 Hockey |        414        5.68       53.72
                           soccer squad |        408        5.59       59.32
                         lacrosse squad |        407        5.58       64.90
                            Tennis Team |        317        4.35       69.24
                       basketball squad |        297        4.07       73.32
                     cross country team |        258        3.54       76.85
                         Wrestling Team |        253        3.47       80.32
*/
	// Most common sports
	gen rowing = subcat == 1 & activitycode == 5 
	gen track = subcat == 1 & activitycode == 13
	gen football = subcat == 1 & activitycode == 1
	gen baseball = subcat == 1 & activitycode == 2
	
	// Other common sports
	gen hockey = subcat == 1 & activitycode == 8
	gen soccer = subcat == 1 & activitycode == 12
	gen lacrosse = subcat == 1 & activitycode == 14 
	gen basketball= subcat == 1 & activitycode == 3
	gen university_sport = subcat == 1
	gen intramural_sport = subcat > 1

	// Bring back to student level
	collapse (max) rowing track football baseball basketball hockey soccer lacrosse *_sport ///
		, by(index)
	egen any_common_sport = rowmax(rowing track football baseball basketball)
	gen other_sport = any_common_sport == 0 
	drop any_common_sport

	tempfile sports
	save `sports', replace
restore

// Merge onto redbooks
merge 1:1 index using `sports', gen(_msports)
label var _msports "Merge with sports data"

// Make unconditional on any sport
foreach var of varlist rowing track football baseball basketball hockey soccer lacrosse *_sport {
    replace `var' = 0 if mi(`var') & _msports == 1
}

drop _msports

// generate activity private share and merge back on //
preserve

	* create index*activity level data
	
	keep index year accategorycode? acsubcategorycode? activitycode? private_wm finance manage_high
	
	reshape long accategorycode acsubcategorycode activitycode , i(index) 
	
	drop if mi(accategorycode)
	
	tempfile micro
	save `micro'	

restore