/*

02a_clean.do
(called from 02_rb_census_merge.do)

Purpose: drops unused Census variables and labels others
Inputs: N/A
Outputs: N/A
	
*/

drop all_harvard ///
ark1900 ///
ark1910 ///
ark1920 ///
ark1930 ///
ark1940 ///
bp1900 ///
age1900 ///
role1900 ///
bphead1900 ///
bpwife1900 ///
county1900 ///
state1900 ///
city1900 ///
occupation1900 ///
wage_score1900 ///
employment1900 ///
bp1910 ///
age1910 ///
role1910 ///
bphead1910 ///
bpwife1910 ///
city1910 ///
county1910 ///
state1910 ///
employment1910 ///
wage_score1910 ///
occupation1910 ///
bp1920 ///
age1920 ///
role1920 ///
bphead1920 ///
bpwife1920 ///
county1920 ///
state1920 ///
city1920 ///
wage_score1920 ///
occupation1920 ///
bp1930 ///
age1930 ///
role1930 ///
bphead1930 ///
bpwife1930 ///
state1930 ///
county1930 ///
city1930 ///
employment1930 ///
wage_score1930 ///
occupation1930 ///
bp1940 ///
age1940 ///
role1940 ///
bphead1940 ///
bpwife1940 ///
state1940 ///
county1940 ///
city1940 ///
education1940 ///
employment1940 ///
wage_score1940 ///
income1940 ///
occupation1940 ///
father_pid1900 ///
mother_pid1900 ///
father_pid1910 ///
mother_pid1910 ///
father_pid1920 ///
mother_pid1920 ///
father_pid1930 ///
mother_pid1930 ///
father_pid1940 ///
mother_pid1940 ///
nchild1900 ///
head_occupation1900 ///
head_wage_score1900 ///
nchild1910 ///
head_wage_score1910 ///
head_occupation1910 ///
nchild1920 ///
head_wage_score1920 ///
head_occupation1920 ///
nchild1930 ///
head_wage_score1930 ///
head_occupation1930 ///
nchild1940 ///
head_wage_score1940 ///
head_occupation1940 ///
two_parent1900 ///
two_parent1910 ///
two_parent1920 ///
two_parent1930 ///
two_parent1940 ///
wife_present1900 ///
wife_present1910 ///
wife_present1920 ///
wife_present1930 ///
wife_present1940 ///
literacy1900 ///
literacy1910 ///
literacy1920 ///
literacy1930 ///
hh_servant1900 ///
hh_boarder1900 ///
hh_servant1910 ///
hh_boarder1910 ///
hh_servant1920 ///
hh_boarder1920 ///
hh_servant1930 ///
hh_boarder1930 ///
hh_servant1940 ///
hh_boarder1940 ///
speak_english1900 ///
speak_english1910 ///
mother_tongue1910 ///
speak_english1920 ///
mother_tongue1920 ///
speak_english1930 ///
mother_tongue1930 ///
mother_tongue1940 ///
anc_line_num ///
new_fs_ln ///
new_line_diff ///
line_good ///
age1940_nber ///
sex1940_nber ///
bpl1940_nber ///
school1940_nber ///
occscore1940_nber ///
classwkr1940_nber ///
incwage1940_nber ///
incnonwg1940_nber ///
educ1940_nber ///
mbpl1940_nber ///
fbpl1940_nber ///
metro1940_nber ///
farm1940_nber ///
ownershp1940_nber ///
valueh1940_nber ///
ed1940_nber ///
dnotmetro ///
valueh1940_clean ///
rent1940_clean ///
toprent1940 ///
selfemp1940 ///
occscore1940_clean ///
hs1940 ///
col11940 ///
has_cen_occ ///
cen_fin_any ///
cen_mng_any ///
cen_sci ///
cen_hed ///
cen_art ///
bpl_us ///
bpl_ma ///
bpl_eu ///
bpl_cee ///
bpl_ee ///
bpl_se ///
bpl_we ///
bpl_ne ///
bpl_ir ///
bpl_ca ///
mbpl_us ///
mbpl_ma ///
mbpl_eu ///
mbpl_cee ///
mbpl_ee ///
mbpl_se ///
mbpl_we ///
mbpl_ne ///
mbpl_ir ///
mbpl_ca ///
fbpl_us ///
fbpl_ma ///
fbpl_eu ///
fbpl_cee ///
fbpl_ee ///
fbpl_se ///
fbpl_we ///
fbpl_ne ///
fbpl_ir ///
fbpl_ca ///
gen1_immg ///
gen1_immg_se ///
gen1_immg_ee ///
gen2_immg ///
gen2_immg_ee ///
gen2_immg_se ///
prime_age_m1940 ///
dp95_rent ///
dp95_rent_head ///
dp95_valueh ///
dp95_valueh_head ///
dp95_incwage ///
dp95_incwage_head ///
dp99_rent ///
dp99_rent_head ///
dp99_valueh ///
dp99_valueh_head ///
dp99_incwage ///
dp99_incwage_head ///
dist_share_ownershp1940_clean ///
dist_share_ownershp1940_head ///
dist_share_toprent1940 ///
dist_share_hs1940 ///
dist_share_col51940 ///
dist_share_dp95_rent ///
dist_share_dp95_incwage ///
dist_N_hh ///
dist_N_prime ///
dist_N_harvard ///
mpreH_cen_year ///
preH_histid ///
preH_hs_momloc ///
preH_hs_poploc ///
preH_hs_sploc ///
preH_hs_famsize ///
preH_hs_famunit ///
preH_hs_relate ///
preH_hs_mbpl ///
preH_hs_fbpl ///
preH_serial ///
preH_cen_year ///
preH_pernum ///
preH_momloc ///
preH_poploc ///
preH_sploc ///
preH_famunit ///
preH_relate ///
preH_age ///
preH_sex ///
preH_bpl ///
preH_mtongue ///
preH_lit ///
preH_occ1950 ///
preH_occscore ///
preH_erscor50 ///
preH_edscor50 ///
preH_stateicp ///
preH_gq ///
preH_ownershp ///
preH_harvard ///
preH_max_pernum ///
preH_nparents ///
preH_dmom ///
preH_dpop ///
preH_dsp ///
preH_in_hs_fam ///
preH_is_hs_mom ///
preH_is_hs_pop ///
preH_is_hs_sp ///
preH_head ///
preH_rel ///
preH_vis ///
preH_bdr ///
preH_emp ///
preH_emp_rel ///
preH_other_nonrel ///
preH_relate_cat ///
preH_gq_any ///
preH_bpl_us ///
preH_bpl_ma ///
preH_bpl_eu ///
preH_bpl_cee ///
preH_bpl_ee ///
preH_bpl_se ///
preH_bpl_we ///
preH_bpl_ne ///
preH_bpl_ir ///
preH_bpl_ca ///
preH_mbpl_us ///
preH_mbpl_ma ///
preH_mbpl_eu ///
preH_mbpl_cee ///
preH_mbpl_ee ///
preH_mbpl_se ///
preH_mbpl_we ///
preH_mbpl_ne ///
preH_mbpl_ir ///
preH_mbpl_ca ///
preH_fbpl_us ///
preH_fbpl_ma ///
preH_fbpl_eu ///
preH_fbpl_cee ///
preH_fbpl_ee ///
preH_fbpl_se ///
preH_fbpl_we ///
preH_fbpl_ne ///
preH_fbpl_ir ///
preH_fbpl_ca ///
preH_gen1_immg ///
preH_gen1_immg_se ///
preH_gen1_immg_ee ///
preH_gen2_immg ///
preH_gen2_immg_ee ///
preH_gen2_immg_se ///
preH_mt_yjh_wm ///
preH_mt_yjh ///
preH_mt_noteng_wm ///
preH_mt_noteng ///
preH_lit_clean ///
preH_lit_adult ///
preH_fhead ///
preH_farm_clean ///
preH_occscore_clean ///
preH_edscor50_clean ///
preH_erscor50_clean ///
preH_has_cen_occ ///
preH_cen_fin_any ///
preH_cen_mng_any ///
preH_cen_sci ///
preH_cen_hed ///
preH_cen_art ///
preH_cen_doc ///
preH_cen_law ///
preH_cen_tch ///
preH_byear ///
preH_men2536 ///
preH_prime_age_m ///
preH_ed ///
preH_ed_year ///
preH_serial_year ///
preH_hs_serial_year ///
preH_N_bdr ///
preH_d_bdr ///
preH_N_rel ///
preH_d_rel ///
preH_f_ocscor ///
preH_f_edscor ///
preH_f_erscor ///
preH_f_cen_fin_any ///
preH_f_cen_mng_any ///
preH_f_cen_sci ///
preH_f_cen_hed ///
preH_f_cen_art ///
preH_f_cen_tch ///
preH_father_present ///
has_census191030 ///
has_census1900 ///
has_census1910 ///
has_census1920 ///
has_census1930 ///
has_census1940_2035 ///
has_census ///
harvard_2033 ///
gen1_immg_ir ///
preH_gen1_immg_ir ///
gen2_immg_ir ///
preH_gen2_immg_ir ///
comb_gen1_immg ///
comb_gen2_immg ///
comb_gen12_immg ///
comb_gen1_immg_ee ///
comb_gen2_immg_ee ///
comb_gen12_immg_ee ///
comb_gen1_immg_se ///
comb_gen2_immg_se ///
comb_gen12_immg_se ///
comb_gen1_immg_ir ///
comb_gen2_immg_ir ///
comb_gen12_immg_ir ///
comb_gen1_immg_eese ///
comb_gen1_immg_irse ///
comb_gen2_immg_eese ///
comb_gen2_immg_irse ///
comb_gen12_immg_irse ///
comb_gen12_immg_not ///
any_fc_hasty ///
fc_hasty_nottier2 ///
namemiflag ///
spousenamelast ///
spousenamefrst ///
spousenamemiflag ///
harvard_fnindex ///
pf_fnindex ///
pf_lnindex_spouse ///
spouse_sex ///
fncount_spouse ///
jewish_fnindex_spouse ///
cath_fnindex_spouse ///
harvard_lnindex ///
pf_lnindex ///
harvard_lnindex_spouse ///
lncount_spouse ///
harvard_index ///
pf_index ///
jewish_index_spouse ///
cath_index_spouse ///
harvard_index_spouse ///
pf_index_spouse ///
zdist_p50_valueh ///
zdist_p50_incwage ///
zincwage1940_clean ///
inressample ///
_harvardmerge

