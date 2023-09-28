/*
Programs to be installe

*/



local net_program_list ietoolkit // for iebaltab

foreach program in `net_program_list' {
    net install `program', from ("http://fmwww.bc.edu/RePEc/bocode/i")
}



ssc install heatplot
ssc install palettes, replace
ssc install colrspace, replace
ssc install dmout
ssc install oaxaca

do "$do_loc/code/my_programs/fix_import.do"

