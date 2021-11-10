/*

01c_clean_census_extract_preHarvard.do
(called from 01_clean_census.do)

Purpose: extract and clean data from pre Harvard years census
Inputs: CENSUS_PATH2/dta/`year', intstata/hh_extract_`year'
Outputs: intstata/harvard_indv_preH_desc, intstata/all_ed_191030_desc,
	intstata/harvard_indv_and_dist_preH_desc, intstata/harvard_only_indv_preH_desc,
	intstata/harvard_only_indv_and_dist_preH_desc
	
*/

** clean 1900-1930 extracts to characterizes the households students grew up in

global keep_varlist "stateicp enumdist serial sex age occ1950 edscor50 erscor50 occscore farm hhtype gq lit mtongue bpl mbpl fbpl ownershp relate famunit famsize pernum momloc poploc sploc" 

use "$intstata/hh_extract_1930.dta", clear
gen cen_year=1930
gen harvard=(hs_pernum1930_nber==pernum)
gen hs_histid=hs_histid1930

foreach year in 1900 1910 1920 {
	append using "$intstata/hh_extract_`year'.dta"
	replace cen_year=`year' if mi(cen_year)
	replace harvard=(hs_pernum`year'_nber==pernum) if mi(harvard)
	replace hs_histid=hs_histid`year' if mi(hs_histid)
} 
keep $keep_varlist cen_year hs_histid harvard

bysort cen_year serial: egen max_pernum=max(pernum)

gen nparents=0
foreach parent in mom pop{
gen d`parent'=(`parent'loc>0)
replace d`parent'=. if mi(`parent'loc)
replace nparents=nparents+1 if d`parent'==1
}
gen dsp=(sploc>0)
replace dsp=. if mi(sploc) 

tempfile hh
save `hh'

** there are some more variables at the harvard student (hs) level that would be helpful to have available at the household level 
keep if harvard==1
foreach var in famsize famunit momloc poploc sploc relate mbpl fbpl { //dsp dmom dpop 
rename `var' hs_`var'
}
keep cen_year serial hs_*

merge 1:m cen_year serial hs_histid using `hh', nogen

** for the most part, I only want to characterize the family
gen in_hs_fam=(famunit==hs_famunit)
foreach rel in mom pop sp{
gen is_hs_`rel'=(pernum==hs_`rel'loc & !mi(pernum))
}

** however, for borders and servants I need to seperate out group quarters
gen head=(relate==101)
gen rel=((relate>101 & relate<=1061) | relate==1206) // include foster child as family instead of boarder
gen vis=(relate>=1100 & relate<=1139)
gen bdr=(relate>=1200 & relate<=1206 & relate!=1206)
gen emp=(relate>=1210 & relate<=1217)
gen emp_rel=(relate==1219) // relatives of employees shouldn't count in count of employees
gen other_nonrel=(relate>=1221)

gen relate_cat=""
foreach var in head rel vis bdr emp emp_rel other_nonrel {
replace relate_cat="`var'" if `var'==1
}

gen gq_any=(gq>2)

gen ownershp_clean=ownershp
replace ownershp_clean=. if (ownershp!=10 & ownershp!=20)
replace ownershp_clean=0 if ownershp==20
replace ownershp_clean=1 if ownershp==10

// by household count employee, boarder
// replace counts with missing if gq_any==1 | hs_relate>=1100 

// keep if in_hs_fam  

// isrelate not in ipums documentation, but flags if related to head
foreach vbpl in bpl mbpl fbpl{
	gen `vbpl'_us=(`vbpl'<15000)
	gen `vbpl'_ma=(`vbpl'==02500) // massachusetts
	gen `vbpl'_eu=(`vbpl'>=40000 & `vbpl'<49900) // any europe 
	gen `vbpl'_cee=(`vbpl'>=45000 & `vbpl'<49900) // central / eastern europe 
	gen `vbpl'_ee=(`vbpl'>=45400 & `vbpl'<49900) // cee without Germany 
	gen `vbpl'_se=(`vbpl'>=43000 & `vbpl'<45000) // southern europe 
	gen `vbpl'_we=(`vbpl'>=42000 & `vbpl'<43000) // western europe 
	gen `vbpl'_ne=(`vbpl'>=40000 & `vbpl'<42000) // norther europe 
	gen `vbpl'_ir=(`vbpl'>=41400 & `vbpl'<=41410) // ireland + northern ireland 
	gen `vbpl'_ca=(`vbpl'>=15000 & `vbpl'<15500) // canada
}

