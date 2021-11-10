/*

03b_harvard_sr_lr_desc.do
(called from 03_descriptive.do)

Purpose: produces Harvard related output
Inputs: cleaned/census_rb_merged
Outputs: tables/desc_tab_sr, tables/desc_tab_sr_app, tables/desc_tab_lr,
	tables/desc_tab_lr_app, tables/desc_tab_sr_sib, tables/desc_tab_lr_sib 
	
*/


/*
    Produce Tables 2/A.2/A.5,3/A.3, B.12 and B.13:
		- Table 2/A.2/A.5: Family background and college outcomes for Harvard students
		- Table 3/A.3: Adult outcomes for Harvard students
		- Table B.12: Brothers sample description: background and college outcomes
		- Table B.13: Brothers sample description: adult outcomes
				
*/

/// Prepare Data

use "$cleaned/census_rb_merged", clear

label var aclead "Activity leadership position" 
label var doctor "Medicine"
label var law "Law"
label var finance "Finance"
label var manage_high "Senior management" 
label var manage_low "Low management" 
label var teach "Teach"
label var hed "Higher ed."
label var gov "Government"
label var art_pub "Art/pub"
label var final_tier2 "Selective final club"
label var from_MA "From MA"
label var from_NY "From NY"
label var harvard_brother "Have Harvard brother"
label var harvard_father "Have Harvard father"
label var pf_wm "Private feeder"
label var hasty "Hasty Pudding"
label var all "All"
label var private_wm "Any private high school"
label var public_feeder_wm "Any public feeder"
label var have_hs_rec "Have high school data"
label var have_campus_address "Have address data"
label var oncampus "Live on campus"
label var roomatts "Have room attributes"
label var price_per "Room price per occupant (\\\$)"
label var have_ac "Have any activity"
label var nac "N activities"
label var have_social_club "Have soc. club"
label var sports "Sports"
label var music "Music" 
label var social "Social"
label var zphat_ac "First-year activity index"
label var zphat_oc "Occupation index"
label var final_club "Any final club"
label var zphat_uac "Upper-year club index"
label var mp_dorm_nbd "Peer neighborhood price (\\\$)"                  
label var zphat_cl "Adult association index"
label var any_social_main "Any social club"
label var have_country_club "Country club"
label var have_gent_club "Gentleman's club"
label var have_frat_order "Fraternal order"
label var any_honor "Any honor/prof group"
label var bookkeep "Accounting" 
label var bus "Retail"
label var npf_wm "Non-private"
label var rg_notlisted1 "Not ranked"
gen final_tier2_HEAD = final_tier2
label var final_tier2_HEAD "Sel. Fin. Club"

global samplist "all pf_wm npf_wm hasty final_tier2_HEAD" 

if $ACCESS == 1 {
	// name indicators: 
	gen jewish_name=jewish_index>=0.7 if !mi(jewish_index)
	gen cath_name=cath_index>=0.7 if !mi(cath_index)
	gen oc_name=oldMA_lnindex>=0.7 if !mi(oldMA_lnindex)

	label var jewish_name "Jewish name"
	label var cath_name "Catholic name"
	label var oc_name "Colonial name"
}

gen nbdranki_for_p25=nbdranki
label var nbdranki_for_p25 "25th pctile neighborhood rank"
gen nbdranki_for_p75=nbdranki
label var nbdranki_for_p75 "75th pctile neighborhood rank"
cap gen not_ssm=(redbook==1 | outdoors==1 | dorm_com==1 |  politics==1 | politics==1 | language==1 | drama==1 | pubs==1 | other_club==1 )
label var not_ssm "Other activities"

// want to present some availability conditional on class report link:

gen have_occ_if_cr=have_occ
replace have_occ_if_cr=. if has_pid!=1
label var have_occ_if_cr "Have occupation"

// combine academic rank variables
gen rg13 = .
replace rg13 = 0 if rg1 != .
replace rg13 = 1 if rg1 == 1 | rg2 == 1 | rg3 == 1
label var rg13 "High grades (groups 1-3)"

