/*

04a_clean_home_address.do
(called from 04_clean_redbooks.do)

Purpose: assigns states, countries and regions based off home addresses
Inputs: N/A
Outputs: N/A


*/

cap drop state
gen state = ""

* Alabama
replace state = "AL" if strpos(home_address,"Alabama")>0
replace state = "AL" if strpos(home_address,"Ala.")>0
replace state = "AL" if strpos(home_address,"Al.")>0
replace state = "AL" if strpos(home_address,"A.L.")>0
replace state = "AL" if strpos(home_address,"A. L.")>0
replace state = "AL" if strpos(home_address,"Montgomery")>0

* Alaska
replace state = "AK" if strpos(home_address,"Alaska")>0
replace state = "AK" if strpos(home_address,"Alas.")>0
replace state = "AK" if strpos(home_address,"Ak.")>0
replace state = "AK" if strpos(home_address,"A. K.")>0
replace state = "AK" if strpos(home_address,"Anchorage")>0

* Arizona
replace state = "AZ" if strpos(home_address,"Arizona")>0
replace state = "AZ" if strpos(home_address,"Ariz.")>0
replace state = "AZ" if strpos(home_address,"Az.")>0
replace state = "AZ" if strpos(home_address,"A.Z.")>0
replace state = "AZ" if strpos(home_address,"A. Z.")>0
replace state = "AZ" if strpos(home_address,"Phoenix")>0

* Arkansas
replace state = "AR" if strpos(home_address,"Arkansas")>0
replace state = "AR" if strpos(home_address,"Ark.")>0
replace state = "AR" if strpos(home_address,"Ar.")>0
replace state = "AR" if strpos(home_address,"A.R.")>0
replace state = "AR" if strpos(home_address,"A. R.")>0
replace state = "AR" if strpos(home_address,"Little Rock")>0

* California
replace state = "CA" if strpos(home_address,"California")>0
replace state = "CA" if strpos(home_address,"Calif.")>0
replace state = "CA" if strpos(home_address,"Calif")>0
replace state = "CA" if strpos(home_address,"Cal.")>0
replace state = "CA" if strpos(home_address,"Ca.")>0
replace state = "CA" if strpos(home_address,"C.A.")>0
replace state = "CA" if strpos(home_address,"C. A.")>0
replace state = "CA" if strpos(home_address,"San Diego")>0
replace state = "CA" if strpos(home_address,"Los Angeles")>0
replace state = "CA" if strpos(home_address,"San Fran")>0
replace state = "CA" if strpos(home_address,"Santa Barbara")>0
replace state = "CA" if strpos(home_address,"Sacramento")>0

* Colorado
replace state = "CO" if strpos(home_address,"Colorado")>0
replace state = "CO" if strpos(home_address,"Colo.")>0
replace state = "CO" if strpos(home_address,"Col.")>0
replace state = "CO" if strpos(home_address,"Co.")>0
replace state = "CO" if strpos(home_address,"C.O.")>0
replace state = "CO" if strpos(home_address,"C. O.")>0
replace state = "CO" if strpos(home_address,"Denver")>0

* Connecticut
replace state = "CT" if strpos(home_address,"Connecticut")>0
replace state = "CT" if strpos(home_address,"Conn")>0
replace state = "CT" if strpos(home_address,"Ct.")>0
replace state = "CT" if strpos(home_address,"C.T.")>0
replace state = "CT" if strpos(home_address,"C. T.")>0
replace state = "CT" if strpos(home_address,"New Haven")>0

* Delaware
replace state = "DE" if strpos(home_address,"Delaware")>0
replace state = "DE" if strpos(home_address,"Del.")>0
replace state = "DE" if strpos(home_address,"De.")>0
replace state = "DE" if strpos(home_address,"D.E.")>0
replace state = "DE" if strpos(home_address,"D. E.")>0
replace state = "DE" if strpos(home_address,"Wilmington")>0

* Washington DC
replace state = "DC" if strpos(home_address,"Washington D.C.")>0		
replace state = "DC" if strpos(home_address,"Wash. D.C.")>0		
replace state = "DC" if strpos(home_address,"D.C.")>0
replace state = "DC" if strpos(home_address,"D. C.")>0		
replace state = "DC" if strpos(home_address,"DC")>0		