gen gen1_immg=(bpl_us==0)
gen gen1_immg_se=(bpl_se==1)
gen gen1_immg_ee=(bpl_ee==1)
gen gen1_immg_ir=(bpl_ir==1)
gen gen2_immg=(mbpl_us==0 | fbpl_us==0)
gen gen2_immg_ee=(mbpl_ee==1 | fbpl_ee==1)
gen gen2_immg_se=(mbpl_se==1 | fbpl_se==1)
gen gen2_immg_ir=(mbpl_ir==1 | fbpl_ir==1)

gen mt_yjh_wm=((mtongue>=0300 & mtongue <=0320) | mtongue==5900)
gen mt_yjh=mt_yjh_wm
replace mt_yjh=. if mtongue==0 
gen mt_noteng_wm=(mtongue!=100 & mtongue!=0)
gen mt_noteng=mt_noteng_wm
replace mt_noteng=. if mtongue==0

* recall mtougue only asked of those born outside the US
* 99% of those reporting yiddish/jewish/hebrew were born in central or eastern europe // tab bpl_cee  if (mtongue>=0300 & mtongue <=0320) | mtongue==5900
* 40% of those born in central or eastern europe report mtounge of yiddish/jewish/hebrew // tab bpl_cee  
* of those born in cee who do not report mt of yjh, 80% report English, German, or Russian, (the next 10% report Polish or Lithuanian) // tab mtongue   if !((mtongue>=0300 & mtongue <=0320) | mtongue==5900) & bpl_cee, sort

* will group together only read and only write with neither
* not defined for under 10
gen lit_clean=(lit==4)
gen lit_adult=(lit==4)
replace lit_clean=. if age<10
replace lit_adult=. if age<18

gen fhead=(hhtype==3)
replace fhead=. if hhtype==0 | mi(hhtype)

** recode 2, 1 variables as 0, 1
foreach var in farm {
gen `var'_clean=`var'-1
replace `var'_clean=. if (`var'>2 | `var'<1)
} 

gen occscore_clean=occscore
replace occscore_clean=. if occscore==0

foreach var in edscor50 erscor50{
gen `var'_clean=`var'
replace `var'_clean=. if `var'>100
}

gen has_cen_occ=(occ1950<=970)

gen cen_fin_any=inlist(occ1950,0,305,310,450,470,480)
gen cen_mng_any=(occ1950>=200 & occ1950<=290)

gen cen_sci=inlist(occ1950,7) | (occ1950>=61 & occ1950<=69)
gen cen_hed=(occ1950>=10 & occ1950<=29)
gen cen_art=inlist(occ1950, 1,4,6,31,33,36,51,57,502) //art and publishing
gen cen_doc=inlist(occ1950,32,70,75) // includes dentists and optometrists but not nurses
gen cen_law=inlist(occ1950,55)
gen cen_tch=inlist(occ1950,93)

foreach var in fin mng_any sci hed art doc law tch {
	replace cen_`var'=. if has_cen_occ==0
}

** who will be 25-36 in 1940? byear 1904-1915
gen byear= cen_year - age
gen men2536=(sex==1 & byear>=1904 & byear<=1915)
** flag current prime aged men
gen prime_age_m =(sex==1 & age>=25 & age<=54)
egen ed = concat(stateicp enumdist) , punct("_") //no countyicp prior to 1940; unlike
egen ed_year=concat(ed cen_year), punct("_")
egen serial_year=concat(serial cen_year), punct("_")

egen hs_serial_year=concat(hs_histid serial cen_year), punct("_")
foreach dvar in emp bdr rel{ 
bysort hs_serial_year: egen N_`dvar'=sum(`dvar' ) if gq<=2
gen d_`dvar'=(N_`dvar'>0)
}

save "$intstata/harvard_indv_preH_desc.dta", replace

preserve
keep if is_hs_pop==1
keep occscore_clean erscor50_clean edscor50_clean occ1950 has_cen_occ cen_art cen_doc cen_fin_any cen_hed cen_law cen_mng_any cen_sci cen_tch hs_histid

rename occscore_clean f_ocscor
rename erscor50_clean f_erscor
rename edscor50_clean f_edscor

foreach var in occ1950 has_cen_occ cen_art cen_doc cen_fin_any cen_hed cen_law cen_mng_any cen_sci cen_tch {
	rename `var' f_`var'
}
gen father_present=1
tempfile father
save `father'

restore
keep if harvard ==1
isid hs_histid 
merge 1:1 hs_histid using `father', nogen

// have father occ among all with preH census matches (not just those with a father present)
replace father_present=0 if mi(father_present)
replace f_has_cen_occ=0 if father_present==0

rename hs_histid histid
foreach var of varlist _all{
   rename `var' preH_`var'
   }  
   
save "$intstata/harvard_only_indv_preH_desc.dta", replace