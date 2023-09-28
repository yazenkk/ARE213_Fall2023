* ============================================================================= *
* 							ARE 213: Problem set 1
* 			Group members: Rajdev Brar, Yazen Kashlan, Cassandra Turk 
* ============================================================================= *

/*
Master do file for PSet 1
Course: AER 213
Date created: 9/24/2024
*/


* ============================================================================= *
* Set initial configurations and globals
* ============================================================================= *

clear all
version 16.1
clear matrix

set more off
set varabbrev off
set linesize 100

cap log close
set linesize 225


if "`c(username)'" == "yfkashlan" {
	
	local mainfolder "//Client/C$/Users/yfkas/OneDrive/Documents"
	
	global do_loc  "`mainfolder'/GitHub/ARE213_Fall2023"
	global dta_loc "`mainfolder'/personal/Berk/01_Courses/04_fall_23/ARESEC 213 Metrics/PSet1"
	
	// programs
	net set ado "//Client/C$\Users/yfkas/Documents/stata_packages"
	adopath + "//Client/C$/Users/yfkas/Documents/stata_packages"
	
}
if `c(username)' == "rajdevb" {
	global directory	"/Users/rajdevb/Dropbox/ARE213/Pset1"
	
	global raw_data					"${directory}/raw_data/pset1.dta"
	global intermediate_output		"${directory}/intermediate_output"
	
}


stop
// install programs
do "$do_loc/code/01_programs.do"

// clean
do "$do_loc/code/02_clean.do"

// analyze
do "$do_loc/code/03_analysis.do"



