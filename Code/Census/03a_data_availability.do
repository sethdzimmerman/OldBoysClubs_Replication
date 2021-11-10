/*

03a_data_availability.do
(called from 03_descriptive.do)

Purpose: prodcues output on data availability
Inputs: cleaned/census_rb_merged
Outputs: tables/merge_table, figures/merge_A_cohort_size, figures/merge_B_campus,
	figures/merge_C_class_report, figures/merge_D_census, figures/merge_fig
	
*/

/*
    Produce Table 1 and Figure A.1 on Data Availability in
    different samples
*/

***** Table 1 *******
** counts and share of eligable universe for outcomes and samples

* short run social (1919-1935)
* short run academic (1920-1935)
* college residential (1919-1925; 1927-1935)
* college residential for random (1922-1925; 1927-1935)
* medium-run social (1919-1934)
* class report occ (1920-1935)
* census outcomes (1920-1933)
* census outcomes with min 6 yrs exp (1920-1930)

* random 5: Census + residential (1922-1925; 1927-1930)
* random 6: Census wage income + residential (1922-1925; 1927-1930)

use "$cleaned/census_rb_merged", clear

label var all "Freshman Red Book"
label var have_hs_rec "High school"
label var has_pid "25 year Class Report"
label var have_occ "Class Report occupation"

gen have_campus_address_n1926=have_campus_address
replace have_campus_address_n1926=. if year==1926 
label var have_campus_address_n1926 "Campus address"

if $ACCESS == 1 {
	gen has_census_preH_2033=has_census_preH
	replace has_census_preH_2033=. if year<1920 | year>1933
	label var has_census_preH_2033 "Pre-Harvard census"
	label var has_census1940_2030 "1940 Census"
}	

replace oncampus=. if have_campus_address_n1926==0 | mi(have_campus_address_n1926)
replace rblock_sample=. if have_campus_address_n1926==0 | mi(have_campus_address_n1926)
label var rblock_sample "Randomization sample"


** variables not available for 1919
foreach var in have_grade has_pid have_occ{
replace `var'=. if year==1919
}

gen have_medsoc=(year<1935)
replace have_medsoc=. if year>1934
label var have_medsoc "Have upper-year social club membership"

if $ACCESS == 1 {
	gen random5=(has_census1940_2030==1 & rblock_sample==1)
	label var random5 "1940 census + in randomization"
	gen random6=(has_census1940_2030==1 & poswage1940==1 & rblock_sample==1)
	label var random6 "1940 census wage income + in randomization"

	foreach n in 5 6 {
		replace random`n'=. if year<1920 | year==1926 | year>1930
	}

	foreach var in has_census1940_2030 {
		replace `var'=. if year<1920 | year>1930
	}
}
// for statistics in text
gen d1919=(year==1919)
gen d1935=(year==1935)

// want to present some availability conditional on class report link:

if $ACCESS == 1 {
	foreach var in has_census1940_2030 has_census_preH_2033 {
		gen `var'_if_cr=`var'
		replace `var'_if_cr=. if has_pid!=1
	}
	label var has_census1940_2030_if_cr "1940 Census"
	label var has_census_preH_2033_if_cr "Pre-Harvard Census"	
}

gen have_occ_if_cr=have_occ
replace have_occ_if_cr=. if has_pid!=1
label var have_occ_if_cr "Class Report occupation"

local tablelist "all have_hs_rec have_campus_address_n1926  has_pid have_occ has_census1940_2030 has_census_preH_2033 have_occ_if_cr has_census1940_2030_if_cr has_census_preH_2033_if_cr"

if $ACCESS == 0 {
	
	local tablelist "all have_hs_rec have_campus_address_n1926 has_pid have_occ have_occ_if_cr"
	
}

preserve
	// table:
	cap file close f
	file open f using "${tables}/merge_table.txt", write replace

	file write f "\begin{tabular}{l ccl}" 
	file write f _n "Data type" $tab  "Share non-missing" $tab  "Universe"  $tab "N"  $llb

	foreach var of varlist `tablelist' {
		tab year `var', m 
		local cohs "unspecified"
		if "`var'"=="all" | "`var'"=="have_hs_rec"{
			local cohs "Cohorts 1919-35"
		}
		if "`var'"=="have_campus_address_n1926"	 local cohs "Cohorts 1919-25; 1927-35"

		if "`var'"=="has_pid"  | "`var'"=="have_occ" {
			local cohs "Cohorts 1920-35"
		}
		if "`var'"=="has_census_preH_2033" local cohs "Cohorts 1920-33"

		if "`var'"=="has_census1940_2030"  local cohs "Cohorts 1920-30"

		su `var'
		
		if "`var'"=="all" {
			file write f "\multicolumn{4}{l}{\emph{A. Match rates within available cohorts}}" 
		}
		if "`var'"=="have_occ_if_cr" local cohs "Cohorts 1920-35 in Class Report"
		if "`var'"=="has_census1940_2030_if_cr" local cohs "Cohorts 1920-30 in Class Report"
		if "`var'"=="has_census_preH_2033_if_cr" local cohs "Cohorts 1920-33 in Class Report"
		if "`var'"=="have_occ_if_cr" {
			file write f $lb  $lb"\multicolumn{4}{l}{\emph{B. Match rates conditional on Class Report availability}}"
		}
		file write f	$lb "`:var label `var''"  $tab %4.3f (`r(mean)') $tab "`cohs'" $tab %12.0f (`r(N)')
		
	}
	file write f $llb
	file write f "\end{tabular}"
	file close f
