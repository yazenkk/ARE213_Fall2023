
pause on 
set graphics off


// Scratch Q4.
use "$dta_loc/data/pset1_clean.dta", clear

// rajdev
global covar_list alcohol mrace3_2 mrace3_3 hisp_moth ///
				cardiac pre4000 phyper chyper diabetes anemia lung  ///
				dmeduc_1 dmeduc_2 dmeduc_3 dgestat /// 
				csex dmar dlivord dplural /// 
				adequacy_2 adequacy_3 cntocpop_2 cntocpop_3 cntocpop_4  ///
				isllb10_2 isllb10_3 isllb10_4 isllb10_5 isllb10_6 isllb10_7 isllb10_8 isllb10_9 isllb10_10 ///
				totord9_2 totord9_3 totord9_4 totord9_5 totord9_6 totord9_7 totord9_8 dplural_1
				
// cass
// global covar_list alcohol mrace3_2 mrace3_3 hisp_moth adequacy cardiac pre4000 ///
// 				phyper chyper diabetes anemia lung wgain dmeduc dgestat dmage dmar ///
// 				csex totord9 isllb10 dlivord dplural


logit tobacco $covar_list
predict phatx, pr

tab tobacco, sum(phatx )

sort $covar_list

twoway (histogram phatx if tobacco==0, color(green%25)) ///
	   (histogram phatx if tobacco==1, color(red%25)), ///   
       legend(label(1 "Observed non-smokers") label(2 "Observed smokers")) ///
	   xtitle("Pr(tobacco{sub:i}=1|X{sub:i})") ///
	   saving("phatx_overlap", replace)

graph export "$do_loc/graphs/phatx_overlap.png", ///
	width(1200) height(900) ///
	replace
	
	
	
** -----------------------------------------------------------------------------
** -----------------------------------------------------------------------------
// 	4c. 
// Assess balance
xtile phatx_bins = phatx, nq(10)

// Within bins of p(X) compare X among treated and controls
// run regs controlling for bins so that D is within bin
iebaltab $covar_list, ///
	grpvar(tobacco) ///
	fixedeffect(phatx_bins) ///
	rowvarlabels ///
	stats(desc(sd) pair(t)) ///
	nostars ///
	savetex("$do_loc/tables/table4_balance_pbins.tex") ///
	addnote("Notes: Insert footnote") 				///
	nonote 								/// 
	texnotewidth(1) 		///	
	replace

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

** -----------------------------------------------------------------------------
** -----------------------------------------------------------------------------
// 4d: blocking (chosen because matching is computationally fun but not as 
// and convincing risks discarding some observations).

reg dbrwt tobacco##phatx_bins
mat A = r(table)
mat list A
mat c = A["b","1.tobacco"]
mat list c
local baseeffect = c[1,1]

mat b = A["b", "1.tobacco#1.phatx_bins" .. "1.tobacco#10.phatx_bins"]
mat list b

// initialize 
local ate_numerator = 0 
local att_numerator = 0 
// mat list b
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
local ate = `baseeffect' + round(`ate_numerator'/`w_sum', 0.001)
local att = `baseeffect' + round(`att_numerator'/`w_t_sum', 0.001)
 
// display
dis "ATE: = `ate'"
dis "ATT: = `att'" // makes sense that ATT > ATE
 

** -----------------------------------------------------------------------------
** -----------------------------------------------------------------------------
// 4e
// teffects ipw (dbrwt) (tobacco, logit), ate // testing Stata command without luck
// teffects ipw (dbrwt) (tobacco, logit), atet

** ATE -------------------------------------------------------------------------
// regress Y on D with IPW weights and no controls
gen ipw1 = tobacco/phatx + (1-tobacco)/(1-phatx) // generate ATE weights
regress dbrwt tobacco [pw=ipw1]

	// for ATT below
	mat b = e(b)[1,1]
	local ate = b[1,1]
	dis `ate'
	qui sum tobacco // get Pr(D=1)
	dis `ate'/`r(mean)' // nope! DNE ATT below


// alternative approach: ATE_hat
egen numerator1 = total(tobacco*dbrwt/phatx)
egen denom1 = total(tobacco/phatx)
egen numerator2 = total((1-tobacco)*dbrwt/(1-phatx))
egen denom2 = total((1-tobacco)/(1-phatx))
gen ate_hat = (numerator1/denom1) - (numerator2/denom2)
sum ate_hat
// seems to replicate well?


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
sum att_hat // -303.50


** Q5a -------------------------------------------------------------------------
** ATE -------------------------------------------------------------------------

foreach var of varlist $covar_list { // generate interactions
	egen m_`var' = mean(`var') 			// bar
	gen dm_`var' = `var' - m_`var' 		// X-X_bar
	gen tbco_`var' = tobacco*dm_`var' 	// D(X-X_bar)
}
regress dbrwt tobacco $covar_list tbco_* [pw=ipw1], noconstant









