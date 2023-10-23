/*
Title: 		05_analysis_q4.do
Outline:	Question 4, PSet 2 
*/

			
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
use "$dta_loc/pset2", clear

	gen 	log_fatal_per_cap=log(fatalities/(population*1000))
	lab var log_fatal_per_cap "Log of fatalities per capita"

	byso state : egen prim_ever = max(primary)
	
	
	tsset state year  // declare dataset as panel
		
	drop if prim_ever==1 & state!=4 // drop states that were treated other than CA
	unique state 
	
* predictors are only pre-treatment log fatalities 
	* synth independent_var: log_fatal_per_cap  
	* predictors log_fatal_per_cap  between 1981 and 1993  
	* trunit(4) trperiod(1993) - because unit affected by intervention is unit 4
	synth log_fatal_per_cap log_fatal_per_cap(1981(1)1993), trunit(4) trperiod(1993)   fig  resultsperiod(1981(1)2003)

* predictors are pre-treatment log fatalities and other covars 
	synth log_fatal_per_cap  beer(1981(1)1993) precip(1981(1)1993) college(1981(1)1993) rural_speed(1981(1)1993) population(1981(1)1993) snow32(1981(1)1993) unemploy(1981(1)1993) totalvmt(1981(1)1993) log_fatal_per_cap(1981(1)1993) , trunit(4) trperiod(1993)   fig  resultsperiod(1981(1)2003)  keep(synth_results, replace)
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
	legend(label(1 "California") label(2 "Aveage of donor states"))  ///
	scheme(swift_red)
	graph export "$oput_loc/q4a_CAvsUS.png", replace 
	
	use "synth_results.dta", clear 
	   

* ============================================================================= *
* Question 4b 
* ============================================================================= *
* (b) Estimate the effects for California using synthetic DiD. Report and discuss the weights the estimator places on untreated units and on various pre-treatment periods.



* ============================================================================= *
* Question 4c
* ============================================================================= *

