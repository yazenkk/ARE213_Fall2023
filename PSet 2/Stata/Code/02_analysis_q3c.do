/*
Title: 		02_analysis_q3c.do
Outline:	Question 3, PSet 2 

Q3 DinD estimation

3. Now proceed with the DiD estimation. 

(c) Researchers sometimes use state population as weights. Describe two distinct reasons
for using such weights. For this part only, modify the imputation procedure
to accommodate each of these reasons one by one. Discuss how the estimates
change from part 3(b).

*/



use "$dta_loc/pset2_q1", clear
isid state year

sort state year primary secondary
drop college beer unemploy totalvmt precip snow32 rural_speed urban_speed






// Weighting approach 1: weight in regression step to address endogenous sampling

// 1) Get predictions for alpha_i and beta_t by OLS in omega_0 
gen pop_flr = floor(population) // round down to use as fweights
reg ln_fat_pc i.state i.year if primary == 0 [pw=pop_flr]


// 2) Get \hat{tau}
// 2a) Compute \hat{y(0)} = in omega_1 population
predict yhat, xb
// 2b) Compute \hat{tau} = y-\hat{y(0)}
gen tau_hat_it = ln_fat_pc - yhat if primary == 1 // 

// 3) Estimate tau_w by a weighted sum over omega_q
// For weights, w_it, I follow Liu et al. (2022) AJPS who use a regular average
gen h = year - cohort if cohort != 999
byso h (cohort) : egen ATT_h_Liu = mean(tau_hat_it) // get horizon specific ATT
label var ATT_h_Liu "ATT_h Liu et al (Imputation ATTs by horizon weighted regularly)"

egen ATT_Liu = mean(ATT_h_Liu) // tau_w (tau given weights)
label var ATT_Liu "ATT Liu et al (Imputation ATT weighted regularly)"
qui sum ATT_Liu
local mean_w1 = round(`r(mean)', 0.001)

// why are these ATTs much larger than ATT dCDH? 
// Are my tau_hats right? What about my weights/averaging method?

preserve
	keep h ATT_h_Liu ATT_Liu
	keep if ATT_h_Liu != .
	duplicates drop
	
	// save
	compress
	save "$dta_loc\q3c_ATTs", replace
restore



// Weighting approach 2: weight in averaging step to address HTE by it
egen pop_tot = total(population)
gen pop_w = population/pop_tot
gen weighted_tau = tau_hat_it * pop_w
egen ATT_popw = sum(weighted_tau)
qui sum ATT_popw
local mean_w2 = round(`r(mean)', 0.001)


dis "Weighting method 1 gives ATT = `mean_w1'"
dis "Weighting method 2 gives ATT = `mean_w2'"

