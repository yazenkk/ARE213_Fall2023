/*
Title: 		02_analysis_q1.do
Outline:	Question 1, PSet 2 

Q1a
	1. Is the panel balanced (a.k.a. complete)? 
	2. Visualize the timing of primary belt laws.
	3. Are there any reversals of primary belt laws? 
	4. Are there never-treated states? 
	5. How does the timing of primary and secondary belt laws relate to each other?

Q1b Compare log fatilities per capita with fatality count
Q1c Plot outcome in an informative way. Interpret.

*/

			

* ============================================================================= *
* Question 1
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
// twoway (line primary year if state == 1) ///
// 	   (line primary year if state == 4)

// I can't run this on my computer for some reason :(
*panelview primary, i(state) t(year) type(treat)


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
preserve
	collapse (max) primary secondary , by(state)
	corr primary secondary 
	tab primary secondary 
	// not immediately useful
restore


// Q1b ----------------------
gen ln_fat = ln(fatalities)
gen fat_pc = fatalities/population
gen ln_fat_pc = ln(fatalities/population)
label var ln_fat_pc "Log fatalities per capita"
// hist ln_fat_pc
// ANS: taking the log of the fraction of fatalities per capita (the outcome) 
// is a good idea because it normalizes its distribution.

* histogram
histogram ln_fat_pc, percent ytitle(Percent) xtitle("Log of fatalities per capita") title(Log of fatalities per capita) scheme(white_tableau) name(histogram_1b_1, replace) 
graph export "$do_loc/Graphs/histogram_1b_1.png" , replace 

* histogram
histogram fat_pc, percent ytitle(Percent) xtitle("Fatalities per capita") title(Fatalities per capita) scheme(white_tableau) name(histogram_1b_2, replace )
graph export "$do_loc/Graphs/histogram_1b_2.png" , replace 


* fatalties  (raw) 
* histogram
histogram fatalities, percent ytitle(Percent) xtitle("Fatalities") title(Fatalities) scheme(white_tableau) name(histogram_1b_3, replace)
graph export "$do_loc/Graphs/histogram_1b_3.png" , replace 
	
histogram ln_fat, percent ytitle(Percent) xtitle("Log fatalities") title(Log fatalities) scheme(white_tableau) name(histogram_1b_4, replace)
graph export "$do_loc/Graphs/histogram_1b_4.png" , replace 
	
graph combine histogram_1b_1 histogram_1b_2 histogram_1b_3 histogram_1b_4
graph export "$do_loc/Graphs/histogram_1b_combined.png" , replace 



// Q1c ----------------------

/*
// First try
collapse (mean) fatalities ln_fat_pc fat_pc, by(prim_ever year)
// States that adopt the law have lower log fatalities/cap every year
twoway (scatter ln_fat_pc year if prim_ever == 0) ///
	   (scatter ln_fat_pc year if prim_ever == 1), ///
		legend(label(1 "Never treated") label(2 "Treated"))

// States that adopt the law have higher total fatalities every year
twoway (scatter fatalities year if prim_ever == 0) ///
	   (scatter fatalities year if prim_ever == 1), ///
		legend(label(1 "Never treated") label(2 "Treated"))

// States that adopt the law have lower fatalities/cap every year
twoway (scatter fat_pc year if prim_ever == 0) ///
	   (scatter fat_pc year if prim_ever == 1), ///
		legend(label(1 "Never treated") label(2 "Treated"))

// Can also do relative to event time
gen year_primary = year if primary == 1
byso state primary (year) : egen yr_prim_start = min(year_primary)
byso state (yr_prim_start): replace yr_prim_start = yr_prim_start[1]
gen yr_relative = year - yr_prim_start if yr_prim_start != .
sort state year
tab yr_relative
// hard to choose cutoff
*/


// Plot raw data as in his "favorite event plot" by Fadlon and Nielsen (2015)
// plot a few states that do and do not adopt with vertical lines for E_i
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

* control vs primary  
twoway (scatter ln_fat_pc year if primary==0 & secondary==0, ///
			mcolor(blue%70) msize(3-pt) msymbol(circle)) ///
	   (scatter ln_fat_pc year if primary==1 & secondary==0, ///
			mcolor(red%70) msize(3-pt) msymbol(diamond)), ///
		xtitle(Year) ///
		title("Log of fatalities per capita by year (raw data)", ///
			size(medlarge)) ///
		legend(size(small) position(6)) ///
		scheme(swift_red) ///
		legend(label(1 "No law") label(2 "Primary law") )
		
graph export "$do_loc/Graphs/q1c_scatterraw.png", replace 


* now do this relative to year of exposure to treatment
bys state (year): gen sum=sum(primary)
gen first_yr_primary=year if sum==1
bys state (year): egen firstyr_primary=max(first_yr_primary)
lab var firstyr_primary  "First year of having primary law"
drop sum first_yr_primary

gen diff_firstyr_primary = year-firstyr_primary
lab var diff_firstyr_primary "Years since introduction of primary law"

twoway (scatter ln_fat_pc diff_firstyr_primary if primary==0 & secondary==0, ///
			mcolor(blue%70) ///
			msize(3-pt) ///
			msymbol(circle)) ///
		(scatter ln_fat_pc diff_firstyr_primary if primary==1 & secondary==0, ///
			mcolor(red%70) ///
			msize(3-pt) ///
			msymbol(diamond)), ///
		xtitle(Year) ///
		title(Log of fatalities per capita relative to year of introduction of primary law, ///
			  size(medsmall)) ///
		scheme(swift_red) ///
		legend(size(small) position(6) label(1 "No law") label(2 "Primary law"))
		
graph export "$do_loc/Graphs/q1c_scatterraw_relativeyr.png", replace 


drop diff_firstyr_primary

// save new dta with additional vars
compress
save "$dta_loc/pset2_q1", replace





