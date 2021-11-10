/*

04h_rooms.do
(called from 04_clean_redbooks.do)

Purpose: update rooms data using occupancy data from Red Books
Inputs: intstata/rooms_update, instata/redbooks_clean_norooms
Outputs: intstata/rooms_all_grays_fixed

*/

use "$intstata/rooms_update" , clear

* just want to id which rooms are occupied so only keeping room id variables 
merge 1:m year dorm roomno observed_roomcap using "$intstata/redbooks_clean_norooms" , gen(_mroom) keepusing(year dorm roomno observed_roomcap)/* changed from keep(1 3)*/
* indicator for if the room is occupied in each year
gen ind=1
replace ind=0 if _mroom==1

* the room_all data has more years than we have redbooks for 
* I drop all years for which we do not have redbook records because we 
drop if year>1935

* I sort by id and then roomcap to help double checking
sort dorm year roomno ind roomcap
quietly by dorm year roomno:  gen dup = cond(_N==1,0,_n)
* I am going to 'hard code'
quietly by dorm year roomno:  egen keepif = mean(observed_roomcap) if ind==1
quietly by dorm year roomno:  egen nm_keepif = mean(keepif) 
* this gives me a rule for all but 6 grays year roomno combos; which are all from 1931
* perhaps as first year on the yard Grays was only partially full that year?
* more commonly used as triple: "11 12" "19 20" "23 24"  "3 4" "7 8"
* more commonly used as double: "27 28"
replace nm_keepif=3 if dorm=="Grays" & year==1931 & (roomno=="11 12" | roomno=="19 20" | roomno=="23 24" | roomno=="3 4" | roomno=="7 8")
replace  nm_keepif=2 if dorm=="Grays" & year==1931 & roomno=="27 28"
drop if dorm=="Grays" & nm_keepif!= observed_roomcap
drop observed_roomcap

* just keep the rooms_update variables and observations
keep if _mroom!=2
drop keepif nm_keepif _mroom ind dup

sort dorm year roomno roomcap
quietly by dorm year roomno:  gen dup = cond(_N==1,0,_n)
keep if dup<2 
tab dup, m
drop dup

// generate share of high vs. low rent rooms, weighting by room capacity: 
gen roomid=_n 
expand roomcap // because I already dealt with Grays, it is correct to use roomcap here

egen topcut=pctile(price_per), by(year) p(50)
egen elitecut=pctile(price_per), by(year) p(90)

gen toproom=price_per>=topcut if !mi(price_per)
gen eliteroom=price_per>=elitecut if !mi(price_per)

egen topshare=mean(toproom), by(year dorm_nbd_id)
egen eliteaccess=mean(eliteroom), by(year dorm_nbd_id)

drop topcut elitecut toproom eliteroom 

