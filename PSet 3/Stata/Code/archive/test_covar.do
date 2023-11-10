// testing covariance rules


forval i = 1/1000 {
    clear
	dis "`i'"
qui {
	set obs 1000
	gen y = rnormal(-1,1)
	gen x = rnormal(-1,1) + 10
	qui sum x
	gen xd = x - `r(mean)'
	corr y x
	local rho_`i' = `r(rho)'
	corr y xd
	local rhod_`i' = `r(rho)'
	
	clear
	set obs 1
	gen rho = `rho_`i''
	gen rhod = `rhod_`i''
	
	tempfile rho_`i'_dta
	save 	`rho_`i'_dta'
}
}
pause
use `rho_1_dta', clear
forval i = 1/1000 {
	append using `rho_`i'_dta'
}
kdensity rho
kdensity rhod





