/*
Title: 		02_q1d.do
Purpose:	Question 1.d, PSet 3

Outline: 
d.i Estimate (1) by OLS controlling for Qi instead of province fixed effects. 
d.ii Does including Qi change the estimates? 
d.iii Does your estimate rely on Assumptions A2 and A3?


*/

use "$dta_loc/q1a_sol.dta", clear
merge 1:1 cityid using "$dta_loc/q1c_sol.dta", nogen assert(3)
encode province_en, gen(prov)
assert S_i == plines_i + deltalines

/* ---------------------------------------------------------------------------
d.i Estimate (1) by OLS controlling for Qi instead of province fixed effects. 
ANS: See reg below
*/
areg empgrowth deltalines, robust absorb(prov) // recall result from Q1b
reg empgrowth nlinks_i S_i deltalines, robust

/*
d.ii Does including Qi change the estimates? 
	ANS: Adding city-level controls changes the estimates drastically. 
	The number of open lines that go through city i is now insignificant 
	at the 10% level. Instead, the total number of links that the lines 
	passing through city add up to is more predictive of employment growth.

d.iii Does your estimate rely on Assumptions A2 and A3?
	ANS: 
	Our results rely on A3 because 
	ss stated in BHJ (page 7), ``shock orthogonality is a necessary and sufficient
	condition for the orthogonality [unbiasedness] of the shift-share instrument."
	
	Our results do not strictly rely on A2 because the uncorrelatedness assumption
	can be weakened as shown in BHJ (2020).
*/

