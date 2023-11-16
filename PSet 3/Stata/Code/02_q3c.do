/*
Title: 		02_q3c.do
Purpose:	Question 3.c, PSet 3

Outline: Question 3.c

Briefly describe how Assumptions A1–A3 allow you to construct 
counterfactual 2016 railway networks (i.e., sets of lines) that 
were as likely to have happened as the realized network. 

c.i
Simulate 999 such counterfactual networks; make sure to set a 
seed, such that your results can be exactly reproduced. 

Compute logNDi for each city in each simulation and average it across simulations. 

We denote this average by μi. 

c.ii
Report two corrected estimates of τ2: recentering by and controlling for μi. 
Are they very different from your estimate in 3(b)? 
What do you learn from this?

*/


/*3.c.i  ---------------------------------------------------------------------
Estimate (2) by OLS without controls 
We repeat part b only with randomly generated shocks g_k = open at the line level
*/

// Question: should I adjust probablity of opening by the number of links?
// link stratified randomization? How do I force a positive relation between
// L_k and propensity to get shocked? Not stratified for now.
pause on
set seed 154
local T = 4

forval t = 1/`T' {

	qui {
	// 0 randomize the shocks (line openings)
	use "$dta_loc/pset3_lines", clear
	qui sum open
	// gen rand = runiform()
	gen open_`t' = runiform()  >= `r(mean)'
	drop open
	rename open_`t' open
	tempfile line_rand
	save 	`line_rand'
	
	
	// 1 Get list of cities with stations for lines open by 2016
	use "$dta_loc/pset3_stations", clear 
	merge m:1 lineid using "`line_rand'", nogen assert(3) keepusing(open)
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
	gen lognd_`t' = log(nd)
	label var lognd_`t' "log nearest distance to city with HSR"
	// hist lognd
	keep cityid2 lognd_`t'
	duplicates drop
	isid cityid2
	rename cityid2 cityid
	}
	dis "Simulation t = `t'"
	sum lognd_`t'
	
	tempfile lognd_dta_`t'
	save 	`lognd_dta_`t''
	
	if `t' == 1 {
		use `lognd_dta_1', clear
		tempfile lognd_dta
		save 	`lognd_dta', replace	
	}
	else {
		use `lognd_dta'
		merge 1:1 cityid using `lognd_dta_`t'', assert(3) nogen
		tempfile lognd_dta
		save 	`lognd_dta', replace			
	}
}

egen mu_i = rowmean(lognd_*)
drop lognd_*

/*3.c.ii ----------------------------------------------------------------------
Estimate (2) by OLS without controls */
// merge lognd from 3b
merge 1:1 cityid using "$dta_loc/q3b", keepusing(lognd) assert(3) nogen
// merge dependent variable
merge 1:1 cityid using "$dta_loc/pset3_cities", nogen assert(3)

// Approach 1: demeaned
gen ztilde = lognd-mu_i
reg empgrowth ztilde

// Approach 2: control function
reg empgrowth lognd mu_i





