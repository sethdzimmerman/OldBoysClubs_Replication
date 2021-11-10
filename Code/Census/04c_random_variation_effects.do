/*

04c_random_variation_effects.do
(called from 04_random_variation.do)

Purpose: produces experimental effects tables
Inputs: cleaned/redbooks_res_sample
Outputs: tables/out_tab_* (not including sr_rinf/lr_rinf), figures/hist_n_prox, 
	tables/altout_tab_*, figures/rfxall_`restrict', figures/rfxall_`restrict'_row*,
	intexcel/binres_`out', figures/binscat_`out', figures/binscat_fifty
	
*/

/*
	Produces Tables 6,7,A.7-15,B.16-20,B.25 and Figures 6,A.6,B.17
		- Table 6: Peer neighborhood effects on short-run outcomes
		- Table 7: Peer neighborhood effects on long-run outcomes
		- Figure 6: Key outcomes by decile of peer neighbhorhood price and high school type
		- Table A.7: Peer effects on additional outcomes
		- Table A.8, A.9: ...without occupancy controls
		- Table A.10 & A.11: ...without large HS controls
		- Table A.12 & A.13: ...with alternate private high school classifications
		- Table A.14 & A.15: ...excluding cohorts 1919-1921
		- Table B.16 & B.17: Entryway rank effects on short-run and long-run outcomes
		- Table B.18 & B.19: Nearest neighbor rank effects on short-run and long-run outcomes
		- Table B.20: Peer neighborhood effects on outcome-by-grade interactions for private feeder students
		- Table B.25: Peer neighborhood effects on major choice and stated career intent
		- Figure A.6: Peer effect estimates by tercile
		- Figure B.17: Histograms of group size for alternate spatial groupings	
*/

//////////////////////////
// Experimental effects //
//////////////////////////

global ac_list "have_ac nac aclead social sports music zphat_ac"
global mr_list "final_tier2 fc_nottier2 hasty zphat_uac"
global grade_list_main "rg13_wm rg_listed1" 
global oc_list "finance  doctor hed law  bus_agg zphat_oc" 
global oc_list_supp "bookkeep manage_high manage_low bus " 

global club_list "any_social_main have_country_club have_gent_club any_honor zphat_cl"
global inc_list "incwage1940_clean topincwg1940 incnonwg1940_clean  wage_index"   
global maj_intent_index_list "zphat_maj zphat_intent zphat_maj_intent fin_index"
global maj_list "econ_major stem_major humanities_major social_science_major double_major"
global intent_list "finance_intended bus_intended hed_ext_intended doctor_intended law_intended"

global club_list_app "have_frat_order have_prof_assoc have_hon_club"
global oc_list_app "teach gov art_pub"

if $ACCESS == 0 {
	global inc_list ""   
}

//
//
// run programs and output tables: 
//
//

// open up residential sample data: 
use "${cleaned}/redbooks_res_sample", clear

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

// format variables for output: 
// reverse sign of rankgroup1 
replace rankgroup1=rankgroup1*-1
replace rankgroup3=rankgroup3*-1

