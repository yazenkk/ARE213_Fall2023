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
					dmar ///
					csex /// 
					alcohol ///
					phyper ///
					diabetes ///
					lung ///
					anemia ///
					pre4000 /// 
					dgestat ///
					dlivord ///
					dplural_1 
					
	
* PENDING YK to check
iebaltab `balance_list', ///
	grpvar(miss_any) ///
	rowvarlabels normdiff starsno /// 
	savetex("$do_loc/tables/table0_balance_miss.tex") ///
	tblnote("Notes: Insert footnote") 				///
	tblnonote 				/// 
	texnotewidth(1) replace  		
	
/*	
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

local covar_list 	dbrwt ///
					mrace3_3 ///
					hisp_moth ///
					dmeduc_1 dmeduc_2 dmeduc_3  ///
					dmage ///
					dmar ///
					csex /// 
					alcohol ///
					phyper ///
					diabetes ///
					lung ///
					anemia ///
					pre4000 /// 
					dgestat ///
					dlivord ///
					dplural_1

		
/* YK to fix 
// generate balance table
iebaltab `covar_list', ///
	grpvar(tobacco) ///
	savetex("$do_loc/tables/table1_balance.tex") ///
	rowvarlabels ///
	total ///
	starsno ///
	tblnote("Notes: Insert footnote") 	///
	tblnonote 	 						/// 
	replace normdiff  onerow
	
	
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
	eststo: reg dbrwt tobacco , robust
	esttab using "$do_loc/tables/table2_diffmeans.tex", nostar label  tex  replace  se
	eststo clear 
	
	* means in birthweight by number of cigars smoked by mother on average 
	tabstat dbrwt, by(cigar6) stats(mean N)


* ---------------------------------------------------------------------------- * 
* Question 2b: choose controls
	
* create global of controls 
	global covar_list alcohol mrace3_2 mrace3_3 hisp_moth ///
						adequacy_2 adequacy_3 ///
						cardiac pre4000 phyper diabetes anemia lung  ///
						dlivord dmeduc_1 dmeduc_2 dmeduc_3 dgestat /// 
						dmage dmar ///
						totord9_2 totord9_3 totord9_4 totord9_5 totord9_6 totord9_7 totord9_8 ///
						csex  /// 
						isllb10_2 isllb10_3 isllb10_4 isllb10_5 isllb10_6 isllb10_7 isllb10_8 isllb10_9 isllb10_10 ///
						dplural_1 
						

* ----------------------------------------------------------------------------- * 
* ============================================================================= *
* Question 3: 
* ============================================================================= *

* See 3a after 3b

* ----------------------------------------------------------------------------- * 
* Question 3b: Results sensitive to dropping controls one at a time?
use "$dta_loc/data/pset1_clean.dta", clear

eststo clear
preserve 

	local num_controls: list sizeof global(covar_list)
	di `num_controls'

	* drop controls one at a time 
	forvalues i=1/`num_controls' {
// 		dis "`i'"
		local control_num: word `i' of $covar_list 
		unab varlist: $covar_list 
		unab exclude: `control_num' 
		local control_exclude: list varlist-exclude 
		dis as error "Running reg dbrwt of tobacco and all but covar `control_num'"
		qui eststo: reg dbrwt tobacco `control_exclude', robust
		
		if inlist(`i', 8, 16, 24, 32, 37) {
			esttab using "$do_loc/tables/table_3b_`i'.tex",   		///
				style(tex)											///
				nogaps												///
				nobaselevels 										///
				noconstant											///
				nodepvars											/// remove ylabel
				label            									///
				varwidth(50)										///
				wrap 												///
				cells (b(fmt(2)) se(fmt(2) par))					///
				keep(tobacco) 	 									///
				stats(N, 											///
					  fmt(%9.0f)									///
					  labels("Observations")) 						///
				replace
				
			// clear estimates after tabulating what's regressed so far.
			eststo clear
		}
	}
restore 


* ----------------------------------------------------------------------------- * 
* Question 3a: Basic, uninteracted linear regression model to estimate impact of smoking  

	eststo clear
 
	* without controls 
	eststo: reg dbrwt tobacco , robust 
	qui estadd local covar_entry = "", replace

	* with controls 
	eststo: reg dbrwt tobacco $covar_list, robust 
	qui estadd local covar_entry = "X", replace
// 	sum $covar_list
					

* ----------------------------------------------------------------------------- * 
* Question 3c: Control for covariates in a more flexible functional form 

