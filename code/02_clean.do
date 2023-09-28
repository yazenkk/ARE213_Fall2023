/*
Cleaning script
Author: YK

Outline:
Q1.a Fix missing values
Q1.b Recode indicators 

*/



use "$dta_loc/data/pset1", clear


* ============================================================================= *
* Question 1 (a-b)
* ============================================================================= *


// label variables
label define yesno 0 "No" 1 "Yes"
label define tobacco_lab 0 "Non-smoker" 1 "Smoker"
label values tobacco tobacco_lab


** Q1.a Fix missing values -----------------------------------------------------
// we are told andn can confirm that all variables except for cardiac - wgain 
// are without unassigned missing values.

/*
// explore
foreach var of varlist cardiac - wgain {
	tab `var', m
}
codebook cardiac - wgain
*/


// From the original codebook: unknown or not stated
// 99: wgain
// 5: drink5
// 9: alcohol tobacco preterm pre4000 phyper chyper herpes diabetes lung cardiac
// 6: cigar6
recode wgain (99=.m)
recode drink5 (5=.m)
recode cigar6 (6=.m)
recode alcohol tobacco preterm pre4000 phyper chyper herpes diabetes lung cardiac (9=.m)

// From the codebook: other unknowns
// 8: herpes
recode herpes (8=.d)





** Q1.b Recode indicators ------------------------------------------------------
// From code book: indicators with 1 = yes, 2 = no include

// recode indicators 
ds dmar rectype pldel3 csex anemia - tobacco alcohol
recode `r(varlist)' (2=0)

// relabel vague indicators
label var dmar "Mother: married"
label var rectype "Resident in state and county of occurance"
label var pldel3 "Born in hospital"
label var csex "Male"


// Recode mrace3 as a set of indicator variables
assert !missing(mrace3) // no missing values
tab mrace3, gen(mrace3_)
drop mrace3
label var mrace3_1 "Mother race: white"
label var mrace3_2 "Mother race: other"
label var mrace3_3 "Mother race: black"


// Coarsen ormoth and orfath into indicator variables
tab ormoth 
gen hisp_moth = ormoth 
replace hisp_moth = 1 if ormoth > 0 & !missing(ormoth)
label var hisp_moth "Mother race: hispanic"

tab orfath
gen hisp_fath = orfath 
replace hisp_fath = 1 if orfath > 0 & !missing(orfath)
label var hisp_fath "Father race: hispanic"

drop ormoth orfath


// For simplicity, drop stresfip, birmon, and weekday.
tab stresfip 
tab birmon 
tab weekday
// These are discrete state and time variables best considered as categorical
drop stresfip birmon weekday


save "$dta_loc/data/pset1_clean_miss.dta", replace

// Drop any observation with missing values and verify it has 114,610 observations. 
qui ds
local all_vars `r(varlist)'
egen miss_ct = rowmiss(`all_vars')
gen  miss_any = (miss_ct > 0)
label define miss_any_lab 0 "No missings observations" 1 "Some missing observations"
label values miss_any miss_any_lab

// drop missings to achieve final obs count of 114,610.
drop if miss_any == 1
drop miss*
assert _N == 114610 // as required in prompt


save "$dta_loc/data/pset1_clean.dta", replace


