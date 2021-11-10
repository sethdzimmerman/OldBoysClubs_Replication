/*

04g_label_order.do
(called from 04_clean_redbooks.do)

Purpose: labels and orders variables
Inputs: N/A
Outputs: N/A

*/

label var class "Graduating class"
label var dorm "Dorm name"
label var havedorm "Has a dorm"
label var roomno "Room number (string)"
label var state "Home state"
label var country "Home country"
label var from_MA "From Massachusetts"
label var from_NY "From New York"
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
label var occupation_intended "Intended occupation"
forv i = 1/3 {
	
	label var categorycode_intended`i' "Intended occupation category code (`i')"
	label var subcategorycode_intended`i' "Intended occupation subcategory code (`i')"
	label var category_intended`i' "Intended occupation category (`i')"
	label var subcategory_intended`i' "Intended occupation subcategory (`i')"
	
}
label var finance "Occupation: finance"
label var doctor "Occupation: medicine"
label var law "Occupation: law"
label var bus "Occupation: business"
label var manage_high "Occupation: senior management"
label var manage_low "Occupation: low management"
label var hed "Occupation: higher education"
label var hed_ext "Occupation: higher education (extended)"
label var teach "Occupation: teacher"
label var gov "Occupation: government"
label var art_pub "Occupation: art/publishing"
label var engineer "Occupation: engineering"
label var sci "Occupation: science"
label var bookkeep "Occupation: accounting"
label var finance_intended "Intended occupation: finance"
label var doctor_intended "Intended occupation: medicine"
label var law_intended "Intended occupation: law"
label var bus_intended "Intended occupation: business"
label var manage_high_intended "Intended occupation: senior management"
label var manage_low_intended "Intended occupation: low management"
label var hed_intended "Intended occupation: higher education"
label var hed_ext_intended "Intended occupation: higher education (extended)"
label var teach_intended "Intended occupation: teacher"
label var gov_intended "Intended occupation: government"
label var art_pub_intended "Intended occupation: art/publishing"
label var engineer_intended "Intended occupation: engineering"
label var sci_intended "Intended occupation: science"
label var bookkeep_intended "Intended occupation: accounting"
label var bus_agg "Occupation: other business"
label var occupation "Occupation"
label var publications "Publications"
label var pub_or_patent "Occupation: publishing or patents"
label var college_major "College major"
label var have_major "Has major"
forv i = 1/3 {
	
	label var majorcategorycode`i' "Major category code (`i')"
	label var majorsubcategorycode`i' "Major subcategory code (`i')"
	label var majorcategory`i' "Major category (`i')"
	label var majorsubcategory`i' "Major subcategory (`i')"
	
}
label var econ_major "Major: economics"
label var stem_major "Major: STEM/engineering"
label var humanities_major "Major: humanities"
label var social_science_major "Major: social science"
label var coarse_major "Category of major"
label var double_major "Double majored"
forv i = 1/20 {
	
	label var clubcode`i' "Club code (`i')"
	label var social_club`i' "Social club (`i')"
	label var honorary_or_political`i' "Honorary or political club (`i')"
	label var gent_club`i' "Gentleman's club (`i')"
	label var country_club`i' "Country club (`i')"
	label var frat_order`i' "Fraternity (`i')"
	label var clubname`i' "Club name (`i')"
	
}
label var have_gent_club "Participated in gentleman's club" 
label var have_country_club "Participated in country club"
label var have_frat_order "Participated in fraternity"
label var any_social_main "Participated in adult social organization"
label var have_social_club "Participated in social club"
label var have_hon_club "Participated in honors club"
label var have_prof_assoc "Participated in professional association"
label var any_honor "Participated in honor or professional society"
forv i = 1/11 {
	
	label var accategorycode`i' "Activity category code (`i')"
	label var acsubcategorycode`i' "Activity subcategory code (`i')"
	label var activitycode`i' "Activity code (`i')"
	label var acCategory`i' "Activity category (`i')"
	label var acSubcategory`i' "Activity subcategory (`i')"
	label var ActivityTitle`i' "Activity name (`i')"
	label var hac_`i' "Has activity (`i')"
	
}
label var have_ac "Has any activity"
label var nac "Number of activities"
label var dorm_com "Participated in dorm committee"
label var sports "Participated in sports activity"
label var music "Participated in music activity"
label var redbook "Participated in Red Books activity"
label var language "Participated in language activity"
label var social "Participated in social activity"
label var outdoors "Participated in outdoors activity"
label var politics "Participated in politics activity"
label var stem "Participated in STEM activity"
label var drama "Participated in drama activity"
label var pubs "Participated in publishing activity"
label var jewish "Participated in Jewish activity"
label var military "Participated in military activity"
label var hs_club "Participated in high school activity"
label var other_club "Participated in other club"
label var catholic_club "Participated in Catholic club"
label var jewish_club "Participated in Jewish club"
label var christian_club "Participated in Christian club"
label var rowing "Participated in rowing"
label var track "Participated in track"
label var football "Participated in football"
label var baseball "Participated in baseball"
label var basketball "Participated in basketball"
label var hockey "Participated in hockey"
label var soccer "Participated in soccer"
label var lacrosse "Participated in lacrosse"
label var university_sport "Participated in university sport"
label var intramural_sport "Participated in intramural sport"
label var other_sport "Participated in other sport"
label var aclead "Has activity leadership position"
label var family_id "Family ID (from Class Reports)"
label var harvard_brother "Has brother from Harvard"
label var harvard_father "Has father from Harvard"
label var spousename "Spouse name"
label var married "Married"
label var major_year "Major is available freshman year"
label var observed_roomcap "Room capacity (used for merging)"

