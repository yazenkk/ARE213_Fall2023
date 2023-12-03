/*
Title: 		02_q2d.do
Purpose:	Question 2.d, PSet 4

*/



use "$dta_loc/pset4_trim2.dta", clear

gen y = logwage 

local h_max = 50
local step = 50
forval i = 1(`=`h_max'/`step'')`h_max' {
	dis "rdrobust with h(`i'/100)"
	qui rdrobust y x, p(1) c(0.5) h(`i'/100) kernel(uniform) 
	
	// get stats
	local tau_`i' = `e(tau_cl)'
	local z_bc = e(tau_bc) / e(se_tau_rb)
	local bc_lb_`i' = e(tau_bc) - invnormal(0.975)*e(se_tau_rb)
	local bc_ub_`i' = e(tau_bc) + invnormal(0.975)*e(se_tau_rb)
}


// plot estimates and SEs against bandwidth
clear 
set obs `step'
gen h = .
gen tau = .
gen rb_lb = .
gen rb_ub = .

forval i = 1/`=_N' {
	replace h     = `i'/`h_max' in `i'
	replace tau   = `tau_`i''   in `i'
	replace rb_lb = `bc_lb_`i'' in `i'
	replace rb_ub = `bc_ub_`i'' in `i'
}

label var rb_ub "Bias-corrected upper bound (95% CI)"
label var tau   "Conventional local-polynomial RD estimate"
label var rb_lb "Bias-corrected lower bound (95% CI)"
label var h "Bandwidth"
twoway (line rb_ub h, lpattern(dash) lcolor(grey)) ///
		(line tau h, lcolor(black)) ///
		(line rb_lb h, lpattern(dash) lcolor(grey)), ///
		legend(position(6)) ytitle("Estimate")
  
  
/* As the bandwidth increases, the estimates become less biased in this 
local linear setting.
*/

