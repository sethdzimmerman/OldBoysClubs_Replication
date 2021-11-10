/*

01_clean_roomprices.do
(called from master_main.do)

Purpose: construct room level datasets and peer neighborhood groups
Inputs: raw/Room_prices
Outputs: intstata/rooms_1919, intstata/rooms_1927, intstata/rooms_3241, 
	intstata/rooms_1930_all, intstata/rooms_3241_all, intstata/rooms_all, 
	intstata/rooms_update

*/

////////////////
// 1919 rooms //
////////////////

insheet using "$raw/Room_prices/1919/prices1919.csv" , clear

* make vars: roomcap = # students per bedroom type
* (here they are listed as #s, so redundant)
gen roomcap = bedrooms

cap tostring bedrooms , replace force

* price per student
/*
See "Assignment of Rooms in The Freshman Halls For 1919-20" page 156,
Official Register Of Harvard University. Vol XV. November 18, 1918. No. 44. 
Descriptive Catalogue.

"... In the following lists, the price in each case is for the whole room from
the beginning of the academic year until the next Commencement, and includes
heat, use of furniture, and the daily care of the room. The price is equally
divided between the tenants."
*/
gen price_per_student = round(price/roomcap,0.01)

** label variables 

label var dorm "Dorm name"
label var roomno "Room number (string)"
label var price "Room price"
label var bedrooms "Bedrooms description"
label var roomcap "Room capacity"
label var price_per_student "Price per student"

order price, before(price_per_student)

compress
save "$intstata/rooms_1919", replace

////////////////
// 1927 rooms //
////////////////

* iterate over files in directory
local files : dir "$raw/Room_prices/1927"  files "*1927.xlsx"

cd "$raw/Room_prices/1927"
foreach file in `files' {

	* don't open the "suties available" one
	if strpos("`file'","suites_available")==0 {

		import exc "`file'" , clear first

		* clean vars
		foreach var of varlist _all {
			cap tostring `var', replace force
			cap replace `var' = trim(`var')
		}

		destring floor , replace force
		destring price , replace force
		compress

		local savename = subinstr("`file'",".xlsx","",.)
		local fname_iter = "`fname_iter'" + " `savename'"

		tempfile `savename'
		save ``savename'' , replace
	}
}

// switch back to code directory
cd "$code"  

clear 
foreach f in `fname_iter' {
	append using ``f''
}

* room capacity
cap drop roomcap
gen roomcap = 0
replace roomcap = roomcap + 1 if strpos(bedrooms,"1 single")>0
replace roomcap = roomcap + 2 if strpos(bedrooms,"2 single")>0
replace roomcap = roomcap + 3 if strpos(bedrooms,"3 single")>0
replace roomcap = roomcap + 4 if strpos(bedrooms,"4 single")>0
replace roomcap = roomcap + 5 if strpos(bedrooms,"5 single")>0
replace roomcap = roomcap + 6 if strpos(bedrooms,"6 single")>0
replace roomcap = roomcap + 7 if strpos(bedrooms,"7 single")>0
replace roomcap = roomcap + 2 if strpos(bedrooms,"1 double")>0
replace roomcap = roomcap + 4 if strpos(bedrooms,"2 double")>0
replace roomcap = roomcap + 3 if strpos(bedrooms,"triple")>0

* price per student
gen price_per_student = round(price/roomcap,0.01)

* missing stairwell (data entry issue)
replace stairwell = substr(roomno,1,1) if mi(stairwell)
replace stairwell = "E" if stairwell=="e"

label var dorm "Dorm name"
label var roomno "Room number"
label var price "Room price"
label var bedrooms "Bedrooms description"
label var floor "Floor number"
label var stairwell "Stairwell"
label var suite "Suite"
label var roomcap "Room capacity"
label var price_per_student "Price per student"

order price, before(price_per_student)

compress
save "$intstata/rooms_1927", replace

//////////////////////
// prices 1932-1941 // 
//////////////////////

