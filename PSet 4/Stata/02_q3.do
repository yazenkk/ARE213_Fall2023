/*
Title: 		02_q3.do
Purpose:	Question 3, PSet 4

*/
/*
3. Simulating RDD
3.1 Use the dataset to estimate mu-, mu+, sigma-, and sigma+
*/

pause on
set seed 154
use "$dta_loc/pset4_trim2.dta", clear

gen y = logwage 

rdrobust y x, p(1) c(0.5) h(0.5) kernel(uniform) all // replicate 2a result
local tau_cl_true = e(tau_cl)
local tau_bc_true = e(tau_bc)
mat list e(beta_p_l)
mat list e(beta_p_r)

// mu-
mat coefsl = e(beta_p_l)
local bl_1 = coefsl[1,1]
local bl_2 = coefsl[2,1]
// mu+
mat coefsr = e(beta_p_r)
local br_1 = coefsr[1,1]
local br_2 = coefsr[2,1]

	// plot reality check (compare with rdplot in 2a)
	gen mul = `bl_1' + `bl_2'*x if x < 0.5
	gen mur = `br_1' + `br_2'*x if x > 0.5
// 	twoway (scatter y x) ///
// 		   (line mul x) ///
// 		   (line mur x)

// sigma- (residual variance from mu-)
gen resl = mul - y if x < 0.5
qui sum resl
local resl_sd = r(sd)
// sigma+ (residual variance from mu+)
gen resr = mur - y if x > 0.5
qui sum resr
local resr_sd = r(sd)

// simulate y
local S 300 // simulations
forval s = 1/`S' {
	capture drop eps yl_s yr_s y_s
	
	// generate std normal error terms
	qui gen eps = rnormal() 
	// generate new outcomes
	qui gen yl_s = mul + `resl_sd'*eps if x < 0.5 // 
	qui gen yr_s = mur + `resr_sd'*eps if x > 0.5 // 

/*
		// plot reality check (compare with rdplot in 2a)
		twoway (scatter yl_s x) ///
			   (scatter yr_s x) ///
			   (line mul x) ///
			   (line mur x)
*/

	// Simulate
	// 3.a Ignore bandwidth because local linear
	// 3.b Estimate conventional and bias-corrected ATE 
	qui gen 	y_s = yl_s if x < 0.5
	qui replace y_s = yr_s if x > 0.5
	rdrobust y_s x, p(4) c(0.5) h(0.5) kernel(uniform) all 
	dis "tau_cl = `e(tau_cl)' and tau_bc = `e(tau_bc)'" 
// 	twoway (scatter y_s x) ///
// 			   (line mul x) ///
// 			   (line mur x)
// 	twoway    (line mul x) ///
// 			   (line mur x)
// 	rdplot y_s x, ///
// 		p(1) ///
// 		c(0.5) ///
// 		masspoints(adjust) ///
// 		/// bwselect(mserd) ///
// 		kernel(uniform) ///
// 		binselect(espr) ///
// 		graph_options(legend(position(6)) ///
// 					  xtitle("Running variable") ///
// 					  ytitle("Eligible voters")) ///
// 		ci(95) ///
// 		shade 
	
	
	// collect locals
	// tau
	local tau_cl_`s' = e(tau_cl)
	local tau_bc_`s' = e(tau_bc)
	// se of tau
	local se_tau_cl_`s' = e(se_tau_cl)
	local se_tau_bc_`s' = e(se_tau_rb)
	// bias of conventional and bias-corrected ATEs relative to true effect
	local bias_cl_`s' = `tau_cl_`s'' - `tau_cl_true'
	local bias_bc_`s' = `tau_bc_`s'' - `tau_cl_true'

}


// collect simulation results
clear
set obs `S' 
gen s = .
gen tau_cl = .
gen tau_bc = .
gen se_tau_cl = .
gen se_tau_bc = .
gen bias_cl = .
gen bias_bc = .

forval i = 1/`=_N' {
	replace s = `i' in `i'
	foreach var in tau_cl tau_bc se_tau_cl se_tau_bc bias_cl bias_bc {
		replace `var' = ``var'_`i'' in `i'
	}
}

save "$dta_loc/pset4_simresults.dta", replace


