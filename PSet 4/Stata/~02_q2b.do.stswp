/*
Title: 		02_q2b.do
Purpose:	Question 2.b, PSet 4

*/

/*
What's the estimand? The estimand is \hat{tau}, the same one as in slide 15. 
Larger or smaller firms? As we showed in q 1

*/

use "$dta_loc/pset4_trim2.dta", clear

gen y = logwage 

rdrobust y x, p(1) c(0.5) kernel(uniform) 
local h_l `e(h_l)'
local h_r `e(h_r)'
rdplot y x, ///
	p(1) ///
	c(0.5) ///
	masspoints(adjust) ///
	/// bwselect(mserd) ///
	h(`h_l' `h_r') ///
	kernel(tri) ///
	binselect(espr) ///
	graph_options(legend(position(6))) ///
	ci(95) ///
	shade 

// around the cutoff, firms are not larger
gen localtobw = inrange(x, 0.5-`h_l', 0.5+`h_r')
ttest w, by(localtobw)
