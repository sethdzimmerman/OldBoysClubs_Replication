/*

03f_harvard_vs_world.do
(called from 03_descriptive.do)

Purpose: produces output relating Harvard students to other people
Inputs: cleaned/census_rb_merged, intstata/all_indv_1940_desc
Outputs: tables/desc_tab_cen
	
*/

/*
	Harvard vs the world
	Produces:
		- Table B.10: Harvard sample compared to similarly aged men
*/


///////////////////////////////////////////////////////////
// Table B.10 - Harvard vs the World sample descriptives //
///////////////////////////////////////////////////////////

** Harvard v. the world (note uses program from Tables 2-3)

global rowlist8A "col41940 col51940 school1940_clean cen_doc cen_law lfp1940 nonfarm_selfemp1940 farm1940_clean incnonwg1940_clean poswage1940 incwage1940_clean topincwg1940 head ownershp1940_head valueh1940_head rent1940_head" 
global rowlist8B "dmetro_cc dist_share_farm1940_clean dist_share_nonfarm_selfemp1940 dist_share_incnonwg1940_clean dist_p50_incwage dist_share_topincwg1940 dist_p50_valueh dist_share_col41940 dist_share_harvard dist_N_men2737 "

use "$cleaned/census_rb_merged", clear

* read in only necessary variables and observations to speed run time

keep $rowlist8A $rowlist8B men2737 men2737_c1 men2737_c4 harvard head all year pf_wm // will only need rows, head, harvard, and samplist_cen when reconstruct full census file to include 27 year olds and have the 2737  
keep if year>=1920 & year<=1930

tempfile harvard_only
save `harvard_only'

use "$intstata/all_indv_1940_desc.dta", clear // 
keep $rowlist8A $rowlist8B  men2737 men2737_c1 men2737_c4 harvard head
su topincwg1940 if men2737==1 &  !mi(incwage1940_clean)
local rev_top=1-`r(mean)'
store_stat topcode_per_men2737 `rev_top' 1 "per"

append using `harvard_only'
drop if harvard==1 & all!=1 // duplicate copies of harvard records that are not from redbooks / class reports

* flag for harvard student from the cohorts with good census match rates
gen harvard_2030=harvard
replace harvard_2030=0 if year<1920 | year>1930
gen harvard_pf_2030=(harvard_2030==1 & pf_wm==1)

label var harvard "Harvard (1919-1935)"
label var harvard_2030 "Harvard"
label var harvard_pf_2030 "Private feeder"

label var men2737 "Men 27-37"
label var men2737_c1 "Men 27-37 w\/ col. $1+$"
label var men2737_c4 "Men 27-37 w\/ col. $4+$"
label var head "Household head"

label var col41940 "Yrs. of col. $4+$"
label var col51940 "Yrs. of col. $5+$"
label var school1940_clean "In school"
label var lfp1940 "In labor force"
label var nonfarm_selfemp1940 "Non-farm self emp."
label var farm1940_clean  "Farm"
label var incwage1940_clean "Wage income"
label var topincwg1940 "Wage inc. $5000+$"
label var poswage1940 "Has wage income"
label var incnonwg1940_clean "Non-wage inc.$50+$"
label var ownershp1940_head "Own home"
label var rent1940_head "Monthly rent"
label var valueh1940_head "Home value"

label var cen_doc "Cen. Occ.: Doc."
label var cen_law "Cen. Occ.: Law."

label var dmetro_cc "Central city"

label var dist_N_men2737 "Dist. N men 27-37"
label var dist_share_harvard "Dist. share Harvard"
label var dist_share_col41940 "Dist. share college 4+"
label var dist_p50_incwage "Dist. 50p wage income"
label var dist_share_topincwg1940 "Dist. share wage $5000+$"
label var dist_share_incnonwg1940_clean "Dist. share non-wage inc. $50+$"
label var dist_p50_valueh "Dist. 50p home value"
label var dist_share_nonfarm_selfemp1940 "Dist. share non-farm self emp."
label var dist_share_farm1940_clean  "Dist. share farm"

global samplist_cen "men2737 men2737_c1 men2737_c4 harvard_2030 harvard_pf_2030"  //head

desc_tab desc_tab_cen "$rowlist8A $rowlist8B" "$samplist_cen" 6 "ccccc"  

// drop the Harvard obs that don't match to census
drop if mi(harvard_2030)

gen incwage_with0=incwage1940_clean
replace incwage_with0=0 if mi(incwage1940_clean) 
su incwage_with0 if men2737==1, detail // p99 3945 
gen dp99_incwage_with0=(incwage_with0>=`r(p99)') 

gen dp99_incwage_if_pos=(incwage1940_clean>=4228) if !mi(incwage1940_clean)

foreach pop in men2737 men2737_c1 men2737_c4 harvard_2030 harvard_pf_2030 {
	su incwage1940_clean if `pop'==1
	store_stat inc_`pop' `r(mean)' 0
	su topincwg1940 if `pop'==1
	store_stat tc_`pop' `r(mean)' 1 "per"
	su dp99_incwage_if_pos if `pop'==1
	store_stat inc_p99_`pop'_if_pos `r(mean)' 1 "per"
	su dp99_incwage_with0 if `pop'==1
	store_stat inc_p99_`pop' `r(mean)' 1 "per"
}