/*
Title: 		02_analysis_q2.do
Outline:	Question 1, PSet 2 

Q2 Testing assumptions for DinD design

*/

pause on 

use "$dta_loc/pset2_q1", clear
isid state year

sort state year primary secondary

** Q2a -----------------
/* List the assumptions. Then perform tests you find feasible and useful. 
For each of them, describe the alternative and the testing procedure.

We assume 
1) No spillovers
2) No anticipation effects: Y_i1 does not depend on D_i2
3) No lagged effects: Y_i2 does not depend on D_i1 (not sure about this. Carried from C2 slides)
4) Parallel trends: 
	- This can be applied to (monotonically) transformed data
	- This can only be tested in the pre-period
5) Target estimand tau is linear in tau_it

// I test assumption 4 which is a first order concern for ID
Following Marcus and Santanna (2020), page 250:
"...one can directly test if E[Y_3 – Y_2|C=1]= E[Y_3 – Y_2|G=1] using a standard t-test. 
Rejecting the null hypothesis would provide direct evidence against the identifying assumptions."
*/

drop college beer unemploy totalvmt precip snow32 rural_speed urban_speed
// Get cohort averages \bar{y}_gt
// average across states with cohort-year (g,t)
// Get delta Y and test means
byso state (year) : gen del_lny = ln_fat_pc[_n] - ln_fat_pc[_n-1]

