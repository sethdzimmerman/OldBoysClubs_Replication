/*

11_cross_section_trends.do
(called from master_census.do)

Purpose: producescross-sectional trends output
Inputs: 11a_program_define.do, cleaned/lr_series_redbooks_update (cleaned/lr_series_redbooks_clean),
	intstata/IPEDS_HEGIS_harvard_enrollment
Outputs: figures/honors_schooltype, figures/honors_schooltype_slides, figures/honors_race_cat,
	figures/finance_byrace, figures/honors_ad_club, figures/finance_ad_club,
	figures/main-text-magna-summa, figures/main-text-finance, figures/honors_ad_club,
	figures/finance_ad_club, figures/main-text-magna-summa-male,
	figures/main-text-finance-male, figures/hs_dems_lr_1, figures/hs_dems_lr_2,
	figures/hs_dems_lr_3, tables/longrun-demos-desc, tables/longrun-cross-section-desc`i',
	figures/women_benchmark, figures/race_benchmark, figures/count_benchmark,
	tables/name-index-availability, figures/ad-club
	
*/

// define catout_graph and catshare_graph programs for making graphs below:
do 11a_program_define.do

// open up long-run data series: 

if $ACCESS == 1 {
	use "$cleaned/lr_series_redbooks_update", clear
	label var private_feeder "Private feeder"
	label var public_feeder "Public feeder"
}

if $ACCESS == 0 {
	use "$cleaned/lr_series_redbooks_clean", clear
	label var private_feeder "Private feeder"
	label var public_feeder "Public feeder"	
}

// generate codes and labels for graphs: 
label define male 0 "Female" 1 "Male"
label values male male 

// school type variables: 
gen schooltype=4  if have_hs_rec==1 
replace schooltype=1 if public_feeder==1 & have_hs_rec==1
replace schooltype=2 if private_feeder==1 & have_hs_rec==1
replace schooltype=3 if private_other==1 & have_hs_rec==1

label define schooltype  1 "Public feeder"  2 "Private feeder" 3 "Other private" 4 "Other HS"
label values schooltype schooltype

// stand-alone public feeder variable with non-missing values
replace public_feeder=0 if mi(public_feeder) & have_hs_rec==1

// race categorizations

if $ACCESS == 1 {
	gen race_cat=. 
	replace race_cat=1 if  have_race==1 & jewish_lnindex>0.7 &  !mi(jewish_lnindex) // jewish
	replace race_cat=2 if have_race==1 & (jewish_lnindex<=0.7 | mi(jewish_lnindex) )& ///
		oldMA_lnindex>0.7 & !mi(oldMA_lnindex) // colonial	
	replace race_cat=3 if non_white==0 & have_race==1 & ( jewish_lnindex<=0.7 | mi(jewish_lnindex) )  ///
		& (oldMA_lnindex<=0.7 | mi(oldMA_lnindex)) // other white; includes missing index values of name indices
	replace race_cat=4 if (hispanic==1 | black==1 ) & have_race==1 // urm
	replace race_cat=5 if asian==1 & have_race==1 // asian

	count if have_race==1 & mi(race_cat) // <1% of records; these are other non-white and missing hand-codes


	label define racecat 1 "Jewish" 2 "Colonial" 3 "Oth. wht" 4 "URM" 5 "Asian"
	label values race_cat racecat
}

// AD club categorizations: 
label define ad_club 1 "A.D. club"  0 "Not A.D. club" // 99 "Other final club"
label values ad_club ad_club

//
//
// Figure 7: Grades and career outcomes over time
//
//

//
// by HS type:
//

preserve
        replace schooltype = . if schooltype==4 | schooltype==3
	expand 2, gen(copy)
	replace schooltype = 99 if copy == 1
	label define schooltype 99 "All", add
	label values schooltype schooltype

// grades:
	catout_graph magna_summa "" schooltype "A. High honors by HS type"
	graph display g_magna_summa_schooltype_out, xsize(20) ysize(14)
	graph export "$figures/honors_schooltype.png", as(png) width(3200) replace
	
// finance
	catout_graph finance "" schooltype "D. Finance by HS type"
	graph display g_finance_schooltype_out, xsize(20) ysize(14)	
	
// for slides: 

	gen sts=schooltype
	label values sts schooltype
	catout_graph magna_summa "" sts ""
	graph display g_magna_summa_sts_out, xsize(17) ysize(14)
	graph export "$figures/honors_schooltype_slides.png", as(png) width(3200) replace
	
