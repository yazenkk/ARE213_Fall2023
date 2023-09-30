* ============================================================================= *
* 							ARE 213: Problem set 1
* 			Group members: Rajdev Brar, Yazen Kashlan, Cassandra Turk 
* ============================================================================= *
/*

	Title: 		are213_pset1.do

 	Outline:

 	Input: 		pset1.dta

	Output:		pset1_cleaned.dta

	Modified:	Rajdev Brar on 23 Sep 2023

*/
* ============================================================================= *

	clear all
	clear matrix

	set more off
	set varabbrev off
	set linesize 100

	cap log close
	set linesize 225



* ============================================================================= *
* Set initial configurations and globals + import data 
* ============================================================================= *
	
* global for main directory 
	if c(username) == "rajdevb" {
		global directory	"/Users/rajdevb/Dropbox/ARE213/Pset1"
	}


* globals for datasets
	global raw_data					"${directory}/raw_data/pset1.dta"
	global intermediate_output		"${directory}/intermediate_output"
		
	
* install required packages	
	* ssc install  dmout

* import data 
	use "${raw_data}", clear 
	
* ============================================================================= *
* Question 1
* ============================================================================= *

* ----------------------------------------------------------------------------- * 
* Question 1a: Fix missing values  (replace with .a if missing)
	* check missing values for vars: cardiac lung diabetes herpes chyper phyper pre4000 preterm tobacco cigar6 alcohol drink5 wgain
	
	tab1 cardiac lung diabetes herpes chyper phyper pre4000 preterm tobacco cigar6 alcohol drink5 wgain, m 
	
	* variables with 9=missing(=unknown/not stated)
	foreach var of varlist cardiac lung diabetes herpes chyper phyper pre4000 preterm alcohol  tobacco {
		replace 	 `var'=.a if (`var'==9) 
	}
	
	* variables with 6=missing(=unknown/not stated)
	replace cigar6=.a if (cigar6==6)
	
	* variables with 5=missing(=unknown/not stated)
	replace drink5=.a if (drink5==5)
	
	* variables with 99=missing(=unknown/not stated)
	replace wgain=.a if (wgain==99)

	
	 * foreach var with missing=.a, label value of .a 
	 foreach var of varlist cardiac lung diabetes herpes chyper phyper pre4000 preterm tobacco cigar6 alcohol drink5 wgain {
	label define `var' .a "Missing", modify 
	}
 
 
* check tabulations to see missing values have been recoded 
	tab1 cardiac lung diabetes herpes chyper phyper pre4000 preterm tobacco cigar6 alcohol drink5 wgain, m

  
* ----------------------------------------------------------------------------- * 
* Question 1b: Recode indicator variables

* indicator variables: rectype pldel3 dmar csex anemia cardiac lung herpes chyper phyper pre4000 preterm tobacco alcohol  

	recode rectype (2=0)
	lab define rectype_lab 0 "Nonresident" 1 "Resident", add
	lab values rectype rectype_lab 
	
	recode pldel3 (2=0) 
	lab define pldel3_lab  0 "Not in a hospital" 1 "In a hospital", add 
	lab value pldel3 pldel3_lab 
	
	recode dmar (2=0)
	lab define dmar_lab 0 "Unmarried" 1 "Married", add
	lab value dmar dmar_lab 
	
	recode csex (2=0)
	lab define csex_lab 0 "Female" 1 "Male", add 
	lab value csex csex_lab 
	
	recode anemia cardiac lung herpes chyper phyper pre4000 preterm tobacco alcohol  (2=0)
	lab define yesno_lab 0 "No" 1 "Yes", add 
	lab values anemia cardiac lung herpes chyper phyper pre4000 preterm tobacco alcohol yesno_lab    
	
	
* unordered categorical variables 	
	* recode mrace3 as a set of indicator variables 
	tab mrace3, gen(mrace3_)
	lab var mrace3_1 "Race of mother: Black" 
	lab var mrace3_2 "Race of mother: Not white or black" 
	lab var mrace3_3 "Race of mother: White"
	lab values mrace3_? yesno_lab 

* coarsen ormoth orfath into indicator variables 
	clonevar hisp_fath=orfath
	clonevar hisp_moth=ormoth
	recode hisp_moth hisp_fath (2=1) (3=1) (4=1) (5=1)
	lab define hisp_moth_lab 0 "Non-hispanic origin of mother" 1 "Hispanic origin of mother" , add
	lab define hisp_fath_lab 0 "Non-hispanic origin of father" 1 "Hispanic origin of father" , add
	lab values hisp_moth hisp_fath hisp_mot_lab 
	lab var hisp_moth "Hispanic origin of mother" 
	lab var hisp_fath "Hispanic origin of father"
	tab1 hisp_moth hisp_fath, m
		
* drop stresfip, birmon, and weekday
	tab1 stresfip birmon weekday, m 
	drop stresfip birmon weekday

* ----------------------------------------------------------------------------- * 
* Question 1c: Produce analysis dataset 

* drop observations with any missing values
	foreach var of varlist * { 
	drop if mi(`var')
	}
	
