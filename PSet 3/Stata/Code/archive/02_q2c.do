/*
Title: 		02_q2c.do
Purpose:	Question 2.c, PSet 3

Outline: (c)
 
2c.i Manually (i.e., without the ssaggregate package) use the BHJ equivalence 
result to compute ˆτ1 from a weighted IV specification at the level of planned 
lines.

2c.ii Describe and interpret the outcome, treatment, instrument, controls, and 
weights in this specification, taking into account the somewhat special 
structure of ΔLinesi relative to a generic shift-share variable. 

2c.iii Confirm that the estimate matches your answer to 1(d) perfectly. 

2c.iv You should find that there are a bit fewer than 149 observations — why is 
that? 

2c.v Finally, report exposure-robust standard errors for ˆτ1.

*/

/*
2c.i
Manually transform variables following equivalence result in BHJ (2020)
*/
cls
pause on

use "$dta_loc/q1a_sol.dta", clear // deltalines
merge 1:1 cityid using "$dta_loc/q1c_sol_v2.dta", nogen assert(3) keepusing(Q_*)
encode province_en, gen(prov)

// 1) residualize variable on controls
local varstotranform empgrowth deltalines
foreach var in `varstotranform' {
	reg `var' Q_* 
	predict `var'_res, res
}

isid cityid
keep cityid *_res
tempfile i_resvars
save 	`i_resvars'

// 2) Generate exposure-weighted averages of the residuals
// 2.1) Get denominator of weighted average: s_k = sum_i s_ik

use "$dta_loc/pset3_stations", clear // city-line matrix
gen s_ik = 1 // indicator for cities with lines
label var s_ik "line k passes through city i" 
sort lineid cityid
merge m:1 cityid using `i_resvars', nogen assert(2 3) // not all cities have lines

count if lineid == . & cityid !=. // 75 cities have no lines
drop if lineid == . & cityid !=.

byso lineid : egen s_k = total(s_ik)
// gen s_k_wt = s_k/`=_N'

sort lineid cityid
sort cityid lineid

foreach var in `varstotranform' {
	gen numerator_1 = `var'_res * s_ik 					// s_ik x_i
	byso lineid : egen numerator_2 = total(numerator_1) if numerator_1 != . // sum_i s_ik x_i
	byso lineid (numerator_2) : replace numerator_2 = numerator_2[1]
	gen `var'_res_bar = numerator_2/s_k 				// sum_i s_ik x_i / sum_i s_ik
	drop numerator_*
}

keep lineid empgrowth_res_bar deltalines_res_bar s_k
duplicates drop

/* Footnote 13 in BHJ: 
In the special case of reduced-form shift-share regressions, 
Proposition 1 shows that the equivalent shock-level procedure is still 
an IV regression, of y_bar_res_k on the transformed shift-share 
instrument z_bar_res_k, again instrumented by gn and weighted by s_n
*/

merge 1:1 lineid using "$dta_loc/pset3_lines.dta", assert(3) keepusing(open) nogen
merge 1:1 lineid using "$dta_loc/q1c_lines.dta", assert(3) keepusing(q_*) nogen
ivregress 2sls empgrowth_res_bar (deltalines_res_bar=open) q_* [aw=s_k], robust






