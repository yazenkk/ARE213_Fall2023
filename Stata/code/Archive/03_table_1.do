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
	addnote("Notes: Insert footnote") 				///
	nonote 								/// 
	replace
	
// adjust footnote width
import delimited "$do_loc/tables/table1_balance.tex", clear
fix_import
count if strpos(text, "\multicolumn{8}") > 0 // confirm there's that line to fix
assert `r(N)' == 1
replace text = subinstr(text, "\multicolumn{8}", "\multicolumn{9}", .) if ///
	strpos(text, "Notes:") > 0
outfile using "$do_loc/tables/table1_balance.tex", ///
	noquote wide replace





