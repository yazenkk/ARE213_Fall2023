/*
Title: 		02_q2a.do
Purpose:	Question 2.a, PSet 3

Outline: 
(a) Compute standard errors clustered by province.
(b) Compute spatially-clustered (“Conley”) standard errors. 
Describe any choices you have made.

*/

// ssc install spmap // taking forever to install
// ssc install shp2dta
// ssc install mif2dta


use "$dta_loc/q1a_sol.dta", clear
merge 1:1 cityid using "$dta_loc/q1c_sol.dta", nogen assert(3)
encode province_en, gen(prov)

// Recall 1d
reg empgrowth nlinks_i S_i deltalines, robust

/*
2.a Province-clustered standard errors
*/
// simply include cluster option 
reg empgrowth nlinks_i S_i deltalines, cluster(prov)

/*
2.b “Conley” standard errors
*/
// construct regional category where cities 
