/*

03d_labor_market_academic_rank.do
(called from 03_descriptive.do)

Purpose: produces labor market/academic output
Inputs: cleaned/census_rb_merged
Outputs: figures/ggrade*

*/

/*
    Produces Figures 1, 2, 5, A.5, B.14, and B.16: 
		- Figure 1: Labor Market outcomes by rank group in year 1, high school type, and final club
		- Figure 2, A.5: Adult career and social outcomes by rank group in year 1, high school type, and final club
		- Figure A.5: Occupations by rank group, high school type and final club
		- Figure B.14: Alternative earnings by academic performance and final club membership
		- Figure B.16: Labor Market outcomes by rank group in year 3, high school type, and final club
*/

******* Upper panel **********
** labor market outcomes by rank group and high school type

// argument 1: sample
// argument 2: split variable (must be binary)
// argument 3: outcome of interest
// argument 4: stata graph name
// arugment 5: name of split==1 series
// arugment 6: name of split==0 series
// arg 7: title
// arg 8 : census flag: set to 1 to cnodition on census data availabilty, 0 not to, 2 to look at early experience levels
// arg 9: year of academic performance (1 or 3)

cap program drop acgraph 
program define acgraph
	use "$cleaned/census_rb_merged", clear
	keep if year>1919 // 1919 not matched to class reports, so no long-run outcomes
	gen exp=1940-class // this is how many years out from graduation people are in 1940 
	
	if `8'==6 {
		keep if year<=1933 & year>1919
		keep if exp>=6
	}
	
	* Select the correct rank variable
	gen rankgroup = rankgroup`9'
	drop rankgroup?
	label var rankgroup "Class rank year `9'"
	
	if $ACCESS == 1 {
		// generate alternate income variable that assigns doctors max. possible value
		gen incwage_tc=incwage1940_clean
		replace incwage_tc=5000 if cen_doc==1	
		replace incwage_tc=5000 if cen_law==1	
		gen topincwg_tc=topincwg1940 
		replace topincwg_tc=1 if cen_doc==1	
		replace topincwg_tc=1 if cen_law==1	

		// is head and owns home
		gen ownhead=ownershp1940_head
		replace ownhead=0 if ownershp1940_head!=1 & has_census1940_2030==1
		// alternate predictions based on home value for people without wage earnings:
		su valueh1940_head, det
		replace valueh1940_head=`r(p99)' if !mi(valueh1940_head) & valueh1940_head>`r(p99)'
		replace valueh1940_head=`r(p5)' if !mi(valueh1940_head) & valueh1940_head<`r(p5)'
		gen vh2=valueh1940_head^2
		gen vh3=valueh1940_head^3
		gen vh4=valueh1940_head^4
		reg incwage1940_clean i.exp valueh1940_head vh2 vh3 if incnonwg1940_clean==0
		predict what if !mi(valueh1940_head), xb // what -> wage hat
	}
	
	replace rankgroup=2 if rankgroup==1 // not ny 
	
	if $ACCESS == 1 {
		collapse (mean) incwage1940_clean incnonwg1940_clean finance hed ///
			topincwg1940 doctor law manage_high teach  ///
			have_prof_assoc any_social_main have_hon_club ///
			incwage_tc topincwg_tc what valueh1940_head ownhead (sum) all `1' ///
			, by(`2' rankgroup)	
					
		label var incwage1940_clean "Wage income"
		label var incnonwg1940_clean "Have non-wage inc"
		label var topincwg1940 "Topcoded wages"	
		label var incwage_tc  "Wage income - Doc/Law set to 5k"
		label var topincwg_tc "Topcoded wages - Doc/Law set to 5k"
		label var what "Predicted wages"
		label var valueh1940_head "Home value if head"
		label var ownhead "Head and own home"
	}
	
	if $ACCESS == 0 {
		collapse (mean) finance hed ///
			doctor law manage_high teach  ///
			have_prof_assoc any_social_main have_hon_club ///
			(sum) all `1' ///
			, by(`2' rankgroup)	
	}
		
	label define cat 2 "2-1" 3 "3" 4 "4" 5 "5" 6 "6"
	label values rankgroup cat

	label var finance "Finance"
	label var law "Law" 
	label var hed "Higher ed."
	label var doctor "MD"
	label var manage_high "Manager"
	label var any_social_main "Social club"
	label var have_hon_club "Honor society"
	label var have_prof_assoc "Prof. Assoc."

	global mincell 20
	keep if all>$mincell // supress tiny cells

	if "`2'"=="pf_wm"	{
		if "`3'"=="incwage1940_clean" | "`3'"=="incwage_tc" | "`3'"=="what" {
		twoway (connect `3' rankgroup if `2'==1, msymbol(O) color($c_pf)) ///
			(connect `3' rankgroup if `2'==0, msymbol(D) color($c_npf)) ///
			, name(`4', replace) scheme(s1color) xsc(reverse) xlabel(2 3 4 5 6, valuelabel) ///
			legend(order(1 "`5'" 2 "`6'") size(small)) ytitle("Mean wage earnings") title("`7'") 
			}
			if "`3'"!="incwage1940_clean" & "`3'"!="incwage_tc" & "`3'"!="what" {
		twoway (connect `3' rankgroup if `2'==1, msymbol(O) color($c_pf)) ///
			(connect `3' rankgroup if `2'==0, msymbol(D) color($c_npf)) ///
			, name(`4', replace) scheme(s1color) ytitle("") xsc(reverse) xlabel(2 3 4 5 6, valuelabel) ///
			legend(order(1 "`5'" 2 "`6'") size(small)) ytitle("Share") title("`7'") 
			}
			graph display `4' //, xsize(10) ysize(20)
		graph export "${figures}/ggradeXpriv_`3'_y`9'.png", width(2400) replace
	}
	// for consistency with other graphs, use style rather than color to distinguish club membership
	if "`2'"=="final_tier2"	{
		if "`3'"=="incwage1940_clean"  | "`3'"=="incwage_tc" | "`3'"=="what" {
			local ytitle="Mean wage earnings"
		}
			if "`3'"=="valueh1940_head" {
			local ytitle="Mean home value"
		}
		if "`3'"!="incwage1940_clean" & "`3'"!="incwage_tc" & "`3'"!="what" & "`3'"!="valueh1940_head" {
			local ytitle="Share"
		}
		twoway (connect `3' rankgroup if `2'==1, msymbol(Oh) color($c_all) lpattern(solid)) ///
			(connect `3' rankgroup if `2'==0, msymbol(Dh) color($c_all) lpattern(dash)) ///
			, name(`4', replace) scheme(s1color)  xsc(reverse) xlabel(2 3 4 5 6, valuelabel) ///
			legend(order(1 "`5'" 2 "`6'") size(small)) ytitle("`ytitle'") title("`7'") nodraw
			graph display `4' //, xsize(10) ysize(20)
		graph export "${figures}/ggradeXsoc_`3'_y`9'.png", width(2400) replace
	}
end   

if $ACCESS == 1 {
	/////////////////////////////
	// Figure 1 -- Upper Panel //
	/////////////////////////////
	// private-public gaps by grades in year 1: 
	acgraph "" final_tier2 incwage1940_clean  g1 "Final club member" "Not member" "A. Wage income" 6 1 // grc1leg pulls from first graph 
	acgraph "" final_tier2 topincwg1940 g2 "Club member" "Not member""B. Topcoded" 6 1
	acgraph "" final_tier2 incnonwg1940_clean g3 "Club member" "Not member" "C. Non-wage" 6 1

	grc1leg g1 g2 g3 ///
		,xcommon scheme(s1color) rows(1) name(gsoc1,replace) ///
		xsize(18) ysize(20)
		graph display gsoc1, xsize(40) ysize(20) 
	graph export "${figures}/ggradeXsoc1.png", width(2400) replace

	////////////////////////////////
	// Figure B.16 -- Upper Panel //
	////////////////////////////////
	// private-public gaps by grades in year 3: 
	acgraph "" final_tier2 incwage1940_clean  g1_y3 "Final club member" "Not member" "A. Wage income" 6 3 // grc1leg pulls from first graph 
	acgraph "" final_tier2 topincwg1940 g2_y3 "Club member" "Not member""B. Topcoded" 6 3
	acgraph "" final_tier2 incnonwg1940_clean g3_y3 "Club member" "Not member" "C. Non-wage" 6 3
		
	grc1leg g1_y3 g2_y3 g3_y3 ///
		,xcommon scheme(s1color) rows(1) name(gsoc1_y3,replace) ///
		xsize(18) ysize(20)
		graph display gsoc1, xsize(40) ysize(20) 
	graph export "${figures}/ggradeXsoc1_y3.png", width(2400) replace
}

/////////////////////////////
// Figure 2 -- Upper Panel //
/////////////////////////////

// main text: 
acgraph "" final_tier2 finance g4 "Club member" "Not member" "A. Finance" 0 1
acgraph "" final_tier2 doctor g5 "Club member" "Not member" "B. Doctor" 0 1
acgraph "" final_tier2 any_social_main g8 "Club member" "Not member" "C. Social org." 0 1

grc1leg g4 g5 g8 ///
	,xcommon scheme(s1color) rows(1) name(gsoc2,replace) 

// appendix supplement (A.5): 
acgraph "" final_tier2 hed g6 "Club member" "Not member" "A. Higher Ed" 0 1
acgraph "" final_tier2 law g7 "Club member" "Not member" "B. Law" 0 1
acgraph "" final_tier2 have_prof_assoc g9 "Club member" "Not member" "C. Prof. Assoc." 0 1

grc1leg g6 g7 g9 ///
	,xcommon scheme(s1color) rows(1) name(gsoc2_a,replace) 	

// other combinations (for slides): 
grc1leg g4 g5 g8 ///
	,xcommon scheme(s1color) rows(1) name(gsoc2a,replace) ///
	xsize(18) ysize(20) 
	graph display gsoc2a, xsize(40) ysize(20) 
	graph export "${figures}/ggradeXsoc2a.png", width(2400) replace
	
grc1leg g6 g7 g9 ///
	,xcommon scheme(s1color) rows(1) name(gsoc2b,replace) ///
	xsize(40) ysize(20) 
	graph display gsoc2b, xsize(40) ysize(20) 
	graph export "${figures}/ggradeXsoc2b.png", width(2400) replace
	
grc1leg g4 g5 g8 /// // g7  ///
	,xcommon scheme(s1color) rows(1) name(gsoc2a,replace) ///
	xsize(18) ysize(20) 
	graph display gsoc2a, xsize(40) ysize(20) 
	graph export "${figures}/ggradeXsoc2_prof.png", width(2400) replace
	
grc1leg g8 g9 ///
	,xcommon scheme(s1color) rows(1) name(gsoc2b,replace) ///
	xsize(18) ysize(20) 
	graph display gsoc2b, xsize(30) ysize(20) 
	graph export "${figures}/ggradeXsoc2_assoc.png", width(2400) replace
	
if $ACCESS == 1 {

	////////////////////////////////////
	/// Additional versions of plots ///
	////////////////////////////////////
	acgraph "" final_tier2 incwage_tc  ga "Final club member" "Not member" "A. Wage income (doc/law set to top)" 6 1 // grc1leg pulls from first graph 
	acgraph "" final_tier2 topincwg_tc gb "Club member" "Not member" "B. Topcoded (doc/law set to top)" 6 1
	acgraph "" final_tier2 what gc "Club member" "Not member" "C. Predicted wages" 6 1
	acgraph "" final_tier2 valueh1940_head gd "Club member" "Not member" "D. Home value if head" 6 1
	acgraph "" final_tier2 ownhead ge "Club member" "Not member" "E. Head and own home" 6 1

	grc1leg ga gb gc gd ///
		,xcommon scheme(s1color) rows(2) name(gsoc1alt,replace) ///
		xsize(18) ysize(20)
		graph display gsoc1alt, xsize(40) ysize(20) 
	graph export "${figures}/ggradeXsoc1alt.png", width(2400) replace

	acgraph "" final_tier2 incwage_tc  ga2 "Final club member" "Not member" "A. Adjusted wage income" 6 1 // grc1leg pulls from first graph 
	acgraph "" final_tier2 what gcb "Club member" "Not member" "B. Predicted wage income" 6 1

	grc1leg ga2 gcb ///
		,xcommon scheme(s1color) rows(1) name(gsocwagealt,replace) ///
		xsize(20) ysize(14)

}

**************** Lower panel ****************
** labor market outcomes by rank group and high school type AND by more selective final club 
// argument 1: sample
// argument 2: split variable (must be binary)
// argument 3: outcome of interest
// argument 4: stata graph name
// arugment 5: name of split==1 series
// arugment 6: name of split==0 series
// arg 7: title
// arg 8 : census flag: set to 1 to cnoditio on census data availabilty, 0 not to, 2 to look at early experience levels
// arg 9: year of academic performance (1 or 3)

cap program drop acgraph2 
program define acgraph2
	use "$cleaned/census_rb_merged", clear
	keep if year>1919 // 1919 not matched to class reports, so no long-run outcomes
		gen exp=1940-class // this is how many years out from graduation people are in 1940
	if `8'==1 {
		keep if year<=1933 & year>1919
		keep if exp>=10
	}

	if `8'==2 {
		keep if year<=1933 & year>1919
		keep if exp<10
	}
	if `8'==6 {
		keep if year<=1933 & year>1919
		keep if exp>=6
	}
	
	** Select the correct rank variable
	gen rankgroup = rankgroup`9'
	drop rankgroup?
	label var rankgroup "Class rank year `9'"
	
	if $ACCESS == 1{
		// generate alternate income variable that assigns doctors max. possible value
		gen incwage_tc=incwage1940_clean
		replace incwage_tc=5000 if cen_doc==1	
		replace incwage_tc=5000 if cen_law==1	
		gen topincwg_tc=topincwg1940 
		replace topincwg_tc=1 if cen_doc==1	
		replace topincwg_tc=1 if cen_law==1	

		// is head and owns home
		gen ownhead=ownershp1940_head
		replace ownhead=0 if ownershp1940_head!=1 & has_census1940_2030==1
		// alternate predictions based on home value for people without wage earnings:
		su valueh1940_head, det
		replace valueh1940_head=`r(p99)' if !mi(valueh1940_head) & valueh1940_head>`r(p99)'
		replace valueh1940_head=`r(p5)' if !mi(valueh1940_head) & valueh1940_head<`r(p5)'
		gen vh2=valueh1940_head^2
		gen vh3=valueh1940_head^3
		gen vh4=valueh1940_head^4
		reg incwage1940_clean i.exp valueh1940_head vh2 vh3 if incnonwg1940_clean==0
		predict what if !mi(valueh1940_head), xb // what -> wage hat
	}

	replace rankgroup=2 if rankgroup==1 // not ny 
	
	if $ACCESS == 1 {
		collapse (mean) incwage1940_clean incnonwg1940_clean finance hed ///
			topincwg1940 doctor law manage_high teach  ///
			have_prof_assoc any_social_main have_hon_club ///
			incwage_tc topincwg_tc what valueh1940_head ownhead  (sum) all `1' ///
			, by(`2' pf_wm rankgroup)
		label var incwage1940_clean "Wage income"
		label var incnonwg1940_clean "Have non-wage inc"
		label var topincwg1940 "Topcoded wages"	
		label var incwage_tc  "Wage income - Doc/Law set to 5k"
		label var topincwg_tc "Topcoded wages - Doc/Law set to 5k"
		label var what "Predicted wages"
		label var valueh1940_head "Home value if head"
		label var ownhead "Head and own home"
	}
	
	if $ACCESS == 0 {
		collapse (mean) finance hed ///
			doctor law manage_high teach  ///
			have_prof_assoc any_social_main have_hon_club ///
			(sum) all `1' ///
			, by(`2' pf_wm rankgroup)
	}
	
	
	label define cat 2 "2-1" 3 "3" 4 "4" 5 "5" 6 "6"
	label values rankgroup cat
		
	label var finance "Finance"
	label var law "Law" 
	label var hed "Higher ed."
	label var doctor "MD"
	label var manage_high "Manager"
	label var any_social_main "Social club"
	label var have_hon_club "Honor society"
	label var have_prof_assoc "Prof. Assoc."

	keep if all> $mincell // supress tiny cells
	if "`3'"=="incwage1940_clean" | "`3'"=="incwage_tc" | "`3'"=="what" {
		twoway (connect `3' rankgroup if `2'==1 & pf_wm==1, msymbol(O) color($c_pf) lpattern(solid)) ///
			(connect `3' rankgroup if `2'==0 & pf_wm==1, msymbol(Oh) color($c_pf) lpattern(dash)) ///
			(connect `3' rankgroup if `2'==1 & pf_wm==0, msymbol(D) color($c_npf) lpattern(solid)) ///
			(connect `3' rankgroup if `2'==0 & pf_wm==0, msymbol(Dh) color($c_npf) lpattern(dash)) ///	
			, name(`4', replace) scheme(s1color) ///
			legend(order(1 "Private fdr., club member" 2 "Private fdr., not member " ///
			3 "Other hs, club member" 4 "Other hs, not member") size(small)) ytitle("Mean wage earnings") ///
			title("`7'")  xsc(reverse) xlabel(2 3 4 5 6, valuelabel) 
	}
	if "`3'"=="valueh1940_head" {
		twoway (connect `3' rankgroup if `2'==1 & pf_wm==1, msymbol(O) color($c_pf) lpattern(solid)) ///
			(connect `3' rankgroup if `2'==0 & pf_wm==1, msymbol(Oh) color($c_pf) lpattern(dash)) ///
			(connect `3' rankgroup if `2'==1 & pf_wm==0, msymbol(D) color($c_npf) lpattern(solid)) ///
			(connect `3' rankgroup if `2'==0 & pf_wm==0, msymbol(Dh) color($c_npf) lpattern(dash)) ///	
			, name(`4', replace) scheme(s1color) ///
			legend(order(1 "Private fdr., club member" 2 "Private fdr., not member " ///
			3 "Other hs, club member" 4 "Other hs, not member") size(small)) ytitle("Mean home value") ///
			title("`7'")  xsc(reverse) xlabel(2 3 4 5 6, valuelabel) 
	}
	if "`3'"!="incwage1940_clean"  & "`3'"!="incwage_tc" & "`3'"!="what" & "`3'"!="valueh1940_head" {
		twoway (connect `3' rankgroup if `2'==1 & pf_wm==1, msymbol(O) color($c_pf) lpattern(solid)) ///
			(connect `3' rankgroup if `2'==0 & pf_wm==1, msymbol(Oh) color($c_pf) lpattern(dash)) ///
			(connect `3' rankgroup if `2'==1 & pf_wm==0, msymbol(D) color($c_npf) lpattern(solid)) ///
			(connect `3' rankgroup if `2'==0 & pf_wm==0, msymbol(Dh) color($c_npf) lpattern(dash)) ///	
			, name(`4', replace) scheme(s1color) ///
			legend(order(1 "Private fdr., club member" 2 "Private fdr., not member " ///
			3 "Other hs, club member" 4 "Other hs, not member") size(small)) ytitle("Share") ///
			title("`7'")  xsc(reverse) xlabel(2 3 4 5 6, valuelabel) 
	}
	//	graph display `4', xsize(10) ysize(20)
	graph export "${figures}/ggradeXprivXsoc_`3'_y`9'.png", width(2400) replace 
		
	// changed "Private" to "PF" and "NP" to "Other"
end 


if $ACCESS == 1 {
	/////////////////////////////
	// Figure 1 -- Lower Panel //
	/////////////////////////////

	acgraph2 "" final_tier2 incwage1940_clean g1_hs "PF" "Other" "D. Wage income" 6 1 // 
	acgraph2 "" final_tier2 topincwg1940 g2_hs "PF" "Other" "E. Topcoded" 6 1 // 10 20
	acgraph2 "" final_tier2 incnonwg1940_clean g3_hs "PF" "Other" "F. Non-wage" 6 1 // 
		
	grc1leg g1_hs g2_hs g3_hs, ///
		xcommon scheme(s1color) rows(1) ///
		xsize(18) ysize(20) name(gprivsoc1,replace)
		graph display gprivsoc1, xsize(40) ysize(20) 
	graph export "${figures}/ggradeXprivXsoc1.png", width(2400) replace 

	////////////////////////////////
	// Figure B.16 -- Lower Panel //
	////////////////////////////////

	acgraph2 "" final_tier2 incwage1940_clean g1_hs_y3 "PF" "Other" "D. Wage income" 6 3 // 
	acgraph2 "" final_tier2 topincwg1940 g2_hs_y3 "PF" "Other" "E. Topcoded" 6 3 // 10 20
	acgraph2 "" final_tier2 incnonwg1940_clean g3_hs_y3 "PF" "Other" "F. Non-wage" 6 3 // 
		
	grc1leg g1_hs_y3 g2_hs_y3 g3_hs_y3, ///
		xcommon scheme(s1color) rows(1) ///
		xsize(18) ysize(20) name(gprivsoc1_y3,replace)
		graph display gprivsoc1, xsize(40) ysize(20) 
	graph export "${figures}/ggradeXprivXsoc1_y3.png", width(2400) replace 
}


/////////////////////////////
// Figure 2 -- Lower Panel //
/////////////////////////////

// main text: 
acgraph2 "" final_tier2  finance g4_hs "PF" "Other" "D. Finance" 0 1
acgraph2 "" final_tier2  doctor g5_hs "PF" "Other" "E. Doctor" 0 1
acgraph2 "" final_tier2 any_social_main g8_hs "PF feeder" "Other" "F. Social org." 0 1

grc1leg g4_hs g5_hs  g8_hs ///
	,xcommon scheme(s1color) rows(1) ///
	xsize(20) ysize(20) name(gprivsoc2,replace) //altshrink

// appendix supplment (A.5): 
acgraph2 "" final_tier2 hed g6_hs "PF feeder" "Other" "D. Higher Ed" 0 1
acgraph2 "" final_tier2  law g7_hs "PF feeder" "Other" "E. Law" 0 1
acgraph2 "" final_tier2  have_prof_assoc g9_hs "PF" "Other" "F. Prof. Assoc." 0 1

grc1leg  g6_hs g7_hs g9_hs ///
	,xcommon scheme(s1color) rows(1) ///
	xsize(20) ysize(20) name(gprivsoc2_a,replace) //altshrink

if $ACCESS == 1 {
	// other graphs-- for slides
	grc1leg g4_hs g5_hs g6_hs ///
		,xcommon scheme(s1color) rows(1) ///
		xsize(18) ysize(20) name(gprivsoc2a,replace) 
		graph display gprivsoc2a, xsize(40) ysize(20) 
	graph export "${figures}/ggradeXprivXsoc2a.png", width(2400) replace
		
	grc1leg g7_hs g8_hs g9_hs ///
		,xcommon scheme(s1color) rows(1) ///
		xsize(18) ysize(20) name(gprivsoc2b,replace) 
		graph display gprivsoc2b, xsize(40) ysize(20)  
	graph export "${figures}/ggradeXprivXsoc2b.png", width(2400) replace
		
	grc1leg g4_hs g5_hs g6_hs g7_hs ///
		,xcommon scheme(s1color) rows(1) ///
		xsize(18) ysize(20) name(gprivsoc2a,replace) 
		graph display gprivsoc2a, xsize(30) ysize(14) 
	graph export "${figures}/ggradeXprivXsoc2_prof.png", width(2400) replace
		
	grc1leg g8_hs g9_hs ///
		,xcommon scheme(s1color) rows(1) ///
		xsize(18) ysize(20) name(gprivsoc2b,replace) 
		graph display gprivsoc2b, xsize(30) ysize(20)  
	graph export "${figures}/ggradeXprivXsoc2_assoc.png", width(2400) replace
		
	///////////////////////////////
	/// Figure 1 -- Both Panels ///
	///////////////////////////////
	graph combine gsoc1 gprivsoc1, ///
		xcommon scheme(s1color) rows(2) ///
		xsize(25) ysize(20) name(gsocprivsoc1,replace)
	graph export "${figures}/ggradeXsoc1_XprivXsoc1.png", width(2400) replace 

	///////////////////////////////
	/// Figure B.16 -- Both Panels ///
	///////////////////////////////
	graph combine gsoc1_y3 gprivsoc1_y3, ///
		xcommon scheme(s1color) rows(2) ///
		xsize(25) ysize(20) name(gsocprivsoc1_y3,replace)
	graph export "${figures}/ggradeXsoc1_XprivXsoc1_y3.png", width(2400) replace 
}

///////////////////////////////
/// Figure 2 -- Both Panels ///
///////////////////////////////

// main (Figure 2): 
graph combine gsoc2 gprivsoc2, ///
	xcommon scheme(s1color) rows(2) ///
	xsize(25) ysize(20) name(gsocprivsoc2,replace)
graph export "${figures}/ggradeXsoc2_XprivXsoc2.png", width(2400) replace

// appendix supplement (Figure A.5) :
graph combine gsoc2_a gprivsoc2_a, ///
	xcommon scheme(s1color) rows(2) ///
	xsize(25) ysize(20) name(gsocprivsoc2,replace)
graph export "${figures}/ggradeXsoc2_XprivXsoc2_a.png", width(2400) replace
	

if $ACCESS == 1 {
	////////////////////////////////////
	/// Additional versions of plots ///
	////////////////////////////////////
	acgraph2 "" final_tier2 incwage_tc  ga_hs "PF" "Other" "A. Wage income (doc/law set to top)" 6 1 // grc1leg pulls from first graph 
	acgraph2 "" final_tier2 topincwg_tc gb_hs "PF" "Other" "B. Topcoded (doc/law set to top)" 6 1
	acgraph2 "" final_tier2 what gc_hs "PF" "Other" "C. Predicted wages" 6 1
	acgraph2 "" final_tier2 valueh1940_head gd_hs "PF" "Other" "D. Home value if head" 6 1
	acgraph2 "" final_tier2 ownhead ge_hs "PF" "Other" "E. Head and own home" 6 1

	grc1leg ga_hs gb_hs gc_hs gd_hs ///
		,xcommon scheme(s1color) rows(2) name(gprivsoc1alt,replace) ///
		xsize(18) ysize(20)
		graph display gprivsoc1alt, xsize(40) ysize(20) 
	graph export "${figures}/ggradeprivXsoc1alt.png", width(2400) replace

	acgraph2 "" final_tier2 incwage_tc  gac_hs "PF" "Other" "C. Adjusted wage income" 6 1 // grc1leg pulls from first graph 
	acgraph2 "" final_tier2 what gcd_hs "PF" "Other" "D. Predicted wage income" 6 1

	grc1leg gac_hs gcd_hs  ///
		,xcommon scheme(s1color) rows(1) name(gprivsocwagealt,replace) 

		
	// Figure B.14
	graph combine gsocwagealt gprivsocwagealt, ///
		xcommon scheme(s1color) rows(2) ///
		xsize(10) ysize(10) name(gsocprivsocwagealt,replace)
	graph export "${figures}/ggrade_wage_alt.png", width(2400) replace
}