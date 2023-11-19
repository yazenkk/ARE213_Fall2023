* ============================================================================= *
* 						ARE 213: Problem set 3 - Q1 + Q2 
* ============================================================================= *

* ============================================================================= *
* Load datasets 
* ============================================================================= *

* load datasets, save as global 
	global dta_lines  "${dta_loc}/data/pset3_lines.dta"
	* 149 unique lines

	global dta_cities "${dta_loc}/data/pset3_cities.dta"
	* 340 unique cities 

	global dta_stations "${dta_loc}/data/pset3_stations.dta"
	* 565 unique city-line combinations 

	global dta_distance "${dta_loc}/data/pset3_distances.dta"
	* 115600 unique city1-city2-dist combinations 

	
* ============================================================================= *
* Prepare datasets 
* ============================================================================= *
	* DeltaLines= number of open lines that go through city i 
	
	* using stations dataset, merge in lines 
	use "${dta_stations}", clear
		merge m:1 lineid using "${dta_lines}"
		assert _merge==3 
		drop _merge 
	
	* for each city, gen var for number of open lines 
		bys cityid: egen num_openlines_temp = sum(open)
		bys cityid: egen num_openlines=max(num_openlines_temp)
		lab var num_openlines "Number of open lines in city"
		drop num_openlines_temp 
		
	* for each city, number of planned lines
		bys cityid: gen num_plannedlines = _N 
		lab var num_plannedlines "Number of planned lines in city"
		
		rename num_openlines deltalines 

		keep cityid deltalines num_plannedlines 
		duplicates drop 
		
	tempfile dta_merge 
	save 	`dta_merge'

	* starting from city-level dataset, merge in variables we just created 
	use "${dta_cities}", clear 
		merge 1:1 cityid using `dta_merge'
		replace deltalines = 0 if _merge==1 
		drop _merge 
		
	tempfile city_withdeltalines 
	save 	`city_withdeltalines'
	
* ============================================================================= *
* 1a
* ============================================================================= *
* Represent DeltaLines_i as a shift-share variable
	
	* Y = outcome = 2007-2016 log change in city employment 
	* DeltaLines= number of open lines that go through city i 


	* Compute DeltaLines_i for each city 
	* Mean/min/avg of DeltaLines_i across 340 cities?
		tabstat deltalines, stats(min max mean med sd)
	/*
		variable |       min       max      mean       p50        sd
	-------------+--------------------------------------------------
	  deltalines |         0         7  .9970588         1  1.143143
	----------------------------------------------------------------
	*/
		
	* how many cities with missing data? 
	unique cityid if mi(empgrowth)
	
	* and what provinces are these missing cities from? 
	tab province_en if mi(empgrowth) 
	
* ============================================================================= *
* 1b
* ============================================================================= *
* Estimate (1) by OLS without controls and also adding fixed effects of 30 Chinese provinces. 
* Use heteroskedasticity-robust standard errors. 
* Is the coeffcient economically large? 

	
	replace province_en=proper(province_en) 
	lab var empgrowth "Emp growth (log-change, 2007-2016)"
	
	encode province_en, gen(province_enc)
	
	eststo clear 
	
	eststo: reg empgrowth deltalines  , vce(robust)	
	eststo: reg empgrowth deltalines i.province_enc , vce(robust)
	
	esttab using "${dta_loc}/1b_reg"  , nostar label  tex  replace  se wide




* ============================================================================= *
* 1c
* ============================================================================= *

	* moving forward using nlinks at the qk 
	* need to merge in nlinks (nlinks unique at lineid level) 
preserve 
	* now dataset will be at city-line level 
	merge m:m cityid using "${dta_stations}", gen(merge1) 
	/*
		Result                           # of obs.
		-----------------------------------------
		not matched                            75
			from master                        75  (_merge==1)
			from using                          0  (_merge==2)

		matched                               565  (_merge==3)
		-----------------------------------------
	*/ 	
	merge m:1 lineid using "${dta_lines}", gen(merge2) 
	
	/*
		Result                           # of obs.
		-----------------------------------------
		not matched                            75
			from master                        75  (merge2==1)
			from using                          0  (merge2==2)

		matched                               565  (merge2==3)
		-----------------------------------------
	*/ 
	unique cityid lineid 
	
	/*
	Number of unique values of cityid lineid is  640
	Number of records is  640
	*/ 	
	

	* Compute the city-level controls Qi corresponding to these qk.
	tab nlinks, gen(nlinks_) 
	forvalues i = 1/10 {
		bys cityid: egen Qi_`i' = sum(nlinks_`i')
	}
			
	bys cityid: egen sum_nlinks = sum(nlinks)
	lab var sum_nlinks "Citylevel sum of number of links across all lines"
	
	* How many of them do you have and how do you interpret them? 
	
	tab sum_nlinks 
	
	keep cityid sum_nlinks Qi_* 
	duplicates drop 
	tempfile sumnlinks_dta 
	save 	`sumnlinks_dta' 
restore 
	
	merge 1:1 cityid using `sumnlinks_dta'
	assert _merge==3 
	drop _merge 
	
	unique sum_nlinks 
	* 34 
	

