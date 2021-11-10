/*

06_college_sports.do
(called from master_census.do)

Purpose: producessports related output
Inputs: cleaned/census_rb_merged
Outputs: tables/sports-desc, tables/athlete-premium
	
*/

/*
	Sports
	table B.31: descriptive stats
	columns are samples: all students, private feeder, public feeder, other
	rows are sports categories
	-any sport
	-any schoolwide sport (not dorm or intramural sport, let me know if this distinction is unclear)
	-take five most common schoolwide sports and show participation for each of those groups and then do an "other sports" category
	-if five is not the right number of sports to look at, propose some other number
*/

use "$cleaned/census_rb_merged", clear

label var football "Football"
label var baseball "Baseball"
label var track "Track"
label var rowing "Crew/rowing"
label var basketball "Basketball"
label var other_sport "Other sport"
label var private_feeder "Private feeder"
label var public_feeder "Public feeder"
label var finance "Finance"
label var social "Social"

gen hs = have_hs_rec
replace hs = 0 if have_hs_rec == 1
replace hs = 1 if public_feeder == 1
replace hs = 2 if private == 1 & private_feeder == 0 
replace hs = 3 if private_feeder==1
label define hs_lab 0 "Other HS" 1 "Public Feeder" 2 "Priv. Other" 3 "Priv. Feeder"
label values hs hs_lab

gen other_hs = hs == 0 | hs == 2 if have_hs_rec==1
label var other_hs "Other HS"
label var all "All"
label var sports "Any Sport"
label var university_sport "Schoolwide"
label var intramural_sport "Intramural/Dormitory"
label var basketball "Basketball"
label var hasty "Hasty Pudding"

global samples "all private_feeder public_feeder other_hs"
global rowsA "sports university_sport intramural_sport"
global rowsB "rowing track football baseball basketball other_sport"

// Open file 
cap file close f 
file open f using "$tables/sports-desc.tex", write replace

file write f "\begin{tabular}{l*{4}{c}}"_n
file write f "\toprule"_n

foreach samp in $samples {
	file write f "& `:var la `samp''"
}

file write f "\\"_n
file write f "\midrule"_n

write_panel "$rowsA" "$samples" "A. Sport by competition level" "all"
write_panel "$rowsB" "$samples" "B. Sport by type" "all"

file write f "\bottomrule"_n
file write f "\end{tabular}"_n
file close f 

// save numbers for text   appendix b sports participation
su university_sport if all==1
store_stat perc_unisport "`r(mean)'" 0 per 

/*
	Table B.32: Athlete premiums regressions
	column 1: outcome=class rank (reverse signed). controls=cohort effects, any sport, schoolwide sport, high school type.
	column 2: same, but outcome is final club participation
	column 3: same but outcome is earnings
	column 4: same but outcome is finance
	column 5: outcome is earnings. controls=cohort effects, any sport, schoolwide sport, HS type, grade fixed effects, final club fixed effect
	column 6: same as 5, but now split schoolwide sport into specific sport categories from descriptive table.
	sample= OLS earnings regression sample 

*/

gen exp = 1940 - class // experience at time of 1940 census

// Define earnings sample as in main OLS specs: at least 6 years experience in 1940, and years for which earnings are matched
gen earnings_samp = exp >= 6 & year<=1933 & year>1919

gen rankgroup1_rev = (-1) * rankgroup1
label var rankgroup1_rev "Class rank"
label var final_tier2 "Sel. fin. club"
label var university_sport "Schoolwide Sport"
// Define sets of controls
global baseline_cntrls "university_sport private_feeder i.year"
global advanced_cntrls "university_sport private_feeder final_tier2 i.year"
global adv_hasty_cntrls "university_sport private_feeder final_tier2 hasty social i.year"
global ind_sport_cntrls "rowing track football baseball basketball other_sport private_feeder final_tier2 i.year"
global ind_sport_hasty_cntrls "rowing track football baseball basketball other_sport private_feeder final_tier2 hasty social i.year"

// Model 1: Grades on cohort, schoolwide, HS
reg rankgroup1_rev $baseline_cntrls if earnings_samp == 1, r
est sto e_athlete_1

// Model 2: Selective Final club on cohort, schoolwide, HS
reg final_tier2 $baseline_cntrls if earnings_samp == 1, r
est sto e_athlete_2

if $ACCESS == 1 {
	// Model 3: Earnings on cohort, schoolwide, HS
	reg incwage1940_clean $baseline_cntrls if earnings_samp == 1, r
	est sto e_athlete_3
}

