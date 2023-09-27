/*

Outline:
Q 1.d Produce a summary table 


...describing some of the key variables in the final analysis data set. 

(A useful "Table 1" is one that describes the overall averages of the key
variables, and then describes the subsets of people who do and do not receive the
treatment, when the treatment is binary.)

*/


use "$dta_loc/data/pset1_clean.dta", clear


// generate balance table
qui ds tobacco, not // display all but binary treatment var
iebaltab `r(varlist)', ///
	grpvar(tobacco) ///
	savexlsx("$dta_loc/q1_treatmentbalance.xlsx") ///
	rowvarlabels ///
	total ///
	replace




