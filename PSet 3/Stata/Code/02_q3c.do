/*
Title: 		02_q3c.do
Purpose:	Question 3.c, PSet 3

Outline: Question 3.c.i

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
local T = 10

use "$dta_loc/pset3_lines", clear
count if open == 0 // get count of shocks to resample
local line_ct `r(N)' // 66

forval t = 1/`T' {

	dis "Simulation t = `t'"
	dis "	- Randomize shocks"
	// 0 randomize the shocks (line openings)
	qui {
		
		use "$dta_loc/pset3_lines", clear
		isid lineid
		expand nlinks // duplicate observations based on nlinks (.|w)
		sort lineid
		
		// equal weights where nlinks defines number of draws per line
		gen rand = runiform() 
		sort rand
		
		// For lines with multiple draws, keep higher draw
		byso lineid : egen higher_draw = max(rand) 
		byso lineid : gen to_drop = rand < higher_draw // keep higher draw by lineid
		drop if to_drop == 1
		drop to_drop
		assert _N == 149
		
		// generate shock indicator for highest 149-66=83 draws
		sort higher_draw
		gen open_`t' = _n > `line_ct'
		byso open_`t' : egen city_ct = rank(lineid), track
		sort open_`t' city_ct
		
		// confirm number of shocks generated equals original number
		count if open_`t' == 0
		assert `r(N)' == `line_ct'
		sort lineid
		drop open rand
		rename open_`t' open
		tempfile line_rand
		save 	`line_rand'
	}
	
	dis "	- Merge openness data"
	qui {
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
	}
	
	dis "	- Find nearest distance to HSR city for each city"
	qui {
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
	
	dis "	- Merge result `t'"
	qui {
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
}

// save
compress
save "$dta_loc/q3c_lognd_i", replace






