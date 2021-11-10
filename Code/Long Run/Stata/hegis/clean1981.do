
* data and dictionary
local series = 2069
local dir = "$hegis_raw_data/ICPSR_0`series'/DS0001"
global icpst_dict "$hegis_raw_data/0`series'-0001-Setup.dct"
local data = "`dir'" + "/" + "0`series'-0001-Data.txt"
di "`data'"

local raw_data "`data'"
local dict "$icpst_dict"

infile using "`dict'", using ("`raw_data'") clear

isid FICE LINE

/*********************************************************

Section 3: Value Label Definitions
This section defines labels for the individual values of each variable.
We suggest that users do not modify this section.

**********************************************************/


label data "Higher Education General Information Survey (HEGIS) XVI: Fall Enrollment, 1981, Dataset 0001"

#delimit ;
cap label define OESTATE   10 "Alabama" 11 "Alaska" 12 "Arizona" 13 "Arkansas"
                       14 "California" 15 "Colorado" 16 "Connecticut"
                       17 "Delaware" 18 "Distr of Columbia" 19 "Florida"
                       20 "Georgia" 21 "Hawaii" 22 "Idaho" 23 "Illinois"
                       24 "Indiana" 25 "Iowa" 26 "Kansas" 27 "Kentucky"
                       28 "Louisiana" 29 "Maine" 30 "Maryland"
                       31 "Massachusetts" 32 "Michigan" 33 "Minnesota"
                       34 "Mississippi" 35 "Missouri" 36 "Montana"
                       37 "Nebraska" 38 "Nevada" 39 "New Hampshire"
                       40 "New Jersey" 41 "New Mexico" 42 "New York"
                       43 "North Carolina" 44 "North Dakota" 45 "Ohio"
                       46 "Oklahoma" 47 "Oregon" 48 "Pennsylvania"
                       49 "Rhode Island" 50 "South Carolina"
                       51 "South Dakota" 52 "Tennessee" 53 "Texas" 54 "Utah"
                       55 "Vermont" 56 "Virginia" 57 "Washington"
                       58 "West Virginia" 59 "Wisconsin" 60 "Wyoming"
                       61 "US Schls American Samoa" 62 "American Samoa"
                       63 "Former Canal Zone" 64 "Guam" 65 "Puerto Rico"
                       66 "Trust Terr Pac Is" 67 "Virgin Islands" ;
cap label define CITYSIZE  0 "Not Identified" 1 "Outside any SMA"
                       2 "Within SMA less the 250,000"
                       3 "Within SMA 250,000 to 499,999"
                       4 "Within SMA 500,000 to 999,999"
                       5 "SMA of 1,000,000 - 1,999,999 Outside Center City"
                       6 "SMA of 1,000,000 - 1,999,999 Within Center City"
                       7 "SMA/SCSA 2,000,000 or more Outside Center City"
                       8 "SMA/SCSA 2,000,000 or more Within Center City" ;
cap label define GEOGCODE  10 "Alabama" 11 "Alaska" 12 "Arizona" 13 "Arkansas"
                       14 "California" 15 "Colorado" 16 "Connecticut"
                       17 "Delaware" 18 "Distr of Columbia" 19 "Florida"
                       20 "Georgia" 21 "Hawaii" 22 "Idaho" 23 "Illinois"
                       24 "Indiana" 25 "Iowa" 26 "Kansas" 27 "Kentucky"
                       28 "Louisiana" 29 "Maine" 30 "Maryland"
                       31 "Massachusetts" 32 "Michigan" 33 "Minnesota"
                       34 "Mississippi" 35 "Missouri" 36 "Montana"
                       37 "Nebraska" 38 "Nevada" 39 "New Hampshire"
                       40 "New Jersey" 41 "New Mexico" 42 "New York"
                       43 "North Carolina" 44 "North Dakota" 45 "Ohio"
                       46 "Oklahoma" 47 "Oregon" 48 "Pennsylvania"
                       49 "Rhode Island" 50 "South Carolina"
                       51 "South Dakota" 52 "Tennessee" 53 "Texas" 54 "Utah"
                       55 "Vermont" 56 "Virginia" 57 "Washington"
                       58 "West Virginia" 59 "Wisconsin" 60 "Wyoming"
                       61 "US Schls American Samoa" 62 "American Samoa"
                       63 "Former Canal Zone" 64 "Guam" 65 "Puerto Rico"
                       66 "Trust Terr Pac Is" 67 "Virgin Islands" ;
cap label define OEREGCOD  1 "North Atlantic" 2 "Great Lakes & Plains"
                       3 "Southeast" 4 "West & Southwest"
                       5 "US service schools" 6 "Not in use"
                       7 "Outlying Areas" ;
cap label define OBEREGCO  0 "US service schools" 1 "New England" 2 "Mideast"
                       3 "Great Lakes" 4 "Plains" 5 "Southeast" 6 "Southwest"
                       7 "Rocky Mountains" 8 "Far West" 9 "Outlying Areas" ;
cap label define CONTCODE  0 "Combination Public & Private" 1 "Public only"
                       2 "Private only" ;
cap label define SEXCODE   1 "Male" 2 "Female" 3 "Coeducational" 4 "Coordinate" ;
cap label define LANDGRAN  0 "No-land Grant Institution"
                       1 "Land Grant Institution" 2 "Member of NASULGC" ;