// only use census outcomes from years 1920-1930
foreach var in $inc_list{
	replace `var'=. if year<1920 | year>1930
}

// combine academic rank variables
gen rg13_wm = .
replace rg13_wm = 0 if rg1_wm != .
replace rg13_wm = 1 if rg1_wm == 1 | rg2_wm == 1 | rg3_wm == 1
label var rg13_wm "High grades (groups 1-3)"
label var rg_listed1 "Rank listed"

////////////////////////////////////////////////////////////////
// Tables 6 & 7: Peer effects on Short and Long Run Outcomes //
////////////////////////////////////////////////////////////////
// main specification on  1919-1935 sample
// baseline specification-- rblock +HS

*** Table 6: Peer effects on Short Run Outcomes
exp_table out_tab_sr rblock "i.hs_wm" "ac_list mr_list grade_list_main" nbdranki dorm_nbd_id 1919

*** Table 7: Peer effects on Long Run Outcomes
if $ACCESS == 1 {
	exp_table out_tab_lr rblock "i.hs_wm" "club_list oc_list inc_list" nbdranki dorm_nbd_id 1919
}
if $ACCESS == 0 {
	exp_table out_tab_lr rblock "i.hs_wm" "club_list oc_list" nbdranki dorm_nbd_id 1919
}

if $ACCESS == 1 {
/// Store numbers for text output: 
foreach pop in all pf npf {
	foreach var in have_ac aclead social final_tier2 finance any_social_main have_country_club rg_listed1 { 
		store_stat `pop'_`var' "${`pop'_`var'}" 1 "per"
		store_stat `pop'_`var'_se "${`pop'_`var'_se}" 1 "per"
		if "`var'"=="social" | "`var'"=="final_tier2" | "`var'"=="finance" | "`var'"=="any_social_main" | "`var'"=="rg_listed1"  {
			local `pop'_`var'_5 =${`pop'_`var'} /2
			local `pop'_`var'_se_5 =${`pop'_`var'_se} /2
			store_stat `pop'_`var'_5 ``pop'_`var'_5' 1 "per"
			store_stat `pop'_`var'_se_5 ``pop'_`var'_se_5' 1 "per"
		}
	}
	foreach var in nac zphat_ac zphat_uac zphat_cl zphat_oc  {
		store_stat `pop'_`var' "${`pop'_`var'}" 3
		store_stat `pop'_`var'_se "${`pop'_`var'_se}" 3
		
			local `pop'_`var'_5 =${`pop'_`var'} /2
			local `pop'_`var'_se_5 =${`pop'_`var'_se} /2
			store_stat `pop'_`var'_5 ``pop'_`var'_5' 2
			store_stat `pop'_`var'_se_5 ``pop'_`var'_se_5' 2
			if "`pop'"=="npf" & "`var'"=="zphat_oc" { // absolute value of shift down in oc index for npf students
			local `pop'_`var'_abs_5 =${`pop'_`var'} /2*-1
			store_stat `pop'_`var'_abs_5 ``pop'_`var'_abs_5' 2
				
			}
	}

	foreach var in wage_index { 
		local `pop'_`var'_5 =${`pop'_`var'} /2
		local `pop'_`var'_se_5 =${`pop'_`var'_se} /2
		store_stat `pop'_`var'_5 ``pop'_`var'_5' 0
		store_stat `pop'_`var'_se_5 ``pop'_`var'_se_5' 0
	}
}

// want all_zphat_ac as percentage of diff
foreach var in zphat_ac {
	su `var' if rblock_sample==1 & pf_wm==0
	local mean_`var'_npf `r(mean)'
	su `var' if rblock_sample==1 & pf_wm==1
	local diff_rb_`var' = `r(mean)' -`mean_`var'_npf'
	local all_perdiff_`var'= ${all_`var'} /`diff_rb_`var''
	store_stat all_perdiff_`var' `all_perdiff_`var'' 1 "per"
}

local npf_zphat_oc_abv=${npf_zphat_oc}*-1  // store abs val of negative coefs
store_stat npf_zphat_oc_abv `npf_zphat_oc_abv' 3

store_stat test_final_tier2 "${test_final_tier2}" 3
store_stat test_zphat_oc "${test_zphat_oc}" 3
store_stat test_any_social_main "${test_any_social_main}" 3

* sample means for rblock_sample
foreach var in have_ac aclead final_tier2 finance {
	su `var' if rblock_sample==1 
	store_stat mean_rb_`var' `r(mean)' 1 "per"
	if "`var'"=="finance"{
		su `var' if rblock_sample==1 & pf_wm==1
		store_stat mean_rb_`var'_pf `r(mean)' 1 "per"
	} 
}

foreach var in nac {
	su `var' if rblock_sample==1 
	store_stat mean_rb_`var' `r(mean)' 3
}

foreach var in any_social_main {
	su `var' if rblock_sample==1 
	store_stat perc_rb_`var' `r(mean)' 1 "per"
}

* difference pf npf in baseline
foreach var in zphat_ac zphat_oc final_tier2 finance social nac any_social_main {
	su `var' if rblock_sample==1 & pf_wm==0
	local mean_`var'_npf `r(mean)'
	su `var' if rblock_sample==1 & pf_wm==1
	local diff_rb_`var' = `r(mean)' -`mean_`var'_npf'
	store_stat diff_rb_`var' `diff_rb_`var'' 1 "per"
	local perdiff_`var'=${pf_`var'}/`diff_rb_`var''
	store_stat perdiff_`var' `perdiff_`var'' 1 "per"
	local perdiff_`var'_5 =`perdiff_`var''/2
	store_stat perdiff_`var'_5 `perdiff_`var'_5' 1 "per"
}


store_stat pf_topincwg1940_se "${pf_topincwg1940_se}" 1 "per"
su topincwg1940 if rblock_sample==1 & pf_wm==1
store_stat mean_rb_pf_tc `r(mean)' 1 "per"

// differ from baseline
foreach var in nac final_tier2 finance social any_social_main rg_listed1 {
	su `var' if rblock_sample==1 
	local permean_`var'_5 = (${all_`var'}/`r(mean)')/2
	store_stat permean_`var'_5 `permean_`var'_5' 1 "per"
	su `var' if rblock_sample==1 & pf_wm==1
	local permean_`var'_pf_5 = (${pf_`var'}/`r(mean)')/2
	store_stat permean_`var'_pf_5 `permean_`var'_pf_5' 1 "per"
	store_stat permean_`var'_pf_5_round `permean_`var'_pf_5' 0 "per" // rounded for abstract
}

}

/////////////////////////////////
// Table A.7
// other short run outcomes
////////////////////////////////

label var bookkeep "Accounting" 
label var manage_high "Senior management" 
label var manage_low "Low management" 
label var bus "Retail"
label var rankgroup1 "Class rank"
global APP1 "not_ssm"
global APP2 "rg1_wm rg2_wm rg3_wm rg4_wm rg5_wm rg6_wm rankgroup1"
global APP3 "$club_list_app"
global APP4 "$oc_list_app"
global APP5 "$oc_list_supp"

*** Table A.7:
exp_table out_tab_app rblock "i.hs_wm" "APP1 APP2 APP3 APP4 APP5" nbdranki dorm_nbd_id 1919

////////////////////////////////////////
// Tables A.14 and A.15
// run robustness on 1922-1935 sample
////////////////////////////////////////
global ac_list "have_ac nac aclead social sports music zphat_ac"
global mr_list "final_tier2 fc_nottier2 hasty zphat_uac"
global grade_list_main "rg13_wm rg_listed1"
global oc_list "finance  doctor hed law  bus_agg zphat_oc" 
global oc_list_supp "bookkeep manage_high manage_low bus " 

global club_list "any_social_main have_country_club have_gent_club any_honor zphat_cl"
global inc_list "incwage1940_clean topincwg1940 incnonwg1940_clean  wage_index"   
global maj_intent_index_list "zphat_maj zphat_intent zphat_maj_intent fin_index"
global maj_list "econ_major stem_major humanities_major social_science_major double_major"
global intent_list "finance_intended bus_intended hed_ext_intended doctor_intended law_intended"

global club_list_app "have_frat_order have_prof_assoc have_hon_club"
global oc_list_app "teach gov art_pub"

if $ACCESS == 0 {
	global inc_list ""   
}

preserve
	drop if year<1922

	// baseline specification-- rblock +HS
	** Make Table A.14
	exp_table out_tab_sr rblock "i.hs_wm" "ac_list mr_list grade_list_main" nbdranki dorm_nbd_id 1922
	
	* Make Table A.15
	if $ACCESS == 1 { 
		exp_table out_tab_lr rblock "i.hs_wm" "club_list oc_list inc_list" nbdranki dorm_nbd_id 1922
restore
	}
	if $ACCESS == 0 { 
		exp_table out_tab_lr rblock "i.hs_wm" "club_list oc_list" nbdranki dorm_nbd_id 1922
restore
	}


if $ACCESS == 1 {
	// IV specifications for text: 
	reghdfe final_tier2 nbdranki if pf_wm==1  , absorb(${rblock} i.hs_wm )  cluster(dorm_nbd_id) 

	reghdfe wage_index nbdranki if pf_wm==1  , absorb(${rblock} i.hs_wm )  vce(cluster dorm_nbd_id)


	ivreghdfe wage_index (final_tier2=nbdranki) if pf_wm==1  ///
		, absorb(${rblock} i.hs_wm )   cluster(dorm_nbd_id) 
	ivreghdfe incwage1940_clean (final_tier2=nbdranki)  ,  ///
		absorb(${rblock} i.hs_wm )   cluster(dorm_nbd_id) 
}

////////////////////////////////////////
//
// ADDITIONAL ROBUSTNESS TESTS: 
//
///////////////////////////////////////

// Preprocess residential data: 
use "${cleaned}/redbooks_res_sample", clear

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
replace rankgroup3=rankgroup3*-1

// only use census outcomes from years 1920-1930
foreach var in $inc_list{
	replace `var'=. if year<1920 | year>1930
}

