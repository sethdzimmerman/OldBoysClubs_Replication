/*

03_descriptive.do
(called from master_census.do)

Purpose: produces descriptive output
Inputs: 03a_data_availability, 03b_harvard_sr_lr_desc.do, 
	03c_labor_market_academic_rank.do, 03d_prices_and_peer_attributes.do, 
	03e_rand_blocks.do, 03f_harvard_vs_world.do, 03g_academic_social_success.do,
	03h_appendixA.do, 03i_appendixB.do
Outputs: N/A
	
*/

//////////////////////////////////////////
// program to output descriptive tables //
//////////////////////////////////////////
// argument 1: file name
// argument 2: rowlists
// argument 3: collists
// argument 4: number of columns
// argument 5: centering of columns
cap program drop desc_tab 
program define desc_tab 

	cap file close f
	file open f using "${tables}/`1'.txt", write replace

	file write f "\begin{tabular}{l `5'}"  _n 
	// column headers: 
	foreach samp in `3' { // $samplist  {
	file write f $tab "`:var label `samp''"
	}

	// loop over variables of interest: 
	local i=0 

	foreach var in `2' {
		local i=`i'+1
		// panel labels: 
		if "`var'"=="have_hs_rec" | ("`var'"=="private_wm" & $sibling == 0) file write f $llb "\multicolumn{`4'}{l}{\emph{A. Demographics}}" 
		if "`var'"=="has_census_preH"| ("`var'"=="comb_gen12_immg_eese" & $sibling == 0) file write f $lb  $lb"\multicolumn{`4'}{l}{\emph{B. Census childhood household demographics}}" 	
		if "`var'"=="have_campus_address" | ("`var'"=="oncampus" & $sibling == 0) file write f $lb  $lb "\multicolumn{`4'}{l}{\emph{C. First-year campus location}}"
		if "`var'"=="rg1" | ("`var'"=="rg13" & $sibling == 0) file write f $lb  $lb  "\multicolumn{`4'}{l}{\emph{D. Academic class rank groups}}" 	
		if "`var'"=="have_ac" file write f $lb  $lb "\multicolumn{`4'}{l}{\emph{E. First-year activities}}"
		if "`var'"=="hasty" file write f $lb  $lb  "\multicolumn{`4'}{l}{\emph{F. Upper-year social clubs}}"
		if "`var'"=="have_occ_if_cr" | ("`var'"=="teach" & $sibling == 0) file write f $lb $lb "\multicolumn{`4'}{l}{\emph{B. Occupations}}"
		if "`var'"=="any_social_main" | ("`var'" == "have_frat_order" & $sibling == 0) file write f $llb "\multicolumn{`4'}{l}{\emph{A. Adult associations}}"
		if "`var'"=="school1940_clean" & "`1'"!="desc_tab_cen" file write f $lb  $lb"\multicolumn{`4'}{l}{\emph{C. Adult census}}"
		if "`var'"=="col41940" & "`1'"=="desc_tab_cen" file write f $llb"\multicolumn{`4'}{l}{\emph{A. Census: individual}}"	
		if "`var'"=="dmetro_cc" file write f  $lb  $lb "\multicolumn{`4'}{l}{\emph{B. Census: enumeration district}}"
		
		file write f $lb "`:var label `var''"

	// loop over samples: 
	foreach samp in `3' { 
		
		su `var' if `samp'==1 , detail
		if `r(mean)' > -.0005 & `r(mean)' <= 0 {
			if "`var'"!="price_per_student" &  "`var'"!="mp_dorm_nbd" & "`var'"!="incwage1940_clean" & /// 
			"`var'"!="valueh1940_head" & "`var'"!="rent1940_head" & "`var'"!="dist_p50_incwage" & ///
			"`var'"!="dist_p90_incwage" & "`var'"!="dist_p50_valueh" & "`var'"!="dist_p90_valueh"  &  ///
			"`var'"!="dist_p50_rent" & "`var'"!="dist_p90_rent" &  "`var'"!="dist_N_men2737" ///
			&  "`var'"!="nbdranki_for_p25" &  "`var'"!="nbdranki_for_p75" ///
			file write f $tab %4.3f (0.000)
			if "`var'"=="incwage1940_clean" | "`var'"=="valueh1940_head"  |  "`var'"=="dist_p50_incwage" | ///
			"`var'"=="dist_p90_incwage" | "`var'"=="dist_p50_valueh" | "`var'"=="dist_p90_valueh"  ///
			file write f $tab %5.0f (0.000)
			if "`var'"=="price_per_student" | "`var'"=="mp_dorm_nbd" | "`var'"=="dist_N_men2737" | ///
			"`var'"=="rent1940_head" | "`var'"=="dist_p50_rent" | "`var'"=="dist_p90_rent"  ///
			file write f $tab %4.1f (0.000)
			
		}
		else {
			if "`var'"!="price_per_student" &  "`var'"!="mp_dorm_nbd" & "`var'"!="incwage1940_clean" & /// 
			"`var'"!="valueh1940_head" & "`var'"!="rent1940_head" & "`var'"!="dist_p50_incwage" & ///
			"`var'"!="dist_p90_incwage" & "`var'"!="dist_p50_valueh" & "`var'"!="dist_p90_valueh"  &  ///
			"`var'"!="dist_p50_rent" & "`var'"!="dist_p90_rent" &  "`var'"!="dist_N_men2737" ///
			&  "`var'"!="nbdranki_for_p25" &  "`var'"!="nbdranki_for_p75" ///
			file write f $tab %4.3f (`r(mean)')
			if "`var'"=="incwage1940_clean" | "`var'"=="valueh1940_head"  |  "`var'"=="dist_p50_incwage" | ///
			"`var'"=="dist_p90_incwage" | "`var'"=="dist_p50_valueh" | "`var'"=="dist_p90_valueh"  ///
			file write f $tab %5.0f (`r(mean)')
			if "`var'"=="price_per_student" | "`var'"=="mp_dorm_nbd" | "`var'"=="dist_N_men2737" | ///
			"`var'"=="rent1940_head" | "`var'"=="dist_p50_rent" | "`var'"=="dist_p90_rent"  ///
			file write f $tab %4.1f (`r(mean)')
			if "`var'"=="nbdranki_for_p25" file write f $tab %4.3f (`r(p25)')
			if "`var'"=="nbdranki_for_p75" file write f $tab %4.3f (`r(p75)')
		}
	}
	}

	// sample sizes: note, this does not reflect additional missingness for some variables in some panels
	file write f $llb "N"
	foreach samp in `3' { // $samplist  {
		count if `samp'==1
	file write f $tab  %12.0g (`r(N)')
	}

	file write f $lb "\end{tabular}"	

	file close f 

end 
//
// end program

//////////////////////////////////
// Main Text Tables and Figures //
//////////////////////////////////

***** Table 1 & Figure A.1 ******
** Data availability in different samples
do 03a_data_availability.do
graph drop _all

***** Tables 2, A.2, A.3, A.5, 3, B.12, and B.13  *******
** Harvard students short run and long run by high school type 
do 03b_harvard_sr_lr_desc.do
graph drop _all

***** Figure 1, Figure 2, Figure A.5, Figure B.14, and Figure B.16 ******
*** Labor Market Outcomes by academic rank, HS type and social clubs
do 03c_labor_market_academic_rank.do
graph drop _all

***** Figure 4 ******
** Dorm room prices and peer attributes
do 03d_prices_and_peer_attributes.do

***** Figure 5 ******
** Randomization block size and within-block variation in peer attributes
do 03e_rand_blocks.do
graph drop _all

**** Table B.10 ******
** Harvard vs the World 
if $ACCESS == 1 {
	do 03f_harvard_vs_world.do
	graph drop _all
}

if $ACCESS == 1 {
	***** Table 4 and A.4 and B.14 and B.15 *******
	* Predict earnings by academic and social success in college as well as 
	* high school background
	do 03g_academic_social_success.do
	graph drop _all
}

/////////////////////////////////
// Appendix Figures and Tables //
/////////////////////////////////

**** Appendix A ****
** Figure A.2 and Figure A.3
do 03h_appendixA.do
graph drop _all

**** Appendix B ****
** Figures B.13 and B.15
** Tables B.6, B.7 and B.8
do 03i_appendixB.do
graph drop _all