gen dgestat_sq=dgestat*dgestat 
gen dmage_sq=dmage*dmage
gen int_tobacco_dmage=tobacco*dmage

eststo q3c: reg dbrwt tobacco $covar_list dgestat_sq dmage_sq int_tobacco_dmage, robust 
	qui estadd local covar_entry = "X", replace

	
* ----------------------------------------------------------------------------- * 
* Question 3d:  Add "bad controls"
eststo q3d: reg dbrwt tobacco $covar_list omaps fmaps cigar6 drink5, robust
	qui estadd local covar_entry = "X", replace


// output tables 3a, c, & d
esttab using "$do_loc/tables/table_3acd.tex",   		///
	style(tex)											///
	nogaps												///
	nobaselevels 										///
	noconstant											///
	label            									///
	varwidth(50)										///
	wrap 												///
	cells (b(fmt(2)) se(fmt(2) par))					///
	stats(N												///
		  covar_entry, 									///
		  fmt(%9.0f)									///
		  labels("Observations" 						///
				 "Full list of covariates included")) 	///
	keep(tobacco 										///
		alcohol mrace3_2 hisp_moth						///
		adequacy_2 										///
		cardiac pre4000 								///
		dlivord dmeduc_1 dgestat dmage dmar 			///
		totord9_2 totord9_3 							///
		csex  											/// 
		isllb10_2 isllb10_3 							///
		dplural_1 										///
		dgestat_sq dmage_sq int_tobacco_dmage 			///
		omaps fmaps cigar6 drink5) 						///
	replace



* ----------------------------------------------------------------------------- *  
* Question 3e: Oaxaca-Blinder estimator for ATE and ATT
global oaxaca_covar_list alcohol mrace3_2 mrace3_3 hisp_moth ///
						adequacy_2 adequacy_3 ///
						cardiac pre4000 phyper diabetes anemia lung  ///
						dlivord dmeduc_1 dmeduc_2 dmeduc_3  /// 
						dmar ///
						totord9_2 totord9_3 totord9_4 totord9_5 totord9_6 totord9_7 totord9_8 ///				
						csex  /// 
						isllb10_2 isllb10_3 isllb10_4 isllb10_5 isllb10_6 isllb10_7 isllb10_8 isllb10_9 isllb10_10 ///
						dplural_1 

						
	* generate variables needed for oaxaca 
	foreach var of varlist $oaxaca_covar_list {
	* demean controls 
	egen `var'_mean=mean(`var')
	gen `var'demean=(`var'-`var'_mean)
	* interaction of tobacco with demeaned controls 
	gen `var'demeantobacco = `var'demean*tobacco
	}
	
	eststo clear 
	* oaxaca estimate via regression 
	reg dbrwt tobacco $oaxaca_covar_list *demeantobacco, robust 
	
	* estimating coeff
	eststo: reg dbrwt  $oaxaca_covar_list if tobacco==1, robust 
	predict tob1h 
	predict tob1h_1 if tobacco==1
	
	eststo: reg dbrwt  $oaxaca_covar_list if tobacco==0, robust 
	predict tob0h 
	predict tob0h_1 if tobacco==1
	
	esttab using "$do_loc/tables/table3e_oaxaca.tex", nostar label  tex  replace  ///
	style(tex)											///
	nogaps												///
	nobaselevels 										///
	noconstant											///
	varwidth(50)										///
	wrap 												///
	cells (b(fmt(2)) se(fmt(2) par)) mtitle("birthweight if tobacco=1" "birthweight if tobacco=0")					

	foreach var of varlist tob1h tob1h_1 tob0h tob0h_1 { 
	egen mean_`var' = mean(`var')
	}
	
	* ATE 
	* oaxaca coefficient by differencing 
	gen oaxaca_ate = mean_tob1h - mean_tob0h
	di oaxaca_ate
	
	* ATT 
	gen oaxaca_att = mean_tob1h_1 - mean_tob0h_1
	di oaxaca_att 
	
	

* PENDING : add to latex 



* ============================================================================= *
* Question 4: PROPENSITY SCORE MATCHING  
* ============================================================================= *
* ----------------------------------------------------------------------------- * 
* Question 4a: propensity score using logit with nonlinear terms and interactions 

// run logit regression and predict E[D|X]?
eststo clear
eststo: logit tobacco $covar_list
predict phatx, pr

tab tobacco, sum(phatx)

// sort $covar_list // browse predictions with covariate cells
// br $covar_list phatx