// combine academic rank variables
gen rg13_wm = .
replace rg13_wm = 0 if rg1_wm != .
replace rg13_wm = 1 if rg1_wm == 1 | rg2_wm == 1 | rg3_wm == 1
label var rg13_wm "High grades (groups 1-3)"
label var rg_listed1 "Rank listed"

// Tables A.8 and A.9
// alternate rblock-- price X year only
exp_table out_tab_rob_sr rblock2 "i.hs_wm"  "ac_list mr_list grade_list_main" nbdranki dorm_nbd_id 1919
if $ACCESS == 1 {
	exp_table out_tab_rob_lr rblock2  "i.hs_wm" "club_list oc_list inc_list" nbdranki dorm_nbd_id 1919
}
if $ACCESS == 0 {
	exp_table out_tab_rob_lr rblock2  "i.hs_wm" "club_list oc_list" nbdranki dorm_nbd_id 1919
}

// Tables A.10 and A.11
// price and cap controls only (no HS)
exp_table out_tab_rob2_sr rblock "i.all" "ac_list mr_list grade_list_main" nbdranki dorm_nbd_id 1919
if $ACCESS == 1 {
	exp_table out_tab_rob2_lr rblock "i.all" "club_list oc_list inc_list" nbdranki dorm_nbd_id 1919
}
if $ACCESS == 0 {
	exp_table out_tab_rob2_lr rblock "i.all" "club_list oc_list" nbdranki dorm_nbd_id 1919
}

