/*

10_spouse_analysis.do
(called from master_census.do)

Purpose: producesspouse related output
Inputs: cleaned/census_rb_merged
Outputs: intstata/s1, intstata/s2, intstata/s3, figures/spouse_binscatter, 
	tables/spouse-desc, tables/spouse_descriptive, tables/spouse_pfx
	
*/

//
//
// spouse appendix material
//
//

// 1. descriptive binscatters on assortative matching
// 2. descriptive regressions on club membership and finance careers
// 3. assortative matching as LHS variable in peer effect regressions

// use merged Census data: 
use "$cleaned/census_rb_merged", clear

if $ACCESS == 1 {
	// identify self/spouses: 
	// category identifiers: 
	gen wasp_self=oldMA_lnindex>=0.7 if !mi(oldMA_lnindex)
	gen jewish_self=jewish_index>=0.7 if !mi(jewish_index)
	gen cath_self=cath_index>=0.7 if !mi(cath_index)

	// these variables are indicators for being married AND having spouse of given type
	// i.e., non-married people have spouse type variables equal to zero
	// look only within sample merged to class reps (has_pid==1); otherwise we don't see spouses at all
	gen wasp_spouse=oldMA_lnindex_spouse>0.7 & !mi(oldMA_lnindex_spouse) & married==1 if has_pid==1
	gen jewish_spouse=jewish_lnindex_spouse>0.7 & !mi(jewish_lnindex_spouse) & married==1 if has_pid==1
	gen cath_spouse=cath_lnindex_spouse>0.7 & !mi(cath_lnindex_spouse) & married==1 if has_pid==1

	gen wasp_couple=wasp_spouse*wasp_self

	// labeling: 
	label var wasp_spouse "Colonial spouse"
	label var jewish_spouse "Jewish spouse"
	label var cath_spouse "Catholic spouse"

	label var jewish_index "Jewish index"
	label var cath_index "Catholic index"
	label var oldMA_lnindex_spouse "Colonial index"

	label var wasp_couple "Colonial marriage"

	// basic facts on assortative matching:
	// use binsreg command to select binning approach
	// control for cohort effects
	binsreg wasp_spouse oldMA_lnindex ib1920.year if married==1, ///
		dotsgrid(mean) ///
		savedata(${intstata}/s1) replace
		
	binsreg jewish_spouse jewish_index ib1920.year if married==1, ///
		dotsgrid(mean) ///
		savedata(${intstata}/s2) replace
		
	binsreg cath_spouse cath_index ib1920.year if married==1, ///
		dotsgrid(mean) ///
		savedata(${intstata}/s3) replace

	// compile graphs:

	preserve
	use "${intstata}/s1", clear
	ren dots_x dots_wasp
	ren dots_fit y_wasp

	merge 1:1 dots_binid using "${intstata}/s2", nogen
	ren dots_x dots_jew
	ren dots_fit y_jew

	merge 1:1 dots_binid using "${intstata}/s3", nogen
	ren dots_x dots_cath
	ren dots_fit y_cath

	// Figure B.18

	twoway (connect y_wasp dots_wasp, msymbol(Oh)) ///
		(connect y_jew dots_jew, msymbol(Th)) ///
		(connect y_cath dots_cath, msymbol(+)) ///
		, scheme(s1color) ///
		legend(order(1 "Colonial" 2 "Jewish" 3 "Catholic") rows(1)) ///
		ytitle(Spouse of given background) xtitle(Own name index value)
	graph export "${figures}/spouse_binscatter.png", width(3200) replace
	restore
}

// descriptive statistics table: 

// Table B.26

gen have_spousename=!mi(spousename) if married==1 // have spouse name
label var have_spousename "Have spouse name"

label var all "All"
label var hasty "Hasty Pudding"
label var final_tier2 "Final club"
label var pf_wm "Private feeder"
label var npf_wm "All non-private"

global samples "all pf_wm npf_wm hasty final_tier2"
global rowsA "married"
global rowsB ""

if $ACCESS == 1 {
	gen have_spousescore=!mi(oldMA_lnindex_spouse) if married==1 // have spouse name colonial score
	label var have_spousescore "Have spouse name score"
	global samples "all pf_wm npf_wm hasty final_tier2"
	global rowsA "married"
	global rowsB " have_spousescore jewish_spouse cath_spouse wasp_spouse wasp_couple"
}

// Open file
cap file close f 
file open f using "$tables/spouse-desc.tex", write replace
file write f "\begin{tabular}{l*{5}{c}}"_n
file write f "\toprule"_n

// Column headers
foreach samp in $samples {
    file write f "& `: var la `samp''"
}
file write f "\\" _n
file write f "\midrule"_n
write_panel "$rowsA" "$samples" "A. Marriage rates" "all"
write_panel "$rowsB" "$samples" "B. Spouse attributes" "married"

// Sample sizes
file write f "\\"_n
file write f "N"
foreach samp in $samples {

		count if `samp'==1 & has_pid==1
		file write f _tab "&" %9.0f (`r(N)')
	
}
file write f "\\"_n

// Close file
file write f "\bottomrule"_n
file write f "\end{tabular}"_n
file close f	

// save numbers for text    
// percent married
su married if has_pid==1 & all==1
store_stat perc_married "`r(mean)'" 0 per 
su married if has_pid==1 & final_tier2==1
store_stat perc_married_t2 "`r(mean)'" 0 per 

