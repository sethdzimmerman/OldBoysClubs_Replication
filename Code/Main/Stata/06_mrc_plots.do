/*

06_mrc_plots.do
(called from master.do)

Purpose: producesfamily income figures
Inputs: raw/Other/CLIMB/mrc_table6
Outputs: figures/grec*, tables/mrc-tab

*/

// Figures 8 and A.7

// histograms: 
use "$raw/Other/CLIMB/mrc_table6.dta" , clear
drop if par_pctile==99.9 // this is non-exclusive

twoway (hist par_pctile if tier==1  | tier==2 [fw=count], ///
	color(teal%30) start(0) width(1) fraction) ///
	, scheme(s1color) legend(order(1 "Elite")) title(Histogram of elite college parent income) ///
	name(ghist, replace)

//
// produce parallel of figure 3
// not an exact replication-- they are using microdata. but close
//

use "$raw/Other/CLIMB/mrc_table6.dta" , clear

drop if par_pctile==99.9 // this is non-exclusive

gen ventile=floor(par_pctile/5)*5+2.5
gen coll_group=1 if tier==1 
replace coll_group=2 if tier==2 | tier==3 | tier==4 | tier==5 | tier==6 | tier==7 | tier==8 | tier==10
replace coll_group=3 if tier==9 | tier==11

// generate "all" category
preserve
collapse (mean) k_rank (rawsum) count [fw=count] , by(ventile)
gen coll_group=4 
tempfile ts
save `ts'
restore

collapse (mean) k_rank (rawsum) count [fw=count] , by(ventile coll_group)
append using `ts'

replace k_rank=k_rank*100
label var ventile "Parent rank"

twoway (lfit  k_rank ventile if coll_group==1 [fw=count]) ///
	(scatter  k_rank ventile if coll_group==1, msymbol(Dh) mcolor(green)) ///
	(lfit  k_rank ventile if coll_group==2  [fw=count]) ///
	(scatter  k_rank ventile if coll_group==2, msymbol(Oh) mcolor(orange)) ///
	(lfit k_rank ventile if coll_group==3 [fw=count]) ///
	(scatter k_rank ventile if coll_group==3, msymbol(Th) mcolor(blue)) ///
	(lfit k_rank ventile if coll_group==4 [fw=count]) ///
	(scatter k_rank ventile if coll_group==4, msymbol(X) mcolor(red)) ///	
	, legend(order(2 "Ivy+" 4 "Other 4-year" 6 "2-year" 8 "All") rows(1)) ///
	scheme(s1color) title(A. Kid rank by parent rank )  ///
	name(g1, replace)
graph export "$figures/grec-app-rep.png", width(3200) replace
	
//
//
// now extend figure 3 to break out top 5% of parent income
//
//

use "$raw/Other/CLIMB/mrc_table6.dta" , clear

// fix 99 pctile so that it excludes top 0.1%-- make all categories mutually exclusive
// baseline dataset has overlap between 99 and 99.9
egen density999=max((par_pctile==99.9)*density), by(tier)
foreach var in k_mean k_top1pc k_rank k_nowork k_q1 {
	egen `var'999=max((par_pctile==99.9)*`var'), by(tier)
	replace `var'=(`var'-(density999/density)*`var'999)/(1-(density999/density)) if par_pctile==99
}

// fix densities and counts: 
replace density=density-density999 if par_pctile==99
egen count999=max((par_pctile==99.9)*count), by(tier)
replace count=count-count999 if par_pctile==99

// coarse categories
gen ventile=floor(par_pctile/5)*5+2.5
replace ventile=par_pctile if par_pctile>=95
gen coll_group=1 if tier==1 // Ivy+
replace coll_group=2 if tier==2 |tier==3 | tier==4 | tier==5 | tier==6 | tier==7 | tier==8 | tier==10 // all other 4-year
replace coll_group=3 if tier==9 | tier==11

// generate "all" category
preserve
collapse (mean) k_rank k_top1pc k_mean k_nowork k_q1  k_q2 k_q3 k_q4 (rawsum) count [fw=count] , by(ventile)
gen coll_group=4 
tempfile ts
save `ts'
restore

collapse (mean) k_rank k_top1pc k_mean k_nowork k_q1  k_q2 k_q3 k_q4 (rawsum) count [fw=count] ///
 , by(ventile coll_group)
append using `ts'

