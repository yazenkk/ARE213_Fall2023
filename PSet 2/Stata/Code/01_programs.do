/*
Programs to be installed

*/



local net_program_list ietoolkit // for iebaltab

foreach program in `net_program_list' {
    net install `program', from ("http://fmwww.bc.edu/RePEc/bocode/i")
}

ssc install panelView
ssc install sencode
net install grc1leg, from("http://www.stata.com/users/vwiggins")
ssc install labutil
ssc install colrspace, replace
ssc install heatplot
ssc install palettes, replace

