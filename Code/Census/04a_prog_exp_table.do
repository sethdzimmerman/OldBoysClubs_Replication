/*

04a_prog_exp_table.do
(called from 04_random_variation.do)

Purpose: defines programs used in step 4b-d
Inputs: N/A
Outputs: N/A
	
*/

// program for making experimental balance table
// arguments are: 
// 1: name of tabular output
// 2: lists in quoutes
// 3: title   
cap program drop bal_table
program define bal_table 
	cap file close f
	file open f using "${tables}/`1'_test_`3'.txt", write replace
	
	file write f "\begin{tabular}{l cccccc}" 
	
	file write f _n $tab "\multicolumn{2}{c}{Year FEs}" $tab "\multicolumn{2}{c}{Price * Year FEs}" $tab "\multicolumn{2}{c}{Block FEs}" //

	foreach list in `2' {
		if "`list'"=="bal_list" file write f $llb "\emph{A. Balance test}"
		if "`list'"=="link_list" file write f $llb "\emph{A. Links to other data sources}"
		if "`list'"=="fs_list" file write f $lb $lb  "\emph{B. Peer and neighborhood attributes}"
		if "`list'"=="endog_list" file write f $lb  $lb "\emph{B. Endogenous peer outcomes}"

		foreach var of varlist ${`list'} {
			file write f $lb "`:var label `var''"
			
			if "`var'"!="mpgincwage1940_clean_nr" & "`var'"!="price_per_student" {
				// point estimates: 
				reg `var' $ivar i.year if rblock_sample==1, vce(cluster dorm_nbd_id)
				file write f $tab %4.3f (_b[${ivar}]) 
				file write f $tab "(" %4.3f (_se[${ivar}])  ")"
				if "`list'"=="bal_list" global res_`var'=_b[${ivar}]
				
				reghdfe `var' $ivar if rblock_sample==1, absorb(${rblock2} ) vce(cluster dorm_nbd_id)
				file write f $tab %4.3f (_b[${ivar}])
				file write f $tab "(" %4.3f (_se[${ivar}])  ")"
				
				reghdfe `var' $ivar, absorb(${rblock} i.hs_wm) vce(cluster dorm_nbd_id)
				if "`var'"!="pf_wm" {
					file write f $tab %4.3f (_b[${ivar}]) 
					file write f $tab "(" %4.3f (_se[${ivar}])  ")"
				}
				if "`var'"=="pf_wm" {
					file write f $tab "--"
					file write f $tab "--"
				}
				if "`list'"=="fs_list" global rb_`var'=_b[${ivar}]
				if "`list'"=="endog_list" global rb_`var'=_b[${ivar}]
				if "`list'"=="fs_list" global rb_`var'_se=_se[${ivar}]
			
			}

			if "`var'"=="mpgincwage1940_clean_nr" | "`var'"=="price_per_student" {
				// point estimates: 
				reg `var' $ivar i.year if rblock_sample==1, vce(cluster dorm_nbd_id)
				file write f $tab %4.1f (_b[${ivar}]) 
				file write f $tab "(" %4.1f (_se[${ivar}])   ")"
				if "`list'"=="bal_list" global res_`var'=_b[${ivar}]
				
				reghdfe `var' $ivar if rblock_sample==1, absorb(${rblock2} ) vce(cluster dorm_nbd_id)
				if "`var'"!="price_per_student"{
					file write f $tab %4.1f (_b[${ivar}]) 
					file write f $tab "(" %4.1f (_se[${ivar}])   ")"
				}
				if "`var'"=="price_per_student"{
					file write f $tab "--"
					file write f $tab "--"
				}
				
				reghdfe `var' $ivar, absorb(${rblock} i.hs_wm) vce(cluster dorm_nbd_id)
				if "`var'"!="price_per_student"{
					file write f $tab %4.1f (_b[${ivar}]) 
					file write f $tab "(" %4.1f (_se[${ivar}])   ")"
				}
				if "`var'"=="price_per_student"{
					file write f $tab "--"
					file write f $tab "--"
				}

				if "`list'"=="fs_list" global rb_`var'=_b[${ivar}]
				if "`list'"=="endog_list" global rb_`var'=_b[${ivar}]
				if "`list'"=="fs_list" global rb_`var'_se=_se[${ivar}]
				
			}
			
		}

		
		if $ACCESS == 1 {
			// balance joint test: 
			if "`list'"=="bal_list" {
				file write f $lb $lb "\emph{Joint balance test [p-value]}"

				// col 2: (rblock sample, no controls)
				estimates clear
				local test_text ""
				local suest_text ""	
				foreach txvar of varlist $test_list {
					reg `txvar' $ivar ib1920.year if rblock_sample==1
					eststo `txvar'
					local suest_text="`suest_text'"+" " +"`txvar'"			
					local  test_text="`test_text'"+" " +"([`txvar'_mean]${ivar}==0)"
				}
				
				// get joint VCV
				suest `suest_text', vce(cluster dorm_nbd_id)
				di "`test_text'"
				test `test_text'
				file write f $tab "[" %4.3f (`r(p)') "]"  $tab
				global test1=`r(p)' 
				
				// note that here and below base levels for rblocks are selected to be large
				// this is computationally important for computing VCV matrices for the blocks, which we are doing
				
				// col 3: (price  controls)
				estimates clear
				local test_text ""
				local suest_text ""	
				foreach txvar of varlist $test_list {
					qui reg `txvar' $ivar ib265.${rblock2} if rblock_sample==1
					eststo `txvar'
					if "`txvar'" !="price_per_student"  ///
						local suest_text="`suest_text'"+" " +"`txvar'"				
					if "`txvar'" !="price_per_student" local  test_text="`test_text'"+" " +"([`txvar'_mean]${ivar}==0)"
				}
				
				// get joint VCV
				suest `suest_text', vce(cluster dorm_nbd_id)
				di "`test_text'"
				test `test_text'
				file write f $tab "[" %4.3f (`r(p)') "]"  $tab
				global test2=`r(p)'
				
				// col 4: (price X occ+hs controls)
				estimates clear
				local test_text ""
				local suest_text ""
				foreach txvar of varlist $test_list {
					qui reg `txvar' $ivar ib491.${rblock} i.hs_wm if rblock_sample==1
					eststo `txvar'
					if "`txvar'" !="price_per_student" & "`txvar'" !="pf_wm" ///
						local suest_text="`suest_text'"+" " +"`txvar'"		
					if "`txvar'" !="price_per_student" & "`txvar'" !="pf_wm" ///
						local test_text="`test_text'"+" " +"([`txvar'_mean]${ivar}==0)"
				}
				
				// get joint VCV
				suest `suest_text', vce(cluster dorm_nbd_id)
				di "`test_text'"
				test `test_text'
				file write f $tab "[" %4.3f (`r(p)') "]"  $tab
				global test3=`r(p)'
			}
			
		}

	}

	// sample sizes: 
	file write f $llb "N" 
	
	reghdfe pf_wm $ivar if rblock_sample==1, absorb(${rblock} i.hs_wm) vce(cluster dorm_nbd_id)
	file write f $tab %12.0g (`e(N)') $tab 

	
	reghdfe pf_wm $ivar if rblock_sample==1, absorb(${rblock2}) vce(cluster dorm_nbd_id)
	file write f $tab %12.0g (`e(N)') $tab 
	
	reghdfe pf_wm $ivar if rblock_sample==1, absorb(${rblock} i.hs_wm) vce(cluster dorm_nbd_id)
	file write f $tab %12.0g (`e(N)') $tab 
	
	// close file: 
	file write f _n "\end{tabular}"
	file close f
end

// program for making experimental outcomes table
// arguments are: 
// 1: name of tabular output
// 2: name of rblock
// 3: additional controls to absorb
// 4: lists (in quotes)
// 5: indep variabl
// 6: cluster variables
// 7: sample restriction label
cap program drop exp_table
program define exp_table 
	cap file close f
	file open f using "${tables}/`1'_`7'.txt", write replace
	
	file write f "\begin{tabular}{l ccc c}" 
	
	file write f _n $tab "All" $tab " Private" $tab "Non-private" $tab "Test"

	di "`4'"
	foreach list in `4' {

		if "`list'"=="ac_list" | "`list'"=="APP1" file write f  $llb "\emph{A. First-year activities}" 
		if "`list'"=="mr_list" file write f  $lb $lb "\emph{B. Upper-year social clubs}"
		if "`list'"=="grade_list" |"`list'"=="grade_list_main" file write f $lb $lb "\emph{C. First-year academic rank}"
		if "`list'"=="APP2" file write f $lb $lb "\emph{B. First-year academic rank}"
		if "`list'"=="APP3" file write f $lb $lb "\emph{C. Adult associations}"
		if "`list'"=="APP4" file write f $lb $lb "\emph{D. Occupation choice}"
		if "`list'"=="APP5" file write f $lb $lb "\emph{E. Disaggregated business categories}"

		if "`list'"=="club_list" | "`list'"=="club_list_app" file write f $llb "\emph{A. Adult associations}"
		if "`list'"=="oc_list" | "`list'"=="oc_list_app" file write f $lb $lb "\emph{B. Occupation choice}"
		if "`list'"=="inc_list" file write f $lb $lb"\emph{C. Adult income}"
		
		if "`list'"=="maj_intent_index_list" file write f $llb "\emph{A. Major \& Intended Occ. Indices}"
		if "`list'"=="maj_list" file write f $lb $lb "\emph{B. Major Choice}"
		if "`list'"=="intent_list" file write f $lb $lb"\emph{C. Intended Occupation}"
		
		if "`list'"=="oc_list_supp" file write f $llb "\emph{A. Disaggregated business categories}"
		foreach var of varlist $`list' {
			file write f $lb "`:var label `var''"
			
			if  "`var'"!="incwage1940_clean" & "`var'"!="wage_index" {
				// point estimates: 
				reghdfe `var' `5', absorb(${`2'} `3') vce(cluster `6')
				file write f $tab %4.3f (_b[${ivar}]) 
				global all_`var'=_b[${ivar}]

				reghdfe `var' `5' if pf_wm==1, absorb(${`2'} `3') vce(cluster `6')
				file write f $tab %4.3f (_b[${ivar}])  
				global pf_`var'=_b[${ivar}]
				
				reghdfe `var' `5' if pf_wm==0, absorb(${`2'} `3')  vce(cluster `6')
				file write f $tab %4.3f (_b[${ivar}])   
				global npf_`var'=_b[${ivar}]
				
				// test: 
				reghdfe `var' ib0.pf_wm##c.`5', absorb(pf_wm##${`2'} pf_wm##`3') vce(cluster `6')
				test 1.pf_wm#$ivar
				file write f $tab %4.3f (`r(p)')  
				global test_`var'=`r(p)'
				
				// SEs: 
				file write f $lb
				reghdfe `var' `5', absorb(${`2'} `3') vce(cluster `6')
				file write f $tab "(" %4.3f (_se[${ivar}]) ")"
				global all_`var'_se=_se[${ivar}]
				
				reghdfe `var' `5' if pf_wm==1, absorb(${`2'} `3')  vce(cluster `6')
				file write f $tab "("  %4.3f (_se[${ivar}])   ")"
				global pf_`var'_se=_se[${ivar}]
				
				reghdfe `var' `5' if pf_wm==0, absorb(${`2'} `3')  vce(cluster `6')
				file write f $tab "("  %4.3f (_se[${ivar}])    ")"
				global npf_`var'_se=_se[${ivar}]
			}
			
			if  "`var'"=="incwage1940_clean" | "`var'"=="wage_index"{
				// point estimates: 
				reghdfe `var' `5', absorb(${`2'} `3') vce(cluster `6')
				file write f $tab %4.1f (_b[${ivar}]) 
				global all_`var'=_b[${ivar}]

				reghdfe `var' `5' if pf_wm==1, absorb(${`2'} `3') vce(cluster `6')
				file write f $tab %4.1f (_b[${ivar}])  
				global pf_`var'=_b[${ivar}]
				
				reghdfe `var' `5' if pf_wm==0, absorb(${`2'} `3')  vce(cluster `6')
				file write f $tab %4.1f (_b[${ivar}]) 
				global npf_`var'=_b[${ivar}]  
				
				// test: 
				reghdfe `var' ib0.pf_wm##c.`5', absorb(pf_wm##${`2'} pf_wm##`3') vce(cluster `6')
				test 1.pf_wm#$ivar
				file write f $tab  %4.3f (`r(p)') 
				global test_`var'=`r(p)'
				
				// SEs: 
				file write f $lb
				reghdfe `var' `5', absorb(${`2'} `3') vce(cluster `6')
				file write f $tab "(" %4.1f (_se[${ivar}]) ")"
				global all_`var'_se=_se[${ivar}]
				
				reghdfe `var' `5' if pf_wm==1, absorb(${`2'} `3')  vce(cluster `6')
				file write f $tab "("  %4.1f (_se[${ivar}])   ")"
				global pf_`var'_se=_se[${ivar}]
				
				reghdfe `var' `5' if pf_wm==0, absorb(${`2'} `3')  vce(cluster `6')
				file write f $tab "("  %4.1f (_se[${ivar}])    ")"
				global npf_`var'_se=_se[${ivar}]
			}
		}

		// sample sizes: 

		file write f $lb "N" 

		if "`list'"=="ac_list"  local vy "social" 
		if "`list'"=="mr_list"  local vy "hasty" 
		if "`list'"=="grade_list_main"  local vy "rg13_wm" 
		if "`list'"=="APP1" local vy "not_ssm"
		if "`list'"=="APP2" local vy "rankgroup1"
		if "`list'"=="APP3" local vy "have_frat_order"
		if "`list'"=="APP4" local vy "teach"
		if `"list"'=="APP5" local vy "bookkeep"
		if "`list'"=="oc_list"  local vy "finance" 
		if "`list'"=="club_list"  local vy "any_social_main" 
		if "`list'"=="inc_list"  local vy "incwage1940_clean"
		if "`list'"=="maj_intent_index_list"  local vy "zphat_maj_intent"
		if "`list'"=="maj_list"  local vy "econ_major"
		if "`list'"=="intent_list"  local vy "finance_intended"
		
		reghdfe `vy' `5', absorb(${`2'} `3')  vce(cluster `6')
		file write f $tab %12.0g (`e(N)')

		reghdfe `vy' `5' if pf_wm==1, absorb(${`2'} `3')  vce(cluster `6')
		file write f $tab %12.0g (`e(N)')
		
		reghdfe `vy' `5' if pf_wm==0, absorb(${`2'} `3')  vce(cluster `6')
		file write f $tab %12.0g (`e(N)')

	}

	file write f $llb
	
	// close file: 
	file write f _n "\end{tabular}"

	file close f
end
// end program exp_table

// program for making alternate experimental outcomes table
// arguments are: 
// 1: name of tabular output
// 2: name of rblock
// 3: additional controls to absorb
// 4: lists (in quotes)

cap program drop altexp_table
program define altexp_table 
	cap file close f
	file open f using "${tables}/`1'.txt", write replace

	file write f "\begin{tabular}{l ccc c}" 

	file write f _n $tab "Private feeder"  $tab "More expansive" $tab "Less expansive" $tab "Private non-feeder"

	foreach list in `4' {

		if "`list'"=="ac_list" file write f  $llb "\emph{A. First-year activities}"
		if "`list'"=="grade_list_main" file write f $lb $lb "\emph{C. Academic outcomes}"
		if "`list'"=="mr_list" file write f  $lb $lb "\emph{B. Upper-year social clubs}"

		if "`list'"=="club_list" file write f $llb "\emph{A. Adult associations}"
		if "`list'"=="oc_list" file write f $lb $lb "\emph{B. Occupation choice}"
		if "`list'"=="inc_list" file write f $lb $lb "\emph{C. Adult income}"

		foreach var of varlist $`list' {
			file write f $lb "`:var label `var''"
			
			if  "`var'"!="incwage1940_clean" & "`var'"!="wage_index" {
				// point estimates: 

				reghdfe `var' $ivar if pf_wm==1, absorb(${`2'} `3') vce(cluster dorm_nbd_id)
				file write f $tab %4.3f (_b[${ivar}])  
				
				reghdfe `var' $ivar if a1_pf_wm==1, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
				file write f $tab %4.3f (_b[${ivar}])   

				reghdfe `var' $ivar if a2_pf_wm==1, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
				file write f $tab %4.3f (_b[${ivar}])   
				
				reghdfe `var' $ivar if private_wm==1 & pf_wm==0, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
				file write f $tab %4.3f (_b[${ivar}])    

				// SEs: 
				file write f $lb
				reghdfe `var' $ivar if pf_wm==1, absorb(${`2'} `3') vce(cluster dorm_nbd_id)
				file write f $tab "(" %4.3f (_se[${ivar}]) ")"

				reghdfe `var' $ivar if a1_pf_wm==1, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
				file write f $tab "("  %4.3f (_se[${ivar}])    ")"

				reghdfe `var' $ivar if a2_pf_wm==1, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
				file write f $tab "("  %4.3f (_se[${ivar}])    ")"

				reghdfe `var' $ivar  if private_wm==1 & pf_wm==0, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
				file write f $tab "("  %4.3f (_se[${ivar}])   ")" 
			}
			
			if  "`var'"=="incwage1940_clean" | "`var'"=="wage_index" {
				// point estimates: 

				reghdfe `var' $ivar if pf_wm==1, absorb(${`2'} `3') vce(cluster dorm_nbd_id)
				file write f $tab %4.1f (_b[${ivar}])  
				
				reghdfe `var' $ivar if a1_pf_wm==1, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
				file write f $tab %4.1f (_b[${ivar}])   

				reghdfe `var' $ivar if a2_pf_wm==1, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
				file write f $tab %4.1f (_b[${ivar}])   
				
				reghdfe `var' $ivar if private_wm==1 & pf_wm==0, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
				file write f $tab %4.1f (_b[${ivar}])    

				// SEs: 
				file write f $lb
				reghdfe `var' $ivar if pf_wm==1, absorb(${`2'} `3') vce(cluster dorm_nbd_id)
				file write f $tab "(" %4.1f (_se[${ivar}]) ")"

				reghdfe `var' $ivar if a1_pf_wm==1, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
				file write f $tab "("  %4.1f (_se[${ivar}])    ")"

				reghdfe `var' $ivar if a2_pf_wm==1, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
				file write f $tab "("  %4.1f (_se[${ivar}])    ")"

				reghdfe `var' $ivar  if private_wm==1 & pf_wm==0, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
				file write f $tab "("  %4.1f (_se[${ivar}])   ")" 
			}
			
		}

		// sample sizes: 

		file write f $lb "N" 

		if "`list'"=="ac_list"  local vy "social" 
		if "`list'"=="mr_list"  local vy "hasty" 
		if "`list'"=="grade_list_main"  local vy "rg13_wm" 
		if "`list'"=="oc_list"  local vy "finance" 
		if "`list'"=="club_list"  local vy "any_social_main" 
		if "`list'"=="inc_list"  local vy "incwage1940_clean" 
			
		reghdfe `vy' $ivar if pf_wm==1, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
		file write f $tab %12.0g (`e(N)')
		
		reghdfe `vy' $ivar  if a1_pf_wm==1, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
		file write f $tab %12.0g (`e(N)')
			
		reghdfe `vy' $ivar  if a2_pf_wm==1, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
		file write f $tab %12.0g (`e(N)')
		
		reghdfe `vy'  $ivar if private_wm==1 & pf_wm==0, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
		file write f $tab %12.0g (`e(N)') 
		
	}

	file write f $llb
	
	// close file: 
	file write f _n "\end{tabular}"

	file close f
end
// end program

// program for making alternate experimental outcomes table
// arguments are: 
// 1: name of tabular output
// 2: lists (in quotes)

cap program drop out_by_higrade_table
program define out_by_higrade_table 
	cap file close f
	file open f using "${tables}/`1'.txt", write replace
	
	file write f "\begin{tabular}{l cccc}" 
	
	file write f _n $tab "\multicolumn{2}{c}{Rank group 1-4}" $tab "\multicolumn{2}{c}{Rank group 5-6 or unlisted}" //
	foreach list in `2' {
		if "`list'"=="mr_list_hg" file write f  $llb "\emph{A. Upper-year social clubs}"
		if "`list'"=="oc_list_hg" file write f $lb $lb "\emph{B. Occupation choice}"
		if "`list'"=="club_list_hg" file write f $lb $lb "\emph{C. Adult associations}"

		foreach var of varlist $`list' {
			file write f $lb "`:var label `var''"
			
			// point estimates: 

			reghdfe hg_`var' nbdranki if pf_wm==1, absorb($rblock i.hs_wm) vce(cluster dorm_nbd_id)
			file write f $tab %4.3f (_b[${ivar}])  
			file write f $tab "("  %4.3f (_se[${ivar}])   ")" 
			global b_hg_`var'=_b[${ivar}]
			global b_hg_`var'_rev=_b[${ivar}]*-1

			reghdfe lg_`var' nbdranki if pf_wm==1, absorb($rblock i.hs_wm) vce(cluster dorm_nbd_id)
			file write f $tab %4.3f (_b[${ivar}])  
			file write f $tab "("  %4.3f (_se[${ivar}])   ")"
			// global b_lg_`var'=_b[${ivar}]
			
			if "`var'"=="final_tier2" | "`var'"=="hed"  | "`var'"=="have_prof_assoc"  { // last vars of panels
				// sample sizes: 
				file write f $lb "N" 

				// if "`list'"=="ac_list"  local vy "social" 
					
				reghdfe hg_`var' nbdranki if pf_wm==1, absorb($rblock i.hs_wm)  vce(cluster dorm_nbd_id)
				file write f $tab %12.0g (`e(N)') $tab
				
				reghdfe lg_`var' nbdranki if pf_wm==1, absorb($rblock i.hs_wm)  vce(cluster dorm_nbd_id)
				file write f $tab %12.0g (`e(N)') $tab
			}

		}
			
	}

	file write f $llb
	
	// close file: 
	file write f _n "\end{tabular}"

	file close f
end
// end program

//
//
// graphs of treatment effects
//
//

// argument 1: outcome
// argument 2: number of quantiles
cap program drop tgraph
program define tgraph
	// generate rankings: 
	global q=`2'

	cap drop nbdqx
	xtile nbdqx=nbdranki, nq($q)

	// all : 
	reghdfe `1' ib1.nbdqx   , absorb(${rblock} i.hs_wm) vce(cluster dorm_nbd_id)

	cap drop x y lb ub
	gen x=.
	gen y=.
	gen lb=. 
	gen ub=.

	forv j=1/$q {
		replace x=`j' if _n==`j'
		replace y=_b[`j'.nbdqx] if _n==`j'
		replace ub=_b[`j'.nbdqx]+_se[`j'.nbdqx]*1.645 if _n==`j'
		replace lb=_b[`j'.nbdqx]-_se[`j'.nbdqx]*1.645  if _n==`j'	
	} 

	// group 1: 
	reghdfe `1' ib1.nbdqx if private_wm==1  , absorb(${rblock} i.hs_wm) vce(cluster dorm_nbd_id)

	cap drop x1 y1 lb1 ub1
	gen x1=.
	gen y1=.
	gen lb1=. 
	gen ub1=.

	forv j=1/$q {
		replace x1=`j' if _n==`j'
		replace y1=_b[`j'.nbdqx] if _n==`j'
		replace ub1=_b[`j'.nbdqx]+_se[`j'.nbdqx]*1.645 if _n==`j'
		replace lb1=_b[`j'.nbdqx]-_se[`j'.nbdqx]*1.645  if _n==`j'
	} 

	// group 2
	reghdfe `1' ib1.nbdqx if private_wm==0  , absorb(${rblock} i.hs_wm) vce(cluster dorm_nbd_id)

	cap drop x2 y2 lb2 ub2
	gen x2=.
	gen y2=.
	gen lb2=. 
	gen ub2=.

	forv j=1/$q {
		replace x2=`j'+.2 if _n==`j'
		replace y2=_b[`j'.nbdqx] if _n==`j'
		replace ub2=_b[`j'.nbdqx]+_se[`j'.nbdqx]*1.645 if _n==`j'
		replace lb2=_b[`j'.nbdqx]-_se[`j'.nbdqx]*1.645  if _n==`j'		
	} 

	// graph all: 

	twoway (bar y x,  barw(.75) color($c_all)) ///
		(scatter ub  x, msymbol(+) mcolor(gs5) msize(large) ) ///
		(scatter lb  x, msymbol(+) mcolor(gs5) msize(large)) ///	
		, scheme(s1color) legend(rows(1) order(1 "Effect" 2 "90% CI") size(vsmall)) yline(0) ///
		xlabel(1 2 3) xsize(10) ysize(10) title("`:var label `1''")  name(gpool`1', replace) xtitle(Tercile of peer price) ///
		ytitle(Effect estimate) nodraw

	// graph by group: 

	twoway (bar y1 x1,  barw(.75) color($c_pf)) ///
		(scatter ub1  x1, msymbol(+) mcolor(gs5) msize(large) ) ///
		(scatter lb1  x1, msymbol(+) mcolor(gs5) msize(large)) ///
		(bar y2 x2, barw(.75) color($c_npf)) ///
		(scatter ub2  x2, msymbol(x) mcolor(gs5) msize(large)) ///
		(scatter lb2  x2, msymbol(x) mcolor(gs5) msize(large)) ///	
		, scheme(s1color) legend(rows(1) order(1 "Priv. fdr." 2 "90% CI" 4 "Other hs" 5 "90% CI") size(vsmall)) yline(0) ///
		xlabel(1 2 3) xsize(10) ysize(10) title("`:var label `1''") name(g`1', replace) xtitle(Tercile of peer price) ///
		ytitle(Effect estimate) nodraw
		
end 
// end program

// randomization inference program
// inputs: you need to have just run the regression of interest
// argument 1: regression command to start things off
// argument 2: regression coefficent to extract
// argument 3: local storing beta
cap program drop rinf 
program define rinf , rclass

  `1'
  local depvar "`e(depvar)'"

  // generate sample flag
  gen __sample=e(sample)

  // initialize output variable
  gen __b=. 

  // loop over resamplings, storing estimates in __b: 
  forv j=1/$nresamp {
    if round(`j'/100)*100==`j' di "`j'" 

    // estimate regression on resampled data:
    qui reghdfe `depvar' sr`j' if __sample==1 , absorb(${rblock} i.hs_wm)  nosample
    qui replace __b=_b[`2'`j'] if _n==`j'
  }

  su __b if _n==1 // this is the parameter estimate we want to perform inference on we saved our data as observed in j==1
  return local b=`r(mean)' 

  gen __d=abs(__b)>=abs(`r(mean)') if !mi(__b) // how many estimates are larger than the one from the actual randomization 
  su __d

  // output: 
  return local p=`r(mean)'

  // store betas in variable from argument 3
  di "`3'"
  gen `3'=__b

  drop __b __d __sample

end 
// end program

// program for making experimental outcomes table with randomized inference
// arguments are: 
// 1: name of tabular output
// 2: name of rblock
// 3: additional controls to absorb
// 4: lists (in quotes)
cap program drop exp_table_rinf
program define exp_table_rinf 
  di "A"

  cap file close f
  file open f using "${tables}/`1'.txt", write replace

  file write f "\begin{tabular}{l ccc c}" 
  
  file write f _n $tab "All" $tab " Private" $tab "Non-private" $tab "Test"

  di "`4'"
  foreach list in `4' {

    if "`list'"=="ac_list" file write f  $llb "\emph{A. First-year activities}" 
    if "`list'"=="mr_list" file write f  $lb $lb "\emph{B. Upper-year social clubs}"
    if "`list'"=="grade_list" file write f $lb $lb "\emph{C. Academic outcomes}"

    if "`list'"=="club_list" file write f $llb "\emph{A. Adult social and professional organizations}"
    if "`list'"=="oc_list" file write f $lb $lb "\emph{B. Occupation choice}"
    if "`list'"=="inc_list" file write f $lb $lb"\emph{C. Adult income}"
    
    foreach var of varlist $`list' {
      file write f $lb "`:var label `var''"
      
      if  "`var'"!="incwage1940_clean" {
        
        di "A2"
        // point estimates: 
          rinf "reghdfe `var'  nbdrank, absorb(${`2'} `3')" "sr"  bmain
          local pmain=`r(p)'
          file write f $tab %4.3f (`r(b)') 

          rinf "reghdfe `var'  nbdrank if pf_wm==1, absorb(${`2'} `3')" "sr" bp
          local pp=`r(p)' 
          file write f $tab %4.3f (`r(b)') 
        
          rinf "reghdfe `var'   nbdrank if pf_wm==0, absorb(${`2'} `3')" "sr" bnp
            local pnp=`r(p)'  
          file write f $tab %4.3f (`r(b)') 
        
        // test: uses stored coefficients from above rinf commands
        gen difpnp=bp-bnp if !mi(bp) & !mi(bnp)
	su difpnp if _n==1 // observed difference
	gen __d=abs(difpnp)>=abs(`r(mean)') if !mi(difpnp)
	su __d
	local p=`r(mean)' 
	di "`p'"
        assert `r(N)'==$nresamp  // be sure that you are getting the right count of observations for this test
        
        file write f $tab %4.3f (`p')  
        drop bmain bp bnp __d  difpnp // drop stored variables for test
        // p-values: 
        file write f $lb
        file write f $tab "[" %4.3f (`pmain') "]"

        file write f $tab "["  %4.3f (`pp')   "]"
        
        file write f $tab "["  %4.3f (`pnp')    "]"
        
      }
      
      if  "`var'"=="incwage1940_clean" {
          
        di "A2"
        // point estimates: 
          rinf "reghdfe `var'  nbdrank, absorb(${`2'} `3')" "sr"  bmain
          local pmain=`r(p)'
          file write f $tab %4.1f (`r(b)') 

          rinf "reghdfe `var'  nbdrank if pf_wm==1, absorb(${`2'} `3')" "sr" bp
          local pp=`r(p)' 
          file write f $tab %4.1f (`r(b)') 
        
          rinf "reghdfe `var'   nbdrank if pf_wm==0, absorb(${`2'} `3')" "sr" bnp
            local pnp=`r(p)'  
          file write f $tab %4.1f (`r(b)') 
        
        // test: uses stored coefficients from above rinf commands
	gen difpnp=bp-bnp if !mi(bp) & !mi(bnp)
	su difpnp if _n==1 // observed difference
	gen __d=abs(difpnp)>=abs(`r(mean)') if !mi(difpnp)
	su __d
	local p=`r(mean)' 
	di "`p'"
        assert `r(N)'==$nresamp  // be sure that you are getting the right count of observations for this test
        
        file write f $tab %4.3f (`p')  
        drop bmain bp bnp __d  difpnp // drop stored variables for test
        // p-values: 
        file write f $lb
        file write f $tab "[" %4.1f (`pmain') "]"

        file write f $tab "["  %4.1f (`pp')   "]"
        
        file write f $tab "["  %4.1f (`pnp')    "]"
        
      }	
      
    }

    // sample sizes: 

    file write f $lb "N" 

    if "`list'"=="ac_list"  local vy "social" 
    if "`list'"=="mr_list"  local vy "hasty" 
    if "`list'"=="grade_list"  local vy "rg13_wm" 
    if "`list'"=="oc_list"  local vy "finance" 
    if "`list'"=="soc_club"  local vy "have_prof_assoc" 
    if "`list'"=="inc_list"  local vy "incwage1940_clean"
    if "`list'"=="club_list"  local vy "any_social_main" 
      
    reghdfe `vy' $ivar, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
    file write f $tab %12.0g (`e(N)')

    reghdfe `vy'  $ivar if pf_wm==1, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
    file write f $tab %12.0g (`e(N)')
    
    reghdfe `vy' $ivar if pf_wm==0, absorb(${`2'} `3')  vce(cluster dorm_nbd_id)
    file write f $tab %12.0g (`e(N)')
      
  }

  file write f $llb

  // close file: 
  file write f _n "\end{tabular}"

  file close f

end
// end program exp_table_rinf