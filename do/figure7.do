use "$final_data", clear

// Create a f7 folder to store outputs if it doesn't exist 
capture mkdir "figures/f7/"

eststo clear 

generate productivity_2017 = . //We will replace this variable in each regression so all 2017 values of the dependent variable appear in one row 
label var productivity_2017 "2017 yield"


*****************************************************************************
* Convert raw vegetation index values to yield estimates 
*****************************************************************************

ivreg2 yield_hectare_2018 i.block_id (max_re705_2018 = total_rain Sow_date) if yield_hectare_2018 >0 & yield_hectare_2018 < 3900, robust
predict sentinel_2018, xb 

* OLS yield predictions 
regress yield_hectare_2018 max_re705_2018 i.block_id if yield_hectare_2018 > 0 & yield_hectare_2018 < 3900, robust
predict sentinel_2018_ols, xb 

//////////////////////////////////////////////////////
//Regression 1 - farmer-reported yield and plot size: full sample and Lee Bounds
//////////////////////////////////////////////////////

replace productivity_2017 = yield_hectare_2017_alt
eststo: regress yield_hectare_2018_alt i.treatment productivity_2017 i.block_id, robust

//////////////////////////////////////////////////////
//Regression 2 - satellite, 2016 control (full sample)
//////////////////////////////////////////////////////

replace productivity_2017 = max_re705_2017
eststo: regress sentinel_2018 i.treatment productivity_2017 max_re705_2016 i.block_id, robust

//////////////////////////////////////////////////////
//Regression 3 - satellite, 2016 control (full sample), OLS predictions 
//////////////////////////////////////////////////////

replace productivity_2017 = max_re705_2017
eststo: regress sentinel_2018_ols i.treatment productivity_2017 max_re705_2016 i.block_id, robust

//////////////////////////////////////////////////////
//Regression 4 - farmer-reported yield and plot size 
//////////////////////////////////////////////////////

preserve

// We want to examine the effect of data source on power, so we only keep observations that are non-missing for each data type 
drop if missing(sentinel_2018, max_re705_2017, yield_hectare_2018_alt, yield_hectare_2017_alt)

replace productivity_2017 = yield_hectare_2017_alt
eststo: regress yield_hectare_2018_alt i.treatment productivity_2017 i.block_id, robust

//////////////////////////////////////////////////////
//Regression 5 - satellite, no 2016 control
//////////////////////////////////////////////////////

replace productivity_2017 = max_re705_2017
eststo: regress sentinel_2018 i.treatment productivity_2017 i.block_id, robust 

//////////////////////////////////////////////////////
//Regression 6 - satellite, no 2016 control, OLS predictions 
//////////////////////////////////////////////////////

replace productivity_2017 = max_re705_2017
eststo: regress sentinel_2018_ols i.treatment productivity_2017 i.block_id, robust 

//////////////////////////////////////////////////////
//Regression 7 - satellite, 2016 control
//////////////////////////////////////////////////////

replace productivity_2017 = max_re705_2017
eststo: regress sentinel_2018 i.treatment productivity_2017 max_re705_2016 i.block_id, robust

//////////////////////////////////////////////////////
//Regression 8 - satellite, 2016 control, OLS predictions 
//////////////////////////////////////////////////////

replace productivity_2017 = max_re705_2017
eststo: regress sentinel_2018_ols i.treatment productivity_2017 max_re705_2016 i.block_id, robust

restore

set scheme s2color //Default scheme 

coefplot est1 || est2 || est3 || est4 || est5 || est6 || est7 || est8, bycoefs ///
drop(productivity_2017 *.block_id _cons max_re705_2016) ///
bylabels("FR" "Satellite, 2SLS" "Satellite, OLS" "FR" `""Satellite, 2SLS" "(exc. 2016)""' `""Satellite, OLS" "(exc. 2016)""' "Satellite, 2SLS" "Satellite, OLS") ///
msymbol(d) mcolor(white) levels(99 95 90 80 70) ciopts(lwidth(3 ..) lcolor(*.2 *.4 *.6 *.8 *1)) xline(0) ///
legend(order(1 "99" 2 "95" 3 "90" 4 "80" 5 "70") rows(1)) groups(1 2 3 ="All data" 4 5 6 7 8="Intersecting sample") ///
graphregion(color(white)) plotregion(margin(b = 0))

gexport, file("figures/f7/confidence_intervals.png")

