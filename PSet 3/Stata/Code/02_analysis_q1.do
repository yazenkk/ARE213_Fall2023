/*
PSet is based on the Borusyak and Hull analysis of employment effects of China's 
high-speed railway (HSR) system.

Data struture: 
two levels of analysis: cities i and HSR lines k.
- cross-section of 340 cities in  China; offcially they are called “prefecture-level cities” (and they are really regions rather than cities). 
- outcome var: Yi= 2007–2016 log-change in city employment (which has some missing values).
- there are 149 planned HSR lines, 84 of which opened by the end of 2016; see Figure 1B
in BH for the map of the open and not-yet-open lines.
	- explanatory variables will be different summary measures of a city’s connectedness to the HSR network in 2016 relative to 2007.
	
To get identifying variation in the railway network, we will follow BH in making the
following “design” assumptions:
A1: Each line has a probability of being opened by 2016 which only depends (in an unspecified way) on the number of cross-regional “links” the line has, denoted Lk, which you can think of as the number of cities the line connects, minus one.
		- E.g., it is fine if lines connecting more regions are prioritized to open first, but lines with the same Lk are of equal priority regardless of which cities they connect and one might argue the variation in opening is due to some unexpected construction delays for random reasons;
A2. Whether line k opens is independent from whether any other one opens;
A3. Whether line k opens is independent from the error terms, i.e. employment trends of
any city due to reasons other than HSR development.

*/

* ssc install shp2dta //1f 
* ssc install spmap //1f 
* ssc install ssaggregate // to check  2c 
* ssc install reg2hdfe // for 2b. 

* load dataset 
local dta_lines  "/Users/rajdevb/Dropbox/ARE213/Pset3/data/pset3_lines.dta"
* 149 unique lines

	 
local dta_cities "/Users/rajdevb/Dropbox/ARE213/Pset3/data/pset3_cities.dta"
* 340 unique cities 

local dta_stations "/Users/rajdevb/Dropbox/ARE213/Pset3/data/pset3_stations.dta"
* 565 unique city-line combinations 

local dta_distance "/Users/rajdevb/Dropbox/ARE213/Pset3/data/pset3_distances.dta"
* 115600 unique city1-city2-dist combinations 



	use `dta_cities', clear 
	
	e
	br if lineid==252 
	/* connected to city 44 and 31 */
	* nlinks== 1
	
	
	e 
	
	
	
* ============================================================================= *
* Question 1
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
	
	* for each city, number of planned lines
	bys cityid: gen num_plannedlines = _N 
	lab var num_plannedlines "Number of planned lines in city"
	
	rename num_openlines deltalines 

	keep cityid deltalines num_plannedlines 
	duplicates drop 
	tempfile dta_merge 
	save 	`dta_merge'

	
	use `dta_cities', clear 
	merge 1:1 cityid using `dta_merge'
	replace deltalines = 0 if _merge==1 
	drop _merge 
	
	tempfile city_withdeltalines 
	save 	`city_withdeltalines'
	

* 1a -------------------------------------------------------------------------- * 
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
	

* 1b -------------------------------------------------------------------------- * 
* Estimate (1) by OLS without controls and also adding fixed effects of 30 Chinese provinces. 
* Use heteroskedasticity-robust standard errors. 
* Is the coeffcient economically large? 

	
	replace province_en=proper(province_en) 
	lab var empgrowth "Emp growth (log-change, 2007-2016)"
	
	encode province_en, gen(province_enc)
	
	eststo clear 
	
	eststo: reg empgrowth deltalines  , vce(robust)	
	eststo: reg empgrowth deltalines i.province_enc , vce(robust)
	
	esttab using "/Users/rajdevb/Dropbox/PhD Fall 2023/ARE 213/1b_reg"  , nostar label  tex  replace  se wide




* 1c -------------------------------------------------------------------------- * 
* Which line-level controls does Assumption A1 compel us to include (qk in the notation of the lecture)? 

	/*
	A1: Each line has a probability of being opened by 2016 which only depends (in an unspecified way) on the number of cross-regional “links” the line has, denoted Lk, which you can think of as the number of cities the line connects, minus one.

	Candidates: 
	nlinks 
	number of planned lines // i don't think we include this because it's not a line-level control 
	year opened 
		
	Vector of shock-level controls should include a constant (BHJ, pg 12) 

	Other notes: 
	BJH: Ït follows from Proposition 2 that beta is identified by Assumption 1 provided the instrument is relevant. 
	(pg 12)
	*/ 

	* moving forward using nlinks at the qk 
	* need to merge in nlinks (nlinks unique at lineid level) 
preserve 
	* now dataset will be at city-line level 
	merge m:m cityid using `dta_stations', gen(merge1) 
	/*
		Result                           # of obs.
		-----------------------------------------
		not matched                            75
			from master                        75  (_merge==1)
			from using                          0  (_merge==2)

		matched                               565  (_merge==3)
		-----------------------------------------
	*/ 	
	merge m:1 lineid using `dta_lines', gen(merge2) 
	
	/*
		Result                           # of obs.
		-----------------------------------------
		not matched                            75
			from master                        75  (merge2==1)
			from using                          0  (merge2==2)

		matched                               565  (merge2==3)
		-----------------------------------------
	*
	*/ 
	unique cityid lineid 
	/*
	Number of unique values of cityid lineid is  640
	Number of records is  640
	*/ 	
	
	
	
* Compute the city-level controls Qi corresponding to these qk.
	tab nlink, gen(nlink_) 
	forvalues i = 1/10 {
		bys cityid: egen Qi_`i' = sum(nlink_`i')
	}
			
	bys cityid: egen sum_nlinks = sum(nlinks)
	lab var sum_nlinks "Citylevel sum of number of links across all lines"
	
