/*

master_main.do
(called from MASTER.do)

Purpose: runs the Python pre-cleaning and the main Stata build
Inputs: refresh_all.py, 01_clean_roomprices.do, 02_clean_classranks.do,
	03_format_senior_clubs.do, 04_clean_redbooks.do, 05_catcode_tables.do,
	06_mrc_plots.do
Outputs: all main data files and output

*/

clear all 

// Set directories
global code "`c(pwd)'/Stata"
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

// Set seed
set seed 33921558
set sortseed 20910

if $PYTHON_CLEAN == 1 {
	
	cd "./Code/Main/Python"
	shell py -3.7 ./refresh_all.py
	
}

// move to stata code directory: 
cd "$code"

if $STATA_BUILD == 1 {

	// Clean room prices
	do 01_clean_roomprices.do

	// Clean class ranks
	do 02_clean_classranks.do

	// Clean senior clubs
	do 03_format_senior_clubs.do

	// Clean Red Books
	do 04_clean_redbooks.do
	
}

if $OUTPUT == 1 {

	// Produce codes tables 
	do 05_catcode_tables.do
	
	// Produce family income plots
	do 06_mrc_plots.do
	
	// Run R code to make rooms visualization
	if $R_FIGURE == 1 {
		
		cd ..
		shell Rscript process_gpkg.R
		cd "$code"
		
	}

}

cd ../..