forv year = 1932/1941 {
	clear

	cd "$raw/Room_prices/`year'" 
	if `year' == 1932 local files : dir  "$raw/Room_prices/`year'"  files "*`year'.xlsx"
	if `year' > 1932 local files : dir  "$raw/Room_prices/`year'"  files "*`year'.csv"

	foreach file in `files' {
		quietly {
			preserve
				if `year' == 1932 import exc "`file'" , clear first
				if `year' > 1932 insheet using "`file'" , clear
				
				* fixes
				cap tostring roomno , replace force
				cap tostring suite , replace force
				
				replace roomno = trim(roomno)
				replace suite = trim(suite)
				replace stairwell = trim(stairwell)
				replace dorm = trim(dorm)
				
				if "`d'"=="Straus" | "`d'"=="Wigglesworth" | "`d'"=="Mower"  | "`d'"=="Lionel" /*
				*/ replace roomno=subinstr(roomno,"-"," ", .) 
				
				tempfile x
				save `x' , replace
			restore

			append using `x' 
		}
	}

	gen year = `year'

	qui compress
	qui tempfile r`year'
	qui save `r`year'' , replace
}

cd "$main" 

clear
forv year = 1932(1)1941 {
	di `year'
	append using `r`year''
}

replace dorm = "40 Quincy Street" if strpos(dorm,"Quincy St")>0
replace dorm = "40 Quincy Street" if strpos(dorm,"Walker House")>0

replace dorm = "Harvard Union" if dorm=="The Harvard Union"

drop if strpos(dorm,"The following suite")>0

replace bedrooms = lower(trim(bedrooms))
replace bedrooms = "1 triple" if bedrooms=="triple"
replace bedrooms = subinstr(bedrooms,"-"," ",.)

tab bedrooms

* handling "nones" & "study bedroom"
/*
upon investigation: here's what "none" means: these aren't *rooms*, recall,
but suites: a single may consist of a room with a nearest annex - the annex
is the bedroom. when bedrooms is listed as none, it always corresponds to a 
suite with a single *physical* room which is presumably always a single, 
unless noted (in the case of the harvard union, which distinguishes its
"none" types.

why assume unlisted "nones" are singles? because they appear in stoughton and
hollis, where the non-"none" bedrooms are singles, and those rooms are physically
entrywayr than the "none" rooms.

moreover, in 1935, these rooms are listed no longer as "none"
but instead as "study-bedrooms" 
*/

replace bedroom = "1 single" if bedroom=="none" | bedroom=="none (single)"
replace bedroom = "1 double" if bedroom=="none (double)"
replace bedroom = "1 single" if bedroom=="study bedroom" 
replace bedroom = "1 double" if bedroom=="double study bedroom"

drop if mi(dorm)

* room capacity
cap drop roomcap
gen roomcap = 0
replace roomcap = roomcap + 1 if strpos(bedrooms,"1 single")>0
replace roomcap = roomcap + 2 if strpos(bedrooms,"2 single")>0
replace roomcap = roomcap + 3 if strpos(bedrooms,"3 single")>0
replace roomcap = roomcap + 4 if strpos(bedrooms,"4 single")>0
replace roomcap = roomcap + 2 if strpos(bedrooms,"1 double")>0
replace roomcap = roomcap + 4 if strpos(bedrooms,"2 double")>0
replace roomcap = roomcap + 3 if strpos(bedrooms,"triple")>0

* price
ren price price_per_student 

* note: duplicates in grays '34-'37
/*
register indicates that rooms changed type based on demand: 

"the following suites may be assigned as doubles at the prices indicated:" 
- page 12, 1934 harvard register, "grays hall" section, e.g.
the section lists duplicates at different prices, for ex.:

suite 35-36 goes from a "1 single, 1 double" at $140 a head to 
a "1 double" at $180 a head.
*/

duplicates report dorm year roomno
duplicates report dorm year roomno roomcap

* fix stairwells/floors/suites (data entry errors)
replace stairwell = "S" if stairwell=="W" & dorm=="Stoughton"
replace stairwell = "N" if stairwell=="E" & dorm=="Stoughton"
replace floor = 4 if roomno=="18" & dorm=="Weld"
replace suite = "D-31" if suite=="D31" & dorm=="Wigglesworth" 

* make grays roomno data look like "1 2" for rooms "1-2"
replace suite = "37" if (roomno=="37" | roomno=="38") & dorm=="Grays" & year==1932
replace suite = "17" if (roomno=="17" | roomno=="18") & dorm=="Grays" & year==1932

replace stairwell = "M" if (roomno=="35" | roomno=="36") & dorm=="Grays"

gen j = roomno!=suite
bys dorm year suite : egen in_suite = max(j)
replace in_suite = 0 if dorm=="Wigglesworth" // a typo causes this

gen new_roomno = ""
bys dorm year suite (roomno) : replace new_roomno = suite + " " + roomno[_N] if in_suite==1

replace roomno = new_roomno if in_suite==1

replace roomno = "9 10" if roomno=="9 9" & dorm=="Grays"

drop j in_suite new_roomno

duplicates drop

* create "observed roomcap" variable for merging -- this is to take care
* of duplicate room price data in Grays
gen observed_roomcap = 0
duplicates tag dorm year roomno, gen(dup)
replace observed_roomcap = roomcap if dorm=="Grays"
drop dup

* clean roomno 
replace roomno = trim(roomno)
replace roomno = subinstr(roomno,"-"," ",.)

label var dorm "Dorm name"
label var roomno "Room number"
label var bedrooms "Bedrooms decription"
label var floor "Floor number"
label var stairwell "Stairwell"
label var suite "Suite"
label var roomcap "Room capacity"
label var price_per_student "Price per student"
label var year "Freshman year"
label var observed_roomcap "Room capacity (only used for merging)"

order year
order price_per_student, last

compress
save "$intstata/rooms_3241", replace

/////////////////////
// one big dataset //
/////////////////////

// '19 - '30 prices //
* note: McKinlock is added in 1927 & Shepherd in '23.

use "$intstata/rooms_1919" , clear

gen year = 1919
label var year "Freshman year"

append using "$intstata/rooms_1927" 

* variable fixes
replace year = 1927 if mi(year)
replace dorm = trim(proper(dorm))
replace roomno = trim(roomno)
replace bedrooms = trim(bedrooms)
replace stairwell = trim(stairwell)
replace suite = trim(suite)

* fill in floor & stairwell vars since they are not observed in 1919
tostring floor , replace
replace floor = "" if floor == "."
foreach var in floor stairwell suite {
	bys dorm roomno (`var') : replace `var' = `var'[_N] if mi(`var')
}
destring floor , replace

