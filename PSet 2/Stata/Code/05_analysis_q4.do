/*
Title: 		05_analysis_q4.do
Outline:	Question 4, PSet 2 
*/


* ============================================================================= *
* 2c 
	use "$dta_loc/pset2_q1", clear
	rename ln_fat_pc log_fatal_per_cap 
	byso cohort: egen w_g = count(cohort)
	replace w_g = w_g/23 // 23 is number of periods (works due to balance)

preserve
	keep cohort w_g
	duplicates drop
	egen tot_w_g = total(w_g)
	assert tot_w_g == 48 // states
	replace w_g = w_g/tot_w_g // get relative weights
	drop tot_w_g
	lab var w_g "Cohort weight"
	
	tempfile est_w_g
	save 	`est_w_g'
restore

	merge m:1 cohort using `est_w_g' 
	assert _merge==3
	drop _merge 

	* make kdensities for 1986 as an example
		* make variable for change in pdf across periods 
		gen control_logfatal=log_fatal_per_cap if prim_ever==0
		gen treat1986_logfatal=log_fatal_per_cap if cohort==1986
		
		gen diff1986_logfatal = control_logfatal - treat1986_logfatal 

		twoway (kdensity log_fatal_per_cap if prim_ever==1 & primary==0 & cohort==1986) (kdensity log_fatal_per_cap if prim_ever==0 & primary==0 & year<1986, lpattern(dash)), ytitle() xtitle(Y(0)= "Log fatalities per capita") title("PDF in pre-treatment period (1986 cohort)") scheme(swift_red) legend(label(1 "Treated") label(2 "Comparison")) name(kdensity1, replace)
		twoway (kdensity log_fatal_per_cap if prim_ever==1 & primary==1 & cohort==1986) (kdensity log_fatal_per_cap if prim_ever==0 & primary==0 & year>=1986, lpattern(dash)), ytitle() xtitle(Y(0)= "Log fatalities per capita") title("PDF in post-treatment period (1986 cohort)") scheme(swift_red) legend(label(1 "Treated") label(2 "Comparison")) name(kdensity2, replace)
		
		graph combine kdensity1 kdensity2 
		
		kdensity log_fatal_per_cap if prim_ever==1 & primary==0 & cohort==1986, nograph generate(a1 b1)  
		kdensity log_fatal_per_cap if prim_ever==1 & primary==0 & year<1986, nograph generate(a2 b2)  
		kdensity log_fatal_per_cap if prim_ever==1 & primary==1 & cohort==1986, nograph generate(a3 b3)
		kdensity log_fatal_per_cap if prim_ever==0 & primary==0 & year>=1986, nograph generate(a4 b4)
		gen diff_control = a1-a3

		twoway (kdensity fat_pc if prim_ever==1 & primary==0 & cohort==1986) (kdensity fat_pc if prim_ever==0 & primary==0 & year<1986, lpattern(dash)), ytitle() xtitle(Y(0)= "Log fatalities per capita") title("PDF in pre-treatment period (1986 cohort)") scheme(swift_red) legend(label(1 "Treated") label(2 "Comparison")) name(kdensity3, replace)
		twoway (kdensity fat_pc if prim_ever==1 & primary==1 & cohort==1986) (kdensity fat_pc if prim_ever==0 & primary==0 & year>=1986, lpattern(dash)), ytitle() xtitle(Y(0)= "Log fatalities per capita") title("PDF in post-treatment period (1986 cohort)") scheme(swift_red) legend(label(1 "Treated") label(2 "Comparison")) name(kdensity4, replace)
			graph combine kdensity3 kdensity4 
	

		
* ============================================================================= *
* Question 4a
/*
Build synthetic control for California 
Report which states comprise this synthetic control and how well it matches predictors 
* Show estimates and perform statistical inference on them 
*/ 
* ============================================================================= *
* Estimating effects for California only
* never-treated groups= donors
* ssc install outreg2 

use "$dta_loc/pset2", clear

	gen 	log_fatal_per_cap=log(fatalities/(population*1000))
	lab var log_fatal_per_cap "Log of fatalities per capita"

	byso state : egen prim_ever = max(primary)
	
	
	tsset state year  // declare dataset as panel
		
	drop if prim_ever==1 & state!=4 // drop states that were treated other than CA
	unique state 
	
* predictors are pre-treatment log fatalities and other covars 
	synth log_fatal_per_cap  beer(1981(1)1992) precip(1981(1)1992) college(1981(1)1992) rural_speed(1981(1)1992) population(1981(1)1992) unemploy(1981(1)1992) totalvmt(1981(1)1992) snow32(1981(1)1992)  log_fatal_per_cap(1981(1)1992) , trunit(4) trperiod(1993)   fig  resultsperiod(1981(1)2002)  keep(synth_results, replace)

	graph export "$oput_loc/q4a_synthCA.png", replace 
	
* graph california with rest of US that did not implement these laws 
	bys year: egen avg_log_fatal_per_cap = mean(log_fatal_per_cap) if state!=4
	lab var avg_log_fatal_per_cap "Average log fatalities per capita"
	
	twoway (tsline log_fatal_per_cap if state==4)  ///
	(tsline avg_log_fatal_per_cap, lcolor(black)), /// 
	xline(1993) ///
	ytitle(Log fatalities per capita) ttitle(Year) ///
	title(California vs. donor states) ///
	caption(Donor states are those who never adopted primary law) ///
	legend(on rows(1) size(medsmall) position(6)) ///
	legend(label(1 "California") label(2 "Average of donor states"))  ///
	scheme(swift_red)
	graph export "$oput_loc/q4a_CAvsUS.png", replace 

	* outsheet synthetic CA composition 
