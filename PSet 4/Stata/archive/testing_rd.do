// Generate artifitial data:
clear
set obs 2000
set seed 42
gen lpd_data = rnormal()

// Density estimation at empirical quantiles:
lpdensity lpd_data

// Density estimation at empirical quantiles with the IMSE-optimal bandwidth:
lpdensity lpd_data, bwselect(imse-dpi)


lpdensity lpd_data, plot
lpdensity lpd_data, plot histogram
lpdensity lpd_data, plot histogram ciuniform level(90)




// Load dataset (cutoff is 0 in this dataset):
cls
clear
use rddensity_senate.dta, clear

// Manipulation test using default options:
rddensity margin
rddensity margin, plot

// Reporting both conventional and robust bias-corrected statistics:
rddensity margin, all

// Manipulation test using manual bandwidths choices and plug-in standard errors:
rddensity margin, h(10 20) vce(plugin)

// Plot density and save results to variables:
capture drop temp_*
rddensity margin, pl plot_range(-50 50) plot_n(100 100) genvars(temp)


// rdplot

use rdrobust_senate.dta, clear

// Basic specification with title
rdplot vote margin, graph_options(title(RD Plot))

// Quadratic global polynomial with confidence bands
rdplot vote margin, p(2) ci(95) shade



// test rdperm
use table_two_final.dta, clear

// Implement test with default options.
rdperm difdemshare demshareprev

// Implement joint test using 50 observations from either side.
rdperm difdemshare demshareprev demwinprev, q(50)

