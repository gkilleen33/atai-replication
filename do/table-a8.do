use "$final_data", clear 

* This table replicates Appendix Table 4, but interacts everything with an indicator for using a well to irrigate at baseline

// Create a t-a8 folder to store outputs if it doesn't exist 
capture mkdir "tables/t-a8/"

generate interaction = irrigation_well_bl 
generate treatxinteraction = treatment*interaction 

label var interaction "Well"  
label var treatxinteraction "Treatment x Well"

/**********************************************************************************
Amount of fertilizer applied basal (kg/ha)
**********************************************************************************/
eststo clear

foreach x in "UREA" "DAP" "MOP" "ZINC"{
	summarize `x'_kg_hectare_bd if treatment == 0, meanonly 
	local varMean =`r(mean)'
	eststo: regress `x'_kg_hectare_bd treatment interaction treatxinteraction i.block_id, robust
	estadd scalar depMean = `varMean'
}

//Joint effects

local var_num = 1
**Defining list of variables looping over, for eventual combination of estimates
foreach x of varlist UREA_kg_hectare_bd DAP_kg_hectare_bd MOP_kg_hectare_bd ZINC_kg_hectare_bd {

	**Run regression for a given outcome in the variable list
	regress `x' treatment interaction treatxinteraction i.block_id

	**Store the estimates				
	noi estimates store var`var_num'_eg1
	
	**Store the SD from the control observations of the sample [Here, intervention == 3 was control]
	tempvar samplevar
	g `samplevar' = e(sample)
	summ `x' if `samplevar' == 1 & treatment == 0
	local sd1_`var_num' = r(sd)

	**Change variable number counter to next number
	local var_num = `var_num' + 1
}

