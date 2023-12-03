/*
Title: 		02_q1a.do
Purpose:	Question 1.a, PSet 4

*/



use "$dta_loc/pset4_data.dta", clear
foreach v of varlist *vote* election* {
	char `v'[_de_col_width_] 14
}


/* ---------------------------------------------------------------------------
1a Define running var, X*/
gen votes_tot = votes_for + votes_against
gen x = votes_for/votes_tot
assert win == 1 if x > 0.5
gen w = eligible_voters
gen margin = x-0.5


save "$dta_loc/pset4_clean.dta", replace