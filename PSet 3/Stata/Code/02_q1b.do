/*
Title: 		02_q1b.do
Purpose:	Question 1.b, PSet 3

Outline: 
Eqn (1): Y_i = τ_1 ΔLines_i + ε_i,

b.i Estimate (1) by OLS without controls
	- Add fixed effects of 30 Chinese provinces. 
	- Use heteroskedasticity-robust standard errors. 
	
b.ii Is the coefficient economically large? 

b.iii Explain why simple OLS with no controls is not likely to produce a 
causal estimate even if assumptions A1–A3 hold and specification (1)
is correct. 

b.iv Is the estimator with province fixed effects more likely to produce a
causal estimate?

*/


use "$dta_loc/q1a_sol.dta", clear

preserve
	keep province_en
	duplicates drop
	assert _N == 30 
	// 30 unique provinces as needed
	// visually examined to check spelling differences
restore

encode province_en, gen(prov)

/* ----------------------------------------------------------------------------
 b.i Estimate (1) by OLS without controls
 	- Add fixed effects of 30 Chinese provinces. 
 	- Use heteroskedasticity-robust standard errors. 
*/
reg empgrowth i.prov deltalines, robust

/* ----------------------------------------------------------------------------
b.ii Is the coefficient economically large? 
ANS: Adding a new line (0->1 or 4->5 lines) increases the employment growth 
 rate by 5%. This effect is economically large. 
*/

/* ----------------------------------------------------------------------------
 b.iii Explain why simple OLS with no controls is not likely to produce a 
 causal estimate even if assumptions A1–A3 hold and specification (1)
 is correct. 
 ANS: 
	OVB is likely to affect this OLS estimate. deltalines determines MA and
	we know, as stated in BH (2023), that "prefectures with high MA growth 
	(or a high deltalines), which serve as the effective treatment group, 
	tend to be clustered in the main economic areas in the southeast [China] 
	where HSR lines and large markets are concentrated." Thus equation 1 is 
	likely confounded by other policies that differentially affect the 
	economic centers of China.
*/

/* ---------------------------------------------------------------------------
b.iv Is the estimator with province fixed effects more likely to produce a
causal estimate?
ANS: 
	geographic controls such as provincial dummies are likely to lower the OVB,
	but these controls do not seem very informative
*/

// check importance of geographic predictors:
gen ma_growth = deltalines - deltalines13 // market access growth between 2013-16
reg ma_growth dist_beijing latitude longitude, robust
reg deltalines dist_beijing latitude longitude, robust

/*
	delta lines not as interesting as MA_{it} in Zheng and Kahn (2013).
	Can't say geographic predictors capture variation in MA growth

	As stated in BH (2023),
	"for a causal interpretation of ... regression [(1)], one would need to 
	assume that all unobserved determinants of employment growth (e.g. local 
	productivity shocks) are uncorrelated with these geographic features."
*/



