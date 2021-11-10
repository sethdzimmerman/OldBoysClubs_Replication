/*

05_honors.do
(called from master_longrun.do)

Purpose: creates academic honors figures
Inputs: raw/Other/boston_globe_honors, cleaned/lr_series_redbooks_clean,
	cleaned/redbooks_clean
Outputs: figures/honors

*/

// Get honors data from boston globe: http://cache.boston.com/globe/metro/packages/harvard_honors/harvard_graph.htm

insheet using "$raw/Other/boston_globe_honors.csv", clear
ren class class_bin
keep if class_bin <= 1990
tempfile boston_globe
save `boston_globe', replace

use "$cleaned/lr_series_redbooks_clean", clear
drop if year < 1920
* Make private a categorical instead of a binary variable
gen hs_split = 1 if public_feeder == 1
replace hs_split = 2 if private_feeder == 1
replace hs_split = 3 if private == 1 & private_feeder == 0
replace hs_split = 4 if nonfeeder == 1

foreach var of  varlist have_honors *cum *laude magna_summa {
		replace `var' = . if year == 1927 | year == 1920 // Honors not properly documented
	}

foreach var of varlist *grad {
		replace `var' = . if year == 1920 // Only have degree info for 1% of sample that year
	}

// Double count Class report years into two rolling average bins, 
// i.e. 1980 class report in 1977.5 and 1982.5	s
expand 2 if class==class_bin & class<1990, gen(copy)
replace class_bin = class_bin - 2.5 if copy ==0 
replace class_bin = class_bin + 2.5 if copy ==1

preserve
	collapse (mean) harvard_degree have_degree have_honors *cum *laude magna_summa *grad ///
		if have_degree == 1, by(class_bin)
	
	// Merge on comparison data from Boston globe
	merge 1:1 class_bin using `boston_globe', nogen
	
	label var have_degree "Have degree info"
	label var harvard_degree "Have Harvard degree"
	label var have_honors "Any honors"
	label var summa_cum "Summa cum laude"
	label var magna_cum "Magna cum laude"
	label var magna_summa "High honors"
	label var other_laude "Other honors"
	label var phd_grad "PhD"
	label var md_grad "MD"
	label var jd_grad "JD/LLB"
	label var mba_grad "MBA"
	label var hon_bosglobe "Any honors (Boston Globe)"

	// Honors
	// Figure B.19 panel D
	twoway ///
		(connect have_honors class_bin, msize(medlarge) col(navy) msymbol(Th)) ///
		(connect summa_cum class_bin, msize(medlarge) col(maroon) msymbol(+)) ///
		(connect magna_cum class_bin, msize(medlarge) col(sienna) msymbol(Oh)) ///
		(connect other_laude class_bin, msize(medlarge) col(ltblue) msymbol(Sh)) ///
		(scatter hon_bosglobe class_bin, msize(medlarge) col(emerald) ///
			mfc(emerald%60) msymbol(X)) ///
		, ///
		xsca(range(1920 1990)) xlab(1920(10)1990) xtitle("") ytitle("Share") /// 
		ylab(0(.1).8) scheme(s1color) ///
		legend( colgap(*.5) symxsize(*.5) ) ///
		xsize(16) ysize(11) name(g_hon, replace)
		graph export "$figures/honors.png", width(2400) replace
		
	graph drop _all
restore

graph drop _all