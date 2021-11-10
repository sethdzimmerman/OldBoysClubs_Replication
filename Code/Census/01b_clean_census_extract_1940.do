/*

01b_clean_census_extract_1940.do
(called from 01_clean_census.do)

Purpose: extract and clean data from 1940 census
Inputs: CENSUS_PATH1/dta-columns/1940/`var', CENSUS_PATH1/dta/1940, intstata/histids_1940,
	intstata/extract_1940
Outputs: intstata/all_ed40_1940_desc, intstata/all_indv_1940_desc,
	intstata/harvard_indv_and_all_dist_1940_desc
	
*/

*only keep necessary variables to free up memory
global keep_varlist= "stateicp countyicp supdist enumdist histid sex age relate valueh rent ownershp incwage incnonwg farm school empstat classwkr educ occ1950 occscore metro bpl mbpl fbpl"
*only keep necessary variables to free up memory
global keep_varlist1940_nber= "_harvardmerge1940 harvard ed1940_nber histid1940 sex1940_nber age1940_nber relate1940_nber valueh1940_nber rent1940_nber ownershp1940_nber incwage1940_nber incnonwg1940_nber farm1940_nber school1940_nber empstat1940_nber classwkr1940_nber educ1940_nber occ19501940_nber occscore1940_nber metro1940_nber bpl1940_nber mbpl1940_nber fbpl1940_nber"
***********************************************************
**** Store full population percentiles for later (runtime = 2-3 minutes) *******
***********************************************************
** faster to just read in necessary columns for this step
cd "$CENSUS_PATH1/dta-columns/1940/"
use age, clear
foreach var in sex rent valueh incwage relate{
   merge 1:1 _n using `var'
   drop _merge
   } 
*keep if (sex==1 & age>=25 & age<=36) 
keep if (sex==1 & age>=27 & age<=37) 
replace rent=. if (rent==0 | rent>=9998)
replace valueh=. if (valueh>=9999998)
replace incwage=5000 if incwage>5000 & incwage<999998
replace incwage=. if (incwage==0 | incwage>=999998)

foreach per in p95 p99{
foreach cvar in rent valueh incwage{
	summarize `cvar', detail
local men2737_`per'_`cvar'=r(`per')
}
}
keep if (sex==1 & age>=27 & age<=37 & relate==101) // condition on head for next run, not in current vars
replace rent=. if (rent==0 | rent>=9998)
replace valueh=. if (valueh>=9999998)
replace incwage=5000 if incwage>5000 & incwage<999998
replace incwage=. if (incwage==0 | incwage>=999998)

