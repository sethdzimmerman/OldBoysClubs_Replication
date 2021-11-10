/*

03e_rand_blocks.do
(called from 03_descriptive.do)

Purpose: produces randomization blocks related ouput
Inputs: cleaned/redbooks_res_sample
Outputs: figures/block_size_hist, figures/rand_support_C_pf, figures/rand_support_B_price,
	figures/rand_support_B_nbdranki, figures/rand_support
	
*/

/*
    Produces Figure 5: 
        - Randomization block size and within-block variation 
        in peer attributes

*/

// Figure 5A: Distribution of rand. block sizes

use  "${cleaned}/redbooks_res_sample"	, clear
// keep if year>1919 // or restricted 1921

// size of rblocks: 
bys ${rblock}: gen blocksize=_N

su blocksize if pf_wm==1, det 
foreach n in 10 25 50 75 90 {
	local p`n'_pf=`r(p`n')'
}
su blocksize if pf_wm==0, det 
foreach n in 10 25 50 75 90 {
	local p`n'_npf=`r(p`n')'
}

su blocksize,det
store_stat p25_n_block "`r(p25)'" 0
store_stat p75_n_block  "`r(p75)'" 0
store_stat mean_n_block "`r(mean)'" 1
store_stat p10_n_block "`r(p10)'" 0
store_stat p90_n_block  "`r(p90)'" 0
store_stat p50_n_block "`r(p50)'" 0

hist blocksize , scheme(s1color) color($c_all) freq ///
	xline(`r(p75)', lcolor($c_line_all) lwidth(thick) lpattern(dash)) ///
	xline(`r(p25)', lcolor($c_line_all) lwidth(thick) lpattern(dash)) /// 
xtitle(Randomization block size) name(g0, replace) title(A. Distribution of randomization block sizes) 
	
graph export "${figures}/block_size_hist.png", replace width(2400)

// Figure 5 B + C: Peer neighborhood rank and private feeder share

use  "${cleaned}/redbooks_res_sample"	, clear


foreach var in mpgpf_wm_nr mp_dorm_nbd nbdranki { 
	su `var', det
	foreach k of numlist 10 90 { //25 50 75
		local `var'p`k'=`r(p`k')'
	}

	su `var' if pf_wm==1, det
	foreach k of numlist 10 90 {
		local `var'p`k'_pf=`r(p`k')'	
	}

	su `var' if pf_wm==0, det
	foreach k of numlist 10 90 {
		local `var'p`k'_npf=`r(p`k')'	
	}
}

collapse (mean) mpgprivate_wm_nr mp_dorm_nbd nbdranki ///
	(max) mpg_max=mpgpf_wm_nr mp_max=mp_dorm_nbd nbdranki_max=nbdranki ///
	(min) mpg_min=mpgpf_wm_nr mp_min=mp_dorm_nbd nbdranki_min=nbdranki ///
	(sum) all /// 
	, by(${rblock})
	
keep if all>8 // top 90% -> no, top 80%
expand all

sort mpg_max mpg_min ${rblock}
gen rank=_n

di "Median is: `mpgprivate_wm_nrp50'"

twoway (rarea mpg_max mpg_min rank, horizontal color($c_all)) ///
	, scheme(s1color) xtitle(Range of peer attributes) ytitle(Count of students) ///
	xline(`mpgpf_wm_nrp90', lcolor($c_line_all) lwidth(thick) lpattern(dash)) ///
	xline(`mpgpf_wm_nrp10', lcolor($c_line_all) lwidth(thick) lpattern(dash)) ///
	name(g1, replace) title(C. Peer private feeder share)
graph export "${figures}/rand_support_C_pf.png", replace width(2400)

drop rank
	
sort mp_max mp_min ${rblock}
gen rank=_n
twoway (rarea mp_max mp_min rank, horizontal color($c_all)) ///
	, scheme(s1color) xtitle(Range of local prices) ytitle(Count of students) ///
	xline(`mp_dorm_nbdp90', lcolor($c_line_all) lwidth(thick) lpattern(dash)) ///
	xline(`mp_dorm_nbdp10', lcolor($c_line_all) lwidth(thick) lpattern(dash)) ///
	name(g2_old, replace) title(B. Peer room prices)
graph export "${figures}/rand_support_B_price.png", replace width(2400)

drop rank
sort nbdranki_max nbdranki_min ${rblock}
gen rank=_n
twoway (rarea nbdranki_max nbdranki_min rank, horizontal color($c_all)) ///
	, scheme(s1color) xtitle(Range of peer neighborhood rank) ytitle(Count of students) ///
	xline(`nbdrankip90', lcolor($c_line_all) lwidth(thick) lpattern(dash)) ///
	xline(`nbdrankip10', lcolor($c_line_all) lwidth(thick) lpattern(dash)) ///
	name(g2, replace) title(B. Peer neighborhood rank)
graph export "${figures}/rand_support_B_nbdranki.png", replace width(2400)
	
drop rank
	
graph combine g2 g1 , scheme(s1color) xsize(20) ysize(13) rows(1)
graph export "${figures}/rand_support.png", replace width(2400)

// share of variation within rblocks
use  "${cleaned}/redbooks_res_sample"	, clear

reghdfe mp_dorm_nbd, absorb($rblock)
gen sample=e(sample)

// compute within year total sum of squares: 
reghdfe mp_dorm_nbd if sample==1, absorb(i.year)
local tss_wy=`e(tss_within)'

reghdfe mp_dorm_nbd, absorb($rblock)
local tss_rb=`e(tss_within)'
di "Share of variation: price" `tss_rb'/`tss_wy'
local rblock_share_var_price=`tss_rb'/`tss_wy'
store_stat rblock_share_var_price `rblock_share_var_price' 0 per

// compute within year total sum of squares: 
reghdfe mpgprivate_wm_nr if sample==1, absorb(i.year)
local tss_wy=`e(tss_within)'

reghdfe mpgprivate_wm_nr, absorb($rblock)
local tss_rb=`e(tss_within)'
di `tss_rb'/`tss_wy'
local rblock_share_var_priv=`tss_rb'/`tss_wy'
store_stat rblock_share_var_priv `rblock_share_var_priv' 0 per