labellist cohort
foreach g in `r(values)' {
	dis as result "----------------------"
	dis as result "COHORT g=`g'"
    preserve
		keep if inlist(cohort, 999, `g') 
		forval t = 1984/`g' {
		    dis as text ""
		    dis as result "Run ttest comparing dely_C,`t' with dely_g`g',`t'"
			qui sum del_lny if cohort == 999 & year == `t' // get control mean
			local delyc_rd = round(`r(mean)', 0.001)
		    qui count if cohort == `g' & year == `t'
			local n_g `r(N)'
			if `n_g' == 1 {
			    // test cohort C (control group) against cohort g's scalar
			    qui sum del_lny if cohort == `g' & year == `t'
				local delyg = `r(mean)'
				local delyg_rd = round(`r(mean)', 0.001)
			    qui ttest del_lny == `r(mean)' if year == `t' & cohort == 999
			}
			else if `r(N)' > 1 qui ttest del_lny if year == `t', by (cohort)
			// collect test stats
			local se_rd = round(`r(se)', 0.001)
			local t_rd = round(`r(t)', 0.001)
			local p_rd = round(`r(p)', 0.001)
			
			// display results
			dis as text "ttest E[del_ly|C=1]-E[del_ly|g=`g'] with g size = `n_g'"
			dis as text "ttest `delyc_rd'-`delyg_rd'"
			if `p_rd' < 0.05 dis as error "SE = `se_rd', t-stat = `t_rd', p-value= `p_rd'"
			else dis as text "SE = `se_rd', t-stat = `t_rd', p-value= `p_rd'"
		}
	restore
}





** Q2b -----------------
/*
Do secondary belt laws pose a potential problem for your DiD design? If so, test
whether that problem is likely to be significant. If not, explain why not.

ANS: States implement secondary belt laws before switching to primary. Thus
secondary laws are indeed a threat to any effect caused by the primary laws in 
that primary laws have anticipatory effects wrought by the preceeding secondary 
laws or perhaps even some national awareness (spilovers). 

Not sure how to test this. Taker-uppers of 2ndary laws are not the same as
primary. That is, within a primary cohort, there exist different secondary 
cohorts. 

*/



// Secondary cohorts for sole states in primary cohort: 
// list cohort_sec if inlist(cohort, 1987, 1993, 2002) & year == 1981
// 1986 -> 1987
// 1986 -> 1993
// 1987 -> 2002

// replot q1 graph with secondary cohort verticals
preserve
	collapse (mean) fatalities ln_fat_pc fat_pc, by(cohort year)

	// plot raw data by cohort with vertical E_i
	twoway (line ln_fat_pc year if cohort == 999, lcolor(black) ) ///
		   (line ln_fat_pc year if cohort == 1987, lcolor(gs10) ) ///		   
		   (line ln_fat_pc year if cohort == 1993, lcolor(red) ) ///
		   (line ln_fat_pc year if cohort == 2002, lcolor(blue) ), ///
			legend(label(1 "No shock") ///
				   label(2 "1987") /// 
				   label(3 "1993") /// 
				   label(4 "2002")) ///
			   xline(1986.1, lcolor(gs10) lpatter(dot)) ///
			   xline(1986.2, lcolor(red) lpatter(dot)) ///
			   xline(1987.1, lcolor(blue) lpatter(dot)) ///
			   ///
			   xline(1987, lcolor(gs10) lpatter(dash)) ///
			   xline(1993, lcolor(red) lpatter(dash)) ///
			   xline(2002, lcolor(blue) lpatter(dash))
restore
// ANS: Let the data speak for themselves. The raw data show that, in some states, 
// the secondary laws were better markers of declines in fatality rates. The 1993
// cohort is interesting in that both sets of laws seem to be associated with 
// declines in fatalities.

// Meeting todos: Run Max's test and discuss theoretically
// States with out any laws will have seen states take up secondary before primary

** Q2c -----------------
/*
Repeat the tests from part 2(a) (and, if any, 2(b)) using fatalities per capita as
the outcome, without logs. Do the conclusions change? Discuss.

*/

byso state (year) : gen del_y = fat_pc[_n] - fat_pc[_n-1]

labellist cohort
foreach g in `r(values)' {
	dis as result "----------------------"
	dis as result "COHORT g=`g'"
    preserve
		keep if inlist(cohort, 999, `g') 
		forval t = 1984/`g' {
		    dis as text ""
		    dis as result "Run ttest comparing dely_C,`t' with dely_g`g',`t'"
			qui sum del_y if cohort == 999 & year == `t' // get control mean
			local delyc_rd = round(`r(mean)', 0.001)
		    qui count if cohort == `g' & year == `t'
			local n_g `r(N)'
			if `n_g' == 1 {
			    // test cohort C (control group) against cohort g's scalar
			    qui sum del_y if cohort == `g' & year == `t'
				local delyg = `r(mean)'
				local delyg_rd = round(`r(mean)', 0.001)
			    qui ttest del_y == `r(mean)' if year == `t' & cohort == 999
			}
			else if `r(N)' > 1 qui ttest del_y if year == `t', by (cohort)
			// collect test stats
			local se_rd = round(`r(se)', 0.001)
			local t_rd = round(`r(t)', 0.001)
			local p_rd = round(`r(p)', 0.001)
			
			// display results
			dis as text "ttest E[del_ly|C=1]-E[del_ly|g=`g'] with g size = `n_g'"
			dis as text "ttest `delyc_rd'-`delyg_rd'"
			if `p_rd' < 0.05 dis as error "SE = `se_rd', t-stat = `t_rd', p-value= `p_rd'"
			else dis as text "SE = `se_rd', t-stat = `t_rd', p-value= `p_rd'"
		}
	restore
}
// The conclusion doesn't change much as the pre-trend test can be scaled monotonically
// without altering the qualitative comparison between means.


// repeat 2b
preserve
	collapse (mean) fatalities ln_fat_pc fat_pc, by(cohort year)

	// plot raw data by cohort with vertical E_i
	twoway (line fat_pc year if cohort == 999, lcolor(black) ) ///
		   (line fat_pc year if cohort == 1987, lcolor(gs10) ) ///		   
		   (line fat_pc year if cohort == 1993, lcolor(red) ) ///
		   (line fat_pc year if cohort == 2002, lcolor(blue) ), ///
			legend(label(1 "No shock") ///
				   label(2 "1987") /// 
				   label(3 "1993") /// 
				   label(4 "2002")) ///
			   xline(1986.1, lcolor(gs10) lpatter(dot)) ///
			   xline(1986.2, lcolor(red) lpatter(dot)) ///
			   xline(1987.1, lcolor(blue) lpatter(dot)) ///
			   ///
			   xline(1987, lcolor(gs10) lpatter(dash)) ///
			   xline(1993, lcolor(red) lpatter(dash)) ///
			   xline(2002, lcolor(blue) lpatter(dash))
restore

// 2c) The raw data show the same general trend.
/*
As per Roth and Santanna (2023), we can test against the null that the PTA is
invariant to (strictly monotonic) transformations. Compare change in pdfs of 
raw outcome (fatalities per capita) over time across treatment and control. If
the distributions are indistinguishable, then the PTA holds under tranformation.

*/

