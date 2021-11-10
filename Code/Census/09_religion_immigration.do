/*

09_religion_immigration.do
(called from master_census.do)

Purpose: producesimmigration related output
Inputs: cleaned/census_rb_merged,
Outputs: figures/jewish_name_index_time_trend, intstata/binsdata_`index',
	figures/final_club_name_indices_binscatter, tables/most-common-names-by-ethnicity
	
*/

/*
figure on religious discrimination
	-panel A: jewish name index by year
	-panel B: final club membership by jewish name index
	-panel C: final club membership catholic name index
	-Panel D: final club membership by colonial name index 
*/

// Figure A.8

global jewish_var "jewish_index"

use "$cleaned/census_rb_merged", clear

gen jewish_name=${jewish_var}>=0.7 if !mi(${jewish_var})

preserve
	gen year_bin = year if mod(year,2)==0
	replace year_bin = year - 1 if mi(year_bin)

	collapse (mean) jewish_index jewish_name ,  by(year_bin)
	// expand 2 if year_bin >= 1922 & year_bin <= 1924, gen(copy)
	// replace year_bin = year_bin  + 1 if copy == 1
	// replace jewish_index = . if copy == 1
	qui su jewish_name
	local upper = round(`r(max)',0.02)
	gen upper = `upper' if year >= 1922 & year <= 1925
	label var upper "Top 7th policy"
	label var jewish_index "Jewish name index"
	label var jewish_name "Jewish"	
	sort year_bin
	qui su jewish_index
	local ypos = round(`r(max)',0.02)- .0025
	twoway 	(area upper year if year_bin >= 1922, bcolor(gs15)) ///
		(connected jewish_name year_bin , col(navy)) ///
		, ///
		scheme(s1color) xtitle("") ytitle(Share with Jewish names) ///
		xtitle(Entering year) /// 
		xline(1926 ,lp(dash) lc(gray)) ///
		text(`ypos' 1926 "Non-academic admissions criteria",place(e) size(small)) ///
		legend(order(2 1)) xlabel(1920(5)1930)
	graph export "$figures/jewish_name_index_time_trend.png", as(png) width(3200) replace
restore

// Figure A.4
// Make binscatters of name Index by sel. fin. club membership
//

foreach index in jewish_index cath_index oldMA_lnindex {
	preserve
		binsreg final_tier2 `index', ///
			scheme(s1color) ytitle(Share in Sel. fin. club) ///
			ylab(0(.025).15) xtitle("`:var la `index''") ///
			nbins(10) binspos(es) ///
			savedata($intstata/binsdata_`index') replace
	restore
}

use "$intstata/binsdata_jewish_index", clear
gen group = 1
append  using "$intstata/binsdata_cath_index"
replace group = 2 if mi(group)
append  using "$intstata/binsdata_oldMA_lnindex"
replace group = 3 if mi(group)

label var dots_fit "Share sel. final club"
label var dots_x "Name index"
twoway (connected dots_fit dots_x if group == 1 , msym(O) col(maroon)) ///
	(connected dots_fit dots_x if group == 2 , msym(Th) col(emerald)) ///
	(connected dots_fit dots_x if group == 3 , msym(Sh) col(navy)), ///
	scheme(s1color) legend(rows(1) order(1 "Jewish" 2 "Catholic" ///
	3 "Colonial"))

graph export "$figures/final_club_name_indices_binscatter.png", as(png) width(3200) replace
graph drop _all

// Table A.1
// Make table of 10 most common names by name indices
//
use "$cleaned/census_rb_merged", clear

// Colonial last names
preserve
	keep if !mi(namelast)
	keep if lncount > 100
	bys namelast: keep if _n == 1
	gsort -oldMA_lnindex
	lis namelast oldMA_lnindex in 1/10
	gen namelast_oldMA_rank = _n
	tempfile oldMA_last
	save `oldMA_last', replace
restore

// Jewish last names
preserve
	keep if !mi(namelast)
	keep if lncount > 100
	
	bys namelast: keep if _n == 1
	gsort -jewish_lnindex
	lis namelast jewish_lnindex in 1/10
	gen namelast_jewish_rank = _n
	tempfile jewish_last
	save `jewish_last', replace
restore

// Jewish first names
preserve
	keep if !mi(namefrst)
	keep if fncount >100
	bys namefrst: keep if _n == 1
	gsort -jewish_fnindex
	lis namefrst jewish_fnindex in 1/10
	gen namefrst_jewish_rank = _n
	tempfile jewish_first
	save `jewish_first', replace
restore

// Catholic last names
preserve
	keep if !mi(namelast)
	keep if lncount>100
	bys namelast: keep if _n == 1
	gsort -cath_lnindex
	lis namelast cath_lnindex in 1/10
	gen namelast_cath_rank = _n
	tempfile catholic_last
	save `catholic_last', replace
restore

// Catholic first names
preserve
	keep if !mi(namefrst)
	keep if fncount > 100
	bys namefrst: keep if _n == 1
	gsort -cath_fnindex
	lis namefrst cath_fnindex in 1/10
	gen namefrst_cath_rank = _n
	tempfile catholic_first
	save `catholic_first', replace
restore

merge m:1 namelast using `oldMA_last', nogen keep(1 3) keepusing(*oldMA_rank)
merge m:1 namelast using `jewish_last', nogen keep(1 3) keepusing(*jewish_rank)
merge m:1 namelast using `catholic_last', nogen keep(1 3) keepusing(*cath_rank)
merge m:1 namefrst using `jewish_first', nogen keep(1 3) keepusing(*jewish_rank)
merge m:1 namefrst using `catholic_first', nogen keep(1 3) keepusing(*cath_rank)

// Make table of 10 most common first and last names by jewish, catholic and colonial index

levelsof namelast if namelast_jewish_rank==1, local(last)
di `last'
cap file close f 
file open f using "$tables/most-common-names-by-ethnicity.tex", write replace
file write f "\begin{tabular}{l*{6}{c}}"_n
file write f "\toprule"_n

file write f "& \multicolumn{2}{c}{Jewish names} & \multicolumn{2}{c}{Catholic Names}"
file write f "& \multicolumn{2}{c}{Colonial names} \\"_n
file write f "\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7}"_n

file write f "Rank"
forv k = 1/3 {
	file write f "& First & Last"
}

file write f "\\"_n

file write f "\midrule"_n

forv k = 1/10 {
	file write f "`k'"
	
	foreach col in "jewish" "cath" "oldMA" {
		local first_name ""
		if "`col'" != "oldMA" {
			levelsof namefrst if namefrst_`col'_rank==`k', local(first_name)
		}
		levelsof namelast if namelast_`col'_rank==`k', local(last_name)
		file write f _tab "&" `first_name' _tab "& " `last_name'
	}
	
	file write f "\\ \addlinespace"_n
	
}

file write f "\bottomrule"_n
file write f "\end{tabular}"_n
file close f 