esttab using "$do_loc/tables/table_4a.tex",   			///
	style(tex)											///
	nogaps												///
	nobaselevels 										///
	noconstant											///
	label            									///
	varwidth(50)										///
	wrap 												///
	cells (b(fmt(2)) se(fmt(2) par))					///
	stats(N, 											///
		  fmt(%9.0f)									///
		  labels("Observations")) 	///
	eqlabel(none) ///
	replace

* ----------------------------------------------------------------------------- * 
* Question 4b: testing overlap

// assert phat \in (0,1)
assert inrange(phatx, 0, 1) & !inlist(phatx, 0, 1) 

// plot and export histogram of p(X)
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

// Assess balance
** old binning approach
// xtile phatx_bins = phatx, nq(10)

** New binning approach. Equal sized bins, not on deciles
gen phatx_bins = .
forval i = 1/10 {
	replace phatx_bins = `i' if `i'/10-1/10 <= phatx & phatx < `i'/10 // omit upper bound
}

// assert overlap within each bin
forval i = 1/10 {
	qui sum tobacco if phatx_bins == `i'
	assert !inlist(`r(mean)', 0, 1)
}
	
	
// Within bins of p(X) compare X among treated and controls
// run regs controlling for bins so that D is within bin

iebaltab $covar_list, ///
	grpvar(tobacco) ///
	fixedeffect(phatx_bins) ///
	rowvarlabels ///
	starsno  ///
	savetex("$do_loc/tables/table4_balance_pbins.tex") ///
	tblnote("Notes: Insert footnote") 				///
	tblnonote 								/// 
	texnotewidth(1) 		///	
	replace  
/*
preserve
	// adjust footnote width
	import delimited "$do_loc/tables/table4_balance_pbins.tex", clear
	fix_import
	count if strpos(text, "\multicolumn{6}") > 0 // confirm there's that line to fix
	assert `r(N)' == 1
	replace text = subinstr(text, "\multicolumn{6}", "\multicolumn{7}", .) if ///
		strpos(text, "Notes:") > 0
	outfile using "$do_loc/tables/table4_balance_pbins.tex", ///
		noquote wide replace

restore
*/


* ----------------------------------------------------------------------------- * 
* Question 4d: Blocking

// Regress Y on D, p(X), and p(X)D
reg dbrwt tobacco##phatx_bins
mat A = r(table)
mat list A

// collect base group mean
mat c = A["b","1.tobacco"]
mat list c
local baseeffect = c[1,1]

// collect bin-specific means
mat b = A["b", "1.tobacco#1.phatx_bins" .. "1.tobacco#10.phatx_bins"]
mat list b

// initialize ATE and ATT locals to be updated in loop
local ate_numerator = 0 
local att_numerator = 0 

// Calculate ATE and ATT
forval i = 1/`=colsof(b)' {
	
	// get beta from reg
	local b`i' = b[1,`i'] // loop over columns
	
	// get weights w for ATE
	qui count if phatx_bins == `i'
	local w_`i' = `r(N)'/`=_N'
	local w_sum = `w_sum' + `w_`i''
	
	// get weights w_t for ATT
	qui count if phatx_bins == `i' & tobacco == 1
	local w_t_`i' = `r(N)'/`=_N'
	local w_t_sum = `w_t_sum' + `w_t_`i''
	
	// get ATE and ATT numerators
	local ate_numerator = `ate_numerator' + `b`i'' * `w_`i''
	local att_numerator = `att_numerator' + `b`i'' * `w_t_`i''
	
}

// get ATE and ATT
local ate_block = round(`baseeffect' + `ate_numerator'/`w_sum', 0.01)
local att_block = round(`baseeffect' + `att_numerator'/`w_t_sum', 0.01)

// display
dis "ATE: = `ate_block'"
dis "ATT: = `att_block'" // makes sense that ATT > ATE


* ----------------------------------------------------------------------------- * 
* Question 4e: 
// teffects ipw (dbrwt) (tobacco, logit), ate // testing Stata command without luck
// teffects ipw (dbrwt) (tobacco, logit), atet

** ATE -------------------------------------------------------------------------
// regress Y on D with IPW weights and no controls
gen ipw1 = tobacco/phatx + (1-tobacco)/(1-phatx) // generate ATE weights
eststo: regress dbrwt tobacco [pw=ipw1]

	// for ATT below
	mat b = e(b)[1,1]
	local ate = b[1,1]
	dis `ate'
	qui sum tobacco // get Pr(D=1)
	dis `ate'/`r(mean)' // nope! DNE ATT below


