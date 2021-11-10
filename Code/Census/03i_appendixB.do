/*

03i_appendixB.do
(called from 03_descriptive.do)

Purpose: produces various output from Appendix B
Inputs: cleaned/census_rb_merged, bulk/all_indv_1940_desc
Outputs: tables/cen_occ_tab_both, tables/lassotab, figures/phat_hist_act,
	figures/phat_hist_uyclubs, figures/phat_hist_occs, figures/phat_hist_adultclubs,
	figures/phat_all_hist, cleaned/census_rb_merged, figures/rg3*
	
*/


/*
    Produces additional tables and figures for appendix B
        - Table B.6: Most common Census occupation by Class Report occupation
        - Table B.7: Most common Census occupation: Harvard vs all men 27-37
        - Table B.8: Coefficient estimates from Lasso estimation
        - Figure B.13: Occupation private school indices
		- Figure B.15: Academic rank in years 1 and 3
*/

//////////////////////////////////////////////////////////////
/// Table B.6 
/// Most common Census occupation by Class Report occupation
//////////////////////////////////////////////////////////////
******************** Census Occupations *********************

** table will have to be displayed landscape

// program to output descriptive tables
// argument 1: file name
// argument 2: rowlists
// argument 3: collists
// argument 4: N top occs

cap program drop occ_tab 
program define occ_tab 
	cap file close f
	file open f using "${tables}/`1'.txt", write replace

	file write f "\begin{tabular}{l cccc|lccc}"	 _n 	

	
	file write f  "Class report occ." 
	// column headers: 
	foreach outcome in `3' { 
		file write f $tab "`:var label `outcome''"
	}

	file write f  $tab "Modal census occ." $tab "Occ. score" $tab "N" $tab "Share" 

	// loop over occupations of interest: 
	foreach occ in `2' {
		if "`occ'"=="finance" file write f $llb "`:var label `occ''"
		if "`occ'"!="finance" file write f $lb "`:var label `occ''"
		
		if "`occ'"=="finance" |  "`occ'"=="manage_high" {
			local mod_occ=290
			local mod_ws=42
			local mod_label="Managers, officials, and proprietors (n.e.c.)"
		}
		if "`occ'"=="law" {
			local mod_occ=55
			local mod_ws=62
			local mod_label="Lawyers and judges"
		}
		if "`occ'"=="doctor" {
			local mod_occ=75
			local mod_ws=80
			local mod_label="Physicians and surgeons"
		}
		
	local mod_ws=`mod_ws'*100 // convert occ scores to dollar units

	// loop over outcome vars: 
	foreach var in `3' { 
		su `var' if occ19501940_nber==`mod_occ' & `occ'==1
		if "`var'"!="incwage1940_clean" file write f $tab %4.2f (`r(mean)')
		if "`var'"=="incwage1940_clean" file write f $tab %5.0f (`r(mean)')
	}

	gen ismode=(occ19501940_nber==`mod_occ')
	su ismode if `occ'==1
		file write f $tab "`mod_label'" $tab "`mod_ws'" $tab %5.0f (`r(sum)') $tab %4.2f (`r(mean)') 
	drop ismode

	}

	file write f $lb "\end{tabular}"	

	file close f 

end 
//
// end program
//
// for reference, program arguments:
// argument 1: file name
// argument 2: rowlists
// argument 3: collists

if $ACCESS == 1 {

	use "$cleaned/census_rb_merged", clear
	label var finance "Finance"
	label var manage_high "Senior management"
	label var law "Law"
	label var doctor "Medicine"
	label var poswage1940 "Has wage inc."
	label var incwage1940_clean "Wage inc."
	label var topincwg1940 "Wage inc. 5k+"
	label var incnonwg1940_clean "Has non-wage inc."
	keep if year>1919 & year<1931 // only keep cohorts 1920-1930 

	global our_occs "finance manage_high law doctor" 
	global cen_wage "poswage1940 incwage1940_clean topincwg1940 incnonwg1940_clean"

	occ_tab occ_tab "$our_occs" "$cen_wage"

	////////////////////////////////////////////////////////////
	/// Table B.7 
	/// Most common Census occupation: Harvard vs all men 27-37
	////////////////////////////////////////////////////////////
	{
		cap program drop cen_occ_tab 
		program define cen_occ_tab 
			cap file close f
			file open f using "${tables}/`1'.txt", write replace

			file write f "\begin{tabular}{l rcccc}"	 _n 	

			foreach pop in harvard men2737 {	
				if "`pop'"=="harvard" {
					file write f  "Census occ." $tab "N"  
					// $tab "Occ. score" 

					use "$cleaned/census_rb_merged", clear
					keep if year>1919 & year<1931 // only keep cohorts 1920-1930 
					gen all_occ = !mi(occ19501940_nber)
					label var all_occ "All occupations"
					label var poswage1940 "Has wage inc."
					label var incwage1940_clean "Wage inc."
					label var topincwg1940 "Wage inc. 5k+"
					label var incnonwg1940_clean "Has non-wage inc."

					// column headers: 
					foreach outcome in `3' { 
						file write f $tab "`:var label `outcome''"
					}
					// panel labels: 
					file write f $llb "\multicolumn{6}{l}{\emph{A. Harvard cohorts 1920-1930}}"
					
				}
				
				if "`pop'"=="men2737" {
					use "$intstata/all_indv_1940_desc.dta", clear
					keep if men2737==1
					gen all=1
					gen all_occ = !mi(occ19501940_nber)
					label var all_occ "All occupations"
					label var poswage1940 "Has wage inc."
					label var incwage1940_clean "Wage inc."
					label var topincwg1940 "Wage inc. 5k+"
					label var incnonwg1940_clean "Has non-wage inc."

					file write f $lb  $lb "\multicolumn{6}{l}{\emph{B. All men ages 27-37}}"
				}
				// loop over occupations of interest: 
				foreach occ in `2' {
					if "`occ'"=="290" file write f $lb "`: label occ1950_lbl  `occ''" 
					if "`occ'"!="290" & "`occ'"!="29" & "`occ'"!="all" file write f $lb "`: label occ1950_lbl `occ''"
					if "`occ'"=="29" file write f $lb "College professors"
					if "`occ'"=="all" file write f $lb "All occupations"

					** hard coding wage scores here because didn't include them in original census pull
					if "`occ'"=="290" local ws=42 // manager nec
					if "`occ'"=="55" local ws=62 // lawyer
					if "`occ'"=="75" local ws=80 // doctor
					if "`occ'"=="490" local ws=24 // salesman
					if "`occ'"=="93" local ws=27 // teachers
					if "`occ'"=="99" local ws=33 // professionsal, technical and kindred worker
					if "`occ'"=="390" local ws=25 // clerical and kindred workers 
					if "`occ'"=="29" local ws=41 // subject not specified (college professor)
							
					if "`occ'"!="all" su all if occ19501940_nber==`occ'
					if "`occ'"=="all" su all if all_occ==1

					file write f $tab %5.0f (`r(N)') 
					// $tab "`ws'"

					// loop over outcome vars: 
					foreach var in `3' { 
						if "`occ'"!="all" su `var' if occ19501940_nber==`occ' 
						if "`occ'"=="all" su `var' if all_occ==1
						
						if "`var'"!="incwage1940_clean" file write f $tab %4.2f (`r(mean)')
						if "`var'"=="incwage1940_clean" file write f $tab %5.0f (`r(mean)')
					}

				}

			}
			file write f $lb "\end{tabular}"	

			file close f 

		end 
		//
		// end program
		//

		global top_occs "290 55 75 490 93 99 390 29 all" 
		global cen_wage "poswage1940 incwage1940_clean topincwg1940 incnonwg1940_clean"

		cen_occ_tab cen_occ_tab_both "$top_occs" "$cen_wage"
	
}

//////////////////////////////////////////////////////////////
/// Table B.8
/// Coefficient estimates from Lasso estimation
//////////////////////////////////////////////////////////////

use "$cleaned/census_rb_merged", clear
*keep if year>1919

label var aclead "Activity leadership position" 
label var have_occ "Have occupation"
label var doctor "Medicine"
label var law "Law"
label var finance "Finance"
label var manage_high "Senior management" 
label var manage_low "Low management" 
label var teach "Teach"
label var hed "Higher ed."
label var gov "Government"
label var art_pub "Art/pub"
label var sci "Science"
label var sports "Sports"
label var music "Music" 
label var social "Social"
label var final_tier2 "Selective final club"
label var pf_wm "Private feeder"
label var hasty "Hasty Pudding Inst. 1770"
label var have_ac "Have any activity"
label var nac "Activity count"
label var have_social_club "Have soc. club"
label var redbook "Redbook" 
label var dorm_com "Dorm committee"
label var language "Language club"
label var drama "Drama club"
label var politics "Politics club"
label var other_club "Other club" 
label var zphat_cl "Adult association index"
label var any_social_main "Any social club"
label var any_honor "Any honor/prof group"
label var bookkeep "Accounting" 
label var bus "Retail"
label var engineer "Engineering"
label var zphat_cl "Club PHS score"
label var have_country_club "Country club"
label var have_gent_club "Gentleman's club"
label var have_frat_order "Fraternal order"
label var have_prof_assoc "Prof. Association" 
label var have_hon_club "Honor society" 
label var final_club "Any final club"

lasso2 pf_wm have_ac nac aclead social sports music redbook dorm_com language drama politics  other_club ///		
	i.year  , long postresults lic(ebic)
	
mat B1=e(b)
local N1=`e(N)'
global list1 "`e(selected0)'"	


lasso2 pf_wm  final_tier2 hasty final_club ///		
	i.year , long postresults lic(ebic)
	
mat B2=e(b)
global list2 "`e(selected0)'"	
local N2=`e(N)'	
	
lasso2 pf_wm manage_high manage_low bus bookkeep finance doctor law  hed teach gov art_pub engineer sci ///
	i.year , long postresults lic(ebic)
	
mat B3=e(b)
global list3 "`e(selected0)'"	
local N3=`e(N)'


lasso2 pf_wm have_country_club have_gent_club have_frat_order have_prof_assoc have_hon_club  ///
	i.year, long postresults lic(ebic)
	
mat B4=e(b)
global list4 "`e(selected0)'"	
local N4=`e(N)'

cap file close f 
file open f using "${tables}/lassotab.txt", write replace
file write f "\begin{tabular}{lc lc lc lc}" 
file write f _n "\multicolumn{2}{c}{Activities}" $tab "\multicolumn{2}{c}{UY Clubs}" $tab  "\multicolumn{2}{c}{Occupations}" $tab "\multicolumn{2}{c}{Associations}" $llb

// Only keep coefficients that are not year FEs or the constant
forv k = 1/4 {
	global coef_list`k' = ""
	local count = wordcount("${list`k'}")
	forv j =1/`count' {
		local name = word("${list`k'}",`j')
		if strpos("`name'","19")==0 & "`name'"!="" & "`name'"!="_cons"  {
			global coef_list`k' = "${coef_list`k'} `name'"
		}
	}
	global count`k' = wordcount("${coef_list`k'}")
}

