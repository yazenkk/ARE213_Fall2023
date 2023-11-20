/*
Title: 		02_q1c.do
Purpose:	Question 1.c, PSet 3

Outline: 
c.i Which line-level controls does Assumption A1 compel us to include 
	(qk in the notation of the lecture)? 
c.ii Compute the city-level controls Qi corresponding to these qk. 
c.iii How many of them do you have and how do you interpret them? 
c.iv Intuitively, why is including these controls a good idea?

*/

/* ---------------------------------------------------------------------------
c.i Which line-level controls does Assumption A1 compel us to include 
	(qk in the notation of the lecture)? 
ANS: 
	We control for the number of cross-regional links. The exogeneity of the 
	a line opening by 2016 is more plausible within groups of cities that have 
	the same connectivity (priority) in the network.
	
	We also control for the number of lines planned to pass through city i. 
	It is also plausible that if a city has more lines (market access) planned, 
	then it is expected to grow more. Hence we compare within cells of priority
	on this measure as well.
*/

use "$dta_loc/pset3_lines", clear

// Check if nlinks == number of cities linked by line - 1
use "$dta_loc/pset3_stations", clear // city-line matrix
sort lineid cityid
collapse (count) cityct = cityid, by(lineid)
merge 1:1 lineid using "$dta_loc/pset3_lines"
assert _merge == 3
drop _merge
isid lineid
// br if cityct - 1 != nlinks // cityct by line is not exact same as nlinks
drop cityct // could be due to the line that was dropp prior to 2007

/* ---------------------------------------------------------------------------
c.ii Compute the city-level controls Qi corresponding to these qk. 
	Q_i = sum_k s_{ik} * q{k}
*/
use "$dta_loc/pset3_lines", clear
gen planned = open == 0
tempfile lines_dta
save 	`lines_dta'

// Get city-line matrix indicating which lines were open
// Transform v_k to V_i
use "$dta_loc/pset3_stations", clear // city-line matrix
merge m:1 lineid using "`lines_dta'", keepusing(nlinks planned) // merge open var
gen q_1 = 1 // constant
sort cityid lineid
assert _merge == 3
drop _merge
reshape wide nlinks planned q_1, i(cityid) j(lineid) // 
isid cityid
tempfile city_open_dta
save 	`city_open_dta'

// merge city_open_dta with cities data
use "$dta_loc/pset3_cities", clear
merge 1:1 cityid using `city_open_dta'
assert _merge != 2 // no line without a city 
drop _merge

// control 1
egen numberoflinks_i = rowtotal(nlinks*)
label var numberoflinks_i "nlinks at city level"
drop nlinks*
rename numberoflinks_i nlinks_i

// control 2
egen plines_i = rowtotal(planned*)
label var plines_i "number of '16 planned lines k that go through city i"
drop planned*

// control constant (sum of shares)
egen S_i = rowtotal(q_1*) // sum_k s_ik * q_1
label var S_i "Sum of shares city i (total lines open or planned)"
drop q_1*

corr plines_i nlinks_i // slight correlation

/*
We consider two controls, but a researcher could include more.
nlinks_i counts the number of cities that its lines when considered together 
link it to. One would expect cities that are better connected to have
better MA.
Similarly, plines captures the number of planned lines that link with a city. 
If a city has more planned lines, then it is expected to grow more and of
course have better market access.
*/
isid cityid
keep cityid nlinks_i plines_i S_i

// save
compress
save "$dta_loc/q1c_sol.dta", replace


