use "$final_data", clear

// Create a f8 folder to store outputs if it doesn't exist 
capture mkdir "figures/f8/"

set scheme plotplain

*****************************************************************************
* Convert raw vegetation index values to yield estimates
*****************************************************************************

regress yield_hectare_2018 max_re705_2018 i.block_id if yield_hectare_2018 > 0 & yield_hectare_2018 < 3900
predict sentinel_2018_ols, xb  

ivreg2 yield_hectare_2018 i.block_id (max_re705_2018 = total_rain Sow_date) if yield_hectare_2018 > 0 & yield_hectare_2018 < 3900
predict sentinel_2018, xb  

label var yield_hectare_2018 "Farmer-reported yield (kg/ha)"
label var sentinel_2018 "Predicted yield, IV"
scatter sentinel_2018 yield_hectare_2018 || ///
line yield_hectare_2018 yield_hectare_2018, color(red) aspectratio(1) legend(off) ytitle("Predicted yield, IV") yscale(range(-2000 4000))
gexport, file("figures/f8/yield-prediction-iv.png")
 
label var sentinel_2018_ols "Predicted yield, OLS"
scatter sentinel_2018_ols yield_hectare_2018 || ///
line yield_hectare_2018 yield_hectare_2018, color(red) aspectratio(1) legend(off) ytitle("Predicted yield, OLS") yscale(range(-2000 4000))
gexport, file("figures/f8/yield-prediction-ols.png") 

