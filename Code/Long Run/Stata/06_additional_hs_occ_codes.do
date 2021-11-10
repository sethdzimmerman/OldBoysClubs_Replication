/*

07_additional_hs_occ_codes.do
(called from master_longrun.do)

Purpose: creates appendix code tables
Inputs: keys/lr_high_school_key.xlsx, keys/high_school_key.xlsx, 
	keys/lr_occupation_key.xlsx, keys/occupation_key.xlsx
Outputs: tables/lr_additional_hs_codes, tables/lr_additional_occ_codes.tex


*/

//////////////////////////////////////////
/// Table B.30: Additional High schools ///
//////////////////////////////////////////

// Load long run high school codes
import excel "$keys/lr_high_school_key.xlsx", clear first

keep schoolcode name public private
ren public public_feeder
gen private_feeder=inlist(schoolcode,1,3,4,5,6,8,10,22) 

tempfile longrun
save `longrun', replace

/// Load main high school codes
import excel "$keys/high_school_key.xlsx", clear first

keep schoolcode name

merge 1:1 schoolcode using `longrun'

// assert _merge > 1
// Only list the added high school codes
keep if _merge == 2
sort name

foreach var in private_feeder private public_feeder {
    replace `var' = 0 if mi(`var')
}

cap file close f 
file open f using "$tables/lr_additional_hs_codes.tex", write replace

// Table Body
local N = _N
forv k =1/`N' {
    foreach var in name private_feeder private {
		file write f %-40s (`var'[`k']) "&"
	}
	file write f %-20s (public_feeder[`k']) "\\"_n
}

// file write f "\bottomrule"_n
// file write f "\end{tabular}"_n

cap file close f 

////////////////////////////////////////////////////
/// Table B.29: Additional Occupation identifiers ///
////////////////////////////////////////////////////

// Load long run occupation codes
import excel "$keys/lr_occupation_key.xlsx", clear first

keep *category* identifiers

// Only keep finance, doctor, law and hed relevant categories
keep if inlist(categorycode,1,2,4,6)
drop if categorycode==1 & !inlist(subcategorycode,1,2,11)
drop if categorycode==6 & !inlist(subcategorycode,1,9)

ren identifiers occ
split occ, p(,)
drop occ

reshape long occ, i(categorycode subcategorycode) j(id)
drop if mi(occ)
replace occ = trim(occ)
drop id
* Get rid of distinction in hed
replace subcategorycode = 1 if categorycode == 6
replace subcategory = "professor" if categorycode==6
replace category = "academics/research" if categorycode==6

sort categorycode subcategorycode occ
tempfile lr_occ
save `lr_occ', replace

// Load main build occupation codes
import excel "$keys/occupation_key.xlsx", clear first

keep *category* identifiers

// Only keep finance, doctor, law and hed relevant categories
keep if inlist(categorycode,1,2,4,6)
drop if categorycode==1 & !inlist(subcategorycode,1,2,11)
drop if categorycode==6 & !inlist(subcategorycode,1,9)

ren identifiers occ
split occ, p(,)
drop occ

reshape long occ, i(categorycode subcategorycode) j(id)
drop if mi(occ)
replace occ = trim(occ)
drop id

merge 1:1 occ using `lr_occ'

assert _merge > 1

* Only keep additional codes
keep if _merge == 2
drop _merge
foreach var in category subcategory occ {
    replace `var'= proper(`var')
}

replace subcategory = "Firms (ext. definition)" if categorycode==1 & subcategorycode==11

bys categorycode subcategorycode (occ): gen id = _n

replace occ = "HSBC" if occ == "Hsbc"
replace occ = "BNP Paribas" if occ=="Bnp Paribas"
replace occ = "BMO Capital Markets" if occ=="Bmo Capital Markets"
replace occ = "RBC Capital" if occ=="Rbc Capital"
replace occ = "UBS" if occ == "Ubs"

* Make Latex-ready
replace occ = subinstr(occ,"&","\&",.)
reshape wide occ, i(categorycode subcategorycode) j(id)

egen identifiers = concat(occ*), punct(", ")
replace identifiers = trim(regexs(1)) if regexm(identifiers,"(.+) *,$")
replace identifiers = trim(subinstr(identifiers,", ,", "",.))
replace identifiers = trim(regexs(1)) if regexm(identifiers,"(.+) *,$")

/// Write table

cap file close f 
file open f using "$tables/lr_additional_occ_codes.tex", write replace

sort categorycode subcategorycode

local N = _N
forv row = 1/`N' {
    file write f %-25s (category[`row']) "& " 
    file write f %-25s (subcategory[`row']) "& " 
    file write f %-540s (identifiers[`row']) "\\"_n 
}

cap file close f