*quantiles of own room: 
local q=20
gen pq=. 
levelsof year, local(levels)
foreach l of local levels {
   xtile j=price_per if year==`l', nq(`q')
   replace pq=j if year==`l'
   drop j
}
replace pq=pq/`q'

*rank of nbd price: 
*compute rank for each price. assign rooms to midpoint rank for that price.
* do this for each group type (large (entryway), small (nearest), best (dorm); (best is the preferred definition)
   
foreach type in entryway nearest dorm {
   
   preserve
   keep year mp_`type'_nbd mpi_`type'_nbd dorm roomno year roomid  mpi_dorm_nbd
   drop if mi(mp_`type'_nbd)

   bys year (mp_`type'_nbd): gen jrrank=_n/_N
   egen nbdrank_`type'=median(jrrank), by(year mp_`type'_nbd) 
   drop jrrank

   bys year (mpi_`type'_nbd): gen jrrank=_n/_N
   egen nbdranki_`type'=median(jrrank), by(year mpi_`type'_nbd) 
   drop jrrank

   // now want to contruct 'psuedo-rank' for large and small prox groups
   // this rank is the rank of the room's (large or small) neighborhood price relative to all the other rooms' best neighborhood price 
   if ( "`type'"=="entryway" | "`type'"=="nearest" ) {

      gen psuedo_nbdranki_`type'=.
         
         //gen psuedo_nbdranki_entryway=. // for troubleshooting
         local N = _N
         gen index=_n  // we sort during this process, so need hard index
         forv i=1/`N' {
            
            gen temp_mpi=mpi_dorm_nbd
            replace temp_mpi=mpi_`type'_nbd if index==`i'
            //replace temp_mpi=mpi_entryway_nbd if index==`i' // for trouble shooting

            bys year (temp_mpi): gen jrrank=_n/_N
            egen temp_nbdranki=median(jrrank), by(year temp_mpi) 
            replace psuedo_nbdranki_`type'=temp_nbdranki if index==`i'
            //replace psuedo_nbdranki_entryway=temp_nbdranki if index==`i' // for trouble shooting
            //gen temp_mpi`i'=temp_mpi // for trouble shooting
            //gen temp_nbdranki`i'=temp_nbdranki // for trouble shooting
            drop jrrank temp_mpi temp_nbdranki
         }
   }

   bys roomid: keep if _n==1

   di "B"
   if "`type'"=="entryway" {
      tempfile slarge
      save `slarge' 
   }

   if "`type'"=="nearest" {
      tempfile ssmall
      save `ssmall' 
   }

if "`type'"=="dorm" {
   tempfile sbest
	save `sbest' 
}
di "C"

restore
}

merge m:1 dorm roomno year  using `sbest', keepusing(nbdrank_dorm nbdranki_dorm) gen(_m1)
ren nbdrank_dorm nbdrank
ren nbdranki_dorm nbdranki
count if _m1==2 
assert `r(N)'==0

merge m:1 dorm roomno year  using `slarge', keepusing(nbdrank_entryway nbdranki_entryway psuedo_nbdranki_entryway) gen(_m2)
count if _m2==2 
assert `r(N)'==0

merge m:1 dorm roomno year  using `ssmall', keepusing(nbdrank_nearest nbdranki_nearest psuedo_nbdranki_nearest) gen(_m3)
count if _m3==2 
assert `r(N)'==0

drop _m1 _m2 _m3

bys roomid: keep if _n==1
drop roomid

drop mpi_nearest_nbd mp_nearest_nbd mp_entryway_nbd nbdrank_nearest nbdranki_nearest nbdrank_entryway nbdranki_entryway

//label variables
label var topshare "Share of students in best proximity group in top half of room price per student"
label var eliteaccess "Share of students in best proximity group in top tenth of room price per student"
label var pq "Percentile of room price per year"
label var nbdrank "Peer neighborhood rank (excluding self)"
label var nbdranki "Peer neighborhood rank" 
label var psuedo_nbdranki_entryway "Peer large neighborhood rank relative to all other rooms' best neighborhood price'"
label var psuedo_nbdranki_nearest "Peer small neighborhood rank relative to all other rooms' best neighborhood price'"

save "$intstata/rooms_all_grays_fixed" , replace
/* /// I want to keep all the variables (including floor, roomcap, etc.) not just the features of dorm_nbd
keep dorm roomno year dorm_nbd n_dorm_nbd mp_dorm_nbd ///
	dorm_nbd_id topshare botshare eliteaccess toproom botroom eliteroom nbdpq pq n_dorm_nbd nbdrank */
tempfile rooms
save `rooms'

use "$intstata/redbooks_clean_norooms" , clear 

// identify people who live off campus or who have missing dorm info
gen offcampus=dorm=="Off Campus"
gen midorm=mi(dorm) 

su offcampus midorm
gen have_campus_address=midorm==0 
gen oncampus=1-offcampus

// merge on better peer group definitions: 

merge m:1 dorm roomno year using `rooms', gen(_mr) keep(match master)
label var _mr "Merge wih rooms data"

// what share of rooms do we have attributes for? 
tab _mr if offcampus==0 & midorm==0
gen roomatts=_mr==3
drop _mr

drop offcampus midorm

// identify private feeders: 
gen have_hs_rec=!mi(high_school)
gen pf_wm=private_feeder==1

// people with home addresses: 
gen have_home_address=!mi(home_address)

// fix state codes: (note: this should be done earlier in code)
// key fix is that US addresses w/ missing states are implied to be MA/boston area
// but current approach also includes foreign addresses, which is bad
replace from_NY=0 if mi(from_NY) & have_home_address==1
replace from_MA=1 if mi(from_MA) & have_home_address==1

drop have_home_address observed_roomcap