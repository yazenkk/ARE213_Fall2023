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
reg ln_fat_pc i.state##i.year if primary == 0 


// 2) Get \hat{tau}
// 2a) Compute \hat{y(0)} = in omega_1 population
predict yhat, xb
// 2b) Compute \hat{tau} = y-\hat{y(0)}
gen tau_hat_it = ln_fat_pc - yhat if primary == 1 // 

// 3) Estimate tau_w by a weighted sum over omega_q
// For weights, w_it, I follow Liu et al. (2022) AJPS who use a regular average
gen h = year - cohort if cohort != 999
byso h (cohort) : egen ATT_h_Liu = mean(tau_hat_it) // get horizon specific ATT

// why are these ATTs much larger than ATT dCDH? 
// Are my tau_hats right? What about my weights/averaging method?
label var h "Horizon"
label var ATT_h_Liu "ATT_h Liu et al (Imputation ATTs by horizon weighted regularly)"

egen ATT_Liu = mean(ATT_h_Liu) // tau_w (tau given weights)
label var ATT_Liu "ATT Liu et al (Imputation ATT weighted regularly)"


preserve
	keep h ATT_h_Liu ATT_Liu
	keep if ATT_h_Liu != .
	duplicates drop
	
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

// get tau_hat_{it} - tau_hat_{Et}
byso cohort_coarse (h) : egen tau_hat_coarset = mean(tau_hat_it) 
gen eps_it = tau_hat_it - tau_hat_coarset
egen SE_Liu = mean(eps_it) // BS come back to this.


// how to get weights?


sum ATT_Liu
// results very sensitive to including state-specific linear trends
// estimated ATT increases similar to Wolfers (2006)