cap label define OFFERLEV  2 "Less than 1 Year" 3 "1 but less than 4 Yrs"
                       4 "4 or 5 Yr Baccalaureate"
                       5 "First-Professional Degree" 6 "Master's"
                       7 "Beyond Master's but less than Doctorate"
                       8 "Doctorate" 9 "Undergrad Non-degree Granting"
                       10 "Graduate Non-degree Granting"
                       11 "Postdoctoral Research only" ;
cap label define CALENSYS  1 "Semester" 2 "Quarter" 3 "Trimester" 4 "4/1/4"
                       5 "Other" ;
cap label define EXCNTL    0 "Not specified" 1 "Publicly controlled"
                       2 "Privately controlled" 3 "Religious affiliation" ;
cap label define AFFILI    11 "Federal" 12 "State" 13 "Local" 14 "State/ Local"
                       15 "State Related" 21 "Independent Non-Profit"
                       22 "American Evangelical Lutheran Church"
                       23 "American Missionary Association"
                       24 "African Methodist Episcopal Zion Church"
                       25 "Organized as Profit Making"
                       26 "Advent Christian Church"
                       27 "Assemblies of God Church" 28 "Brethren Church"
                       29 "Brethren in Christ Church" 30 "Roman Catholic"
                       31 "Church of God in Christ"
                       32 "Church of New Jerusalem"
                       33 "Wisconsin Evangelical Lutheran Synod"
                       34 "Christian and Missionary Alliance Church"
                       35 "Christian Reformed Church"
                       36 "Evangelical Congregational Church"
                       37 "Evangelical Covenant Church of America"
                       38 "Evangelical Free Church of America"
                       39 "Evangelical Lutheran Church"
                       41 "Free Will Baptist Church" 42 "Interdenominational"
                       43 "Mennonite Brethren Church" 44 "Moravian Church"
                       45 "North American Baptist"
                       46 "American Lutheran and Lutheran Church in America"
                       47 "Pentecostal Holiness Church"
                       48 "Christian Churches and Churches of Christ"
                       49 "Reformed Church in America"
                       50 "Reformed Episcopal Church"
                       51 "African Methodist Episcopal" 52 "American Baptist"
                       53 "American Lutheran" 54 "Baptist"
                       55 "Christian Methodist Episcopal"
                       56 "Church of Christ (Scientist)" 57 "Church of God"
                       58 "Church of the Brethren"
                       59 "Church of the Nazarene"
                       60 "Cumberland Presbyterian"
                       61 "Christian Church (Disciples of Christ)"
                       63 "Friends United Meeting" 64 "Free Methodist"
                       65 "Friends" 66 "Presbyterian Church (USA)"
                       67 "Lutheran Church in America"
                       68 "Lutheran Church - Missouri Synod"
                       69 "Mennonite Church"
                       70 "General Conference Mennonite Church"
                       71 "United Methodist" 72 "Presbyterian, U.S."
                       73 "Protestant Episcopal" 74 "Churches of Christ"
                       75 "Southern Baptist" 76 "United Church of Christ"
                       77 "United Presbyterian, USA"
                       78 "Multiple Protestant Denominations"
                       79 "Other Protestant" 80 "Jewish"
                       81 "Reformed Presbyterian Church"
                       82 "Reorganized Latter-Day Saints Church"
                       83 "Seventh Day Baptist Church"
                       84 "United Brethren Church" 87 "Missionary Church INC"
                       88 "Undenominational" 89 "Wesleyan Church"
                       90 "Young Men's Christian Association"
                       91 "Greek Orthodox" 92 "Russian Orthodox"
                       93 "Unitarian Universalist" 94 "Latter-Day Saints"
                       95 "Seventh-Day Adventists"
                       96 "Church of God of Prophecy"
                       97 "The Presbyterian Church in America" 99 "Other" ;
cap label define RANGECOD  0 "00000-00000" 1 "00001-00199" 2 "00200-00499"
                       3 "00500-00999" 4 "01000-02499" 5 "02500-04999"
                       6 "05000-09999" 7 "10000-19999" 8 "20000 and over" ;
cap label define RESTRIC   0 "Not Restricted" 1 "Restricted" ;
cap label define IMPUTCOD  0 "Neither Imputed nor Adjusted data" 1 "Imputed data"
                       3 "Adjusted data" 5 "Both Imputed & Adusted data" ;
cap label define SUBCODE   0 "Reported Data"
                       1 "Totals were generated by computer" ;
cap label define MAJFLDCO  100 "Agriculture and Natural Resources"
                       200 "Architecture and Environmental Design"
                       400 "Biological Sciences"
                       500 "Business and Management" 900 "Engineering"
                       1204 "Dentistry" 1206 "Medicine"
                       1218 "Veterinary Medicine" 1400 "Law"
                       1900 "Physical Sciences" 9000 "All Other"
                       9999 "Summary" ;


#delimit cr



* var renames for consistency with pre '81 work

gen year = 1981

ren TOTMNREP enrollfullmen 
ren TOTWNREP enrollfullwomen

ren LINE LINECOD

* want total undergrad
keep if LINECOD==1 | LINECOD==2 

gen j = "_firsttime" if LINECOD==2
replace j = "_total" if LINECOD==1

drop LINECOD IMPUTCOD 

gen enrollfull = enrollfullmen + enrollfullwomen

drop TOT* MODLINE NRES* BLK* AIA* ASN* HIS* WHTN* IMPUTCID CYUPDATE
reshape wide enroll* , i(FICE) j(j) string

ren SEXCODE institution_sex

qui compress
save "$hegis_in_data/hegis1981.dta" , replace








