/*

02_clean_classranks.do
(called from master_main.do)

Purpose: clean class rank data
Inputs: codes/class_ranks
Outputs: intstata/class_rank_pid, intstata/class_rank_index

*/


// 1) pid dataset-- this takes precedence
insheet using "${codes}/class_ranks.csv", names comma clear

keep if !mi(pid)
drop rb_index
duplicates report pid year
// put groups in numeric format: 
tab group
replace group=trim(group)
gen rankgroup=1 if group=="I"
replace rankgroup=2 if group=="II"
replace rankgroup=3 if group=="III"
replace rankgroup=4 if group=="IV"
replace rankgroup=5 if group=="V"
replace rankgroup=6 if group=="VI"

// put dataset in wide form-- person level:
keep pid year rankgroup
reshape wide rankgroup, i(pid) j(year)

isid pid

label var pid "ID (from Class Reports)"
label var rankgroup1 "Rank group year 1"
drop rankgroup2
label var rankgroup3 "Rank group year 3"

compress
save "${intstata}/class_rank_pid", replace

// 1) red book index: this fills in additional data: 
insheet using "${codes}/class_ranks.csv", names comma clear

keep if !mi(rb_index)
drop pid 
duplicates report rb_index year
// put groups in numeric format: 
tab group
replace group=trim(group)
gen rankgroup=1 if group=="I"
replace rankgroup=2 if group=="II"
replace rankgroup=3 if group=="III"
replace rankgroup=4 if group=="IV"
replace rankgroup=5 if group=="V"
replace rankgroup=6 if group=="VI"

// put dataset in wide form-- person level:
keep rb_index year rankgroup
reshape wide rankgroup, i(rb_index) j(year)

ren rb_index index
isid index

label var index "ID (from red books)"
label var rankgroup1 "Rank group year 1"
drop rankgroup2
label var rankgroup3 "Rank group year 3"

compress
save "${intstata}/class_rank_index", replace