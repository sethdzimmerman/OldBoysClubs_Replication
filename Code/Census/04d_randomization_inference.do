/*

04d_randomization_inference.do
(called from 04_random_variation.do)

Purpose: produces experimental inference tables
Inputs: cleaned/redbooks_res_sample
Outputs: intstata/resampled_nbds, intstata/data_random_inf, tables/out_tab_sr_rinf, 
	tables/out_tab_lr_rinf
	
*/

global nresamp=5000 // count of resamples for randomization inference; first rep is true specification
global resampflag=1 // set to 1 if you want to re-run the resampling

global ac_list "have_ac nac aclead social sports music zphat_ac"
global mr_list "final_tier2 fc_nottier2 hasty zphat_uac"
global grade_list "rg13_wm rg_listed1"
global oc_list "finance  doctor hed  law bus_agg teach gov art_pub zphat_oc" 

global club_list "any_social_main have_country_club have_gent_club have_frat_order any_honor have_prof_assoc have_hon_club zphat_cl"
global inc_list "incwage1940_clean topincwg1940 incnonwg1940_clean wage_index"

if $ACCESS == 0 {
	global inc_list ""
}

// set randomization seed for draws
set seed 1234567

use "$cleaned/redbooks_res_sample", clear

label var have_ac "Have any activity"
label var nac "N activities"
label var aclead "Activity leadership position"
label var social "Social"
label var sports "Sports"
label var music "Music"
label var zphat_ac "First-year activity index"
label var final_tier2 "Selective final club"
label var any_social_main "Any social club"
label var have_country_club "Country club"
label var have_gent_club "Gentleman's club"
label var have_frat_order "Fraternal order"
label var any_honor "Any honor/prof group"
label var have_prof_assoc "Prof. association"
label var have_hon_club "Honor society"
label var zphat_cl "Adult association index"
label var doctor "Medicine"
label var law "Law"
label var finance "Finance"
label var teach "Teach"
label var hed "Higher ed."
label var gov "Government"
label var art_pub "Art/pub"
label var bus_agg "Business"
label var hasty "Hasty Pudding Inst. 1770"
label var zphat_oc "Occupation index"

// reverse sign of rankgroup1 
replace rankgroup1=rankgroup1*-1

// only use census outcomes from years 1920-1930
foreach var in $inc_list{
  replace `var'=. if year<1920 | year>1930
}

gen rg13_wm = .
replace rg13_wm = 0 if rg1_wm != .
replace rg13_wm = 1 if rg1_wm == 1 | rg2_wm == 1 | rg3_wm == 1
label var rg13_wm "High grades (groups 1-3)"
label var rg_listed1 "Rank listed"

// sample descriptors: 
gen main_sample=!mi(pf_wm) & !mi(price_per)

reghdfe pf_wm $ivar, absorb(${rblock}) vce(cluster dorm_nbd_id)

keep if rblock_sample==1 & main_sample==1

// additional covariates: 

keep $rblock hs_wm  $ac_list $mr_list $grade_list $oc_list $club_list $inc_list rankgroup1 nbdranki dorm_nbd_id price_year_cap room_id pf_wm private_wm year
tempfile regdata
save `regdata'

assert "${ivar}"=="nbdranki"

// create dataset of resampled nbdranks
// resample *rooms* within *rblocks*
// create room dataset for resampling: 

if $resampflag==1 {
  keep room_id  price_year_cap nbdranki year 
  duplicates drop 
  isid room_id year // data should be identified at room X year level
  isid room_id price_year_cap // this is within-year variation so obs should be unique here as well. 
  drop year
  
  tempfile roomdat
  // generate true observation counter: 
  bys price_year_cap (room_id): gen id=_n // within price_year_cap, sort by room_id so initial order is the same each run

  forv j=1/$nresamp {
    if round(`j'/100)*100==`j' di "`j'" // display rep every 100 reps
    set seed `j'
    set sortseed `j'
    sort price_year_cap room_id
    
    // resample within price_year_cap: 
    gen r=uniform()
    if `j'==1 gen sr`j'=nbdranki
    if `j'>1 bys price_year_cap (r): gen sr`j'=nbdranki[id] 
    drop r

  }

  keep room_id sr*
  save "$intstata/resampled_nbds", replace
}
// 

// bring back regdat, add resampled: 
use `regdata', clear
merge m:1 room_id using  "${intstata}/resampled_nbds" // all should merge

compress
save "${intstata}/data_random_inf", replace

// run rinf program --- test: 

rinf "reghdfe zphat_ac nbdrank if pf_wm==1, absorb(${rblock} i.hs_wm) " "sr" bmain
drop bmain // test run

//
//
// create main output tables, embedding randomization inference program rinf and outputting p-values not SEs
//
//

////////////////////////////////////////////////////////////////////
// Tables A.16 and A.17: Peer effects with randomization inference //
////////////////////////////////////////////////////////////////////

//
// run program and output tables: 
//

** Make Table A.16: 
exp_table_rinf out_tab_sr_rinf rblock "i.hs_wm" "ac_list mr_list grade_list"


** Make Table A.17:
if $ACCESS == 1 {
	exp_table_rinf out_tab_lr_rinf rblock "i.hs_wm" "club_list oc_list inc_list"
}
if $ACCESS == 0 {
	exp_table_rinf out_tab_lr_rinf rblock "i.hs_wm" "club_list oc_list"
}