order index ///
name ///
first ///
middle ///
last ///
gender ///
year ///
class ///
photo ///
page ///
family_id ///
home_address ///
state ///
country ///
from_MA ///
from_NY ///
harvard_brother ///
harvard_father ///
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
private ///
private_wm ///
private_feeder ///
public_feeder ///
college_address ///
havedorm ///
dorm ///
roomno ///
observed_roomcap ///
clubname1 ///
clubcode1 ///
social_club1 ///
honorary_or_political1 ///
gent_club1 ///
country_club1 ///
frat_order1 ///
clubname2 ///
clubcode2 ///
social_club2 ///
honorary_or_political2 ///
gent_club2 ///
country_club2 ///
frat_order2 ///
clubname3 ///
clubcode3 ///
social_club3 ///
honorary_or_political3 ///
gent_club3 ///
country_club3 ///
frat_order3 ///
clubname4 ///
clubcode4 ///
social_club4 ///
honorary_or_political4 ///
gent_club4 ///
country_club4 ///
frat_order4 ///
clubname5 ///
clubcode5 ///
social_club5 ///
honorary_or_political5 ///
gent_club5 ///
country_club5 ///
frat_order5 ///
clubname6 ///
clubcode6 ///
social_club6 ///
honorary_or_political6 ///
gent_club6 ///
country_club6 ///
frat_order6 ///
clubname7 ///
clubcode7 ///
social_club7 ///
honorary_or_political7 ///
gent_club7 ///
country_club7 ///
frat_order7 ///
clubname8 ///
clubcode8 ///
social_club8 ///
honorary_or_political8 ///
gent_club8 ///
country_club8 ///
frat_order8 ///
clubname9 ///
clubcode9 ///
social_club9 ///
honorary_or_political9 ///
gent_club9 ///
country_club9 ///
frat_order9 ///
clubname10 ///
clubcode10 ///
social_club10 ///
honorary_or_political10 ///
gent_club10 ///
country_club10 ///
frat_order10 ///
clubname11 ///
clubcode11 ///
social_club11 ///
honorary_or_political11 ///
gent_club11 ///
country_club11 ///
frat_order11 ///
clubname12 ///
clubcode12 ///
social_club12 ///
honorary_or_political12 ///
gent_club12 ///
country_club12 ///
frat_order12 ///
clubname13 ///
clubcode13 ///
social_club13 ///
honorary_or_political13 ///
gent_club13 ///
country_club13 ///
frat_order13 ///
clubname14 ///
clubcode14 ///
social_club14 ///
honorary_or_political14 ///
gent_club14 ///
country_club14 ///
frat_order14 ///
clubname15 ///
clubcode15 ///
social_club15 ///
honorary_or_political15 ///
gent_club15 ///
country_club15 ///
frat_order15 ///
clubname16 ///
clubcode16 ///
social_club16 ///
honorary_or_political16 ///
gent_club16 ///
country_club16 ///
frat_order16 ///
clubname17 ///
clubcode17 ///
social_club17 ///
honorary_or_political17 ///
gent_club17 ///
country_club17 ///
frat_order17 ///
clubname18 ///
clubcode18 ///
social_club18 ///
honorary_or_political18 ///
gent_club18 ///
country_club18 ///
frat_order18 ///
clubname19 ///
clubcode19 ///
social_club19 ///
honorary_or_political19 ///
gent_club19 ///
country_club19 ///
frat_order19 ///
clubname20 ///
clubcode20 ///
social_club20 ///
honorary_or_political20 ///
gent_club20 ///
country_club20 ///
frat_order20 ///
have_social_club ///
have_hon_club ///
have_gent_club ///
have_country_club ///
have_frat_order ///
have_prof_assoc ///
any_social_main ///
activities ///
any_honor ///
hac_1 ///
ActivityTitle1 ///
activitycode1 ///
acCategory1 ///
accategorycode1 ///
acSubcategory1 ///
acsubcategorycode1 ///
hac_2 ///
ActivityTitle2 ///
activitycode2 ///
acCategory2 ///
accategorycode2 ///
acSubcategory2 ///
acsubcategorycode2 ///
hac_3 ///
ActivityTitle3 ///
activitycode3 ///
acCategory3 ///
accategorycode3 ///
acSubcategory3 ///
acsubcategorycode3 ///
hac_4 ///
ActivityTitle4 ///
activitycode4 ///
acCategory4 ///
accategorycode4 ///
acSubcategory4 ///
acsubcategorycode4 ///
hac_5 ///
ActivityTitle5 ///
activitycode5 ///
acCategory5 ///
accategorycode5 ///
acSubcategory5 ///
acsubcategorycode5 ///
hac_6 ///
ActivityTitle6 ///
activitycode6 ///
acCategory6 ///
accategorycode6 ///
acSubcategory6 ///
acsubcategorycode6 ///
hac_7 ///
ActivityTitle7 ///
activitycode7 ///
acCategory7 ///
accategorycode7 ///
acSubcategory7 ///
acsubcategorycode7 ///
hac_8 ///
ActivityTitle8 ///
activitycode8 ///
acCategory8 ///
accategorycode8 ///
acSubcategory8 ///
acsubcategorycode8 ///
hac_9 ///
ActivityTitle9 ///
activitycode9 ///
acCategory9 ///
accategorycode9 ///
acSubcategory9 ///
acsubcategorycode9 ///
hac_10 ///
ActivityTitle10 ///
activitycode10 ///
acCategory10 ///
accategorycode10 ///
acSubcategory10 ///
acsubcategorycode10 ///
hac_11 ///
ActivityTitle11 ///
activitycode11 ///
acCategory11 ///
accategorycode11 ///
acSubcategory11 ///
acsubcategorycode11 ///
have_ac ///
nac ///
dorm_com ///
sports ///
music ///
redbook ///
language ///
social ///
outdoors ///
politics ///
stem ///
drama ///
pubs ///
jewish ///
military ///
hs_club ///
other_club ///
catholic_club ///
jewish_club ///
christian_club ///
rowing ///
track ///
football ///
baseball ///
basketball ///
hockey ///
soccer ///
lacrosse ///
university_sport ///
intramural_sport ///
other_sport ///
aclead ///
have_major ///
college_major ///
major_year ///
majorcategory1 ///
majorcategorycode1 ///
majorsubcategory1 ///
majorsubcategorycode1 ///
majorcategory2 ///
majorcategorycode2 ///
majorsubcategory2 ///
majorsubcategorycode2 ///
majorcategory3 ///
majorcategorycode3 ///
majorsubcategory3 ///
majorsubcategorycode3 ///
coarse_major ///
econ_major ///
stem_major ///
humanities_major ///
social_science_major ///
double_major ///
rankgroup1 ///
rankgroup3 ///
hasty ///
final_club ///
final_tier2 ///
has_senior_info ///
occupation_intended ///
have_occ_intended ///
occ_intended_year ///
category_intended1 ///
categorycode_intended1 ///
subcategory_intended1 ///
subcategorycode_intended1 ///
category_intended2 ///
categorycode_intended2 ///
subcategory_intended2 ///
subcategorycode_intended2 ///
category_intended3 ///
categorycode_intended3 ///
subcategory_intended3 ///
subcategorycode_intended3 ///
finance_intended ///
doctor_intended ///
law_intended ///
bus_intended ///
manage_high_intended ///
manage_low_intended ///
hed_intended ///
hed_ext_intended ///
teach_intended ///
gov_intended ///
art_pub_intended ///
engineer_intended ///
sci_intended ///
bookkeep_intended ///
has_pid ///
pid ///
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
doctor ///
law ///
bus ///
manage_high ///
manage_low ///
hed ///
hed_ext ///
teach ///
gov ///
art_pub ///
engineer ///
sci ///
bookkeep ///
bus_agg ///
pub_or_patent ///
unemp ///
publications ///
married ///
spousename