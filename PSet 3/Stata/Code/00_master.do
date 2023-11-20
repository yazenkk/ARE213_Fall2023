* ============================================================================= *
* 							ARE 213: Problem set 3
* ============================================================================= *

* ============================================================================= *
* Set initial configurations and globals
* ============================================================================= *


clear all
version 15
clear matrix
cap log close 
set more off
set varabbrev off
set linesize 255


if "`c(username)'" == "yfkashlan" {
	
	global do_loc  "//Client/C$/Users/yfkas/Documents/GitHub/ARE213_Fall2023/PSet 3/Stata"
	global dta_loc "//Client/C$/Users/yfkas/Dropbox (Personal)/ARE213/Pset3/data"
		
}

if "`c(username)'" == "rajdevb" {

	local mainfolder "/Users/rajdevb"
	
	global do_loc	"`mainfolder'/Desktop/GIT_RajdevBrar/GitHub_are213/ARE213_Fall2023/PSet 3"
	global dta_loc	"`mainfolder'/Dropbox/ARE213/Pset3"
}

log using "$do_loc/pset3_logfile.smcl", replace smcl


* install programs
* do "$do_loc/Stata/Code/01_programs.do"

* analyze
do "$do_loc/Stata/Code/02_analysis_q1.do"



log close
translate "$do_loc/pset3_logfile.smcl" "$do_loc/pset3_logfile.pdf", replace