* create room id
egen double rid = group(dorm roomno)

* create temp dataset of room IDs and static features, multiply by N years
preserve
	keep rid dorm roomno suite floor stairwell
	duplicates drop
	expand 12
	bys rid : gen year = 1918+_n
	tempfile y 
	save `y' , replace
restore

* merge temp data onto full to have balanced panel of rooms*years
merge 1:1 rid year using `y' , nogen

** fill in missing prices when observed **
* first, filling missing roomcap
tostring roomcap , replace
replace roomcap = "" if roomcap == "."
bys dorm roomno (roomcap) : replace roomcap = roomcap[_N] if mi(roomcap)
destring roomcap , replace

* take median price for similar rooms
bys year dorm floor stairwell roomcap : egen mprice_per = median(price_per)
replace price_per = mprice_per if mi(price_per)
replace price = price_per*roomcap if mi(price)
drop mprice_per

* do same exercise for rooms that we *never* observe a roomcap
replace roomcap = . if roomcap==0
bys year dorm floor stairwell : egen mroomcap = mode(roomcap) , minmode 
replace roomcap = mroomcap if mi(roomcap)
bys year dorm floor stairwell roomcap : egen mprice_per = median(price_per)
replace price_per = mprice_per if mi(price_per)
replace price = price_per*roomcap if mi(price)
drop mprice_per mroomcap

replace bedrooms = string(roomcap) if mi(bedrooms)

