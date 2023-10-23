/*
Title: 		02_analysis_q1.do
Outline:	Question 1, PSet 2 
*/

			
* ============================================================================= *
* Question 1a
/*
Q1a
	1. Is the panel balanced (a.k.a. complete)? 
	2. Visualize the timing of primary belt laws.
	3. Are there any reversals of primary belt laws? 
	4. Are there never-treated states? 
	5. How does the timing of primary and secondary belt laws relate to each other?	
*/
* ============================================================================= *

use "$dta_loc/pset2", clear
isid state year

sort state year primary secondary

count if primary == 1 & secondary == 1 // no state applies both laws at once


// Q1a.1 ----------------------
preserve
	byso state  : egen state_ct = count(year)
	tab state_ct 

	byso year  : egen year_ct = count(state)
	tab year_ct 

	gen bal_test = 0 // generate a variable without missing values
	keep state year bal_test
	reshape wide bal_test, i(state) j(year)
	// If the i-j combination contains a missing value for primary, 
	// then reshape returns a missing value

	foreach var of varlist bal_test* {
		assert `var' != .
	}
restore
// ANS: balanced indeed


// Q1a.2 ----------------------
 twoway (line primary year if state == 1) ///
 	    (line primary year if state == 4)

panelview primary, i(state) t(year) type(treat) xtitle("Year") ytitle("State") title("Timing of primary belt laws", size(medium)) 
graph export "$oput_loc/q1a_timing.png", replace



panelview primary, i(state) t(year) type(treat) xtitle("Year") ytitle("State") title("Timing of primary belt laws", size(medium)) bytiming 
graph export "$oput_loc/q1a_timing_bytiming.png" , replace 

// Q1a.3 ----------------------
preserve 
// 	br state year primary
// 	keep state year primary
	byso state (year) : gen prim_delta = primary[_n]-primary[_n-1]
	assert prim_delta >= 0 | prim_delta == . 
restore
// ANS: Change in primary law within states is never negative


// Q1a.4 ----------------------
byso state : egen prim_ever = max(primary)
preserve 
	collapse (max) prim_ever, by(state)
	count if prim_ever == 0 
restore
// ANS: 30 states are never-treated


// Q1a.5 ----------------------
preserve 
keep state year primary secondary
count if primary == 1 & secondary == 1 // no state applies both laws at once
foreach law in primary secondary {
    gen year_`law' = year if `law' == 1
}
byso state secondary (year) : egen yr_sec_end = max(year_secondary)
byso state primary (year) : egen yr_prim_start = min(year_primary)
sort state year primary secondary

	collapse (mean) yr_sec_end yr_prim_start , by(state)
	assert yr_sec_end < yr_prim_start if !missing(yr_prim_start) & !missing(yr_sec_end)
	assert yr_sec_end + 1 == yr_prim_start if !missing(yr_prim_start) & !missing(yr_sec_end)
restore
// ANS: Primary and secondary laws never overlapped. 
// Primary laws were adopted (if at all) one year after secondary laws were phased out.
// correlate adopting prim and sec within state



* ============================================================================= *
* Question 1b
/*
Define the outcome as log traffc fatalities per capita. Do you think taking the
log and normalizing by population are good ideas for your later analysis?
*/
* ============================================================================= *
* gen outcome variable = log (fatalities/pop*1000) 
	gen 	log_fatal_per_cap=log(fatalities/(population*1000))
	lab var log_fatal_per_cap "Log of fatalities per capita"
	
	* histogram
	histogram log_fatal_per_cap, percent ytitle(Percent) xtitle(Log of fatalities per capita) title(Log of fatalities per capita) scheme(white_brbg) name(histogram_1b_1, replace) 
	graph export "$oput_loc/histogram_1b_1.png" , replace 


* fatal_per_cap_1000
	gen 	fatal_per_cap_1000=(fatalities/population)
	lab var fatal_per_cap_1000 "Fatalities per capita (pop in 1000s)"
	
	* histogram
	histogram fatal_per_cap_1000, percent ytitle(Percent) xtitle("Fatalities per capita (pop in 1000s)") title(Fatalities per population) scheme(white_brbg) name(histogram_1b_2, replace )
	graph export "$oput_loc/histogram_1b_2.png" , replace 


* fatalties  (raw) 
	* histogram
	histogram fatalities, percent ytitle(Percent) xtitle("Fatalities") title(Fatalities) scheme(white_brbg) name(histogram_1b_3, replace)
	graph export "$oput_loc/histogram_1b_3.png" , replace 
		
* log fatalities 
	gen 	log_fatalities=log(fatalities)
	lab var	log_fatalities "Log of fatalities"
	
	histogram log_fatalities, percent ytitle(Percent) xtitle("Log fatalities") title(Log fatalities) scheme(white_brbg) name(histogram_1b_4, replace)
	graph export "$oput_loc/histogram_1b_4.png" , replace 
		
graph combine histogram_1b_1 histogram_1b_2 histogram_1b_3 histogram_1b_4
	graph export "$oput_loc/histogram_1b_combined.png" , replace 


* ============================================================================= *
* Question 1c
/*
Plot raw outcome data in a way that may be helpful for later DiD analysis
*/ 
 
* ============================================================================= *
* plot x (year) and y (log fatalities per capita) 

twoway (scatter log_fatal_per_cap year if primary==1, mcolor(blue%30) msize(3-pt)) (scatter log_fatal_per_cap year if primary==0 & secondary==0, mcolor(green%30) msize(3-pt)) (scatter log_fatal_per_cap year if secondary==1, mcolor(cranberry%30) msize(3-pt)), xtitle(Year) title(Log of fatalities per capita by year (raw data)) legend(position(6)) scheme(swift_red) legend(label(1 "Neither primary nor secondary") label(2 "Primary") label(3 "Secondary"))
graph export "$oput_loc/1c_scatterraw.png", replace 











isid state year
sort state year primary secondary
gen ln_fat_pc = ln(fatalities/population)
gen year_primary = year if primary == 1
byso state primary (year) : egen cohort = min(year_primary)
byso state (cohort): replace cohort = cohort[1]
replace cohort = 999 if cohort == .
sort state year // clean up
drop year_primary
label define cohort 999 "No shock" ///
			 1984 "1984" ///
			 1986 "1986" ///
			 1987 "1987" ///
			 1991 "1991" ///
			 1993 "1993" ///
			 1996 "1996" ///
			 1998 "1998" ///
			 2000 "2000" ///
			 2002 "2002" ///
			 2003 "2003"
label values cohort cohort
preserve
	collapse (mean) fatalities ln_fat_pc fat_pc, by(cohort year)
	// plot raw data by cohort with vertical E_i
	twoway (line ln_fat_pc year if cohort == 999, lcolor(black) ) ///
		   (line ln_fat_pc year if cohort == 1984, lcolor(ebblue) ) ///
		   (line ln_fat_pc year if cohort == 1987, lcolor(gs10) ) ///
		   (line ln_fat_pc year if cohort == 1993, lcolor(midgreen) ) ///
		   (line ln_fat_pc year if cohort == 2002, lcolor(dkorange) ), ///
			legend(label(1 "No shock") ///
				   label(2 "1984") /// 
				   label(3 "1987") /// 
				   label(4 "1993") /// 
				   label(5 "2002")) ///
			   xline(1984, lcolor(ebblue) lpatter(dash)) ///
			   xline(1987, lcolor(gs10) lpatter(dash)) ///
			   xline(1993, lcolor(midgreen) lpatter(dash)) ///
			   xline(2000, lcolor(dkorange) lpatter(dash))
restore