* ============================================================================= *
* 1d
* ============================================================================= *
* Estimate (1) by OLS controlling for Qi instead of province fixed effects. 
* Does including Qi change the estimates? 
* Does your estimate rely on Assumptions A2 and A3?
 
	eststo clear 
	reg empgrowth deltalines Qi_*, vce(robust) 
	
	eststo: reg empgrowth deltalines Qi_*, vce(robust)

	esttab using "${dta_loc}/1d_reg"  , nostar label  tex  replace  se wide


tempfile clean_dta
save 	`clean_dta'

* ============================================================================= *
* 1e
* ============================================================================= *
	
* line-level balance tests 
	* regression of line-level covariates on shocks
	use "${dta_lines}", clear
	
	eststo clear 
	eststo: reg speed open, vce(robust)
	
* city-level balance test 
	* regressions on the shift-share instrument
	use `city_withdeltalines', clear 

	eststo clear
	eststo: reg dist_beijing deltalines, vce(robust) 

* ============================================================================= *
* 1f
* ============================================================================= *

	* translate .shp file into .dta
	shp2dta using chn_admbnda_adm2_ocha.shp,  data("china_data") coor("china_coordinates")  replace 

	* Display ∆Linesi on the map of China’s regions to visualize your treatment; 
	set graph off 
	
	spmap deltalines using "china_coordinates", id(cityid) title("Number of opened railway lines per city") ///
	legend(on)  fcolor(Blues2) clbreaks(0 1 2 3 4 5 6 7 8) clmethod(custom)  ///
	legend(label(1 "0 lines") label(2 "0 lines") label(3 "1 line") label (4 "2 lines") label (5 "3 lines") label(6 "4 lines") label(7 "5 lines") label(8 "6 lines") label(9 "7 lines")) 
	graph export "1f_graph1.png", replace 


	merge 1:1 cityid using `clean_dta', keepusing(Qi_*)
	
	* make a map for deltalines, after residualizing on Qi to visualize the identifying variation
	* make it clear which regions are in the treated group and which are in the control group and which have missing data 
	
	

* ============================================================================= *
* 1c
* ============================================================================= *
* ============================================================================= *
* 1c
* ============================================================================= *


* 2a -------------------------------------------------------------------------- * 
* Compute standard errors clustered by province 

use `clean_dta', clear 

	* vce(cluster clustvar) is a generalization of the vce(robust) calculation 
	eststo clear 
	eststo: reg empgrowth deltalines Qi_* , vce(cluster province_enc) 
	
	esttab using "${dta_loc}/2a_reg"  , nostar label  tex  replace  se wide b(4)



* 2b -------------------------------------------------------------------------- * 
* Compute spatially-clustered ("Conley") standard errors. 
* Describe any choices you have made. 
	eststo clear 
	eststo: acreg empgrowth deltalines Qi_* , spatial longitude(longitude) latitude(latitude) dist(100) 
	esttab using "${dta_loc}/2b_reg"  , nostar label  tex  replace  se wide b(4)

