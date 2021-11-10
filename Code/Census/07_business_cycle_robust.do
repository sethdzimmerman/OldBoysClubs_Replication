/*

07_business_cycle_robust.do
(called from master_census.do)

Purpose: producesbusiness cycle related output
Inputs: cleaned/census_rb_merged, cleaned/redbooks_res_sample
Outputs: tables/business-cycle-robust-o_c, tables/bus_cyc_pfx
	
*/

/*
	Business Cycle effects
	run regressions like Y=cohort effects+b*final club+c*final club*UE rate when graduated+e
	-note that we don't need a main effect of UE rate, it will be absorbed by cohort effects.
	-outcomes: 1940 earnings (OLS sample only), finance, medicine, h. ed, law, occupation phs index, occupation wage index
*/

// Table B.21

global o_c "finance doctor hed law zphat_oc any_social_main have_country_club"
global deg "any_grad phd_grad mba_grad md_grad jd_grad"

use "$cleaned/census_rb_merged", clear
label var law "Law"
label var finance "Finance"
label var doctor "Medicine"
label var hed "Higher ed."
label var any_social_main "Any social club"
label var have_country_club "Country club"

gen depression=class>=1930
replace law=. if have_occ==0 // one obs with non-missing law observation but have_occ=0. 

label var zphat_oc "Occ. index"
label var unemp "Unemp. rate"
label var final_tier2 "Sel. fin. club"
label var private_feeder "Priv. fdr."
label var depression "Depression graduate"
gen exp = 1940 - class
gen inc_samp = exp >= 6 & year<=1933 & year>1919
gen o_c_samp=1

replace unemp = unemp * 100 // scale to 1 percentage point

estimates clear

foreach depvar in $o_c {
	reg `depvar' private_feeder final_tier2 ///
		1.final_tier2#1.depression ib1920.year if o_c_samp==1, r
est sto e_`o_c'_`depvar'3
}
	
// Export table
esttab e_`o_c'_* using "$tables/business-cycle-robust-o_c.tex", ///
booktabs nostar noconstant obslast b(%9.3f) se(%9.3f) ///
label drop(*.year _cons) replace nonotes
	
//
//
// peer effects analysis
//
//	
	
// Table B.22
	
use "${cleaned}/redbooks_res_sample", clear

label var final_tier2 "Selective final club"
label var any_social_main "Any social club"
label var zphat_oc "Occupation index"

gen depression=class>=1930 & class<=1939 

estimates clear

//
//
// causal peer fx regressions: 
// reproduce final club outcomes to show results within colonial sample
//	
//

global splist "final_tier2  any_social_main zphat_oc wage_index"
if $ACCESS == 0 {
	global splist "final_tier2  any_social_main zphat_oc"
}

// peer effects: 
foreach out in $splist {
	
reghdfe `out' nbdranki ///
	if pf_wm==1 & depression==0, absorb(price_per_student##roomcap##year i.hs_wm ) ///
	cluster(dorm_nbd_id)
eststo `out'1, noe
	
reghdfe `out'  nbdranki ///
	if pf_wm==1 & depression==1, absorb(price_per_student##roomcap##year i.hs_wm ) ///
	cluster(dorm_nbd_id)
eststo `out'2, noe

reghdfe `out'  ib0.depression##c.nbdranki ///
	if pf_wm==1 , absorb(ib0.depression##price_per_student##roomcap##year ///
	ib0.depression##i.hs_wm ) ///
	cluster(dorm_nbd_id)
test 1.depression#nbdranki
local test_`out'=`r(p)'
	
}

// output 
local t `" "& " _tab"'
local lb `" "\\ " _n"'
local lbh `" "\\ \hline" _n"'

cap file close f 
file open f using "${tables}/bus_cyc_pfx.txt", write replace
file write f "\begin{tabular}{l ccc}"

file write f _n _tab "& Pre-depression cohorts" _tab "& Depression cohorts" _tab "& Test"

 file write f `lbh'

// print coeffs+SEs
local i=0
foreach var in $splist {
 local i=`i'+1
 if `i'==1 file write f  "`:var label `var''"	
 if `i'>1 file write f `lb' "`:var label `var''"
 // file write f `lb' "`:var label `var''"	
 forv j=1/2 {
 estimates restore `var'`j'
 file write f `t' %4.3f (_b[nbdranki])	
 }
 file write f `t' %4.3f (`test_`var'')
 
 file write f `lb'
 forv j=1/2 {
 estimates restore `var'`j'
 file write f `t' "(" %4.3f (_se[nbdranki])	")"
 } 
 
}

// print N 
foreach var in zphat_oc {
 file write f `lbh' "N"	
 forv j=1/2 {
 estimates restore `var'`j'
 file write f `t' %12.0f (`e(N)')	
 }
 
}

file write f `lb' "\end{tabular}"
file close f