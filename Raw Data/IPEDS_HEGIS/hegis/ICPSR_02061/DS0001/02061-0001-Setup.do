/**************************************************************************
 |                    STATA SETUP FILE FOR ICPSR 02061
 |       HIGHER EDUCATION GENERAL INFORMATION SURVEY (HEGIS) VIII:
 |           OPENING FALL ENROLLMENT IN HIGHER EDUCATION, 1973
 |
 |                                                                        
 |  Please edit this file as instructed below.                            
 |  To execute, start Stata, change to the directory containing:          
 |       - this do file                                                   
 |       - the ASCII data file                                            
 |       - the dictionary file                                            
 |                                                                        
 |  Then execute the do file (e.g., do 02061-0001-statasetup.do)          
 |                                                                        
 **************************************************************************/

set mem 9m  /* Allocating 9 megabyte(s) of RAM for Stata SE to read the
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


label data "Higher Education General Information Survey (HEGIS) VIII: Opening Fall Enrollment in Higher Education, 1973, Dataset 0001"

#delimit ;
label define OESTATE   10 "Alabama" 11 "Alaska" 12 "Arizona" 13 "Arkansas"
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
label define GEOGCODE  10 "Alabama" 11 "Alaska" 12 "Arizona" 13 "Arkansas"
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
label define OEREGCOD  1 "North Atlantic" 2 "Great Lakes & Plains"
                       3 "Southeast" 4 "West & Southwest"
                       5 "US service schools" 6 "Not in use"
                       7 "Outlying Areas" ;
label define OBEREGCO  0 "US service schools" 1 "New England" 2 "Mideast"
                       3 "Great Lakes" 4 "Plains" 5 "Southeast" 6 "Southwest"
                       7 "Rocky Mountains" 8 "Far West" 9 "Outlying Areas" ;
label define RACECODE  1 "White" 2 "Black" ;
label define CONTCODE  0 "Combin public & Priv" 1 "Public only"
                       2 "Private only" ;
label define SEXCODE   1 "Male" 2 "Female" 3 "Coeducational" 4 "Coordinate" ;
label define LANDGRAN  0 "No-land Grant Institution"
                       1 "Land Grant Institution" 2 "Member of NASULGC" ;
label define ACCREDIT  0 "None" 1 "Yes" ;
label define OFFERLEV  2 "Less than 1 Year" 3 "2 but less than 4 Yrs"
                       4 "4 or 5 Yr Baccalaureat"
                       5 "First Professional Degree" 6 "Masters"
                       7 "Beyond Masters less Doctor" 8 "Doctorate"
                       9 "Undergrad non-degree Granting"
                       10 "Graduate non-degree Granting"
                       11 "Post Doctoral Research only" ;
label define CALENSYS  1 "Semester" 2 "Quarter" 3 "Trimester" 4 "4/1/4"
                       5 "Other" ;
label define RECLASS   0 "None" ;
label define RANGECOD  0 "00000-00000" 1 "00001-00199" 2 "00200-00499"
                       3 "00500-00999" 4 "01000-02499" 5 "02600-04999"
                       6 "06000-09999" 7 "10000-19909" 8 "20000-and over" ;
label define RESTRIC   0 "Not Restricted" 1 "Restricted" ;
label define IMPUTCOD  0 "Unimputed" 1 "Imputed data" 3 "Adjusted data"
                       5 "Both imputed & Adusted data" ;
label define PARTID    1 "PART A" 2 "PART B" ;


#delimit cr

/********************************************************************

 Section 4: Save Outfile

  This section saves out a Stata system format file.  There is no reason to
  modify it if the macros in Section 1 were specified correctly.

*********************************************************************/

save `outfile', replace