/////////////////////////////////////
/// Table 2 and A.2 and A.5 -- Short Run Outcomes ///
/////////////////////////////////////
** columns All; Private feeder; all non-pf; public feeder
* Panel A: non-census background
* Panel B: campus location
* Panel C: census background
* Panel D: Grades
* Panel E: Freshmen activities (any, count, leadership, social, sports)
* Panel F:Upper-year social clubs  

// rows: 
global rowlist_srA "private_wm pf_wm  public_feeder_wm harvard_father harvard_brother jewish_name cath_name oc_name"  
global rowlist_srB "comb_gen12_immg_eese preH_f_cen_doc preH_f_cen_law" 
global rowlist_srC "oncampus price_per_student mp_dorm_nbd nbdranki_for_p25 nbdranki_for_p75"  
global rowlist_srD1 "rg13 rg_notlisted1"
global rowlist_srD3 "rankgroup3 rg_notlisted3"
global rowlist_srE "have_ac nac aclead sports social music zphat_ac" // i
global rowlist_srF "hasty final_tier2 final_club zphat_uac" //  
global rowlist_sr_appA "have_hs_rec from_MA from_NY"
global rowlist_sr_appB "has_census_preH preH_f_has_cen_occ"
global rowlist_sr_appC "have_campus_address roomatts"
global rowlist_sr_appD "rg1 rg2 rg3 rg4 rg5 rg6"
global sibling = 0

if $ACCESS == 0 {
	
	global rowlist_srA "private_wm pf_wm  public_feeder_wm harvard_father harvard_brother"    
	global rowlist_srB "" 
	global rowlist_sr_appB ""
	
}

// set childhood census data to missing in 1934-36:
foreach var in $rowlist_srB $rowlist_sr_appB {
	replace `var'=. if  year<1920 | year>1933
}
// set room attribute data to missing in 1926 when they are not reproted:
foreach var in $rowlist_srC $rowlist_sr_appC {
	replace `var'=. if year==1926
}

// set grades to missing in 1919
foreach var in $rowlist_srD1 $rowlist_srD3 $rowlist_sr_appD {
	replace `var'=. if year==1919
}
// set uyclubs to missing in 1935
foreach var in $rowlist_srF {
	replace `var'=. if year==1935
}

// Make Short-Run Table (Table 2)
desc_tab desc_tab_sr "$rowlist_srA $rowlist_srB $rowlist_srC $rowlist_srD1 $rowlist_srE $rowlist_srF" "$samplist" 5 "ccccc" 

// Make Appendix Table (Table A.2)
desc_tab desc_tab_sr_app "$rowlist_sr_appA $rowlist_sr_appB $rowlist_sr_appC $rowlist_sr_appD" "$samplist" 5 "ccccc" 

// Make Randomized Appendix Table (Table A.5)
desc_tab desc_tab_sr_randomized "$rowlist_srA $rowlist_srB $rowlist_srC $rowlist_srD1 $rowlist_srE $rowlist_srF" "all rblock_sample" 2 "cc" 

/////////////////////////////////////
/// Table 3 and Table A.3 -- Long Run Outcomes ///
/////////////////////////////////////
** columns All; Private feeder; all non-pf; public feeder
* Panel A: Adult associations
* Panel B: Occupations
* Panel C: Adult Census

global rowlist_lrA "any_social_main have_country_club have_gent_club any_honor zphat_cl" 
global rowlist_lrB "have_occ_if_cr finance bookkeep doctor law hed zphat_oc" 
global rowlist_lrC "school1940_clean lfp1940 incwage1940_clean poswage1940 incnonwg1940_clean topincwg1940" 
global rowlist_lr_appA "have_frat_order"
global rowlist_lr_appB "teach gov art_pub manage_high manage_low bus "

if $ACCESS == 0{
	
	global rowlist_lrC = ""
	
}

