/*

Outline:
Q 1.d Produce a summary table 


...describing some of the key variables in the final analysis data set. 

(A useful "Table 1" is one that describes the overall averages of the key
variables, and then describes the subsets of people who do and do not receive the
treatment, when the treatment is binary.)

*/


use "$dta_loc/data/pset1_clean.dta", clear
ds tobacco, not

// generate balance table
qui ds tobacco, not // display all but binary treatment var
local covar_list 	mrace3_3 ///
					moth_hisp /// hisp_moth
					dmeduc ///
					dmage ///
					male /// csex
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

iebaltab `covar_list', ///
	grpvar(tobacco) ///
	savetex("$do_loc/tables/table1_balance.tex") ///
	rowvarlabels ///
	total ///
	stats(desc(sd) pair(t)) ///
	nostars ///
	replace




