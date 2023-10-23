/*
Title: 		05_analysis_q4.do
Outline:	Question 4, PSet 2 
*/

			
* ============================================================================= *
* Question 4a
/*
Build synthetic control for California 
Report which states comprise this synthetic control and how well it matches predictors 
* Show estimates and perform statistical inference on them 
*/ 
* ============================================================================= *
* Estimating effects for California only
* never-treated groups= donors
use "$dta_loc/pset2", clear

(a) Build the synthetic control for California. Report which states comprise this
synthetic control and how well it matches the predictors you’ve chosen. Show the
estimates and perform statistical inference on them. At every step briefly describe
the procedure and discuss the choices you’ve made.


* ============================================================================= *
* Question 4b 
* ============================================================================= *
(b) Estimate the effects for California using synthetic DiD. Report and discuss the
weights the estimator places on untreated units and on various pre-treatment
periods.



* ============================================================================= *
* Question 4c
* ============================================================================= *

