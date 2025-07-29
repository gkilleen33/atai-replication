use "$final_data", clear 

// Create a t-a5 folder to store outputs if it doesn't exist 
capture mkdir "tables/t-a5/"

cap file close handle
file open handle using "tables/t-a5/recommendations_by_dose.tex", write replace

/////////////
// UREA 
/////////////

* Basal dose 

// Begin with the amount applied for the 2017 season 
quietly summarize used_urea_bl if irrigation_bl == 0 & treatment == 0
local share_apply_ur_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_urea_bl if irrigation_bl == 0 & treatment == 1
local share_apply_ur_treat_bl: di %9.2fc `r(mean)' 

quietly summarize used_urea_bl if irrigation_bl == 1 & treatment == 0
local share_apply_ir_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_urea_bl if irrigation_bl == 1 & treatment == 1
local share_apply_ir_treat_bl: di %9.2fc `r(mean)' 

summarize urea_bd_rec_ir if irrigation_bl == 1 & used_urea_bl == 1  
local average_rec_ir_bl: di %9.2fc `r(mean)'

summarize urea_bd_rec_ur if irrigation_bl == 0 & used_urea_bl == 1  
local average_rec_ur_bl: di %9.2fc `r(mean)'

generate urea_kg_ha_d1_bl = urea_kg_dose_1_vBL/merged_cotton_area  // Use the endline calculated cotton area since it's more precise, and for fair comparisons 

quietly summarize urea_kg_ha_d1_bl if treatment == 0 & irrigation_bl == 0 & used_urea_bl == 1
local average_amt_control_ur_bl: di %9.2fc `r(mean)'

quietly summarize urea_kg_ha_d1_bl if treatment == 0 & irrigation_bl == 1 & used_urea_bl == 1
local average_amt_control_ir_bl: di %9.2fc `r(mean)'

quietly summarize urea_kg_ha_d1_bl if treatment == 1 & irrigation_bl == 0 & used_urea_bl == 1
local average_amt_treat_ur_bl: di %9.2fc `r(mean)'

quietly summarize urea_kg_ha_d1_bl if treatment == 1 & irrigation_bl == 1 & used_urea_bl == 1
local average_amt_treat_ir_bl: di %9.2fc `r(mean)'

// Now turn to 2018 season
quietly summarize SII_6_1_UREA if SII_4_1 == 0 & treatment == 0
local share_apply_ur_control: di %9.2fc `r(mean)' 
quietly summarize SII_6_1_UREA if SII_4_1 == 1 & treatment == 0
local share_apply_ir_control: di %9.2fc `r(mean)' 

quietly summarize SII_6_1_UREA if SII_4_1 == 0 & treatment == 1
local share_apply_ur_treat: di %9.2fc `r(mean)' 
quietly summarize SII_6_1_UREA if SII_4_1 == 1 & treatment == 1
local share_apply_ir_treat: di %9.2fc `r(mean)' 

quietly summarize urea_bd_rec_ur if SII_4_1 == 0 & SII_6_1_UREA == 1 
local average_rec_ur: di %9.2fc `r(mean)'

quietly summarize urea_bd_rec_ir if SII_4_1 == 1 & SII_6_1_UREA == 1 
local average_rec_ir: di %9.2fc `r(mean)'

quietly summarize UREA_kg_hectare_bd if SII_4_1 == 0 & treatment == 0 & SII_6_1_UREA == 1
local average_amt_control_ur: di %9.2fc `r(mean)'
quietly summarize UREA_kg_hectare_bd if SII_4_1 == 1 & treatment == 0 & SII_6_1_UREA == 1
local average_amt_control_ir: di %9.2fc `r(mean)'

quietly summarize UREA_kg_hectare_bd if SII_4_1 == 0 & treatment == 1 & SII_6_1_UREA == 1
local average_amt_treat_ur: di %9.2fc `r(mean)'
quietly summarize UREA_kg_hectare_bd if SII_4_1 == 1 & treatment == 1 & SII_6_1_UREA == 1
local average_amt_treat_ir: di %9.2fc `r(mean)'

* Write to the handle 
file w handle "UREA: Basal dose unirrigated & `average_rec_ur_bl' & $`share_apply_ur_control_bl'^*$ & $`share_apply_ur_treat_bl'^*$ & $`average_amt_control_ur_bl'^*$ & $`average_amt_treat_ur_bl'^*$ & `average_rec_ur' & `share_apply_ur_control' & `share_apply_ur_treat' & `average_amt_control_ur' & `average_amt_treat_ur' \\ " _n
file w handle "UREA: Basal dose irrigated & `average_rec_ir_bl' & $`share_apply_ir_control_bl'^*$ & $`share_apply_ir_treat_bl'^*$ & $`average_amt_control_ir_bl'^*$ & $`average_amt_treat_ir_bl'^*$ & `average_rec_ir' & `share_apply_ir_control' & `share_apply_ir_treat' & `average_amt_control_ir' & `average_amt_treat_ir' \\ " _n

* Doses 2 - 4 

// First normalize doses 2 - 4 so don't include basal for 2018 data 
if urea_d1_crop_stage == 3 & !missing(urea_d1_crop_stage) {
	replace urea_d4_kg = urea_d3_kg
	replace urea_d3_kg = urea_d2_kg 
	replace urea_d2_kg = urea_d1_kg
}

