/*
Title: 		02_q1e.do
Purpose:	Question 1.e, PSet 4

*/



/* ---------------------------------------------------------------------------
1d Redefine x and 
*/
use "$dta_loc/pset4_trim.dta", clear
gen xp = votes_for - votes_against, after(x)
sort xp

// cdfplot xp

xtile xp_100 = xp, nq(100)
// scatter xp_100 xp
// drop if inlist(xp_100, 1,2,99,100)

// Test for continuity of mean firm size around the cutoff.
// Visual test
rdplot w xp if !inlist(xp_100, 1,2,99,100) , ///
	p(2) ///
	c(0) ///
	masspoints(adjust) ///
	bwselect(mserd) ///
	h(`h_l' `h_r') ///
	kernel(tri) ///
	binselect(espr) ///
	graph_options(legend(position(6))) ///
	ci(95) ///
	shade 
graph export "$do_loc/graphs/q1e.png", ///
	width(1200) height(900) ///
	replace

	
/* 1e and 1f Ans: 

1e: Redefining x as the difference shows that firms tend to be smaller if the race
is close. That is, larger firms have larger majorities either for or against.

1f: From the exercise in q1d, it appears that there is indeed bunching 
that causes close races. Dropping inconclusive races results in balance tests
that fail to reject the identifying assumption of the continuity of potential 
outcomes which we test using balance of w and x at the cutoff.

*/

save "$dta_loc/pset4_trim2.dta", replace



