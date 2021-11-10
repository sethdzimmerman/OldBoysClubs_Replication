/*

01e_label_order.do
(called from 01_clean_redbooks.do)

Purpose: labels and orders variables
Inputs: N/A
Outputs: N/A

*/

label var class "Graduating class"
forv i = 1/3 {
	
	label var schoolcode`i' "High school code (`i')"
	label var schoolname`i' "High school name (`i')"
	label var private`i' "Private high school (`i')"
	label var public_feeder`i' "Public feeder high school (`i')"
	label var private_feeder`i' "Private feeder high school (`i')"
	
}
label var schoolcode1 "High school code (1)"
label var schoolname1 "High school name (1)"
label var private1 "Private high school (1)"
label var public_feeder1 "Public feeder high school (1)"
label var private_feeder1 "Private feeder high school (1)"
label var schoolcode2 "High school code (2)"
label var schoolname2 "High school name (2)"
label var private2 "Private high school (2)"
label var public_feeder2 "Public feeder high school (2)"
label var private_feeder2 "Private feeder high school (2)"
label var have_hs "Has high school code"
label var private "Private high school"
label var private_wm "Private highchool (including uncoded schools)"
label var private_feeder "Private feeder high school"
label var public_feeder "Public feeder high school"
label var has_pid "Has PID"
label var have_occ "Has occupation"
forv i = 1/9 {
	
	label var categorycode`i' "Occupation category code (`i')"
	label var subcategorycode`i' "Occupation subcategory code (`i')"
	label var category`i' "Occupation category (`i')"
	label var subcategory`i' "Occupation subcategory (`i')"
	
}
label var finance "Occupation: finance"
label var doctor "Occupation: medicine"
label var law "Occupation: law"
label var bus "Occupation: business"
label var manage_high "Occupation: senior management"
label var manage_low "Occupation: low management"
label var hed "Occupation: higher education"
label var teach "Occupation: teacher"
label var gov "Occupation: government"
label var art_pub "Occupation: art/publishing"
label var engineer "Occupation: engineering"
label var sci "Occupation: science"
label var bookkeep "Occupation: accounting"
label var bus_agg "Occupation: other business"
label var occupation "Occupation"
label var publications "Publications"
label var pub_or_patent "Occupation: publishing or patents"
label var spousename "Spouse name"
label var married "Married"
label var male "Male"
label var year "Freshman year"
label var have_hs_rec "Has high school record"
label var private_other "Other private high school"
label var nonfeeder "Nonfeeder high school"
label var cr_year "Year has class reports"
label var class_bin "Class year (rounded to half decade)"
label var finance_ext "Occupation: finance (including firms)"
label var tech "Occupation: tech"
label var consulting "Occupation: consulting"
label var consulting_ext "Occupation: consulting (including firms)"
label var law_ext "Occupation: law (including LLP)"
label var degree_str "Degree"
label var degree "Degree type"
label var degree_year "Year of degree"
label var honors "Student honors"
label var have_degree "Has degree"
label var harvard_degree "Has Harvard degree"
label var any_prof_grad "Has professional graduate degree"
label var any_other_grad "Has other graduate degree"
label var have_honors "Has academic honors"
label var summa_cum "Summa cum laude"
label var magna_cum "Magna cum laude"
label var magna_summa "High honors"
label var other_laude "Other academic honors"
label var grad_degrees "Graduate degrees"
label var phd_grad "PhD"
label var md_grad "MD"
label var jd_grad "JD/LLB"
label var mba_grad "MBA"
label var have_race "Has race info" 
label var ad_club "In A.D. club"
label var white "White"
label var white_non_hisp "Non-hispanic White"
label var non_white "Non white"
label var black "Black"
label var black_non_hisp "Non-hispanic Black"
label var hispanic "Hispanic"
label var asian "Asian"
label var hispanic_sn "Hispanic surname"
label var asian_sn "Asian surname" 
label var black_sn "Black surname" 

order index ///
name ///
first ///
middle ///
last ///
gender ///
male ///
white ///
non_white ///
black ///
hispanic ///
asian ///
have_race ///
white_non_hisp ///
black_non_hisp ///
hispanic_sn ///
asian_sn ///
black_sn ///
year ///
class ///
class_bin ///
photo ///
page ///
home_address ///
have_hs_rec ///
have_hs ///
high_school ///
schoolcode1 ///
schoolname1 ///
private1 ///
public_feeder1 ///
private_feeder1 ///
schoolcode2 ///
schoolname2 ///
private2 ///
public_feeder2 ///
private_feeder2 ///
schoolcode3 ///
schoolname3 ///
private3 ///
public_feeder3 ///
private_feeder3 ///
private ///
private_wm ///
private_feeder ///
private_other ///
public_feeder ///
nonfeeder ///
college_address ///
intended_major ///
activities ///
has_pid ///
pid ///
cr_year ///
have_degree ///
degree_str ///
degree ///
degree_year ///
harvard_degree ///
ad_club ///
have_honors ///
honors ///
summa_cum ///
magna_cum ///
magna_summa ///
other_laude ///
any_prof_grad ///
any_other_grad ///
grad_degrees ///
phd_grad ///
md_grad ///
jd_grad ///
mba_grad ///
have_occ ///
occupation ///
category1 ///
categorycode1 ///
subcategory1 ///
subcategorycode1 ///
category2 ///
categorycode2 ///
subcategory2 ///
subcategorycode2 ///
category3 ///
categorycode3 ///
subcategory3 ///
subcategorycode3 ///
category4 ///
categorycode4 ///
subcategory4 ///
subcategorycode4 ///
category5 ///
categorycode5 ///
subcategory5 ///
subcategorycode5 ///
category6 ///
categorycode6 ///
subcategory6 ///
subcategorycode6 ///
category7 ///
categorycode7 ///
subcategory7 ///
subcategorycode7 ///
category8 ///
categorycode8 ///
subcategory8 ///
subcategorycode8 ///
category9 ///
categorycode9 ///
subcategory9 ///
subcategorycode9 ///
finance ///
finance_ext ///
doctor ///
law ///
bus ///
manage_high ///
manage_low ///
hed ///
teach ///
gov ///
art_pub ///
engineer ///
sci ///
bookkeep ///
tech ///
consulting ///
consulting_ext ///
bus_agg ///
pub_or_patent ///
law_ext ///
publications ///
married ///
spousename