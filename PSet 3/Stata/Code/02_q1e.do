/*
Title: 		02_q1e.do
Purpose:	Question 1.e, PSet 3

Outline: 
For each line, pset3_lines reports the operational speed (in km/h). 
For each city, pset3_cities reports the distance from city i to Beijing (in km). 

e.i Use these variables to run balance tests. 
e.ii Describe the procedures and which assumption(s) you are testing in each case. 
e.iii Suggest another test that would be helpful to perform if you had the necessary data.

*/

/*
e.i Use these variables to run balance tests. 
Note that, as per BHJ (2020),
``If the... shocks are as-good-as-randomly assigned to [raillines], 
then we expect them to not predict... predetermined variables [such as 
distance to Beijing, speed of line, and other observables]. 

[City-level] balance coefficients are obtained by regressing each potential 
confounder on the shift-share instrument (normalized to have a unit 
variance), since [we have] a setting with incomplete shares.

For the [shock]-level balance test this amounts to regressing each 
potential confounder on the rail-line shocks (normalized to have a 
unit variance)..., weighting by average industry... shares. 

Note from footnote 10 in BHJ 2020:
"Without regression weights (i.e. e_l = 1/L), s_k is the average 
share of shock k across units i.

*/

// city-level
	use "$dta_loc/q1a_sol.dta", clear
	merge 1:1 cityid using "$dta_loc/q1c_sol.dta", nogen assert(3)
	
	// 1) normalize SSIV to have unit variance for balance testing
	// (standardize without recentering)
	qui sum deltalines
	gen deltalines_std = (deltalines)/`r(sd)'
	sum deltalines_std
	label var deltalines_std "deltalines (sd = 1)"

	// 2) regress SSIV on confounder
	reg dist_beijing deltalines_std, robust


// shock-level
	// 1) generation regression weights
	use "$dta_loc/pset3_stations", clear // city-line matrix
	gen s_ik = 1 // indicator for cities with lines
	
	merge m:1 lineid using "$dta_loc/pset3_lines", assert(3)
	label var s_ik "line k passes through city i" 
	byso lineid : egen s_k = total(s_ik) // not exactly 1+nlinks due to dropped obs
	count if s_k != nlinks + 1
	
	// 2) standardize shocks to unit variance
	qui sum open
	gen open_std = (open)/`r(sd)'
	sum open_std  
	
	// 3) regress shock on confounder
	keep lineid speed open open_std s_k
	duplicates drop 
	reg speed open, robust // balance without weights
	reg speed open_std, robust // balance without weights
	reg speed open_std [aw=s_k], robust


/*
Our results show that there is indeed no statistically significant 
correlation between the shocks and these potential confounders, consistent 
with the assumption that the shocks are conditionally exogenous.

Question: BHJ keep on the period FEs when running (falsitication) balance tests.
Which controls should we include? 


e.ii Describe the procedures and which assumption(s) you are testing in each case. 
ANS:
	
e.iii Suggest another test that would be helpful to perform if you had the necessary data.
ANS: 
	One could also test for balance on some pre-trend variables for 
	employment growth prior to 2008 on the shift-share instrument to 
	test for a city-level ``pre-trend."
*/



