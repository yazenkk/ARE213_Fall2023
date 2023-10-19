/*
Title: 		02_analysis_q1.do
Outline:	Question 1, PSet 2 

*/

			

* ============================================================================= *
* Question 1
* ============================================================================= *

use "$dta_loc/pset2", clear
sort state year primary secondary

count if primary == 1 & secondary == 1 // no states have both laws at once
