/*
Title: 		02_analysis_q3f.do
Outline:	Question 3, PSet 2 

Q3 DinD estimation

3. Now proceed with the DiD estimation. 

(f) Estimate the static two-way fixed-effect regression (without covariates or 
population weights). 

Then estimate and plot the total weight this regression places on treated 
observations at each horizon. In what way are these weights informative?

Compare them to the sample weights of each horizon. 

In your view, does the static regression coefficient provide a useful summary of causal effects in this setting? Discuss.

*/


use "$dta_loc/pset2_q1", clear
isid state year

sort state year primary secondary
drop college beer unemploy totalvmt precip snow32 rural_speed urban_speed prim_ever

// 1) Run static TWFE
reg ln_fat_pc i.state i.year primary 


// 2) Get weights using auxiliary reg via FWL: reg D on i and t FEs
// from proof of proposition 2 in BJS
reg primary i.state i.year  
predict dres, residuals

// two ways to get denominator
// method 1
gen dres_sq = dres^2
egen tot_dres_sq = total(dres_sq)

// method 2
gen dres_treat = dres if primary == 1
egen tot_dres_treat = total(dres_treat) 
// assert tot_dres_treat == tot_dres_sq // equivalent
drop tot_dres_treat // drop method 2

gen w_it_static = dres/tot_dres_sq 
egen tot_w_it = total(w_it_static)
sum tot_w_it // this sums to zero because it's on both omega_0 and _1

gen h = year - cohort if cohort != 999
byso h (cohort) : egen w_h = mean(w_it_static) // get horizon specific w_it_static
scatter w_h h if primary == 1 
// ANS: distant horizons get negative weights, yet total weights sum to 1.
// These are the forbidden comparisons?

gen w_it_d = w_it_static if primary == 1 
egen tot_w_d = total(w_it_d)
sum tot_w_d // this sums to one because it's on omega_1 only as proven in Prop. 3


// Q: Compare them to the sample weights of each horizon.
// generate population weights at each horizon
gen pop_d = population if primary == 1
egen tot_pop_d = total(pop_d)
gen w_sample = population/tot_pop_d
byso h (cohort) : egen w_h_pop = mean(w_sample) // get horizon specific w_it_static
twoway (scatter w_h_pop h if primary == 1) ///
		(scatter w_h h if primary == 1 ), ///
			legend(label(1 "Population weights") ///
				   label(2 "Static TWFE weight"))
// ANS: TWFE weights are decreasing in h while the population weights are 
// increasing because the sample size increases over time.
preserve
	collapse (mean) population, by(year)
	scatter population year
restore

// In your view, does the static regression coefficient provide a useful 
// summary of causal effects in this setting? Discuss.
// ANS: if the BJS paper provides any conclusion, it is that the static TWFE
// is exactly wrong because if treatment effects are heterogeneous, then the 
// later horizons will be weighted negatively as we see in the horizon specifc
// weights, w_h.