* How many of them do you have and how do you interpret them? 
	*/ 
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
	
* Intuitively, why is including these controls a good idea?
	* From class: As long as we put in the shift-share control, then the shift-share regression is valid (slide 11)
	* From slide 12, I think we are in the case of incomplete shares, then we have to control for the sum of exposure shares (Qi) 
	
	* page 35: https://bfi.uchicago.edu/wp-content/uploads/2020/09/BFI_WP_2020130.pdf
	* Borusyak et al. (2020) show how for linear SSIVs, of the form z_l = sum(w_ln g_n), OVB from non-random exposure is removed by controlling for sum(w_ln q_n) provided E[g_n | q_n] is linear. In the language of the present paper, such controls absorb the expected instrument
		
	* BJH: Relax A1 and A2 to only hold conditionally on a vector of shock-level observables qn (that includes a constant) 

	/*BH: Even when the opening status of lines is as-good-as-randomly
	assigned, regions in the economic and geographic center of the country will tend to see
	more market access growth than peripheral regions as the former are closer to a typical
	potential line. Central regions may face different amenity and productivity shocks,
	generating OVB.
	*/


* 1d -------------------------------------------------------------------------- * 
* Estimate (1) by OLS controlling for Qi instead of province fixed effects. 
* Does including Qi change the estimates? 
* Does your estimate rely on Assumptions A2 and A3?
 
	eststo clear 
	reg empgrowth deltalines Qi_*, vce(robust) 
	
	eststo: reg empgrowth deltalines Qi_*, vce(robust)

	* esttab using "/Users/rajdevb/Dropbox/PhD Fall 2023/ARE 213/1d_reg"  , nostar label  tex  replace  se wide


tempfile clean_dta
save 	`clean_dta'



* 1e -------------------------------------------------------------------------- * 
* For each line, pset3_lines reports the operational speed (in km/h). 
* For each city, pset3_cities reports the distance from city i to Beijing (in km). 
* Use these variables to run balance tests. 

	* The identifying variation is at the shock level, so we want to ensure shocks are uncorrelated with observables, controlling for our covariates. Seeing as our shifter or our shcok variable is S_ik = I{line k passes through city i}, we want to show (1) that S_ik is uncorrelated with city observables, controlling for province FE, and (2) we also want to make sure SSIV is uncorrelated with regional(?) observables, controlling for X and Y. We want to show balance across lines and balance across cities.
	
/* Note that Autor et al. (2013)'s dataset -- BHJ did a shock balance test to check for industry-level balanace and regiona balance  (BHJ - Table 3) 

	Y= growth of manufacturing employment rate
	D= growth of import competition in region i 
	
	Z = sum (Sik * gk) = predicted growth of import competition 
		* Sik: 10year lagged share of manufacturing industry 
		* gk: growth of industry import competition 

	k= industry 
	i = region 


In our case, Y=tD + e
	Y= log change in employment 
	D= number of lines opened 
	
	Z 
		Sik: I{line k passes through city i} 
		gk: line k opened by 2016 
		
	k= line 
	i= city 

	*/
	
	
* line-level balance tests 
	* regression of line-level covariates on shocks
	use `dta_lines', clear
	
	eststo clear 
	eststo: reg speed open, vce(robust)
	
* city-level balance test 
	* regressions on the shift-share instrument
	use `city_withdeltalines', clear 

	eststo clear
	eststo: reg dist_beijing deltalines, vce(robust) 


* 1f -------------------------------------------------------------------------- * 
* When working with spatial data, visualizing main variables on a map is invaluable.
* Display ∆Linesi on the map of China’s regions to visualize your treatment; confirm that what you see is consistent with the map of opened lines in Figure 1A of BH.


* translate .shp file into .dta
shp2dta using chn_admbnda_adm2_ocha.shp,  data("china_data") coor("china_coordinates")  replace 

* spmap deltalines using "china_coordinates", id(cityid) fcolor(Blues)




* 2a -------------------------------------------------------------------------- * 
* Compute standard errors clustered by province 

use `clean_dta', clear 

	* vce(cluster clustvar) is a generalization of the vce(robust) calculation 
	eststo clear 
	eststo: reg empgrowth deltalines Qi_* , vce(cluster province_enc) 
	
	esttab using "/Users/rajdevb/Dropbox/PhD Fall 2023/ARE 213/2a_reg"  , nostar label  tex  replace  se wide



* 2b -------------------------------------------------------------------------- * 
* Compute spatially-clustered ("Conley") standard errors. 
* Describe any choices you have made. 
	eststo clear 
	eststo: acreg empgrowth deltalines Qi_* , spatial longitude(longitude) latitude(latitude) dist(100) 
	esttab using "/Users/rajdevb/Dropbox/PhD Fall 2023/ARE 213/2b_reg"  , nostar label  tex  replace  se wide

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
