/*

04_random_variation.do
(called from master_census.do)

Purpose: produces randomization and peer effects output
Inputs: 04a_prog_exp_table.do, 04b_random_variation_balance.do,
	4c_random_variation_effects.do, 04d_randomization_inference.do
Outputs: N/A
	
*/

/*
	Produces randomization and peer effects table and figures 
*/

** Define programs exp_table, alt_exp_table, out_by_higrade_table, tgraph, rinf, exp_table_rinf
** These programs run experimental specifications and outputs them to tables 
do 04a_prog_exp_table.do

** Implement programs to generate analysis tables/figures: 

** Table 5, A.6: Experimental Balance
do 04b_random_variation_balance.do

** Tables 6,7,A.7-15,B.16-20,B.25 and Figures 6,A.6,B.17
** Peer effects
do 04c_random_variation_effects.do

if $RANDOMIZATION == 1 {
	** Tables A.16 and A.17: Randomization Inference
	do 04d_randomization_inference.do
}