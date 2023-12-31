/*
Title: 		02_q2a.do
Purpose:	Question 2.a, PSet 4

*/



use "$dta_loc/pset4_trim2.dta", clear

gen y = logwage 

scatter y x
graph export "$do_loc/graphs/q2a_yx.png", ///
	width(1200) height(900) ///
	replace

// statistically inspect ATE at c
reg y i.win##c.margin // Local linear regression
rdrobust y x, p(1) c(0.5) h(0.5) kernel(uniform)

// visually inspect ATE at c
rdplot y x, ///
	p(1) ///
	c(0.5) ///
	masspoints(adjust) ///
	/// bwselect(mserd) ///
	kernel(tri) ///
	binselect(espr) ///
	graph_options(legend(position(6))) ///
	ci(95) ///
	shade 
graph export "$do_loc/graphs/q2a_h50.png", ///
	width(1200) height(900) ///
	replace
	
// setting h by minimizing MSE tightens the bandwidth and exagerates the ATE
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
graph export "$do_loc/graphs/q2a_hopt.png", ///
	width(1200) height(900) ///
	replace

/*
// plotting xp against y is very different and sensitive to outliers
rdplot y xp if !inlist(xp_100, 1,2,99,100), ///
	p(2) ///
	c(0.5) ///
	masspoints(adjust) ///
	/// bwselect(mserd) ///
	kernel(tri) ///
	binselect(espr) ///
	graph_options(legend(position(6))) ///
	ci(95) ///
	shade 
	
rdplot y xp, ///
	p(2) ///
	c(0.5) ///
	masspoints(adjust) ///
	/// bwselect(mserd) ///
	kernel(tri) ///
	binselect(espr) ///
	graph_options(legend(position(6))) ///
	ci(95) ///
	shade 
*/


/* 2a Discuss:

Upon visual inspection, the outcome appears to follow a local linear trend
on both sides of the cutoff. I therefore implement a local linear regression
using the full range of the running variable as a bandwidth. I also use a
uniform kernel but a triangular one does not change the results by much. My
approach is thus equivalent to a specification where the treatment and the 
margin (running variable less cutoff) are fully interacted. A local linear
specification is not always the most informative because the conditional 
expectation of Y given X can have some curvature. In our case, it apparently
does not.

The effect is a statistically significant positive number.

2c: see discussion above.

*/