**Combine stored estimates  [If you are clustering standard errors, you need to wait until now to do this or else SUEST won't work]
suest var1_eg1 var2_eg1 var3_eg1 var4_eg1, robust

**Calculate average standardized effect across outcomes  [Here, when combining outcomes sometimes have plus, sometimes minus, depending on whether more is good (ex: vitamin uptake) or bad (eg: malnutrition), 
//then use trickery to get it to save as a regression estimation that can be added correctly to esttab

nlcom (treatment:([var1_eg1_mean]treatment/`sd1_1' + [var2_eg1_mean]treatment/`sd1_2' ///
	+ [var3_eg1_mean]treatment/`sd1_3' + [var4_eg1_mean]treatment/`sd1_4') / 4) ///
	(interaction:([var1_eg1_mean]interaction/`sd1_1' + [var2_eg1_mean]interaction/`sd1_2' ///
	+ [var3_eg1_mean]interaction/`sd1_3' + [var4_eg1_mean]interaction/`sd1_4') / 4) ///
	(treatxinteraction:([var1_eg1_mean]treatxinteraction/`sd1_1' + [var2_eg1_mean]treatxinteraction/`sd1_2' ///
	+ [var3_eg1_mean]treatxinteraction/`sd1_3' + [var4_eg1_mean]treatxinteraction/`sd1_4') / 4) /// 
	(block:([var1_eg1_mean]2.block)), post  // This last line is just so block FEs get included

estimates store est5 

estimates restore est5
eststo


esttab using "tables/t-a8/fert_applied_basal.tex", replace se noobs not label tex star(* 0.10 ** 0.05 *** 0.01) ///
noomitted nobaselevels scalars("N Observations" "depMean Control mean") sfmt(%9.0fc %9.3fc %9.3fc) frag interaction(" x ") indicate("Block FE = *block*") ///
mtitles("UREA" "DAP" "MOP" "Zinc" "\makecell[c]{Standardized \\ joint effects}") rename(v1 treatment) ///
noconstant

/**********************************************************************************
Fertilizer gap (basal)
**********************************************************************************/

*This loops over each fertilizer of interest, calculates the distance (absolute difference), then calculates treatment effects with this DV
eststo clear

foreach x in "UREA" "DAP" "MOP" "ZINC"{
	summarize distance_`x' if treatment == 0, meanonly 
	local varMean =`r(mean)'
	eststo: regress distance_`x' treatment interaction treatxinteraction i.block_id, robust
	estadd scalar depMean = `varMean'
}

//Joint effects

local var_num = 1
**Defining list of variables looping over, for eventual combination of estimates
foreach x of varlist distance_UREA distance_DAP distance_MOP distance_ZINC {

	**Run regression for a given outcome in the variable list
	regress `x' treatment interaction treatxinteraction i.block_id

	**Store the estimates				
	noi estimates store var`var_num'_eg1
	
	**Store the SD from the control observations of the sample [Here, intervention == 3 was control]
	tempvar samplevar
	g `samplevar' = e(sample)
	summ `x' if `samplevar' == 1 & treatment == 0
	local sd1_`var_num' = r(sd)

	**Change variable number counter to next number
	local var_num = `var_num' + 1
}

**Combine stored estimates  [If you are clustering standard errors, you need to wait until now to do this or else SUEST won't work]
suest var1_eg1 var2_eg1 var3_eg1 var4_eg1, robust

**Calculate average standardized effect across outcomes  [Here, when combining outcomes sometimes have plus, sometimes minus, depending on whether more is good (ex: vitamin uptake) or bad (eg: malnutrition), 
//then use trickery to get it to save as a regression estimation that can be added correctly to esttab

nlcom (treatment:([var1_eg1_mean]treatment/`sd1_1' + [var2_eg1_mean]treatment/`sd1_2' ///
	+ [var3_eg1_mean]treatment/`sd1_3' + [var4_eg1_mean]treatment/`sd1_4') / 4) ///
	(interaction:([var1_eg1_mean]interaction/`sd1_1' + [var2_eg1_mean]interaction/`sd1_2' ///
	+ [var3_eg1_mean]interaction/`sd1_3' + [var4_eg1_mean]interaction/`sd1_4') / 4) ///
	(treatxinteraction:([var1_eg1_mean]treatxinteraction/`sd1_1' + [var2_eg1_mean]treatxinteraction/`sd1_2' ///
	+ [var3_eg1_mean]treatxinteraction/`sd1_3' + [var4_eg1_mean]treatxinteraction/`sd1_4') / 4) /// 
	(block:([var1_eg1_mean]2.block)), post  // This last line is just so block FEs get included

estimates store est5 

estimates restore est5
eststo

esttab using "tables/t-a8/gap_basal.tex", replace se noobs not label tex star(* 0.10 ** 0.05 *** 0.01) ///
noomitted nobaselevels scalars("N Observations" "depMean Control mean") sfmt(%9.0fc %9.3fc %9.3fc) frag ///
indicate("Block FE = *block*") rename(v1 treatment) noconstant ///
mtitles("UREA" "DAP" "MOP" "Zinc" "\makecell[c]{Standardized \\ joint effects}")

********************************************************************************************************
* Total amount of fertilizer applied (kg/ha)
********************************************************************************************************

eststo clear

foreach x in "urea" "dap" "mop" "zinc" {
  summarize `x'_kg_hectare_ml if treatment == 0, meanonly 
  local varMean = `r(mean)' 
  eststo: regress `x'_kg_hectare_ml treatment interaction treatxinteraction i.block_id, robust
  estadd scalar depMean = `varMean'
} 

//Joint effects

local var_num = 1
**Defining list of variables looping over, for eventual combination of estimates
foreach x of varlist urea_kg_hectare_ml dap_kg_hectare_ml mop_kg_hectare_ml zinc_kg_hectare_ml {

  **Run regression for a given outcome in the variable list
  regress `x' treatment interaction treatxinteraction i.block_id

  **Store the estimates       
  noi estimates store var`var_num'_eg1
  
  **Store the SD from the control observations of the sample [Here, intervention == 3 was control]
  tempvar samplevar
  g `samplevar' = e(sample)
  summ `x' if `samplevar' == 1 & treatment == 0
  local sd1_`var_num' = r(sd)

  **Change variable number counter to next number
  local var_num = `var_num' + 1
}

**Combine stored estimates  [If you are clustering standard errors, you need to wait until now to do this or else SUEST won't work]
suest var1_eg1 var2_eg1 var3_eg1 var4_eg1, robust

**Calculate average standardized effect across outcomes  [Here, when combining outcomes sometimes have plus, sometimes minus, depending on whether more is good (ex: vitamin uptake) or bad (eg: malnutrition), 
//then use trickery to get it to save as a regression estimation that can be added correctly to esttab

nlcom (treatment:([var1_eg1_mean]treatment/`sd1_1' + [var2_eg1_mean]treatment/`sd1_2' ///
	+ [var3_eg1_mean]treatment/`sd1_3' + [var4_eg1_mean]treatment/`sd1_4') / 4) ///
	(interaction:([var1_eg1_mean]interaction/`sd1_1' + [var2_eg1_mean]interaction/`sd1_2' ///
	+ [var3_eg1_mean]interaction/`sd1_3' + [var4_eg1_mean]interaction/`sd1_4') / 4) ///
	(treatxinteraction:([var1_eg1_mean]treatxinteraction/`sd1_1' + [var2_eg1_mean]treatxinteraction/`sd1_2' ///
	+ [var3_eg1_mean]treatxinteraction/`sd1_3' + [var4_eg1_mean]treatxinteraction/`sd1_4') / 4) /// 
	(block:([var1_eg1_mean]2.block)), post  // This last line is just so block FEs get included

estimates store est5 

estimates restore est5
eststo


esttab using "tables/t-a8/fert_applied_midline.tex", replace se noobs not label tex star(* 0.10 ** 0.05 *** 0.01) ///
noomitted nobaselevels scalars("N Observations" "depMean Control mean") sfmt(%9.0fc %9.3fc %9.3fc) ///
frag interaction(" x ") indicate("Block FE = *block*") ///
mtitles("UREA" "DAP" "MOP" "Zinc" "\makecell[c]{Standardized \\ joint effects}") rename(v1 treatment) ///
noconstant b(%9.3fc)

/**********************************************************************************
Fertilizer gap
**********************************************************************************/

//////////////////////////////////////////////////////
// Midline (all doses)
//////////////////////////////////////////////////////


eststo clear

foreach x in "urea" "dap" "mop" "zinc" {

  summarize distance_`x' if treatment == 0, meanonly 
  local varMean = `r(mean)' 
  eststo: regress distance_`x' treatment interaction treatxinteraction i.block_id, robust
  estadd scalar depMean = `varMean'

} 

// Joint effects

**Run regression of interest

local var_num = 1
**Defining list of variables looping over, for eventual combination of estimates
foreach x of varlist distance_urea distance_dap distance_mop distance_zinc {

  **Run regression for a given outcome in the variable list
  regress `x' treatment interaction treatxinteraction i.block_id

  **Store the estimates       
  noi estimates store var`var_num'_eg1
  
  **Store the SD from the control observations of the sample 
  tempvar samplevar
  g `samplevar' = e(sample)
  summ `x' if `samplevar' == 1 & treatment == 0
  local sd1_`var_num' = r(sd)

  **Change variable number counter to next number
  local var_num = `var_num' + 1
}

**Combine stored estimates  [If you are clustering standard errors, you need to wait until now to do this or else SUEST won't work]
suest var1_eg1 var2_eg1 var3_eg1 var4_eg1, robust 

**Calculate average standardized effect across outcomes  [Here, when combining outcomes sometimes have plus, sometimes minus, depending on whether more is good (ex: vitamin uptake) or bad (eg: malnutrition), 
//then use trickery to get it to save as a regression estimation that can be added correctly to esttab

nlcom (treatment:([var1_eg1_mean]treatment/`sd1_1' + [var2_eg1_mean]treatment/`sd1_2' ///
	+ [var3_eg1_mean]treatment/`sd1_3' + [var4_eg1_mean]treatment/`sd1_4') / 4) ///
	(interaction:([var1_eg1_mean]interaction/`sd1_1' + [var2_eg1_mean]interaction/`sd1_2' ///
	+ [var3_eg1_mean]interaction/`sd1_3' + [var4_eg1_mean]interaction/`sd1_4') / 4) ///
	(treatxinteraction:([var1_eg1_mean]treatxinteraction/`sd1_1' + [var2_eg1_mean]treatxinteraction/`sd1_2' ///
	+ [var3_eg1_mean]treatxinteraction/`sd1_3' + [var4_eg1_mean]treatxinteraction/`sd1_4') / 4) /// 
	(block:([var1_eg1_mean]2.block)), post  // This last line is just so block FEs get included

estimates store est5
estimates restore est5
eststo


esttab using "tables/t-a8/gap_all_doses.tex", replace se noobs frag not label tex star(* 0.10 ** 0.05 *** 0.01) ///
noomitted nobaselevels scalars("N Observations" "depMean Control mean") sfmt(%9.0fc %9.3fc %9.3fc) noconstant b(%9.3fc) ///
indicate("Block FE = *block*") mtitles("\makecell[c]{UREA}" "\makecell[c]{DAP}" "\makecell[c]{MOP}" "\makecell[c]{Zinc}" "\makecell[c]{Standardized \\ joint effects}")


