/*
Programs to be installed

*/



// local net_program_list ietoolkit // for iebaltab
//
// foreach program in `net_program_list' {
//     net install `program', from ("http://fmwww.bc.edu/RePEc/bocode/i")
// }

ssc install panelView
ssc install sencode
net install grc1leg, from("http://www.stata.com/users/vwiggins")
ssc install labutil
ssc install heatplot
ssc install palettes, replace
ssc install colrspace, replace

// did stuff
ssc install did_imputation
cap ado uninstall ftools
cap ado uninstall reghdfe
local ftools_loc "\\Client\C$\Users\yfkas\OneDrive\Documents\personal\Berk\01_Courses\04_fall_23\ARESEC 213 Metrics\ftools-master\ftools-master\src"
net install ftools, from("`ftools_loc'") replace
local reg_loc "\\Client\C$\Users\yfkas\OneDrive\Documents\personal\Berk\01_Courses\04_fall_23\ARESEC 213 Metrics\reghdfe-master\reghdfe-master\current-code"
net install reghdfe, from("`reg_loc'") replace



ssc install labellist