* impute missing price and room type values based on nearest year in which data
* is available
foreach var in price price_per_student bedrooms roomcap {
	forv loop = 1/12 {
		* backwards
		bys rid (year) : replace `var' = `var'[_n-1] if ///
			mi(`var') & !mi(`var'[_n-1])
			
		* forwards
		bys rid (year) : replace `var' = `var'[_n+1] if ///
			mi(`var') & !mi(`var'[_n+1])
	}
}

duplicates report rid year

label var rid "Room ID"

order year rid
order price price_per_student, last
order roomcap, after(suit)
order dorm roomno, after(rid)

compress
save "$intstata/rooms_1930_all" , replace

// '32-'41 prices //

* open up '31-'41 prices
use "$intstata/rooms_3241" , clear

* keep only obs with non-missing room feature data
drop if mi(bedroom) | mi(price_per) | roomcap==0

* gen room id -- recall, "obs roomcap" is being treated
* as an immutable feature of a room -- it's whether the room is 
* treated as a room of type X or type Y within a year, which
* we can only see ex post, hence "observed" -- observed in red books data
egen double rid = group(dorm roomno observed_roomcap)

* create temp dataset of room IDs and static features, multiply by N years
preserve
	keep rid dorm roomno suite floor stairwell observed_roomcap
	duplicates drop
	expand 11
	bys rid : gen year = 1930+_n
	tempfile y 
	save `y' , replace
restore

* merge temp data onto full to have balanced panel of rooms*years
merge 1:1 rid year using `y' , nogen

* impute missing price and room type values based on nearest year in which data
* is available
foreach var in price_per_student bedrooms roomcap {
	forv loop = 1/11 {
		* backwards
		bys rid (year) : replace `var' = `var'[_n-1] if ///
			mi(`var') & !mi(`var'[_n-1])
			
		* forwards
		bys rid (year) : replace `var' = `var'[_n+1] if ///
			mi(`var') & !mi(`var'[_n+1])
	}
}

* fix observed roomcap var
duplicates tag dorm year roomno, gen(dup)
replace observed_roomcap = roomcap if dup>0 & dorm=="Grays"
drop dup

duplicates report rid year
duplicates report dorm year roomno obs
drop rid

compress
save "$intstata/rooms_3141_all" , replace

// append data sets together //

use "$intstata/rooms_1930_all" , clear

append using "$intstata/rooms_3141_all" 

replace observed_roomcap = 0 if mi(observed_roomcap)

replace dorm="McKinlock" if dorm=="Mckinlock"

drop rid

compress
save "$intstata/rooms_all" , replace

* refining proximity group definitions and calculating mean price of other rooms in prox groups
* modification, the suite 21A-D in Shepherd should be assigned to floor 1
replace floor=1 if  dorm=="Shepherd" & (roomno=="A 21" | roomno=="B 21" | roomno=="C 21" | roomno=="D 21")

* room IDs
egen double room_id = group(year dorm roomno) , missing
* dorm group: 
egen double dorm_id = group(year dorm) , missing
* dorm X floor group: 
egen double dorm_fl_id = group(year dorm floor) , missing
* dorm X stairwell group:
egen double dorm_sw_id = group(year dorm stairwell) , missing
* dorm X floor X stairwell group: 
egen double dorm_fl_sw_id = group(year dorm floor stairwell) , missing

* dorm x floor x stairwell
egen n_dorm_fl_sw = total(roomcap), by(dorm_fl_sw_id)
egen total_incl_dorm_fl_sw = total(roomcap*price_per_student), by(dorm_fl_sw_id)
generate mpi_dorm_fl_sw=total_incl_dorm_fl_sw/n_dorm_fl_sw
generate total_dorm_fl_sw=total_incl_dorm_fl_sw-(price_per_student) /*note: only subtracts student, not roommates*/ 
generate mp_dorm_fl_sw=total_dorm_fl_sw/(n_dorm_fl_sw-1)
replace mp_dorm_fl_sw=. if n_dorm_fl_sw==roomcap 

* dorm x stairwell
egen n_dorm_sw = total(roomcap), by(dorm_sw_id)
egen total_incl_dorm_sw = total(roomcap*price_per_student), by(dorm_sw_id)
generate mpi_dorm_sw=total_incl_dorm_sw/n_dorm_sw
generate total_dorm_sw=total_incl_dorm_sw-(price_per_student)
generate mp_dorm_sw=total_dorm_sw/(n_dorm_sw-1)
replace mp_dorm_sw=. if n_dorm_sw==roomcap 

* dorm x floor 
egen n_dorm_fl = total(roomcap), by(dorm_fl_id)
egen total_incl_dorm_fl = total(roomcap*price_per_student), by(dorm_fl_id)
generate mpi_dorm_fl=total_incl_dorm_fl/n_dorm_fl
generate total_dorm_fl=total_incl_dorm_fl-(price_per_student)
generate mp_dorm_fl=total_dorm_fl/(n_dorm_fl-1)
replace mp_dorm_fl=. if n_dorm_fl==roomcap 

* dorm  
egen n_dorm = total(roomcap), by(dorm_id)
egen total_incl_dorm = total(roomcap*price_per_student), by(dorm_id)
generate mpi_dorm=total_incl_dorm/n_dorm
generate total_dorm=total_incl_dorm-(price_per_student)
generate mp_dorm=total_incl_dorm/(n_dorm-1)
replace mp_dorm=. if n_dorm==roomcap 

* now, by dorm assign 'dorm' dorm group, 'entryway' dorm group, and 'nearest' dorm group
* 'dorm' proximity groups
gen dorm_nbd="no floor plan"

replace dorm_nbd="Dorm_fl_sw" if (dorm=="George Smith" | dorm=="James Smith" | dorm=="Persis Smith" | dorm=="Gore" | dorm=="Standish" | dorm=="McKinlock" | dorm=="Thayer" | dorm=="Matthews" | dorm=="Massachusetts" | dorm=="Weld")

replace dorm_nbd="Dorm_sw" if (dorm=="Straus" | dorm=="Hollis" | dorm=="Stoughton" | dorm=="Lionel" | dorm=="Mower" | dorm=="Mower" | dorm=="Holworthy" | dorm=="Wigglesworth" | dorm=="Grays")

replace dorm_nbd="Dorm_fl" if (dorm=="Shepherd" | dorm=="Apley Court" | dorm=="Russell" ) /* note: no prices for Russell yet */

replace dorm_nbd="Dorm" if (dorm=="Harvard Union")

* nearest proximity groups
gen nearest_nbd="no floor plan"
replace nearest_nbd="Dorm_fl_sw" if (dorm=="George Smith" | dorm=="James Smith" | dorm=="Persis Smith" | dorm=="Gore" | dorm=="Standish" | dorm=="McKinlock" | dorm=="Thayer" | dorm=="Matthews" | dorm=="Massachusetts" | dorm=="Weld"  | ///
dorm=="Straus" | dorm=="Hollis" | dorm=="Stoughton" | dorm=="Lionel" | dorm=="Mower" | dorm=="Mower" | dorm=="Holworthy" | dorm=="Wigglesworth" | dorm=="Grays" )

replace nearest_nbd="Dorm_fl" if (dorm=="Shepherd" | dorm=="Apley Court" | dorm=="Russell" ) /* note: no prices for Russell yet */

replace nearest_nbd="Dorm" if (dorm=="Harvard Union")

* entryway proximity groups 
gen entryway_nbd="no floor plan"
replace entryway_nbd="Dorm_sw" if (dorm=="George Smith" | dorm=="James Smith" | dorm=="Persis Smith" | dorm=="Gore" | dorm=="Standish" | dorm=="McKinlock" | dorm=="Thayer" | dorm=="Matthews" | dorm=="Massachusetts" | dorm=="Weld" | ///
dorm=="Straus" | dorm=="Hollis" | dorm=="Stoughton" | dorm=="Lionel" | dorm=="Mower" | dorm=="Mower" | dorm=="Holworthy" | dorm=="Wigglesworth" |  dorm=="Grays" )

replace entryway_nbd="Dorm" if (dorm=="Harvard Union" | dorm=="Shepherd" | dorm=="Apley Court" | dorm=="Russell") /* note: no prices for Russell yet */

* make dorm_nbd_id carefully!
generate temp_dorm_nbd_id=.
replace temp_dorm_nbd_id=dorm_fl_sw_id if dorm_nbd=="Dorm_fl_sw"
replace temp_dorm_nbd_id=dorm_fl_id if dorm_nbd=="Dorm_fl"
replace temp_dorm_nbd_id=dorm_sw_id if dorm_nbd=="Dorm_sw"
replace temp_dorm_nbd_id=dorm_id if dorm_nbd=="Dorm"

egen double dorm_nbd_id = group(dorm_nbd temp_dorm_nbd_id) , missing
drop temp_dorm_nbd_id

* now make prox_group n and mean variables

* number of other students in prox group (including roommates): n_nbd
generate n_dorm_nbd=.
replace n_dorm_nbd=n_dorm_fl_sw if dorm_nbd=="Dorm_fl_sw"
replace n_dorm_nbd=n_dorm_fl if dorm_nbd=="Dorm_fl"
replace n_dorm_nbd=n_dorm_sw if dorm_nbd=="Dorm_sw"
replace n_dorm_nbd=n_dorm if dorm_nbd=="Dorm"

* average price of other rooms in prox group (including roommates): mp_nbd
* n_dorm_fl_sw mp_dorm_fl_sw
generate mp_dorm_nbd=.
replace mp_dorm_nbd=mp_dorm_fl_sw if dorm_nbd=="Dorm_fl_sw"
replace mp_dorm_nbd=mp_dorm_fl if dorm_nbd=="Dorm_fl"
replace mp_dorm_nbd=mp_dorm_sw if dorm_nbd=="Dorm_sw"
replace mp_dorm_nbd=mp_dorm if dorm_nbd=="Dorm"

generate mpi_dorm_nbd=.
replace mpi_dorm_nbd=mpi_dorm_fl_sw if dorm_nbd=="Dorm_fl_sw"
replace mpi_dorm_nbd=mpi_dorm_fl if dorm_nbd=="Dorm_fl"
replace mpi_dorm_nbd=mpi_dorm_sw if dorm_nbd=="Dorm_sw"
replace mpi_dorm_nbd=mpi_dorm if dorm_nbd=="Dorm"

* make nearest_nbd_id carefully!
generate temp_nearest_nbd_id=.
replace temp_nearest_nbd_id=dorm_fl_sw_id if nearest_nbd=="Dorm_fl_sw"
replace temp_nearest_nbd_id=dorm_fl_id if nearest_nbd=="Dorm_fl"
replace temp_nearest_nbd_id=dorm_sw_id if nearest_nbd=="Dorm_sw"
replace temp_nearest_nbd_id=dorm_id if nearest_nbd=="Dorm"

egen double nearest_nbd_id = group(nearest_nbd temp_nearest_nbd_id) , missing
drop temp_nearest_nbd_id

* now make prox_group n and mean variables

* number of other students in prox group (including roommates): n_nbd
generate n_nearest_nbd=.
replace n_nearest_nbd=n_dorm_fl_sw if nearest_nbd=="Dorm_fl_sw"
replace n_nearest_nbd=n_dorm_fl if nearest_nbd=="Dorm_fl"
replace n_nearest_nbd=n_dorm_sw if nearest_nbd=="Dorm_sw"
replace n_nearest_nbd=n_dorm if nearest_nbd=="Dorm"

* average price of other rooms in prox group (including roommates): mp_nbd
* n_dorm_fl_sw mp_dorm_fl_sw
generate mp_nearest_nbd=.
replace mp_nearest_nbd=mp_dorm_fl_sw if nearest_nbd=="Dorm_fl_sw"
replace mp_nearest_nbd=mp_dorm_fl if nearest_nbd=="Dorm_fl"
replace mp_nearest_nbd=mp_dorm_sw if nearest_nbd=="Dorm_sw"
replace mp_nearest_nbd=mp_dorm if nearest_nbd=="Dorm"

generate mpi_nearest_nbd=.
replace mpi_nearest_nbd=mpi_dorm_fl_sw if nearest_nbd=="Dorm_fl_sw"
replace mpi_nearest_nbd=mpi_dorm_fl if nearest_nbd=="Dorm_fl"
replace mpi_nearest_nbd=mpi_dorm_sw if nearest_nbd=="Dorm_sw"
replace mpi_nearest_nbd=mpi_dorm if nearest_nbd=="Dorm"

* make entryway_nbd_id carefully!
generate temp_entryway_nbd_id=.
replace temp_entryway_nbd_id=dorm_fl_sw_id if entryway_nbd=="Dorm_fl_sw"
replace temp_entryway_nbd_id=dorm_fl_id if entryway_nbd=="Dorm_fl"
replace temp_entryway_nbd_id=dorm_sw_id if entryway_nbd=="Dorm_sw"
replace temp_entryway_nbd_id=dorm_id if entryway_nbd=="Dorm"

egen double entryway_nbd_id = group(entryway_nbd temp_entryway_nbd_id) , missing
drop temp_entryway_nbd_id

* now make prox_group n and mean variables

* number of other students in prox group (including roommates): n_nbd
generate n_entryway_nbd=.
replace n_entryway_nbd=n_dorm_fl_sw if entryway_nbd=="Dorm_fl_sw"
replace n_entryway_nbd=n_dorm_fl if entryway_nbd=="Dorm_fl"
replace n_entryway_nbd=n_dorm_sw if entryway_nbd=="Dorm_sw"
replace n_entryway_nbd=n_dorm if entryway_nbd=="Dorm"

* average price of other rooms in prox group (including roommates): mp_nbd
* n_dorm_fl_sw mp_dorm_fl_sw
generate mp_entryway_nbd=.
replace mp_entryway_nbd=mp_dorm_fl_sw if entryway_nbd=="Dorm_fl_sw"
replace mp_entryway_nbd=mp_dorm_fl if entryway_nbd=="Dorm_fl"
replace mp_entryway_nbd=mp_dorm_sw if entryway_nbd=="Dorm_sw"
replace mp_entryway_nbd=mp_dorm if entryway_nbd=="Dorm"

generate mpi_entryway_nbd=.
replace mpi_entryway_nbd=mpi_dorm_fl_sw if entryway_nbd=="Dorm_fl_sw"
replace mpi_entryway_nbd=mpi_dorm_fl if entryway_nbd=="Dorm_fl"
replace mpi_entryway_nbd=mpi_dorm_sw if entryway_nbd=="Dorm_sw"
replace mpi_entryway_nbd=mpi_dorm if entryway_nbd=="Dorm"

// drop variables not used in analysis
drop dorm_id - dorm_fl_sw_id
drop n_dorm_fl_sw - n_dorm
drop total_*
drop mpi_dorm mp_dorm

label var room_id "Room ID"
label var dorm_nbd "Peer group"
label var nearest_nbd "Nearest neighbors (nearest neighborhodd)"
label var entryway_nbd "Entryway (entryway neighborhood)"
label var dorm_nbd_id "Peer group ID"
label var n_dorm_nbd "Number of other students in peer group"
label var mp_dorm_nbd "Peer neighborhood price"
label var mpi_dorm_nbd "Peer neighborhood price (including self)"
label var nearest_nbd_id "Nearest peer group ID"
label var n_nearest_nbd "Number of other students in nearest peer group"
label var mp_nearest_nbd "Nearest peer neighborhood price"
label var mpi_nearest_nbd "Nearest peer neighborhood price (including self)"
label var entryway_nbd_id "Entryway peer group ID"
label var n_entryway_nbd "Number of other students in entryway peer group"
label var mp_entryway_nbd "Entryway peer neighborhood price"
label var mpi_entryway_nbd "Entryway peer neighborhood price (including self)"

order room_id, after(roomno)

save "$intstata/rooms_update" , replace

cd "$code"  
