/*
Title: 		05_analysis_q4.do
Outline:	Question 4, PSet 2 
*/

* ============================================================================= *

/* QUESTION 3A: Report the de Chaisemartin and D’Haultfouille’s manual averaging estimates of the dynamic ATTs for the horizons where a reasonable sample is available.

de Chaisemartin and D'Haultfoeuille (AER 2020) look at h=0; ie. what happens right after treatment.
*/ 
 
* ssc install did_multiplegt_dyn

* generate cohort size var 

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

* did_multiplegt Y G T D, options
* Y= outcome variable
* G= group variable
* T= time period variable (assumes time period is evenly spaced)
* D= treatment variable 
* options: 
	* effects(#) gives the number of event-study effects to be estimated 
	* placebo(#) gives the number of placebo estimators to be computed 

* breps(50)- default (without specifying) is command executes 50 bootstrap replications 
* robust_dynamic option- computes the DID_l estimators introduced in CDH  (2020)
* weight(varlist) gives the name of a variable to be used to weight the data 

did_multiplegt_dyn log_fatal_per_cap  state year primary,  graph_off save_results($oput_loc/q3a_cdh_results)  effects(19) // weight(w_g)
e
* my average = -0.032
* yazen's average = -0.016 // yazen used weights for cohort size 
* cass's = -0.012




/*
h	ATT_h_dCDH	ATT_h_SnA
0	-.0112402	-.0112328
1	-.0160019	-.0159756
2	-.0177748	-.0182887
3	-.0164864	-.0172799
4	-.0193444	-.0209481
5	-.0223849	-.0250976
6	-.0196936	-.0216656
7	-.0145641	-.0170061
8	-.0208143	-.0224303
9	-.0174865	-.0192162
10	-.0172894	-.0185355
11	-.0183952	-.0204713
12	-.0203281	-.0235469
13	-.015268	-.0192468
14	-.0141425	-.0178426
15	-.0145673	-.0180682
16	-.0207922	-.0256901
17	-.0176296	-.0210095
18	-.0041717	-.0052039
19	-.0043965	-.0053057
*/ 

* QUESTION 3B  
/* Report the Borusyak, Jaravel, and Spiess’s imputation estimates for the same
estimands.

*/

* ssc install did_imputation
* ssc install reghdfe // did_imputation requires a recent version of reghdfe 

*  did_imputation Y i t Ei [if] [in] [estimation weights] [, options]
* did_imputation Y id t Ei, fe(id t) horizons(#) pretrends(#)
* Y = outcome variable = log fatalities per capita = log_fatal_per_cap
* i = variable for unique unit id 
* t = variable for calendar year 
* Ei = variable for unit-specific date of treatment (missing= never treated) 
gen year_treat=primary
replace year_treat=year if primary==1
replace year_treat=. if primary==0

did_imputation log_fatal_per_cap state year year_treat, fe(state year)
* very close to Yazen's avg of -0.138, mine is -0.107
/*
h	ATT_h_Liu
0	-.0535273
1	-.0650679
2	-.0675896
3	-.0637709
4	-.0852289
5	-.096785
6	-.1155177
7	-.0927107
8	-.1540992
9	-.1365185
10	-.135313
11	-.1445146
12	-.1577798
13	-.1439597
14	-.1375055
15	-.1407373
16	-.204112
17	-.2247997
18	-.2673867
19	-.2747974

*/ 
	
* check out ssc install event_plot 


* Question 3c
* did_multiplegt_dyn log_fatal_per_cap  state year primary,  graph_off save_results($oput_loc/q3c_cdh_results)    weight(population)

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
	synth log_fatal_per_cap  beer(1981(1)1993) precip(1981(1)1993) college(1981(1)1993) rural_speed(1981(1)1993) population(1981(1)1993) unemploy(1981(1)1993) totalvmt(1981(1)1993) snow32(1981(1)1993)  log_fatal_per_cap(1981(1)1993) , trunit(4) trperiod(1993)   fig  resultsperiod(1981(1)2003)  keep(synth_results, replace)

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
	
	
	

effects_ylabels(-30(10)30) effects_ymax(35) effects_ymin(-35) 
sysuse synth_smoking, clear
tsset state year
synth_runner cigsale beer(1984(1)1988) lnincome(1972(1)1988) retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), ///
	trunit(3) trperiod(1989) gen_vars
	

effect_graphs , trlinediff(-1) effect_gname(cigsale1_effect) tc_gname(cigsale1_tc)
	
pval_graphs , pvals_gname(cigsale1_pval) pvals_std_gname(cigsale1_pval_t)

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
			covariates(beer precip college rural_speed population snow32 unemploy totalvmt) ///
			graph g1on g1_opt(xtitle("")  scheme(white_tableau)) g2_opt(scheme(white_tableau)) ///
			graph_export($oput_loc/q4b_, .png)
	//  vce(placebo), not bootstrap or jackknife because few treated units  
	// repititions for bootstrap and placebo SE 

	esttab sdid_1 using "$oput_loc/q4b_sdid.tex", nostar label  tex  replace  se

						
* ============================================================================= *
* Question 4c
* ============================================================================= *

