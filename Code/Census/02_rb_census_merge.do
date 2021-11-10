/*

02_rb_census_merge.do
(called from master_census.do)

Purpose: merges Red Books data with Census data
Inputs: cleaned/redbooks_clean, intstata/harvard_full_v4_histid_all, 
	int/harvard_indv_and_all_dist_1940_desc, int/harvard_only_indv_preH_desc,
	intstata/harvard_name_indices, 02a_clean.do
Outputs: cleaned/census_rb_merged, cleaned/redbooks_res_sample
	
*/

///////////
** This merges assembled Harvard records (redbooks_clean) with census data on the NBER server
** 	additionally, it performs a few supplemental cleaning tasks (e.g., academic rank groups and immigrant status)
**	finally, variable labels are set at the end of the file
**	we produce a version with the full sample: "$cleaned/census_rb_merged"
**  and a version with just the residential sample "${cleaned/redbooks_res_sample"	

if $ACCESS == 1{ 

	use "$cleaned/redbooks_clean", clear

	merge m:1 pid using "$intstata/harvard_full_v4_histid_all.dta",  keep(match master) nogen
	gen all_harvard=1

	merge m:1 histid1940 using "${intstata}/harvard_indv_and_all_dist_1940_desc.dta", nogen keep(match master) 

	** merge in student-level data with one obs per most-recent valid preH census match
	gen mpreH_cen_year=.
	gen preH_histid=histid1930
	replace preH_histid="" if year<1930
	replace mpreH_cen_year=1930 if preH_histid!=""
	replace preH_histid=histid1920 if preH_histid==""
	replace mpreH_cen_year=1920 if preH_histid!="" & mpreH_cen_year==.
	replace preH_histid=histid1910 if preH_histid==""
	replace mpreH_cen_year=1910 if preH_histid!="" & mpreH_cen_year==.

	** No longer using and district level preH characteristics
	merge m:1 preH_histid using "$intstata/harvard_only_indv_preH_desc.dta", keep(match master) gen(_mpreH)

	gen has_census191030=(_mpreH==3)
	drop _mpreH

	// in census data: (self, mother, father, wife) 
	forv j=1900(10)1940 {
		gen has_census`j'=!mi(histid`j') 
	}

	egen has_census=rowmax(has_census1910 has_census1920 has_census1930 has_census1940)
	gen has_census1940_2033=has_census1940
	replace has_census1940_2033=0 if year<1920 | year>1933
	gen has_census1940_2030=has_census1940
	replace has_census1940_2030=0 if year<1920 | year>1930
	rename has_census1940 has_census1940_2035 
	egen has_census_preH=rowmax(has_census1910 has_census1920)
	replace has_census_preH=1 if (has_census1930==1 & year>=1930) // can use the 1930 census for background if entered Harvard after 1930; note in 1930 'census day' was April 1st, so prior to move in date for students entering Harvard that fall

	* flag for harvard student from the cohorts with good census match rates
	gen harvard_2033=harvard
	replace harvard_2033=0 if year<1920 | year>1933

	// Irish immigrants 
	gen gen1_immg_ir = bpl_ir
	gen gen2_immg_ir= (mbpl_ir==1 | fbpl_ir==1)

	foreach region in "" "_ee" "_se" "_ir"{
		foreach gen in 1 2 {
			gen comb_gen`gen'_immg`region' = ///
				max(gen`gen'_immg`region', preH_gen`gen'_immg`region')
		}
		* First or second generation
		gen comb_gen12_immg`region' = ///
			max(comb_gen1_immg`region',comb_gen2_immg`region')
	}
	// combine southern and eastern European immigrants and southern and irish immigrants
	// and for parent birthplace, we can also use 1940 records!

	** 1st generation
	gen comb_gen1_immg_eese=max(bpl_ee, preH_bpl_ee,gen1_immg_se, preH_gen1_immg_se)
	gen comb_gen1_immg_irse=max(bpl_ir, preH_bpl_ir,gen1_immg_se, preH_gen1_immg_se)

	* 2nd generation
	gen comb_gen2_immg_eese=max(gen2_immg_ee, preH_gen2_immg_ee,gen2_immg_se, preH_gen2_immg_se)
	gen comb_gen2_immg_irse=max(gen2_immg_ir, preH_gen2_immg_ir,gen2_immg_se, preH_gen2_immg_se)

	* 1st or 2nd generation
	gen comb_gen12_immg_eese=max(comb_gen1_immg_eese,comb_gen2_immg_eese)
	gen comb_gen12_immg_irse=max(comb_gen1_immg_irse,comb_gen2_immg_irse)

	gen comb_gen12_immg_not=comb_gen12_immg
	replace comb_gen12_immg_not=0 if comb_gen12_immg_eese==1

	** Merge name indices created in step 01d
	merge 1:1 index using "$intstata/harvard_name_indices",  nogen

	** z-scores for 
	egen zdist_p50_valueh = std(dist_p50_valueh)
	egen zdist_p50_incwage = std(dist_p50_incwage)
	egen zincwage1940_clean = std(incwage1940_clean)

	gen npf_wm=1-pf_wm	
	label var npf_wm "Not private feeder high school (includes uncoded schools)"

	gen public_feeder_wm=public_feeder==1
	label var public_feeder_wm "Public feeder high school (includes uncoded schools)"

	gen inressample=!mi(dorm_nbd_id)
	label var inressample "Residential Sample"

	// DEFINE RBLOCK_SAMPLE HERE so consistent without.

	// group variables: 
	egen double price_year=group(price_per year)
	egen double price_year_cap=group(price_per year roomcap)

	// coarse high school code with missing data
	gen hs_wm=schoolcode1
	replace hs_wm=1000 if  inlist(schoolcode1,1,4,3,6,5,10,8,16,9,2,13,22,21)==0
	replace hs_wm=1000 if mi(schoolcode1)

	reghdfe pf_wm nbdrank, absorb(${rblock} i.hs_wm) vce(cluster dorm_nbd_id)

	gen rblock_sample=e(sample)==1 & !mi(pf_wm) & !mi(price_per) & !mi(roomcap)

	label var price_year "Room price per student group by year"
	label var price_year_cap "Room price per student group by year and room capacity"
				
	label var hs_wm "High school code (including missing)"
	label var rblock_sample "Randomized"
			
	cd "$code"

	do 02a_clean.do

	compress
	save "$cleaned/census_rb_merged", replace
	//
	// residential sorting for on-campus students
	// keep only people w/ dorm info
	//	

	use "$cleaned/census_rb_merged", clear
		
	drop if dorm_nbd_id==.
	* peer mean attributes, excluding
	drop if class==1930 // missing room and hs records in this year
	drop if dorm=="Off Campus" | mi(college_address) 
	drop if mi(roomno) 
	drop if mi(dorm) 
	drop if mi(floor) | mi(bedrooms) 

	* peer mean attributes, excluding attributes of in-room students: 
	local rlevel "dorm_nbd_id"

	foreach pdef in private_wm pf_wm nac social finance rankgroup1 ///
		comb_gen12_immg_eese zphat_ac zphat_oc  harvard_father ///
		final_tier2 incwage1940_clean {

		egen gsize=total(!mi(`pdef')), by(`rlevel') 
		egen gpriv=total(`pdef'), by(`rlevel')
		egen roomsize=total(!mi(`pdef')), by(room_id) 
		egen roompriv=total(`pdef'), by(room_id) 
		gen mpg`pdef'_nr=(gpriv-roompriv) /(gsize-roomsize) // peer group, not room

		drop gsize gpriv roomsize roompriv

	}

	// label variables
	label var mpgprivate_wm_nr "Private HS peer share"
	label var mpgpf_wm_nr "Feeder HS peer share"
	label var mpgharvard_father "Legacy share"
	label var topshare "Share rooms $>$ median price"  // "Share nbd price above median"
	label var eliteaccess "Share rooms $>$ 90th pctile price" // "Share nbd price 90th pctl"
	label var mpgcomb_gen12_immg_eese "E Eur. peer share"
	label var mpgnac "Peer mean activity count"
	label var mpgsocial "Peer mean social act."
	label var mpgfinance "Peer mean finance"
	label var mpgrankgroup1 "Peer mean acad. rank"
	label var mpgzphat_ac "Peer activity index"
	label var mpgzphat_oc "Peer occ. index"
	label var mpgfinal_tier2 "Peer more sel. final"
	label var mpgincwage1940_clean "Peer mean wage inc."

	preserve

	use "${cleaned}/census_rb_merged", clear
	lasso2 incwage1940_clean finance doctor law hed teach gov art_pub manage_high manage_low bus ///
		bookkeep sci engineer any_social_main have_prof_assoc have_hon_club ///
		if year>=1920 & year<=1930 ,lic(ebic) postres
	predict wage_index, xb
	keep index wage_index
	label var wage_index "Class Reports wage index"
	tempfile tf
	save `tf'
	restore

	merge 1:1 index using `tf', keep(master match) nogen

	save "${cleaned}/redbooks_res_sample"	, replace 

} 

if $ACCESS == 0 {
	
	use "$cleaned/redbooks_clean", clear
	gen npf_wm=1-pf_wm	
	label var npf_wm "Not private feeder high school (includes uncoded schools)"

	gen public_feeder_wm=public_feeder==1
	label var public_feeder_wm "Public feeder high school (includes uncoded schools)"

	gen inressample=!mi(dorm_nbd_id)
	label var inressample "Residential Sample"

	// DEFINE RBLOCK_SAMPLE HERE so consistent without.

	// group variables: 
	egen double price_year=group(price_per year)
	egen double price_year_cap=group(price_per year roomcap)

	// coarse high school code with missing data
	gen hs_wm=schoolcode1
	replace hs_wm=1000 if  inlist(schoolcode1,1,4,3,6,5,10,8,16,9,2,13,22,21)==0
	replace hs_wm=1000 if mi(schoolcode1)

	reghdfe pf_wm nbdrank, absorb(${rblock} i.hs_wm) vce(cluster dorm_nbd_id)

	gen rblock_sample=e(sample)==1 & !mi(pf_wm) & !mi(price_per) & !mi(roomcap)

	label var price_year "Room price per student group by year"
	label var price_year_cap "Room price per student group by year and room capacity"

	label var hs_wm "High school code (including missing)"
	label var rblock_sample "Randomized"
	save "$cleaned/census_rb_merged", replace
	drop if dorm_nbd_id==.
	* peer mean attributes, excluding
	drop if class==1930 // missing room and hs records in this year
	drop if dorm=="Off Campus" | mi(college_address) 
	drop if mi(roomno) 
	drop if mi(dorm) 
	drop if mi(floor) | mi(bedrooms) 
	* peer mean attributes, excluding attributes of in-room students: 
	local rlevel "dorm_nbd_id"

	foreach pdef in private_wm pf_wm nac social finance rankgroup1 ///
		zphat_ac zphat_oc  harvard_father final_tier2 {

		egen gsize=total(!mi(`pdef')), by(`rlevel') 
		egen gpriv=total(`pdef'), by(`rlevel')
		egen roomsize=total(!mi(`pdef')), by(room_id) 
		egen roompriv=total(`pdef'), by(room_id) 
		gen mpg`pdef'_nr=(gpriv-roompriv) /(gsize-roomsize) // peer group, not room

		drop gsize gpriv roomsize roompriv
	}
	// label variables
	label var mpgprivate_wm_nr "Private HS peer share"
	label var mpgpf_wm_nr "Feeder HS peer share"
	label var mpgharvard_father "Legacy share"
	label var topshare "Share rooms $>$ median price"  // "Share nbd price above median"
	label var eliteaccess "Share rooms $>$ 90th pctile price" // "Share nbd price 90th pctl"
	label var mpgnac "Peer mean activity count"
	label var mpgsocial "Peer mean social act."
	label var mpgfinance "Peer mean finance"
	label var mpgrankgroup1 "Peer mean acad. rank"
	label var mpgzphat_ac "Peer activity index"
	label var mpgzphat_oc "Peer occ. index"
	label var mpgfinal_tier2 "Peer more sel. final"

	save "${cleaned}/redbooks_res_sample", replace 

}