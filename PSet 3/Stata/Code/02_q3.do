/*
Title: 		02_q3.do
Purpose:	Question 3, PSet 3

Outline: Question 3

(b) Still, let’s try it out. Compute logNDi and estimate (2) by OLS without controls.
Explain why this OLS may not be causal even if the specification is correct.

(c) Briefly describe how Assumptions A1–A3 allow you to construct 
counterfactual 2016 railway networks (i.e., sets of lines) that 
were as likely to have happened as the realized network. 

Simulate 999 such counterfactual networks; make sure to set a 
seed, such that your results can be exactly reproduced. 

Compute logNDi for each city in each simulation and average it across simulations. 

We denote this average by μi. 

Report two corrected estimates of τ2: recentering by and controlling for μi. 
Are they very different from your estimate in 3(b)? 
What do you learn from this?

*/

/* ---------------------------------------------------------------------------
3.b.i Compute logND */

// 1 Get list of cities with stations for lines open by 2016
use "$dta_loc/pset3_stations", clear 
merge m:1 lineid using "$dta_loc/pset3_lines", nogen assert(3) keepusing(open)
byso cityid : egen open_i = max(open)
keep cityid open_i
duplicates drop
isid cityid
label var open_i "City has any station open by 2016"
tempfile city_wline_dta
save 	`city_wline_dta'

// 2 merge station dummy with matrix of cross-city distances
use "$dta_loc/pset3_distances", clear // distance between cities
rename cityid1 cityid
merge m:1 cityid using `city_wline_dta', assert(1 3) nogen // no cities only in using
replace open_i = 0 if open_i == .

// 3 find ND (nearest distance)
gen cond_dist = dist if open_i == 1
sort cityid2 open_i cond_dist
byso cityid2 : egen nd = min(cond_dist)
gen lognd = log(nd)
label var lognd "log nearest distance to city with HSR"
// hist lognd
keep cityid2 lognd
duplicates drop
isid cityid2
rename cityid2 cityid


/*3.b.i -----------------------------------------------------------------------
Estimate (2) by OLS without controls */
merge 1:1 cityid using "$dta_loc/pset3_cities", nogen assert(3)
sum lognd
reg empgrowth lognd

// cities with missing data are more remote 
// (farther away from Beijing and from nearest city with HSR)
gen miss = missing(empgrowth)
reg lognd miss
reg dist_beijing miss

/*3.b.iii Threats to ID -------------------------------------------------------
Explain why this OLS may not be causal even if the specification is correct. */




