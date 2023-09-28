
pause on 
// Scratch Q4.
use "$dta_loc/data/pset1_clean.dta", clear

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
	
	
	
// 	4c. Assess balance
xtile phatx_bins = phatx, nq(10)

// Within bins of p(X) compare X among treated and controls
// run regs controlling for bins so that D is within bin
iebaltab `covar_list', ///
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
// 4d: blocking (chosen because matching is computationally fun but not as and convincing risks discarding some observations).

reg dbrwt tobacco#phatx_bins
mat A = r(table)
mat b = A["b", "1.tobacco#1.phatx_bins" .. "1.tobacco#10.phatx_bins"]

// initialize 
local ate_numerator =0 
local att_numerator =0 
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
local ate = round(`ate_numerator'/`w_sum', 0.001)
local att = round(`att_numerator'/`w_t_sum', 0.001)

// display
dis "ATE: = `ate'"
dis "ATT: = `att'" // makes sense that ATT > ATE


** -----------------------------------------------------------------------------
// 4e
See overleaf







