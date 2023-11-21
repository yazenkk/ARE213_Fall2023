/*
Title: 		02_q3c.do
Purpose:	Question 3.c, PSet 3

Outline: Question 3.c.ii

Briefly describe how Assumptions A1–A3 allow you to construct 
counterfactual 2016 railway networks (i.e., sets of lines) that 
were as likely to have happened as the realized network. 

c.ii
Report two corrected estimates of τ2: recentering by and controlling for μi. 
Are they very different from your estimate in 3(b)? 
What do you learn from this?

*/

/*3.c.ii ----------------------------------------------------------------------
Estimate (2) by OLS without controls */

eststo clear
use "$dta_loc/q3c_lognd_i", clear

egen mu_i = rowmean(lognd_*)
label var mu_i "Expected log nearest distance"
drop lognd_*

// merge lognd from 3b
merge 1:1 cityid using "$dta_loc/q3b_lognd", keepusing(lognd) assert(3) nogen
// merge dependent variable
merge 1:1 cityid using "$dta_loc/pset3_cities", nogen assert(3)

// Approach 1: demeaned
gen ztilde = lognd-mu_i
label var lognd "Log nearest distance"
label var ztilde "Log nearest distance (recentered)"
label var empgrowth "Employment growth"


/*Regressions -----------------------------------------------------------------
*/

// Approach 0: recall 3b results
eststo: reg empgrowth lognd 

// Approach 1: demeaned
eststo: reg empgrowth ztilde // recentering

// Approach 2: control function
eststo: reg empgrowth lognd mu_i // controlling

// Q3 table
esttab using "$do_loc/Tables/table_3c.tex",   			///
	style(tex)											///
	nogaps												///
	nobaselevels 										///
	label            									///
	varwidth(50)										///
	wrap 												///
	cells (b(fmt(2)) se(fmt(2) par))					///
	stats(N, 											///
		  fmt(%9.0f)									///
		  labels("Observations")) 	///
	eqlabel(none) ///
	replace




