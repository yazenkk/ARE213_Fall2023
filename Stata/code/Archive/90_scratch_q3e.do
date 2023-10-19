

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

local covar_list alcohol hisp_moth cardiac pre4000  ///
				 phyper chyper diabetes anemia lung ///
				 csex dmar mrace3_2 mrace3_3 

					
regress dbrwt `covar_list' if tobacco == 1
estimates store tobac1
predict e_ya if tobacco == 1, xb
egen e_ya_mu = mean(e_ya)

regress dbrwt `covar_list'  if tobacco == 0
estimates store tobac0
predict e_yb if tobacco == 0, xb
egen e_yb_mu = mean(e_yb)

// compare means using suest to account for covariance
suest tobac1 tobac0
test [tobac1_mean = tobac0_mean]

// new approach
gen R_vector = e_ya_mu - e_yb_mu
sum R_vector
stop


estimates clear

// contrast with oaxaca command
oaxaca dbrwt `covar_list', by(tobacco) noisily
stop

foreach var of varlist `covar_list' {
	
	* gen int_`var' = `var'*tobacco 
		
	* gen var = (X_i -X)	
	egen mean_`var' = mean(`var')
	gen diffmean_`var' = `var'-mean_`var'
	
	* gen (Xi-X)Di 
	gen int_`var' = diffmean_`var'*tobacco
	
}
	
reg dbrwt tobacco `covar_list' int_*, robust
oaxaca dbrwt `covar_list', by(tobacco) relax noisily


stop


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
predict e_ya if tobacco == 1, xb

regress dbrwt `covar_list' `interact_x' if tobacco == 0
estimates store tobac0
predict e_yb if tobacco == 0, xb

// compare means using suest to account for covariance
suest tobac1 tobac0
test [tobac1_mean = tobac0_mean]

// new approach
gen R_vector = e_ya - e_yb
sum R_vector
stop


// contrast with oaxaca command
oaxaca dbrwt `covar_list' `interact_x', by(tobacco) suest relax noisily


// Q: Should we use full interaction? We'd have to cut down on our covariate list.

