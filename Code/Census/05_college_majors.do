/*

05_college_majors.do
(called from master_census.do)

Purpose: producessports related output
Inputs: cleaned/census_rb_merged
Outputs: tables/college-majors-desc, tables/major-premium-`depvar',
	tables/major-premium-exp-`depvar', tables/major-premium-wide,
	tables/major-premium-long
	
*/

/*
	Appendix Table B.23: descriptive stats
	columns are samples.
	first column is "all" group that restricts data to years for which major records are available
	second column is "nonmissing major data"
	rest of columns are coarse major groups

	rows are variables, display means
		Panel A: demographics-- high school type, from MA/from NY, harvard father/brother
		Panel B: college outcomes-- academic rank (1st year), N activity, social activity, 
			sports, music, Hasty, selective final club
		Panel C: career intent at grad-- have intent data, finance, business, higher education, medicine, law
		Panel D: later life outcomes: social club, prof assoc, honor society, have occ, 
			finance, medicine, law, higher ed
		Panel E: earnings-- condition on 5+ years out by 1940 (is this possible? what is sample count?)
*/
		
/////////////////////////////////////////
/// Descriptive Table: College Majors ///
/////////////////////////////////////////
use "$cleaned/census_rb_merged" , clear

label var doctor "Medicine"
label var law "Law"
label var finance "Finance"
label var hed "Higher ed."
label var private_feeder "Private feeder"
label var final_tier2 "Selective final club"
label var from_MA "From MA"
label var from_NY "From NY"
label var harvard_brother "Have harvard brother"
label var harvard_father "Have harvard father"
label var hasty "Hasty Pudding Inst. 1770"
label var nac "N activities"
label var have_occ "Have occupation"
label var have_social_club "Have soc. club"
label var sports "Sports"
label var music "Music" 
label var social "Social"
label var final_club "Any final club"
label var have_prof_assoc "Prof. Association"
label var have_hon_club "Honor society"

gen full = class >= 1928 & class <= 1938
label var full "Full sample"

gen major_cohorts=class>=1931 & class<=1938 // cohorts where major is available
label var major_cohorts "Cohorts w/ maj."

gen occ_cohorts=class>=1929 & class<=1938 // cohorts where intent is available
label var occ_cohorts "Cohorts w/ int."

gen exp=1940-class // this is how many years out from graduation people are in 1940
gen exp_sq = exp^2
gen earnings_sample = full == 1 & exp>=6

if $ACCESS == 1 {
	gen have_wage=!mi(incwage1940_clean )
	label var have_wage "Has earnings"
}

replace coarse_major = . if coarse_major == 0 // drop 1 guy with "other major"

replace have_occ_intended=. if year<=1924 // don't include years where we have no intent data when describing reporting rate (state missing years in text instead)

gen econ_major_excl = coarse_major == 4 if !mi(coarse_major)
label var econ_major_excl "`:lab major_lab 4'"
gen stem_major_excl = coarse_major == 3 if !mi(coarse_major)
label var stem_major_excl "`:lab major_lab 3'"
gen humanities_major_excl = coarse_major == 1 if !mi(coarse_major)
label var humanities_major_excl "`:lab major_lab 1'"
gen social_science_major_excl = coarse_major == 2 if !mi(coarse_major)
label var social_science_major_excl "`:lab major_lab 2'"

label var finance_intended "Finance"
label var bus_intended "Business" 
label var hed_ext_intended "Higher education"
label var doctor_intended "Medicine"
label var law_intended "Law"
label var have_occ_intended "Have intent data"

global earnings ""
if $ACCESS == 1 {
	global earnings "have_wage incwage1940_clean incnonwg1940_clean topincwg1940"
}
global samples "major_cohorts have_major occ_cohorts have_occ_intended econ_major_excl stem_major_excl humanities_major_excl social_science_major_excl"
global rowsA "private_feeder public_feeder from_MA from_NY harvard_father harvard_brother"
global rowsB "rankgroup1 nac social sports music hasty final_tier2"
global rowsC "have_occ_intended finance_intended bus_intended hed_ext_intended doctor_intended law_intended"
global rowsD "have_social_club have_prof_assoc have_hon_club have_occ finance doctor law hed"
global rowsE "$earnings"

// Open file
cap file close f 
file open f using "$tables/college-majors-desc.tex", write replace
file write f "\begin{tabular}{l*{8}{c}}"_n
file write f "\toprule"_n

// Column headers
foreach samp in $samples {
    file write f "& `: var la `samp''"
}
file write f "\\" _n
file write f "\midrule"_n

// have major data: 
file write f "Have major"
foreach samp in $samples {
	if inlist("`samp'", "full" ,"occ_cohorts","have_occ_intended") {
		file write f _tab "&" 
	}
	else {
		qui su have_major if `samp' == 1
		file write f _tab "&" %9.3f (`r(mean)')
	}
}
file write f "\\"_n

