

/*
Title: 		02_q1a.do
Purpose:	Question 1.a, PSet 3

Outline: 
Represent ΔLinesi as a shift-share variable. 
	What are the exposure shares and what are the shocks? 
	How many shocks do you have? 
	Do the shares add up to one for each i? 
	Compute ΔLinesi for each city. 
	What is the mean, maximum, and the average of ΔLinesi across the 340 cities?
*/


// explore data
/*
use "$dta_loc/pset3_cities", clear // city characteristics
isid cityid

use "$dta_loc/pset3_distances", clear // distance between cities
use "$dta_loc/pset3_stations", clear // city-line matrix
use "$dta_loc/pset3_lines", clear // 
isid lineid

use "$dta_loc/china_data", clear // 
 */


* ============================================================================= *
* Question 1 Y_i ~ DeltaLines_i where i is city level
* ============================================================================= *


** A: construct del_lines measure as number of open lines that go through city i


// What are the exposure shares and what are the shocks? 
// ANS: g_k=I{line k is open}
// 		s_{ik} = I{line k passes through city i}

// How many shocks do you have? 
use "$dta_loc/pset3_lines", clear
tab open
// ANS: We have 149 shocks, g_k. In 83 cases g_k=1.

// Do the shares add up to one for each i? 
// ANS: no, the shares add up to the number of lines passing through a city
// similar to Miguel and Kremer's count of kid k's neighbors.

use "$dta_loc/pset3_lines", clear
rename open open16
gen open13 = year_opening <= 2013
tempfile lines_dta
save 	`lines_dta'

// Get city-line matrix indicating which lines were open
use "$dta_loc/pset3_stations", clear // city-line matrix
merge m:1 lineid using "`lines_dta'", keepusing(open16 open13) // merge open var
sort cityid lineid
assert _merge == 3
drop _merge
reshape wide open16 open13, i(cityid) j(lineid) // 
isid cityid
tempfile city_open_dta
save 	`city_open_dta'

// merge city_open_dta with cities data
use "$dta_loc/pset3_cities", clear
merge 1:1 cityid using `city_open_dta'
assert _merge != 2 // no line without a city 
drop _merge
egen deltalines = rowtotal(open16*)
egen deltalines13 = rowtotal(open13*)
label var deltalines "number of '16 open lines k that go through city i"
label var deltalines13 "number of '13 open lines k that go through city i"

// Compute ΔLinesi for each city. 
// ANS: see deltalines above
// What is the mean, maximum, and the average of ΔLinesi across the 340 cities?
sum deltalines
sum deltalines13
assert deltalines13 <= deltalines

drop open*

// save
compress
save "$dta_loc/q1a_sol.dta", replace



