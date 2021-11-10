/*

master_longrun.do
(called from MASTER.do)

Purpose: runs the Python pre-cleaning and the long run Stata build
Inputs: make_lr_series.py, 01_clean_redbooks.do, 02_IPEDS_HEGIS_bechmarking.do,
	03_timeseries_plots.do, 04_occupations.do, 05_honors.do,
	06_additional_hs_occ_codes.do
Outputs: all long run data files and output

*/

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

if $PYTHON_CLEAN == 1 {
	
	cd "./Code/Long Run/Python"
	shell py -3.7 ./make_lr_series.py
		
}

cd "$code"

if $STATA_BUILD == 1 {
	
	// Clean Red Books
	do 01_clean_redbooks.do
	
	// Run IPEDS/HEGIS benchmarking
	do 02_IPEDS_HEGIS_benchmarking.do
	
}

if $OUTPUT == 1 {

	// Produce merge rate output
	do 03_merge_rates.do
	
	// Analyze occupations
	do 04_occupations.do
	
	// Analyze academic honors
	do 05_honors.do
	
	// Produce codes tables
	do 06_additional_hs_occ_codes.do

}

cd ../..
