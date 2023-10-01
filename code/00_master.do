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
version 15
clear matrix

set more off
set varabbrev off
set linesize 100

cap log close
set linesize 225

// See used in lasso step Q5b. 
global seed_q5b 1234

if "`c(username)'" == "yfkashlan" {
	
	global do_loc  "//Client/C$/Users/yfkas/OneDrive/Documents/GitHub/ARE213_Fall2023"
	global dta_loc "//Client/C$/Users/yfkas/CEGA Dropbox/Yazen Kashlan/ARE213/Pset1"
	
	// programs
	net set ado "//Client/C$\Users/yfkas/Documents/stata_packages"
	adopath + "//Client/C$/Users/yfkas/Documents/stata_packages"
	
}

if "`c(username)'" == "rajdevb" {

	local mainfolder "/Users/rajdevb"
	
	global do_loc	"`mainfolder'/Desktop/GIT_RajdevBrar/GitHub_are213/ARE213_Fall2023"
	global dta_loc	"`mainfolder'/Dropbox/ARE213/Pset1"
}


stop

// install programs
do "$do_loc/code/01_programs.do"

// clean
do "$do_loc/code/02_clean.do"

// analyze
do "$do_loc/code/03_analysis.do"