label var rblock_sample "Randomized"
label var fc_nottier2 "Less selective final club"
label var zphat_uac "Upper-year club index"
label var has_census1940_2033 "Cen 1940 (1920-33)"
label var has_census1940_2030 "1940 Census"
label var has_census_preH "Have Census pre-Harvard"
label var col41940 "Yrs. of col. $4+$"
label var col51940 "Yrs. of col. $5+$"
label var school1940_clean "In school"
label var lfp1940 "In labor force"
label var nonfarm_selfemp1940 "Non-farm self emp."
label var farm1940_clean  "Farm"
label var incwage1940_clean "Wage income" // (\$)" stata does not print the escape character in the tables
label var topincwg1940 "Wage inc. $5000+$" // \$" stata does not print the escape character in the tables
label var poswage1940 "Has wage income"
label var incnonwg1940_clean "Non-wage inc. $50+$" // \$ stata does not print the escape character in the tables
label var rent1940_head "Monthly rent if head"
label var dmetro_cc "Central city"
label var dist_N_men2737 "Dist. N men 27-37"
label var dist_share_harvard "Dist. share Harvard"
label var dist_share_col41940 "Dist. share college 4+"
label var dist_p50_incwage "Dist. 50p wage income"
label var dist_p90_incwage "Dist. 90p wage income"
label var dist_share_topincwg1940 "Dist. share wage $5000+$"
label var dist_p50_valueh "Dist. 50p home value"
label var dist_p90_valueh "Dist. 90p home value"
label var dist_p50_rent "Dist. 50p rent"
label var dist_p90_rent "Dist. 90p rent"
label var dist_share_nonfarm_selfemp1940 "Dist. share non-farm self emp."
label var dist_share_farm1940_clean  "Dist. share farm"
label var men2737 "Men 27-37"
label var men2737_c1 "Men 27-37 w/ col. $1+$"
label var men2737_c4 "Men 27-37 w/ col. $4+$"
label var harvard "Harvard"
label var head "Household head"
label var comb_gen12_immg_eese "S or E Eur. immg. gen. 1-2"
label var preH_f_has_cen_occ "Have father's occupation" // have father occ among all with preH census matches (not just those with a father present)
label var preH_N_emp "N servants"
label var preH_d_emp "Any servants"
label var preH_f_cen_doc "Father's occupation: doctor" 
label var preH_f_cen_law "Father's occupation: lawyer"
label var cen_doc "Cen. Occ.: Doc."
label var cen_law "Cen. Occ.: Law."
label var cen_tch "Cen. Occ.: Tch."
label var jewish_index "Jewish name index"
label var cath_index "Catholic name index"
label var oldMA_lnindex "Colonial name index"
label var histid1900 "Historical ID (1900)"
label var histid1910 "Historical ID (1910)"
label var histid1920 "Historical ID (1920)"
label var histid1930 "Historical ID (1930)"
label var histid1940 "Historical ID (1940)"
label var dist_share_dp95_valueh "Dist. share 95p men 25-36 house value"
label var preH_ownershp_clean "Home owner before Harvard"
label var namelast "Census last name"
label var namefrst "Census first name"
label var fncount "Count of first name in Census"
label var jewish_fnindex "Jewish first name index"
label var cath_fnindex "Catholic first name index"
label var lncount "Count of last name in Census"
label var jewish_lnindex "Jewish last name index"
label var cath_lnindex "Catholic last name index"
label var jewish_lnindex_spouse "Spouse Jewish last name index"
label var cath_lnindex_spouse "Spouse Catholic last name index"
label var oldMA_lnindex_spouse "Spouse colonial name index"
label var hs_wm "High school code (including missing)"
label var ownershp1940_clean "Home owned"
label var ownershp1940_head "Own home"
label var valueh1940_head "Home value if head"
label var dist_share_incnonwg1940_clean "Dist. share non-wage inc. $50+$"