// set adult census data to missing unless in 1920-30:
foreach var in $rowlist_lrC {
	replace `var'=. if  year<1920 | year>1930
}  

// Make Long-Run Table (Table 3)
desc_tab desc_tab_lr "$rowlist_lrA $rowlist_lrB $rowlist_lrC" "$samplist" 5 "ccccc"

// Make Long-Run Appendix Table (Table A.3)
desc_tab desc_tab_lr_app "$rowlist_lr_appA $rowlist_lr_appB" "$samplist" 5 "ccccc"

//////////////////////////////
/// store numbers for text ///
//////////////////////////////

if $ACCESS == 1 {

	foreach var in all private_wm pf_wm npf_wm public_feeder_wm {
		su `var' 
		store_stat N_`var' "`r(sum)'"   
		store_stat perc_`var' "`r(mean)'"  0 per
	}
	gen pf_if_res=pf_wm
	replace pf_if_res=. if rblock_sample!=1
	gen notpriv_if_res=(1-private_wm)
	replace notpriv_if_res=. if rblock_sample
	gen roomatts_if_campus=roomatts
	replace roomatts_if_campus=. if oncampus!=1
	foreach var in harvard_brother roomatts_if_campus pf_if_res notpriv_if_res{
		su `var' 
		store_stat perc_`var' "`r(mean)'"  0 per
	}

	gen preH_f_cen_doclaw=preH_f_cen_doc+preH_f_cen_law

	foreach var in from_MA from_NY harvard_father harvard_brother has_census_preH preH_N_emp ///
		comb_gen12_immg_eese preH_f_has_cen_occ preH_f_cen_doclaw price_per_student  ///
		mp_dorm_nbd nbdranki pq have_ac nac aclead sports social zphat_ac hasty final_tier2 ///
		final_club roomatts oncampus jewish_name cath_name oc_name ///
		finance incwage1940_clean incnonwg1940_clean topincwg1940 {
		gen `var'_npf=`var'
		replace `var'_npf=. if npf_wm==0 | mi(npf_wm)	
		gen `var'_pf=`var'
		replace `var'_pf=. if pf_wm==0 | mi(pf_wm)	
		gen `var'_pub=`var'
		replace `var'_pub=. if public_feeder_wm==0 | mi(public_feeder_wm)
		foreach hs_var in `var' `var'_npf `var'_pf `var'_pub	{
			su `hs_var'   
			local mean_`hs_var' `r(mean)'
			if "`var'"!="preH_N_emp" & "`var'"!="nac" & "`var'"!="zphat_ac" & "`var'"!="zphat_uac" ///
				& "`var'"!="price_per" & "`var'"!="mp_dorm_nbd" & "`var'"!="pq"  & "`var'"!="nbdranki" {
				store_stat perc_`hs_var' "`r(mean)'" 1 per 
			}
			if "`var'"=="preH_N_emp" | "`var'"=="nac" {
				store_stat mean_`hs_var' "`r(mean)'" 2
			}
			if "`var'"=="price_per_student" | "`var'"=="mp_dorm_nbd" | strpos("`var'","incwage") > 0{
				store_stat mean_`hs_var' "`r(mean)'" 0
			}
			if  "`var'"=="zphat_ac" | "`var'"=="zphat_uac" | "`var'"=="pq" | "`var'"=="nbdranki" {
				store_stat mean_`hs_var' "`r(mean)'" 2
			}
			if "`var'"=="nbdranki" | "`var'"=="pq" { 
				su `hs_var', detail
				store_stat p25_`hs_var' "`r(p25)'" 2
				store_stat p75_`hs_var' "`r(p75)'" 2
			}
		}
		if "`var'"=="have_ac" | "`var'"=="sports" | "`var'"=="social" {
			local ratio_npf_`var'=`mean_`var'_pf'/`mean_`var'_npf'
			store_stat ratio_npf_`var' `ratio_npf_`var'' 1 // times as likely
		}
		drop `var'_npf `var'_pf `var'_pub
	}

	// difference in price ranks (own and nbd)
	foreach var in pq nbdranki {
		local diffmean_`var'= `mean_`var'_pf' - `mean_`var'_npf' 
		store_stat diffmean_`var' "`diffmean_`var''" 0 "per"
	}

	// pf-npf gap as percent of npf
	foreach var in finance incwage1940_clean incnonwg1940_clean topincwg1940  {
		local diffper_`var'= (`mean_`var'_pf' - `mean_`var'_npf')/ `mean_`var'_npf'
		store_stat diffper_`var' "`diffper_`var''" 0 "per"
	}

	// group together top two rank groups
	gen rg12=rg1
	replace rg12=1 if rg2==1

	foreach var in rg12 rg6 {
		su `var' if pf_wm==1
		local `var'_pf `r(mean)'
		su `var' if pf_wm==0
		if "`var'"=="rg12"{
			local ratio_npf_rg12=(`r(mean)'-`rg12_pf')/`r(mean)' //percent less likely
		}

		if "`var'"=="rg6"{
			local ratio_npf_rg6=(`rg6_pf'-`r(mean)')/`r(mean)' //percent more likely
		}
		store_stat ratio_npf_`var' `ratio_npf_`var'' 0 "per"	
	}
	
	su rg13 if pf_wm==1
	local rg13_pf `r(mean)'
	sum rg13 if pf_wm==0
	local ratio_pf_rg13=(`rg13_pf')/`r(mean)'
	store_stat ratio_pf_rg13 `ratio_pf_rg13' 0 "per"	
	
	su rg13 if final_tier2==1
	local rg13_t2 `r(mean)'
	sum rg13 if all==1
	local ratio_t2_rg13=(`rg13_t2')/`r(mean)'
	store_stat ratio_t2_rg13 `ratio_t2_rg13' 0 "per"	

	su incwage1940_clean if rg6==1 & final_tier2==1 & year>=1920 & year<=1930
	local wage_rg6_t2 `r(mean)'
	su incwage1940_clean if rg12==1 & final_tier2==0 & year>=1920 & year<=1930
	local ratio_wage=(`wage_rg6_t2'-`r(mean)')/`r(mean)' // percent more
	store_stat ratio_wage_rg6t2_rg12nt2 `ratio_wage' 0 "per"	

	su topincwg1940 if rg6==1 & final_tier2==1 & year>=1920 & year<=1930
	local tc_rg6_t2 `r(mean)'
	su topincwg1940 if rg12==1 & final_tier2==0 & year>=1920 & year<=1930
	local ratio_tc=`tc_rg6_t2'/`r(mean)' // times more likely
	store_stat ratio_tc_rg6t2_rg12nt2 `ratio_tc' 1


	foreach var in finance doctor {
		su `var' if final_tier2==1
		local `var'_t2 `r(mean)'
		su `var' if final_tier2==0
		local ratio_nt2_`var'=``var'_t2'/`r(mean)' // times more likely
		store_stat ratio_nt2_`var' `ratio_nt2_`var'' 1	
	}

	local ratio_nt2_doctor_abs = abs((`doctor_t2'-`r(mean)')/`r(mean)') // percent less likely
	store_stat ratio_nt2_doctor_abs `ratio_nt2_doctor_abs' 0 "per"


	su price_per_student if pf_wm==1
	store_stat mean_own_price_pf "`r(mean)'" 0
	local mean_own_price_pf "`r(mean)'"

	su price_per_student if pf_wm==0
	store_stat mean_own_price_npf "`r(mean)'" 0
	local diff_npf_own_price=`mean_own_price_pf'-`r(mean)'
	store_stat diff_npf_own_price `diff_npf_own_price' 0
	local diff_npf_own_price_sd=`diff_npf_own_price'/`r(sd)'
	store_stat diff_npf_own_price_sd `diff_npf_own_price_sd' 2

	su price_per_student if public_feeder_wm==1
	store_stat mean_own_price_pub "`r(mean)'" 0
	local diff_pub_own_price=`mean_own_price_pf'-`r(mean)'
	store_stat diff_pub_own_price `diff_pub_own_price' 0
	local diff_pub_own_price_sd=`diff_pub_own_price'/`r(sd)'
	store_stat diff_pub_own_price_sd `diff_pub_own_price_sd' 2

	su mp_dorm_nbd if pf_wm==1
	local mp_pf=`r(mean)'
	su mp_dorm_nbd if pf_wm==0
	local pricegaps=(`mp_pf'-`r(mean)')/`diff_npf_own_price'
	store_stat pricegaps `pricegaps' 0 "per"

	// stat for abstract
	// private feeder students are X% more likely / have X% more:
	su incwage1940_clean if final_tier2==1 & year>=1920 & year<=1930
	local mean_inc_t2 "`r(mean)'"

	su incwage1940_clean if final_tier2==0 & year>=1920 & year<=1930
	local diff_nt2_inc=`mean_inc_t2'-`r(mean)'
	local share_diff_nt2_inc=(`mean_inc_t2'-`r(mean)')/`r(mean)'
	store_stat per_diff_nt2_inc `share_diff_nt2_inc' 0 "per"

	// additional stats for "The social 'funnel' and selection into final clubs" subsection 
	// and the analogous portion of the introduction
	// describes the attributes of Hasty Pudding members and selective final club members
	foreach var in private_wm pf_wm jewish_name oc_name final_tier2 {
			su `var' if hasty==1  
			store_stat perc_`var'_hp "`r(mean)'" 0 "per" 
			}
	foreach var in private_wm pf_wm oc_name jewish_name hasty public_feeder_wm {
			su `var' if final_tier2==1  
			store_stat perc_`var'_t2 "`r(mean)'" 0 "per" 
			if "`var'"=="jewish_name" store_stat perc_`var'_t2 "`r(mean)'" 1 "per" 	
			}

	foreach var in rg12 rg6 {
		su `var' if hasty==1
		local `var'_hp `r(mean)'
		su `var' // all students
		local diff_hpall_`var'=``var'_hp'-`r(mean)'
		local share_diff_hpall_`var'=`diff_hpall_`var''/`r(mean)' // 
		store_stat per_diff_hpall_`var' `share_diff_hpall_`var'' 0 "per"
		if "`var'"=="rg12" {
		local share_less_hpall_`var'= 1 + `share_diff_hpall_`var''
		store_stat per_less_hpall_`var' `share_less_hpall_`var'' 0 "per"
		}
	}

	foreach var in rg6 {
		su `var' if final_tier2==1
		local `var'_t2 `r(mean)'
		su `var' // all students
		local diff_t2all_`var'=``var'_t2'-`r(mean)'
		local share_diff_t2all_`var'=`diff_t2all_`var''/`r(mean)' // 
		store_stat per_diff_t2all_`var' `share_diff_t2all_`var'' 0 "per"
	}

	// additional stats for "The boys' club premium" subsection
	// describes raw "premium" in outcomes between tier2 club members and all students (as opposed to not tier2 students)
	// 
	//
	foreach var in any_social_main finance doctor incwage1940_clean topincwg1940 {
		local svar "`var'"
		if "`var'"=="any_social_main" local svar "adultsocial" // need to shorten name
		if "`var'"=="incwage1940_clean" local svar "incwage1940" 
		su `var' if final_tier2==1
		local `svar'_t2 `r(mean)'
		su `var' // all students
		local diff_t2all_`svar'=``svar'_t2'-`r(mean)'
		if "`var'"!="doctor" {
		local share_diff_t2all_`svar'=`diff_t2all_`svar''/`r(mean)' // 
		store_stat per_diff_t2all_`svar' `share_diff_t2all_`svar'' 1 "per"
		}
		if "`var'"=="topincwg1940" | "`var'"=="finance" {
			local xmore_t2all_`svar' = ``svar'_t2'/`r(mean)'
			display `xmore_t2all_`svar''
		store_stat xmore_t2all_`svar' `xmore_t2all_`svar'' 1
		}
		if "`var'"=="doctor" {
		local share_diff_t2all_`svar'=`diff_t2all_`svar''/`r(mean)'*-1 //
		store_stat per_diff_t2all_`svar' `share_diff_t2all_`svar'' 1 "per"
			local xless_t2all_`svar' = `r(mean)'/``svar'_t2'
			display `xless_t2all_`svar''
		store_stat xless_t2all_`svar' `xless_t2all_`svar'' 1
		}
	}

}
/////////////////////////////////////////////////////
// Table B.12 and B.13: Brothers sample description //
/////////////////////////////////////////////////////
// Siblings specification and numbers 

gen exp=1940-class // this is how many years out from graduation people are in 1940 

global rowlist_srA "have_hs_rec private_wm pf_wm  public_feeder_wm from_MA from_NY harvard_father harvard_brother jewish_name cath_name oc_name"  
global rowlist_srB "has_census_preH comb_gen12_immg_eese preH_f_has_cen_occ preH_f_cen_doc preH_f_cen_law" 
global rowlist_srC "have_campus_address oncampus roomatts price_per_student mp_dorm_nbd nbdranki_for_p25 nbdranki_for_p75"  
global rowlist_srD1 "rg1 rg2 rg3 rg4 rg5 rg6 rg_notlisted1"
global rowlist_srD3 "rankgroup3 rg_notlisted3"
global rowlist_srE "have_ac nac aclead sports social music zphat_ac" // i
global rowlist_srF "hasty final_tier2 final_club zphat_uac" //  

global rowlist_lrA "any_social_main have_country_club have_gent_club have_frat_order any_honor zphat_cl" 
global rowlist_lrB "have_occ_if_cr finance bookkeep doctor law hed teach gov art_pub manage_high manage_low bus zphat_oc" 
global rowlist_lrC "school1940_clean lfp1940 incwage1940_clean poswage1940 incnonwg1940_clean topincwg1940" 
global sibling = 1

if $ACCESS == 1 {
	** all students with wages 1920-30
	gen wages_rank=(poswage1940==1 & year<=1933 & year>1919 & exp>=6) & !mi(rankgroup1)
	label var wages_rank "Wages \& rank"

	** students contributing to brothers earnings specification
	reghdfe  incwage1940_clean final_tier2_HEAD rankgroup1 i.year if !mi(family_id) & year<=1933 & year>1919 & exp>=6, cluster(family_id) absorb(family_id)
	gen esamp_E_wage=e(sample)
	label var esamp_E_wage "Brothers"

	 
	** students contributing to final_tier2 coefficient in brothers earnings specification
	bysort family_id: egen min_fam_fc=min(final_tier2) if esamp_E_wage==1
	bysort family_id: egen max_fam_fc=max(final_tier2) if esamp_E_wage==1
	bysort family_id: egen min_fam_year=min(year) if esamp_E_wage==1

	gen esamp_E_wage_t2=esamp_E_wage
	replace esamp_E_wage_t2=0 if min_fam_fc==max_fam_fc
	label var esamp_E_wage_t2 "Mixed membership"

	tab final_tier2  if min_fam_year ==year & esamp_E_wage_t2==1,   m // 32 sibs, 11 families, 9/11 the youngest is not a member and 2/11 the youngest is the member
	
	global samplist_sib "all wages_rank esamp_E_wage esamp_E_wage_t2"

	** Make Table B.12
	desc_tab desc_tab_sr_sib "$rowlist_srA $rowlist_srB $rowlist_srC $rowlist_srD1 $rowlist_srE $rowlist_srF" "$samplist_sib" 4 "cccc" // $rowlist_srD3 

	** Make Table B.13
	desc_tab desc_tab_lr_sib "$rowlist_lrA $rowlist_lrB $rowlist_lrC" "$samplist_sib" 4 "cccc"

	// numbers for text
	su pf_wm if wages_rank==1 // private feeder share of main table 4 sample
	store_stat perc_pf_wr "`r(mean)'"  0 per
	su pf_wm if esamp_E_wage==1 // private feeder share of brothers sample
	store_stat perc_pf_bro "`r(mean)'"  0 per
	su esamp_E_wage_t2 if esamp_E_wage==1 
	store_stat perc_t2_bro "`r(mean)'"  0 per // share of brothers sample with within family variation on final_tier2
	store_stat N_bro_t2 "`r(sum)'"  0 // number of students in brothers sample with within family variation on final_tier2
	keep if esamp_E_wage_t2==1
	by family_id: gen E_bro_n=_n  
	su E_bro_n if E_bro_n==1
	store_stat N_fam_t2 "`r(sum)'"  0  // number of families in brothers sample with within family variation on 

	su pf_wm if esamp_E_wage_t2==1 // private feeder share of members of brothers sample identifying the final_tier2 coefficient
	store_stat perc_pf_t2 "`r(mean)'"  0 per
		
	// In our sample, the average private feeder student lives in a residential peer group in which XX\% of students are from non-private feeder backgrounds. The average private feeder student participating in Hasty Pudding has XX\% of group peers from non-private feeder backgrounds, and the average private feeder student in a final club has YY\% of peers from non-private feeder backgrounds. 
	foreach hstype in npf nprivate { 
		use "$cleaned/census_rb_merged", clear
		gen nprivate_wm=1-private_wm
		drop if mi(dorm_nbd_id)  // only students in dorms
		egen gsize=total(!mi(`hstype'_wm)), by(dorm_nbd_id) 
		egen g`hstype'=total(`hstype'_wm), by(dorm_nbd_id)
		gen mpg_`hstype'_ns=(g`hstype'-`hstype'_wm) /(gsize-1) // peer group (include room), not self
		su mpg_`hstype'_ns if pf_wm==1 // calculate exposure for pf kid
		store_stat perc_mpg_`hstype'_ns  "`r(mean)'" 0 per 
		bys year: su mpg_`hstype'_ns if pf_wm==1 // calculate exposure for pf kid
		drop gsize g`hstype'

		use "$cleaned/census_rb_merged", clear
		gen nprivate_wm=1-private_wm
		drop if year==1935 //
		foreach club in hasty final_tier2 final_club {	
			egen gsize=total(!mi(`hstype'_wm)), by(`club') 
			egen g`hstype'=total(`hstype'_wm), by(`club')
			gen m`club'_`hstype'_ns=(g`hstype'-`hstype'_wm) /(gsize-1) // peer group, not self
			su m`club'_`hstype'_ns if `club'==1 & pf_wm==1  // calculate exposure for pf students in clubs
			store_stat perc_m`club'_`hstype'_ns  "`r(mean)'" 0 per 
			drop gsize g`hstype'
		}
	}

	// X% of on campus students do not come from a private school we identify
	su private_wm if rblock_sample==1
	local nonpriv_inres=1-`r(mean)'
	store_stat nonpriv_inres "`nonpriv_inres'" 0 per 

	//
	//
	//
	// ADDITIONAL BENCHMARKING CALCULATION:
	// if we set the jewish cutoff to ~match reported shares of Jews at Harvard, what do patterns of selection look like? 
	//
	//

	use "$cleaned/census_rb_merged", clear

	// name indicators: 
	gen jewish_name=jewish_index>=0.7 if !mi(jewish_index)
	gen cath_name=cath_index>=0.7 if !mi(cath_index)
	gen oc_name=oldMA_lnindex>=0.7 if !mi(oldMA_lnindex)

	label var jewish_name "Jewish name"
	label var cath_name "Catholic name"
	label var oc_name "Colonial name"

	// 27.6% for entering class of 1925 (Karabel p105)
	su jewish_index if year==1925, det // ~.45

	gen jewish_name_alt=jewish_index>=0.45 if !mi(jewish_index)
	tab year, su(jewish_name_alt)

	su jewish_name_alt // full sample
	su jewish_name_alt if pf_wm==1
	su jewish_name_alt if pf_wm==0
	su jewish_name_alt if final_tier2==1

}