/*

04b_random_variation_balance.do
(called from 04_random_variation.do)

Purpose: produces experimental balance table
Inputs: cleaned/redbooks_res_sample
Outputs: tables/balance_test_1919, tables/balance_app_test_1919
	
*/

// I ran into a maxvar problem, so setting to higher than default 5,000
clear
clear matrix
clear mata
set maxvar 10000

////////////////////////////////////
// Table 5/A.6 - Experimental balance //
////////////////////////////////////

// MAIN - 5
global bal_list "price_per_student private_wm pf_wm have_hs from_MA from_NY harvard_father harvard_brother jewish_name cath_name oc_name comb_gen12_immg_eese preH_f_has_cen_occ preH_f_cen_doc preH_f_cen_law" // f_east_euro f_s_euro immig_any"
global fs_list "mpgprivate_wm_nr mpgpf_wm_nr mpgh_father mpggen12_eese  topshare eliteaccess" 
global test_list "price_per_student private_wm pf_wm from_MA from_NY harvard_father harvard_brother comb_gen12_immg_eese preH_f_has_cen_occ preH_f_cen_doc preH_f_cen_law have_hs jewish_name cath_name oc_name" // f_east_euro f_s_euro immig_any"
global inc_list "incwage1940_clean topincwg1940 incnonwg1940_clean wage_index"

//APPENDIX - A.6
global link_list "has_pid have_occ has_census1940_2030" 
global endog_list "mpgrankgroup1 mpgzphat_ac mpgnac mpgsocial mpgtier2 mpgzphat_oc mpgfinance mpgincwage1940_clean" 

if $ACCESS == 0 {
	// MAIN
	global bal_list "price_per_student private_wm pf_wm have_hs from_MA from_NY harvard_father harvard_brother" 
	global fs_list "mpgprivate_wm_nr mpgpf_wm_nr mpgh_father topshare eliteaccess" 
	global test_list "price_per_student private_wm pf_wm from_MA from_NY harvard_father harvard_brother" 
	global inc_list ""
	//APPENDIX
	global link_list "has_pid have_occ"
	global endog_list "mpgrankgroup1 mpgzphat_ac mpgnac mpgsocial mpgtier2 mpgzphat_oc mpgfinance" 
}

/////////

foreach restrict in 1919 { 
	
	use "${cleaned}/redbooks_res_sample", clear

	label var have_hs "Have HS code"
	label var harvard_brother "Have Harvard brother"
	label var harvard_father "Have Harvard father"
	label var private_wm "Any private high school"
	label var from_MA "From MA"
	label var from_NY "From NY"
	label var has_pid "Class report link"
	label var have_occ "Have occupation"
	label var pf_wm "Private feeder high school"
	label var price_per "Room price per occupant"

	// rename to shorter names: 
	rename mpgharvard_father mpgh_father 
	if $ACCESS == 1 {
		rename mpgcomb_gen12_immg_eese mpggen12_eese
		// name indicators: 
		gen jewish_name=jewish_index>=0.7 if !mi(jewish_index)
		gen cath_name=cath_index>=0.7 if !mi(cath_index)
		gen oc_name=oldMA_lnindex>=0.7 if !mi(oldMA_lnindex)
		
		label var jewish_name "Jewish name"
		label var cath_name "Catholic name"
		label var oc_name "Colonial name"
		
		// restrict pre-Harvard Census anlysis to years where variables are systematically available
		foreach var in comb_gen12_immg_eese preH_f_has_cen_occ preH_f_cen_doc preH_f_cen_law {
			replace `var'=. if year < 1920 | year > 1933
		}
	}
	rename mpgfinal_tier2_nr mpgtier2_nr

	if `restrict'==1922{
		replace rblock_sample=0 if year<1922
	}

	// Table 5
	bal_table balance "bal_list fs_list" `restrict'
	// Table A.6
	bal_table balance_app  "link_list endog_list" `restrict'

	// balance stats
	store_stat res_price_per "${res_price_per_student}" 0
	su price_per if rblock_sample==1 
	local permean_price_per = ${res_price_per_student}/`r(mean)'
	store_stat permean_price_per `permean_price_per' 1 "per"

	foreach var in private_wm pf_wm harvard_father harvard_brother { 
		store_stat res_`var' "${res_`var'}" 1 "per"
		su `var' if rblock_sample==1 
		local permean_`var' = ${res_`var'}/`r(mean)'
		store_stat permean_`var' `permean_`var'' 1 "per"
		// divide by half for intro text
	}

	store_stat test1 ${test1} 3
	store_stat test2 ${test2} 3
	store_stat test3 ${test3} 3

	if $ACCESS == 1 {
			// first-stage stats
			foreach var in mpgprivate_wm_nr mpgpf_wm_nr mpgh_father mpggen12_eese{
				store_stat rb_`var' "${rb_`var'}" 1 "per"
				su `var' if rblock_sample==1 
				store_stat mean_`var' `r(mean)' 1 "per"
			}
			// ee share is negative, so want to store the absolute value to match text descriping "lower"
			local rb_mpggen12_eese_abv=${rb_mpggen12_eese}*-1 
			store_stat rb_mpggen12_eese_abv `rb_mpggen12_eese_abv' 1 "per"

			foreach var in mpgprivate_wm_nr mpgpf_wm_nr {
				store_stat rb_`var'_se "${rb_`var'_se}" 1 "per"

				local rb_`var'_5=${rb_`var'}/2
				store_stat rb_`var'_5 `rb_`var'_5' 1 "per"
				su `var' if rblock_sample==1 
				local permean_`var' = ${rb_`var'}/`r(mean)'
				store_stat permean_`var' `permean_`var'' 1 "per"
				local permean_`var'_5=`permean_`var''/2
				store_stat permean_`var'_5 `permean_`var'_5' 1 "per"

			}

			// endog outcomes
			foreach var in mpgrankgroup1_nr mpgzphat_ac_nr mpgnac_nr mpgsocial_nr mpgtier2_nr { 
				display ${rb_`var'}
				store_stat rb_`var' "${rb_`var'}" 2
			}
}
}