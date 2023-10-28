/*
Title: 		02_analysis_q2.do
Outline:	Question 3a, PSet 2 

Q3 DinD estimation

3. Now proceed with the DiD estimation. 

(a) Report the de Chaisemartin and D’Haultfouille’s manual averaging estimates of
the dynamic ATTs for the horizons where a reasonable sample is available.
*/



use "$dta_loc/pset2_q1", clear
isid state year

sort state year primary secondary
drop college beer unemploy totalvmt precip snow32 rural_speed urban_speed


// I start with Sun and Abraham (2021) where control is never-treated 
// as opposed to not yet treated.

// Compute cohort-horizon specific CATT_{g,e+h} as Y_{g,e+h} - Y_{g,e-1}
// Consider 1997 first.
// get cohort level data
collapse (mean) fatalities ln_fat_pc fat_pc, by(cohort year)

preserve
	local n1996 = 1996-1981 + 1
	dis `n1996'
	// get y_bar for each cohort at horizon 2
	byso cohort (year) : gen del_y_1996_h2 = ln_fat_pc[`n1996'+2] - ln_fat_pc[`n1996'-1]

	keep del_y_1996_h2 cohort 
	duplicates drop
	keep if inlist(cohort, 999, 1996)
	gen CATT_1996_h2 = del_y_1996_h2[_n]-del_y_1996_h2[_n-1]
restore

// 1) loop over all cohorts and horizons
labellist cohort
foreach g in `r(values)' {
	if `g' != 999 { // omit control group
		dis as error "g=`g'"
		local n`g' = `g'-1981 + 1
		dis `n`g''
		
		// get y_bar for each cohort at horizon h
		local h_max = 2003-`g'
		dis `h_max'
		forval h = 0/`h_max' {
			preserve
				dis as error "h=`h'"
				byso cohort (year) : gen del_y_g`g'_h`h' = ///
					ln_fat_pc[`n`g''+`h'] - ln_fat_pc[`n`g''-1]
				keep del_y_g`g'_h`h' cohort 
				duplicates drop
				keep if inlist(cohort, 999, `g')
				gen CATT_`g'_h`h' = del_y_g`g'_h`h'[_n] - del_y_g`g'_h`h'[_n-1]
// 				pause
				keep cohort CATT_`g'_h`h' 
				keep if CATT_`g'_h`h' != .
				gen h = `h'
				rename CATT_`g'_h`h' CATT_hg
				
				// save to stack later
				tempfile est_CATT_`g'_h`h'
				save 	`est_CATT_`g'_h`h''
				
			restore
		}
	}
}

// 2) stack CATTs in new dta
use `est_CATT_1984_h0', clear // call first cohort
local counter 0
labellist cohort
foreach g in `r(values)' {
	if `g' != 999 { // omit control group
		local h_max = 2003-`g'
		dis `h_max'
		forval h = 0/`h_max' {
			dis "g, h = `g', `h'"
			if `counter' > 0 {
				append using `est_CATT_`g'_h`h''	
			}
			local counter = `counter' + 1
		}
	}
}
tempfile CATT_w_`g'
save 	`CATT_w_`g'', replace


// 3) Generate cohort-specific weights
use "$dta_loc/pset2_q1", clear
byso cohort: egen w_g = count(cohort)
replace w_g = w_g/23 // 23 is number of periods (works due to balance)
preserve // get total w
	keep cohort w_g 
	duplicates drop
	egen tot_w_g = total(w_g) 
	assert tot_w_g == 48 // states
	replace w_g = w_g/tot_w_g // get relative weights
	drop tot_w_g
	
	tempfile est_w_`g'
	save 	`est_w_`g''
restore


// 4) take weighted average of CATT_{g,h} where weights are cohort size.
use `CATT_w_`g'', clear
merge m:1 cohort using `est_w_`g''
assert cohort == 999 if _merge == 2 // no CATT for control group
drop _merge


// take sum product of CATT_{gh}*w_{g} for different horizons
byso h (cohort) : gen product_h = CATT_hg * w_g
byso h (cohort) : egen ATT_h_SnA = sum(product_h)

drop if cohort == 999 // drop control cohort with no ATT
keep h ATT_h_SnA
duplicates drop

tempfile tau_SnA
save 	`tau_SnA', replace
// How to get SE? Bootstrap. Ignore, not asked for.






