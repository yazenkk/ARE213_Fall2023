
// squares
local covar_squares dgestat_sq dmage_sq // from Q3c

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

global covars_lasso $covar_list `covars_interact' `covar_squares'


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


