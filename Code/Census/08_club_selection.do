/*

08_club_selection.do
(called from master_census.do)

Purpose: producescollege clubs related output
Inputs: cleaned/census_rb_merged,
Outputs: tables/club-selection-desc, tables/club-selection-regs
	
*/

/*
Selection into final clubs

Descriptive table: 
	- columns are samples: all students, hasty pudding members, any final club, selective final club
	- rows are variables, displaying means:
		-private feeder HS
		-private non-feeder HS
		-public feeder HS
		-harvard father
		-harvard brother
		-from MA
		-from NY
		-EE immigrant
		-SE immigrant

		grade categories: high (rank 1-3), middle (rank 4-5), low (6)
		-social club
		-first-year leadership
		-sports categories from above
		-music

		hasty pudding
		-any final club
		-selective final club
*/

/// Descriptive Table on Selection into clubs

use "$cleaned/census_rb_merged", clear
label var final_tier2 "Sel. final club"
label var hasty "Hasty"
label var private_feeder "Private feeder"

gen private_other = private == 1 & private_feeder==0 if !mi(have_hs_rec)
label var private_other "Private other"

gen social_leader = social == 1 if !mi(social)
replace social_leader = 1 if aclead == 1
label var social_leader "Social Leader"

gen legacy = harvard_father == 1 | harvard_brother == 1 ///
	if !mi(harvard_brother) | !mi(harvard_father)
label var legacy "Harvard legacy"

gen acad_high = rankgroup1 <= 3 if !mi(rankgroup1)
gen acad_med = rankgroup1 <=5 & acad_high == 0 if !mi(rankgroup1)
gen acad_low = rankgroup1 == 6 if !mi(rankgroup1)

label var acad_high "High acad. rank"
label var acad_med "Medium acad. rank"
label var acad_low "Low	 acad. rank"

global samples "all hasty final_tier2"
global rowsA "private_feeder public_feeder legacy"
global rowsB "acad_high acad_med acad_low nac social_leader university_sport"
global rowsC "hasty final_tier2" 

if $ACCESS == 1 {
	gen jewish_name=jewish_index>=0.7 if !mi(jewish_index)
	gen cath_name=cath_index>=0.7 if !mi(cath_index)
	gen oc_name=oldMA_lnindex>=0.7 if !mi(oldMA_lnindex)
	label var comb_gen12_immg_ee "E. Eur. Immg. gen. 1-2"

	label var jewish_index "Jewish name index"
	label var cath_index "Catholic name index"
	label var oldMA_lnindex "Colonial name index"

	label var jewish_name "Jewish name"
	label var cath_name "Catholic name"
	label var oc_name "Colonial name"

	global rowsA "private_feeder public_feeder legacy jewish_name cath_name oc_name"
}

// NOT USED IN PAPER

// Open file
cap file close f 
file open f using "$tables/club-selection-desc.tex", write replace

// Header
file write f "\begin{tabular}{l*{3}{c}}"_n
file write f "\toprule"_n
foreach col in $samples {
    file write f "& `:var la `col''"
}
file write f "\\"_n
file write f "\midrule"_n

file write f "\emph{I. Sample descriptives}\\ \addlinespace"_n
// Write panels
write_panel "$rowsA" "$samples" "A. Demographics" "all" "noobs"
write_panel "$rowsB" "$samples" "B. Academic \& social activities" "all" "noobs"
write_panel "$rowsC" "$samples" "C. Upper year clubs" "all" "noobs"

// Sample size
file write f "\midrule"_n
file write f "\emph{N}"
foreach col in $columns {
    qui count if `col' == 1 
    file write f "& " %4.0fc (`r(N)')
}
file write f "\\"_n 

// Close file 
file write f "\bottomrule \addlinespace"_n
*file write f "\end{tabular}"_n
file close f

// Table B.11