// -----------------------------
// Now get dCDH equivalent where control cohort is larger and then shrinking 
// to the control I used above. There will be a control group for each cohort, g.


use "$dta_loc/pset2_q1", clear
drop college beer unemploy totalvmt precip snow32 rural_speed urban_speed
sort cohort state year
assert !missing(cohort)

// 0) Get cohort specific cohort list
labellist cohort
foreach g in `r(values)' {
	if `g' != 999 { // omit control group
		gen cohort_`g' = cohort
		replace cohort_`g' = 999 if cohort_`g' > `g'
		label values cohort_`g' cohort
	}
}
sort cohort state year

// 1) loop over all cohorts and horizons
labellist cohort // same list of cohorts (cohort_g) comes later
foreach g in `r(values)' {
	if `g' != 999 { // omit control group
		dis as error "g=`g'"
		local n`g' = `g'-1981 + 1
		dis `n`g''
		
		// get y_bar for each cohort at horizon h
		local h_max = 2003-`g'
		dis `h_max'
		forval h = 0/`h_max' {
			preserve
				dis as error "h=`h'"
				
				// get new cohort specific annual means across states
				collapse (mean) fatalities ln_fat_pc fat_pc, by(cohort_`g' year)
				
				byso cohort_`g' (year) : gen del_y_g`g'_h`h' = ///
					ln_fat_pc[`n`g''+`h'] - ln_fat_pc[`n`g''-1]
				keep del_y_g`g'_h`h' cohort_`g' 
				duplicates drop

				keep if inlist(cohort_`g', 999, `g') 
				// this step is also necessary for dCDH for 2nd cohort onward
				
				gen CATT_`g'_h`h' = del_y_g`g'_h`h'[_n] - del_y_g`g'_h`h'[_n-1]
				keep cohort_`g' CATT_`g'_h`h' 
				keep if CATT_`g'_h`h' != .
				gen h = `h'
				rename CATT_`g'_h`h' CATT_hg
				rename cohort_`g' cohort // for append later
				
				// save to stack later
				tempfile dCDH_CATT_`g'_h`h'
				save 	`dCDH_CATT_`g'_h`h'', replace
				
			restore
		}
	}
}

// 2) stack CATTs in new dta
use `dCDH_CATT_1984_h0', clear // call first cohort
local counter 0
labellist cohort
foreach g in `r(values)' {
	if `g' != 999 { // omit control group
		local h_max = 2003-`g'
		dis `h_max'
		forval h = 0/`h_max' {
			dis "g, h = `g', `h'"
			if `counter' > 0 {
				append using `dCDH_CATT_`g'_h`h''	
			}
			local counter = `counter' + 1
		}
	}
}
tempfile dCDH_CATT_w_`g'
save 	`dCDH_CATT_w_`g'', replace


// 3) skip. Same as before?

// 4) take weighted average of CATT_{g,h} where weights are cohort size.
use `dCDH_CATT_w_`g'', clear
merge m:1 cohort using `est_w_`g''
assert cohort == 999 if _merge == 2 // no CATT for control group
drop _merge

// take sum product of CATT_{gh}*w_{g} for different horizons
byso h (cohort) : gen product_h = CATT_hg * w_g
byso h (cohort) : egen ATT_h_dCDH = sum(product_h)

drop if cohort == 999 // drop control cohort with no ATT
keep h ATT_h_dCDH
duplicates drop

merge 1:1 h using `tau_SnA'

// visualize: S&A estimates are larger in absolute terms
twoway (kdensity ATT_h_dCDH) (kdensity ATT_h_SnA)
sum ATT_h_dCDH ATT_h_SnA
drop _merge

label var h "Horizon"
label var ATT_h_dCDH "ATT dCDH (C = not-yet-treated)"
label var ATT_h_SnA  "ATT Sun and Abraham (C = never-treated)"

// Meeting notes: compare weights with Cass's


// save
compress
save "$dta_loc\q3a_ATTs", replace







