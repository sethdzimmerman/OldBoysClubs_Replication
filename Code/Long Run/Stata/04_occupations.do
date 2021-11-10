/*

04_occupations.do
(called from master_longrun.do)

Purpose: creates occupation-related figures
Inputs: cleaned/lr_series_redbooks_clean
Outputs: figures/occupations_vs_degree_doctor_law-all, figures/occupations_vs_degree_doctor-all,
	figures/occupations_vs_degree_law-all, figures/occupations_finance_hs_split-all,
	figures/occupations_other_hs_split-all
	
*/


///////////////////
/// Occupations ///
///////////////////

use "$cleaned/lr_series_redbooks_clean", clear
drop if year < 1920
* Make private a categorical instead of a binary variable
gen hs_split = 1 if public_feeder == 1
replace hs_split = 2 if private_feeder == 1
replace hs_split = 3 if private == 1 & private_feeder == 0
replace hs_split = 4 if nonfeeder == 1

// Double count Class report years into two rolling average bins, 
// i.e. 1980 class report in 1977.5 and 1982.5
expand 2 if class==class_bin & class<1990, gen(copy)
replace class_bin = class_bin - 2.5 if copy ==0 
replace class_bin = class_bin + 2.5 if copy ==1
drop if class_bin < 1920

local legend_str_all = "off"
local legend_str_all_short = "off"

local legend_str_hs_split = `"order(1 "Public Feeder" 2 "Private feeder" "'
local legend_str_hs_split_short = `"order(1 "Public Feeder" 2 "Private feeder")"'

gen honor_split=.	
replace honor_split=1 if magna_summa!=1 & have_degree==1	
replace honor_split=2 if magna_summa==1

local legend_str_honor_split = `"order(1 "Low/no honors" 2 "High honors" "' 
local legend_str_honor_split_short = `"order(1 "Low/no honors" 2 "High honors")"'		

global symbol_hs_split1 = "Oh"
global symbol_hs_split2 = "T"
global symbol_hs_split5 = "X"
global col_hs_split1 = "maroon"
global col_hs_split2 = "navy"
global col_hs_split5 = "gray"

global symbol_honor_split1 = "Sh"		
global symbol_honor_split2 = "D"
global symbol_honor_split5 = "X"

global col_honor_split1 = "emerald"
global col_honor_split2 = "sienna"
global col_honor_split5 = "gray"

global occ_vars = "finance finance_ext doctor law "
global degree_vars = "phd_grad md_grad jd_grad mba_grad"
global intersec_vars = "$occ_vars $degree_vars"

gen have_intersec = have_degree == 1 & have_occ == 1

