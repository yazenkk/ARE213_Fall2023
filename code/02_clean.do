* ============================================================================= *
* 							ARE 213: Problem set 1
* 			Group members: Rajdev Brar, Yazen Kashlan, Cassandra Turk 
* ============================================================================= *
/*

	Title: 		are213_pset1.do

 	Outline:

 	Input: 		pset1.dta

	Output:		pset1_cleaned.dta

	Modified:	Rajdev Brar on 23 Sep 2023

*/
* ============================================================================= *


use "$dta_loc/data/pset1", clear


* ============================================================================= *
* Question 1 (a-b)
* ============================================================================= 

	// label values
	label define yesno 				 0 "No" 		1 "Yes"
	label define tobacco_lab 		 0 "Non-smoker" 1 "Smoker"
	label values tobacco tobacco_lab


** Q1.a Fix missing values -----------------------------------------------------
* We are told and can confirm that all variables except for cardiac - wgain are without unassigned missing values.

	* check missing values for vars: cardiac lung diabetes herpes chyper phyper pre4000 preterm tobacco cigar6 alcohol drink5 wgain
	tab1 cardiac lung diabetes herpes chyper phyper pre4000 preterm tobacco cigar6 alcohol drink5 wgain, m 
		

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


	* check tabulations to see missing values have been recoded 
	tab1 cardiac lung diabetes herpes chyper phyper pre4000 preterm tobacco cigar6 alcohol drink5 wgain, m

	
** Q1.b Recode indicators ------------------------------------------------------
// From code book: indicators with 1 = yes, 2 = no 

	// recode indicators 
	ds dmar rectype pldel3 csex anemia - tobacco alcohol
	recode `r(varlist)' (2=0)

	// relabel vague indicators
	label var dmar 		"Mother: married (yes=1)"
	label var rectype 	"Resident in state and county of occurance (yes=1)"
	label var pldel3 	"Born in hospital (yes=1)"
	label var csex 		"Male (yes=1)"


	// Recode mrace3 as a set of indicator variables
	assert !missing(mrace3) // no missing values
	tab mrace3, gen(mrace3_)
	drop mrace3
	label var mrace3_1 "Mother race: White (yes=1)"
	label var mrace3_2 "Mother race: Other (yes=1)"
	label var mrace3_3 "Mother race: Black (yes=1)"


	// Coarsen ormoth and orfath into indicator variables
	tab ormoth 
	gen 	hisp_moth = ormoth 
	replace hisp_moth = 1 if ormoth > 0 & !missing(ormoth)
	lab var hisp_moth "Mother race: Hispanic (yes=1)"

	tab orfath
	gen 	hisp_fath = orfath 
	replace hisp_fath = 1 if orfath > 0 & !missing(orfath)
	lab var hisp_fath "Father race: Hispanic (yes=1)"

	drop ormoth orfath

	// For simplicity, drop stresfip, birmon, and weekday.
	tab stresfip 
	tab birmon 
	tab weekday
	
	drop stresfip birmon weekday


* recode potential controls 
	gen 	dmeduc_0 = (dmeduc==0)
	lab var dmeduc_0 "Education: No formal education (yes=1)"
	gen 	dmeduc_1 = (dmeduc>=1 & dmeduc<=8) 
	lab var dmeduc_1 "Highest education: Elementary school (yes=1)"
	gen 	dmeduc_2 = (dmeduc>=9 & dmeduc<=12) 
	lab var dmeduc_2 "Highest education: High school (yes=1)"
	gen 	dmeduc_3 = (dmeduc>=13 & dmeduc<=17) 
	lab var dmeduc_3 "Highest education: College or more (yes=1)" 
	foreach var of varlist dmeduc_* {
		replace `var'=. if mi(dmeduc)
	}
	
	tab adequacy, gen(adequacy_)
	lab var adequacy_1 "Adequacy of care: Adequate (yes=1)" 
	lab var adequacy_2 "Adequacy of care: Intermediate (yes=1)" 
	lab var adequacy_3 "Adequacy of care: Inadequate (yes=1)" 
	
	tab cntocpop, gen(cntocpop_)
	lab var cntocpop_1 "Population of county of origin: 1000k or more (yes=1)"
	lab var cntocpop_2 "Population of county of origin: 500k to 1000k (yes=1)"
	lab var cntocpop_3 "Population of county of origin: 250k to 500k (yes=1)"
	lab var cntocpop_4 "Population of county of origin: 100k to 250k (yes=1)"
	
	tab isllb10, gen(isllb10_)
	lab var isllb10_1 "Interval since last birth: No previous live birth (yes=1)"
	lab var isllb10_2 "Interval since last birth: 0 months (yes=1)"
	lab var isllb10_3 "Interval since last birth: 1-11 months (yes=1)"
	lab var isllb10_4 "Interval since last birth: 12-17 months (yes=1)" 
	lab var isllb10_5 "Interval since last birth: 18-23 months (yes=1)"
	lab var isllb10_6 "Interval since last birth: 24-35 months (yes=1)"
	lab var isllb10_7 "Interval since last birth: 36-47 months (yes=1)"
	lab var isllb10_8 "Interval since last birth: 48-59 months (yes=1)"
	lab var isllb10_9 "Interval since last birth: 60-71 months (yes=1)"
	lab var isllb10_10 "Interval since last birth: 72 months or over (yes=1)" 
	
	tab totord9, gen(totord9_)
	lab var totord9_1 "Total birth order: First child (yes=1)" 
	lab var totord9_2 "Total birth order: Second child (yes=1)" 
	lab var totord9_3 "Total birth order: Third child (yes=1)" 
	lab var totord9_4 "Total birth order: Fourth child (yes=1)" 
	lab var totord9_5 "Total birth order: Fifth child (yes=1)" 
	lab var totord9_6 "Total birth order: Sixth child (yes=1)" 
	lab var totord9_7 "Total birth order: Seventh child (yes=1)" 
	lab var totord9_8 "Total birth order: Eight child or more (yes=1)" 
	
	gen 	dplural_1 = (dplural==1 )
	replace dplural_1 = . if mi(dplural_1) 
	lab var dplural_1 "Single child birth (yes=1)" 

	
	
* Label variables 
	lab var dbrwt 	 "Birthweight (grams)" 
	lab var tobacco  "Tobacco use during pregnancy (yes=1)"
	lab var dmage 	 "Age of mother (years)"
	lab var alcohol  "Alcohol use during pregnancy (yes=1)"
	lab var phyper 	 "Pregnancy-related hypertension (yes=1)"
	lab var diabetes "Mother has diabetes (yes=1)"
	lab var anemia 	 "Mother has anemia (yes=1)"
	lab var dgestat  "Gestation (weeks)"
	lab var dlivord  "Number of live births, now dead"
	lab var pre4000  "Previous infant 4000+ grams (yes=1)"


	qui ds
	local all_vars `r(varlist)'
	egen miss_ct = rowmiss(`all_vars')
	gen  miss_any = (miss_ct > 0)
	label define miss_any_lab 0 "No missings variables" 1 "Any missing variables"
	label values miss_any miss_any_lab

	
save "$dta_loc/data/pset1_clean_miss.dta", replace

	// drop missings to achieve final obs count of 114,610.
	drop if miss_any == 1
	drop miss*
	assert _N == 114610 // as required in prompt


save "$dta_loc/data/pset1_clean.dta", replace



