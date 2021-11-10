/*

02a_clean_ipeds.do
(called from 02_IPEDS_HEGIS_benchmarking.do)

Purpose: clean IPEDS data
Inputs: code/ipeds/ef`year'_a.do, intstata/dct_ef`year'_a,
	raw/IPEDS/ipeds/`year'/ic`year'_data_stata, raw/IPEDS/ipeds/`year'/ic`year'_a_data_stata
	raw/IPEDS/ipeds/1997/ic9798_hdr_data_stata, raw/IPEDS/ipeds/1998/ic98hdac_data_stata,
	raw/IPEDS/ipeds/1999/ic99_hd_data_stata, raw/IPEDS/ipeds/`year'/fa`year'hd_data_stata,
	raw/IPEDS/ipeds/`year'/hd`year'_data_stata
Outputs: intstata/ipeds_full

*/

// set up // 
clear
set more off

global ipeds "$code/ipeds/"
global ipeds_raw_data "$raw/IPEDS_HEGIS/ipeds/"
global ipeds_in_data "$intstata/"

// clean //
quietly {

do "$ipeds/ef1980_a.do" "$ipeds_raw_data/1980" "$ipeds_in_data"
forv year = 1984/1985 {
	do "$ipeds/ef`year'.do" "$ipeds_raw_data/`year'" "$ipeds_in_data"
}

forv year = 1986/1993 {
	do "$ipeds/ef`year'_a.do" "$ipeds_raw_data/`year'" "$ipeds_in_data"
}

forv year = 1994/1999 {
	do "$ipeds/ef`year'_anr.do" "$ipeds_raw_data/`year'" "$ipeds_in_data"
}

forv year = 2000/2018 {
	do "$ipeds/ef`year'a.do" "$ipeds_raw_data/`year'" "$ipeds_in_data"
}

}

// glue together //
clear
gen year = .
append using "$ipeds_in_data/dct_ef1980_a.dta"
replace year = 1980 if mi(year)

