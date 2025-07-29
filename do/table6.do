use "$final_data", clear

// Create a t6 folder to store outputs if it doesn't exist 
capture mkdir "tables/t6/"

eststo clear 

*****************************************************************************
* Convert raw vegetation index values to yield estimates
*****************************************************************************

regress yield_hectare_2018 max_re705_2018 i.block_id if yield_hectare_2018 > 0 & yield_hectare_2018 < 3900
predict sentinel_2018_ols, xb  

ivreg2 yield_hectare_2018 i.block_id (max_re705_2018 = total_rain Sow_date) if yield_hectare_2018 > 0 & yield_hectare_2018 < 3900
predict sentinel_2018, xb  

//////////////////////////////////////////////////////
//Regression 1 - farmer-reported yield and plot size 
//////////////////////////////////////////////////////

preserve

// We want to examine the effect of data source on power, so we only keep observations that are non-missing for each data type 
drop if missing(sentinel_2018, max_re705_2017, yield_hectare_2018_alt, yield_hectare_2017_alt)

summarize yield_hectare_2018_alt if treatment == 0, meanonly
local varMean: di %9.3f `r(mean)'
eststo: regress yield_hectare_2018_alt i.treatment yield_hectare_2017_alt i.block_id, robust
local ci_lower = _b[1.treatment] - invttail(e(df_r),0.025)*_se[1.treatment] // Add 95% confidence interval (no Lee bounds)
local ci_lower: di %9.3f `ci_lower'
local ci_upper = _b[1.treatment] + invttail(e(df_r),0.025)*_se[1.treatment] 
local ci_upper: di %9.3f `ci_upper'
estadd local confidence_interval "[`ci_lower', `ci_upper']"
estadd scalar depMean = `varMean'

//////////////////////////////////////////////////////
//Regression 2 - farmer-reported yield, measured plot size 
//////////////////////////////////////////////////////

summarize yield_hectare_2018 if treatment == 0, meanonly
local varMean: di %9.3f `r(mean)'
eststo: regress yield_hectare_2018 i.treatment yield_hectare_2017 i.block_id, robust
local ci_lower = _b[1.treatment] - invttail(e(df_r),0.025)*_se[1.treatment] // Add 95% confidence interval (no Lee bounds)
local ci_lower: di %9.3f `ci_lower'
local ci_upper = _b[1.treatment] + invttail(e(df_r),0.025)*_se[1.treatment] 
local ci_upper: di %9.3f `ci_upper'
estadd local confidence_interval "[`ci_lower', `ci_upper']"
estadd scalar depMean = `varMean'

//////////////////////////////////////////////////////
//Regression 3 - satellite, OLS calibration
//////////////////////////////////////////////////////

eststo: regress sentinel_2018_ols i.treatment max_re705_2017 max_re705_2016 i.block_id, robust 
local ci_lower = _b[1.treatment] - invttail(e(df_r),0.025)*_se[1.treatment] // Add 95% confidence interval (no Lee bounds)
local ci_lower: di %9.3f `ci_lower'
local ci_upper = _b[1.treatment] + invttail(e(df_r),0.025)*_se[1.treatment] 
local ci_upper: di %9.3f `ci_upper'
estadd local confidence_interval "[`ci_lower', `ci_upper']"

summarize sentinel_2018_ols if treatment == 0, meanonly
local varMean: di %9.3f `r(mean)'
estadd scalar depMean = `varMean'

//////////////////////////////////////////////////////
//Regression 4 - satellite, 2SLS calibration 
//////////////////////////////////////////////////////

eststo: regress sentinel_2018 i.treatment max_re705_2017 max_re705_2016 i.block_id, robust
local ci_lower = _b[1.treatment] - invttail(e(df_r),0.025)*_se[1.treatment] // Add 95% confidence interval (no Lee bounds)
local ci_lower: di %9.3f `ci_lower'
local ci_upper = _b[1.treatment] + invttail(e(df_r),0.025)*_se[1.treatment] 
local ci_upper: di %9.3f `ci_upper'
estadd local confidence_interval "[`ci_lower', `ci_upper']"

summarize sentinel_2018 if treatment == 0 
local varMean: di %9.3f `r(mean)'
estadd scalar depMean = `varMean'

restore


esttab using "tables/t6/sat_vs_fr_yield.tex", replace se noobs ///
not label tex star(* 0.10 ** 0.05 *** 0.01) noconstant b(%9.3fc) ///
noomitted nobaselevels scalars("N Observations" "r2_a Adjusted \$R^2$" "depMean Control mean" "confidence_interval 95\% CI:") ///
sfmt(%9.0fc %9.3fc %9.3fc %20g) ///
frag indicate("2017 productivity = *2017*" "2016 productivity = *2016*" "Block FE = *block*") ///
mtitles("\makecell[c]{Reported yield \\ and plot size}" "\makecell[c]{Reported yield \\ GPS plot size}" "\makecell[c]{Satellite yield \\ OLS calibration}" ///
	"\makecell[c]{Satellite yield \\ 2SLS calibration}")
 