// alternate peer group definitions: 

// Tables B.16 and B.17
// large: 
exp_table out_tab_sr_large rblock "i.hs_wm" "ac_list mr_list grade_list_main" nbdranki_entryway entryway_nbd_id 1919
if $ACCESS == 1 {
	exp_table out_tab_lr_large rblock "i.hs_wm" "club_list oc_list inc_list" nbdranki_entryway entryway_nbd_id 1919
}
if $ACCESS == 0 {
	exp_table out_tab_lr_large rblock "i.hs_wm" "club_list oc_list" nbdranki_entryway entryway_nbd_id 1919
}

// Tables B.18 and B.19
// small: 
exp_table out_tab_sr_small rblock "i.hs_wm" "ac_list mr_list grade_list_main" nbdranki_nearest nearest_nbd_id 1919
if $ACCESS == 1 {
	exp_table out_tab_lr_small rblock "i.hs_wm" "club_list oc_list inc_list" nbdranki_nearest nearest_nbd_id 1919
}
if $ACCESS == 0 {
	exp_table out_tab_lr_small rblock "i.hs_wm" "club_list oc_list" nbdranki_nearest nearest_nbd_id 1919
}

// Table B.25: 
// Major and Intended Occupation
label var double_major "Double Major"
label var bus "Business"
label var stem_major "STEM/Eng."
label var econ_major "Economics"
label var humanities_major "Humanities"
label var social_science_major "Social Science"
foreach  var in finance doctor law bus {
	label var `var'_intended "`:var la `var''"
}
label var hed_ext_intended "Higher Ed."
label var zphat_maj_intent "Major + Intended Occ. index"
label var zphat_maj "Major index"
label var zphat_intent "Intended Occ. index"
label var fin_index "Finance index"

exp_table out_tab_major_intent rblock "i.hs_wm" "maj_intent_index_list maj_list intent_list" nbdranki dorm_nbd_id 1919

///////////////////////////////////////////////////////////////////////////
// Figure B.17: Histograms of group size for alternate spatial groupings //
///////////////////////////////////////////////////////////////////////////
twoway (hist n_dorm_nbd, color(blue%80) width(5) fraction), ///
	title("A. Peer neighborhoods") ytitle("Share of students") xtitle("Size of group") ///
	graphregion( color(white) ) xlab(0(10)60) ylab(0(.1).6) name(g1, replace)  nodraw

twoway (hist n_nearest_nbd, color(cranberry%80) width(5) fraction), ///
	title("B. Nearest neighbors only") ytitle("Share of students")  xtitle("Size of group") ///
	graphregion( color(white) )  xlab(0(10)60) ylab(0(.1).6) name(g2, replace) nodraw

twoway (hist n_entryway_nbd, color(green%80) width(5) fraction), ///
	title("C. Entire dorm or entryway") ytitle("Share of students")  xtitle("Size of group") ///
	graphregion( color(white) )  xlab(0(10)60) ylab(0(.1).6) name(g3, replace) nodraw

graph combine g1 g2 g3, scheme(s1color) xsize(10) ysize(13) rows(3)
graph export "${figures}/hist_n_prox.png", replace width(2400) 

// STATISTICS FOR TEXT: 

// rename these variables to follow scheme used in paper compiling
rename nearest_nbd small_nbd
rename entryway_nbd large_nbd
rename n_nearest_nbd n_small_nbd
rename n_entryway_nbd n_large_nbd
rename n_dorm_nbd n_best_nbd
rename mpi_entryway_nbd mpi_large_nbd
rename mpi_dorm_nbd mpi_best_nbd

foreach size in small large {
	gen has_`size'_prox=(dorm_nbd!=`size'_nbd)
	su has_`size'
	store_stat perc_diff_`size'_prox  "`r(mean)'" 0 per 
}
	
