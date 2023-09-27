/*
Master do file for PSet 1
Course: AER 213
Author: Yazen
Date created: 9/24/2024


*/

clear all
version 16.1




if "`c(username)'" == "yfkashlan" {
	
	local mainfolder "//Client/C$/Users/yfkas/OneDrive/Documents"
	
	global do_loc  "`mainfolder'/GitHub/ARE213_Fall2023"
	global dta_loc "`mainfolder'/personal/Berk/01_Courses/04_fall_23/ARESEC 213 Metrics/PSet1"
	
	// programs
	net set ado "//Client/C$\Users/yfkas/Documents/stata_packages"
	adopath + "//Client/C$/Users/yfkas/Documents/stata_packages"
	
}

stop
// install programs
do "$do_loc/code/01_programs.do"

// clean
do "$do_loc/code/02_clean.do"





