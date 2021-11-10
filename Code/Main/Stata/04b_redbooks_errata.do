/*

04b_redbooks_errata.do
(called from 04_clean_redbooks.do)

Purpose: hard-codes fixes to Red Books
Inputs: N/A
Outputs: N/A

*/

** George Smith ** 
replace roomno = "A 22" if roomno=="A 82" ///
	& dorm == "George Smith" & class==1924 & name=="Dubois, John Delafield" // photo has error; found on HCS

** Gore **
replace roomno = "D 34" if roomno == "20 D 34" ///
	& dorm == "Gore" & class==1924 & name=="Cabon, Nelson" // obvious fix
	
replace roomno = "C 42" if roomno == "42" ///
	& dorm == "Gore" & class==1924 & name=="Scheffreen, Bertram Fogel" // photo

replace roomno = "A 31" if roomno == ": A 31" ///
	& dorm == "Gore" & class==1924 & name=="Davies, Stedman Cory" // obvious
	
replace roomno = "B 33" if roomno == "B 83" ///
	& dorm == "Gore" & class==1924 & name=="Newhall, Campbell"	// photo

replace roomno = "C 34" if roomno == "C 84" ///
	& dorm == "Gore" & class==1924 & name=="Childs, Ralph Desoneri"	// photo	

replace roomno = "E 11" if roomno == "E Ll" ///
	& dorm == "Gore" & class==1926 & name=="Jones, Richard, 3d"	// photo	

replace roomno = "E 23" if roomno == "E23" ///
	& dorm == "Gore" & class==1926 & name=="Walcott, Charles Folsom" // obvious

replace roomno = "C 21" if roomno == "C 2L" ///
	& dorm == "Gore" & class==1927 & name=="Gates, John Monteith"	// photo
	
replace roomno = "D 43" if roomno == "D 48" ///
	& dorm == "Gore" & class==1927 & name=="Hawkes, Richard Sylvester"	// photo

replace roomno = "D 41" if roomno == "D41" ///
	& dorm == "Gore" & class==1931 & name=="Rowe, Carl Sherman"	// photo
	
replace roomno = "C 41" if roomno == "C 14" ///
	& dorm == "Gore" & class==1932 & name=="Wheelwright, Warren Lombard"	// photo

replace roomno = "D 22" if roomno == "" ///
	& dorm == "Gore" & class==1933 & name=="James Sachs Plaut"	// photo
	
** James Smith **
replace roomno = "B 42" if roomno == "6 42" ///
	& dorm == "James Smith" & class==1924 & name=="Cromwell, Seymour Bryant"	// photo

replace roomno = "B 14" if roomno == "B I4" ///
	& dorm == "James Smith" & class==1924 & name=="Brown, Stanley Noël"	// photo
	
replace roomno = "A 42" if roomno == "A 44" ///
	& dorm == "James Smith" & class==1927 & name=="Ellison, William Partridge"	// photo

replace roomno = "B 42" if roomno == "B 42`" ///
	& dorm == "James Smith" & class==1931 & name=="Winkley, Prescott"	// obvious
	
replace roomno = "B 42" if roomno == "" ///
	& dorm == "James Smith" & class==1932 & name=="Pierce, Carl Dale"	// photo	
	
** McKinlock **	
* found no errors -- all "errors" are rooms that don't exist. typos in redbooks?

** Persis Smith **
replace roomno = "A 22" if roomno == "A 2" ///
	& dorm == "Persis Smith" & class==1924 & name=="Dubois, John Kzekiel"	// photo

replace roomno = "B 12" if roomno == "B I2" ///
	& dorm == "Persis Smith" & class==1924 & name=="Carpenter, George Benjamin"	// photo

replace roomno = "C 13" if roomno == "C 18" ///
	& dorm == "Persis Smith" & class==1928 & name=="Howland, John Phelips"	// photo

replace roomno = "B 51" if roomno == "R 51" ///
	& dorm == "Persis Smith" & class==1928 & name=="Carlson, Oscar Rudolph"	// photo

replace roomno = "B 33" if roomno == "B 83" ///
	& dorm == "Persis Smith" & class==1929 & name=="Lobred, James Isenberg"	// photo	

replace roomno = "A 11" if roomno == "A11" ///
	& dorm == "Persis Smith" & class==1931 & name=="Barry, Samuel"	// obvious	

replace roomno = "A 31" if roomno == "A31" ///
	& dorm == "Persis Smith" & class==1933 & name=="Joseph Shack"	// obvious
	