global count=max( $count1 , $count2 , $count3 , $count4 )

forv j=1/$count {
	* Start new line
	file write f $lb
	* First column
	if `j' <= wordcount("$coef_list1")  {
		local name=word("$coef_list1",`j')
		local coef=B1[1,`j']
		file write f "`: var label `name''" $tab  %4.3f (`coef')
	}
	else {
		file write f $tab $tab
	}

	* Second column
	if `j' <= wordcount("$coef_list2") {
		local name=word("$coef_list2",`j')
		local coef=B2[1,`j']
		
		di "`name'"
		file write f $tab "`: var label `name''" $tab  %4.3f (`coef')
	}
	else {
		file write f $tab $tab
	}
	
	* Third column
	if `j' <= wordcount("$coef_list3") {
		local name=word("$coef_list3",`j')
		local coef=B3[1,`j']
		
		di "`name'"
		file write f $tab "`: var label `name''" $tab  %4.3f (`coef')
	}
	else {
		file write f $tab $tab
	}
	
	* Fourth column
	if `j' <= wordcount("$coef_list4") {
		local name=word("$coef_list4",`j')
		local coef=B4[1,`j']
		
		di "`name'"
		file write f $tab "`: var label `name''" $tab  %4.3f (`coef')
	}
	else {
		file write f $tab $tab
	}
}
file write f $llb
file write f "N" $tab %12.0f (`N1') $tab  $tab %12.0f (`N2')  $tab  $tab %12.0f (`N3') $tab  $tab %12.0f (`N4') "\\"

file write f _n "\end{tabular}"
file close f

//////////////////////////////////////////////////////////////
/// Figure B.13
/// Occupation private school indices
//////////////////////////////////////////////////////////////

use "$cleaned/census_rb_merged" , clear	

label var phat_ac "Predicted feeder | freshman activity"

su phat_ac if phat_ac>0, det
hist phat_ac if phat_ac>0, scheme(s1color) color($c_pf) start(0) width(.01) ///
	xline(`r(p10)', lpattern(dash)) ///
	xline(`r(p90)', lpattern(dash)) xline(`r(p50)', lpattern(dash))	///
	 xlabel(0(.2)1)  name(g1, replace) title(Activities)

graph export "${figures}/phat_hist_act.png", replace width(2400)

	
label var phat_uac "Predicted feeder | upper-year club"

su phat_uac if phat_uac>0, det
hist phat_uac if phat_uac>0, scheme(s1color) color($c_pf) start(0) width(.01) ///
	xline(`r(p10)', lpattern(dash)) ///
	xline(`r(p90)', lpattern(dash)) xline(`r(p50)', lpattern(dash))	///
	xlabel(0(.2)1)  name(g2, replace) title(Upper-year clubs)

graph export "${figures}/phat_hist_uyclubs.png", replace width(2400)
	
label var phat_oc "Predicted feeder | occupation"

su phat_oc, det
hist phat_oc , scheme(s1color) color($c_pf) start(0) width(.01) ///
	xline(`r(p10)', lpattern(dash)) ///
	xline(`r(p90)', lpattern(dash)) xline(`r(p50)', lpattern(dash))	///
	xlabel(0(.2)1) name(g3, replace) title(Occupations)
	
graph export "${figures}/phat_hist_occs.png", replace width(2400)

label var phat_cl "Predicted feeder | adult associations"

su phat_cl, det
hist phat_cl , scheme(s1color) color($c_pf) start(0) width(.01) ///
	xline(`r(p10)', lpattern(dash)) ///
	xline(`r(p90)', lpattern(dash)) xline(`r(p50)', lpattern(dash))	///
	xlabel(0(.2)1) name(g4, replace) title(Adult Associations)

graph export "${figures}/phat_hist_adultclubs.png", replace width(2400)
		
	
gr combine g1 g2 g3 g4, scheme(s1color)  xsize(20) ysize(8)

graph export "${figures}/phat_all_hist.png", replace width(2400)

//////////////////////////////////////////////////////////////
/// Figure B.15
/// Academic rank in years 1 and 3
//////////////////////////////////////////////////////////////

// upper-year grades: how does rankgroup3 compare to rankgroup1?
use "$cleaned/census_rb_merged", clear

cor rankgroup1 rankgroup3 if year>1919 & year<1931
local rho = r(rho) /*create the local*/
di `rho'

// Rescale rankgroup1 and rankgroup3

gen rankgroup1_lab = rankgroup1 * (-1)
label define rankgroup1_lab -1 "1" -2 "2" -3 "3" -4 "4" -5 "5" -6 "6"
label values rankgroup1_lab rankgroup1_lab
label var rankgroup1_lab "`:var la rankgroup1'"

** Upper Panel of Figure B.15
twoway hist rankgroup3 if year>1919 & year<1931, scheme(s1color) color($c_all) ///
	discrete  by(rankgroup1_lab, title(Third-year rank group by first-year rank group)) ///
	xlabel(1(1)6) xsc(reverse) 
	
graph export "${figures}/rg3_by_rg1_hist.png", width(2400) replace
 
drop if year<1920 | year>1930
collapse (mean) rankgroup3 (p25) p25_rg3=rankgroup3 (p75) p75_rg3=rankgroup3, by(pf_wm rankgroup1) 

* Not in paper
twoway (scatter rankgroup3 rankgroup1 if pf_wm==1, color($c_pf) ) ///
	(scatter rankgroup3 rankgroup1 if pf_wm==0, color($c_npf) ) ///
	, scheme(s1color) legend(order(1 "Private feeder" 2 "Other high school")) ///
	ylabel(1(1)6) xlabel(1(1)6) ysc(reverse) xsc(reverse) ///
	xtitle(First-year rank group) ytitle(Mean third-year rank group) ///
	title(Mean third-year rank group by first-year rank group)  
 graph export "${figures}/rg3_by_rg1_binscatter.png", width(2400) replace
 
 
** Lower panel of Figure B.15
use "$cleaned/census_rb_merged", clear
drop if year<1920 | year>1930
collapse (mean) rankgroup3 (p25) p25_rg3=rankgroup3 (p75) p75_rg3=rankgroup3, by(rankgroup1) 

twoway (scatter rankgroup3 rankgroup1, color($c_all) ) ///
	(scatter p25_rg3 rankgroup1 , color($c_all) msymbol(X)) ///
	(scatter p75_rg3 rankgroup1 , color($c_all) msymbol(+)) ///
	, scheme(s1color) legend(order(1 "Average" 2 "25th pctile" 2 "75th pctile") rows(1)) ///
	xlabel(1(1)6) ylabel(1(1)6) ysc(reverse) xsc(reverse)  ///
	xtitle(First-year rank group) ytitle(Third-year rank group) ///
	title(Third-year rank group by first-year rank group)  
graph export "${figures}/rg3_by_rg1_binscatter_iqr.png", width(2400) replace
 
}