* ============================================================================= *
* 							ARE 213: Problem set 2
* 			Group members: Rajdev Brar, Yazen Kashlan, Cassandra Turk 
* ============================================================================= *

/*
Master do file for PSet 2
Course: AER 213
Date created: 10/19/2023
*/


* ============================================================================= *
* Set initial configurations and globals
* ============================================================================= *


clear all
version 15
clear matrix
cap log close 


// log using "$do_loc/pset2_logfile.smcl", replace smcl


set more off
set varabbrev off
set linesize 255


if "`c(username)'" == "yfkashlan" {
	
	global do_loc  "//Client/C$/Users/yfkas/Documents/GitHub/ARE213_Fall2023/PSet 2/Stata"
	global dta_loc "//Client/C$/Users/yfkas/Dropbox (Personal)/ARE213/Pset2/data"
	
	// programs
	net set ado "//Client/C$\Users/yfkas/Documents/stata_packages"
	adopath + "//Client/C$/Users/yfkas/Documents/stata_packages"
	
}

if "`c(username)'" == "rajdevb" {

	local mainfolder "/Users/rajdevb"
	
	global do_loc	"`mainfolder'/Desktop/GIT_RajdevBrar/GitHub_are213/ARE213_Fall2023"
	global dta_loc	"`mainfolder'/Dropbox/ARE213/Pset1"
}


// install programs
// do "$do_loc/Code/01_programs.do"

// analyze
do "$do_loc/Code/02_analysis_q1.do"
do "$do_loc/Code/02_analysis_q2.do"
do "$do_loc/Code/02_analysis_q3a.do"
do "$do_loc/Code/02_analysis_q3b.do"
do "$do_loc/Code/02_analysis_q3c.do"
do "$do_loc/Code/02_analysis_q3d.do"
do "$do_loc/Code/02_analysis_q3e.do"
do "$do_loc/Code/02_analysis_q3f.do"
do "$do_loc/Code/02_analysis_q3z.do" // stack results



// log close
// translate "$do_loc/pset2_logfile.smcl" "$do_loc/pset2_logfile.pdf", replace


