

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

gen dgestat2 = dgestat^2
gen dmage2 = dmage^2
gen dmage_tobacco = dmage*tobacco
reg dbrwt tobacco `covar_list' dmage_tobacco, robust