* Florida
replace state = "FL" if strpos(home_address,"Florida")>0
replace state = "FL" if strpos(home_address,"Fla.")>0
replace state = "FL" if strpos(home_address,"Flor.")>0
replace state = "FL" if strpos(home_address,"Fl.")>0
replace state = "FL" if strpos(home_address,"F.L.")>0
replace state = "FL" if strpos(home_address,"F. L.")>0
replace state = "FL" if strpos(home_address,"Tampa")>0
replace state = "FL" if strpos(home_address,"Miami")>0
replace state = "FL" if strpos(home_address,"Orlando")>0

* Georgia
replace state = "GA" if strpos(home_address,"Georgia")>0
replace state = "GA" if strpos(home_address,"Geo.")>0
replace state = "GA" if strpos(home_address,"Ga.")>0
replace state = "GA" if strpos(home_address,"G.A.")>0
replace state = "GA" if strpos(home_address,"G. A.")>0
replace state = "GA" if strpos(home_address,"Atlanta")>0

* Hawaii
replace state = "HI" if strpos(home_address,"Hawaii")>0
replace state = "HI" if strpos(home_address,"H.I.")>0
replace state = "HI" if strpos(home_address,"Honolulu")>0

* Idaho 
replace state = "ID" if strpos(home_address,"Idaho")>0
replace state = "ID" if strpos(home_address,"Ida.")>0
replace state = "ID" if strpos(home_address,"Id.")>0
replace state = "ID" if strpos(home_address,"I.D.")>0
replace state = "ID" if strpos(home_address,"I. D.")>0
replace state = "ID" if strpos(home_address,"Boise")>0

* Illinois
replace state = "IL" if strpos(home_address,"Illinois")>0
replace state = "IL" if strpos(home_address,"Ill.")>0
replace state = "IL" if strpos(home_address,"Il.")>0				
replace state = "IL" if strpos(home_address,"I.L.")>0				
replace state = "IL" if strpos(home_address,"I. L.")>0				
replace state = "IL" if strpos(home_address,"Chicago")>0		
replace state = "IL" if strpos(home_address,"111.")>0
replace state = "IL" if strpos(home_address,"Joliet")>0
replace state = "IL" if strpos(home_address,"Elgin")>0

* Indiana
replace state = "IN" if strpos(home_address,"Indiana")>0
replace state = "IN" if strpos(home_address,"Ind.")>0
replace state = "IN" if strpos(home_address,"In.")>0
replace state = "IN" if strpos(home_address,"I.N.")>0
replace state = "IN" if strpos(home_address,"I. N.")>0
replace state = "IN" if strpos(home_address,"Indianapolis")>0

* Iowa
replace state = "IA" if strpos(home_address,"Iowa")>0
replace state = "IA" if strpos(home_address,"Ioa.")>0
replace state = "IA" if strpos(home_address,"Ia.")>0
replace state = "IA" if strpos(home_address,"I.A.")>0
replace state = "IA" if strpos(home_address,"Des Moines")>0
replace state = "IA" if strpos(home_address,"Davenport")>0
replace state = "IA" if strpos(home_address,"Cedar Rapids")>0

* Kansas
replace state = "KS" if strpos(home_address,"Kansas")>0
replace state = "KS" if strpos(home_address,"Kans.")>0
replace state = "KS" if strpos(home_address,"Kan.")>0
replace state = "KS" if strpos(home_address,"Ka.")>0
replace state = "KS" if strpos(home_address,"Ks.")>0
replace state = "KS" if strpos(home_address,"K.S.")>0
replace state = "KS" if strpos(home_address,"K. S.")>0

* Kentucky
replace state = "KY" if strpos(home_address,"Kentucky")>0
replace state = "KY" if strpos(home_address,"Kent.")>0
replace state = "KY" if strpos(home_address,"Ken.")>0
replace state = "KY" if strpos(home_address,"Ky.")>0
replace state = "KY" if strpos(home_address,"Louisville")>0

* Louisiana
replace state = "LA" if strpos(home_address,"Louisiana")>0
replace state = "LA" if strpos(home_address,"La.")>0
replace state = "LA" if strpos(home_address,"New Orleans")>0

* Maine
replace state = "ME" if strpos(home_address,"Maine")>0
replace state = "ME" if strpos(home_address,"Me.")>0
replace state = "ME" if strpos(home_address,"Bangor")>0
replace state = "ME" if strpos(home_address,"Lewiston")>0
replace state = "ME" if strpos(home_address,"Augusta")>0