restore

//
// By race
//

if $ACCESS == 1 {
// magna/summa: 
catout_graph magna_summa "& ((race_cat==1 | race_cat==2 | race_cat==3) | class>=1975)" ///
	race_cat "B. High honors by race/ethnicity"
	graph display g_magna_summa_race_cat_out, xsize(20) ysize(14)
	
	graph export "$figures/honors_race_cat.png", as(png) width(3200) replace
	
// finance: 
catout_graph finance "& ((race_cat==1 | race_cat==2 | race_cat==3) | class>=1975)"  race_cat "E. Finance by race/ethnicity"
graph display g_finance_race_cat_out, xsize(20) ysize(14)

graph export "$figures/finance_byrace.png", as(png) width(3200) replace
}	

//
// by AD membership: 
//

// magna/summa:
catout_graph magna_summa "" ad_club "C. High honors by A.D. membership"
graph display g_magna_summa_ad_club_out, xsize(20) ysize(14)

graph export "$figures/honors_ad_club.png", as(png) width(3200) replace	
	
	
// finance: 	
catout_graph finance "" ad_club "F. Finance by A.D. membership"
graph display g_finance_ad_club_out, xsize(20) ysize(14)
graph export "$figures/finance_ad_club.png", as(png) width(3200) replace
	
if $ACCESS == 1 {
	// combine graphs-- magna summa: 
	gr combine g_magna_summa_schooltype_out g_magna_summa_race_cat_out g_magna_summa_ad_club_out ///
		, scheme(s1color)  ycommon xsize(20) ysize(6.5) rows(1)
	graph export "$figures/main-text-magna-summa.png", as(png) width(3200) replace
		
		
	// combine graphs-- finance: 
	gr combine g_finance_schooltype_out g_finance_race_cat_out g_finance_ad_club_out ///
		, scheme(s1color)  ycommon xsize(20) ysize(6.5) rows(1)	
	graph export "$figures/main-text-finance.png", as(png) width(3200) replace
}
	
		
if $ACCESS == 0 {
	// combine graphs-- magna summa: 
	gr combine g_magna_summa_schooltype_out g_magna_summa_ad_club_out ///
		, scheme(s1color)  ycommon xsize(20) ysize(6.5) rows(1)
	graph export "$figures/main-text-magna-summa.png", as(png) width(3200) replace
		
		
	// combine graphs-- finance: 
	gr combine g_finance_schooltype_out g_finance_ad_club_out ///
		, scheme(s1color)  ycommon xsize(20) ysize(6.5) rows(1)	
	graph export "$figures/main-text-finance.png", as(png) width(3200) replace
}
	
//
//
// Figure B.21: grades and career outcomes over time, men only
//
//

//
// by HS type:
//

preserve
        replace schooltype = . if schooltype==4 | schooltype==3
	expand 2, gen(copy)
	replace schooltype = 99 if copy == 1
	label define schooltype 99 "All", add
	label values schooltype schooltype

// grades:
	catout_graph magna_summa "& male==1" schooltype "A. High honors by HS type"
	graph display g_magna_summa_schooltype_out, xsize(20) ysize(14)
	
// finance
	catout_graph finance "& male==1" schooltype "D. Finance by HS type"
	graph display g_finance_schooltype_out, xsize(20) ysize(14)	
	
restore

//
// By race
//

if $ACCESS == 1 {
// magna/summa: 
	catout_graph magna_summa "& ((race_cat==1 | race_cat==2 | race_cat==3) | class>=1975) & male==1" ///
		race_cat "B. High honors by race/ethnicity"
		graph display g_magna_summa_race_cat_out, xsize(20) ysize(14)
		
		
	// finance: 
	catout_graph finance "& ((race_cat==1 | race_cat==2 | race_cat==3) | class>=1975) & male==1"  race_cat "E. Finance by race/ethnicity"
	graph display g_finance_race_cat_out, xsize(20) ysize(14)
}

//
// by AD membership: 
//

// magna/summa:
catout_graph magna_summa "& male==1" ad_club "C. High honors by A.D. membership"
graph display g_magna_summa_ad_club_out, xsize(20) ysize(14)

graph export "$figures/honors_ad_club.png", as(png) width(3200) replace	
	
	
// finance: 	
catout_graph finance "& male==1" ad_club "F. Finance by A.D. membership"
graph display g_finance_ad_club_out, xsize(20) ysize(14)
graph export "$figures/finance_ad_club.png", as(png) width(3200) replace
	