* PENDING: ARE missing values non-random 	

* ----------------------------------------------------------------------------- * 
* Question 1d: Generate summary table 
* PENDING
	
* ============================================================================= *
* Question 2
* ============================================================================= *
* ----------------------------------------------------------------------------- * 
* Question 2a: Compute mean difference in birthweight by smoking status 

	
	* difference in means table: birthweight by mother's smoker status 
	dmout dbrwt, by(tobacco) 
* PENDING: OUTSHEET 
* PENDING: Do we need to do manually 
	
	* means in birthweight by number of cigars smoked by mother on average 
	tabstat dbrwt, by(cigar6) stats(mean N)
* PENDING: outsheet


* ----------------------------------------------------------------------------- * 
* Question 2b: 
	
	* outsheet list of all variables to manually classify as controls or not 
	preserve
		describe, replace clear 
		list
	restore
	
	
* create global of controls 
	global 	control_vars 	alcohol mrace3_2 mrace3_3 hisp_moth ///
							adequacy cardiac pre4000 phyper chyper diabetes anemia lung wgain ///
							dmeduc dgestat dmage csex dmar  totord9 isllb10 dlivord dplural 
							


* ----------------------------------------------------------------------------- * 
* ============================================================================= *
* Question 3: 
* ============================================================================= *
* ----------------------------------------------------------------------------- * 
* Question 3a: Basic, uninteracted linear regression model to estimate impact of smoking  

local num_controls: list sizeof control_vars
di `num_controls'
 
	* without controls 
	eststo: reg dbrwt tobacco , robust 

	* with controls 
	eststo: reg dbrwt tobacco $control_vars, robust 
	
	* drop controls one at a time 
	forvalues i=1/`num_controls' {
		local control_num: word `i' of $control_vars 
		unab varlist: $control_vars 
		unab exclude: `control_num' 
		local control_exclude: list varlist-exclude 
		eststo: reg dbrwt tobacco `control_exclude', robust	
	}
	
	esttab * using "${intermediate_output}/reg_output.csv", replace ///
					cells(b(fmt(3) pvalue(p) star) se(par fmt(3))) 

* ----------------------------------------------------------------------------- * 
* Question 3b: 
* PENDING

* ----------------------------------------------------------------------------- * 
* Question 3c: 
* PENDING


* ----------------------------------------------------------------------------- * 
* Question 3d:  Add "bad controls"
* PENDING 

* ----------------------------------------------------------------------------- *  
* Question 3e: Oaxaca-Blinder estimator for ATE and ATT
* PENDING 

			
	foreach var of varlist $control_vars {
	* gen var = (X_i -X)	
	egen mean_`var' = mean(`var')
	gen diffmean_`var'=`var'-mean_`var'
	* gen (Xi-X)Di 
	gen int_`var'=diffmean_`var'*tobacco
	}
	
	* Model for group 1 = ATE 
	reg dbrwt $control_vars tobacco int_*, robust
	
	oaxaca dbrwt  $control_vars, by(tobacco) noisily
e

.         reg dbrwt $control_vars tobacco int_*

      Source |       SS           df       MS      Number of obs   =   114,616
-------------+----------------------------------   F(45, 114570)   =   1727.96
       Model |  1.5867e+10        45   352609397   Prob > F        =    0.0000
    Residual |  2.3379e+10   114,570  204060.953   R-squared       =    0.4043
-------------+----------------------------------   Adj R-squared   =    0.4041
       Total |  3.9247e+10   114,615  342421.902   Root MSE        =    451.73

-------------------------------------------------------------------------------
        dbrwt |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
--------------+----------------------------------------------------------------
      alcohol |  -23.91911   20.86971    -1.15   0.252    -64.82342     16.9852
     mrace3_2 |  -173.6592   9.792702   -17.73   0.000    -192.8527   -154.4656
     mrace3_3 |  -132.0141   5.201656   -25.38   0.000    -142.2093   -121.8189
    hisp_moth |  -89.19239   7.890132   -11.30   0.000    -104.6569   -73.72785
     adequacy |   -24.0311   2.953937    -8.14   0.000    -29.82077   -18.24143
      cardiac |  -18.58678   17.43184    -1.07   0.286    -52.75291    15.57935


* ============================================================================= *
* Question 4: PROPENSITY SCORE MATCHING  
* ============================================================================= *
* ----------------------------------------------------------------------------- * 
* Question 4a: propensity score using logit with nonlinear terms and interactions 

* ----------------------------------------------------------------------------- * 
* Question 4b: 

* ----------------------------------------------------------------------------- * 
* Question 4c: 

* ----------------------------------------------------------------------------- * 
* Question 4d: 

* ----------------------------------------------------------------------------- * 
* Question 4e: 


* ============================================================================= *
* Question 5: DOUBLY-ROBUST METHODS  
* ============================================================================= *
* ----------------------------------------------------------------------------- * 
* Question 5a: 

* ----------------------------------------------------------------------------- * 
* Question 5b: 