* Maryland
replace state = "MD" if strpos(home_address,"M.D.")>0
replace state = "MD" if strpos(home_address,"M. D.")>0				
replace state = "MD" if strpos(home_address,"Md")>0	
replace state = "MD" if strpos(home_address,"Maryland")>0	

* Massachusetts
replace state = "MA" if strpos(home_address,"Massachusetts")>0 
replace state = "MA" if strpos(home_address,"Mass")>0 
replace state = "MA" if strpos(home_address,"M.A.")>0 
replace state = "MA" if strpos(home_address,"M. A.")>0 
// MA people tend to list cities not state
foreach city in "Lynn" "Somerville" "Brookline" "Boston" "Cambridge" ///
				"Medford" "Ipswich" "Arlington" "Mattapan" "Roxbury" ///
				"Dorchester" "Worcester" "Springfield" "Quincy" "Framingham" ///
				"Wellesley" "Revere" "Newton" "Jamaica Plain" ///
				"Lowell" "Malden" "Marblehead" "Brockton" "Taunton" ///
				"Watertown" "Attleboro" "Salem" "Chelsea" "Andover" ///
				"Belmont" "Fairhaven" "Plymouth" "Holyoke" "Roslindale" ///
				"Weymouth" "Dedham" "Methuen" "Haverhill" "Lawrence" ///
				"Woburn" "Gloucester" "Norwood" "Duxbury" "Foxboro" ///
				"Lincoln" "Winthrop" "Boxborough" "Chestnut Hill" ///
				"Harvard" "Winchester" "Hingham" "Newburyport" "Melrose" ///
				"New Bedford" "Northhampton" "Natick" "Needham" ///
				"Wollaston" "Waltham" "Braintree" "Fall River" "Fitchburg" ///
				"Allston" {

				replace state = "MA" if strpos(home_address,"`city'")>0 & mi(state)
				
				}
				
* Michigan
replace state = "MI" if strpos(home_address,"Michigan")>0
replace state = "MI" if strpos(home_address,"Mich")>0
replace state = "MI" if strpos(home_address,"MI.")>0
replace state = "MI" if strpos(home_address,"M.I.")>0
replace state = "MI" if strpos(home_address,"Ann Arbor")>0
replace state = "MI" if strpos(home_address,"Detroit")>0

* Minnesota
replace state = "MN" if strpos(home_address,"Minnesota")>0		
replace state = "MN" if strpos(home_address,"Minn.")>0		
replace state = "MN" if strpos(home_address,"Duluth")>0		
replace state = "MN" if strpos(home_address,"St. Paul")>0
replace state = "MN" if strpos(home_address,"Minneapolis")>0

* Mississippi
replace state = "MS" if strpos(home_address,"Mississippi")>0
replace state = "MS" if strpos(home_address,"Miss.")>0

* Missouri
replace state = "MO" if strpos(home_address,"Missouri.")>0
replace state = "MO" if strpos(home_address,"Mo.")>0
replace state = "MO" if strpos(home_address,"St. Louis")>0
replace state = "MO" if strpos(home_address,"St, Louis")>0

* Montana
replace state = "MT" if strpos(home_address,"Montana")>0
replace state = "MT" if strpos(home_address,"Mont.")>0

* Nebraska
replace state = "NE" if strpos(home_address,"Nebraska")>0
replace state = "NE" if strpos(home_address,"Neb.")>0
replace state = "NE" if strpos(home_address,"Omaha")>0

* Nevada
replace state = "NE" if strpos(home_address,"Nevada")>0
replace state = "NE" if strpos(home_address,"Nv.")>0
replace state = "NE" if strpos(home_address,"Las Vegas")>0

* New Hampshire
replace state = "NH" if strpos(home_address,"New Hampshire")>0
replace state = "NH" if strpos(home_address,"N. H")>0
replace state = "NH" if strpos(home_address,"N.H.")>0
replace state = "NH" if strpos(home_address,"Concord")>0
replace state = "NH" if strpos(home_address,"Manchester")>0

* New Jersey
replace state = "NJ" if strpos(home_address,"New Jersey")>0
replace state = "NJ" if strpos(home_address,"N.J.")>0
replace state = "NJ" if strpos(home_address,"N. J.")>0
replace state = "NJ" if strpos(home_address,"N J.")>0