if $ACCESS == 1 {
	// combine graphs-- magna summa: 
	gr combine g_magna_summa_schooltype_out g_magna_summa_race_cat_out g_magna_summa_ad_club_out ///
		, scheme(s1color)  ycommon xsize(20) ysize(6.5) rows(1)
	graph export "$figures/main-text-magna-summa-male.png", as(png) width(3200) replace
		
		
	// combine graphs-- finance: 
	gr combine g_finance_schooltype_out g_finance_race_cat_out g_finance_ad_club_out ///
		, scheme(s1color)  ycommon xsize(20) ysize(6.5) rows(1)	
	graph export "$figures/main-text-finance-male.png", as(png) width(3200) replace
}

if $ACCESS == 0 {
	// combine graphs-- magna summa: 
	gr combine g_magna_summa_schooltype_out g_magna_summa_ad_club_out ///
		, scheme(s1color)  ycommon xsize(20) ysize(6.5) rows(1)
	graph export "$figures/main-text-magna-summa-male.png", as(png) width(3200) replace
		
		
	// combine graphs-- finance: 
	gr combine g_finance_schooltype_out g_finance_ad_club_out ///
		, scheme(s1color)  ycommon xsize(20) ysize(6.5) rows(1)	
	graph export "$figures/main-text-finance-male.png", as(png) width(3200) replace
}
	
if $ACCESS == 1 {
//
//
// demographic shares by HS type (not in paper;  used for slides): 
//
//

// shares by HS type -- selected figures-- for presentations
preserve
drop asian 
gen urm = race_cat==4 if !mi(race_cat)
gen asian=race_cat==5 if !mi(race_cat)
gen jewish=race_cat==1 if !mi(race_cat)
gen colonial=race_cat==2 if !mi(race_cat)

gen yearbin=floor(year/2)*2
collapse (mean) urm asian jewish colonial if have_race==1 & have_hs_rec==1, by(private_feeder yearbin)

twoway (connect colonial year if private_feeder==1, msymbol(Oh) lpattern(solid) mcolor(green) lcolor(green))  ///
	(connect colonial year if private_feeder==0, msymbol(O) lpattern(dash) mcolor(green) lcolor(green)) ///
	(connect jewish year if private_feeder==1, msymbol(Th) lpattern(solid) mcolor(red) lcolor(red)) ///
	(connect jewish year if private_feeder==0, msymbol(T) lpattern(dash) mcolor(red) lcolor(red)) ////
	, scheme(s1color) legend(rows(2) order(1 "Colonial-- Priv. feeder" 2 "Colonial--other" ///
	3 "Jewish-- Priv. feeder " 4 "Jewish-- other")) ///
	xlabel(1920(20)2000) xtitle("Entering year") ytitle(Share) xsize(20) ysize(14) name(rs1, replace)
graph export "$figures//hs_dems_lr_1.png", as(png) width(3200) replace
	
twoway (connect urm year if private_feeder==1, msymbol(Sh) lpattern(solid) mcolor(blue) lcolor(blue))  ///
	(connect urm year if private_feeder==0, msymbol(S) lpattern(dash) mcolor(blue) lcolor(blue))  ///
	(connect asian year if private_feeder==1, msymbol(Dh) lpattern(solid) mcolor(orange) lcolor(orange))  ///
	(connect asian year if private_feeder==0, msymbol(D) lpattern(dash) mcolor(orange) lcolor(orange))  ///	
	, scheme(s1color) legend(rows(2) order( 1 "URM-- Priv. feeder" 2 "URM-- other" ///
	3 "Asian-- Priv. feeder" 4 "Asian-- other") ) ///
	xlabel(1920(20)2000) xtitle("Entering year") ytitle(Share) xsize(20) ysize(14) name(rs2, replace)	
graph export "$figures//hs_dems_lr_2.png", as(png) width(3200) replace

restore

preserve
collapse (mean) male, by(year private_feeder )

twoway (connect male year if private_feeder==1, msymbol(Dh) lpattern(solid)) ///
	(connect male year if private_feeder==0, msymbol(Oh) lpattern(dash)) ///
	, scheme(s1color) legend(order(1 "Priv. feeder" 2 "Other")) xtitle("Entering year") ///
	ytitle(Share male) yline(0.5,lpattern(dash) lcolor(gs7)) name(gs3, replace)
graph export "$figures/hs_dems_lr_3.png", as(png) width(3200) replace
	
restore 
}

