**
**	PROJECT: 	 Applied Econometrics Pset1
**
**  DESCRIPTION: Panel Data, and the Effects of Primary Seat Belt Laws on Traﬀic Fatalities 
**
**	PURPOSE: 	 Conduct empirical analysis for the pset
**
**	AUTHOR:		 Bobing, Dingzhe, Rui, Prema
**
**	CREATED:	 27 October 2023
**
**	LAST MODIFIED: 30 October 2023
**	
*******************************************************************************************

cls 
clear all
set more off 
cap log close 

if "`c(username)'"== "bobingqiu" cd "D:\OneDrive - pku.edu.cn\Berkeley\2023 Fall\ARE 213 Applied Econometrics\PSet1"
if "`c(username)'"== "premanarasimhan" local dbhome "/Users/premanarasimhan/Dropbox/Professional/Berkeley/Academics/Second year/ARE 213/problem sets/PSet2"
if "`c(username)'"== "yfkashlan" local dbhome "//Client/C$/Users/yfkas/Dropbox (Personal)/ARE213/Pset2"

log using "$do_loc/pset2_logfile_prema.smcl", replace smcl



********************************************************************************
* Paths and Settings
********************************************************************************

global raw    "`dbhome'/data"
global temp   "`dbhome'/temp"
global clean  "`dbhome'/clean"
global graphs "`dbhome'/graphs"
global tables "`dbhome'/tables"

/* packages
net describe dm31, from(http://www.stata.com/stb/stb26)
net install dm31
net install grc1leg, from(http://www.stata.com/users/vwiggins) replace
net install gr0075, from(http://www.stata-journal.com/software/sj18-4) replace
ssc install labutil, replace
ssc install sencode, replace
ssc install panelview, all
ssc install did_imputation
ssc install reghdfe 
ssc install ftools
ssc install fuzzydid
ssc install did_multipleGT 
ssc install did_multiplegt_dyn
ssc install pretrends
ssc install synth2
net install synth_runner, from(https://raw.github.com/bquistorff/synth_runner/master/) replace
*/

********************************************************************************
* Import data
********************************************************************************

use "$raw/pset2.dta", clear 
tsset state year 

by state (year), sort: gen evt_first = sum(primary) == 1 & sum(primary[_n - 1]) == 0
by state (year), sort: gen evt_year = evt_first * year if evt_first == 1
by state (evt_year), sort: replace evt_year = evt_year[_n - 1] if missing(evt_year) //cohorts 
replace evt_year = 0 if missing(evt_year) // never-treated groups
gen evt_year_treat = evt_year if evt_year != 0

**Outcome variable 
gen l_fatalities_pc = log(fatalities/population) 
gen fatalities_pc = fatalities/population

* Summarize the data 
* Check panel balance and visualization 
egen nmiss = rmiss2(state-l_fatalities_pc)
tab nmiss //Balanced panel, no missing in any variable 

***************Synthetic control methods 
keep if state == 4 | evt_year == 0  //keep only CA and never-treated group 

******synthetic control 
// reghdfe l_fatalities_pc college beer unemploy precip snow32 totalvmt rural_speed urban_speed, absorb(state year) cluster(state) //college snow32 totalvmt urban_speed not good predictor of fatality 

**estimation
synth l_fatalities_pc beer unemploy precip rural_speed l_fatalities_pc(1981) l_fatalities_pc(1985) l_fatalities_pc(1988) l_fatalities_pc(1992), trunit(4) trperiod(1993) nested allopt figure 
mat sc_weights = e(W_weights) 
mat list sc_weights 
mat ATT = e(Y_treated) - e(Y_synthetic)
disp ATT[13, 1] //-.08472038 
*graph export "Output/ps2_4a.png", replace 

**inference 
// synth_runner l_fatalities_pc beer unemploy precip rural_speed l_fatalities_pc(1981) l_fatalities_pc(1985) l_fatalities_pc(1988) l_fatalities_pc(1992), trunit(4) trperiod(1993) gen_vars 

******synthetic DiD 
sdid l_fatalities_pc state year primary, vce(placebo) covariates(beer unemploy precip rural_speed) seed(123) g1on method("sdid") graph mattitles //choice of vce type? cannot do bootstrap or jackknife 
*graph export "Output/ps2_4b.png", replace 
mat unit_weights = e(omega)
mat time_weights = e(lambda)
mat list unit_weights 
mat list time_weights

******imputation for CA only 
gen treat_year = evt_year if evt_year != 0 
did_imputation l_fatalities_pc state year treat_year, fe(state year) control(beer unemploy precip rural_speed) autosample nose minn(0) 

**estimate a model for non-treated potential outcomes 
reghdfe l_fatalities_pc beer unemploy precip rural_speed, absorb(state year) vce(cluster state)
predict yhat

**show the predicted untreated potential outcome for CA
preserve 
keep if evt_year != 0
xtline l_fatalities_pc yhat if year <= 1994, xline(1993, lpattern("--") lcolor("gray") lwidth(thin)) ///
    ytitle("Log fatalities in 1,000") xtitle("Year") xscale(r(1981 1995)) xlabel(1981[3]1995) ///
    legend(order(1 "Actual Y(0)" 2 "Imputed Y(0)")) legend(col(2)) 
*graph export "Output/ps2_4c.png", replace 
restore 


log close
translate "$do_loc/pset1_logfile.smcl" "$do_loc/pset1_logfile.pdf", replace


