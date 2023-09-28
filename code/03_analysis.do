* ============================================================================= *
/*

	Title: 		are213_pset1.do

 	Outline:	Analysis

 	Input: 		pset1_clean.dta

	Output:		tables

	Modified:	Rajdev Brar on 23 Sep 2023
				Yazen K 9/27/2023

*/
* ============================================================================= *



* ============================================================================= *
* Question 1 (c-d)
* ============================================================================= *

* ----------------------------------------------------------------------------- * 
* Question 1c: Produce analysis dataset 
//Q: Do the data appear to be missing completely at random?

* import data 
use "$dta_loc/data/pset1_clean_miss.dta", clear


// Compare group averages
local balance_list dbrwt ///
					tobacco ///
					mrace3_3 ///
					hisp_moth ///
					dmeduc ///
					dmage ///
					male /// csex
					alcohol ///
					adequacy ///
					phyper ///
					diabetes ///
					anemia ///
					dgestat ///
					totord9 ///
					isllb10 ///
					dlivord ///
					dplural
					
iebaltab `balance_list', ///
	grpvar(miss_any) ///
	rowvarlabels ///
	stats(desc(sd) pair(t)) ///
	nostars ///
	savetex("$do_loc/tables/table0_missingbalance.tex") ///
	addnote("Notes: Insert footnote") 				///
	nonote 								/// 
	texnotewidth(1) 		///	
	replace

preserve
	// adjust footnote width
	import delimited "$do_loc/tables/table0_missingbalance.tex", clear
	fix_import
	count if strpos(text, "\multicolumn{6}") > 0 // confirm there's that line to fix
	assert `r(N)' == 1
	replace text = subinstr(text, "\multicolumn{6}", "\multicolumn{7}", .) if ///
		strpos(text, "Notes:") > 0
	outfile using "$do_loc/tables/table0_missingbalance.tex", ///
		noquote wide replace

restore

/*
ANS: 
No, there are some differences in covariate averages between observations with 
no and some nmissing observations. One limitation to my test is that the standard
errors are small because the sample is large. The key variable to look at here is 
the treatment variable, tobacco. Indeed, the dropped observations exhibit a 
larger average rate of tobacco use during pregnancy.
*/




* ----------------------------------------------------------------------------- * 
* Question 1d: Generate summary table 

*Import data
use "$dta_loc/data/pset1_clean.dta", clear

local covar_list 	mrace3_3 ///
					moth_hisp /// hisp_moth
					dmeduc ///
					dmage ///
					csex /// 
					alcohol ///
					adequacy ///
					phyper ///
					diabetes ///
					anemia ///
					dgestat ///
					totord9 ///
					isllb10 ///
					dlivord ///
					dplural

// generate balance table
iebaltab `covar_list', ///
	grpvar(tobacco) ///
	savetex("$do_loc/tables/table1_balance.tex") ///
	rowvarlabels ///
	total ///
	stats(desc(sd) pair(t)) ///
	nostars ///
	addnote("Notes: Insert footnote") 				///
	nonote 								/// 
	replace
	
// adjust footnote width of latex output
preserve
	import delimited "$do_loc/tables/table1_balance.tex", clear
	fix_import
	count if strpos(text, "\multicolumn{8}") > 0 // confirm there's that line to fix
	assert `r(N)' == 1
	replace text = subinstr(text, "\multicolumn{8}", "\multicolumn{9}", .) if ///
		strpos(text, "Notes:") > 0
	outfile using "$do_loc/tables/table1_balance.tex", ///
		noquote wide replace
restore




	
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
	local 	control_vars 	alcohol mrace3_2 mrace3_3 hisp_moth ///
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