// Major shares
file write f "Share in major"
foreach samp in $samples {
	if inlist("`samp'", "full" , "have_major", "major_cohorts","occ_cohorts","have_occ_intended") {
		file write f _tab "&" 
	}
	else {
		qui su `samp' if have_major == 1
		file write f _tab "&" %9.3f (`r(mean)')
	}
}
file write f "\\"_n

// Write row panels
write_panel "$rowsA" "$samples" "A. Demographics" "full"
write_panel "$rowsB" "$samples" "B. College outcomes" "full"
write_panel "$rowsC" "$samples" "C. Career intent at grad." "full"
write_panel "$rowsD" "$samples" "D. Adult outcomes" "full"
write_panel "$rowsE" "$samples" "E. Earnings" "earnings_samp" // specify later

// Sample sizes
file write f "\\"_n
file write f "N (full sample)"
foreach samp in $samples {

		count if `samp'==1
		file write f _tab "&" %9.0f (`r(N)')
	
}
file write f "\\"_n

// Close file
file write f "\bottomrule"_n
file write f "\end{tabular}"_n
file close f

// save numbers for text    
// shares non-missing
su have_major if major_cohorts== 1
store_stat perc_have_major "`r(mean)'" 0 per 
su have_occ_intended if occ_cohorts== 1
store_stat perc_have_intocc "`r(mean)'" 0 per 
// private feeder by major econ_major_excl stem_major_excl humanities_major_excl social_science_major_excl
su private_feeder if humanities_major_excl== 1
store_stat perc_pf_human "`r(mean)'" 1 per 
su private_feeder if stem_major_excl== 1
store_stat perc_pf_stem "`r(mean)'" 1 per 
// career intent by major finance_intended bus_intended hed_ext_intended doctor_intended law_intended
su finance_intended if econ_major_excl== 1
store_stat perc_fin_intend_econ "`r(mean)'" 1 per 
su bus_intended if econ_major_excl== 1
store_stat perc_bus_intend_econ "`r(mean)'" 1 per 
su doctor_intended if econ_major_excl== 1
store_stat perc_doc_intend_econ "`r(mean)'" 1 per 
su finance_intended if stem_major_excl== 1
store_stat perc_fin_intend_stem "`r(mean)'" 1 per 
su doctor_intended if stem_major_excl== 1
store_stat perc_doc_intend_stem "`r(mean)'" 1 per 
// career realisation by major 
su finance if econ_major_excl== 1
store_stat perc_fin_econ "`r(mean)'" 1 per 
su doctor if econ_major_excl== 1
store_stat perc_doc_econ "`r(mean)'" 1 per 
su finance if stem_major_excl== 1
store_stat perc_fin_stem "`r(mean)'" 1 per 
su doctor if stem_major_excl== 1
store_stat perc_doc_stem "`r(mean)'" 1 per 