// alternative approach: ATE_hat
egen numerator1 = total(tobacco*dbrwt/phatx)
egen denom1 	= total(tobacco/phatx)
egen numerator2 = total((1-tobacco)*dbrwt/(1-phatx))
egen denom2 	= total((1-tobacco)/(1-phatx))
gen ate_hat 	= (numerator1/denom1) - (numerator2/denom2)
sum ate_hat
local ate_ipw = round(`r(mean)', 0.01)
// replicates well


** ATT -------------------------------------------------------------------------
// regress Y on D with new IPW weights and no controls
gen ipw2 = (tobacco-phatx)/(1-phatx) // generate ATT weights
// problem: ipw2 includes negative weights
regress dbrwt tobacco [pw=ipw2] // can't get this to run. Need right weights

// alternative approach: ATT_hat
egen element1_temp = total(tobacco)
gen element1 = _N/element1_temp
egen element2_temp = total(((tobacco-phatx)* dbrwt)/(1-phatx)) 
gen element2 = element2_temp/_N
gen att_hat = element1 * element2
sum att_hat //
local att_ipw = round(`r(mean)', 0.01)




	local table_loc table_4de
	local table_title "ATE and ATT by estimation method"
	local note_local "This table shows the vaATE and ATT estimated using the blocking and IPW methods."

	// print table of selected vars
	cap file close fh 
	file open fh using "$do_loc/tables/table_4de.tex", replace write

		file write fh "\begin{center}" _n
		file write fh "\begin{tabular}{lcc}" _n
		file write fh "\hline\hline" _n
		file write fh "Estimation method & ATE & ATT \\ [0.5ex]" _n
		file write fh "\hline" _n
		file write fh "Blocking & `ate_block' & `att_block' \\ " _n
		file write fh "IPW 		& `ate_ipw'   & `att_ipw' \\ " _n
		file write fh "\hline\hline" _n		
		file write fh "\end{tabular}" _n	
		file write fh "\end{center}" _n	
	
	file close fh 

stop


* ============================================================================= *
* Question 5: DOUBLY-ROBUST METHODS  
* ============================================================================= *
* ----------------------------------------------------------------------------- * 
* Question 5a: 
foreach var of varlist $covar_list { // generate interactions
	egen m_`var' = mean(`var') 			// bar
	gen dm_`var' = `var' - m_`var' 		// X-X_bar
	gen tbco_`var' = tobacco*dm_`var' 	// D(X-X_bar)
}
regress dbrwt tobacco $covar_list tbco_* [pw=ipw1], noconstant



* ----------------------------------------------------------------------------- * 
* Question 5b: 

// interactions
local covars_to_interact $covar_list
loc n1 : list sizeof covars_to_interact // for interaction loop
dis `n1'

local i_ct = 1
foreach i in `covars_to_interact' {
	
	dis "Covar `i'"
	local j_start = `i_ct' + 1
	
	forval j = `j_start'/`n1' {
		
		local word_j : word `j' of `covars_to_interact'
		dis "    `word_j'"
		
		// generate combo
		qui gen `i'_`word_j' = `i' * `word_j'
		label var `i'_`word_j' "`i' * `word_j'"
		
		// collect interactions as list
		local covars_interact `covars_interact' `i'_`word_j'
// 		dis "Interaction = `i'_`word_j'"
// 		pause
	}
	local i_ct = `i_ct' + 1
}
dis "`covars_interact'"

global covars_lasso $covar_list `covars_interact'


** Lasso steps
set seed $seed_q5b // defined in 00_master.do

// regress Y on X and collect selected covariates
lasso linear dbrwt $covars_lasso, rseed("$seed_q5b") // linear model
eststo lasso_logit_y
global selectedvars_y `e(allvars_sel)'
dis "Selected vars: `e(allvars_sel)'"

// regress D on X and collect selected covariates
lasso logit tobacco $covars_lasso, rseed("$seed_q5b") // logit model
eststo lasso_logit_d
global selectedvars_d `e(allvars_sel)'
dis "Selected vars: `e(allvars_sel)'"


/* Notes on lasso options:
- lasso standardizes variables by default. See manual p. 152. (seed in 00_master_ps2.do)
*/

// Regress Y on D and union of selected covariates from two lasso regs above
global lasso_covars_union: list global(selectedvars_y) | global(selectedvars_d)
reg dbrwt tobacco $lasso_covars_union

// ATE 






