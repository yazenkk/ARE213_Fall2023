/*

Purpose: Q3. Covariate adjustment 1: regression

Outline:
(a) Use a basic, uninteracted linear regression model to estimate the impact of smoking
and report your estimates. Under what circumstances does it identify the
average treatment effect (ATE)? (Assemble all of your estimates and standard
errors from this and later questions into a table or several tables that would make
it easy to compare the methods.)

(b) Is the estimate in the previous question sensitive to dropping controls one at a
time? What do you learn from this exercise?

(c) For this part only, extend the OLS specification from question 3(a) to control for
the covariates using a more flexible functional form. Describe the specification
you picked. What are the potential benefits and drawbacks of this approach?

(d) For this part only, add to the specification of question 3(a) some “bad controls.”
Check if your estimate changes and discuss the direction of the change.

(e) Produce the Oaxaca-Blinder estimator for the ATE and ATT. Describe the exact
steps you have used. Does your answer differ substantially from the one in 3(a)?
Discuss.

*/
use "$dta_loc/data/pset1_clean_trim.dta", clear


local covar_list 	alcohol ///
					mrace3_2 ///
					mrace3_3 ///
					moth_hisp /// hisp_moth
					adequacy ///
					cardiac ///
					pre4000 ///
					phyper ///
					chyper ///
					diabetes ///
					anemia ///
					lung ///
					wgain ///
					dmeduc ///
					dgestat ///
					dmage ///
					dmar ///
					male /// csex
					totord9 ///
					isllb10 ///
					dlivord ///
					dplural
//



reg dbrwt tobacco `covar_list'



