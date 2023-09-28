

// Oaxaca Blinder

use "$dta_loc/data/pset1_clean.dta", clear

local covar_list 	alcohol ///
					mrace3_2 ///
					mrace3_3 ///
					hisp_moth /// 
					adequacy ///
					cardiac ///
					pre4000 ///
					phyper ///
					chyper ///
					diabetes ///
					anemia ///
					lung ///
					wgain ///
					dmeduc ///
					dgestat ///
					dmage ///
					dmar ///
					csex /// 
					totord9 ///
					isllb10 ///
					dlivord ///
					dplural


// regress dbrwt `covar_list' if tobacco == 1
// estimates store tobac1
//
// regress dbrwt `covar_list' if tobacco == 0
// estimates store tobac0
//
// // compare means using suest to account for covariance
// suest tobac1 tobac0
// test [tobac1_mean = tobac0_mean]
//
// estimates clear
//
// // contrast with oaxaca command
// oaxaca dbrwt `covar_list', by(tobacco) suest


// -----------------------------------------------------------------------------
// try again with saturated model
tab adequacy, gen(adequacy_)
drop adequacy
local covar_list 	alcohol ///
					mrace3_2 ///
					mrace3_3 ///	
					hisp_moth /// 
					adequacy_1 ///
					adequacy_2 ///
					adequacy_3 ///
					cardiac ///
					pre4000

foreach i of varlist `covar_list' {
	foreach j of varlist `covar_list' {
		if "`i'" != "`j'" {
			gen  `i'_`j' = `i'*`j'
			local interact_x `interact_x' `i'_`j'
		}
	}
}
dis "`interact_x'"


regress dbrwt `covar_list' `interact_x' if tobacco == 1
estimates store tobac1

regress dbrwt `covar_list' `interact_x' if tobacco == 0
estimates store tobac0

// compare means using suest to account for covariance
suest tobac1 tobac0
test [tobac1_mean = tobac0_mean]


// contrast with oaxaca command
oaxaca dbrwt `covar_list' `interact_x', by(tobacco) suest relax


// Q: Should we use full interaction? We'd have to cut down on our covariate list.



