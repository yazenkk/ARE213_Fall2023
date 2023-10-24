/*
Title: 		02_analysis_q2.do
Outline:	Question 3, PSet 2 

Q3 DinD estimation

3. Now proceed with the DiD estimation. 
(Note: These methods are quite simple. If the commands are not available 
in some of the languages, just code them up.)

(b) Report the Borusyak, Jaravel, and Spiess’s imputation estimates for the same
estimands. Use the most appropriate standard errors. Do the results mostly
agree with part 3(a)?

Approach: following Theorem 2 in BJS (2023):
1) Get predictions for alpha_i and beta_t by OLS in the omega_0 
(untreated or not yet treated) population only.
2) Get \hat{tau}
	2a. Compute \hat{y(0)} = in omega_1 population and 
	2b. compute \hat{tau} = y-\hat{y(0)}
3) Estimate tau_w by a weighted sum over omega_q

*/

use "$dta_loc/pset2_q1", clear
isid state year

sort state year primary secondary
drop college beer unemploy totalvmt precip snow32 rural_speed urban_speed

// 1) Get predictions for alpha_i and beta_t by OLS in omega_0 
reg ln_fat_pc i.state i.year if primary == 0

// 2) Get \hat{tau}
// 2a) Compute \hat{y(0)} = in omega_1 population
predict yhat if primary == 1, xb
// 2b) Compute \hat{tau} = y-\hat{y(0)}
gen tau_hat_it = ln_fat_pc - yhat

// 3) Estimate tau_w by a weighted sum over omega_q
// For weights, w_it, I follow Liu et al. (2022) AJPS who use a regular average
gen h = year - cohort if cohort != 999
byso h (cohort) : egen ATT_h_Liu = mean(tau_hat_it) // get horizon specific ATT
stop
keep h ATT_h_Liu
keep if ATT_h_Liu != .
duplicates drop

// why are these ATTs much larger than ATT dCDH? 
// Are my tau_hats right? What about my weights/averaging method?

