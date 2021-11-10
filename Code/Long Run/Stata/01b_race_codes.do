/*

01b_race_codes.do
(called from 01_clean_redbooks.do)

Purpose: code race variable
Inputs: raw/Red_Books_race_handcodes
Outputs: N/A

*/

global filelist : dir "$raw/Red_Books_race_handcodes/" files "race_template*.xlsx"

foreach file in $filelist {
	preserve
		import excel using "$raw/Red_Books_race_handcodes//`file'", first clear
		qui su year
		qui assert `r(min)' == `r(max)'
		local year = `r(mean)'
		
		keep if !mi(index)
		keep index *check* year  comment
		ren *_check* *
		tostring comment, force replace
		
		foreach var in white non_white black hispanic asian {
			cap destring `var', replace force
			replace `var' = 0 if mi(`var')
			replace `var' = . if comment == "no picture available"
		}
		
		tempfile races`year'
		save `races`year'', replace
	restore
	
	merge 1:1 index using `races`year'', gen(_mrace_`year') keep(1 3 4 5) update
	tab _mrace_`year'  if class == `year'

}

gen have_race = 0
levelsof class ,  local(years)
foreach year in `years' {
	cap  replace have_race = 1 if _mrace_`year' >= 3 & class == `year'
	if _rc != 0 {
		di "No racecodes in `year' available."
	}
}

drop _mrace_*

// classify white non hisp and black non hisp: 
gen white_non_hisp = white == 1 & hispanic == 0 if have_race==1
gen black_non_hisp = black == 1 & hispanic == 0 if have_race==1

drop comments_on_race_coding