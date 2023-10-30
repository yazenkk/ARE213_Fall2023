/*
Title: 		02_analysis_q3z.do
Outline:	Question 3, PSet 2 

Q3 DinD estimation

3. Stack estimates in latex table

*/



local table_loc table_3_all
local table_title "ATT and SE by estimation method"
local note_local "This table shows the ATT and, where feasible, the SE estimated using the different methods listed in question 3."

// print table of selected vars
cap file close fh 
file open fh using "$do_loc/Tables/`table_loc'.tex", replace write

	file write fh "\begin{center}" _n
	file write fh "\begin{tabular}{lccl}" _n
	file write fh "\hline\hline" _n
	file write fh "Question & ATT & SE & Estimation note \\ [0.5ex]" _n
	file write fh "\hline" _n
	file write fh "Q3a 		& $att_est_3a  & - 			 & dCDH (2023) \\ " _n
	file write fh "Q3b 		& $att_est_3b  & $se_est_3b  & BJS (2023) \\ " _n
	file write fh "Q3c.i 	& $att_est_3c1 & $se_est_3c1 & Population weight 1 \\ " _n
	file write fh "Q3c.ii 	& $att_est_3c2 & $se_est_3c2 & Population weight 2 \\ " _n
	file write fh "Q3d 		& $att_est_3d  & $se_est_3d  & Including state-specific linear trends \\ " _n
	file write fh "Q3e 		& $att_est_3e  & $se_est_3e  & Including several covariates \\ " _n
	file write fh "Q3f 		& $att_est_3f  & $se_est_3f  & Static TWFE \\ " _n
	file write fh "\hline\hline" _n	
	file write fh "\end{tabular}" _n 
	file write fh "\end{center}" _n	

file close fh 