// Model 4: Finance on cohort, schoolwide, HS
reg finance $baseline_cntrls if earnings_samp == 1, r
est sto e_athlete_4

if $ACCESS == 1 {
	label var incwage1940_clean "Wage inc."
	// Model 5: Earnings on cohort, schoolwide sport, HS, selective final club
	reg incwage1940_clean $advanced_cntrls if earnings_samp == 1, r
	est sto e_athlete_5
}

// Model 6: Finance on cohort, schoolwide sport, HS, selective final club
reg finance $advanced_cntrls if earnings_samp == 1, r
est sto e_athlete_6

if $ACCESS == 1 {
	// Model 5b: Earnings on cohort, schoolwide sport, HS, selective final club + HASTY
	reg incwage1940_clean $adv_hasty_cntrls if earnings_samp == 1, r
	est sto e_athlete_5b
}

// Model 6b: Finance on cohort, schoolwide sport, HS, selective final club + HASTY
reg finance $adv_hasty_cntrls if earnings_samp == 1, r
est sto e_athlete_6b

if $ACCESS == 1 {
	// Model 7: Earnings on cohort, HS, selective fin. club, individual sports
	reg incwage1940_clean $ind_sport_cntrls if earnings_samp == 1, r
	est sto e_athlete_7
}

// Model 8: Finance on cohort, HS, selective fin. club, individual sports
reg finance $ind_sport_cntrls if earnings_samp == 1 , r
est sto e_athlete_8

if $ACCESS == 1 {
	// Model 7b: Earnings on cohort, HS, selective fin. club, individual sports + HASTY
	reg incwage1940_clean $ind_sport_hasty_cntrls if earnings_samp == 1, r
	est sto e_athlete_7b
}

// Model 8b: Finance on cohort, HS, selective fin. club, individual sports + HASTY
reg finance $ind_sport_hasty_cntrls if earnings_samp == 1 , r
est sto e_athlete_8b

if $ACCESS == 0 {
	
	// Export results to table with Hasty controls
	esttab e_athlete_1 e_athlete_2 e_athlete_4 e_athlete_6b e_athlete_8b ///
		using "$tables/athlete-premium.tex", ///
		booktabs nostar obslast b(a2) se(a2) ///
	label drop(*.year _cons) replace nonotes
	
}
	 
if $ACCESS == 1 {
	// Export results to table with Hasty controls
	esttab e_athlete_1 e_athlete_2 e_athlete_3 e_athlete_4 e_athlete_*b ///
		using "$tables/athlete-premium.tex", ///
		booktabs nostar obslast b(a2) se(a2) ///
	label drop(*.year _cons) replace nonotes

	// save numbers for text appendix b sports participation
	su incwage1940_clean if earnings_samp==1 & university_sport==1
	local mean_inc_us `r(mean)'
	su incwage1940_clean if earnings_samp==1 & university_sport==0
	local mean_inc_nus `r(mean)'


	foreach var in inc {
	local diffper_`var'= (`mean_`var'_us' - `mean_`var'_nus')/ `mean_`var'_nus'
	store_stat diffper_`var'_us "`diffper_`var''" 0 "per"
	}
}

su finance if university_sport==1
local mean_finance_us `r(mean)'
store_stat perc_finance_us "`mean_finance_us'" 0 "per"
su finance if university_sport==0
local mean_finance_nus `r(mean)'
store_stat perc_finance_nus "`mean_finance_nus'" 0 "per"

su manage_high if university_sport==1
local mean_hmanage_us `r(mean)'
store_stat perc_hmanage_us "`mean_hmanage_us'" 0 "per"
su manage_high if university_sport==0
local mean_hmanage_nus `r(mean)'
store_stat perc_hmanage_nus "`mean_hmanage_nus'" 0 "per"

if $ACCESS == 1 {
	// statistics: 
	tab university_sport if earnings_samp==1, su(incwage1940_clean)
	tab university_sport, su(finance)
	tab university_sport, su(manage_high)
}

// approximate 0-100 class rank: 
drop if mi(rankgroup1)
bys year (rankgroup1): gen overallrank=_n
egen grank=median(overallrank), by(rankgroup1 year)
bys year: gen rank100=100*grank/_N

table year rankgroup1, c(mean rank100)
tab university_sport, su(rank100)

// save diff in ranks for text
su rank100  if university_sport==1
local mean_pctl_us `r(mean)'
su rank100   if university_sport==0
local mean_pctl_nus `r(mean)'

local diff_pctl_us= `mean_pctl_us' - `mean_pctl_nus'
store_stat diff_pctl_us "`diff_pctl_us'" 0 