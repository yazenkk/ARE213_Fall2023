/*
Title: 		02_q3.do
Purpose:	Question 3, PSet 4

*/
/*
3. Simulating RDD
3.1 Use the dataset to estimate mu-, mu+, sigma-, and sigma+
*/


set seed 154
use "$dta_loc/pset4_trim2.dta", clear

gen y = logwage 

rdrobust y x, p(1) c(0.5) h(0.5) kernel(uniform) // replicate 2a result
local tau_cl_true = e(tau_cl)
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
local resl_se = r(sd)
// sigma+ (residual variance from mu+)
gen resr = mur - y if x > 0.5
qui sum resr
local resr_se = r(sd)

// simulate y
local S 50 // simulations
forval s = 1/`S' {
	capture drop eps yl_s yr_s y_s
	gen eps = rnormal() // generate std normal error terms
	gen yl_s = mul + `resl_se'*eps if x < 0.5 // 
	gen yr_s = mur + `resr_se'*eps if x > 0.5 // 

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
	gen 	y_s = yl_s if x < 0.5
	replace y_s = yr_s if x > 0.5
	rdrobust y_s x, p(1) c(0.5) h(0.5) kernel(uniform)
	
	// collect locals
	local tau_cl_`s' = e(tau_cl)
	local tau_bc_`s' = e(tau_bc)
	local se_tau_cl_`s' = e(se_tau_cl)
	local se_tau_bc_`s' = e(se_tau_bc)
	local bias_cl_`s' = `tau_cl_`s'' - `tau_cl_true'
	local bias_bc_`s' = `tau_bc_`s'' - `tau_cl_true'
}


// plot simulation results
clear
set obs `S' 
gen s = .
gen tau_bc = .
gen tau_cl = .
gen se_tau_bc = .
gen se_tau_cl = .
gen bias_cl = .
gen bias_bc = .

forval i = 1/`=_N' {
	replace s = `i' in `i'
	foreach var in tau_bc tau_cl se_tau_bc se_tau_cl bias_cl bias_bc {
		replace `var' = ``var'_`i'' in `i'
	}
}

hist tau_cl
hist tau_bc
hist bias_cl
hist bias_bc
sum bias*
ttest bias_cl == bias_bc
ttest tau_cl == tau_bc

Todo: figure out which paper he's referring to Cattaneo et al. (2014).
Finish b and c.