* New Mexico
replace state = "NM" if strpos(home_address,"New Mex")>0
replace state = "NM" if strpos(home_address,"N.M.")>0
replace state = "NM" if strpos(home_address,"N. M.")>0

* New York
replace state = "NY" if strpos(home_address,"New York")>0
replace state = "NY" if strpos(home_address,"N.Y")>0
replace state = "NY" if strpos(home_address,"N. Y")>0
replace state = "NY" if strpos(home_address,"N Y")>0
replace state = "NY" if strpos(home_address,"NY")>0
replace state = "NY" if strpos(home_address,"Long Island")>0
replace state = "NY" if strpos(home_address,"Brooklyn")>0
replace state = "NY" if strpos(home_address,"Buffalo")>0
replace state = "NY" if strpos(home_address,"Albany")>0
replace state = "NY" if strpos(home_address,"L.I.")>0
replace state = "NY" if strpos(home_address,"L. I.")>0
replace state = "NY" if strpos(home_address,"Flushing")>0
replace state = "NY" if strpos(home_address,"Queens")>0
replace state = "NY" if strpos(home_address,"Ny.")>0

* North Carolina
replace state = "NC" if strpos(home_address,"North Carolina")>0
replace state = "NC" if strpos(home_address,"N. C.")>0
replace state = "NC" if strpos(home_address,"N.C.")>0

* North Dakota
replace state = "ND" if strpos(home_address,"No. Dak")>0
replace state = "ND" if strpos(home_address,"North Dakota")>0
replace state = "ND" if strpos(home_address,"N. D.")>0
replace state = "ND" if strpos(home_address,"N.D.")>0

* Ohio
replace state = "OH" if strpos(home_address,"Ohio")>0
replace state = "OH" if strpos(home_address,"O.")>0	
replace state = "OH" if strpos(home_address,"Oh.")>0		
replace state = "OH" if strpos(home_address,"O.H.")>0												
replace state = "OH" if strpos(home_address,"Cleveland")>0		
replace state = "OH" if strpos(home_address,"leveland, O")>0		
replace state = "OH" if strpos(home_address,"Youngstown, O")>0		
replace state = "OH" if strpos(home_address,"Cincinnati")>0

* Oklahoma
replace state = "OK" if strpos(home_address,"Okla.")>0
replace state = "OK" if strpos(home_address,"Ok.")>0
replace state = "OK" if strpos(home_address,"Oklahoma")>0

* Oregon
replace state = "OR" if strpos(home_address,"Oregon")>0
replace state = "OR" if strpos(home_address,"Ore.")>0
replace state = "OR" if strpos(home_address,"Or.")>0

* Pennsylvania
replace state = "PA" if strpos(home_address,"Pennsyl")>0
replace state = "PA" if strpos(home_address,"Pa.")>0
replace state = "PA" if strpos(home_address,"P.A.")>0
replace state = "PA" if strpos(home_address,"Penn.")>0
replace state = "PA" if strpos(home_address,"Philadel")>0
replace state = "PA" if strpos(home_address,"Pittsbur")>0

* Rhode Island
replace state = "RI" if strpos(home_address,"Rhode Island")>0
replace state = "RI" if strpos(home_address,"R.I.")>0
replace state = "RI" if strpos(home_address,"R. I.")>0		
replace state = "RI" if strpos(home_address,"Providence")>0

* South Carolina
replace state = "SC" if strpos(home_address,"South Carolina")>0
replace state = "SC" if strpos(home_address,"S. C.")>0
replace state = "SC" if strpos(home_address,"S.C.")>0	

* South Dakota
replace state = "SD" if strpos(home_address,"South Dakota")>0
replace state = "SD" if strpos(home_address,"So. Dak")>0
replace state = "SD" if strpos(home_address,"S. D.")>0
replace state = "SD" if strpos(home_address,"S.D.")>0

* Tennessee
replace state = "TN" if strpos(home_address,"Tenn.")>0
replace state = "TN" if strpos(home_address,"Tn.")>0
replace state = "TN" if strpos(home_address,"Knoxville")>0
replace state = "TN" if strpos(home_address,"Nashville")>0

* Texas
replace state = "TX" if strpos(home_address,"Texas")>0
replace state = "TX" if strpos(home_address,"Tx.")>0
replace state = "TX" if strpos(home_address,"Tex.")>0

