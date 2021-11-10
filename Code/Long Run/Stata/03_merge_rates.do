/*

03_merge_rates.do
(called from master_longrun.do)

Purpose: creates merge rate figures
Inputs: cleaned/lr_series_redbooks_clean
Outputs: figures/merge_class_reports, figures/merge_rates_by_highschool
	
*/

use "$cleaned/lr_series_redbooks_clean", clear

gen have_occ_if_pid=have_occ
replace have_occ_if_pid=. if has_pid==0

 * want to show availability rates from the base of the whole population 
foreach var of varlist have_hs_rec have_hs* have_occ have_degree has_pid ///
	private_feeder* public_feeder* private* nonfeeder* {
	replace `var'=0 if mi(`var')
}

** Make sure Class Reports merge and data statistics don't get pooled down from years
** for which we don't have class report data
foreach var in has_pid have_occ have_degree {
    replace `var' = . if cr_year == 0 
} 

// figure:
keep if class_bin <= 1990 & year > 1919

* Get how many years get pooled for each class_bin
egen tag = tag(class_bin class)
egen distinct = total(tag), by(class_bin)

* Merge rates by HS status
gen have_occ_priv_feeder =  have_occ if private_feeder == 1
gen have_occ_pub_feeder =  have_occ if public_feeder == 1

collapse (mean)  have_occ* have_degree has_pid have_hs have_hs_rec ///
	private_feeder public_feeder private_other nonfeeder ///
	male , by(class_bin)

// label var all "N in Red Book"
// label var en_first "N from IPEDS/HEGIS"
label var have_occ  "Have occupation info"
label var have_occ_priv_feeder "Have occ. info | private feeder"
label var have_occ_pub_feeder "Have occ. info | public feeder"
label var have_degree "Have degree info"
label var has_pid "Class Report match"

// Don't display missing years as 0
foreach var of varlist * {
	replace `var' = . if `var' == 0 
}

// Figure B.19, panels e and f

////////////////////////////
// Merge rates RB <-> CR ///
////////////////////////////
twoway (connect has_pid class_bin  ,  msize(medlarge) col(emerald)  msymbol(O)) ///
	(connect have_occ class_bin ,  msize(medlarge) col(maroon) msymbol(D)) ///
	(connect have_degree class_bin ,  msize(medlarge) col(navy) msymbol(S)) ///
	,xsca(range(1920 1990)) xlab(1920(10)1990) ///
	ysca(range(0 1)) ylab(0(.2)1) ///
	scheme(s1color) ytitle(Share) xtitle("") ///
	xsize(16) ysize(11) name(g2, replace) ///
	legend(colgap(*.75) symxsize(*.5))
graph export "$figures/merge_class_reports.png", width(2400) replace

// Occupation merge rates conditional on HS status
twoway (connect have_occ_pub_feeder class_bin  , ///
	msize(medlarge) col(maroon)  msymbol(Oh)) ///
	(connect have_occ_priv_feeder class_bin ,  ///
		msize(medlarge) col(navy) msymbol(T) mfc(navy%60)) ///
	,xsca(range(1920 1990)) xlab(1920(10)1990) ///
	ysca(range(0 1)) ylab(0(.2)1) ///
	scheme(s1color) ytitle(Share) xtitle("") ///
	xsize(16) ysize(11) name(g2, replace) ///
	legend(colgap(*.75) symxsize(*.5))
graph export "$figures/merge_rates_by_highschool.png", width(2400) replace