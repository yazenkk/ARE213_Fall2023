* ============================================================================= *
/*

	Title: 		03_analysis.do

 	Outline:	Analysis

 	Input: 		pset1_clean.dta

	Output:		tables


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
					dmeduc_1 dmeduc_2 dmeduc_3  ///
					dmage ///
					csex /// 
					alcohol ///
					phyper ///
					diabetes ///
					anemia ///
					dgestat ///
					dlivord ///
					dplural_1 
/* PENDING: FIGURE OUT WHY THIS IEBALTAB ISN'T RUNNING "stats()" not allowed 
	
iebaltab `balance_list', ///
	grpvar(miss_any) ///
	rowvarlabels ///
	stats(desc(sd) pair(t)) ///
	nostars ///
	savetex("$do_loc/tables/table0_balance_miss.tex") ///
	addnote("Notes: Insert footnote") 				///
	nonote 								/// 
	texnotewidth(1) 		///	
	replace
 
preserve
	// adjust footnote width
	import delimited "$do_loc/tables/table0_balance_miss.tex", clear
	fix_import
	count if strpos(text, "\multicolumn{6}") > 0 // confirm there's that line to fix
	assert `r(N)' == 1
	replace text = subinstr(text, "\multicolumn{6}", "\multicolumn{7}", .) if ///
		strpos(text, "Notes:") > 0
	outfile using "$do_loc/tables/table0_balance_miss.tex", ///
		noquote wide replace

restore
  */



* ----------------------------------------------------------------------------- * 
* Question 1d: Generate summary table 

*Import data
use "$dta_loc/data/pset1_clean.dta", clear

local covar_list 	mrace3_3 ///
					hisp_moth /// 
					dmeduc_1 dmeduc_2 dmeduc_3   ///
					dmage ///
					csex /// 
					alcohol ///
					phyper ///
					diabetes ///
					anemia ///
					dgestat ///
					dlivord ///
					dplural_1

/*		 PENDING: FIX		
// generate balance table
iebaltab `covar_list', ///
	grpvar(tobacco) ///
	savetex("$do_loc/tables/table1_balance.tex") ///
	rowvarlabels ///
	total ///
	stats(desc(sd) pair(t)) ///
	nostars ///
	addnote("Notes: Insert footnote") 	///
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
*/ 


	
* ============================================================================= *
* Question 2
* ============================================================================= *
* ----------------------------------------------------------------------------- * 
* Question 2a: Compute mean difference in birthweight by smoking status 

	
	* difference in means table: birthweight by mother's smoker status 
	reg dbrwt tobacco 

* PENDING: OUTSHEET 
	
	* means in birthweight by number of cigars smoked by mother on average 
	tabstat dbrwt, by(cigar6) stats(mean N)

* ----------------------------------------------------------------------------- * 
* Question 2b: 
	
	
* create global of controls 
	global 	control_vars 	alcohol mrace3_2 mrace3_3 hisp_moth ///
							cardiac pre4000 phyper chyper diabetes anemia lung  ///
							dmeduc_1 dmeduc_2 dmeduc_3 dgestat /// 
							csex dmar dlivord dplural phyper /// 
							adequacy_2 adequacy_3 cntocpop_2 cntocpop_3 cntocpop_4  ///
							isllb10_2 isllb10_3 isllb10_4 isllb10_5 isllb10_6 isllb10_7 isllb10_8 isllb10_9 isllb10_10 ///
							totord9_2 totord9_3 totord9_4 totord9_5 totord9_6 totord9_7 totord9_8 dplural_1 
			
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
	

	esttab * using "${intermediate_output}/reg_output.csv", replace ///
					cells(b(fmt(3) pvalue(p) star) se(par fmt(3))) 
					
*  PENDING: ADD TO LATEX
					
* ----------------------------------------------------------------------------- * 
* Question 3b: Results sensitive to dropping controls one at a time?

preserve 

	

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
			
restore 
* PENDING: ADD TO LATEX 

* ----------------------------------------------------------------------------- * 
* Question 3c: Control for covariates in a more flexible functional form 

	gen dgestat_sq=dgestat*dgestat 
	gen dmage_sq=dmage*dmage
	gen int_tobacco_dmage=tobacco*dmage
	
	eststo q3c: reg dbrwt $control_vars tobacco dgestat_sq dmage_sq int_tobacco_dmage, robust 
* PENDING: Add to latex 
	
* ----------------------------------------------------------------------------- * 
* Question 3d:  Add "bad controls"

reg dbrwt tobacco $control_vars, robust 
reg dbrwt tobacco $control_vars omaps fmaps cigar6  drink5, robust 

* PENDING: Add to latex 

* ----------------------------------------------------------------------------- *  
* Question 3e: Oaxaca-Blinder estimator for ATE and ATT



global oaxaca_control_vars alcohol  mrace3_2 mrace3_3 hisp_moth cardiac anemia lung dmar csex pre4000 phyper chyper diabetes   

	* generate variables needed for oaxaca 
	foreach var of varlist $oaxaca_control_vars {
	* demean controls 
	egen `var'_mean=mean(`var')
	gen `var'demean=(`var'-`var'_mean)
	* interaction of tobacco with demeaned controls 
	gen `var'demeantobacco = `var'demean*tobacco
	}
	
	* oaxaca estimate via regression 
	reg dbrwt tobacco $oaxaca_control_vars *demeantobacco, robust 
	
	* 	estimating coeff
	reg dbrwt tobacco $oaxaca_control_vars if tobacco==1, robust 
	predict tob1h 
	
	reg dbrwt tobacco $oaxaca_control_vars if tobacco==0, robust 
	predict tob0h 
	
	* ATE 
	* oaxaca coefficient by differencing 
	gen oaxaca_ate =tob1h-tob0h
	di oaxaca_ate

* PENDING : add to latex 

e
* ============================================================================= *
* Question 4: PROPENSITY SCORE MATCHING  
* ============================================================================= *
* ----------------------------------------------------------------------------- * 
* Question 4a: propensity score using logit with nonlinear terms and interactions 

* ----------------------------------------------------------------------------- * 
* Question 4b: 
local covar_list 	mrace3_3 ///
					hisp_moth /// 
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
//


logit tobacco `covar_list'
predict phatx, pr

tab tobacco, sum(phatx )

sort `covar_list'

twoway (histogram phatx if tobacco==0, color(green%25)) ///
	   (histogram phatx if tobacco==1, color(red%25)), ///   
       legend(label(1 "Observed non-smokers") label(2 "Observed smokers")) ///
	   xtitle("Pr(tobacco{sub:i}=1|X{sub:i})") ///
	   saving("phatx_overlap", replace)

graph export "$do_loc/graphs/phatx_overlap.png", ///
	width(1200) height(900) ///
	replace


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



