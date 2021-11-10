/*

03h_appendixA.do
(called from 03_descriptive.do)

Purpose: produces various output from Appendix A
Inputs: cleaned/census_rb_merged
Outputs: figures/hs_counts, figures/hs_counts_twopanels, figures/gprofiles_bin`bin'_`var',
	figures/gprofiles_bin`bin'
	
*/


/*
	Produces additional Appendix Figures and Tables
		- Figure A.3: Counts of Harvard students by high school
		- Figure A.2: Earnings Profiles by experience since expected graduation
*/

//////////////////////////////////////////////
/// Figure A.3
/// Counts of Harvard students by high school
//////////////////////////////////////////////

// schools by N
use "$cleaned/census_rb_merged", clear
keep if !mi(schoolname1)

collapse (sum) all (p50) pf_wm private_wm public_feeder ///
		(mean) social finance sports, by(schoolname1)
	

gen all_lab=all+200
sort all schoolname1
gen order=_n

twoway (bar all order if pf_wm==1, color(blue%40) ) ///
	(bar all order if pf_wm==0 & private_wm==1, color(cranberry) ) ///
	(bar all order if public_feeder==1, color(forest_green%20) ) 	///
	(scatter all_lab order,  ///
	mlabpos(0) mlabel(schoolname1) msymbol(none) mlabangle(90) mlabsize(tiny) mlabcolor(black)) ///
	,  xtitle("") xlabel(,nolabel) ytitle("Total students") ///
	scheme(s1color) legend(order(1 "Private feeder" 2 "Other private" 3 "Public feeder") rows(1))
//NOT USED
graph export "${figures}/hs_counts.png", replace width(2400)

preserve 
	keep if _n>56

	twoway (bar all order if pf_wm==1, color(blue%40) ) ///
		(bar all order if pf_wm==0 & private_wm==1, color(cranberry) ) ///
		(bar all order if public_feeder==1, color(forest_green%20) ) 	///
		(scatter all_lab order,  ///
		mlabpos(12) mlabel(schoolname1) msymbol(none) mlabangle(90) mlabsize(vsmall) mlabcolor(black)) ///
		,  title("A. Top 57 most common high schools") xtitle("") xlabel(55(5)113,nolabel) ytitle("Total students") ylab(0(500)1600) ///
		scheme(s1color) legend(order(1 "Private feeder" 2 "Other private" 3 "Public feeder") rows(1) size(small)) ///
		name(g1, replace)
restore	

preserve 
	keep if _n<=56

	twoway (bar all order if pf_wm==1, color(blue%50) ) ///
		(bar all order if pf_wm==0 & private_wm==1, color(cranberry) ) ///
		(bar all order if public_feeder==1, color(forest_green%20) ) 	///
		(scatter all_lab order,  ///
		mlabpos(12) mlabel(schoolname1) msymbol(none) mlabangle(90) mlabsize(vsmall) mlabcolor(black)) ///
		, title("B. Next 56 most common high schools") xtitle("") xlabel(0(5)56,nolabel) ytitle("Total students") ylab(0(500)1600)  ///
		scheme(s1color) legend(order(1 "Private feeder" 2 "Other private" 3 "Public feeder") rows(1)) ///
		name(g2, replace)
restore	

grc1leg g1 g2 ///
	, rows(2) scheme(s1color) name(ghs_split,replace)
	graph display ghs_split, xsize(20) ysize(34)
graph export "${figures}/hs_counts_twopanels.png", width(2400) replace

if $ACCESS == 1 {
	//////////////////////////////////////////////////////////////
	/// Figure A.2
	/// Earnings Profiles by experience since expected graduation
	//////////////////////////////////////////////////////////////

	foreach bin in 1 { 
		graph close _all 

		use "$cleaned/census_rb_merged", clear

		keep if year<=1933 & year>1919
		gen exp=1940-class // this is how many years out from graduation people are in 1940
		if `bin'==2{
			replace exp=floor(exp/2)*2 // bin years into groups of 2
		}
		keep if has_census1940_2033==1 
		gen logearn=log(incwage1940_clean)
		gen inLF=empstat1940_nber<=30 & empstat1940_nber>0 // includes un
		gen employed=empstat1940_nber<=15 & empstat1940_nber>0 // includes un
		gen head_own=ownershp1940_clean *head
		gen child=relate1940_nber==301

		collapse (mean) incwage1940_clean incnonwg1940_clean topincwg1940  ///
			school1940_clean head ownershp1940_clean inLF employed logearn head_own ///
			dist_share_col41940 dist_share_harvard dist_share_topincwg1940 ///
			dist_share_dp95_valueh child ///
			, by(pf_wm exp)
			
		label var head "A. Household head"
		label var child "Child of head"
		label var employed "Employed"
		label var inLF "C. In labor force"
		label var incwage1940_clean "D. Wage earnings"
		label var topincwg1940 "E. Topcoded earnings"
		label var incnonwg1940_clean "F. Non-wage inc"
		label var school1940_clean "B. In school"

		foreach var in head school1940_clean inLF incwage1940_clean topincwg1940 incnonwg1940_clean {
			if "`var'"!="incwage1940_clean" {
				twoway (connect `var'  exp if pf_wm==1, color($c_pf) msymbol(O))  ///
				(connect `var' exp if pf_wm==0, color($c_npf) msymbol(D)) ///
				,scheme(s1color) name(`var', replace) legend(order(1 "Private feeder" 2 "Other high school")) ///
				ytitle("Share") xtitle("Years since expected graduation") title(`:var label `var'') xlabel(5(5)15) 
			}
			if "`var'"=="incwage1940_clean" {
				twoway (connect `var'  exp if pf_wm==1, color($c_pf) msymbol(O))  ///
				(connect `var' exp if pf_wm==0, color($c_npf) msymbol(D)) ///
				,scheme(s1color) name(`var', replace) legend(order(1 "Private feeder" 2 "Other high school")) ///
				ytitle("Mean wage earnings") xtitle("Years since expected graduation") title(`:var label `var'') xlabel(5(5)15) 
			}
			graph export "${figures}/gprofiles_bin`bin'_`var'.png", width(2400) replace
		}	


		grc1leg head school1940_clean inLF incwage1940_clean topincwg1940 incnonwg1940_clean	///
			, rows(3) scheme(s1color) name(gprofiles,replace)
			graph display gprofiles, xsize(14) ysize(20)
		graph export "${figures}/gprofiles_bin`bin'.png", width(2400) replace
	}	


}