* Utah
replace state = "UT" if strpos(home_address,"Utah")>0
replace state = "UT" if strpos(home_address,"Ut.")>0
replace state = "UT" if strpos(home_address,"Salt Lake City")>0

* Vermont
replace state = "VT" if strpos(home_address,"VT")>0
replace state = "VT" if strpos(home_address,"V.T.")>0
replace state = "VT" if strpos(home_address,"Vt.")>0
replace state = "VT" if strpos(home_address,"Vermont")>0
replace state = "VT" if strpos(home_address,"Burlington")>0
replace state = "VT" if strpos(home_address,"Vt")>0	

* Virginia
replace state = "VA" if strpos(home_address,"Virginia")>0
replace state = "VA" if strpos(home_address,"Va.")>0
replace state = "VA" if strpos(home_address,"V.A.")>0

* Washington
replace state = "WA" if strpos(home_address,"Seattle")>0
replace state = "WA" if strpos(home_address,"Spokane")>0
replace state = "WA" if strpos(home_address,"Tacoma")>0
replace state = "WA" if strpos(home_address,"Washington")>0 & mi(state)
replace state = "WA" if strpos(home_address,"Wash")>0 & mi(state)

* West Virgina
replace state = "WA" if strpos(home_address,"West Virginia")>0
replace state = "WA" if strpos(home_address,"W. Vir")>0
replace state = "WA" if strpos(home_address,"W.V.")>0
replace state = "WA" if strpos(home_address,"W.Va.")>0
replace state = "WA" if strpos(home_address,"W. Va.")>0

* Wisconsin
replace state = "WI" if strpos(home_address,"Wisconsin")>0
replace state = "WI" if strpos(home_address,"Milwaukee")>0
replace state = "WI" if strpos(home_address,"Wis.")>0

* Wyoming
replace state = "WY" if strpos(home_address,"Wyoming")>0
replace state = "WY" if strpos(home_address,"Wyo.")>0
replace state = "WY" if strpos(home_address,"Laramie")>0

* PR
replace state = "PR" if strpos(home_address,"Porto Rico")>0
replace state = "PR" if strpos(home_address,"Puerto Rico")>0
replace state = "PR" if strpos(home_address,"P.R.")>0

* Guam
replace state = "PR" if strpos(home_address,"Guam")>0

* country
cap drop country
gen country = "USA" if !mi(state)
replace country = "FRA" if strpos(home_address,"France")>0
replace country = "FRA" if strpos(home_address,"Paris")>0
replace country = "UK" if strpos(home_address,"London")>0
replace country = "UK" if strpos(home_address,"England")>0
replace country = "UK" if strpos(home_address,"Scotland")>0
replace country = "UK" if strpos(home_address,"Glasgow")>0
replace country = "UK" if strpos(home_address,"Edinburgh")>0
replace country = "Cuba" if strpos(home_address,"Cuba")>0
replace country = "Barbados" if strpos(home_address,"Barbados")>0
replace country = "BRA" if strpos(home_address,"Brazil")>0
replace country = "CHN" if strpos(home_address,"China")>0
replace country = "KOR" if strpos(home_address,"Korea")>0
replace country = "CAN" if strpos(home_address,"Canad")>0
replace country = "SYR" if strpos(home_address,"Syria")>0
replace country = "PER" if strpos(home_address,"Peru")>0
replace country = "MEX" if strpos(home_address,"Mexico")>0
replace country = "JAP" if strpos(home_address,"Japan")>0
replace country = "JAP" if strpos(home_address,"Australia")>0
replace country = "MOR" if strpos(home_address,"Morocco")>0
replace country = "SWE" if strpos(home_address,"Sweden")>0
replace country = "NOR" if strpos(home_address,"Norway")>0
replace country = "NER" if strpos(home_address,"Holland")>0
replace country = "BER" if strpos(home_address,"Bermuda")>0
replace country = "BER" if strpos(home_address,"Bermuda")>0
replace country = "DEU" if strpos(home_address,"Germany")>0
replace country = "GT" if strpos(home_address,"Guatemala")>0
replace country = "ITA" if strpos(home_address,"Italy")>0

* misc geography variables
gen from_MA=state=="MA" if !mi(state)
gen from_NY=state=="NY" if !mi(state)