preserve
	use "synth_results.dta", clear 
	keep _Co_Number _W_Weight
	rename _Co_Number State
	rename _W_Weight Weight 
	keep if Weight!=0
	sort Weight
	lab var State "State"
	lab var Weight "Weight"
	
	listtex State Weight using "$oput_loc/q4a_synthCA_tab.tex", replace  
restore

preserve
	* gap: synthetic and real califonria
	use "synth_results.dta", clear 
	gen gap=_Y_treated-_Y_synthetic
	twoway (line gap  _time ), xline(1993) yline(0) scheme(swift_red) ytitle(Gap in log fatalities per capita, size(medsmall)) ttitle(Year, size(medsmall)) ///
	title(Gap in log fatalities per capita between California and synthetic California, size(med)) 
	graph export "$oput_loc/q4a_gapsynth.png", replace 
restore 

	* difference in variables between synthetic CA and CA 
	matrix synthbal=e(X_balance)
	matrix rownames synthbal = "Beer consumption per cap (gals)" "Precipitation (inches)" "Percent college grads" "Rural interstate speed limit" "Population (thousands)" "Unemployment rate" "Vehicle miles traveled (VMT)" "Snow (inches)There" "Log fatalities per capita"
	esttab matrix(synthbal) using "$oput_loc/q4a_diff_synth.tex", replace  ///
	collabels("California" "Synthetic California") 
	
	* estimation 
	synth_runner log_fatal_per_cap  beer(1981(1)1993) precip(1981(1)1993) college(1981(1)1993) rural_speed(1981(1)1993) population(1981(1)1993) unemploy(1981(1)1993) totalvmt(1981(1)1993) snow32(1981(1)1993)  log_fatal_per_cap(1981(1)1993) , trunit(4) trperiod(1993)  gen_vars  
	
	* figure: log fatalities per capita in California vs. placebo gaps in control states 
	single_treatment_graphs, trlinediff(-1) raw_gname(primary_raw) ///
	effects_gname(primary_effects)  
	graph export "$oput_loc/q4a_synth_estimation.png", replace
	

* ============================================================================= *
* Question 4b 
* ============================================================================= *
* (b) Estimate the effects for California using synthetic DiD. Report and discuss the weights the estimator places on untreated units and on various pre-treatment periods.

* ssc install sdid, replace

/*sdid Y S T D [if] [in], vce(method) seed(#) reps(#) covariates(varlist [, method])
                        zeta_lambda(real) zeta_omega(real) min_dec(real) max_iter(real)
                        method(methodtype) unstandardized graph_export([stub] , type) mattitles
                        graph g1on g1_opt(string) g2_opt(string) msize() 
*/ 
eststo clear 

	local Y_sdid log_fatal_per_cap // outcome variable
	local S_sdid state // unit variable
	local T_sdid year // time variable 	
	local D_sdid primary // dummy of treatement 


	eststo sdid_1: sdid `Y_sdid' `S_sdid' `T_sdid' `D_sdid',  /// 
			vce(placebo) ///   
			method(sdid) ///
			reps(100)  /// 
			graph g1on g1_opt(xtitle("")  scheme(white_tableau)) g2_opt(scheme(white_tableau)) ///
			graph_export($oput_loc/q4b_, .png)
	//  vce(placebo), not bootstrap or jackknife because few treated units  
	// repititions for bootstrap and placebo SE 

	esttab sdid_1 using "$oput_loc/q4b_sdid.tex", nostar label  tex  replace  se
	
	covariates(beer precip college rural_speed population snow32 unemploy totalvmt) ///
						
* ============================================================================= *
* Question 4c
* ============================================================================= *

	use "$dta_loc/pset2_q1", clear
	isid state year

	sort state year primary secondary
	drop college beer unemploy totalvmt precip snow32 rural_speed urban_speed

	// 1) Get predictions for alpha_i and beta_t by OLS in omega_0 
	reg ln_fat_pc i.state i.year if primary == 0


	// 2) Get \hat{tau}
	// 2a) Compute \hat{y(0)} = in omega_1 population
	predict yhat, xb
	// 2b) Compute \hat{tau} = y-\hat{y(0)}
	gen tau_hat_it = ln_fat_pc - yhat if primary == 1 // 

	// 3) Estimate tau_w by a weighted sum over omega_q
	// For weights, w_it, I follow Liu et al. (2022) AJPS who use a regular average
	gen h = year - cohort if cohort != 999
	byso h (cohort) : egen ATT_h_Liu = mean(tau_hat_it) if (state==4) // get horizon specific ATT

	// why are these ATTs much larger than ATT dCDH? 
	// Are my tau_hats right? What about my weights/averaging method?
	label var h "Horizon"
	label var ATT_h_Liu "ATT_h (Imputation ATTs by horizon, weighted regularly)"

	egen ATT_Liu = mean(tau_hat_it) if state==4 // tau_w (tau given weights)
	label var ATT_Liu "ATT Liu et al (Imputation ATT, weighted regularly)"

	line yhat year  if state==4, scheme(swift_red) title("Predicted outcome for California") ytitle("Predicted log fatalities per capita for California") xline(1993)
	graph export "$oput_loc/q4c.png", replace 







