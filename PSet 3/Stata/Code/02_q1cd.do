/*
Title: 		02_q1cd.do
Purpose:	Question 1.cd, PSet 3

Outline: 
c.i Which line-level controls does Assumption A1 compel us to include 
	(qk in the notation of the lecture)? 
c.ii Compute the city-level controls Qi corresponding to these qk. 
c.iii How many of them do you have and how do you interpret them? 
c.iv Intuitively, why is including these controls a good idea?

d.i Estimate (1) by OLS controlling for Qi instead of province fixed effects. 
d.ii Does including Qi change the estimates? 
d.iii Does your estimate rely on Assumptions A2 and A3?

*/

// generate q_k
use "$dta_loc/pset3_lines", clear
keep lineid nlinks
sort nlinks lineid
gen q_0 = 1
tab nlinks, gen(q_)
drop nlinks
save 	"$dta_loc/q1c_lines.dta", replace

// Transform q_k to Q_i
use "$dta_loc/pset3_stations", clear // city-line matrix
merge m:1 lineid using "$dta_loc/q1c_lines.dta", assert(3) nogen
sort cityid lineid
rename q_* q_*_
reshape wide q_*_, i(cityid) j(lineid) // 
isid cityid
tempfile city_open_dta
save 	`city_open_dta'

use "$dta_loc/pset3_cities", clear
merge 1:1 cityid using `city_open_dta'
assert _merge != 2 // no line without a city 
drop _merge
forval i = 0/10 {
    egen Q_`i'_i = rowtotal(q_`i'_*)
}
drop q_*_*

// save
compress
save "$dta_loc/q1c_sol_v2.dta", replace



/* ---------------------------------------------------------------------------
d.i Estimate (1) by OLS controlling for Qi instead of province fixed effects.*/

// bring in independent var z
merge 1:1 cityid using "$dta_loc/q1a_sol.dta", assert(3) keepusing(deltalines) nogen

// bring in s_i
merge 1:1 cityid using "$dta_loc/q1c_sol.dta", assert(3) keepusing(nlinks_i) nogen

// 1d regress 
reg empgrowth deltalines Q_*_i, robust 

