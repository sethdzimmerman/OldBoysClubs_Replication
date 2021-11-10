// See README for instructions on how to run

clear all
version 16

cap confirm file MASTER.do
if _rc != 0 {
	display as error "Please make sure you are in the correct directory"
}

// Set each of the options below to either 0 or 1

// set any of these to 1 to run that portion of the project
global MAIN = 1
global LR = 1
global CENSUS = 1

// set any of these to 1 to run that aspect of the code
global PYTHON_CLEAN = 0
global STATA_BUILD = 0
global OUTPUT = 1
	// set to 1 to run the randomization inference code - takes about 10-20 hours
	global RANDOMIZATION = 0
	// set to 1 to run the R code that makes Figure 3
	global R_FIGURE = 0

// set to 1 if you have access to the Census data
global ACCESS = 0
	// put file path of Census materials here - see "Reference/Census File Structure" 
	global CENSUS_PATH1 = "/homes/data/census-ipums/v2019"
		
// set any of these to 1 to install the neccessary packages for the project
global LATEST_PACKAGES_STATA = 1
global PACKAGES_PYTHON = 0

if $LATEST_PACKAGES_STATA == 1 {
	foreach pkg in "coefplot" "reghdfe" "estout" "lassopack" "tabout" "ftools" "binscatter" {
		ssc install `pkg', replace
	}
	net install grc1leg, from(http://www.stata.com/users/vwiggins) replace
	net install binsreg, from (https://raw.githubusercontent.com/nppackages/binsreg/master/stata) replace
	net install dm0082, from(http://www.stata-journal.com/software/sj15-3) replace
}

if $PACKAGES_PYTHON == 1 {
	shell py -3.7 -m pip install -r requirements_version.txt
}


if $MAIN == 1 {
	
	cd "Main"
	do "master_main.do"
	
}

if $LR == 1 {
	
	cd "Long Run"
	do "master_longrun.do"
	
}

if $CENSUS == 1 {
	
	cd "Census"
	do "master_census.do"
	
}