replace k_rank=k_rank*100
replace k_mean=k_mean/1000
label var ventile "Parent rank"
label var k_mean "Mean inc" 
label var k_top1pc "Top 1%"
label var k_nowork "Not working"
label var k_rank "Mean rank"

keep if ventile>=80

twoway (connect  k_rank ventile if coll_group==1, msymbol(Dh) mcolor(green) msize(large) lpattern(dash) lcolor(gs7)) ///
	(connect  k_rank ventile if coll_group==2, msymbol(Oh) mcolor(orange) lpattern(dot) lcolor(gs7)) ///
	(connect k_rank ventile if coll_group==4, msymbol(X) mcolor(red) lpattern(solid) lcolor(gs7)) ///	
	, legend(order(1 "Ivy+" 2 "Other 4-year" 3 "All") rows(1)) ///
	scheme(s1color) title(B. Kid rank by parent rank-- zoomed in) ///
	 name(g2, replace) xlabel(85(5)100)
graph export "$figures/grec-app-rz.png", width(3200) replace

twoway (connect  k_mean ventile if coll_group==1, msymbol(Dh) mcolor(green) msize(large) lpattern(dash) lcolor(gs7)) ///
	, legend(order(1 "Ivy+") rows(1)) ///
	scheme(s1color) title(B. Kid mean income by parent rank) ///
	 name(g3, replace) xlabel(85(5)100) ytitle("Mean income (1000s)")
	 
graph export "$figures/grec-main-means.png", width(3200) replace

twoway (connect  k_top1pc ventile if coll_group==1, msymbol(Dh) mcolor(green) msize(large) lpattern(dash) lcolor(gs7)) ///
	, legend(order(1 "Ivy+") rows(1)) ///
	scheme(s1color) title(C. Kid top 1% by parent rank) ///
	 name(g4, replace) xlabel(85(5)100)
graph export "$figures/grec-main-1pc.png", width(3200) replace

// share not working goes up! that's what explains this
twoway (connect  k_nowork ventile if coll_group==1, msymbol(Dh) mcolor(green) msize(large) lpattern(dash) lcolor(gs7)) ///
	(connect  k_nowork ventile if coll_group==2, msymbol(Oh) mcolor(orange) lpattern(dot) lcolor(gs7)) ///
	(connect k_nowork  ventile if coll_group==4, msymbol(X) mcolor(red) lpattern(solid) lcolor(gs7)) ///	
	, legend(order(1 "Ivy+" 2 "Other 4-year" 3 "All") rows(1)) ///
	scheme(s1color) title(C. Kid share not working by parent rank) ///
	 name(g5, replace) xlabel(85(5)100)
graph export "$figures/grec-app-nw.png", width(3200) replace
		