if $ACCESS == 1 {
	 // Table B.24

	/*
		run regression where left hand side is earnings. condition on 5+ years out by 1940 (or maybe 4 depending on sample)
		Right hand varies by column
		column 1: cohort effects, coarse major effects with humanities as omitted category, HS type
		column 2: add linear rank group effect
		column 3: add selective final club effect
		column 4: interact final club with major, rank group, HS type.

		in reporting, supress cohort effects.

		do same thing with "finance" as outcome. use all available data with class report occupation. this should be columns 5-8.
	*/

	gen hs = have_hs_rec
	replace hs = 0 if have_hs_rec == 1
	replace hs = 1 if public_feeder == 1
	replace hs = 2 if private == 1 & private_feeder == 0 
	replace hs = 3 if private_feeder==1
	label define hs_lab 0 "Other HS" 1 "Public Feeder" 2 "Priv. Other" 3 "Priv. Feeder"
	label values hs hs_lab

	label var final_tier2 "Sel. fin. club"
	* Reverse rankgroup
	replace rankgroup1 = (-1) * rankgroup1
	global outcomes "incwage1940_clean topincwg1940 finance"
	global controls1 "ib3.coarse_major private_feeder"
	global controls2 "$controls1 rankgroup1"
	global controls3 "$controls2 final_tier2"
	global controls4 "$controls3 private_feeder_econ_major"

	gen private_feeder_econ_major = private_feeder * econ_major ///
		if !mi(coarse_major) & !mi(private_feeder)
	label var private_feeder_econ_major "Private Feeder=1 $\times$ Economics=1"

	// Run regressions
	foreach depvar in $outcomes {
		forv k = 1/4{
			 if "`depvar'" == "finance" ///
				qui reg `depvar' ${controls`k'} i.year if full == 1, r
			 if "`depvar'" != "finance" ///
				qui reg `depvar' ${controls`k'} i.year if earnings_sample == 1, r	
			est sto e_`depvar'_fe_`k'
					
			// Quadratic experience
			if "`depvar'" == "finance" ///
				qui reg `depvar' ${controls`k'} exp exp_sq if full == 1, r
			 if "`depvar'" != "finance" ///
				qui reg `depvar' ${controls`k'} exp exp_sq  if earnings_sample == 1, r	
			est sto e_`depvar'_exp_`k'
		}
		if "`depvar'" == "incwage1940_clean" {
			local format %9.1f
		}
		else {
			local format %9.3f
		}
		* Export table (one per outcome)
		esttab e_`depvar'_fe_* ///
		using "$tables/major-premium-`depvar'.tex", ///
		booktabs nostar nomtitles noomitted nobase obslast b(`format') se(`format') ///
		label drop(*.year _cons) replace ///
		// addnotes("All columns control for cohort fixed effects and require at least 6 years of experience in 1940." ///	 "Academic rank is reversed, i.e. high academic achievement corresponds to a high rank." 	 "STEM/Engineering is the ommitted college major.")

		// Alternative version with quadratic experience instead of cohort FE 
		esttab e_`depvar'_exp_* ///
		using "$tables/major-premium-exp-`depvar'.tex", ///
		booktabs nostar nomtitles noomitted nobase obslast b(`format') se(`format') ///
		label drop(exp* _cons) replace ///
		// addnotes("All columns control for quadratic experience and require at least 6 years of experience in 1940." /// "Academic rank is reversed, i.e. high academic achievement corresponds to a high rank." /// "STEM is the ommitted college major.")
		 
	 }

	 /// Make wide table with outcomes wage, topcoded and finance
	esttab e_inc*_fe_* e_topinc*_fe_* e_finance_fe_* ///
	using "$tables/major-premium-wide.tex", ///
	booktabs nostar nomtitles noomitted nobase obslast b(%9.1f) se(%9.1f) ///
	mgroups("Wage" "Topcoded" "Finance", pattern(1 0 0 0 1 0 0 0 1 0 0 0)) ///
	label drop(*.year _cons) replace ///
	addnotes("All columns control for cohort fixed effects and require at least 6 years of experience in 1940." ///
	 "Academic rank is reversed, i.e. high academic achievement corresponds to a high rank." ///
	 "STEM/Engineering is the ommitted college major.")

	 // Make long table with outcomes wage, topcoded  and finance
	label var incwage1940_clean "\emph{A. Wage income}"
	label var topincwg1940 "\emph{B. Topcoded income}"
	label var finance "\emph{C. Finance}"
	 
	global regressors "1.coarse_major 2.coarse_major 4.coarse_major private_feeder rankgroup1 final_tier2 private_feeder_econ_major"

	cap file close f 
	file open f using "$tables/major-premium-long.tex", write replace

	file write f "\begin{tabular}{l*{8}{c}}"_n
	file write f "\toprule"_n

	forv k = 1/4 {
		file write f "& \multicolumn{2}{c}{(`k')}"
	}
	 
	file write f "\\"_n
	forv k = 1/4 {
		local ll = 2 * `k'
		local ul = 2 * `k' +1
		file write f "\cmidrule(lr){`ll'-`ul'}"
	}
	file write f ""_n

	forv k = 1/4 {
		file write f "& $\beta$ & SE"
	}
	file write f "\\"_n
	file write f "\midrule"_n

	foreach depvar in $outcomes {
		file write f "`: var la `depvar'' \\"_n
		if "`depvar'" == "incwage1940_clean" {
			local format %5.1f
		}
		else {
			local format %5.3f
		}

		foreach regressor in $regressors {
			if regexm("`regressor'","^([0-9]).") == 0 {
			file write f "`: var la `regressor'' "
			}
			else {
				local major_cat = substr("`regressor'",1,1)
				file write f "`:label major_lab `major_cat'' "
			}
			forv k = 1/4 {
				est rest e_`depvar'_fe_`k'
				cap file write f  "&" `format' (_b[`regressor'])  "& (" `format' (_se[`regressor']) ")"
				if _rc != 0 {
					file write f  "&" 
				}
			} // k
			file write f "\\"_n
			file write f "\addlinespace"_n
		} // regressor
		* Observations
		file write f "\midrule"_n
		file write f "Observations"
		forv k = 1/4 {
			est rest e_`depvar'_fe_`k'
			file write f "&"  %9.0f (e(N))  "&"
		}
		file write f  "\\"_n
		file write f "\midrule"_n

		file write f "\addlinespace"_n
	} //depvar

	file write f "\end{tabular}"
	cap file close f
	 
}