/*
Title: 		02_q1b.do
Purpose:	Question 1.b, PSet 4

*/


/* ---------------------------------------------------------------------------
1b Check RDD assumption, E[W|X]*/


use "$dta_loc/pset4_clean.dta", clear


// hist x
sort votes_for votes_against eligible_voters

/*
// Testing scatter and binscatter
scatter w x
xtile pctx = x, nq(100)
preserve
	collapse (mean) w, by(pctx)
	scatter w pctx
restore	
*/

/*
rdrobust w x, ///
	p(2) ///
	c(0.5) ///
	h(0.5) ///
	masspoints(adjust) ///
	bwselect(mserd) ///
	kernel(tri)

local h_l = e(h_l)
local h_r = e(h_r)
*/

// Local linear regression
reg w i.win##c.margin
rdrobust w x, p(1) c(0.5) h(0.5) kernel(uniform)
// close

// Visual test
rdplot w x, ///
	p(2) ///
	c(0.5) ///
	masspoints(adjust) ///
	/// bwselect(mserd) ///
	kernel(tri) ///
	binselect(espr) ///
	graph_options(legend(position(6)) ///
				  xtitle("Running variable") ///
				  ytitle("Eligible voters")) ///
	ci(95) ///
	shade 
graph export "$do_loc/graphs/q1b_rdplot.png", ///
	width(1200) height(900) ///
	replace
	
// Statistical test
rdperm x w, c(0.5) perm(500) // rejects equality
cdfplot w if w < 500, by(win) // visually apparent that CDFs diverge early on
graph export "$do_loc/graphs/q1b_cdfs.png", ///
	width(1200) height(900) ///
	replace

/*
Q: is checking whether E [Wi | Xi] is continuous at the cutoff
be a useful placebo check for the RDD assumptions

Testing for the continuity of this expectation can be done visually using a 
scatter plot. If a ruler can be placed across the entire graph, then 
the continuity of E[Wi | Xi] is satisfied in a local linear model. The ruler
analogy can be extended to a polynomial of degree p, hence the result is 
somewhat arbitrary. The bandwidth introduces more arbitrariness. Canay and Kamat
(2017) suggested comparing CDFs of W at either side of the cutoff. The
result of rdperm shows that the null of equality of distributions can be 
rejected. Visually inspecting the CDFs confirms this.

*/


