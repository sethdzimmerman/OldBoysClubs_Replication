/*

master_census.do
(called from MASTER.do)

Purpose: runs the Census data portion of the project
Inputs: refresh_all.py, 01_clean_roomprices.do, 02_clean_classranks.do,
	03_format_senior_clubs.do, 04_clean_redbooks.do, 05_catcode_tables.do,
	06_mrc_plots.do
Outputs: all Census-related data files and output

*/

clear all
version
// set directories
global code "`c(pwd)'"
cd ../..
global home "`c(pwd)'" 
global raw "$home/Raw Data" 
global int "$home/Intermediate Data"
global intstata "$int/Stata Files"
global intexcel "$int/Excel Files"
global cleaned "$home/Cleaned Data"
global raw "$home/Raw Data"
global codes "$int/Codes"
global keys "$home/Code/Keys"
global tables "$home/Output/Tables"
global figures "$home/Output/Figures"
global numbers "$home/Output/Numbers"

/////////////////////////////
/// Set Coding Parameters ///
/////////////////////////////
// set rblock: 
global rblock price_year_cap
global rblock2 price_year
global ivar "nbdranki" // this is the key regressor-- measure of nbd quality

// set Latex notation
global tab `""&" _tab"' 
global lb `""\\ " _n "' //line break
global llb `""\\ \hline" _n "' //single line followed by line break 
global l `""\\ \hline" "' // single line

// set colors
global c_all purple%40
global c_npf red%20
global c_pf blue%60
global c_line_all black%50

//////////////////////////////////////////////////////////////////////////////////
// program to write individual numbers to .tex files to read into the main text //
//////////////////////////////////////////////////////////////////////////////////
// called in both 05_descriptive and 06_random_variation
// argument 1: file name
// argument 2: text (usually a number) to be stored
// argument 3: number of decimal points
// argument 4: per if need to multiply by 100 to convert share to percentage
cap program drop store_stat
program define store_stat 
	cap file close f
	file open f using "${numbers}/`1'.txt", write replace
	if "`4'"=="per" {
	local 2=`2'*100
	}
	if ("`3'"=="") {
	file write f "`2'"
	}
	if ("`3'"=="c") {
	file write f  %12.0fc  (`2')
	}
	if "`3'"=="0" {
	file write f %4.0f (`2')
	}
	if "`3'"=="1" {
	file write f %4.1f (`2')
	}
	if "`3'"=="2" {
	file write f %4.2f (`2')
	}
	if "`3'"=="3" {
	file write f %4.3f (`2')
	}

	file close f
end


/*
	Program: write_panel
	Writes Row panels of means for variables in rows in sample as columns
	Arguments:
	1) list of rows
	2) list of columns (as samples)
	3) Panel header string
	4) additional sample condition
	5) Write sample size row for each colum
*/
cap program drop write_panel
program define write_panel

	global rows "`1'"
	global columns "`2'"
	global header "`3'"
	local samp_cond "`4'"
	local obs "`5'"
	
	
	file write f "\emph{${header}}\\"_n
	
	foreach row in $rows {
	    file write f "`:var la `row''"
		
		foreach col in $columns {
		    qui su `row' if `samp_cond' == 1 & `col' == 1
			file write f "& " %4.3fc (`r(mean)')
		}
		
		file write f "\\"_n
	}
	
	if "`obs'" == "obs" {
		file write f "\emph{N}"
		
		foreach col in $columns {
		    qui count if `col' == 1 & `samp_cond' == 1
		    file write f "& " %4.0fc (`r(N)')
		}
		file write f "\\"_n 
	}
	
	file write f "\\[-1.0em]"_n
end

cd "$code"

if $STATA_BUILD == 1 {

	if $ACCESS == 1 {
		
		// Clean Census data
		do 01_clean_census.do 
		cd "$code"
		
	}

	// Merge Census data with Harvard Redbooks data
	do 02_rb_census_merge.do
	
}

if $OUTPUT == 1 {
	
	// Descriptive Analysis
	do 03_descriptive.do

	// Experimental Balance and Peer Effects
	do 04_random_variation.do

	// Returns to college major
	do 05_college_majors.do

	// The Athlete premium
	do 06_college_sports.do

	// Robustness to Business Cycle Effects
	do 07_business_cycle_robust.do

	// Selection into college clubs
	do 08_club_selection.do

	if $ACCESS == 1 {
		// Long run trends of ethnicities, immigration and religion
		do 09_religion_immigration.do
	}

	// Spouse analysis
	do 10_spouse_analysis.do
	graph drop _all
	
	// Time trends of grades, careers and education by HS, race and gender
	do 11_cross_section_trends.do 
	graph drop _all
	
}

 cd ..
