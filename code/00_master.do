* ============================================================================= *
* 							ARE 213: Problem set 1
* 	Group members: Rajdev Brar, Yazen Kashlan, Cassandra Turk, Max Snyder 
* ============================================================================= *
/*

	Title: 		00_master.do.do

 	Outline:

 	Input: 		pset1.dta

	Output:		pset1_cleaned.dta

	Date created: 9/24/2024
*/

* ============================================================================= *

	clear all
	version 15
	clear matrix

	set more off
	set varabbrev off
	set linesize 100

	cap log close
	set linesize 225

* ============================================================================= *


if "`c(username)'" == "yfkashlan" {
	
	local mainfolder "//Client/C$/Users/yfkas/OneDrive/Documents"
	
	global do_loc  "`mainfolder'/GitHub/ARE213_Fall2023"
	global dta_loc "`mainfolder'/personal/Berk/01_Courses/04_fall_23/ARESEC 213 Metrics/PSet1" // PENDING YK CHANGE TO DROPBOX 
	
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
do "$do_loc/code/01_programs.do"

// clean
do "$do_loc/code/02_clean.do"





