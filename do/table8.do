use "$final_data", clear

// Create a t8 folder to store outputs if it doesn't exist 
capture mkdir "tables/t8/"

eststo clear 

//////////////////////////////////////////////////////
//Regression 1 - OLS regression of farmer-reported yields on reNDVI: excluding outliers
//////////////////////////////////////////////////////

eststo: regress yield_hectare_2018 max_re705_2018 i.block_id if yield_hectare_2018 > 0 & yield_hectare_2018 < 3900, robust  

//////////////////////////////////////////////////////
//Regression 2 - OLS regression of reNDVI on farmer-reported yields: excluding outliers
//////////////////////////////////////////////////////

regress max_re705_2018 yield_hectare_2018 i.block_id if yield_hectare_2018 > 0 & yield_hectare_2018 < 3900, robust  

nlcom (max_re705_2018:1/_b[yield_hectare_2018]) (_cons:-_b[_cons]/_b[yield_hectare_2018]) (block:_b[2.block_id]), post  // The block ID is just so the indicator shows up in esttab 

estimates store est2
estimates restore est2
eststo

//////////////////////////////////////////////////////
//Regression 3 - 2SLS regression of farmer-reported yields on reNDVI: excluding outliers
//////////////////////////////////////////////////////

eststo: ivreg2 yield_hectare_2018 i.block_id (max_re705_2018 = total_rain Sow_date) if yield_hectare_2018 > 0 & yield_hectare_2018 < 3900, robust
local f: di %9.3f `e(F)'
local j: di %9.3f `e(jp)'
estadd scalar f_manual = `f'
estadd scalar j_manual = `j'

//////////////////////////////////////////////////////
//Regression 4 - Reverse regression with 2SLS 
//////////////////////////////////////////////////////

ivreg2 max_re705_2018  i.block_id (yield_hectare_2018 = total_rain Sow_date) if yield_hectare_2018 > 0 & yield_hectare_2018 < 3900, robust
local f: di %9.3f `e(F)'
local j: di %9.3f `e(jp)'

nlcom (max_re705_2018:1/_b[yield_hectare_2018]) (_cons:-_b[_cons]/_b[yield_hectare_2018]) (block:_b[2.block_id]), post  // The block ID is just so the indicator shows up in esttab 

estimates store est4
estimates restore est4
eststo
estadd scalar f_manual = `f'
estadd scalar j_manual = `j'

label var max_re705_2018 "reNDVI"

esttab using "tables/t8/ols_vs_2sls_calibration.tex", replace se noobs ///
not label tex star(* 0.10 ** 0.05 *** 0.01) b(%9.3fc) ///
noomitted nobaselevels scalars("N Observations" "f_manual First-stage F" "j_manual J-test p") ///
sfmt(%9.0fc %9.3fc %9.3fc %20g %20g) ///
frag indicate("Block FE = *block*") ///
mtitles("\makecell[c]{OLS calibration}" "\makecell[c]{OLS calibration \\ Reverse regression}" "\makecell[c]{2SLS calibration}" ///
	"\makecell[c]{2SLS calibration \\ Reverse regression}")
