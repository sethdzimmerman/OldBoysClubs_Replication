/*

04d_clean_clubs.do
(called from 04_clean_redbooks.do)

Purpose: cleans and codes college clubs
Inputs: keys/club_key, codes/club_codes
Outputs: N/A

*/

* ingest club key
preserve 

		import exc "$keys/club_key.xlsx" , clear first
		
		keep code member_of 
		
		tempfile ck
		save `ck' , replace
		
		insheet using "$codes/club_codes.csv" , clear
		ren social social_club // so as not to confuse w/ red book "social" definition
		
		merge m:1 code using `ck' , nogen keep(1 3)
				
		ren member_of clubname
		ren code clubcode
		
		bys pid (clubcode) : gen j = _n 
		
		keep clubcode clubname social_club honorary_or_political ///
			gent_club country_club frat_order /// 
			pid j 
			
		reshape wide clubcode clubname social_club honorary_or_political ///
			gent_club country_club frat_order, i(pid) j(j)
		
		tempfile formerge
		save `formerge'
		
restore

merge m:1 pid using `formerge' , nogen keep(1 3) ///
	keepusing(club* social_club* honorary* gent_club* ///
		country_club* frat_order*)

// indicators by type:  
foreach var in gent_club country_club frat_order {
	egen n_`var'=rowtotal(`var'? `var'??)
	gen have_`var'=n_`var'>0 if !mi(pid)
	drop n_`var'
}

egen n_social_club=rowtotal(social_club?) 
egen n_hon_club=rowtotal(honorary_or_political?)
gen have_club=!mi(clubname1)
forv j=1/20{
	gen have_club`j'=!mi(clubcode`j')
}
egen n_club=rowtotal(have_club?)
gen n_prof_assoc=n_club-n_social_club-n_hon_club
drop n_club have_club*


foreach var in social_club hon_club prof_assoc {
	gen have_`var'=n_`var'>0 if !mi(n_`var') 
	drop n_`var'
}

// any adult social organization
gen any_social_main=max(have_country_club, have_frat_order, have_gent_club) 

// belong to some honor or professional society
gen any_honor=max(have_hon_club, have_prof_assoc)