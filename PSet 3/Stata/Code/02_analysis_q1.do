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
	
	eststo clear 
	
	* gen standardized 
	summ open 
	gen open_std =open/`r(sd)'

	eststo: reg  open_std speed [aw=nlinks], vce(robust)
	esttab using "${dta_loc}/1e_panel1_reg"  , nostar label  tex  replace  se wide
	
* city-level balance test 
	* regressions on the shift-share instrument
	use `city_withdeltalines', clear 

	eststo clear
	
	summ deltalines 
	gen deltalines_std = deltalines/`r(sd)'
	
	eststo: reg  deltalines_std dist_beijing, vce(robust) 
	esttab using "${dta_loc}/1e_panel2_reg"  , nostar label  tex  replace  se wide
e
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

* generate residuals 
	use `clean_dta', clear 
	drop if mi(empgrowth) | mi(deltalines) 
	
	regress empgrowth Qi_*
	predict res_y, residuals
	
	regress deltalines Qi_*
	predict res_d, residuals	
	
	keep cityid res_y res_d 
	duplicates drop 
	
	count if mi(res_y) 
	count if mi(res_d) 
	
	tempfile residuals 
	save 	`residuals' // 275 cities with data for y (empgrowth) and d (deltalines)
	

* combine all generated variables to create line-level dataset for main regression 
	use "${dta_stations}", clear 
	gen Sik = 1 
	lab var Sik "Indicator: line k passes through city i"
	* bys lineid: egen agg_sk = total(Sik) 
	
	merge m:1 cityid using `residuals', gen(merge_residuals)
	unique cityid if merge_residuals==3 
	keep if merge_residuals==3 

	bys lineid: gen num_d = Sik * res_d
	bys lineid: gen num_y = Sik * res_y 
	bys lineid: egen d_bar = sum(num_d)
	bys lineid: egen y_bar = sum(num_y) 
	bys lineid: egen denom = sum(Sik) 
	bys lineid: replace d_bar = d_bar/denom 
	bys lineid: replace y_bar = y_bar/denom 
	
	gen totobs = _N 
	gen sk = denom/totobs 

	keep lineid y_bar d_bar sk 

	duplicates drop 
	
	* merge in open and nlinks 
	merge 1:1 lineid using "${dta_lines}"
	
	lab var y_bar "Exposure-weighted avg of residuals of empgrowth"
	lab var d_bar "Exposure-weighted avg of residuals of deltalines"
	
	eststo clear 
	eststo: ivregress 2sls y_bar (d_bar=open) i.nlinks [aw=sk] , robust 
	esttab using "${dta_loc}/2c_reg",  nostar label  tex  replace  se wide b(4)


	* try ssaggregate 
	merge 1:m lineid using "${dta_stations}", gen(merge_stations)
	
	merge m:1 cityid using `city_withdeltalines', keepusing(empgrowth deltalines) gen(merge_cities) 

	* ssaggregate empgrowth deltalines [aw=sk] , n(lineid) s(sk) controls("i.nlinks") 
	
	