//
//
// Table 8: Harvard demographics over the long run: 
//
//

label define racecat2 1 "Jewish (surname only)" 2 "Colonial" 3 "Oth. wht" 4 "URM" 5 "Asian"

if $ACCESS == 1 {
	// generate dummies for race cat: 
	tab race_cat , gen(race)
	levelsof race_cat, local(levels)
	foreach l of local levels{
		label var race`l' "`:label racecat2 `l''"
	}
}

// gen female variable
gen female = gender == "F"
// set female variable to missing in classes before 1975
replace female=0 if class<=1974
// set female to missing when gender is missing and class is at least 1975
replace female = . if gender == "" & class > 1974

// generate year categories: 
cap drop years*
gen years19201940 = class>= 1920 & class <= 1944
gen years19411974 = class>= 1945 & class <= 1966
gen years19751990= class >=1967 & class <= 1990
gen years19912015= class >=1991 & class <= 2015

// label variables for output: 
label var female "Female"
label var male "Male"
label var years19201940 "1923-1944"
label var years19411974 "1945-1966"
label var years19751990 "1967-1990"
label var years19912015 "1991-2015"

// define panel titles for table: 
global all_title "A. All"
global private_feeder_title "B. Private feeder HS"
global ad_club_title "C. In A.D. club"

// define table objects: 
global columns "years19201940 years19411974 years19751990 years19912015"
local ncols = wordcount("$columns")
global panels "all private_feeder ad_club"
global rows "male race1 race2 race3 race4 race5  "
if $ACCESS == 0 {
	global rows = "male"
}
global rows_ad_club " private_feeder public_feeder  "
global rows_all " private_feeder public_feeder  "

// Write table:
// columns are time periods
// panels are HS types
// rows w/in panels are characteristic shares

cap file close f 
file open f using "$tables/longrun-demos-desc.tex", write replace

file write f "\begin{tabular}{l*{`ncols'}{c}}"_n

// Header
foreach col in $columns {
	file write f "& `:var la `col''"
}
file write f "\\"_n
file write f "\midrule"_n

// Body
foreach panel in $panels {
	file write f "\multicolumn{3}{l}{\emph{${`panel'_title}}}\\"_n
	foreach var in $rows ${rows_`panel'} {
		file write f "`:var la `var''"
		foreach col in $columns {
			qui su `var' if `col' == 1 & `panel' == 1 & have_race==1 // use only obs w/ race codes
			if `r(N)'>40 file write f _tab  "&" %9.3f (`r(mean)')
			if `r(N)'<=40 file write f _tab  "&" 

		}
		file write f "\\"_n
	}
	
	file write f "\\" _n "Share"
	foreach col in  $columns{
		qui su `panel' if  `col' == 1 & have_hs_rec==1 & have_race==1
		file write f "&" %4.3f (`r(mean)')
	}
	
	file write f "\\"_n
	file write f "N w/ race codes"
	foreach col in  $columns{
		qui count if `col' == 1 & `panel' == 1 & have_race==1
		file write f "&" %9.0f (`r(N)')
	}
	file write f "\\ \addlinespace"_n
}

file write f "\bottomrule"_n
file write f "\end{tabular}"
file close f

if $ACCESS == 1 {
	// relabel the race variable for other tables
	levelsof race_cat, local(levels)
	foreach l of local levels{
		label var race`l' "`:label racecat `l''"
	}
}

//
// Table 9/10: Long run trends in grades and career paths
//

// format variables for output: 

// set HS type vars to zero (not missing) whenever we observe HS name
replace private_feeder=0 if private_feeder==. & have_hs_rec==1
replace public_feeder=0 if public_feeder==. & have_hs_rec==1

cap drop years*
gen years19201940 = class>= 1920 & class <= 1940
gen years19451970 = class>= 1945 & class <= 1965
gen years19751990= class >=1970 & class <= 1990

gen not_magna_summa=1-magna_summa
gen not_ad_club=1-ad_club

// label variables for output: 
label var female "Female"
label var male "Male"
label var finance "Finance"
label var magna_summa "High hon."
label var private_feeder "Priv. Fdr."
label var public_feeder "Pub. Fdr."
label var md_grad "MD"
label var jd_grad "JD"
label var mba_grad "MBA"
label var not_magna_summa "Not high hon."
label var not_ad_club "Not A.D. club"
label var ad_club "A.D. club"
label var all "All"
label var hed "Higher ed."
global years19201940_title "A. 1924-1940"
global years19451970_title "B. 1945-1965 (5-year intervals)"
global years19751990_title "C. 1970-1990 (5-year intervals)"

// globals that define output
global columns1 "all male female race1 race2 race3 race4 race5"
global columns2 "private_feeder public_feeder ad_club not_ad_club"
local ncols1 = "8"
local ncols2 = "4"
global panels "years19201940 years19451970 years19751990"
global rows "magna_summa finance  hed md_grad jd_grad mba_grad"

if $ACCESS == 0 {
	
	global columns1 "all male female"
	global columns2 "private_feeder public_feeder ad_club not_ad_club"
	local ncols1 = "3"
	local ncols2 = "4"
	global panels "years19201940 years19451970 years19751990"
	global rows "magna_summa finance hed md_grad jd_grad mba_grad"
	
}

// Write table
/*
- columns are samples: all, male, female, private feeder, public feeder, white, urm, asian, jewish, colonial (very wide)
- panels: time periods-- 1920-1940, 1941-1965, 1966-present
- within each panel, rows are means
- rows are magna-summa, finance, higher ed, md (jd, mba if room)
- sample count w/ occupation data
- set international=0 for race/ethnic categories
-set male to 1 for classes 1974 and earlier
-suppress display of categories with <40 obs
*/

forv i = 1/2 {

	cap file close f 
	file open f using "$tables/longrun-cross-section-desc`i'.tex", write replace

	file write f "\begin{tabular}{l*{`ncols`i''}{c}}"_n

	// Header
	foreach col in ${columns`i'} {
		file write f "& `:var la `col''"
	}
	file write f "\\"_n
	file write f "\midrule"_n

	// Body
	foreach panel in $panels {
		file write f "\multicolumn{3}{l}{\emph{${`panel'_title}}}\\"_n
		foreach var in $rows {
			file write f "`:var la `var''"
			foreach col in ${columns`i'} {
				qui su `var' if `col' == 1 & `panel' == 1
				if `r(N)'>40 file write f _tab  "&" %9.3f (`r(mean)')
				if `r(N)'<=40 file write f _tab  "&" 

			}
			file write f "\\"_n
		}

		// file write f "\\"_n "Share"
		// foreach col in  $columns{
		// 	qui su `col' if have_occ == 1  & `panel' == 1
		//	file write f "&" %4.3f (`r(mean)')
		// }

		file write f "\\"_n
		file write f "N"
		foreach col in  ${columns`i'}{
			qui count if have_occ == 1 & `col' == 1 & `panel' == 1
			file write f "&" %9.0f (`r(N)')
		}
		file write f "\\ \addlinespace"_n
	}

	file write f "\bottomrule"_n
	file write f "\end{tabular}"
	file close f

}

// output numbers for text: Grades and career paths over time 
// share magna_summa
su magna_summa if class>=1924 & class<=1926 // would need to average in order to match figure 6A
store_stat share_hhonor_19241926 "`r(mean)'" 0 per 
su magna_summa if class>=1985 & class<=1990 
store_stat share_hhonor_19851990 "`r(mean)'" 0 per 
// any honor numbers for appendix b
su have_honors if class>=1924 & class<=1926 // would need to average in order to match figure 6A
store_stat share_anyhonor_19241926 "`r(mean)'" 0 per 
su have_honors if class>=1985 & class<=1990 
store_stat share_anyhonor_19851990 "`r(mean)'" 0 per 

if $ACCESS == 1 {
	// share finance by 70-90s
	foreach group in race1 race2 race3 race4 race5 male female {
	su finance if years19751990==1 & `group'==1
	store_stat finance_`group'_7590 "`r(mean)'" 1 per 
	}
}

//
//
// benchmark our race and gender codes to IPEDS/HEGIS aggregates
//
//
// Figure B.19 Panels A,B,C

if $ACCESS == 1 {
	use "$cleaned/lr_series_redbooks_update", clear
}

if $ACCESS == 0 {
	use "$cleaned/lr_series_redbooks_clean", clear
}

// keep if year<=1990
label define male 0 "Female" 1 "Male"
label values male male 

// make the male variable 0 when gender is not male pre class of 1975
replace male = 0 if gender != "M" & class <= 1974
// set male to 0 if gender is missing
replace male = 0 if gender == ""

gen urm=(black==1 | hispanic==1)  /*& international==0 */ if have_race==1
collapse (mean) asian urm male  black hispanic have_race (sum) all , by(year)

// keep only years in which we race coded-- we do happen to pick some people in alternate class years but delete  those
foreach var in urm asian black hispanic {
	replace `var'=. if have_race<=.05
}

append using "$intstata/IPEDS_HEGIS_harvard_enrollment.dta"
gen share_black=enrollfullblack_firsttime/ enrollfull_firsttime
gen share_hisp=enrollfullhisp_firsttime/enrollfull_firsttime

 drop if year>2015 
	
// gender benchmarking
twoway (connect male year, msymbol(Oh)) ///
	(scatter share_male year, msymbol(X)) ///
	, scheme(s1color) legend(order(1 "Our codes" 2 "Harvard/Radcliffe in IPEDS/HEGIS")) ///
	xtitle(Entering year) ytitle(Share)  xlabel(1920(10)2010) 
graph export "$figures/women_benchmark.png", as(png) width(3200) replace

// race benchmarking:	
twoway (connect asian year, msymbol(Dh)) ///
	(scatter share_asian year, msymbol(d)) ///
(connect black year, msymbol(Oh)) ///
	(scatter share_black year, msymbol(o)) ///
(connect hisp year, msymbol(Th)) ///
	(scatter share_hisp year, msymbol(t)) ///	
	, scheme(s1color) ///
	legend(order(1 "Asian" 2 "Asian in IPEDS/HEGIS" 3 "Black" 4 "Black in IPEDS/HEGIS" 5 "Hispanic" 6 "Hispanic in IPEDS/HEGIS") ) ///
	xtitle(Entering year) ytitle(Share) yline(0.5, lpattern(dash) lcolor(gs7))	xlabel(1920(10)2010)	
graph export "$figures/race_benchmark.png", as(png) width(3200) replace
	
// enrollment count benchmarking
twoway (connect all year, msymbol(Oh)) ///
	(scatter enrollfull_firsttime  year, msymbol(X)) ///
	, scheme(s1color) legend(order(1 "Our codes" 2 "Harvard/Radcliffe in IPEDS/HEGIS")) ///
	xtitle(Entering year) ytitle(Share)  xlabel(1920(10)2010) ///
	ylabel(0(250)1500)	
graph export "$figures/count_benchmark.png", as(png) width(3200) replace


if $ACCESS == 1 {
	
	//
	//
	// appendix tables on availability of index data  (short and long-run): 
	//
	//
	// Table B.9

	use "$cleaned/lr_series_redbooks_update", clear
	label var all "All"
	label var private_feeder "Private feeder"
	label var public_feeder "Public feeder"

	// indicators for non-missing culture indicators
	// jewish, catholic, and colonial indicators are non-missing when a name appears in 1920 or 1930 Census
	gen have_jfn=!mi(jewish_fnindex)
	gen have_jln=!mi(jewish_lnindex)

	gen have_cathfn=!mi(cath_fnindex)
	gen have_cathln=!mi(cath_lnindex)

	gen have_colln=!mi(oldMA_lnindex)

	count if have_jfn!=have_cathfn // these are the same-- they just depend on whether name is in early Census records
	count if have_jln!=have_cathln // these are the same as well

	label var have_jfn "Have FN culture indices"
	label var have_jln "Have LN culture indices" 

	// indicators for non-missing race-ethnicity name indices

	global samps "all private_feeder public_feeder" // note: this is LR extended public feeder def
	global rowsA "have_jfn have_jln"
	gen mainsamp=year<=1935
	gen lrsamp=1 

	// Open file
	cap file close f 
	file open f using "$tables/name-index-availability.tex", write replace
	file write f "\begin{tabular}{l*{5}{c}}"_n
	file write f "\toprule"_n

	// Column headers
	foreach samp in $samps {
		file write f "& `: var la `samp''"
	}
	file write f "\\" _n
	file write f "\midrule"_n

	// Write row panels
	write_panel "$rowsA" "$samps" "A. Main sample (1923-1939)" "mainsamp"
	write_panel "$rowsA" "$samps" "B. LR sample (1923-2015)" "lrsamp"

	// Sample sizes
	file write f "\\"_n
	file write f "N (full sample)"
	foreach samp in $samps {

			count if `samp'==1 & mainsamp==1
			file write f _tab "&" %9.0f (`r(N)')
		
	}
	file write f "\\"_n

	// Close file
	file write f "\bottomrule"_n
	file write f "\end{tabular}"_n
	file close f

	//
	//
	// AD shares by decade (FOR SLIDES, NOT IN TEXT)
	//
	//
	use "$cleaned/lr_series_redbooks_update", clear

	label define male 0 "Female" 1 "Male"
	label values male male 
	
	gen schooltype=4  if have_hs_rec==1 
	replace schooltype=1 if public_feeder==1 & have_hs_rec==1
	replace schooltype=2 if private_feeder==1 & have_hs_rec==1
	replace schooltype=3 if private_other==1 & have_hs_rec==1

	label define schooltype  1 "Public feeder"  2 "Private feeder" 3 "Other private" 4 "Other HS"
	label values schooltype schooltype

	// stand-alone public feeder variable with non-missing values
	replace public_feeder=0 if mi(public_feeder) & have_hs_rec==1

	gen race_cat=. 
	replace race_cat=1 if  have_race==1 & jewish_lnindex>0.7 &  !mi(jewish_lnindex) // jewish
	replace race_cat=2 if have_race==1 & (jewish_lnindex<=0.7 | mi(jewish_lnindex) )& ///
		oldMA_lnindex>0.7 & !mi(oldMA_lnindex) // colonial	
	replace race_cat=3 if non_white==0 & have_race==1 & ( jewish_lnindex<=0.7 | mi(jewish_lnindex) )  ///
		& (oldMA_lnindex<=0.7 | mi(oldMA_lnindex)) // other white; includes missing index values of name indices
	replace race_cat=4 if (hispanic==1 | black==1 ) & have_race==1 // urm
	replace race_cat=5 if asian==1 & have_race==1 // asian

	count if have_race==1 & mi(race_cat) // <1% of records; these are other non-white and missing hand-codes

	label define racecat 1 "Jewish" 2 "Colonial" 3 "Other white" 4 "URM" 5 "Asian"
	label values race_cat racecat

	keep if class>=1923 & class<=2015
	gen cbin=floor(class/10)*10+5
	replace cbin=2012.5 if cbin==2015

	tab race_cat, gen(racedum)
	tab schooltype, gen(stdum)
	collapse (mean) racedum* stdum* male finance hed jd_grad md_grad magna_summa, by(cbin ad_club)

	twoway (connect male cbin if ad_club==1, msymbol(Oh)) ///
		 (connect male cbin if ad_club==0, msymbol(Dh)) ///
		 , legend(order(1 "AD club" 2 "Other students"))  scheme(s1color) ///
		 xtitle("") ytitle("") title(Male) name(gmale, replace) nodraw ///
		 xlabel(,labsize(vsmall))

	foreach j in 1 2 4 5 {
	local title : label racecat `j'

	twoway (connect racedum`j' cbin if ad_club==1, msymbol(Oh)) ///
		 (connect racedum`j' cbin if ad_club==0, msymbol(Dh)) ///
		 , legend(order(1 "AD club" 2 "Other students"))  scheme(s1color) ///
		 xtitle("") ytitle("") title(`title') name(grace`j', replace) nodraw ///
		 xlabel(,labsize(vsmall))
		
	}

	foreach j in 1 2 3 {
	local title : label schooltype  `j'

	twoway (connect stdum`j' cbin if ad_club==1, msymbol(Oh)) ///
		 (connect stdum`j' cbin if ad_club==0, msymbol(Dh)) ///
		 , legend(order(1 "AD club" 2 "Other students"))  scheme(s1color) ///
		 xtitle("") ytitle("") title(`title') name(gs`j', replace) nodraw ///
		 xlabel(,labsize(vsmall))
	}

	grc1leg gmale grace1 grace2 grace4 grace5 gs1 gs2 gs3, scheme(s1color) rows(2) 
	graph export "$figures/ad-club.png", as(png) width(3200) replace

	twoway (connect magna_summa cbin if ad_club==1, msymbol(Oh)) ///
		 (connect magna_summa cbin if ad_club==0, msymbol(Dh)) ///
		 , legend(order(1 "AD club" 2 "Other students"))  scheme(s1color) ///
		 xtitle("") ytitle("") 

		 
}