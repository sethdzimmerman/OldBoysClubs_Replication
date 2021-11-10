// 1974 //

* use '73 dictionary for '74
local dir = "$hegis_raw_data/ICPSR_02061/DS0001"
global icpst_dict "`dir'/02061-0001-Setup.dct"

* '74 data
local dir = "$hegis_raw_data/ICPSR_02062/DS0001"
local data = "`dir'" + "/" + "02062-0001-Data.txt"
di "`data'"

// below copied from setup file //

local raw_data "`data'"
local dict "$icpst_dict"

infile using "`dict'", using ("`raw_data'") clear


cap label data "Higher Education General Information Survey (HEGIS) VIII: Opening Fall Enrollment in Higher Education, 1974, Dataset 0001"

#delimit ;
cap label define OESTATE   10 "Alabama" 11 "Alaska" 12 "Arizona" 13 "Arkansas"
                       14 "California" 15 "Colorado" 16 "Connecticut"
                       17 "Delaware" 18 "Distr of Colombia" 19 "Florida"
                       20 "Georgia" 21 "Hawaii" 22 "Idaho" 23 "Illionois"
                       24 "Indiana" 25 "Iowa" 26 "Kansas" 27 "Kentucky"
                       28 "Louisiana" 29 "Maine" 30 "Maryland"
                       31 "Massachusetts" 32 "Michigan" 33 "Minnesota"
                       34 "Mississippi" 35 "Missouri" 36 "Motana"
                       37 "Nebraska" 38 "Nevada" 39 "New Hampshire"
                       40 "New Jersey" 41 "New Mexico" 42 "New York"
                       43 "North Carolina" 44 "North Dakota" 45 "Ohio"
                       46 "Oklahoma" 47 "Oregon" 48 "Pennsylvania"
                       49 "Rhode Island" 50 "South Carolina"
                       51 "South Dakota" 52 "Tennessee" 53 "Texas" 54 "Utah"
                       55 "Vermont" 56 "Virginia" 57 "Washington"
                       58 "West Virginia" 59 "Wisconsin" 60 "Wyoming"
                       61 "US Schls American Samoa" 62 "American Samoa"
                       63 "Former Canal Zone" 64 "Guam" 65 "Peurto Rico"
                       66 "Trust Terr Pac Is" 67 "Virgin Islands" ;
cap label define GEOGCODE  10 "Alabama" 11 "Alaska" 12 "Arizona" 13 "Arkansas"
                       14 "California" 15 "Colorado" 16 "Connecticut"
                       17 "Delaware" 18 "Distr of Colombia" 19 "Florida"
                       20 "Georgia" 21 "Hawaii" 22 "Idaho" 23 "Illionois"
                       24 "Indiana" 25 "Iowa" 26 "Kansas" 27 "Kentucky"
                       28 "Louisiana" 29 "Maine" 30 "Maryland"
                       31 "Massachusetts" 32 "Michigan" 33 "Minnesota"
                       34 "Mississippi" 35 "Missouri" 36 "Motana"
                       37 "Nebraska" 38 "Nevada" 39 "New Hampshire"
                       40 "New Jersey" 41 "New Mexico" 42 "New York"
                       43 "North Carolina" 44 "North Dakota" 45 "Ohio"
                       46 "Oklahoma" 47 "Oregon" 48 "Pennsylvania"
                       49 "Rhode Island" 50 "South Carolina"
                       51 "South Dakota" 52 "Tennessee" 53 "Texas" 54 "Utah"
                       55 "Vermont" 56 "Virginia" 57 "Washington"
                       58 "West Virginia" 59 "Wisconsin" 60 "Wyoming"
                       61 "US Schls American Samoa" 62 "American Samoa"
                       63 "Former Canal Zone" 64 "Guam" 65 "Peurto Rico"
                       66 "Trust Terr Pac Is" 67 "Virgin Islands" ;
