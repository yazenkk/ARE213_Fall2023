/*
Title: 		02_q1d.do
Purpose:	Question 1.d, PSet 4

*/


/* ---------------------------------------------------------------------------
1d Drop inconclusive races and repeat q1b and c 
*/

use "$dta_loc/pset4_clean.dta", clear

drop if x == 0.5



// repeat 1b --------------------------------------------------------
// Visual test
rdplot w x, ///
	p(2) ///
	c(0.5) ///
	masspoints(adjust) ///
	/// bwselect(mserd) ///
	h(`h_l' `h_r') ///
	h(`h_l' `h_r') ///
	kernel(tri) ///
	binselect(espr) ///
	graph_options(legend(position(6))) ///
	ci(95) ///
	shade 

// Statistical test
rdperm x w, c(0.5) perm(500) // fails to reject equality
cdfplot w if w < 500, by(win) 
// although still visually apparent that CDFs diverge early on



// repeat 1c --------------------------------------------------------
hist x // histogram seems ok

// try rddensity
rddensity x, c(0.45) plot kernel(triangular) all
rddensity x, c(0.5) plot kernel(triangular) all
rddensity x, c(0.55) plot kernel(triangular) all


/*
Ans: Explain.
Dropping observations right at the cutoff leads us to fail to reject the 
null hypothesis that the densities are not continuous at the cutoff.

What occurs is that there was no bunching over 0.5. Rather, many races end up 
tied. Dropping such inconclusive races shows that even though there are 
relatively fewer observations right before the cutoff, there also appear to be 
a relatively lower observations from conclusive races right above the cutoff.
So even though there is a visual dip in the estimated density plot, there is
no discontinuity.

*/

save "$dta_loc/pset4_trim.dta", replace


