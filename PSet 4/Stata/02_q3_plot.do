/*
Title: 		02_q3_plot.do
Purpose:	Question 3, PSet 4

*/


use "$dta_loc/pset4_simresults.dta", clear

// visualize ATEs cl and bc
// sort tau_bc
// gen sp = _n
// line tau_bc tau_cl sp
// sort tau_cl
// gen sp2 = _n
// line tau_bc tau_cl sp2
// sort s

// plot simulation results
// tau estimate
twoway (hist tau_cl, color(red%30)) ///
	   (hist tau_bc, color(blue%30)), ///
	   title("Distribution of ATE across simulations") ///
	   xtitle("ATE") ///
	   legend(order(1 "Convential" 2 "Bias-corrected" ) ///
			position(6) row(1))
graph export "$do_loc/graphs/q3b_ate.png", ///
	width(1200) height(900) ///
	replace

			
// Bias estimate
twoway (hist bias_cl, color(red%30)) ///
	   (hist bias_bc, color(blue%30)), ///
	   title("Distribution of bias of ATE across simulations") ///
	   xtitle("Bias of ATE") ///
	   legend(order(1 "Convential" 2 "Bias-corrected" ) ///
			position(6) row(1))
graph export "$do_loc/graphs/q3b_bias.png", ///
	width(1200) height(900) ///
	replace
			
ttest bias_cl == bias_bc // cannot reject null of equality of biases
			
// get SD of tau
preserve
	use "$dta_loc/pset4_trim2.dta", clear
	count if win != .
	local N_reg = `r(N)'
restore
gen sd_tau_bc = se_tau_bc * sqrt(`N_reg') 
gen sd_tau_cl = se_tau_cl * sqrt(`N_reg') 

// Bias SD
twoway (hist sd_tau_cl, color(red%30)) ///
	   (hist sd_tau_bc, color(blue%30)), ///
	   title("Distribution of standard deviation of ATE across simulations") ///
	   xtitle("Standard Deviation of ATE") ///
	   legend(order(1 "Convential" 2 "Bias-corrected" ) ///
			position(6) row(1))
graph export "$do_loc/graphs/q3b_sd.png", ///
	width(1200) height(900) ///
	replace
			
ttest sd_tau_cl == sd_tau_bc // can reject null of equality of SDs

gen mse_bc = sd_tau_bc^2 + bias_bc^2 
gen mse_cl = sd_tau_cl^2 + bias_cl^2 
twoway (hist mse_cl, color(red%30)) ///
	   (hist mse_bc, color(blue%30)), ///
	   title("Distribution of MSE of ATE across simulations") ///
	   xtitle("MSE of ATE") ///
	   legend(order(1 "Convential" 2 "Bias-corrected" ) ///
			position(6) row(1))
// mechanical result. Don't export


// CI Coverage
gen ci_lb_cl = tau_cl - invnormal(0.975)*se_tau_cl
gen ci_ub_cl = tau_cl + invnormal(0.975)*se_tau_cl
gen ci_lb_bc = tau_bc - invnormal(0.975)*se_tau_bc
gen ci_ub_bc = tau_bc + invnormal(0.975)*se_tau_bc

preserve
	use "$dta_loc/pset4_trim2.dta", clear
	gen y = logwage 
	rdrobust y x, p(1) c(0.5) h(0.5) kernel(uniform) all // replicate 2a result
	local tau_cl_true = e(tau_cl)
restore

gen cov_cl = inrange(`tau_cl_true', ci_lb_cl, ci_ub_cl)
gen cov_bc = inrange(`tau_cl_true', ci_lb_bc, ci_ub_bc)
sum cov*




