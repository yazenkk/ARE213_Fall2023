/*
Title: 		02_analysis_q3d.do
Outline:	Question 3, PSet 2 

Q3 DinD estimation

3. Now proceed with the DiD estimation. 

(d) How sensitive are the estimates to including state-specific linear trends into your
model of untreated potential outcomes?

*/

use "$dta_loc/pset2_q1", clear
isid state year

sort state year primary secondary
drop college beer unemploy totalvmt precip snow32 rural_speed urban_speed

// 1) Get predictions for alpha_i and beta_t by OLS in omega_0 
// using state specific time trends atop state and time trends
// reg ln_fat_pc i.state##i.year if primary == 0 
gen state_yr = state*year
tab state, gen(state_)
foreach var of varlist state_* {
	gen `var'_yr = `var'*year
}
reg ln_fat_pc i.state i.year state_*_yr if primary == 0 


// 2) Get \hat{tau}
// 2a) Compute \hat{y(0)} = in omega_1 population
predict yhat, xb
// 2b) Compute \hat{tau} = y-\hat{y(0)}
gen tau_hat_it = ln_fat_pc - yhat if primary == 1 // 

// 3) Estimate tau_w by a weighted sum over omega_q
// For weights, w_it, I follow Liu et al. (2022) AJPS who use a regular average
gen h = year - cohort if cohort != 999
byso h (cohort) : egen ATT_h_Liu = mean(tau_hat_it) // get horizon specific ATT

// to confirm: Are my tau_hats right? What about my weights/averaging method?

label var h "Horizon"
label var ATT_h_Liu "ATT_h Liu et al (Imputation ATTs by horizon weighted regularly)"

egen ATT_Liu = mean(tau_hat_it) // tau_w (tau given weights)
label var ATT_Liu "ATT Liu et al (Imputation ATT weighted regularly)"


preserve
	keep h ATT_h_Liu ATT_Liu
	keep if ATT_h_Liu != .
	duplicates drop
	
	qui sum ATT_Liu
	global att_est_3d = round(`r(mean)', 0.001)
	
	// save
	compress
	save "$dta_loc\q3d_ATTs", replace
restore


// 4) Estimate standard error (conservative estimate)
// Following Theorem 3 in BJS (2023), the plug-in estimator (eqn (7))
// Approach 1: Pool multiple cohorts for simplicity 
gen cohort_coarse = 999 if cohort == 999 // decade cohort
replace cohort_coarse = 1980 if inrange(cohort, 1980, 1989)
replace cohort_coarse = 1990 if inrange(cohort, 1990, 1999)
replace cohort_coarse = 2000 if inrange(cohort, 2000, 2009)

// get eps_it = tau_hat_{it} - tau_hat_{Et}
byso cohort_coarse (h) : egen tau_hat_coarset = mean(tau_hat_it) 
replace tau_hat_coarset = . if primary != 1
gen eps_it = tau_hat_it - tau_hat_coarset
sum eps_it

// let v_it = w_it = size of omega_1
count if primary == 1
gen v_it = 1/`r(N)'
gen v_e_it = v_it * eps_it

// var(tau_it) = sum_i (sum_t v_it eps_it)^2
byso state : egen sumt_v_e = total(v_e_it) // sum over time within state, i
gen sumt_v_e_sq = sumt_v_e^2
keep state sumt_v_e_sq
duplicates drop
egen sumi_sumt_v_e_sq = total(sumt_v_e_sq)
gen se = sqrt(sumi_sumt_v_e_sq)

qui sum se
global se_est_3d = round(`r(mean)', 0.001)


// results very sensitive to including state-specific linear trends

dis "ATT = $att_est_3d"
dis "SE = $se_est_3d"