restore

**** store stats for text *****
if $ACCESS == 1 {
	gen rblock_sample_2030=rblock_sample
	replace rblock_sample_2030=. if year>1930 | year<1920

	foreach var in all d1919 d1935 rblock_sample rblock_sample_2030 random5 random6 {
		su `var' 
		store_stat N_`var' "`r(sum)'"  "c" 
	}

	gen have_occ_if_pid=have_occ
	replace have_occ_if_pid=. if has_pid==0
	foreach var in have_hs_rec have_campus_address_n1926 have_occ have_occ_if_pid ///
		have_grade have_medsoc has_pid has_census1940_2030 has_census_preH_2033 ///
		has_census1940_2030_if_cr has_census_preH_2033_if_cr {
		su `var' 
		store_stat perc_`var' "`r(mean)'" 0 per 
	}

	* share of students in randomized room who are in cohorts matched to census
	su rblock_sample
	local Nr2035 `r(sum)'
	su rblock_sample_2030
	local Nr2030 `r(sum)'
	local shareNr=`Nr2030'/`Nr2035'
	store_stat perc_roomattscencoh `shareNr' 1 per 

	su random5
	local rcenmatch `r(sum)'
	local sharecen=`rcenmatch'/`Nr2030'
	store_stat perc_roomattscenmatch `sharecen' 1 per 

	su random6
	local rwage `r(sum)'
	local sharewage=`rwage'/`rcenmatch'
	store_stat perc_rcenwage `sharewage' 1 per 
}


********** Figure A.1 **************
** Counts and Merge rates (all by in universe cohorts) 
* A. class size count 
* B. Merge rates to short / medium-run outcomes (anything while at Harvard)
* C. Merge rates to long-run class report outcomes
* D. Merge rates to census background and outcomes 

local figurelist "have_hs_rec have_campus_address has_pid have_occ has_census_preH has_census1940_2033"

if $ACCESS == 0 {
	
	local figurelist "have_hs_rec have_campus_address has_pid have_occ"
	
}
 
 * want to show availability rates from the base of the whole population 
foreach var in `figurelist' {
	replace `var'=0 if mi(`var')
}
 
// figure: 
display "`figurelist'"
collapse (mean) `figurelist' (sum) all, by(year)

label var all "N in Red Book"
label var have_campus_address "Freshman address"
label var have_occ  "Occupation"
label var has_pid "Class Report match"
label var have_hs_rec "High school"

// Don't display missing years as 0
foreach var of varlist * {
	replace `var' = . if `var' == 0 
}

if $ACCESS == 1 {
	replace has_census_preH = . if year == 1919 | year >= 1934
	label var has_census1940_2033 "1940 Census"
	label var has_census_preH "Chldhd. Census"
}

twoway (connect all year, msymbol(Oh)) , ///
	xsca(range(1919 1935)) xlab(1920(5)1935) ///
	scheme(s1color) title(A. Cohort size) ///
ylabel(500(200)1100) xsize(15) ysize(13) name(g1, replace) 
graph export "${figures}/merge_A_cohort_size.png", width(2400) replace


twoway (connect have_hs_rec year, msymbol(Oh)) ///
	(connect have_campus_address year, msymbol(Th)) ///
	, xsca(range(1919 1935)) xlab(1920(5)1935) ///
	scheme(s1color) legend(colgap(*.5) symxsize(*.5)) ///
	title(B. Campus records) ytitle(Share) xsize(15) ysize(13) name(g2, replace) 	
graph export "${figures}/merge_B_campus.png", width(2400) replace

twoway (connect has_pid year, msymbol(Oh)) ///
	(connect have_occ year, msymbol(Dh)) ///
	,xsca(range(1919 1935)) xlab(1920(5)1935) ///
	scheme(s1color) title(C. Class Report) ytitle(Share) ///
	xsize(15) ysize(13) name(g3, replace) ///
	legend(rows(1) colgap(*.75) symxsize(*.5))
graph export "${figures}/merge_C_class_report.png", width(2400) replace

if $ACCESS == 1{

	twoway (connect has_census_preH year, msymbol(Oh)) ///
		(connect has_census1940_2033 year, msymbol(Th)) ///
		,xsca(range(1919 1935)) xlab(1920(5)1935) /// 
		scheme(s1color) title(D. Census) ytitle(Share)  ///
		xsize(15) ysize(13) name(g4, replace) ///
		legend(rows(1) colgap(*.75) symxsize(*.5))
	graph export "${figures}/merge_D_census.png", width(2400) replace
	
	gr combine g1 g2 g3 g4, scheme(s1color)  
	graph export "${figures}/merge_fig.png", replace width(2400)
 
}

if $ACCESS == 0 {
	
	gr combine g1 g2 g3, scheme(s1color)  
	graph export "${figures}/merge_fig.png", replace width(2400)
	
}

graph drop _all