foreach per in p95 p99{
foreach cvar in rent valueh incwage{
	summarize `cvar', detail
local men2737_head_`per'_`cvar'=r(`per')
}
}

display `men2737_p95_valueh'

use "$CENSUS_PATH1/dta/1940.dta" if ((sex==1 & age>=25 & age<=54) | relate==101), clear
keep $keep_varlist

foreach var of varlist _all{
   rename `var' `var'1940_nber
   }
drop if mi(histid)
rename histid histid1940
**rename ed401940_nber ed1940_nber
merge 1:1 histid1940 using "$intstata/histids_1940.dta", keep(match master) gen(_harvardmerge1940)

gen harvard=0 //harvard ids now flagged above, but will use harvard to flag the harvard sample records and both_samp to flag the copies that also show up in the 5 percent sample

append using "$intstata/extract_1940.dta"

egen ed1940_nber = concat(stateicp1940_nber countyicp1940_nber  supdist1940_nber  enumdist1940_nber ) , punct("_")
 
replace harvard = 1 if mi(harvard)
tab harvard _harvardmerge1940, m

keep $keep_varlist1940_nber

***********************************************************
**** Clean and construct individual-level variables *******
***********************************************************

* flag men 27-37 as cohorts that could have gone to Harvard
gen men2737=(sex1940_nber==1 & age1940_nber>=27 & age1940_nber<=37)
* flag household heads
gen head=(relate1940_nber==101)

gen dnotmetro=(metro1940_nber==1)
replace dnotmetro=. if mi(metro1940_nber)
gen dmetro_cc=(metro1940_nber==2)
replace dmetro_cc=. if mi(metro1940_nber)

gen valueh1940_clean=valueh1940_nber
replace valueh1940_clean=. if (valueh1940_nber>=9999998)
gen valueh1940_head=valueh1940_clean
replace valueh1940_head=. if head!=1
* these flags would work on the labels, ipums already chose values

gen rent1940_clean=rent1940_nber
replace rent1940_clean=. if (rent1940_nber==0 | rent1940_nber>=9998)
gen rent1940_head=rent1940_clean
replace rent1940_head=. if head!=1

gen toprent1940=(rent1940_clean==9997)
replace toprent1940=. if mi(rent1940_clean)

gen ownershp1940_clean=ownershp1940_nber
replace ownershp1940_clean=. if (ownershp1940_clean!=10 & ownershp1940_clean!=20)
replace ownershp1940_clean=0 if ownershp1940_clean==20
replace ownershp1940_clean=1 if ownershp1940_clean==10

gen ownershp1940_head=ownershp1940_clean
replace ownershp1940_head=0 if head==0

gen incwage1940_clean=incwage1940_nber
replace incwage1940_clean=5000 if incwage1940_clean>5000 & incwage1940_clean<999998
replace incwage1940_clean=. if (incwage1940_clean==0 | incwage1940_clean>=999998)

gen poswage1940=(incwage1940_nber>0)
replace poswage1940=0 if (mi(incwage1940_clean) | incwage1940_clean>=999998)

gen topincwg1940=(incwage1940_clean==5000)
replace topincwg1940=. if mi(incwage1940_clean)

** recode 2, 1 variables as 0, 1
foreach var in incnonwg farm school {
gen `var'1940_clean=`var'1940_nber-1
replace `var'1940_clean=. if (`var'1940_nber>2 | `var'1940_nber<1)
} 

gen lfp1940=(empstat1940_nber<30)
replace lfp1940=. if (mi(empstat1940_nber) | empstat1940_nber==0)

gen selfemp1940=(classwkr1940_nber==11 | classwkr1940_nber==12)
replace selfemp1940=. if (mi(classwkr1940_nber) | classwkr1940_nber==0)
gen nonfarm_selfemp1940=selfemp1940
replace nonfarm_selfemp1940=0 if farm1940_clean==1

** recode if only need to set 0 as missing
foreach var in occscore { 
gen `var'1940_clean=`var'1940_nber
replace `var'1940_clean=. if `var'1940_nber==0
}

gen hs1940=(educ1940_nber>=60)
gen col11940=(educ1940_nber>=70)
gen col41940=(educ1940_nber>=100)
gen col51940=(educ1940_nber>=110)
foreach var in hs1940 col11940 col41940 col51940{
replace `var'=. if (educ1940_nber==999 | mi(educ1940_nber))
 }
 
gen has_cen_occ=(occ19501940_nber<=970)

gen cen_fin_any=inlist(occ19501940_nber,0,305,310,450,470,480)
gen cen_mng_any=(occ19501940_nber>=200 & occ19501940_nber<=290)

gen cen_sci=inlist(occ19501940_nber,7) | (occ19501940_nber>=61 & occ19501940_nber<=69)
gen cen_hed=(occ19501940_nber>=10 & occ19501940_nber<=29)
gen cen_art=inlist(occ19501940_nber, 1,4,6,31,33,36,51,57,502) //art and publishing
gen cen_doc=inlist(occ19501940_nber,32,70,75) // includes dentists and optometrists but not nurses
gen cen_law=inlist(occ19501940_nber,55)
gen cen_tch=inlist(occ19501940_nber,93)

foreach var in fin mng_any sci hed art doc law tch {
	replace cen_`var'=. if has_cen_occ==0
}

foreach vbpl in bpl mbpl fbpl{
gen `vbpl'_us=(`vbpl'1940_nber<15000)
	gen `vbpl'_ma=(`vbpl'1940_nber==02500) // massachusetts
gen `vbpl'_eu=(`vbpl'1940_nber>=40000 & `vbpl'1940_nber<49900) // any europe 
	gen `vbpl'_cee=(`vbpl'1940_nber>=45000 & `vbpl'1940_nber<49900) // central / eastern europe 
	gen `vbpl'_ee=(`vbpl'1940_nber>=45400 & `vbpl'1940_nber<49900) // cee without Germany 
	gen `vbpl'_se=(`vbpl'1940_nber>=43000 & `vbpl'1940_nber<45000) // southern europe 
	gen `vbpl'_we=(`vbpl'1940_nber>=42000 & `vbpl'1940_nber<43000) // western europe 
	gen `vbpl'_ne=(`vbpl'1940_nber>=40000 & `vbpl'1940_nber<42000) // norther europe 
		gen `vbpl'_ir=(`vbpl'1940_nber>=41400 & `vbpl'1940_nber<=41410) // ireland + northern ireland 
gen `vbpl'_ca=(`vbpl'1940_nber>=15000 & `vbpl'1940_nber<15500) // canada
}