/*
Model: estimate probit specifications with following covariates
	column 1: outcome is hasty pudding. covariates: private feeder hs, private non-feeder, harvard legacy (father or brother), immigrant dummies, grade categories, social club, cohort effects.
	column 2: outcome is selective final club, same covariates as above
	column 3: outcome is selective final club, same covariates, but *condition* on hasty pudding
	column 4: same as 2, but add interactions btw HS type variables and grade categories
	column 5: same as 3, but add interactions btw HS type variables and grade categories
report average marginal effect and the SE of that (not coef)
*/

gen acad_groups = 1 if acad_low == 1
replace acad_groups = 2 if acad_med == 1
replace acad_groups = 3 if acad_high == 1
replace acad_groups = 4 if rg_notlisted1 == 1
label define acad_lab 1 "Low acad. rank" 2 "Middle acad. rank" 3 "High acad. rank" 4 "Not ranked"
label values acad_groups acad_lab
label var acad_groups "Academic rank"
label var final_tier2 "Sel. fin. club"
// global baseline_cov "private_feeder ib2.acad_groups legacy comb_gen12_immg_se social" 
// global hs_interact_cov "private_feeder ib2.acad_groups 1.private_feeder##ib2.acad_groups legacy comb_gen12_immg_se social"

global controls = "private_feeder legacy jewish_name cath_name oc_name " + ///
	"ib2.acad_groups social_leader 1.private_feeder##ib2.acad_groups 1.private_feeder##ib0.social_leader"
	
if $ACCESS == 0 {
	
	global controls = "private_feeder legacy " + ///
		"ib2.acad_groups social_leader 1.private_feeder##ib2.acad_groups 1.private_feeder##ib0.social_leader"
	
}

// LPM 1: Outcome Hasty Pudding, baseline covariates
// probit hasty $baseline_cov i.year, r
// margins ,dydx(${baseline_cov}) post
reg hasty $controls i.year, r

est sto e_lpm_1

if $ACCESS == 1 {
	foreach var in private_feeder legacy jewish_name cath_name oc_name 1.acad_groups 3.acad_groups social_leader {
		store_stat hp_lpm_`var' "_b[`var']" 1 per 
	}
}

if $ACCESS == 0 {
	foreach var in private_feeder legacy 1.acad_groups 3.acad_groups social_leader {
		store_stat hp_lpm_`var' "_b[`var']" 1 per 
	}
}

// LPM 2: Outcome Sel. final club, baseline covariates
reg final_tier2 $controls i.year, r

est sto e_lpm_2

// LPM 3: Outcome Sel. final club, baseline covariates, hasty only sample
reg final_tier2 $controls i.year if hasty==1 , r

est sto e_lpm_3

/// Make table 
cap file close f 
file open f using "$tables/club-selection-regs.tex", write replace
file write f "\begin{tabular}{l*{3}{c}}"_n
file write f "\toprule"_n
file close f 

esttab e_lpm_* using "$tables/club-selection-regs.tex", ///
	booktabs nostar nobase noomitted obslast b(%9.3f) se(%9.3f) drop(*year _cons) ///
	nogap nonumber label mtitles("Hasty" "Sel. fin. club" "Sel. fin. club $|$ Hasty") ///
	append fragment
	

cap file close f
file open f using "$tables/club-selection-regs.tex", write append
file write f "\bottomrule"_n
file write f "\end{tabular}"_n
file close f 

if $ACCESS == 1 {
	
////// statistics for text on "crack in glass ceiling"

count if final_tier2==1 & pf_wm==0
gen priv_other_wm= private_other==1
tab priv_other_wm if final_tier2==1 & pf_wm==0, sort

tab schoolname1 if final_tier2==1 & pf_wm==0, sort

// these both seem like "false positives" in terms of actual judaism
li name have_hs_rec schoolname1 priv_other_wm pf_wm class harvard_father harvard_brother ///
if jewish_name==1 & final_tier2==1 

br name have_hs_rec schoolname1 priv_other_wm pf_wm class harvard_father harvard_brother ///
if cath_name==1 & final_tier2==1 

count if final_tier2==1 & public_feeder==1
br name class schoolname1 schoolcode1 schoolname2 harvard_father ///
social sports hasty aclead oc_name jewish_name if final_tier2==1 & public_feeder==1 

}