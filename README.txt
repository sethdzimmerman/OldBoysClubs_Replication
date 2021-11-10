This is the README for the code package for "Old Boys' Clubs and Upward Mobility Among the Educational Elite."

########### CODE ###########

All of the code is run from Code/MASTER.do. 
	You may run portions of the code outside of MASTER.do, but will still need to set the globals defined MASTER.do

We ran this code using Stata 16 and Python 3.7.4 on PC. 
	To ensure exact replication, we recommend using these software versions as well as the versions of the software 
	packages that we used. See below for details on package installation. 

There are four sections of the code, each with its own subfolder in the code directory:
	i) The Main section. 
		This contains data construction code for the analysis of pre-WWII Harvard cohorts in sections 2-5 of the paper. 
		It also constructs appendix tables and figures related to data construction, as well as the the tables and 
		figures in the appendix and main text that use Mobility Report Card data. 

	ii) The Long Run section. 
		This contains data construction code for the analysis of Red Books and Class Reports across the 20th Century,
		as presented in section 6 of the paper. It produces appendix tables and figures describing the data 
		construction process. 
		
	iii) The Census section. 
		This code cleans the full count Census records and links those records to files developed in the Main and Long 
		Run code sections. It then produces the main text and Appendix output, with the exception of the limited set of 
		exhibits on data construction noted above.

	iv) Keys.
		These are files used by code in the Main and Long Run folders to classify text strings. 

We have built options into the MASTER.do file to accommodate replication of different parts of the project, depending 
on data availability and interest. When running MASTER.do, please select the appropriate option by placing either a 0 
or a 1 after the global variable name. Set values to 1 to run the indicated section of code. 

	i) MAIN runs the Main section. LR runs the Long Run section. CENSUS runs the census section.

	ii) PYTHON_CLEAN runs the low-level data cleaning processes that build up intermediate datasets from raw inputs in
		both the Main and Long Run code sections. 

	iii) STATA_BUILD takes output generated in PYTHON_CLEAN and produces the analysis datasets stored in the 
		\Cleaned Data\ subfolder. 

	iv) OUTPUT generates the figures, tables, and numbers reported in the paper, placing them in the folder \Output\ 
		and its subfolders. Figure 3 in the paper requires R to run. You may set R_FIGURE to 1 if you would like 
		to create that figure.

	v) RANDOMIZATION runs the randomization inference step reported in Tables A.16 and A.17 of the Online Appendix. 
		This step takes a long time, so users may wish to skip this section in some cases. 

	vi) ACCESS tells the code whether to conduct analyses requiring access to the full count Census records. If you 
		have access to full count Census records and want to replicate our analyses, set ACCESS to 1, and set 
		CENSUS_PATH1 to the location of the Census files. You will also need to set subdirectories appropriately. We 
		accessed the full count Census records using the 2019 versions stored on the NBER server, and the directories 
		correspond to the file structure there. See the file Reference/Census File Structure.xslx for details. 

########### IMPLEMENTATION HEURISTICS ###########

There are different ways you can use this code, depending on what your goals are and what data you have available. 

Here are the key choices you can make: 

Choice 1: build the cleaned data files from raw files, or use the cleaned files that we have provided. 

	The code in \Code\Main\ and \Code\Long Run\ takes the raw inputs from the folder \Raw Data\ and produces cleaned 
	data outputs that are stored in \Cleaned Data\ and \Intermediate Data\, along with a small number of output files
	describing the data build. You can rebuild these files, by setting PYTHON_CLEAN and STATA_BUILD=1. But you do not 
	have to do this, because all the files are already there. We have set PYTHON_CLEAN and STATA_BUILD to zero as 
	a default.

Choice 2: use full count Census records to produce all output in the paper, or produce only the output that does not 
depend on Census access. 

	Full count Census records typically have access restrictions in place. If you have access to full count Census 
	records, set ACCESS=1 in the master level code, set directories appropriately, and then output all the results in 
	the paper. 

	If you do not have access to full count records, set ACCESS=0 and the code will output a modified set of Tables and 
	Figures that exclude results that require the Census records to generate. We set ACCESS=0 as a default because we 
	assume that most people do not have access to these data. 

########### DATA DETAILS ###########

All the Harvard archival we used for this project is included in its raw form in the folder \Raw Data\. The complete 
count Census data is restricted access. We used the data through an agreement with IPUMS, Ancestry.com, and NBER. 
This webpage provides details: https://www.nber.org/research/data/ancestrycom-and-ipums-complete-count-restricted-file. 

We use data from Census years 1850 and 1900-1940. These data are periodically updated, so we use the 2019 version, 
which should be stable. The directory references to Census data in our code refer to the directory structure on NBER 
servers. 

The data files generated by the code and included in the package are as follows. See Reference/Readme.txt for additional
details. 

Cleaned Data: 
	> redbooks_clean.dta
	> lr_series_redbooks_clean.dta
	> lr_class_reports_clean.dta
	> census_rb_merged.dta (version produced without Census data)
	> better_processed_redbooks_res_sample.dta (version produced without Census  data)

Intermediate contains the following:
	i) Codes. These are where those codes are then stored.
	ii) Excel Files. This is where the output of the Python cleaning is stored.
	iii) Stata Files. These are where intermediate Stata files are stored.

Output contains all of the output produced in the project. It is composed of Figures, Tables, and Numbers
(a folder that stores individual data points for use in the paper). See References/Output Locations to see where each 
of the output is produced in the individual do files.

References contains a codebook for each of the cleaned data files, as well as a guide to where each figure and table
from the paper is produced. You can also find a list of necessary Stata dta files to run the project with 
NBER ACCESS == 1.

########### NOTES ON VERSION CONTROL ###########

Python is open source and packages evolve over time. For replication purposes, we recommend you use Python version 
3.7.4 on a PC, as well as the versions of the packages that we used. We have included the package versions we used in 
/Packages/Python/. Alternatively, users may download the correct versions using the requirements_version.txt file in 
/Code/. See the readme in the Packages folder for more details. 

Python is called by Stata in Code/Main/master.do and Code/Long Run/master_longrun.do. We specifically call Python 
version 3.7 in the shell commands in these files. 

Users who want to use current versions of Python and/or the Python packages we call can change the shell commands to 
call the version of their choice. Similarly, they can set line 44 of MASTER.do to requirements.txt to download the 
latest package versions. 

Stata packages also may evolve over time. We have included the versions of the packages we used in /Packages/Stata/. If 
you want download recent versions from the web, LATEST_PACKAGES_STATA to 1. 

We have also included the versions of the packages neccessary to run the R script in /Packages/R/. The version numbers 
are also commented in /Code/Main/process_gpkg.R. We recommend using these versions along with a version of R between 
3.6.3. and 4.1.2.

Note that when Python and R are called from the Shell within Stata, any errors will result in the Shell closing and
Stata resuming with the Stata code. Be sure when running Python and R code from the shell/command window,
that you have added the Python and R path locations to your computer's PATH environment.