cap label define OEREGCOD  1 "North Atlantic" 2 "Great Lakes & Plains"
                       3 "Southeast" 4 "West & Southwest"
                       5 "US service schools" 6 "Not in use"
                       7 "Outlying Areas" ;
cap label define OBEREGCO  0 "US service schools" 1 "New England" 2 "Mideast"
                       3 "Great Lakes" 4 "Plains" 5 "Southeast" 6 "Southwest"
                       7 "Rocky Mountains" 8 "Far West" 9 "Outlying Areas" ;
cap label define RACECODE  1 "White" 2 "Black" ;
cap label define CONTCODE  0 "Combin public & Priv" 1 "Public only"
                       2 "Private only" ;
cap label define SEXCODE   1 "Male" 2 "Female" 3 "Coeducational" 4 "Coordinate" ;
cap label define LANDGRAN  0 "No-land Grant Institution"
                       1 "Land Grant Institution" 2 "Member of NASULGC" ;
cap label define ACCREDIT  0 "None" 1 "Yes" ;
cap label define OFFERLEV  2 "Less than 1 Year" 3 "2 but less than 4 Yrs"
                       4 "4 or 5 Yr Baccalaureat"
                       5 "First Professional Degree" 6 "Masters"
                       7 "Beyond Masters less Doctor" 8 "Doctorate"
                       9 "Undergrad non-degree Granting"
                       10 "Graduate non-degree Granting"
                       11 "Post Doctoral Research only" ;
cap label define CALENSYS  1 "Semester" 2 "Quarter" 3 "Trimester" 4 "4/1/4"
                       5 "Other" ;
cap label define RECLASS   0 "None" ;
cap label define RANGECOD  0 "00000-00000" 1 "00001-00199" 2 "00200-00499"
                       3 "00500-00999" 4 "01000-02499" 5 "02600-04999"
                       6 "06000-09999" 7 "10000-19909" 8 "20000-and over" ;
cap label define RESTRIC   0 "Not Restricted" 1 "Restricted" ;
cap label define IMPUTCOD  0 "Unimputed" 1 "Imputed data" 3 "Adjusted data"
                       5 "Both imputed & Adusted data" ;
cap label define PARTID    1 "PART A" 2 "PART B" ;

#delimit cr


isid FICE LINECOD COMPUTID

bys FICE LINECOD (COMPUTID) : keep if _n == _N // keep update records
drop ENTRY UPDATE COMPUTID

isid FICE LINECOD

drop PARTID

gen year = 1974

* clean var names

ren SEX institution_sex

ren PARTAB1 enrollfullmen
ren PARTAB2 enrollpartmen
ren PARTAB3 enrollfullwomen
ren PARTAB4 enrollpartwomen
ren PARTAB5 enroll_rowtotal
drop enroll_rowtotal
drop PARTAB6 PARTOT PARTFUL SURVEYIN

gen enrollfull = enrollfullmen + enrollfullwomen
gen enrollpart = enrollpartmen + enrollpartwomen

// enrollment definition //
/*

Line No - 

1 - bachelor's
2 - non BA
3 - lower division undergraduates in BA
4 - lower division undegrads not in BA
5 -  upper division undergrads
6 - 3+4+5
7 - unclassified
8 - first-professional students
9 - graduate students
10 - grand total

*/

* want total undergrad
keep if LINECOD==1 | LINECOD==3 | LINECOD==5 // just BA

gen j = "_firsttime" if LINECOD==1
replace j = "_total1" if LINECOD==3
replace j = "_total2" if LINECOD==5

drop LINECOD IMPUTCOD

reshape wide enrollfull* enrollpart* , i(FICE) j(j) string

foreach ii in men women {
foreach jj in full part {
gen enroll`jj'`ii'_total = enroll`jj'`ii'_total1+enroll`jj'`ii'_total2
}
}
gen enrollfull_total = enrollfull_total1 + enrollfull_total2
gen enrollpart_total = enrollpart_total1 + enrollpart_total2
drop enroll*_total1 enroll*_total2

qui compress
save "$hegis_in_data/hegis1974.dta" , replace
