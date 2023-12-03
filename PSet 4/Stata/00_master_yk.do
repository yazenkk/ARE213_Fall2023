* ============================================================================= *
* 							ARE 213: Problem set 4
* 			Group members: Rajdev Brar, Yazen Kashlan, Cassandra Turk 
* ============================================================================= *

/*
Master do file for PSet 3
Course: AER 213
Date created: 12/2/2023
*/


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


if "`c(username)'" == "yfkas" {
	global do_loc  "C:/Users/yfkas/Documents/GitHub/ARE213_Fall2023/PSet 3/Stata"
	global dta_loc "C:/Users/yfkas/Dropbox (Personal)/ARE213/Pset4"
}
if "`c(username)'" == "yfkashlan" {
	global do_loc  "//Client/C$/Users/yfkas/Documents/GitHub/ARE213_Fall2023/PSet 3/Stata"
	global dta_loc "//Client/C$/Users/yfkas/Dropbox (Personal)/ARE213/Pset3/data"
}
if "`c(username)'" == "yazenkashlan" {
	global do_loc  "/Users/yazenkashlan/Documents/GitHub/ARE213_Fall2023/PSet 3/Stata"
	global dta_loc "/Users/yazenkashlan/Library/CloudStorage/Dropbox/ARE213/Pset3/data"
}

// log using "$do_loc/pset4_logfile.smcl", replace smcl


// install programs
// do "$do_loc/Code/01_programs.do"

// analyze



// log close
// translate "$do_loc/pset3_logfile.smcl" "$do_loc/pset4_logfile.pdf", replace


