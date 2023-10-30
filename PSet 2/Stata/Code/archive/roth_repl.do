local replloc "//Client/C$/Users/yfkas/OneDrive/Documents/personal/Berk/01_Courses/04_fall_23/ARESEC 213 Metrics/Data"

* Load processed data
// use "`replloc'/MW_cengiz_et_al_2019.dta", clear
// gen rand = runiform()
// keep if rand < 0.1
// local replloc "//Client/C$/Users/yfkas/OneDrive/Documents/personal/Berk/01_Courses/04_fall_23/ARESEC 213 Metrics/Data"
// save "`replloc'\trimmed_data", replace
use "`replloc'\trimmed_data", clear

* Number of bootstrap draws in the test
local nboot = 10

* Define treated quarter following Cengiz et al 2019
gen treated_quarter = 0
replace treated_quarter = 1 if !missing(DMW_real) & DMW_real > 0.25 & DMW > 0 & (missing(toosmall) | toosmall != 1) & (missing(fedincrease) | fedincrease == 0)

egen treated_year = total(treated_quarter) if wagebinstate, by(wagebinstate)

* Select relevant variables
gen treated = treated_quarter
gen wage = wagebins / 100

* Define a function to compute implied density
program compute_implied_density
    version 16.0
    syntax varlist(min=1 max=1)
    
    tempvar treated_in_period employment_per_capita
    
    * Filter for the specified years
    keep if year >= `1' & year <= `2'
    
    * Create a variable indicating whether the state was treated in this period
    by statenum: egen `treated_in_period' = max(treated_quarter > 0)
    
    * Compute employment_per_capita by wagebin at the state-year level
    egen `employment_per_capita' = wtdmean(overallcountpc, population) if wagebinstate, by(year wagebins `treated_in_period')
    
    * Reshape the data to be wide
    reshape wide `employment_per_capita', i(wagebins) j(`1' `2' `treated_in_period')
    
    * Compute implied density
    gen implied_density_post = `1_1' + `2_0' - `1_0'
end

* Call the function to compute implied density
compute_implied_density 2007 2015

* Filter for the desired wage bins
keep if minwagebin <= wagebins & wagebins < maxwagebin

* Create a variable for "Implied Employment"
gen Implied_Employment = cond(implied_density_post < 0, "Negative", "Non-negative")

* Create a bar chart
twoway bar implied_density_post wage, ///
    barlabel(`Implied_Employment') xtitle("Wage Bin") ytitle("Employment-to-pop") ///
    xlab(5(5)30) 