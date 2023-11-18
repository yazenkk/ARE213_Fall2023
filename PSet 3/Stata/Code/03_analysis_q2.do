

* load dataset 
local dta_lines  "/Users/rajdevb/Dropbox/ARE213/Pset3/data/pset3_lines.dta"
* 149 unique lines

	 
local dta_cities "/Users/rajdevb/Dropbox/ARE213/Pset3/data/pset3_cities.dta"
* 340 unique cities 

local dta_stations "/Users/rajdevb/Dropbox/ARE213/Pset3/data/pset3_stations.dta"
* 565 unique city-line combinations 

local dta_distance "/Users/rajdevb/Dropbox/ARE213/Pset3/data/pset3_distances.dta"
* 115600 unique city1-city2-dist combinations 


* ============================================================================= *
* set up 
* ============================================================================= *
* Specification: Y_i = tau_i * DeltaLines_i + epsilon_i 
	* DeltaLines= number of open lines that go through city i 
	
	* dataset should have city-line-whether line is open 
	use `dta_stations', clear
	merge m:1 lineid using `dta_lines'
	assert _merge==3 
	drop _merge 
	
	* for each city, number of open lines 
	bys cityid: egen num_openlines_temp = sum(open)
	bys cityid: egen num_openlines=max(num_openlines_temp)
	lab var num_openlines "Number of open lines in city"
	drop num_openlines_temp 
	
	rename num_openlines deltalines 

	keep cityid deltalines 
	duplicates drop 
	tempfile dta_merge 
	save 	`dta_merge'

	
	use `dta_cities', clear 
	merge 1:1 cityid using `dta_merge'
	replace deltalines = 0 if _merge==1 
	drop _merge 
	
	tempfile city_withdeltalines 
	save 	`city_withdeltalines'

* 2 --------------------------------------------------------------------------- * 
/* HSR network is of course spatially correlated, and there may be spatial correlation 
in e_i. Co
*/ 