foreach size in small large best {
	su n_`size'_nbd, detail
	store_stat p50_n_`size'_prox  "`r(p50)'" 0 
	if "`size'"=="large" {
	 store_stat max_n_`size'_prox  "`r(max)'" 0 	
	}
}	

foreach size in large best {
	// compute within year total sum of squares: 
	reghdfe mpi_`size'_nbd, absorb(i.year)
	local tss_wy_`size'=`e(tss_within)'
}

di "`tss_wy_large'"
di "`tss_wy_best'"
local share_tss_large=`tss_wy_large'/`tss_wy_best'
store_stat perc_tss_large  "`share_tss_large'" 0 per 

// iqr of price for best and large averaged over years

foreach size in large best {
	local iqr_`size'=0
	local r9010_`size'=0
	forv y=1919/1935{
		su mpi_`size'_nbd , detail
		local iqr_`size'=`iqr_`size''+`r(p75)'-`r(p25)'
		local r9010_`size'=`r9010_`size''+`r(p90)'-`r(p10)'
	}
	local iqr_`size'=`iqr_`size''/17
	local r9010_`size'=`r9010_`size''/17

}

store_stat iqr_mpi_large "`iqr_large'" 0
store_stat r9010_mpi_large "`r9010_large'" 0
store_stat iqr_mpi_best "`iqr_best'" 0
store_stat r9010_mpi_best "`r9010_best'" 0

/////////////////////////////////////////////////
// Table A.12 and A.13: 
// alternate private HS categorization schemes 
////////////////////////////////////////////////

use "${cleaned}/redbooks_res_sample", clear

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

// format variables for output: 
// reverse sign of rankgroup1 
replace rankgroup1=rankgroup1*-1
replace rankgroup3=rankgroup3*-1

// only use census outcomes from years 1920-1930
foreach var in $inc_list{
	replace `var'=. if year<1920 | year>1930
}

// combine academic rank variables
gen rg13_wm = .
replace rg13_wm = 0 if rg1_wm != .
replace rg13_wm = 1 if rg1_wm == 1 | rg2_wm == 1 | rg3_wm == 1
label var rg13_wm "High grades (groups 1-3)"
label var rg_listed1 "Rank listed"

// generate alternate high school categories: 
// top 13 largest private  (all at least as big as smallest private feeder)		 
gen a1_pf_wm=inlist(schoolcode1,1,4,3,6,10,5,8,16,9,12,13,21,22)

// top 7 largest private (the private feeders larger than any other schools)
gen a2_pf_wm=inlist(schoolcode1,1,4,3,6,10,5,8)

** Make Table A.12
altexp_table altout_tab_sr rblock "i.hs_wm" "ac_list mr_list grade_list_main"

** Make Table A.13
if $ACCESS == 1 {
	altexp_table altout_tab_lr rblock "i.hs_wm" "club_list oc_list inc_list"
}
if $ACCESS == 0 {
	altexp_table altout_tab_lr rblock "i.hs_wm" "club_list oc_list"
}

///////////////////////////////////
// Table B.20: OUTCOMES JOINT WITH RANK GROUP: 
///////////////////////////////////
** Outcomes joint with rankgroup

use "${cleaned}/redbooks_res_sample", clear

label var any_social_main "Any social club"
label var have_prof_assoc "Prof. Association"
label var doctor "Medicine"
label var law "Law"
label var finance "Finance"
label var hed "Higher ed."
label var final_tier2 "Selective final club"
label var hasty "Hasty Pudding Inst. 1770"

// only use census outcomes from years 1920-1930
foreach var in $inc_list{
	replace `var'=. if year<1920 | year>1930
}

// define high grade as 1-4 (so more like not low grade) because pf_wm students generally do so poorly
gen higrade=rankgroup1<=4
replace higrade=. if year==1919

foreach var in hasty final_tier2 finance doctor law hed any_social_main have_prof_assoc {
	gen hg_`var'=`var'*higrade
	gen lg_`var'=`var'*(1-higrade)
	reghdfe hg_`var' nbdranki if pf_wm==1, absorb($rblock i.hs_wm) vce(cluster dorm_nbd_id)
	reghdfe lg_`var' nbdranki if pf_wm==1, absorb($rblock i.hs_wm) vce(cluster dorm_nbd_id)
}


global mr_list_hg "hasty final_tier2"
global oc_list_hg "finance doctor law hed" 
global club_list_hg "any_social_main have_prof_assoc"

** Make Table B.20
out_by_higrade_table higrade_tab "mr_list_hg oc_list_hg club_list_hg"

** Store statistics for text
store_stat hg_final_tier2 $b_hg_final_tier2 1 "per"
store_stat hg_finance $b_hg_finance 1 "per"
store_stat hg_hed_rev $b_hg_hed_rev 1 "per"
store_stat hg_doctor_rev $b_hg_doctor_rev 1 "per"

//
//
// FIGURE A.6: effects by tercile: 
//
//

// sent N quantiles for graphs: 
global q=3 

cap drop nbdqx
xtile nbdqx=nbdranki, nq($q)

 // MAKE GRAPHS: 
foreach restrict in 1919 { 
	use "${cleaned}/redbooks_res_sample", clear
	label var have_ac "Have any activity"
	label var nac "N activities"
	label var social "Social"
	label var any_social_main "Any social club"
	label var any_honor "Any honor/prof group"
	label var zphat_cl "Adult association index"
	label var finance "Finance"
	label var zphat_oc "Occupation index"
	label var final_tier2 "Selective final club"
	label var finance "Finance"
	
	if `restrict'==1922{
		drop if year<1922
	}

	// only use census outcomes from years 1920-1930
	foreach var in $inc_list{
		replace `var'=. if year<1920 | year>1930
	}

	tgraph nac 3
	tgraph social 3

	su y1 if _n==3
	store_stat terc3_social_pf "`r(mean)'" 1 per 
	su y2 if _n==3
	store_stat terc3_social_npf "`r(mean)'" 1 per 

	tgraph zphat_ac 3

	tgraph final_tier2 3
	su y1 if _n==3
	store_stat terc3_final_tier2_pf "`r(mean)'" 1 per 
	su y2 if _n==3
	store_stat terc3_final_tier2_npf "`r(mean)'" 1 per 
	tgraph finance 3
	su y1 if _n==3
	store_stat terc3_finance_pf "`r(mean)'" 1 per 
	su y2 if _n==3
	store_stat terc3_finance_npf "`r(mean)'" 1 per 
	tgraph zphat_oc 3

	tgraph any_social_main 3
	su y1 if _n==3
	store_stat terc3_any_social_main_pf "`r(mean)'" 1 per 
	su y2 if _n==3
	store_stat terc3_any_social_main_npf "`r(mean)'" 1 per 
	tgraph any_honor 3
	tgraph zphat_cl  3

	if $ACCESS == 1 {
		label var topincwg1940 "Wage inc. 5000+"
		label var poswage1940 "Has wage income"
		label var incnonwg1940_clean "Non-wage inc. 50+"

		tgraph incwage1940_clean 3
		tgraph topincwg1940 3
		tgraph incnonwg1940_clean  3

		tgraph wage_index  3
		//gzphat_ac
		
		** Make Figure A.6
		grc1leg  gnac gsocial  gfinal_tier2 gfinance gzphat_oc  ///
		gany_social_main gany_honor gzphat_cl gwage_index ///
		gincwage1940_clean gtopincwg1940 gincnonwg1940_clean ///
			, schem(s1color) rows(4) ///
			xcommon  name(g4, replace) //ycommon
			graph display g4 , xsize(14) ysize(18)
		graph export "${figures}/rfxall_`restrict'.png", replace width(2400)	 
	}

	if $ACCESS == 0 {
			grc1leg  gnac gsocial  gfinal_tier2 gfinance gzphat_oc  ///
		gany_social_main gany_honor gzphat_cl ///
			, schem(s1color) rows(4) ///
			xcommon  name(g4, replace) //ycommon
			graph display g4 , xsize(14) ysize(18)
		graph export "${figures}/rfxall_`restrict'.png", replace width(2400)	 	
	}
	
	grc1leg  gnac gsocial gfinal_tier2 ///
		, schem(s1color) rows(1) ///
		xcommon  name(g4, replace) //ycommon
		graph display g4 , xsize(14) ysize(6)
	graph export "${figures}/rfxall_`restrict'_row1.png", replace width(2400)

	grc1leg  gany_social_main gfinance gzphat_oc  ///
		, schem(s1color) rows(1) ///
		xcommon  name(g4, replace) //ycommon
		graph display g4 , xsize(14) ysize(6)
	graph export "${figures}/rfxall_`restrict'_row2.png", replace width(2400)
	
	if $ACCESS == 1 {
		grc1leg   gany_honor gzphat_cl gincwage1940_clean ///
			, schem(s1color) rows(1) ///
			xcommon  name(g4, replace) //ycommon
			graph display g4 , xsize(14) ysize(6)
		graph export "${figures}/rfxall_`restrict'_row3.png", replace width(2400)

		
		grc1leg  gtopincwg1940 gincnonwg1940_clean gwage_index  ///
			, schem(s1color) rows(1) ///
			xcommon  name(g4, replace) //ycommon
			graph display g4 , xsize(14) ysize(6)
		graph export "${figures}/rfxall_`restrict'_row4.png", replace width(2400)
	}
}

////////////////////////////////////////////////////////////////////
// Figure 6: BINSCATTERS OF TREATMENT EFFECT //
///////////////////////////////////////////////////////////////////
use "${cleaned}/redbooks_res_sample", clear
replace rankgroup1=(7-rankgroup1) // REVERSE CODE RANK GROUP

label var any_social_main "Adult social club"
label var zphat_oc "Occupation index"
label var final_tier2 "Selective final club"
label var rankgroup1 "Class rank year 1"

lab var any_social_main "Adult social club"
gen fitrank = .
forv j=0/1 {
	reghdfe nbdranki if pf_wm==`j', absorb(price_year_cap i.hs_wm) resid
	predict fitrank`j' if e(sample), resid
	replace fitrank=fitrank`j' if e(sample)
}

foreach out in final_tier2 rankgroup1 any_social_main zphat_oc {
	preserve
		gen fity=. 
		gen residy=.
		forv j=0/1 {
			reghdfe `out' if pf_wm==`j', absorb(price_year_cap i.hs_wm) resid
			predict fity`j' if e(sample), resid
			su `out' if e(sample)
			replace residy=fity`j'  if e(sample)
			replace fity=fity`j' + `r(mean)' if e(sample)
		}
		if "`out'"=="final_tier2" local letter="A."
		if "`out'"=="rankgroup1" local letter="B."
		if "`out'"=="any_social_main" local letter="C."
		if "`out'"=="zphat_oc" local letter="D."
		binscatter fity fitrank, by(pf_wm) nbins(10) reportreg ///
		scheme(s1color) colors($c_pf $c_npf) msymbol(Sh C) xlabel(-.3(.1).3, labsize(small)) ///
		ylabel(,labsize(small)) xtitle("Neighborhood price rank",size(small)) ///
		ytitle("Conditional mean",size(small)) title("`letter' `:var label `out''",size(small)) ///
		legend(order(1 "Other high school" 2 "Private feeder") size(*.6)) ///
		savedata("$intexcel/binres_from_Census_step04c_including_do_files/binres_`out'") replace
		su fitrank
		
		local title_str = "`:var la `out''"
		
		// Make twoway plot
		insheet using "$intexcel/binres_from_Census_step04c_including_do_files/binres_`out'.csv", clear
		sort fitrank_by1
		gen min = _n == 1
		gen max = _n == _N
		
		* Get coefficients of fitted line
		forv j = 1/2{
			qui su fitrank_by`j' if min == 1
			global min_x`j' = `r(mean)'
			qui su fitrank_by`j' if max == 1
			global max_x`j' = `r(mean)'
			
			* Get linear fit
			reg fity_by`j' fitrank_by`j', r
			global cutoff`j' = _b[_cons]
			global slope`j' = _b[fitrank_by`j']		
		}
		
		* Min and max of horizontal axis
		global min = min($min_x1, $min_x2 )
		global max = max($max_x1, $max_x2 )
		
		* Vertical positions of fitted line on arg min and arg max
		global min_y1 = $cutoff1 + $slope1 * $min_x1
		global min_y2 = $cutoff2 + $slope2 * $min_x2
		global max_y1 = $cutoff1 + $slope1 * $max_x1
		global max_y2 = $cutoff2 + $slope2 * $max_x2
		
		* Vertical distance at those points
		global min_diff = round($min_y2 - $min_y1, 0.001)
		global max_diff = round($max_y2 - $max_y1, 0.001)
		
		* Vertical position of group 2 line end
		global min_ypos2 = $min_y1 + $min_diff
		global max_ypos2 = $max_y1 + $max_diff

		* Vertical position of text
		global min_textpos = $min_y1 + $min_diff /2
		global max_textpos = $max_y1 + $max_diff /2

		twoway (scatter fity_by1 fitrank_by1, msym(Sh) msize(medlarge) col($c_npf ) ) ///
			(function y=$cutoff1 + $slope1 * x ///
				, range($min $max ) col($c_npf )) ///
			(scatter fity_by2 fitrank_by2, msym(C) msize(medlarge) col($c_pf ) fcol(${c_pf}%40)) ///
			(function y=$cutoff2 + $slope2 * x ///
				, range($min_x1 $max_x1 ) col($c_pf )) ///	
			(pci $min_y1 $min_x1 $min_ypos2 $min_x1 , lpat(shortdash) lwidth(thin) col(gray)) ///
			(pci $max_y1 $max_x1 $max_ypos2 $max_x1 , lpat(shortdash) lwidth(thin) col(gray)) , ///
			text($min_textpos $min_x1 "Diff: $min_diff", place(se) size(vsmall)) ///
			text($max_textpos $max_x1 "Diff: $max_diff", place(sw) size(vsmall)) ///
			scheme(s1color) xlabel(-.3(.1).3, labsize(small)) ///
			ylabel(,labsize(small)) xtitle("Neighborhood price rank",size(small)) ///
			ytitle("Conditional mean",size(small)) title("`letter' `title_str'",size(small)) ///
			legend(order(1 "Other high school" 3 "Private feeder") size(*.8)) ///
			name(g`out', replace)
		graph display g`out', xsize(4) ysize(4)
		graph export "$figures/binscat_`out'.png", as(png) width(2400) replace
		
	restore
}

grc1leg gfinal_tier2 grankgroup1 gany_social_main gzphat_oc , ///
	scheme(s1color) rows(2) name(gfity, replace) 
	graph display gfity, xsize(50) ysize(50)
graph export "${figures}/binscat_fity.png", width(2400) replace

graph drop _all