forv year = 1984/1985 {
append using "$ipeds_in_data/dct_ef`year'.dta", force
replace year = `year' if mi(year)
}

forv year = 1986/1993 {
append using "$ipeds_in_data/dct_ef`year'_a.dta", force
replace year = `year' if mi(year)
}

forv year = 1994/1999 {
append using "$ipeds_in_data/dct_ef`year'_anr.dta" , force
replace year = `year' if mi(year)
}

forv year = 2000/2018 {
append using "$ipeds_in_data/dct_ef`year'a.dta" , force
replace year = `year' if mi(year)
}

* duplicates?
drop if line==99 // excess entries in 1999
duplicates list unitid year line
duplicates drop unitid year line , force
isid unitid year line

* reshape -- keep only undergrad and first year enrollment
gen tokeep = 0
replace tokeep = 1 if (year<2002 & (line==1 | line==2 | line == 8) ) 
replace tokeep = 1 if (year>=2002 & (efalevel==23 | efalevel==24))
keep if tokeep==1

*line formats are tricky-- be careful

// pre-1986, 1=total, 2=FTIC
gen j = "_firsttime" if line==2 & year<1986 
replace j = "_total" if line==1 & year < 1986 

// 86-01: 1=ftic, 8=total
replace j = "_total" if line==8 & year >= 1986 & year < 2002
replace j = "_firsttime" if line==1 & year >= 1986 & year < 2002

// 02 and later: efalevel is now relevant variable
replace j = "_firsttime" if efalevel == 24 & year >= 2002
replace j = "_total" if efalevel == 23 & year >= 2002
drop if mi(j)

* rename enrollment count variables -- using reported, not generated
ren efrace15 enrollfullmen
ren efrace16 enrollfullwomen
ren efrace17 enrollfullint // international
ren efrace18 enrollfullblack // black, non-hispanic
ren efrace19 enrollfullai // american indian
ren efrace20 enrollfullasian // asian-american
ren efrace21 enrollfullhisp // hispanic
ren efrace22 enrollfullwhite //white nonhisp

// before 2002 aggregate race stats aren't reported-- so fill in from disaggregated stats by gender
replace enrollfullint=efrace01+efrace02 if year<2002
replace enrollfullblack=efrace03+efrace04 if year<2002
replace enrollfullai=efrace05+efrace06 if year<2002
replace enrollfullasian=efrace07+efrace08 if year<2002
replace enrollfullhisp=efrace09+efrace10 if year<2002
replace enrollfullwhite=efrace11+efrace12 if year<2002

* fix labels 2008 onwards
replace enrollfullmen = eftotlm if year>2007
replace enrollfullwomen = eftotlw if year>2007

replace enrollfullasian=efasiat+efnhpit if year>=2008 // aggregate AA and PI as in previous years
replace enrollfullblack=efbkaat if year>=2008
replace enrollfullwhite=efwhitt if  year>=2008 
replace enrollfullhisp=efhispt if year>=2008
replace enrollfullai= efaiant if year>=2008 

ren ef2mort enrollfull2ormore // 2 or more races-- 2008 and later only 

gen enrollfull = enrollfullmen + enrollfullwomen

* kill useless vars not constant w/in id*year reshape
keep year unitid enrollfull* j

reshape wide enroll* , i(unitid year) j(j) string

tab year

//////////////////////////
// institutional charcs //
//////////////////////////

preserve

	* records begin
	foreach year in 1980 1984 1985 {
	insheet using "$ipeds_raw_data/`year'/ic`year'_data_stata.csv" , clear
	gen year = `year'
	keep unitid fice instnm year hloffer 
	compress
	tempfile ic`year'
	save `ic`year''
	}

	* late 80 onwards, skipping 90, 91 (missing)
	foreach year in 1986 1987 1988 1989 1992 1993 1994 1995 1996 {
	insheet using "$ipeds_raw_data/`year'/ic`year'_a_data_stata.csv" , clear
	gen year = `year'

	if `year'!=1986 keep unitid fice instnm year hloffer iclevel
	if `year'==1986 keep unitid fice instnm year hloffer iclevel level*

	drop if year==1986 & unitid == 247719 // trade schools with duplicate records?

	if year==1986 {
		replace hloffer = 5 if level5==1 // wasn't coded consistently that year
		replace hloffer = 6 if level6==1
		replace hloffer = 7 if level7==1
		replace hloffer = 8 if level8==1
		replace hloffer = 9 if level9==1
	}
	cap drop level*

	compress
	tempfile ic`year'
	save `ic`year''
	}

	* 1997
	insheet using "$ipeds_raw_data/1997/ic9798_hdr_data_stata.csv" , clear
	gen year = 1997
	keep unitid fice instnm year hbcu city stabbr  iclevel hloffer
	compress
	tempfile ic1997
	save `ic1997'

	* 1998
	insheet using "$ipeds_raw_data/1998/ic98hdac_data_stata.csv" , clear
	gen year = 1998
	keep unitid newid instnm year hbcu city stabbr  iclevel hloffer
	compress
	tempfile ic1998
	save `ic1998'

	* 1999
	insheet using "$ipeds_raw_data/1999/ic99_hd_data_stata.csv" , clear
	gen year = 1999
	keep unitid newid instnm year hbcu city stabbr  iclevel hloffer
	compress
	tempfile ic1999
	save `ic1999'

	* 2000s
	forv year = 2000/2001 {
	insheet using "$ipeds_raw_data/`year'/fa`year'hd_data_stata.csv" , clear
	gen year = `year'
	keep unitid newid instnm year hbcu city stabbr  iclevel deggrant hloffer
	compress
	tempfile ic`year'
	save `ic`year''
	}

	* 2002
	forv year = 2002/2018 {
	insheet using "$ipeds_raw_data/`year'/hd`year'_data_stata.csv" , clear
	gen year = `year'
	replace instnm = upper(instnm)
	keep unitid newid instnm year hbcu city stabbr iclevel deggrant hloffer
	compress
	tempfile ic`year'
	save `ic`year''
	}

	* glue together
	clear
	foreach year in 1980 1984 1985 1986 1987 1988 1989 1992 1993 1994 1995 1996 ///
					1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 ///
					2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 {
	append using `ic`year'' , force
	}

	* impute 1990 and 1991 char'cs using 1989 data (ICs missing for these years)
	expand 3 if year == 1989
	bys unitid year : replace year = year + _n - 1

	duplicates drop
	isid unitid year

	tempfile ics
	save `ics'

restore

merge 1:1 unitid year using `ics' , keep(match) nogen

drop if mi(hloffer)
gen tokeep =  /* first, post '85 def */ ///
		( year>1985 & (hloffer==5 /* highest deg offer = BA */ ///
						| hloffer==6 /* post bacc */ ///
						| hloffer==7 /* masters */ ///
						| hloffer==8 /* post-masters cert */ ///
						| hloffer==9) ) /* doctoral */ 
replace tokeep = 1 if /* 85 and below def */ ///
		( year<=1985 & (hloffer==4 /* highest deg offer = BA */ ///
						| hloffer==6 /* masters */ ///
						| hloffer==7 /* post masters */ ///
						| hloffer==8) ) /* doctoral */ 

tab year tokeep // 1986 looks off but i can't see a reason why
keep if tokeep 
drop tokeep

* save again
gen data = "IPEDS"
compress
save "${intstata}/ipeds_full.dta", replace