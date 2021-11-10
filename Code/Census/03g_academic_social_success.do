/*

03g_academic_social_success.do
(called from 03_descriptive.do)

Purpose: produces grades related output
Inputs: cleaned/census_rb_merged
Outputs: tables/grades*
	
*/


/*
	Produces Table 4/A.4 and Table B.14/15: Labor market outcomes by academic
	and social success
		- Table 4: Academic rank in 1st year
		- Table B.11: Academic rank in 3rd year
		
	Predict earnings by academic and social success in college as well as 
	high school background
	
*/

//
// program to output coefs and SEs for list of outcome variables 
// and coefficients
// argument 1: list of coefficients-- RHS variables for rows
// argument 2: list of LHS variables for columns
// argument 3: panel title
// argument 4: letter of panel title to distinguish stored coefficients
// all need to be stored in regressions in advance. 
// name of regressions in memory should correspond to column labels in arg 2
cap program drop lineout
program define lineout
	// write title: 
	file write f $lb 
	if "`3'"!="A. Baseline "{
		file write f $lb 
	}
	//file write f "\emph{`3'}"
	file write f  "\multicolumn{5}{l}{\emph{`3'}}" 
	foreach coef in `1' {
		
		// write coef: 	
		file write f $lb "`:var label `coef''"
		foreach var in `2' {
			estimates restore `var'
			if "`var'"!="incwage1940_clean" & "`var'"!="tcinc" & "`var'"!="tcinc1p4" file write f $tab %4.3f (_b[`coef'])
			if "`var'"=="incwage1940_clean" | "`var'"=="tcinc" | "`var'"=="tcinc1p4" {
				file write f $tab %12.0f (_b[`coef'])
			} 
			local short_var "`var''"
			if "`var'"=="incwage1940_clean" local short_var "inc"
			if "`var'"=="have_wage" local short_var "hw"  
			if "`var'"=="topincwg1940" local short_var "tc"
			if "`var'"=="incnonwg1940_clean" local short_var "nw"   
			global `4'_`short_var'_`coef'=_b[`coef']
		}

		// write se: 
		file write f $lb

		foreach var in `2' {
			estimates restore `var'
			if "`var'"!="incwage1940_clean" &"`var'"!="tcinc" & "`var'"!="tcinc1p4" file write f $tab "(" %4.3f (_se[`coef']) ")"
			if "`var'"=="incwage1940_clean" | "`var'"=="tcinc" | "`var'"=="tcinc1p4" file write f $tab "(" %12.0f (_se[`coef']) ")" 
			if "`var'"=="incwage1940_clean"	global `4'_inc_`coef'_se=_se[`coef']
		}	
	}

	// write Mean
	file write f $lb "Sample mean" 

	foreach var in `2' {
		su `var' if esamp_`4'_`var'==1
		if "`var'"!="incwage1940_clean"  & "`var'"!="tcinc" & "`var'"!="tcinc1p4" file write f $tab  %4.3f (`r(mean)')
		if "`var'"=="incwage1940_clean"  | "`var'"=="tcinc" | "`var'"=="tcinc1p4" file write f $tab  %12.0f (`r(mean)')
	}
		
	// write N 
	file write f $lb "N" 

	foreach var in `2' {
		estimates restore `var'
		file write f $tab  %12.0f (`e(N)')
		if "`4'"=="D" global N_brofam_D=`e(N)'
	}	
end

use "$cleaned/census_rb_merged", clear

keep if year<=1933 & year>1919 //years for which we have matchs
gen exp=1940-class // this is how many years out from graduation people are in 1940
keep if exp>=6 // 6 years since expected graduation to allow for some convergence
replace rankgroup1=rankgroup1*-1 // reverse sign so better grades are higher numbers
replace rankgroup3=rankgroup3*-1 // reverse sign so better grades are higher numbers
tab year, m // max should be 1930 if exp==6
// replace rankgroup1=rankgroup1/6 // put on 0-1 scale

gen all_hs_wm=schoolcode1
replace all_hs_wm=0 if mi(schoolcode1)
*gen logearn=log(incwage1940_clean)
gen have_wage=!mi(incwage1940_clean )

label var pf_wm "Private feeder"
label var rankgroup1 "Class rank"
label var final_tier2 "Selective final club"  

** for Harvard & Beyond comparison:
** construct log wages with top codes imputed for doctors and lawyers and all topcodes scaled up
gen tcinc=incwage1940_clean
replace tcinc=5000 if cen_law==1 | cen_doc==1  
gen tcinc1p4=tcinc
replace tcinc1p4=tcinc1p4*1.4 if tcinc1p4==5000 // multiplying topcodes by 1.4 to follow footnote 5 of Goldin Katz 2008
gen lntcinc=log(tcinc)

** rankgroup 3 with missing data+missing data flag
gen nog1=mi(rankgroup1)
gen rankgroup1wm=rankgroup1
replace rankgroup1wm=-6 if mi(rankgroup1wm) // nog3 measures effects of misisng grades relative to lowest rank group

label var nog1 "No academic rank"
label var rankgroup1wm "Class rank year 1"

** report standard deviation of rankgroup3 
** notes:
*	- we have already dropped non-census cohorts, so those are not included
*	- this sd is across cohorts (not within as we frequently do with test scores etc)
* 	- I am not omitting students missing earnings. GK 2008 do, but only 317 of their 6000+ obs are missing earnings (selection into earnings being reported is very different for them than for us), so standardizing across the whole population seemed better for the comparison
*	- will report this sd in table note so can draw direct comparisons

su rankgroup3
store_stat sd_rg3 `r(sd)' 2

	// Panel II: private school, class rank, social participation
	reg incwage1940_clean pf_wm rankgroup1  final_tier2 i.year ,r 	
	reghdfe  incwage1940_clean pf_wm rankgroup1  final_tier2 ///
	 , absorb( preH_d_emp preH_ownershp_clean preH_f_occ1950 year preH_famsize ///
	  preH_fbpl preH_mbpl preH_farm preH_hhtype ) vce(robust) 	

///////////////////////////////
// Produce Tables: 			 //
//	- Table 4.A.4: rankgroup1    //
//	- Table B.14/15: rankgroup3, robustness //
///////////////////////////////

// TABLE B.15
foreach rg_var in rankgroup3  rankgroup1  { 

	cap file close f 
	if "`rg_var'"=="rankgroup1" {
		global outlist "have_wage incwage1940_clean topincwg1940 incnonwg1940_clean"  
		file open f using "${tables}/grades1_soc_reg.txt", write replace
		file write f "\begin{tabular}{l cccc}"
		file write f $tab "Has earnings" $tab "Earnings" $tab "Topcoded" $tab "Non-wage"
	}

	if "`rg_var'"=="rankgroup3" {
		global outlist "have_wage incwage1940_clean topincwg1940 incnonwg1940_clean tcinc tcinc1p4"  
		file open f using "${tables}/grades3_soc_reg.txt", write replace
		file write f "\begin{tabular}{l cccccc}"
		file write f $tab "Has earnings" $tab "Earnings" $tab "Topcoded" $tab "Non-wage" $tab "Imputed wages" $tab "Topcodes x 1.4"
	}	

	// baseline - only used for number in paper, not used in table B.15
	global coeflist "pf_wm `rg_var'" 
	foreach var in $outlist {
		reg `var' $coeflist i.year if !mi(final_tier2) ,r 
		gen esamp_A_`var'=e(sample)
		eststo `var', noe	
	}

	// saves coefficient, but makes table
	// we need to reset the table
	lineout "${coeflist} " "${outlist}" "" "A"
	
	// which we do here
	file close f
	if "`rg_var'"=="rankgroup1" {
		global outlist "have_wage incwage1940_clean topincwg1940 incnonwg1940_clean"  
		file open f using "${tables}/grades1_soc_reg.txt", write replace
		file write f "\begin{tabular}{l cccc}"
		file write f $tab "Has earnings" $tab "Earnings" $tab "Topcoded" $tab "Non-wage"
	}

	if "`rg_var'"=="rankgroup3" {
		global outlist "have_wage incwage1940_clean topincwg1940 incnonwg1940_clean tcinc tcinc1p4"  
		file open f using "${tables}/grades3_soc_reg.txt", write replace
		file write f "\begin{tabular}{l cccccc}"
		file write f $tab "Has earnings" $tab "Earnings" $tab "Topcoded" $tab "Non-wage" $tab "Imputed wages" $tab "Topcodes x 1.4"
	}
	
	file write f $l
	
	// Panel I: private school, class rank, social participation
	global coeflist "pf_wm `rg_var' final_tier2" 

	foreach var in $outlist {
		reg `var' $coeflist i.year ,r 	
		gen esamp_B_`var'=e(sample)
		eststo `var', noe	
	}

	lineout "${coeflist} " "${outlist}" "A. Add most elite final clubs" "B"

	// Panel II: extended Census controls
	  
	global coeflist "pf_wm `rg_var' final_tier2" 

	foreach var in $outlist {
		reghdfe `var' $coeflist i.year , vce(robust) ///
		absorb(	preH_d_emp preH_ownershp_clean preH_f_occ1950 year preH_famsize ///
		preH_fbpl preH_mbpl preH_farm preH_hhtype)
		gen esamp_X_`var'=e(sample)
		eststo `var', noe	
	}	  
	lineout "${coeflist} " "${outlist}" "B. Add Census family background controls" "X"
	
	// Panel III: class rank, social, +HS FEs, legacy indicators
	global coeflist "`rg_var' final_tier2 harvard_father" 

	foreach var in $outlist {
		reghdfe  `var' $coeflist i.year if pf_wm==1, vce(robust) absorb(all_hs_wm)
		gen esamp_C_`var'=e(sample)
		eststo `var', noe	
	}

	lineout "${coeflist} " "${outlist}" "C. Private feeders with HS FEs, legacy indicators" "C"
	
	
	// Panel IV: class rank, social, +*family* FEs
	global coeflist "`rg_var' final_tier2 " 

	foreach var in $outlist {
		reghdfe  `var' $coeflist i.year if !mi(family_id), cluster(family_id) absorb(family_id)
		gen esamp_D_`var'=e(sample)
		eststo `var', noe	
	}
	lineout "${coeflist} " "${outlist}" "D. Within family" "D"


	// Panel V: private school, class rank, social participation
	global coeflist "pf_wm `rg_var' final_tier2" 

	foreach var in $outlist {
		reg `var' $coeflist i.year if hasty==1,r 	
		gen esamp_E_`var'=e(sample)
		eststo `var', noe	
	}

	lineout "${coeflist} " "${outlist}" "E. Within Hasty Pudding (approximate applicant pool)" "E"

	file write f $llb _n "\end{tabular}"

	file close f 

	// Panel B coef and se for appendix B for first and third year grades (used to be a panel C comparison before dropped and renumbered)
	if "`rg_var'"=="rankgroup1" {
		store_stat reg_B_inc_rg1 "${B_inc_rankgroup1}" 0
		store_stat reg_B_inc_rg1_se "${B_inc_rankgroup1_se}" 0
	}
	if "`rg_var'"=="rankgroup3" {
		store_stat reg_B_inc_rg3 "${B_inc_rankgroup3}" 0
		store_stat reg_B_inc_rg3_se "${B_inc_rankgroup3_se}" 0
	}


	if "`rg_var'"!="rankgroup1" drop esamp* // for now, want stats for text to only refer to rankgroup1, so make sure it is run last
}

/////////////////////////////////////////
//
// Table B.14 MISSING RANK GROUP DATA
//
//////////////////////////////////////////
global outlist "have_wage incwage1940_clean topincwg1940 incnonwg1940_clean"  
global coeflist "pf_wm rankgroup1wm nog1 final_tier2" 

file open f using "${tables}/grades1_wm.txt", write replace
file write f "\begin{tabular}{l cccc}"
file write f $tab "Has earnings" $tab "Earnings" $tab "Topcoded" $tab "Non-wage"
file write f "\\ \hline%"

	// panel VII (appendix only: bring in missing grade data)

foreach var in $outlist {
	di "`var'"
		 reg `var' $coeflist i.year,r 	
		 gen esamp_Y_`var'=e(sample)
		eststo `var', noe	
}	
lineout "${coeflist} " "${outlist}" "Including unranked students" "Y"

file write f $llb _n "\end{tabular}"
file close f

////////////////////////////////////
// stats for text about the table //
////////////////////////////////////
// NOTE: will refer to last version of table run, so if looping over multiple rank variables above, make sure rankgroup1 is last

su incwage1940_clean if pf_wm==0
store_stat mean_inc_npf "`r(mean)'" 0
local mean_inc_npf = "`r(mean)'"
display `mean_inc_npf'

su topincwg1940 if pf_wm==0
store_stat mean_tc_npf "`r(mean)'" 2
local mean_tc_npf = "`r(mean)'"

su incnonwg1940_clean if pf_wm==0
store_stat mean_nw_npf "`r(mean)'" 2
local mean_nw_npf = "`r(mean)'"

su incwage1940_clean if final_tier2==0
store_stat mean_inc_nt2 "`r(mean)'" 0
local mean_inc_nt2 = "`r(mean)'"

su topincwg1940 if final_tier2==0
store_stat mean_tc_nt2 "`r(mean)'" 2
local mean_tc_nt2 = "`r(mean)'"

su incnonwg1940_clean if final_tier2==0
store_stat mean_nw_nt2 "`r(mean)'" 2
local mean_nw_nt2 = "`r(mean)'"

foreach panel in A B {
	store_stat reg_`panel'_inc_pf "${`panel'_inc_pf_wm}" 0
	store_stat reg_`panel'_inc_rg "${`panel'_inc_rankgroup1}" 0
	if "`panel'"=="A" {
		local cf pf
		local coef pf_wm
	}
	if "`panel'"=="B" {
		store_stat reg_`panel'_inc_t2 "${`panel'_inc_final_tier2}" 0
		local cf t2
		local coef final_tier2
	}

	store_stat reg_`panel'_tc_`cf' "${`panel'_tc_`coef'}" 1 "per"
	store_stat reg_`panel'_nw_`cf' "${`panel'_nw_`coef'}" 1 "per"

	foreach yvar in inc tc nw {
		local `panel'_`yvar'_`cf'rg_ratio=${`panel'_`yvar'_`coef'}/${`panel'_`yvar'_rankgroup1}
		store_stat reg_`panel'_`yvar'_`cf'rg_ratio "``panel'_`yvar'_`cf'rg_ratio'" 0
		local reg_`panel'_`yvar'_`cf'_prem_perc= ${`panel'_`yvar'_`coef'} / `mean_`yvar'_n`cf''
		store_stat reg_`panel'_`yvar'_`cf'_prem_perc `reg_`panel'_`yvar'_`cf'_prem_perc' 0 "per" // percent more
		store_stat reg_`panel'_`yvar'_`cf'_prem_times `reg_`panel'_`yvar'_`cf'_prem_perc' 1 // times more
		local reg_`panel'_`yvar'_`cf'_perc= (${`panel'_`yvar'_`coef'} + `mean_`yvar'_n`cf'')/ `mean_`yvar'_n`cf''
		store_stat reg_`panel'_`yvar'_`cf'_times `reg_`panel'_`yvar'_`cf'_perc' 1 // times 
	}
}

local regAB_change_pf=(${A_inc_pf_wm}-${B_inc_pf_wm})/${A_inc_pf_wm}
store_stat regAB_perchange_pf `regAB_change_pf' 1 "per"

local regAB_of_pf=(${B_inc_pf_wm})/${A_inc_pf_wm} // coef in panel C falls to XX% of baseline from panel A
store_stat regAB_perof_pf `regAB_of_pf' 0 "per"

// $\input{\numdir/reg_E_tc_t2.txt}\%$ of the brothers sample mean for topcodes

// Brothers who are members of selective final clubs earn XX\% more than brothers who are not, 
//are ZZ\% more likely to report topcoded incomes. The effect of class rank on both outcomes is almost exactly zero. 
// CHANGED TO BE % of sample mean as opposed to % of sample mean of non tier2 brothers
su incwage1940_clean if esamp_D_incwage1940_clean==1 
local perc_prem_inc_t2=${D_inc_final_tier2}/`r(mean)' // percent more earned
store_stat reg_D_inc_t2 `perc_prem_inc_t2' 0 "per"

su topincwg1940 if esamp_D_topincwg1940 ==1 
local perc_prem_tc_t2=${D_tc_final_tier2}/`r(mean)' // additional percent more likely
store_stat reg_D_tc_t2 `perc_prem_tc_t2' 0 "per"
local times_reg_D_tc_t2=(${D_tc_final_tier2}+`r(mean)')/`r(mean)' 
store_stat times_reg_D_tc_t2 `times_reg_D_tc_t2' 1

// number of brothers used in model E
store_stat N_brofam_D "${N_brofam_D}" 0
// number of families used in model E
bys family_id: egen N_bros_cen2030=total(has_census1940_2030)
bys family_id: gen bro_num_2030=_n
su bro_num_2030 if bro_num_2030 ==1 &  !mi(family_id ) & N_bros_cen2030>1
store_stat N_fambro_2030 `r(sum)' 0 

// stats for text about the figure of outcomes by final_tier2 and rankgroup1

// Panel 'F': selective final club, class rankgroup: describes what is presented in Figure 4
global coeflist "final_tier2 rankgroup1" 
foreach var in incwage1940_clean topincwg1940 {
	reg `var' $coeflist i.year if !mi(final_tier2) ,r 	
	eststo `var', noe	
}

foreach coef in $coeflist {
	foreach var in incwage1940_clean topincwg1940 {
			estimates restore `var'
			if "`var'"=="incwage1940_clean" local short_var "inc"  
			if "`var'"=="topincwg1940" local short_var "tc" 
			global F_`short_var'_`coef'=_b[`coef']
	}
}

foreach var in inc tc { 
	if "`var'"=="inc" local long_var "incwage1940_clean"
	if "`var'"=="tc" local long_var "topincwg1940"

	if "`var'"=="inc" store_stat reg_F_`var'_t2 "${F_`var'_final_tier2}" 0
	if "`var'"=="tc" store_stat reg_F_`var'_t2 "${F_`var'_final_tier2}" 2

	local reg_F_`var'_t2_prem_perc= ${F_`var'_final_tier2} / `mean_`var'_nt2'
	store_stat reg_F_`var'_t2_prem_perc `reg_F_`var'_t2_prem_perc' 0 "per"

	su `long_var' if rankgroup1==-6 & final_tier2==1 // members in lowest rg
	local mean_`var'_t2_rg6 = "`r(mean)'"
	su `long_var' if (rankgroup1==-1 | rankgroup1==-2) & final_tier2==0 // non-members in highest rg
	local mean_`var'_nt2_rg12 = "`r(mean)'"

	local mean_`var'_diff=`mean_`var'_t2_rg6'-`mean_`var'_nt2_rg12'
	local mean_`var'_prem_perc=`mean_`var'_diff'/`mean_`var'_nt2_rg12'

	if "`var'"=="inc" store_stat mean_`var'_diff `mean_`var'_diff' 0
	if "`var'"=="tc" store_stat mean_`var'_diff `mean_`var'_diff' 2
	store_stat mean_`var'_prem_perc `mean_`var'_prem_perc' 0 "per"
}

store_stat mean_tc_t2_rg6 `mean_tc_t2_rg6' 0 "per" 
store_stat mean_tc_nt2_rg12 `mean_tc_nt2_rg12' 0 "per" 

su finance if rankgroup1==-6 & final_tier2==1
store_stat mean_fin_t2_rg6 "`r(mean)'" 0 "per" 
su finance if rankgroup1==-6 & final_tier2==0
store_stat mean_fin_nt2_rg6 "`r(mean)'" 0 "per" 

//
//
// Tables 4 and A.4 - components, not full table. Full table can be made in Latex
//
//

use "$cleaned/census_rb_merged", clear

keep if year<=1933 & year>1919 //years for which we have matchs
gen exp=1940-class // this is how many years out from graduation people are in 1940
keep if exp>=6 // 6 years since expected graduation to allow for some convergence
replace rankgroup1=rankgroup1*-1 // reverse sign so better grades are higher numbers
replace rankgroup3=rankgroup3*-1 // reverse sign so better grades are higher numbers
tab year, m // max should be 1930 if exp==6
// replace rankgroup1=rankgroup1/6 // put on 0-1 scale

gen all_hs_wm=schoolcode1
replace all_hs_wm=0 if mi(schoolcode1)
*gen logearn=log(incwage1940_clean)
gen have_wage=!mi(incwage1940_clean )

label var pf_wm "Private feeder"
label var rankgroup1 "Class rank"
label var final_tier2 "Selective final club"  
label var harvard_father "Has Harvard father"

** for Harvard & Beyond comparison:
** construct log wages with top codes imputed for doctors and lawyers and all topcodes scaled up
gen tcinc=incwage1940_clean
replace tcinc=5000 if cen_law==1 | cen_doc==1  
gen tcinc1p4=tcinc
replace tcinc1p4=tcinc1p4*1.4 if tcinc1p4==5000 // multiplying topcodes by 1.4 to follow footnote 5 of Goldin Katz 2008
gen lntcinc=log(tcinc)

** report standard deviation of rankgroup3 
** notes:
*	- we have already dropped non-census cohorts, so those are not included
*	- this sd is across cohorts (not within as we frequently do with test scores etc)
* 	- I am not omitting students missing earnings. GK 2008 do, but only 317 of their 6000+ obs are missing earnings (selection into earnings being reported is very different for them than for us), so standardizing across the whole population seemed better for the comparison
*	- will report this sd in table note so can draw direct comparisons

su rankgroup3
store_stat sd_rg3 `r(sd)' 2

	// Panel II: private school, class rank, social participation
	reg incwage1940_clean pf_wm rankgroup1  final_tier2 i.year ,r 	
	reghdfe  incwage1940_clean pf_wm rankgroup1  final_tier2 ///
	 , absorb( preH_d_emp preH_ownershp_clean preH_f_occ1950 year preH_famsize ///
	  preH_fbpl preH_mbpl preH_farm preH_hhtype ) vce(robust) 	

// Main text table: 
global outlist "have_wage incwage1940_clean topincwg1940 incnonwg1940_clean"  
local rg_var "rankgroup1" 

// output format by depvar: 
local fmt_have_wage "%4.3f"
local fmt_incwage1940_clean "%9.0f"
local fmt_topincwg1940 "%4.3f"
local fmt_incnonwg1940_clean "%4.3f"
	  
// Loop over outcome variables: 
foreach var in $outlist {	  
// six specifications: 

// 1. Add most elite final clubs
global coeflist "pf_wm `rg_var' final_tier2" 
reg `var' $coeflist i.year ,r 
eststo e1
estadd ysumm

// 2. Add Census family background
global coeflist "pf_wm `rg_var' final_tier2" 
reghdfe `var' $coeflist i.year , vce(robust) ///
	absorb(	preH_d_emp preH_ownershp_clean preH_f_occ1950 year preH_famsize ///
	preH_fbpl preH_mbpl preH_farm preH_hhtype)
eststo e2
estadd ysumm

// 3. Add HS FEs+Legacy effects, restrict to private feeders
global coeflist "`rg_var' final_tier2 harvard_father" 
reghdfe  `var' $coeflist i.year if pf_wm==1, vce(robust) absorb(all_hs_wm)
eststo e3
estadd ysumm

// 4.  Within family
global coeflist "`rg_var' final_tier2 " 
reghdfe  `var'  $coeflist i.year if !mi(family_id), cluster(family_id) absorb(family_id)
eststo e4
estadd ysumm

// 5. Within Hasty Pudding (applicant pool)
global coeflist "pf_wm `rg_var' final_tier2" 
reg `var'  $coeflist i.year if hasty==1,r 	
eststo e5
estadd ysumm

// Output: 
esttab e1 e2 e3 e4 e5 using "${tables}/grades1_soc_reg_`var'.txt", replace ///
	keep(pf_wm `rg_var' final_tier2 harvard_father) ///
	order(pf_wm `rg_var' final_tier2 harvard_father) ///
	b(`fmt_`var'') se(`fmt_`var'') paren nostar noconstant ///
	scalars("ymean Sample mean") sfmt(`fmt_`var'') obslast label ///
	nonotes  tex fragment nomtitles nolines nogaps nonumbers
	
}