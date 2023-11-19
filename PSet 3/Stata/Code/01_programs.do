/*
Programs to be installed

*/
version 16.0


local net_program_list ietoolkit // for iebaltab

foreach program in `net_program_list' {
    net install `program', from ("http://fmwww.bc.edu/RePEc/bocode/i")
}


ssc install shp2dta //1f 
ssc install spmap //1f 
ssc install ssaggregate // to check  2c 
ssc install reg2hdfe // for 2b. 