** Shepherd **
replace roomno = "B 21" if roomno == "21 B" ///
	& dorm == "Shepherd" & class==1931 & name=="Yamaguchi, Kyoshi"	// obvious	

replace roomno = "B 21" if roomno == "21 B" ///
	& dorm == "Shepherd" & class==1932 & name=="Jameson, Robert Ulrich"	// obvious	
	
** Standish **
replace roomno = "E 41" if roomno == "E41" ///
	& dorm == "Standish" & class==1924 & name=="Noble, Gilbert Wright"	

replace roomno = "E 13" if roomno == "E 18" ///
	& dorm == "Standish" & class==1924 & name=="Graff, David Jefferson"
	
replace roomno = "A 31" if roomno == "A 81" ///
	& dorm == "Standish" & class==1928 & name=="Fox, John Bayley"
	
replace roomno = "A 31" if roomno == "A 81" ///
	& dorm == "Standish" & class==1929 & name=="Gubin, Leon Independence"
	
replace roomno = "C 33" if roomno == "C S3" ///
	& dorm == "Standish" & class==1929 & name=="Nathaniel Griffin Wetherbee"	
	
** Grays **
* make sure all #s are suite formatted, i.e., "9"->"9 10"
destring roomno , gen(rn_n) force
gen n1 = rn_n - 1 + mod(rn_n,2)
gen n2 = rn_n + mod(rn_n,2)
tostring n1 , replace force
tostring n2 , replace force
replace roomno = n1 + " " + n2 if dorm=="Grays" & !mi(rn_n)
drop n1 n2 rn_n

* individual error
replace roomno = "29 30" if roomno=="20 30" ///
	& dorm == "Grays" & class==1936 & name=="Leavitt Howard" // photo has error; found on HCS

** Wigglesworth **
* major errors - letter I coded as 1.
replace roomno = "I 11" if roomno=="1 11" & dorm == "Wigglesworth"
replace roomno = "I 12" if roomno=="1 12" & dorm == "Wigglesworth"
replace roomno = "I 21" if roomno=="1 21" & dorm == "Wigglesworth"
replace roomno = "I 22" if roomno=="1 22" & dorm == "Wigglesworth"
replace roomno = "I 31" if roomno=="1 31" & dorm == "Wigglesworth"
replace roomno = "I 32" if roomno=="1 32" & dorm == "Wigglesworth"
replace roomno = "I 32" if roomno=="1 32" & dorm == "Wigglesworth"

* individual
replace roomno = "H 31" if roomno=="H 3" ///
	& dorm == "Wigglesworth" & class==1937 & name=="Robert Rice" // found in photo

replace roomno = "A 21" if roomno=="A 2" ///
	& dorm == "Wigglesworth" & class==1938 & name=="Le Roy King Smith" // found in photo
	
replace roomno = "I 11" ///
	if dorm == "Wigglesworth" & class==1938 & name=="John Langdon Foster" // had to look up on HCS
	
replace roomno = "H 21" ///
	if dorm == "Wigglesworth" & class==1939 & name=="George Edward Akerson, Jr." // found in photo
	
* this leaves one missing, roger pierce jr, room "32". not on HCS, photo doesn't have letter

** Thayer **
replace roomno = "50" if roomno=="30" & class==1936 & dorm=="Thayer" & ///
	name=="Richard Xavier Goggin" // found in photo
	
replace roomno = "31" if roomno=="81" & class==1939 & dorm=="Thayer" & ///
	name=="Richard Howard Sullivan" // found in photo
	
** Straus ** 
replace roomno = "D 22" if roomno=="S D 22" & class==1937 & dorm=="Straus" & ///
	name=="Chauncey Robert Southworth" // found in photo

replace roomno = "A 32" if roomno=="A 82" & class==1939 & dorm=="Straus" & ///
	name=="Leslie Ross Porter, Jr." // found in photo
	
** Massachusetts **
replace roomno = "8" if roomno=="" & class==1938 & dorm=="Massachusetts" & ///
	name=="Donald Shippee" // found in photo

** Holworthy **
replace roomno = "23" if roomno=="28" & class==1939 & dorm=="Holworthy" & ///
	name=="Arthur Hendricks Brooks, Jr." // found in photo

** Harvard Union **
replace roomno = "4" if roomno=="4 Hume Fogg High Nashville" & class==1939 & dorm=="Harvard Union" & ///
	name=="Burwell Baylor Wilkes 4th" // found in photo

** Weld **
replace roomno = "18" if roomno=="T8" & class==1935 & dorm=="Weld" & ///
	name=="Branford Price Millar" // found in photo	