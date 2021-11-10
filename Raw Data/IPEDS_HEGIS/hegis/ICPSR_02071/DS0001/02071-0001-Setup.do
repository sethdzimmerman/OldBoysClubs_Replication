/**************************************************************************
 |                    STATA SETUP FILE FOR ICPSR 02071
 |        HIGHER EDUCATION GENERAL INFORMATION SURVEY (HEGIS) XX:
 |       FALL ENROLLMENT IN INSTITUTIONS OF HIGHER EDUCATION, 1985
 |
 |                                                                        
 |  Please edit this file as instructed below.                            
 |  To execute, start Stata, change to the directory containing:          
 |       - this do file                                                   
 |       - the ASCII data file                                            
 |       - the dictionary file                                            
 |                                                                        
 |  Then execute the do file (e.g., do 02071-0001-statasetup.do)          
 |                                                                        
 **************************************************************************/

set mem 20m  /* Allocating 20 megabyte(s) of RAM for Stata SE to read the
                 data file into memory. */

set more off  /* This prevents the Stata output viewer from pausing the
                 process*/

/****************************************************

Section 1: File Specifications
   This section assigns local macros to the necessary files.
   Please edit:
        "data-filename" ==> The name of data file downloaded from ICPSR
        "dictionary-filename" ==> The name of the dictionary file downloaded.
        "stata-datafile" ==> The name you wish to call your Stata data file.

   Note:  We assume that the raw data, dictionary, and setup (this do file) all
          reside in the same directory (or folder).  If that is not the case
          you will need to include paths as well as filenames in the macros.

********************************************************/

local raw_data "data-filename"
local dict "dictionary-filename"
local outfile "stata-datafile"

/********************************************************

Section 2: Infile Command

This section reads the raw data into Stata format.  If Section 1 was defined
properly, there should be no reason to modify this section.  These macros
should inflate automatically.

**********************************************************/

infile using `dict', using (`raw_data') clear










/*********************************************************

Section 3: Value Label Definitions
This section defines labels for the individual values of each variable.
We suggest that users do not modify this section.

**********************************************************/


label data "Higher Education General Information Survey (HEGIS) XX: Fall Enrollment in Institutions of Higher Education, 1985, Dataset 0001"

#delimit ;
label define PUBST85   10 "Alabama" 11 "Alaska" 12 "Arizona" 13 "Arkansas"
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
                       64 "Guam" 65 "Northern Marianas" 66 "Peurto Rico"
                       67 "Trust Terr Pac Is" 68 "Virgin Islands" ;
label define AFFIL85   11 "Federal" 12 "State" 13 "Local" 14 "State/Local"
                       15 "State related" 21 "Independent non-profit"
                       22 "American Evangelical Lutheran Church"
                       23 "American Missionary Association"
                       24 "African Methodist Episcopal Zion"
                       25 "Organized as profit making"
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
                       40 "Evangelical and Reformed Church"
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
                       62 "Evangelical United Brethren"
                       63 "Friends United Meeting" 64 "Free Methodis"
                       65 "Friends" 66 "Presbyterian Church (USA)"
                       67 "Lutheran Church in America"
                       68 "Lutheran Church - Missouri Synod"
                       69 "Mennonite Church"
                       70 "General Conference Mennonite Church"
                       71 "United Methodist" 72 "Presbyterian, U.S."
                       73 "Protestant Episcopal" 74 "Churches of Christ"
                       75 "Southern Baptist" 76 "United Church of Christ"
                       78 "Multiple Protestant Denominations"
                       79 "Other Protestant" 80 "Jewish"
                       81 "Reformed Presbyterian Church"
                       82 "Reorganized Latter-day Saints Church"
                       83 "Seventh-day Baptist Church"
                       84 "United Brethren Church"
                       85 "United Christian Missionary Society"
                       86 "United Lutheran Church" 87 "Missionary Church Inc"
                       88 "Undenominational" 89 "Wesleyan Church"
                       90 "Young Men's Christian Association"
                       91 "Greek Orthodox" 92 "Russian Orthodox"
                       93 "Unitarian Universalist" 94 "Latter-day Saints"
                       95 "Seventh-day Adventists"
                       96 "Church of God of Prophecy"
                       97 "The Presbyterian Church in America" 99 "Other" ;