// Now loop across doses 2 - 4 
forval i = 2(1)4 {
	// Begin with the amount applied for the 2017 season 
	local share_rec_apply_bl = 1 // Share recommended to apply this fertilizer type

	generate used_urea_d`i'_bl = 1 if urea_kg_dose_`i'_vBL > 0  & !missing(urea_kg_dose_`i'_vBL)
	replace used_urea_d`i'_bl = 0 if urea_kg_dose_`i'_vBL == 0 & !missing(urea_kg_dose_`i'_vBL)
	replace used_urea_d`i'_bl = 0 if !missing(used_urea_bl) & missing(used_urea_d`i'_bl)
	replace used_urea_d`i'_bl = 0 if used_urea_bl == 0

	quietly summarize used_urea_d`i'_bl if irrigation_bl == 1 & treatment == 0
	local share_apply_ir_control_bl: di %9.2fc `r(mean)' 
	quietly summarize used_urea_d`i'_bl if irrigation_bl == 1 & treatment == 1
	local share_apply_ir_treat_bl: di %9.2fc `r(mean)' 

	quietly summarize used_urea_d`i'_bl if irrigation_bl == 0 & treatment == 0
	local share_apply_ur_control_bl: di %9.2fc `r(mean)' 
	quietly summarize used_urea_d`i'_bl if irrigation_bl == 0 & treatment == 1
	local share_apply_ur_treat_bl: di %9.2fc `r(mean)' 

	quietly summarize urea_d`i'_rec_ir if irrigation_bl == 1 & used_urea_d`i'_bl == 1
	local average_rec_ir_bl: di %9.2fc `r(mean)'

	if `i' > 2 {
		generate urea_d`i'_rec_ur = 0   
	}
	quietly summarize urea_d`i'_rec_ur if irrigation_bl == 0 & used_urea_d`i'_bl == 0
	local average_rec_ur_bl: di %9.2fc `r(mean)'

	generate urea_kg_ha_d`i'_bl = urea_kg_dose_`i'_vBL/merged_cotton_area  // Use the endline calculated cotton area since it's more precise, and for fair comparisons 

	quietly summarize urea_kg_ha_d`i'_bl if irrigation_bl == 1 & treatment == 0 & used_urea_d`i'_bl == 1
	local average_amt_control_ir_bl: di %9.2fc `r(mean)'
	quietly summarize urea_kg_ha_d`i'_bl if irrigation_bl == 0 & treatment == 0 & used_urea_d`i'_bl == 1
	local average_amt_control_ur_bl: di %9.2fc `r(mean)'

	quietly summarize urea_kg_ha_d`i'_bl if irrigation_bl == 1 & treatment == 1 & used_urea_d`i'_bl == 1
	local average_amt_treat_ir_bl: di %9.2fc `r(mean)'
	quietly summarize urea_kg_ha_d`i'_bl if irrigation_bl == 0 & treatment == 1 & used_urea_d`i'_bl == 1
	local average_amt_treat_ur_bl: di %9.2fc `r(mean)'

	// Now turn to 2018 season
	local share_rec_apply = 1 // Share recommended to apply this 

	generate used_urea_d`i' = 1 if urea_d`i'_kg > 0 & !missing(urea_d`i'_kg)
	replace used_urea_d`i' = 0 if urea_d`i'_kg == 0 & !missing(urea_d`i'_kg)

	quietly summarize used_urea_d`i' if irrigation_ml == 1 & treatment == 0
	local share_apply_ir_control: di %9.2fc `r(mean)' 
	quietly summarize used_urea_d`i' if irrigation_ml == 1 & treatment == 1
	local share_apply_ir_treat: di %9.2fc `r(mean)' 

	quietly summarize used_urea_d`i' if irrigation_ml == 0 & treatment == 0
	local share_apply_ur_control: di %9.2fc `r(mean)' 
	quietly summarize used_urea_d`i' if irrigation_ml == 0 & treatment == 1
	local share_apply_ur_treat: di %9.2fc `r(mean)' 

	quietly summarize urea_d`i'_rec_ir if irrigation_ml == 1 & used_urea_d`i' == 1 
	local average_rec_ir: di %9.2fc `r(mean)'

	quietly summarize urea_d`i'_rec_ur if irrigation_ml == 0 & used_urea_d`i' == 1 
	local average_rec_ur: di %9.2fc `r(mean)'

	generate urea_kg_ha_d`i' = urea_d`i'_kg/merged_cotton_area

	summarize urea_kg_ha_d`i' if irrigation_ml == 1 & treatment == 0 & used_urea_d`i' == 1
	local average_amt_control_ir: di %9.2fc `r(mean)'
	quietly summarize urea_kg_ha_d`i' if irrigation_ml == 0 & treatment == 0 & used_urea_d`i' == 1
	local average_amt_control_ur: di %9.2fc `r(mean)'

	quietly summarize urea_kg_ha_d`i' if irrigation_ml == 1 & treatment == 1 & used_urea_d`i' == 1
	local average_amt_treat_ir: di %9.2fc `r(mean)'
	quietly summarize urea_kg_ha_d`i' if irrigation_ml == 0 & treatment == 1 & used_urea_d`i' == 1
	local average_amt_treat_ur: di %9.2fc `r(mean)'

	* Write to the handle 
	file w handle "UREA: Dose `i' unirrigated & `average_rec_ur_bl' & $`share_apply_ur_control_bl'^*$ & $`share_apply_ur_treat_bl'^*$ & $`average_amt_control_ur_bl'^*$ & $`average_amt_treat_ur_bl'^*$ & `average_rec_ur' & `share_apply_ur_control' & `share_apply_ur_treat' & `average_amt_control_ur' & `average_amt_treat_ur' \\ " _n
	file w handle "UREA: Dose `i' irrigated & `average_rec_ir_bl' & $`share_apply_ir_control_bl'^*$ & $`share_apply_ir_treat_bl'^*$ & $`average_amt_control_ir_bl'^*$ & $`average_amt_treat_ir_bl'^*$ & `average_rec_ir' & `share_apply_ir_control' & `share_apply_ir_treat' & `average_amt_control_ir' & `average_amt_treat_ir' \\ " _n

}

* Total applied 

// Begin with the amount applied for the 2017 season 
quietly summarize used_urea_bl if irrigation_bl == 0 & treatment == 0
local share_apply_ur_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_urea_bl if irrigation_bl == 0 & treatment == 1
local share_apply_ur_treat_bl: di %9.2fc `r(mean)' 

quietly summarize used_urea_bl if irrigation_bl == 1 & treatment == 0
local share_apply_ir_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_urea_bl if irrigation_bl == 1 & treatment == 1
local share_apply_ir_treat_bl: di %9.2fc `r(mean)' 

summarize urea_total_rec_ir if irrigation_bl == 1 & used_urea_bl == 1  
local average_rec_ir_bl: di %9.2fc `r(mean)'

summarize urea_total_rec_ur if irrigation_bl == 0 & used_urea_bl == 1  
local average_rec_ur_bl: di %9.2fc `r(mean)'

generate urea_kg_ha = urea_kg_vBL/merged_cotton_area  // Use the endline calculated cotton area since it's more precise, and for fair comparisons 

quietly summarize urea_kg_ha if treatment == 0 & irrigation_bl == 0 & used_urea_bl == 1
local average_amt_control_ur_bl: di %9.2fc `r(mean)'

quietly summarize urea_kg_ha if treatment == 0 & irrigation_bl == 1 & used_urea_bl == 1
local average_amt_control_ir_bl: di %9.2fc `r(mean)'

quietly summarize urea_kg_ha if treatment == 1 & irrigation_bl == 0 & used_urea_bl == 1
local average_amt_treat_ur_bl: di %9.2fc `r(mean)'

quietly summarize urea_kg_ha if treatment == 1 & irrigation_bl == 1 & used_urea_bl == 1
local average_amt_treat_ir_bl: di %9.2fc `r(mean)'

// Now turn to 2018 season
quietly summarize used_urea if SII_4_1 == 0 & treatment == 0
local share_apply_ur_control: di %9.2fc `r(mean)' 
quietly summarize used_urea if SII_4_1 == 1 & treatment == 0
local share_apply_ir_control: di %9.2fc `r(mean)' 

quietly summarize used_urea if SII_4_1 == 0 & treatment == 1
local share_apply_ur_treat: di %9.2fc `r(mean)' 
quietly summarize used_urea if SII_4_1 == 1 & treatment == 1
local share_apply_ir_treat: di %9.2fc `r(mean)' 

quietly summarize urea_total_rec_ur if SII_4_1 == 0 & SII_6_1_UREA == 1 
local average_rec_ur: di %9.2fc `r(mean)'

quietly summarize urea_total_rec_ir if SII_4_1 == 1 & SII_6_1_UREA == 1 
local average_rec_ir: di %9.2fc `r(mean)'

quietly summarize urea_kg_hectare_ml if SII_4_1 == 0 & treatment == 0 & SII_6_1_UREA == 1
local average_amt_control_ur: di %9.2fc `r(mean)'
quietly summarize urea_kg_hectare_ml if SII_4_1 == 1 & treatment == 0 & SII_6_1_UREA == 1
local average_amt_control_ir: di %9.2fc `r(mean)'

quietly summarize urea_kg_hectare_ml if SII_4_1 == 0 & treatment == 1 & SII_6_1_UREA == 1
local average_amt_treat_ur: di %9.2fc `r(mean)'
quietly summarize urea_kg_hectare_ml if SII_4_1 == 1 & treatment == 1 & SII_6_1_UREA == 1
local average_amt_treat_ir: di %9.2fc `r(mean)'

* Write to the handle 
file w handle "UREA: Total unirrigated & `average_rec_ur_bl' & $`share_apply_ur_control_bl'^*$ & $`share_apply_ur_treat_bl'^*$ & $`average_amt_control_ur_bl'^*$ & $`average_amt_treat_ur_bl'^*$ & `average_rec_ur' & `share_apply_ur_control' & `share_apply_ur_treat' & `average_amt_control_ur' & `average_amt_treat_ur' \\ " _n
file w handle "UREA: Total irrigated & `average_rec_ir_bl' & $`share_apply_ir_control_bl'^*$ & $`share_apply_ir_treat_bl'^*$ & $`average_amt_control_ir_bl'^*$ & $`average_amt_treat_ir_bl'^*$ & `average_rec_ir' & `share_apply_ir_control' & `share_apply_ir_treat' & `average_amt_control_ir' & `average_amt_treat_ir' \\[1em] " _n

/////////////
// DAP 
/////////////

generate dap_bd_rec_ur = 0 // Not recommended for non-irrigated plots
generate dap_d2_rec_ur = 0 
generate dap_total_rec_ur = 0 

* Basal dose 

// Begin with the amount applied for the 2017 season 
quietly summarize used_dap_bl if irrigation_bl == 0 & treatment == 0
local share_apply_ur_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_dap_bl if irrigation_bl == 0 & treatment == 1
local share_apply_ur_treat_bl: di %9.2fc `r(mean)' 

quietly summarize used_dap_bl if irrigation_bl == 1 & treatment == 0
local share_apply_ir_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_dap_bl if irrigation_bl == 1 & treatment == 1
local share_apply_ir_treat_bl: di %9.2fc `r(mean)' 

summarize dap_bd_rec_ir if irrigation_bl == 1 & used_dap_bl == 1  
local average_rec_ir_bl: di %9.2fc `r(mean)'

summarize dap_bd_rec_ur if irrigation_bl == 0 & used_dap_bl == 1  
local average_rec_ur_bl: di %9.2fc `r(mean)'

generate dap_kg_ha_d1_bl = dap_kg_dose_1_vBL/merged_cotton_area  // Use the endline calculated cotton area since it's more precise, and for fair comparisons 

quietly summarize dap_kg_ha_d1_bl if treatment == 0 & irrigation_bl == 0 & used_dap_bl == 1
local average_amt_control_ur_bl: di %9.2fc `r(mean)'

quietly summarize dap_kg_ha_d1_bl if treatment == 0 & irrigation_bl == 1 & used_dap_bl == 1
local average_amt_control_ir_bl: di %9.2fc `r(mean)'

quietly summarize dap_kg_ha_d1_bl if treatment == 1 & irrigation_bl == 0 & used_dap_bl == 1
local average_amt_treat_ur_bl: di %9.2fc `r(mean)'

quietly summarize dap_kg_ha_d1_bl if treatment == 1 & irrigation_bl == 1 & used_dap_bl == 1
local average_amt_treat_ir_bl: di %9.2fc `r(mean)'

// Now turn to 2018 season
quietly summarize SII_6_1_DAP if SII_4_1 == 0 & treatment == 0
local share_apply_ur_control: di %9.2fc `r(mean)' 
quietly summarize SII_6_1_DAP if SII_4_1 == 1 & treatment == 0
local share_apply_ir_control: di %9.2fc `r(mean)' 

quietly summarize SII_6_1_DAP if SII_4_1 == 0 & treatment == 1
local share_apply_ur_treat: di %9.2fc `r(mean)' 
quietly summarize SII_6_1_DAP if SII_4_1 == 1 & treatment == 1
local share_apply_ir_treat: di %9.2fc `r(mean)' 

quietly summarize dap_bd_rec_ur if SII_4_1 == 0 & SII_6_1_DAP == 1 
local average_rec_ur: di %9.2fc `r(mean)'

quietly summarize dap_bd_rec_ir if SII_4_1 == 1 & SII_6_1_DAP == 1 
local average_rec_ir: di %9.2fc `r(mean)'

quietly summarize DAP_kg_hectare_bd if SII_4_1 == 0 & treatment == 0 & SII_6_1_DAP == 1
local average_amt_control_ur: di %9.2fc `r(mean)'
quietly summarize DAP_kg_hectare_bd if SII_4_1 == 1 & treatment == 0 & SII_6_1_DAP == 1
local average_amt_control_ir: di %9.2fc `r(mean)'

quietly summarize DAP_kg_hectare_bd if SII_4_1 == 0 & treatment == 1 & SII_6_1_DAP == 1
local average_amt_treat_ur: di %9.2fc `r(mean)'
quietly summarize DAP_kg_hectare_bd if SII_4_1 == 1 & treatment == 1 & SII_6_1_DAP == 1
local average_amt_treat_ir: di %9.2fc `r(mean)'

* Write to the handle 
file w handle "DAP: Basal dose unirrigated & `average_rec_ur_bl' & $`share_apply_ur_control_bl'^*$ & $`share_apply_ur_treat_bl'^*$ & $`average_amt_control_ur_bl'^*$ & $`average_amt_treat_ur_bl'^*$ & `average_rec_ur' & `share_apply_ur_control' & `share_apply_ur_treat' & `average_amt_control_ur' & `average_amt_treat_ur' \\ " _n
file w handle "DAP: Basal dose irrigated & `average_rec_ir_bl' & $`share_apply_ir_control_bl'^*$ & $`share_apply_ir_treat_bl'^*$ & $`average_amt_control_ir_bl'^*$ & $`average_amt_treat_ir_bl'^*$ & `average_rec_ir' & `share_apply_ir_control' & `share_apply_ir_treat' & `average_amt_control_ir' & `average_amt_treat_ir' \\ " _n

* Dose 2 

// First normalize doses 2 - 4 so don't include basal for 2018 data 
if dap_d1_crop_stage == 3 & !missing(dap_d1_crop_stage) {
	replace dap_d2_kg = dap_d1_kg
}

// Begin with the amount applied for the 2017 season 
local share_rec_apply_bl = 1 // Share recommended to apply this fertilizer type

generate used_dap_d2_bl = 1 if dap_kg_dose_2_vBL > 0  & !missing(dap_kg_dose_2_vBL)
replace used_dap_d2_bl = 0 if dap_kg_dose_2_vBL == 0 & !missing(dap_kg_dose_2_vBL)
replace used_dap_d2_bl = 0 if !missing(used_dap_bl) & missing(used_dap_d2_bl)
replace used_dap_d2_bl = 0 if used_dap_bl == 0

quietly summarize used_dap_d2_bl if irrigation_bl == 1 & treatment == 0
local share_apply_ir_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_dap_d2_bl if irrigation_bl == 1 & treatment == 1
local share_apply_ir_treat_bl: di %9.2fc `r(mean)' 

quietly summarize used_dap_d2_bl if irrigation_bl == 0 & treatment == 0
local share_apply_ur_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_dap_d2_bl if irrigation_bl == 0 & treatment == 1
local share_apply_ur_treat_bl: di %9.2fc `r(mean)' 

quietly summarize dap_d2_rec_ir if irrigation_bl == 1 & used_dap_d2_bl == 1
local average_rec_ir_bl: di %9.2fc `r(mean)'

if 2 > 2 {
	generate dap_d2_rec_ur = 0   
}
quietly summarize dap_d2_rec_ur if irrigation_bl == 0 & used_dap_d2_bl == 0
local average_rec_ur_bl: di %9.2fc `r(mean)'

generate dap_kg_ha_d2_bl = dap_kg_dose_2_vBL/merged_cotton_area  // Use the endline calculated cotton area since it's more precise, and for fair comparisons 

quietly summarize dap_kg_ha_d2_bl if irrigation_bl == 1 & treatment == 0 & used_dap_d2_bl == 1
local average_amt_control_ir_bl: di %9.2fc `r(mean)'
quietly summarize dap_kg_ha_d2_bl if irrigation_bl == 0 & treatment == 0 & used_dap_d2_bl == 1
local average_amt_control_ur_bl: di %9.2fc `r(mean)'

quietly summarize dap_kg_ha_d2_bl if irrigation_bl == 1 & treatment == 1 & used_dap_d2_bl == 1
local average_amt_treat_ir_bl: di %9.2fc `r(mean)'
quietly summarize dap_kg_ha_d2_bl if irrigation_bl == 0 & treatment == 1 & used_dap_d2_bl == 1
local average_amt_treat_ur_bl: di %9.2fc `r(mean)'

// Now turn to 2018 season
local share_rec_apply = 1 // Share recommended to apply this 

generate used_dap_d2 = 1 if dap_d2_kg > 0 & !missing(dap_d2_kg)
replace used_dap_d2 = 0 if dap_d2_kg == 0 & !missing(dap_d2_kg)

quietly summarize used_dap_d2 if irrigation_ml == 1 & treatment == 0
local share_apply_ir_control: di %9.2fc `r(mean)' 
quietly summarize used_dap_d2 if irrigation_ml == 1 & treatment == 1
local share_apply_ir_treat: di %9.2fc `r(mean)' 

quietly summarize used_dap_d2 if irrigation_ml == 0 & treatment == 0
local share_apply_ur_control: di %9.2fc `r(mean)' 
quietly summarize used_dap_d2 if irrigation_ml == 0 & treatment == 1
local share_apply_ur_treat: di %9.2fc `r(mean)' 

quietly summarize dap_d2_rec_ir if irrigation_ml == 1 & used_dap_d2 == 1 
local average_rec_ir: di %9.2fc `r(mean)'

quietly summarize dap_d2_rec_ur if irrigation_ml == 0 & used_dap_d2 == 1 
local average_rec_ur: di %9.2fc `r(mean)'

generate dap_kg_ha_d2 = dap_d2_kg/merged_cotton_area

summarize dap_kg_ha_d2 if irrigation_ml == 1 & treatment == 0 & used_dap_d2 == 1
local average_amt_control_ir: di %9.2fc `r(mean)'
quietly summarize dap_kg_ha_d2 if irrigation_ml == 0 & treatment == 0 & used_dap_d2 == 1
local average_amt_control_ur: di %9.2fc `r(mean)'

quietly summarize dap_kg_ha_d2 if irrigation_ml == 1 & treatment == 1 & used_dap_d2 == 1
local average_amt_treat_ir: di %9.2fc `r(mean)'
quietly summarize dap_kg_ha_d2 if irrigation_ml == 0 & treatment == 1 & used_dap_d2 == 1
local average_amt_treat_ur: di %9.2fc `r(mean)'

* Write to the handle 
file w handle "DAP: Dose 2 unirrigated & `average_rec_ur_bl' & $`share_apply_ur_control_bl'^*$ & $`share_apply_ur_treat_bl'^*$ & $`average_amt_control_ur_bl'^*$ & $`average_amt_treat_ur_bl'^*$ & `average_rec_ur' & `share_apply_ur_control' & `share_apply_ur_treat' & `average_amt_control_ur' & `average_amt_treat_ur' \\ " _n
file w handle "DAP: Dose 2 irrigated & `average_rec_ir_bl' & $`share_apply_ir_control_bl'^*$ & $`share_apply_ir_treat_bl'^*$ & $`average_amt_control_ir_bl'^*$ & $`average_amt_treat_ir_bl'^*$ & `average_rec_ir' & `share_apply_ir_control' & `share_apply_ir_treat' & `average_amt_control_ir' & `average_amt_treat_ir' \\ " _n


* Total applied 

// Begin with the amount applied for the 2017 season 
quietly summarize used_dap_bl if irrigation_bl == 0 & treatment == 0
local share_apply_ur_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_dap_bl if irrigation_bl == 0 & treatment == 1
local share_apply_ur_treat_bl: di %9.2fc `r(mean)' 

quietly summarize used_dap_bl if irrigation_bl == 1 & treatment == 0
local share_apply_ir_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_dap_bl if irrigation_bl == 1 & treatment == 1
local share_apply_ir_treat_bl: di %9.2fc `r(mean)' 

summarize dap_total_rec_ir if irrigation_bl == 1 & used_dap_bl == 1  
local average_rec_ir_bl: di %9.2fc `r(mean)'

summarize dap_total_rec_ur if irrigation_bl == 0 & used_dap_bl == 1  
local average_rec_ur_bl: di %9.2fc `r(mean)'

generate dap_kg_ha = dap_kg_vBL/merged_cotton_area  // Use the endline calculated cotton area since it's more precise, and for fair comparisons 

quietly summarize dap_kg_ha if treatment == 0 & irrigation_bl == 0 & used_dap_bl == 1
local average_amt_control_ur_bl: di %9.2fc `r(mean)'

quietly summarize dap_kg_ha if treatment == 0 & irrigation_bl == 1 & used_dap_bl == 1
local average_amt_control_ir_bl: di %9.2fc `r(mean)'

quietly summarize dap_kg_ha if treatment == 1 & irrigation_bl == 0 & used_dap_bl == 1
local average_amt_treat_ur_bl: di %9.2fc `r(mean)'

quietly summarize dap_kg_ha if treatment == 1 & irrigation_bl == 1 & used_dap_bl == 1
local average_amt_treat_ir_bl: di %9.2fc `r(mean)'

// Now turn to 2018 season
quietly summarize used_dap if SII_4_1 == 0 & treatment == 0
local share_apply_ur_control: di %9.2fc `r(mean)' 
quietly summarize used_dap if SII_4_1 == 1 & treatment == 0
local share_apply_ir_control: di %9.2fc `r(mean)' 

quietly summarize used_dap if SII_4_1 == 0 & treatment == 1
local share_apply_ur_treat: di %9.2fc `r(mean)' 
quietly summarize used_dap if SII_4_1 == 1 & treatment == 1
local share_apply_ir_treat: di %9.2fc `r(mean)' 

quietly summarize dap_total_rec_ur if SII_4_1 == 0 & SII_6_1_DAP == 1 
local average_rec_ur: di %9.2fc `r(mean)'

quietly summarize dap_total_rec_ir if SII_4_1 == 1 & SII_6_1_DAP == 1 
local average_rec_ir: di %9.2fc `r(mean)'

quietly summarize dap_kg_hectare_ml if SII_4_1 == 0 & treatment == 0 & SII_6_1_DAP == 1
local average_amt_control_ur: di %9.2fc `r(mean)'
quietly summarize dap_kg_hectare_ml if SII_4_1 == 1 & treatment == 0 & SII_6_1_DAP == 1
local average_amt_control_ir: di %9.2fc `r(mean)'

quietly summarize dap_kg_hectare_ml if SII_4_1 == 0 & treatment == 1 & SII_6_1_DAP == 1
local average_amt_treat_ur: di %9.2fc `r(mean)'
quietly summarize dap_kg_hectare_ml if SII_4_1 == 1 & treatment == 1 & SII_6_1_DAP == 1
local average_amt_treat_ir: di %9.2fc `r(mean)'

* Write to the handle 
file w handle "DAP: Total unirrigated & `average_rec_ur_bl' & $`share_apply_ur_control_bl'^*$ & $`share_apply_ur_treat_bl'^*$ & $`average_amt_control_ur_bl'^*$ & $`average_amt_treat_ur_bl'^*$ & `average_rec_ur' & `share_apply_ur_control' & `share_apply_ur_treat' & `average_amt_control_ur' & `average_amt_treat_ur' \\ " _n
file w handle "DAP: Total irrigated & `average_rec_ir_bl' & $`share_apply_ir_control_bl'^*$ & $`share_apply_ir_treat_bl'^*$ & $`average_amt_control_ir_bl'^*$ & $`average_amt_treat_ir_bl'^*$ & `average_rec_ir' & `share_apply_ir_control' & `share_apply_ir_treat' & `average_amt_control_ir' & `average_amt_treat_ir' \\[1em] " _n

/////////////
// MOP 
/////////////

generate mop_bd_rec_ur = 0 // Not recommended for non-irrigated plots
generate mop_total_rec_ur = 0 

* Basal dose 

// Begin with the amount applied for the 2017 season 
quietly summarize used_mop_bl if irrigation_bl == 0 & treatment == 0
local share_apply_ur_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_mop_bl if irrigation_bl == 0 & treatment == 1
local share_apply_ur_treat_bl: di %9.2fc `r(mean)' 

quietly summarize used_mop_bl if irrigation_bl == 1 & treatment == 0
local share_apply_ir_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_mop_bl if irrigation_bl == 1 & treatment == 1
local share_apply_ir_treat_bl: di %9.2fc `r(mean)' 

summarize mop_bd_rec_ir if irrigation_bl == 1 & used_mop_bl == 1  
local average_rec_ir_bl: di %9.2fc `r(mean)'

summarize mop_bd_rec_ur if irrigation_bl == 0 & used_mop_bl == 1  
local average_rec_ur_bl: di %9.2fc `r(mean)'

generate mop_kg_ha_d1_bl = mop_kg_dose_1_vBL/merged_cotton_area  // Use the endline calculated cotton area since it's more precise, and for fair comparisons 

quietly summarize mop_kg_ha_d1_bl if treatment == 0 & irrigation_bl == 0 & used_mop_bl == 1
local average_amt_control_ur_bl: di %9.2fc `r(mean)'

quietly summarize mop_kg_ha_d1_bl if treatment == 0 & irrigation_bl == 1 & used_mop_bl == 1
local average_amt_control_ir_bl: di %9.2fc `r(mean)'

quietly summarize mop_kg_ha_d1_bl if treatment == 1 & irrigation_bl == 0 & used_mop_bl == 1
local average_amt_treat_ur_bl: di %9.2fc `r(mean)'

quietly summarize mop_kg_ha_d1_bl if treatment == 1 & irrigation_bl == 1 & used_mop_bl == 1
local average_amt_treat_ir_bl: di %9.2fc `r(mean)'

// Now turn to 2018 season
quietly summarize SII_6_1_MOP if SII_4_1 == 0 & treatment == 0
local share_apply_ur_control: di %9.2fc `r(mean)' 
quietly summarize SII_6_1_MOP if SII_4_1 == 1 & treatment == 0
local share_apply_ir_control: di %9.2fc `r(mean)' 

quietly summarize SII_6_1_MOP if SII_4_1 == 0 & treatment == 1
local share_apply_ur_treat: di %9.2fc `r(mean)' 
quietly summarize SII_6_1_MOP if SII_4_1 == 1 & treatment == 1
local share_apply_ir_treat: di %9.2fc `r(mean)' 

quietly summarize mop_bd_rec_ur if SII_4_1 == 0 & SII_6_1_MOP == 1 
local average_rec_ur: di %9.2fc `r(mean)'

quietly summarize mop_bd_rec_ir if SII_4_1 == 1 & SII_6_1_MOP == 1 
local average_rec_ir: di %9.2fc `r(mean)'

quietly summarize MOP_kg_hectare_bd if SII_4_1 == 0 & treatment == 0 & SII_6_1_MOP == 1
local average_amt_control_ur: di %9.2fc `r(mean)'
quietly summarize MOP_kg_hectare_bd if SII_4_1 == 1 & treatment == 0 & SII_6_1_MOP == 1
local average_amt_control_ir: di %9.2fc `r(mean)'

quietly summarize MOP_kg_hectare_bd if SII_4_1 == 0 & treatment == 1 & SII_6_1_MOP == 1
local average_amt_treat_ur: di %9.2fc `r(mean)'
quietly summarize MOP_kg_hectare_bd if SII_4_1 == 1 & treatment == 1 & SII_6_1_MOP == 1
local average_amt_treat_ir: di %9.2fc `r(mean)'

* Write to the handle 
file w handle "MOP: Basal dose unirrigated & `average_rec_ur_bl' & $`share_apply_ur_control_bl'^*$ & $`share_apply_ur_treat_bl'^*$ & $`average_amt_control_ur_bl'^*$ & $`average_amt_treat_ur_bl'^*$ & `average_rec_ur' & `share_apply_ur_control' & `share_apply_ur_treat' & `average_amt_control_ur' & `average_amt_treat_ur' \\ " _n
file w handle "MOP: Basal dose irrigated & `average_rec_ir_bl' & $`share_apply_ir_control_bl'^*$ & $`share_apply_ir_treat_bl'^*$ & $`average_amt_control_ir_bl'^*$ & $`average_amt_treat_ir_bl'^*$ & `average_rec_ir' & `share_apply_ir_control' & `share_apply_ir_treat' & `average_amt_control_ir' & `average_amt_treat_ir' \\ " _n

* Total applied 

// Begin with the amount applied for the 2017 season 
quietly summarize used_mop_bl if irrigation_bl == 0 & treatment == 0
local share_apply_ur_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_mop_bl if irrigation_bl == 0 & treatment == 1
local share_apply_ur_treat_bl: di %9.2fc `r(mean)' 

quietly summarize used_mop_bl if irrigation_bl == 1 & treatment == 0
local share_apply_ir_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_mop_bl if irrigation_bl == 1 & treatment == 1
local share_apply_ir_treat_bl: di %9.2fc `r(mean)' 

summarize mop_total_rec_ir if irrigation_bl == 1 & used_mop_bl == 1  
local average_rec_ir_bl: di %9.2fc `r(mean)'

summarize mop_total_rec_ur if irrigation_bl == 0 & used_mop_bl == 1  
local average_rec_ur_bl: di %9.2fc `r(mean)'

generate mop_kg_ha = mop_kg_vBL/merged_cotton_area  // Use the endline calculated cotton area since it's more precise, and for fair comparisons 

quietly summarize mop_kg_ha if treatment == 0 & irrigation_bl == 0 & used_mop_bl == 1
local average_amt_control_ur_bl: di %9.2fc `r(mean)'

quietly summarize mop_kg_ha if treatment == 0 & irrigation_bl == 1 & used_mop_bl == 1
local average_amt_control_ir_bl: di %9.2fc `r(mean)'

quietly summarize mop_kg_ha if treatment == 1 & irrigation_bl == 0 & used_mop_bl == 1
local average_amt_treat_ur_bl: di %9.2fc `r(mean)'

quietly summarize mop_kg_ha if treatment == 1 & irrigation_bl == 1 & used_mop_bl == 1
local average_amt_treat_ir_bl: di %9.2fc `r(mean)'

// Now turn to 2018 season
quietly summarize used_mop if SII_4_1 == 0 & treatment == 0
local share_apply_ur_control: di %9.2fc `r(mean)' 
quietly summarize used_mop if SII_4_1 == 1 & treatment == 0
local share_apply_ir_control: di %9.2fc `r(mean)' 

quietly summarize used_mop if SII_4_1 == 0 & treatment == 1
local share_apply_ur_treat: di %9.2fc `r(mean)' 
quietly summarize used_mop if SII_4_1 == 1 & treatment == 1
local share_apply_ir_treat: di %9.2fc `r(mean)' 

quietly summarize mop_total_rec_ur if SII_4_1 == 0 & SII_6_1_MOP == 1 
local average_rec_ur: di %9.2fc `r(mean)'

quietly summarize mop_total_rec_ir if SII_4_1 == 1 & SII_6_1_MOP == 1 
local average_rec_ir: di %9.2fc `r(mean)'

quietly summarize mop_kg_hectare_ml if SII_4_1 == 0 & treatment == 0 & SII_6_1_MOP == 1
local average_amt_control_ur: di %9.2fc `r(mean)'
quietly summarize mop_kg_hectare_ml if SII_4_1 == 1 & treatment == 0 & SII_6_1_MOP == 1
local average_amt_control_ir: di %9.2fc `r(mean)'

quietly summarize mop_kg_hectare_ml if SII_4_1 == 0 & treatment == 1 & SII_6_1_MOP == 1
local average_amt_treat_ur: di %9.2fc `r(mean)'
quietly summarize mop_kg_hectare_ml if SII_4_1 == 1 & treatment == 1 & SII_6_1_MOP == 1
local average_amt_treat_ir: di %9.2fc `r(mean)'

* Write to the handle 
file w handle "MOP: Total unirrigated & `average_rec_ur_bl' & $`share_apply_ur_control_bl'^*$ & $`share_apply_ur_treat_bl'^*$ & $`average_amt_control_ur_bl'^*$ & $`average_amt_treat_ur_bl'^*$ & `average_rec_ur' & `share_apply_ur_control' & `share_apply_ur_treat' & `average_amt_control_ur' & `average_amt_treat_ur' \\ " _n
file w handle "MOP: Total irrigated & `average_rec_ir_bl' & $`share_apply_ir_control_bl'^*$ & $`share_apply_ir_treat_bl'^*$ & $`average_amt_control_ir_bl'^*$ & $`average_amt_treat_ir_bl'^*$ & `average_rec_ir' & `share_apply_ir_control' & `share_apply_ir_treat' & `average_amt_control_ir' & `average_amt_treat_ir' \\[1em] " _n

/////////////
// Zinc 
/////////////

generate zinc_sulphate_bd_rec_ur = 0 // Not recommended for non-irrigated plots
generate zinc_sulphate_total_rec_ur = 0 

* Basal dose 

// Begin with the amount applied for the 2017 season 
quietly summarize used_zinc_bl if irrigation_bl == 0 & treatment == 0
local share_apply_ur_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_zinc_bl if irrigation_bl == 0 & treatment == 1
local share_apply_ur_treat_bl: di %9.2fc `r(mean)' 

quietly summarize used_zinc_bl if irrigation_bl == 1 & treatment == 0
local share_apply_ir_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_zinc_bl if irrigation_bl == 1 & treatment == 1
local share_apply_ir_treat_bl: di %9.2fc `r(mean)' 

summarize zinc_sulphate_bd_rec_ir if irrigation_bl == 1 & used_zinc_bl == 1  
local average_rec_ir_bl: di %9.2fc `r(mean)'

summarize zinc_sulphate_bd_rec_ur if irrigation_bl == 0 & used_zinc_bl == 1  
local average_rec_ur_bl: di %9.2fc `r(mean)'

generate zinc_kg_ha_d1_bl = zinc_kg_dose_1_vBL/merged_cotton_area  // Use the endline calculated cotton area since it's more precise, and for fair comparisons 

quietly summarize zinc_kg_ha_d1_bl if treatment == 0 & irrigation_bl == 0 & used_zinc_bl == 1
local average_amt_control_ur_bl: di %9.2fc `r(mean)'

quietly summarize zinc_kg_ha_d1_bl if treatment == 0 & irrigation_bl == 1 & used_zinc_bl == 1
local average_amt_control_ir_bl: di %9.2fc `r(mean)'

quietly summarize zinc_kg_ha_d1_bl if treatment == 1 & irrigation_bl == 0 & used_zinc_bl == 1
local average_amt_treat_ur_bl: di %9.2fc `r(mean)'

quietly summarize zinc_kg_ha_d1_bl if treatment == 1 & irrigation_bl == 1 & used_zinc_bl == 1
local average_amt_treat_ir_bl: di %9.2fc `r(mean)'

// Now turn to 2018 season
quietly summarize SII_6_1_ZINC if SII_4_1 == 0 & treatment == 0
local share_apply_ur_control: di %9.2fc `r(mean)' 
quietly summarize SII_6_1_ZINC if SII_4_1 == 1 & treatment == 0
local share_apply_ir_control: di %9.2fc `r(mean)' 

quietly summarize SII_6_1_ZINC if SII_4_1 == 0 & treatment == 1
local share_apply_ur_treat: di %9.2fc `r(mean)' 
quietly summarize SII_6_1_ZINC if SII_4_1 == 1 & treatment == 1
local share_apply_ir_treat: di %9.2fc `r(mean)' 

quietly summarize zinc_sulphate_bd_rec_ur if SII_4_1 == 0 & SII_6_1_ZINC == 1 
local average_rec_ur: di %9.2fc `r(mean)'

quietly summarize zinc_sulphate_bd_rec_ir if SII_4_1 == 1 & SII_6_1_ZINC == 1 
local average_rec_ir: di %9.2fc `r(mean)'

quietly summarize ZINC_kg_hectare_bd if SII_4_1 == 0 & treatment == 0 & SII_6_1_ZINC == 1
local average_amt_control_ur: di %9.2fc `r(mean)'
quietly summarize ZINC_kg_hectare_bd if SII_4_1 == 1 & treatment == 0 & SII_6_1_ZINC == 1
local average_amt_control_ir: di %9.2fc `r(mean)'

quietly summarize ZINC_kg_hectare_bd if SII_4_1 == 0 & treatment == 1 & SII_6_1_ZINC == 1
local average_amt_treat_ur: di %9.2fc `r(mean)'
quietly summarize ZINC_kg_hectare_bd if SII_4_1 == 1 & treatment == 1 & SII_6_1_ZINC == 1
local average_amt_treat_ir: di %9.2fc `r(mean)'

* Write to the handle 
file w handle "Zinc: Basal dose unirrigated & `average_rec_ur_bl' & $`share_apply_ur_control_bl'^*$ & $`share_apply_ur_treat_bl'^*$ & $`average_amt_control_ur_bl'^*$ & $`average_amt_treat_ur_bl'^*$ & 0.00 & `share_apply_ur_control' & `share_apply_ur_treat' & `average_amt_control_ur' & `average_amt_treat_ur' \\ " _n
file w handle "Zinc: Basal dose irrigated & `average_rec_ir_bl' & $`share_apply_ir_control_bl'^*$ & $`share_apply_ir_treat_bl'^*$ & $`average_amt_control_ir_bl'^*$ & $`average_amt_treat_ir_bl'^*$ & `average_rec_ir' & `share_apply_ir_control' & `share_apply_ir_treat' & `average_amt_control_ir' & `average_amt_treat_ir' \\ " _n

* Total applied 

// Begin with the amount applied for the 2017 season 
quietly summarize used_zinc_bl if irrigation_bl == 0 & treatment == 0
local share_apply_ur_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_zinc_bl if irrigation_bl == 0 & treatment == 1
local share_apply_ur_treat_bl: di %9.2fc `r(mean)' 

quietly summarize used_zinc_bl if irrigation_bl == 1 & treatment == 0
local share_apply_ir_control_bl: di %9.2fc `r(mean)' 
quietly summarize used_zinc_bl if irrigation_bl == 1 & treatment == 1
local share_apply_ir_treat_bl: di %9.2fc `r(mean)' 

summarize zinc_sulphate_total_rec_ir if irrigation_bl == 1 & used_zinc_bl == 1  
local average_rec_ir_bl: di %9.2fc `r(mean)'

summarize zinc_sulphate_total_rec_ur if irrigation_bl == 0 & used_zinc_bl == 1  
local average_rec_ur_bl: di %9.2fc `r(mean)'

generate zinc_kg_ha = zinc_kg_vBL/merged_cotton_area  // Use the endline calculated cotton area since it's more precise, and for fair comparisons 

quietly summarize zinc_kg_ha if treatment == 0 & irrigation_bl == 0 & used_zinc_bl == 1
local average_amt_control_ur_bl: di %9.2fc `r(mean)'

quietly summarize zinc_kg_ha if treatment == 0 & irrigation_bl == 1 & used_zinc_bl == 1
local average_amt_control_ir_bl: di %9.2fc `r(mean)'

quietly summarize zinc_kg_ha if treatment == 1 & irrigation_bl == 0 & used_zinc_bl == 1
local average_amt_treat_ur_bl: di %9.2fc `r(mean)'

quietly summarize zinc_kg_ha if treatment == 1 & irrigation_bl == 1 & used_zinc_bl == 1
local average_amt_treat_ir_bl: di %9.2fc `r(mean)'

// Now turn to 2018 season
quietly summarize used_zinc if irrigation_ml == 0 & treatment == 0
local share_apply_ur_control: di %9.2fc `r(mean)' 
quietly summarize used_zinc if irrigation_ml == 1 & treatment == 0
local share_apply_ir_control: di %9.2fc `r(mean)' 

quietly summarize used_zinc if irrigation_ml == 0 & treatment == 1
local share_apply_ur_treat: di %9.2fc `r(mean)' 
quietly summarize used_zinc if irrigation_ml == 1 & treatment == 1
local share_apply_ir_treat: di %9.2fc `r(mean)' 

quietly summarize zinc_sulphate_total_rec_ur if irrigation_ml == 0 & used_zinc == 1 
local average_rec_ur: di %9.2fc `r(mean)'

quietly summarize zinc_sulphate_total_rec_ir if irrigation_ml == 1 & used_zinc == 1 
local average_rec_ir: di %9.2fc `r(mean)'

quietly summarize zinc_kg_hectare_ml if irrigation_ml == 0 & treatment == 0 & used_zinc == 1
local average_amt_control_ur: di %9.2fc `r(mean)'
quietly summarize zinc_kg_hectare_ml if irrigation_ml == 1 & treatment == 0 & used_zinc == 1
local average_amt_control_ir: di %9.2fc `r(mean)'

quietly summarize zinc_kg_hectare_ml if irrigation_ml == 0 & treatment == 1 & used_zinc == 1
local average_amt_treat_ur: di %9.2fc `r(mean)'
quietly summarize zinc_kg_hectare_ml if irrigation_ml == 1 & treatment == 1 & used_zinc == 1
local average_amt_treat_ir: di %9.2fc `r(mean)'

* Write to the handle 
file w handle "Zinc: Total unirrigated & `average_rec_ur_bl' & $`share_apply_ur_control_bl'^*$ & $`share_apply_ur_treat_bl'^*$ & $`average_amt_control_ur_bl'^*$ & $`average_amt_treat_ur_bl'^*$ & `average_rec_ur' & `share_apply_ur_control' & `share_apply_ur_treat' & `average_amt_control_ur' & `average_amt_treat_ur' \\ " _n
file w handle "Zinc: Total irrigated & `average_rec_ir_bl' & $`share_apply_ir_control_bl'^*$ & $`share_apply_ir_treat_bl'^*$ & $`average_amt_control_ir_bl'^*$ & $`average_amt_treat_ir_bl'^*$ & `average_rec_ir' & `share_apply_ir_control' & `share_apply_ir_treat' & `average_amt_control_ir' & `average_amt_treat_ir' \\ " _n



file close handle
 
