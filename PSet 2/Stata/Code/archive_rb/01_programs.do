/*
Programs to be installed

*/
version 16.0


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
ssc install synth
cap ado uninstall synth_runner //in-case already installed
net install synth_runner, from(https://raw.github.com/bquistorff/synth_runner/master/) replace