gen gen1_immg=(bpl_us==0)
gen gen1_immg_se=(bpl_se==1)
gen gen1_immg_ee=(bpl_ee==1)
gen gen2_immg=(mbpl_us==0 | fbpl_us==0)
gen gen2_immg_ee=(mbpl_ee==1 | fbpl_ee==1)
gen gen2_immg_se=(mbpl_se==1 | fbpl_se==1)

gen prime_age_m1940 =(sex1940_nber==1 & age1940_nber>=25 & age1940_nber<=54)

gen men2737_c1 =(sex1940_nber==1 & age1940_nber>=27 & age1940_nber<=37 & col11940==1)
replace men2737_c1=. if (educ1940_nber==999 | mi(educ1940_nber))
gen men2737_c4 =(sex1940_nber==1 & age1940_nber>=27 & age1940_nber<=37 & col41940==1)
replace men2737_c4=. if (educ1940_nber==999 | mi(educ1940_nber))

display `men2737_p95_valueh'

* generate top percentiles for whole population (or in this case male age cohorts)
foreach p in 95 99 { //90 99{
* select men 25-36	
foreach cvar in rent valueh incwage{
display `men2737_p`p'_`cvar'' 
gen dp`p'_`cvar'=0
replace dp`p'_`cvar'=1 if (`men2737_p`p'_`cvar''<=`cvar'1940_clean & !mi(`cvar'1940_clean))
replace dp`p'_`cvar'=. if (mi(histid1940) | (men2737==0 & harvard!=1))

display `men2737_head_p`p'_`cvar''
gen dp`p'_`cvar'_head=0
replace dp`p'_`cvar'_head=1 if (`men2737_head_p`p'_`cvar''<=`cvar'1940_clean & !mi(`cvar'1940_clean) & head==1)
replace dp`p'_`cvar'_head=. if (mi(histid1940) | (men2737==0 & harvard!=1))

} 
} 

** preserve data at the individual-level before we make enumeration district-level vars
preserve

 drop if harvard==1
 replace harvard=1 if _harvardmerge1940==3

***********************************************************
**** Clean and construct enumeration district-level variables (; 5 percent runtime ~20 minutes) *******
***********************************************************

* generate percentiles for continuous variables
foreach p in 50 90{ // 10 25 75 
* select head so each household has equal weight	
foreach cvar in rent valueh {
bysort ed1940_nber: egen dist_p`p'_`cvar'=pctile(`cvar'1940_clean ) if head==1, p(`p') 
}
* select prime-age men
foreach cvar in incwage { 
bysort ed1940_nber: egen dist_p`p'_`cvar'=pctile(`cvar'1940_clean ) if prime_age_m1940==1 , p(`p') 
}
}
* generate shares for discrete variables
* select head so each household has equal weight
foreach dvar in ownershp1940_clean ownershp1940_head toprent1940 { 
bysort ed1940_nber: egen dist_share_`dvar'=mean(`dvar' ) if head==1 
}
* select prime-age men 
foreach dvar in topincwg1940 incnonwg1940_clean farm1940_clean nonfarm_selfemp1940 hs1940 col41940 col51940 { 
bysort ed1940_nber: egen dist_share_`dvar'=mean(`dvar' ) if prime_age_m1940==1 
}

tab harvard dp95_valueh , m
* select 25-36 men : share earning above certain percentiles
foreach dvar in dp95_rent dp95_valueh dp95_incwage { //dp99_rent dp90_rent dp90_valueh dp99_valueh dp90_incwage dp99_incwage {
bysort ed1940_nber: egen dist_share_`dvar'=mean(`dvar' ) if men2737==1 
}

*bysort ed1940_nber: gen dist_N_pop=_N 
bysort ed1940_nber: egen dist_N_hh=total(head==1) 
bysort ed1940_nber: egen dist_N_prime=total(prime_age_m1940==1) 
bysort ed1940_nber: egen dist_N_harvard=total(harvard==1) 
bysort ed1940_nber: egen dist_N_men2737=total(men2737==1) 

gen dist_share_harvard=dist_N_harvard/dist_N_men2737

keep if men2737==1 & head==1 // subset to individuals with all dist variables defined 
bysort ed1940_nber : keep if _n == 1
keep ed1940_nber dist*

save "$intstata/all_ed40_1940_desc.dta", replace
** restore individual-level variables 
restore
** merge ed40-level records back in so that everyone is linked to enumdist characteristics
** and save individual-level data with cleaned vars and ed40 descriptive vars
merge m:1 ed1940_nber using "$intstata/all_ed40_1940_desc.dta", nogen
save "$intstata/all_indv_1940_desc.dta", replace
keep if harvard==1
save "$intstata/harvard_indv_and_all_dist_1940_desc.dta", replace

cd $code