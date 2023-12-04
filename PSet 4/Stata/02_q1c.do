/*
Title: 		02_q1c.do
Purpose:	Question 1.c, PSet 4

*/

/* ---------------------------------------------------------------------------
1c Check RDD assumption, density of Xi is continuous around c. 
*/


use "$dta_loc/pset4_clean.dta", clear

hist x // histogram seems ok

// try rddensity
rddensity x, c(0.45) plot kernel(triangular) all
graph export "$do_loc/graphs/q1c_45.png", ///
	width(1200) height(900) ///
	replace

rddensity x, c(0.5) plot kernel(triangular) all
graph export "$do_loc/graphs/q1c_50.png", ///
	width(1200) height(900) ///
	replace
	
rddensity x, c(0.55) plot kernel(triangular) all
graph export "$do_loc/graphs/q1c_55.png", ///
	width(1200) height(900) ///
	replace

/*
This algorithm compares densities below and above the cutoff using 
bandwidths calculated as follows:
	1) minimize the MSE of each density estimator to the L and R separately
	2) minimize the MSE of the difference of the two density estimators
	3) repeat (2) for the sum
	3) Take the median of the three bandwidths.
I have also set it to use a triangular kernel to emphasize observations
closer to the cutoff. One notices that shifting the cutoff slightly around
c=0.5 shows that indeed there appears to be manipulation at c = 0.5 but not 
at those other points.
*/

