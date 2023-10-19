/*
Programs to be installed

*/


/*
local net_program_list ietoolkit // for iebaltab

foreach program in `net_program_list' {
    net install `program', from ("http://fmwww.bc.edu/RePEc/bocode/i")
}

* install version 6.2 of ietoolkit 
net install ietoolkit , from("https://raw.githubusercontent.com/worldbank/ietoolkit/v6.2/src") replace
*/
// ssc install heatplot
// ssc install palettes, replace
// ssc install colrspace, replace
ssc install dmout
ssc install oaxaca

do "$do_loc/code/my_programs/fix_import.do"

