/*

03_format_senior_clubs.do
(called from master_main.do)

Purpose: clean senior society and fraternity data
Inputs: codes/final_clubs_and_frats
Outputs: intstata/clubs_frats

*/

insheet using "${codes}/final_clubs_and_frats.csv", names comma clear

tab club_name // hasty pudding most common

tab source_year, m // through 27-28

tab class // 23-38. (entry year 20-35)

// keep observations matched to red books
count 
count if !mi(rb_index)
keep if !mi(rb_index)
duplicates report // no fully duplicated obs
duplicates drop

duplicates report rb_index club_name role // person-club-role identify observations

//
// identify records associated with hasty pudding and finals clubs: 
//

gen hasty_rec=code==19
gen final_club_rec=inlist(code,2,11,14,16,17,21,27,34,36,43) // any final club
gen final_tier2_rec=inlist(code,2,11,16,27,36,43) // any final club in top two selectivity tiers

tab club_name if hasty_rec==1, sort
tab club_name if final_club_rec==1,sort
tab club_name if final_tier2_rec==1,sort

//
// identify individuals who ever have hasty pudding or finals clubs:
//

foreach type in hasty final_club final_tier2 {
    egen `type'=max(`type'_rec), by(rb_index)    
}

//
// keep one observation per individual:
//

bys rb_index: keep if _n==1

// sort+save
ren rb_index index

// keep necessary data:
keep index hasty final_club final_tier2 

label var index "ID (from red books)"
label var hasty "Ever in Hasty Pudding"
label var final_club "Ever in final club"
label var final_tier2 "Ever in top two tier selective final club"

compress
save "${intstata}/clubs_frats", replace