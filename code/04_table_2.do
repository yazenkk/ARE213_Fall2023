/*

Outline: Q2

Purpose: analyze the causal effects of maternal smoking during pregnancy 
	on infant birth weight.

*/

local correlations off

use "$dta_loc/data/pset1_clean.dta", clear

** Q2.a ------------------------------------------------------------------------
// Compute the mean difference in birthweight in grams by smoking status. 
// Is this difference likely to be causal? Provide some evidence for or against.

// group averages
reg dbrwt tobacco 

// explore causality. Control for some observables. Effect should disappear if not causal

/*
Some predictors of low birthweight from the NIH:
https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7290279/#:~:text=
Demographic%20factors%20such%20as%20young,23%2C24%2C25%5D.

Demographic factors such as young maternal age, higher birth order, prim-gravida, 
low educational level, and poor maternal nutritional status before and during 
pregnancy are well recognized risk factors for LBW [7,22,23,24,25]. 
Numerous other determinants have also been associated with intrauterine 
growth retardation, such as rural residence, poor diet, anemia, parity, 
and presence of chronic illness [25,26,27]. Socioeconomic factors including 
household income and level of education have also been suggested [26,28].
*/

// robust to race differences
reg dbrwt tobacco mrace3_? 

// adding a lot of demographic controls that could correlate with the outcomes
// leaves the treatment effect strong.
reg dbrwt tobacco mrace3_? anemia alcohol adequacy monpre dfeduc dmage


// robust to being born with other siblings
reg dbrwt tobacco mrace3_? dplural


// stop 
// continue here. add table showing these regs + brief comment


** Q2.a ------------------------------------------------------------------------
// keep variables for next steps. Explore correlations. See covariates excel sheet 
if "`correlations'" == "on" {

	pwcorr monpre nprevist, sig
	pwcorr isllb10 nlbnl, sig
	pwcorr dfage dmage, sig
	pwcorr dfeduc dmeduc, sig
	pwcorr moth_hisp fath_hisp, sig

	pwcorr dgestat dbrwt
	pwcorr male dbrwt, sig
	pwcorr dplural dbrwt tobacco
	pwcorr omaps dbrwt tobacco, sig
	pwcorr fmaps dbrwt tobacco, sig
	pwcorr clingest dbrwt tobacco

	// mother health
	pwcorr dbrwt tobacco dmeduc dmage ///
		anemia cardiac lung diabetes herpes chyper phyper pre4000 preterm monpre, sig

	pwcorr dbrwt tobacco dmeduc dmage ///
		nlbnl adequacy

	// alcohol
	pwcorr dbrwt tobacco dmeduc dmage ///
		alcohol drink5 wgain, sig

	// demog
	pwcorr dbrwt tobacco ///
		mrace3_1 mrace3_2 mrace3_3 moth_hisp fath_hisp ///
		dmeduc dmage dmeduc dmar ///
		omaps fmaps, sig

	pwcorr	omaps fmaps, sig


	// all control-worthy mother's health vars
		pwcorr adequacy nlbnl dlivord totord9 monpre diabetes alcohol wgain cardiac lung ///
			chyper phyper pre4000 preterm dgestat dplural clingest fmaps, sig
	// 	matrix corrmatrix = r(C)
	// 	heatplot corrmatrix

		// remaining ones
		pwcorr adequacy nlbnl diabetes alcohol wgain cardiac lung ///
			chyper phyper pre4000 preterm, sig
	// 	matrix corrmatrix = r(C)
	// 	heatplot corrmatrix

	// all control-worthy demog
	pwcorr dmage dmeduc dmar mrace3_1 mrace3_2 mrace3_3 moth_hisp, sig
	// 	matrix corrmatrix = r(C)
	// 	heatplot corrmatrix

		pwcorr dbrwt tobacco dmage dmeduc dmar mrace3_1 mrace3_2 mrace3_3 moth_hisp, sig
}

local keep_covars ///
		alcohol ///
		mrace3_2 ///
		mrace3_3 ///
		moth_hisp /// hisp_moth
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
		male /// csex
		totord9 ///
		isllb10 ///
		dlivord ///
		dplural

pwcorr		chyper phyper, sig
keep dbrwt tobacco `keep_covars'

// save
compress
save "$dta_loc/data/pset1_clean_trim.dta", replace