foreach sample in "all" {
	foreach split in hs_split { 
		foreach cat in "occ" "degree" {

			preserve
				// add a pooled split category
				expand 2 , gen(`split'copy)
				replace `split' = 5 if `split'copy == 1 
		
				// subsample
				keep if `sample' == 1
				collapse (mean) ${`cat'_vars} ///
				(count)N=have_`cat' ///
				if cr_year == 1 & have_`cat' == 1, by(class_bin `split')
				
				cap label var finance "Finance"
				cap label var finance_ext "Finance (incl. firms)"
				cap label var doctor "Doctor"
				cap label var hed "Higher Ed."
				cap label var law "Law"
				cap label var tech "Tech"
				cap label var manage_high "Snr. mgmt."
				cap label var mba_grad "MBA"
				cap label var phd_grad "PhD"
				cap label var md_grad "MD"
				cap label var jd_grad "JD"

				// Code parameters
				// Minimum cross section size required to display data in long run figures
				global N_min = 30

				foreach var of varlist ${`cat'_vars} {
					// Display year only if N is large enough
					replace `var' = . if N < $N_min
					
					// Version with tile for multiple panels
					twoway ///
						(connect `var' class_bin if `split' == 1, ///
							col(${col_`split'1}) mfc(${col_`split'1}%60) ///
							msize(medlarge) msymbol(${symbol_`split'1})) ///
						(connect `var' class_bin if `split' == 2, ///
							col(${col_`split'2}) mfc(${col_`split'2}%60) ///
							msize(medlarge) msymbol(${symbol_`split'2})) ///
						, xsca(range(1920 1990)) xlab(1920(10)1990,labsize(small)) ///
						ylab(,labsize(small) labgap(.05cm)) ///
						scheme(s1color) legend(rows(2) colgap(*.5) symxsize(*.3) ///
							`legend_str_`split'' ) size(small)) ///
						title("`:var la `var''") ///
						ytitle(Share, size(medsmall)) xtitle("") xsize(4) ysize(3) ///
						name(g7_`var', replace)
										
					// Bigger markers 
					replace `var' = . if N < $N_min
					twoway ///
						(connect `var' class_bin if `split' == 1, ///
							col(${col_`split'1}) mfc(${col_`split'1}%60) ///
							msize(vlarge) msymbol(${symbol_`split'1})) ///
						(connect `var' class_bin if `split' == 2, ///
							col(${col_`split'2}) mfc(${col_`split'2}%60) ///
							msize(vlarge) msymbol(${symbol_`split'2})) ///
						, xsca(range(1920 1990)) xlab(1920(10)1990,labsize(small)) ///
						ylab(,labsize(small) labgap(.05cm)) ///
						scheme(s1color) legend(rows(1) colgap(*.5) symxsize(*.5) ///
							`legend_str_`split'' ) size(medsmall)) ///
						title("`:var la `var''") ///
						ytitle(Share, size(medsmall)) xtitle("") xsize(4) ysize(3) ///
						name(g7c_`var', replace)
					
				} // var
			restore

		} //cat
		
		//figure b.24
		// Other occupations version
		grc1leg g7_doctor g7_law g7_phd_grad, ///
			scheme(s1color) ycommon cols(2) name(g8, replace)
		gr_edit legend.xoffset = 25
		gr_edit legend.yoffset = 25
		graph display g8, xsize(16) ysize(16)
		graph export "$figures/occupations_other_`split'-`sample'.png", width(2400) replace
		
		// figure b.22
		// Finance with and without firms
		grc1leg g7c_finance g7c_finance_ext, ///
				scheme(s1color) leg(g7c_finance) ycommon name(g8, replace) cols(2)
		graph display g8, xsize(20) ysize(7)
		graph export "$figures/occupations_finance_`split'-`sample'.png", width(2400) replace
		
		graph drop _all
		
	}
} 

/// Compare Doctor vs MD and Lawyer vs JD
foreach samp in "all" {
	preserve
		keep if `samp' == 1
		collapse (mean) doctor law *grad ///
			(count)N=have_intersec ///
			if cr_year == 1 & have_intersec == 1, by(class_bin)
						
		label var doctor "Doctor"
		label var law "Law"
		label var md_grad "MD"
		label var jd_grad "JD"

		foreach var of varlist doctor law md_grad jd_grad {
								
			// Display year only if N is large enough
			replace `var' = . if N < $N_min
		}

		// Version with tile for multiple panels
		twoway ///
			(connect doctor class_bin, col(navy) msize(medlarge) msymbol(Sh)) ///
			(connect md_grad class_bin , lpat(dash) col(navy) mfc(navy%60) ///
				msize(medlarge) msymbol(S)) ///
			, xsca(range(1920 1990)) xlab(1920(10)1990,labsize(small)) ///
			ylab(,labsize(small) labgap(.05cm)) ///
			scheme(s1color) legend(rows(1) colgap(*.5) symxsize(*.3) ///
				order(1 "Medicine" 2 "MD") size(small)) ///
			ytitle(Share, size(medsmall)) xtitle("") xsize(16) ysize(10) ///
			name(g7_doctor_md, replace)
		graph export "$figures/occupation_vs_degree_doctor-`samp'.png", width(2400) replace
		
		twoway ///
			(connect law class_bin, col(gray) msize(medlarge) msymbol(Oh)) ///
			(connect jd_grad class_bin , lpat(dash) col(gray) mfc(gray%60) ///
				msize(medlarge) msymbol(O)) ///
			, xsca(range(1920 1990)) xlab(1920(10)1990,labsize(small)) ///
			ylab(,labsize(small) labgap(.05cm)) ///
			scheme(s1color) legend(rows(1) colgap(*.5) symxsize(*.3) ///
				order(1 "Law" 2 "JD") size(small)) ///
			ytitle(Share, size(medsmall)) xtitle("") xsize(16) ysize(10) ///
			name(g7_law_jd, replace)
		graph export "$figures/occupation_vs_degree_law-`samp'.png", width(2400) replace

		graph combine g7_doctor_md g7_law_jd, ///
			scheme(s1color) cols(1) ycommon name(g9, replace) xsize(16) ysize(20)
			
		// figure b.23
		graph export "$figures/occupation_vs_degree_doctor_law-`samp'.png", width(2400) replace

	restore
}

graph drop _all