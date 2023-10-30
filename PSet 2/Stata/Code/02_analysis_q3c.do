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
/*

*/


// 1) Get predictions for alpha_i and beta_t by OLS in omega_0 
reg ln_fat_pc i.state i.year if primary == 0 [aw=population]


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

egen ATT_Liu = mean(tau_hat_it) // tau_w (tau given weights)
label var ATT_Liu "ATT Liu et al (Imputation ATT weighted regularly)"
qui sum ATT_Liu
global att_est_3c1 = round(`r(mean)', 0.001)


preserve
	keep h ATT_h_Liu ATT_Liu
	keep if ATT_h_Liu != .
	duplicates drop
	
	// save
	compress
	save "$dta_loc\q3c_ATTs", replace
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
local treat_n `r(N)'
gen v_it = 1/`treat_n'
gen v_e_it = v_it * eps_it

// var(tau_it) = sum_i (sum_t v_it eps_it)^2
byso state : egen sumt_v_e = total(v_e_it) // sum over time within state, i
gen sumt_v_e_sq = sumt_v_e^2

preserve 
	keep state sumt_v_e_sq
	duplicates drop
	egen sumi_sumt_v_e_sq = total(sumt_v_e_sq)
	gen se = sqrt(sumi_sumt_v_e_sq)
	qui sum se
	global se_est_3c1 = round(`r(mean)', 0.001)
restore





// Weighting approach 2: weight in averaging step to address HTE by it
egen pop_tot = total(population) if primary == 1
gen pop_w_it = population/pop_tot
gen weighted_tau_it = tau_hat_it * pop_w_it
egen ATT_popw = sum(weighted_tau_it)
qui sum ATT_popw
global att_est_3c2 = round(`r(mean)', 0.001)



// 4) Estimate standard error (conservative estimate)
// Following Theorem 3 in BJS (2023), the plug-in estimator (eqn (7))
// Approach 1: Pool multiple cohorts for simplicity 
// let v_it = new weight = pop weights omega_1
gen popw_e_it = pop_w_it * eps_it

// var(tau_it) = sum_i (sum_t v_it eps_it)^2
byso state : egen sumt_popw_e = total(popw_e_it) // sum over time within state, i
gen sumt_popw_e_sq = sumt_popw_e^2

preserve 
	keep state sumt_popw_e_sq
	duplicates drop
	egen sumi_sumt_popw_e_sq = total(sumt_popw_e_sq)
	gen se = sqrt(sumi_sumt_popw_e_sq)
	
	qui sum se
	global se_est_3c2 = round(`r(mean)', 0.001)
restore




dis "Weighting method 1 gives ""
dis "	ATT = $att_est_3c1"
dis "	SE = $se_est_3c1"

dis "Weighting method 2 gives "
dis "	ATT = $att_est_3c2"
dis "	SE = $se_est_3c2"