label define CALSYS85  1 "Semester" 2 "Quarter" 3 "Trimester" 4 "4/1/4"
                       5 "Other" ;
label define HLVL85    2 "Less than 1 Year" 3 "2 but less than 4 Yrs"
                       4 "4 or 5 Yr Baccalaureat"
                       5 "First Professional Degree" 6 "Masters"
                       7 "Beyond Masters less Doctor" 8 "Doctorate"
                       9 "Undergrad non-degree Granting"
                       10 "Graduate non-degree Granting"
                       11 "Post Doctoral Research only" ;
label define PROCC85   0 "No" 1 "Yes" ;
label define PR2YR85   0 "No" 1 "Yes" ;
label define PRLIB85   0 "No" 1 "Yes" ;
label define PRTEA85   0 "No" 1 "Yes" ;
label define PRPROF85  0 "No" 1 "Yes" ;
label define GEOST85   10 "Alabama" 11 "Alaska" 12 "Arizona" 13 "Arkansas"
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
                       64 "Guam" 65 "Northern Marianas" 66 "Peurto Rico"
                       67 "Trust Terr Pac Is" 68 "Virgin Islands" ;
label define OEREG85   1 "North Atlantic" 2 "Great Lakes & Plains"
                       3 "Southeast" 4 "West & Southwest"
                       5 "US service schools" 6 "Not in use"
                       7 "Outlying Areas" ;
label define OBEREG85  0 "US service schools" 1 "New England" 2 "Mideast"
                       3 "Great Lakes" 4 "Plains" 5 "Southeast" 6 "Southwest"
                       7 "Rocky Mountains" 8 "Far West" 9 "Outlying Areas" ;
label define CNTL85    0 "Combin public & Priv" 1 "Public only"
                       2 "Private only" ;
label define TYPE85    1 "University" 2 "Other Four Year" 3 "Two Year"
                       4 "Other 4 Yr branch" 5 "2 Yr campus multicamp"
                       6 "2 Yr of other 4 Yr" 7 "None of the above" ;
label define SEX85     1 "Male" 2 "Female" 3 "Coeducational" 4 "Coordinate" ;
label define LGRNT85   0 "No-land Grant Institution"
                       1 "Land Grant Institution" 2 "Member of NASULGC" ;
label define SUM2YR85  0 "No" 1 "Yes" ;
label define SUM4YR85  0 "No" 1 "Yes" ;
label define SUMPOS85  0 "No" 1 "Yes" ;
label define EVE2YR85  0 "No" 1 "Yes" ;
label define EVE4YR85  0 "No" 1 "Yes" ;
label define EVEPOS85  0 "No" 1 "Yes" ;
label define EXCNTL85  0 "Not specified" 1 "Publicly controlled"
                       2 "Privately controlled" 3 "Religious affiliation" ;
label define CITYSI85  0 "Not Identified" 1 "Outside any SMA"
                       2 "Within SMA less the 250,000"
                       3 "Within SMA 250,000 to 499,999"
                       4 "Within SMA 500,000 to 999,999"
                       5 "SMA 1,000,000 -1,999,999 outside center city"
                       6 "SMA within Center city 1,000,000- 1,999,999"
                       7 "SMA/SCSA 2,000,000 or more outside center city"
                       8 "SMA/SCSA within center city 2,000,000 or more" ;
label define ADMREQ85  1 "Only the ability to profit from attendance"
                       2 "High School graduation or recognized equivalent"
                       3 "High Schl grad plus an indic superior acad aptitude"
                       4 "Two Year college completion"
                       5 "Four Year college completion"
                       6 "Other: any admission less than 2 year college compl"
                       7 "Other: requires 2 years college compl but less than four"
                       8 "Other: requires 4 years or more" ;


#delimit cr

/********************************************************************

 Section 4: Save Outfile

  This section saves out a Stata system format file.  There is no reason to
  modify it if the macros in Section 1 were specified correctly.

*********************************************************************/

save `outfile', replace

