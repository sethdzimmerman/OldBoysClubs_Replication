/*

03d_price_and_peer_attributes.do
(called from 03_descriptive.do)

Purpose: produces room price/peer attrubute related output
Inputs: cleaned/redbooks_res_sample
Outputs: figures/price_gsize_hist, figures/peer_hstype_by_price,
	figures/peer_nbdranki_by_price, figures/peer_atts_by_price
	
*/

/*
    ********** Figure 4 ****************
    Dorm room prices and peer attributes
*/

// Figure 4A - Randomization support

use  "${cleaned}/redbooks_res_sample"	, clear

// histogram of room prices in representative years: 

su price_per if pf_wm==1, det 
foreach n in 10 25 50 75 90 {
	local p`n'_pf=`r(p`n')'
}
su price_per if pf_wm==0, det 
foreach n in 10 25 50 75 90 {
	local p`n'_npf=`r(p`n')'
}

preserve
	gen coarse_price=floor(price_per/25)*25+12.5
	collapse (sum) all, by(coarse_price year pf_wm)

	egen yearN=total(all), by(year pf_wm)
	gen share=all/yearN
	label var coarse_price "Price per occupant"
	label var share "Share"

	// plot smallest cell to get a third color into the legend
	su share , detail

	twoway (bar share coarse_price if pf_wm==1 & year==1928 , barw(25) color($c_pf) ) ///
		(bar share coarse_price if pf_wm==0 & year==1928, barw(25) color($c_npf))  ///
		,scheme(s1color) legend(order(1 "Private feeder" 2 "Other" 3) rows(1)) ///
		title(A. Price per student by high school)  name(g1, replace)
restore

// FIGURE 4B: Histogram of peer group sizes
su n_dorm_nbd if pf_wm==1, det 
foreach n in 10 25 50 75 90 {
	local p`n'_pf=`r(p`n')'
}

su n_dorm_nbd if pf_wm==0, det 
foreach n in 10 25 50 75 90 {
	local p`n'_npf=`r(p`n')'
}

su n_dorm_nbd, det

store_stat p25_n_group "`r(p25)'" 0
store_stat p75_n_group  "`r(p75)'" 0
store_stat mean_n_group "`r(mean)'" 1
store_stat p10_n_group "`r(p10)'" 0
store_stat p90_n_group  "`r(p90)'" 0
store_stat p50_n_group "`r(p50)'" 0

hist n_dorm_nbd , fraction scheme(s1color) color($c_all) ///
	ytitle(Share) xtitle(Peer group size) title(B. Residential peer group size) ///
	name(g2, replace)
	//graph export "${figures}group_size_hist.png", replace width(2400)

gr combine g1 g2 , scheme(s1color) ysize(13) xsize(20)
graph export "${figures}/price_gsize_hist.png", replace width(2400)

// FIGURE 4 C + D: Neighborhood attributes by room price quantile, within year:  
use  "${cleaned}/redbooks_res_sample"	, clear
//keep if year>1919 // or restrictd year>1921

collapse (mean) private_wm pf_wm mpg* mp_dorm_nbd nbdranki ///
	(p10) mpgprivate_wm_10=mpgprivate_wm mpgpf_wm_10=mpgpf_wm mp10=mp_dorm_nbd ///
	mpgrg10=mpgrankgroup1_nr nbdranki10 = nbdranki ///
  (p90) mpgprivate_wm_90=mpgprivate_wm mpgpf_wm_90=mpgpf_wm  mp90=mp_dorm_nbd ///
  mpgrg90=mpgrankgroup1_nr nbdranki90 = nbdranki , by(pq)

 label var pq "Own room price rank" 
 
 su mp10 if pq==1 // only one obs, so stores in mean
 gen mean_above_10ptop=(mp_dorm_nbd>`r(mean)')
 //tab pq mean_above_10ptop, m // all but the lowest ventile
  
twoway (scatter mpgpf_wm_nr pq, msymbol(Oh))   ///
	 (scatter mpgpf_wm_90 pq, msymbol(+) mcolor(gs5)) ///
	 (scatter mpgpf_wm_10 pq, msymbol(+) mcolor(gs5)) ///
	 , scheme(s1color) legend(order(1 "Peer pf mean"  3 "Peer pf p90/p10" ) rows(1)) ///
	 name(g1, replace) title("D. Peer private feeder share")
graph export "${figures}/peer_hstype_by_price.png", replace width(2400)

twoway (scatter nbdranki pq, msymbol(Oh))   ///
	 (scatter nbdranki90 pq, msymbol(+) mcolor(gs5)) ///
	 (scatter nbdranki10 pq, msymbol(+) mcolor(gs5)) ///
	 , scheme(s1color) legend(order(1 "Mean peer price"  3 "Peer price p90/p10" ) rows(1)) ///
	 name(g2, replace) title("C. Peer neighborhood rank")
graph export "${figures}/peer_nbdranki_by_price.png", replace width(2400)
	 
gr combine g2 g1 , scheme(s1color) xcommon ysize(13) xsize(20)
graph export "${figures}/peer_atts_by_price.png", replace width(2400)

graph drop _all