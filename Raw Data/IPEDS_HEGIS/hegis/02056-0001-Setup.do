/**************************************************************************
 |                                                                         
 |                    STATA SETUP FILE FOR ICPSR 02056
 |       HIGHER EDUCATION GENERAL INFORMATION SURVEY (HEGIS), 1968:
 |                            FALL ENROLLMENT
 |
 |
 |  Please edit this file as instructed below.
 |  To execute, start Stata, change to the directory containing:
 |       - this do file
 |       - the ASCII data file
 |       - the dictionary file
 |
 |  Then execute the do file (e.g., do 02056-0001-statasetup.do)
 |
 **************************************************************************/

set mem 7m  /* Allocating 7 megabyte(s) of RAM for Stata SE to read the
                 data file into memory. */


set more off  /* This prevents the Stata output viewer from pausing the
                 process */

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


label data "Higher Education General Information Survey (HEGIS), 1968: Fall Enrollment"

#delimit ;
label define RACE      1 "WHITE" 2 "BLACK" ;
label define CONTROL   0 "COMBINATION PUBLIC AND PRIVATE" 1 "PUBLIC ONLY"
                       2 "PRIVATE ONLY" ;
label define SEX       1 "MALE" 2 "FEMALE" 3 "COEDUCATIONAL" 4 "COORDINATE" ;
label define RESTRICT  0 "NOT RESTRICTED" 1 "RESTRICTED" ;
label define IMPUTATION 0 "UNIMPUTED" 1 "ENTIRE INSTITUTION IMPUTED" ;


#delimit cr

/********************************************************************

 Section 4: Save Outfile

  This section saves out a Stata system format file.  There is no reason to
  modify it if the macros in Section 1 were specified correctly.

*********************************************************************/

save `outfile', replace