if $ACCESS == 1 {
	// conditional on being married 
	su have_spousescore if married==1
	store_stat perc_spousescore_mar "`r(mean)'" 0 per 
	foreach ethn in jewish wasp {
	su `ethn'_spouse if married==1
	store_stat perc_`ethn'sp_mar "`r(mean)'" 1 per 
	su `ethn'_spouse if married==1 & pf_wm==1
	store_stat perc_`ethn'sp_mar_pf "`r(mean)'" 1 per 
	su `ethn'_spouse if married==1 & final_tier2==1
	store_stat perc_`ethn'sp_mar_t2 "`r(mean)'" 1 per 
	}
}
	
// descriptive regressions
// Table B.27

label var finance "Finance"
label var any_social_main "Social club" 
label var have_country_club "Country club"

if $ACCESS == 1 {
	label var wasp_self "Colonial"
	label var married "Married"
	label var wasp_spouse "Colonial spouse"
	foreach var in finance any_social_main have_country_club {
		reg `var'  wasp_self final_tier2 pf_wm  i.year, r
		eststo `var'1, noe
	 
		reg `var' wasp_spouse married  wasp_couple wasp_self final_tier2 pf_wm  i.year, r
		eststo `var'2, noe
	}

	esttab finance1 finance2 any_social_main1 any_social_main2 have_country_club1 have_country_club2 ///
		using ${tables}/spouse_descriptive.tex, replace nostar b(%4.3f) se(%4.3f) se paren ///
		label keep(wasp_self final_tier2 pf_wm wasp_spouse married wasp_couple) ///
		order(wasp_self final_tier2 pf_wm married wasp_spouse wasp_couple) booktabs nonotes
}
	
if $ACCESS == 0 {
	foreach var in finance any_social_main have_country_club {
		reg `var' final_tier2 pf_wm  i.year, r
		eststo `var'1, noe
	 
		reg `var' married final_tier2 pf_wm  i.year, r
		eststo `var'2, noe
	}
	esttab finance1 finance2 any_social_main1 any_social_main2 have_country_club1 have_country_club2 ///
		using ${tables}/spouse_descriptive.tex, replace nostar b(%4.3f) se(%4.3f) se paren ///
		label keep(final_tier2 pf_wm married) ///
		order(final_tier2 pf_wm married) booktabs nonotes
	
}
	
//
//
// causal peer fx regressions: 
// reproduce final club outcomes to show results within colonial sample
//	
//

global splist "final_tier2 married wasp_spouse wasp_couple"

if $ACCESS == 0 {
	global splist "final_tier2 married"
}
	
// Table B.28
// peer effects: 
foreach out in $splist {
	
reghdfe `out' nbdranki ///
	, absorb(price_per_student##roomcap##year i.hs_wm ) ///
	cluster(dorm_nbd_id)
eststo `out'1, noe
	
reghdfe `out'  nbdranki ///
	if pf_wm==1, absorb(price_per_student##roomcap##year i.hs_wm ) ///
	cluster(dorm_nbd_id)
eststo `out'2, noe

reghdfe `out' nbdranki ///
	if pf_wm==0 , absorb(price_per_student##roomcap##year  i.hs_wm) ///
	cluster(dorm_nbd_id)
eststo `out'3, noe

if $ACCESS == 1 {
	reghdfe `out'  nbdranki ///
		if wasp_self==1 , absorb(price_per_student##roomcap##year i.hs_wm ) ///
		cluster(dorm_nbd_id)
	eststo `out'4, noe
		
	reghdfe `out' nbdranki ///
		if wasp_self==0  , absorb(price_per_student##roomcap##year  i.hs_wm) ///
		cluster(dorm_nbd_id)	
	eststo `out'5, noe
}
	
}

// output 
local t `" "& " _tab"'
local lb `" "\\ " _n"'
local lbh `" "\\ \hline" _n"'

cap file close f 
file open f using "${tables}/spouse_pfx.txt", write replace
file write f "\begin{tabular}{l c cc cc}"

file write f _n _tab "& All"  _tab "& Private" _tab "& Non-private" _tab "& Colonial" _tab "& Non-Colonial"

 file write f `lbh'

// print coeffs+SEs
local i=0

if $ACCESS == 1 {
	foreach var in $splist {
	 local i=`i'+1
	 if `i'==1 file write f  "`:var label `var''"	
	 if `i'>1 file write f `lb' "`:var label `var''"
	 // file write f `lb' "`:var label `var''"	
	 forv j=1/5 {
	 estimates restore `var'`j'
	 file write f `t' %4.3f (_b[nbdranki])	
	 }
	 file write f `lb'
	 forv j=1/5 {
	 estimates restore `var'`j'
	 file write f `t' "(" %4.3f (_se[nbdranki])	")"
	 } 
	 
	}

	// print N 
	foreach var in married {
	 file write f `lbh' "N"	
	 forv j=1/5 {
	 estimates restore `var'`j'
	 file write f `t' %12.0f (`e(N)')	
	 }
	 
	} 
}

if $ACCESS == 0 {
	foreach var in $splist {
	 local i=`i'+1
	 if `i'==1 file write f  "`:var label `var''"	
	 if `i'>1 file write f `lb' "`:var label `var''"
	 // file write f `lb' "`:var label `var''"	
	 forv j=1/3 {
	 estimates restore `var'`j'
	 file write f `t' %4.3f (_b[nbdranki])	
	 }
	 file write f `lb'
	 forv j=1/3 {
	 estimates restore `var'`j'
	 file write f `t' "(" %4.3f (_se[nbdranki])	")"
	 } 
	 
	}

	// print N 
	foreach var in married {
	 file write f `lbh' "N"	
	 forv j=1/3 {
	 estimates restore `var'`j'
	 file write f `t' %12.0f (`e(N)')	
	 }
	 
	} 
}

file write f `lb' "\end{tabular}"
file close f