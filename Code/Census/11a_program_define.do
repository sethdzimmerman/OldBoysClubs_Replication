/*

11a_program_define.do
(called from 11_cross_section_trends.do)

Purpose: define programs used in step 11
Inputs: N/A
Outputs: N/A
	
*/

// graph program for outcomes by arbitrary grouping variable
// argument 1: outcome of interest
// argument 2: additional conditioning statement (optional)
// argument 3: categorical variable to split by
// argument 4: graph title (ste to 'no' if no graph title should be displayed)
// argument 5: filename (optional)
cap program drop catout_graph 
program define catout_graph 
	levelsof `3', local(levels)
	local nvals=wordcount("`levels'")
	local k=0
	foreach  j of local levels {
	local k=`k'+1
	// variables for graph outcomes
	// label using value labels of split variable	
	 cap drop __g`k'
	 gen __g`k'=. 
	 label var __g`k' "`:label (`3') `j''"
	 di "`:label (`3') `j''"
	}
	cap drop gyear
	gen gyear=5*(_n-1)+1922.5 if _n<=14
	local i=0
	forv j=1922.5(5)1987.5 {
	 local i=`i'+1 // counting observations
	 local l=0 //
	foreach  k of local levels {
	 local l=`l'+1	
	// outcome means: 
	qui  su `1' if `3'==`k' & class>=`j'-2.51 & class<=`j'+2.51 `2' // get both endpoints	
	qui cap replace __g`l'=`r(mean)' if _n==`i'
	 }	
	}
	
	// generate figures:
	local symblist "Oh Dh Sh Th + x"
	local title = "`4'"
	if "`title'" == "no" {
		local title = ""
	}
	local graph_string=""
	forv j=1/`nvals' {
	 local sym=word("`symblist'",`j')
	 di "`sym'"
	 local series="(connect __g`j' gyear in 1/14, msymbol(`sym') msize(large))"	
	 local graph_string="`graph_string'"+" `series'" 	
	} 
	twoway `graph_string', scheme(s1color) xtitle(Class year) ytitle("Share") ///
	xlabel(1920(20)1980) legend(rows(1)) title("`title'") name(g_`1'_`3'_out, replace) ///
	xsize(20) ysize(12)
	
	// Export (optional)
	local file = "`5'"
	if strlen("`file'") > 0 {
		graph export "$figures/`file'.png", as(png) width(3200) replace
	}
end

// graph program for shares of arbitrary grouping variable
// argument 1: categorical variable to split by
// argument 2: categories to exclude (optional)
// argument 3: graph title (set to 'no' if no graph title)
// argument 4: filename (optional)
// argument 5: additional conditional statement (optional)
// argument 6: y axis stipulation
cap program drop catshare_graph 
program define catshare_graph
	local excl_list = subinstr("`2'"," ",",",.)
	levelsof `1' , local(levels)
	local nvals=wordcount("`levels'")
	*local k=0
	foreach  l of local levels {
	*local k=`k'+1
	// variables for graph outcomes
	// label using value labels of split variable	
	 cap drop __s`l'
	 gen __s`l'=. 
	 label var __s`l' "`:label (`1') `l''"
	// dummies for computing shares
	 cap drop __d`l'
	 gen __d`l'=`1'==`l' if  !mi(`1')
	}
	cap drop gyear
	gen gyear=5*(_n-1)+1922.5 if _n<=19
	local i=0
	forv y=1922.5(5)2012.5 {
	 local i=`i'+1 // counting observations
	* local l=0 //
	foreach l of local levels {
	* local l=`l'+1	
	// variable shares: 
	qui su __d`l' if  class>=`y'-2.51 & class<=`y'+2.51 `5' // get both endpoints
	qui  replace __s`l'=`r(mean)' if _n==`i'

	 }	
	}
	// Set categories that are not supposed to be dispalyed to missing
	foreach l of local levels {
		if inlist(`l',`excl_list') {
			replace __s`l' = .
		}
	}
	
	// generate figures:
	local symblist "Oh Dh Sh Th + x"
	local title = "`3'"
	if "`title'" == "no" {
		local title ""
	}
	local graph_string=""
	local j = 0
	foreach l of local levels  {
		if inlist(`l',`excl_list')==0 {
		
		local j = `j' +1
		local sym=word("`symblist'",`j')
		local series="(connect __s`l' gyear in 1/20, msymbol(`sym') msize(large))"	
		local graph_string="`graph_string'"+" `series'" 
		}
	} 
	twoway `graph_string', scheme(s1color) xtitle(Class year) ytitle(Share) ///
	xlabel(1920(20)2000) legend(rows(1)) title("`title'") name(g_`1'_share, replace) ///
	xsize(20) ysize(12) `6'
	local file = "`4'"
	if strlen("`file'") > 0 {
		graph export "$figures/`file'.png", as(png) width(3200) replace
	}
end
///// 