* 2c -------------------------------------------------------------------------- * 
/* Manually use the BHJ equivalence result to compute tau^_1 from a weighted IV
specification at the level of planned lines. Describe and interpret the outcome, 
treatment, instrument, controls, and weights in this specificationg, taking into
account he somewhat special structyure of DeltaLines_i relative to a generic 
shift-share variable. Confirm that the estimate matches your answer to 1d 
perfectly. You should find that there are a bit fewer than 149 observations - 
why is that? Finally, report exposure-robust SEs for tau_hat1.  */ 

* shock-level IV regression 
	* calculate average employment level per line (so average across all cities the line touches)

	use `dta_stations', clear 

	merge m:1 cityid using `clean_dta', keepusing(empgrowth deltalines) 
	
	unique lineid cityid 
	
		
	bys lineid: egen avg_emp_k = mean(empgrowth)
	bys lineid: egen avg_deltalines_k = mean(deltalines) 
	
	lab var avg_emp_k 		 "Avg emp of cities linked to line"
	lab var avg_deltalines_k "Avg deltalines of cities linked to line" 
	
	keep lineid avg_emp_k  avg_deltalines_k
	
	
	duplicates drop 
	drop if mi(lineid)


	merge 1:1 lineid using `dta_lines', keepusing(open nlinks)
	assert _merge==3 
	

	use `clean_dta', clear 
	
	* y = d + q 
	* line-level regression
	* instrument d by g 
	
	
	* regress employment growth on Qis 
	drop if mi(empgrowth)
	regress empgrowth Qi_*, robust 
	predict reg1_coef 
	predict reg1_y, residuals
	
	* regress  delta lines on Qis 
	regress deltalines Qi_*, robust 
	predict reg2_coef 
	predict reg2_d, residuals
	
	tempfile data_residuals
	save 	`data_residuals'
	
	use `dta_lines', clear 
	merge 1:m lineid using `dta_stations'
	drop _merge 
	
	merge m:1 cityid using `data_residuals', keepusing(Qi_* reg1_y reg2_d) 
	
	bys lineid: egen avg_resy = mean(reg1_y) 
	bys lineid: egen avg_resd = mean(reg2_d)
	
	
	forvalues i = 1/10 {
	bys lineid: egen sum_Qi_`i' = sum(Qi_`i')
	}
	keep lineid avg_resy avg_resd open nlinks sum_Qi_*  

	
	duplicates drop 
	
	tab nlinks, gen(nlinks_) 
	drop if mi(lineid) 
	
	* generate weights = (1/N)*Sigma(S_ik) 
	* the number of cities the line passes through / the number of cities 

	gen weights = (nlinks+1)/ 275

	ivreg2 avg_resy (avg_resd=open) nlinks_* [pweights=weights]
	
	

	ivreg2 avg_resy (avg_resd=open) nlinks_*  [fweights=weights]
	ivreg2 avg_resy (avg_resd=open) nlinks_*  [pweights=weights]
	ivreg2 avg_resy (avg_resd=open) nlinks_*  [iweights=weights]
	ivreg2 avg_resy (avg_resd=open) nlinks_*  [aweights=weights]

	e
	
	
preserve 
ssaggregate empgrowth , controls("i.sum_nlinks num_plannedlines") s(deltaline) n(city_enc)
restore 
	* n = indsutry identifiers = city in our case 
	* s = name of exposure weight variable 
	*, string: indicates that the indstury identifier is a string 
	
ivreg




	* can cross check with the ssaggregate package
* spatial_hac_iv 


* As we saw in D3 slide 16, conventional clustering of SE (i.e by province or Conley spatial clustering) will not caputre the fact that observations with similar shares are exposed to the same shocks -- both g_k and the unobserved v_k. This is where the 2c method comes in: Adao, Kolesar, Morales (2019) derive corrected formula, which leverages independence of g_k, regardless of correlations in e_i. BHJ show SE from the shock-level equivalent regression are valid. Conventional solution, directly extends to autocorrelation, spatial clsutering etc. 



https://berenger.baospace.com/why-and-how-to-spatially-cluster-standard-errors-solved-in-stata/


https://blogs.worldbank.org/impactevaluations/randomly-drawn-equators
"Similar to cluster robust standard errors, these perform well only when there is a reasonable number of independent clusters (typically at least 30)"
