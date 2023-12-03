/*
Title: 		02_q2e.do
Purpose:	Question 2.e, PSet 4

*/
/*
2.E Alter the cutoff.

*/

use "$dta_loc/pset4_trim2.dta", clear

gen y = logwage 

local c_range 30(10)70

forval i = 1/41 {
	local c = 29+`i' // c= 30(1)70
	
	gen margin_`c' = x - `c'/100
	gen win_`c'    = x > `c'/100
}

// Local linear regression
/*
forval i = 1/41 {
	local c = 29+`i' // c= 30(1)70
	if      `c' <  50 reg y i.win_`c'##c.margin_`c' if x < 0.5 
	else if `c' == 50 reg y i.win_`c'##c.margin_`c'
	else if `c' >  50 reg y i.win_`c'##c.margin_`c' if x > 0.5 
}
*/

local rdopts ""
forval i = 1/41 {
	
	// get c
	local c = 29+`i' // c= 30(1)70
	local c_reg = `c'/100
	
	if      `c' <  50 rdrobust y x if x < 0.5, c(`c_reg') p(1) h(50/100) kernel(uniform)
	else if `c' == 50 rdrobust y x, 		    c(`c_reg') p(1) h(50/100) kernel(uniform)
	else if `c' >  50 rdrobust y x if x > 0.5, c(`c_reg') p(1) h(50/100) kernel(uniform)
	
	// get stats
	local tau_`c' = `e(tau_cl)'
	dis "tau_`c' = `tau_`c''"
	local z_bc = e(tau_bc) / e(se_tau_rb)
	local bc_lb_`c' = e(tau_bc) - invnormal(0.975)*e(se_tau_rb)
	local bc_ub_`c' = e(tau_bc) + invnormal(0.975)*e(se_tau_rb)
}


clear 
set obs 41
gen c = .
gen tau = .
gen rb_lb = .
gen rb_ub = .

forval i = 1/`=_N' {
	local c = 29+`i' // c= 30(1)70
	replace c     = `c' in `i'
	replace tau   = `tau_`c''   in `i'
	replace rb_lb = `bc_lb_`c'' in `i'
	replace rb_ub = `bc_ub_`c'' in `i'
}

label var rb_ub "Bias-corrected upper bound (95% CI)"
label var tau   "Conventional local-polynomial RD estimate"
label var rb_lb "Bias-corrected lower bound (95% CI)"
label var c "Cutoff"
twoway (line rb_ub c, lpattern(dash) lcolor(grey)) ///
		(line tau c, lcolor(black)) ///
		(line rb_lb c, lpattern(dash) lcolor(grey)), ///
		legend(position(6)) ytitle("Estimate") ///
		yline(0, lcolor(red) lpattern(solid))
  