// by quintiles, for qunitles 1-4: 
forv q=1/4 {
if `q'==1 local panel="D"
if `q'==2 local panel="E"
if `q'==3 local panel="F"
if `q'==4 local panel="G"

twoway (connect  k_q`q'  ventile if coll_group==1, msymbol(Dh) mcolor(green) msize(large) lpattern(dash) lcolor(gs7)) ///
	(connect  k_q`q'  ventile if coll_group==2, msymbol(Oh) mcolor(orange) lpattern(dot) lcolor(gs7)) ///
	(connect k_q`q'   ventile if coll_group==4, msymbol(X) mcolor(red) lpattern(solid) lcolor(gs7)) ///	
	, legend(order(1 "Ivy+" 2 "Other 4-year" 3 "All") rows(1)) ///
	scheme(s1color) title(`panel'. Kid Q`q' share by parent rank) ///
	 name(gq`q', replace) xlabel(85(5)100) ytitle("k_q`q'")
graph export "$figures/grec-app-q`q'.png", width(3200) replace
}			
			
// histograms: 
use "$raw/Other/CLIMB/mrc_table6.dta" , clear
drop if par_pctile==99.9 // non-exclusive

twoway (hist par_pctile if tier==1   [fw=count], ///
	color(teal%30) start(0) width(1) fraction) ///
	, scheme(s1color) legend(order(1 "Ivy+")) title(A. Histogram of Ivy+ parent income) ///
	name(ghist, replace)		
graph export "$figures/grec-main-hist.png", width(3200) replace
	
graph drop _all	

use "$raw/Other/CLIMB/mrc_table6.dta" , clear

// 
//
// Tabular output
//
//
// Table A.18

use "$raw/Other/CLIMB/mrc_table6.dta" , clear

// fix tot_count so it is always non-missing (and equal to total value in tier)
egen mtc=mean(tot_count), by(tier)
replace tot_count=mtc if mi(tot_count)
drop mtc

// fix counts to zero if non-reported
replace count=0 if count==. 

// fix 99 pctile so that it excludes top 0.1%-- make all categories mutually exclusive
// baseline dataset has overlap between 99 and 99.9
egen density999=max((par_pctile==99.9)*density), by(tier)
foreach var in k_mean k_top1pc k_rank k_nowork k_q1 {
	egen `var'999=max((par_pctile==99.9)*`var'), by(tier)
	replace `var'=(`var'-(density999/density)*`var'999)/(1-(density999/density)) if par_pctile==99
}

// fix densities and counts: 
replace density=density-density999 if par_pctile==99
egen count999=max((par_pctile==99.9)*count), by(tier)
replace count=count-count999 if par_pctile==99

// dollars in 1000s
replace k_mean=k_mean/1000

// generate college categories
gen coll_group=1 if tier==1 // ivy plus
replace coll_group=2 if tier==2 // other elite 
replace coll_group=3 if tier==3 | tier==4 | tier==5 | tier==6 | tier==7 | tier==8 | tier==10 // other 4-year
replace coll_group=4 if  tier==9 | tier==11 // 2-year
replace coll_group=5 if tier>=14 // no college

// exclude colleges with too little data to report
drop if mi(coll_group)

// generate total counts-- note: have to do this here because rawsum omits zero weights, this is a dumb stata feature
egen tc_group=total(tot_count), by(par_pctile coll_group)

// collapse: 
collapse (mean) k_mean k_top1pc k_rank k_nowork k_q1 tc_group (rawsum) count  [fw=count] , by(par_pctile coll_group)

label define coll_group 1 "Ivy+" 2 "Other elite" 3 "Other 4yr" 4 "2 year" 5 "No college"
label values coll_group coll_group 
 
// initialize file: 

cap file close f
file open f using  "$tables/mrc-tab.tex", write replace

file write f "\begin{tabular}{l*{5}{c}}"_n
file write f "\toprule"_n
// column labels: 
forv c=1/5 {
	file write f " & `:label coll_group `c''"
}
file write f "\\"_n
file write f "\midrule"_n

// Sample counts
file write f "\emph{A. Sample counts} \\"
file write f _n "N students"
forv c=1/5 {
	su tc_group if coll_group==`c' // note: SD should be zero here
	file write f "& " %12.0f (`r(mean)') 
}
file write f "\\"

// continuing panel A: shares in income distribution
gen top999=par_pctile>=99.9
gen top99=par_pctile>=99 & par_pctile<99.9
gen top9599=par_pctile>=95 & par_pctile<99
gen top9095=par_pctile>=90 & par_pctile<95
gen top8090=par_pctile<90 & par_pctile>=80
gen bot80=par_pctile<80

label var top999 "Top 0.1\%"
label var top99 "99-99.9\%"
label var top9599 "95-99\%"
label var top9095 "90-95\%"
label var top8090 "80-90\%"
label var bot80 "$<$80\%"

file write f "\\"
file write f _n "\emph{B. Distribution of parent income} \\"

foreach var in top999 top99 top9599 top9095 top8090 bot80 {
	file write f _n "`:var label `var''"
	forv c=1/5 {
		su `var' if coll_group==`c' [fw=count]
		file write f " & " %5.4f (`r(mean)')
	}
	file write f "\\"
}

file write f "\\"
// kid outcomes by parent income
file write f _n "\emph{C. Kid outcomes by parent income} \\"

label var k_rank "Mean rank"
label var k_mean "Mean income"
label var k_top1pc "Top 1\% share"
label var k_nowork "Share not working"

foreach var in k_rank k_mean k_top1pc k_nowork {
	file write f _n "`:var label `var'' \\"
	
	foreach pgroup in top999 top99 top9599 top9095 top8090 bot80 {
		file write f _n "\hspace{3mm} `:var label `pgroup''"
		forv c=1/5 {
			su `var' if coll_group==`c' & `pgroup'==1 [fw=count]
			if "`var'"!="k_mean" file write f " & " %5.4f (`r(mean)')
			if "`var'"=="k_mean" file write f " & " %4.0f (`r(mean)')
		}
		file write f "\\"
	}
}

file write f _n "\bottomrule"
file write f _n "\end{tabular}" _n
file close f