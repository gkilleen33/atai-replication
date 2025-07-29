drop _all
set more off
capture log close
set logtype text

/****************************************************************************
PROJECT: ATAI YEAR 2
DESCRIPTION: ANALYSIS FOR PAPER
ORGANIZATION: PAD
AUTHOR: GRADY KILLEEN
CREATED: 03/20/2020
****************************************************************************/

//Set directory: insert the path to the repository root folder 

global user INSERT_PATH_TO_PARENT_FOLDER
set python_exec INSERT_PATH_TO_PYTHON

cd "$user"
capture mkdir "data/nosync/"  // Stores generated data that's not tracked by git (speeds up subsequent runs)

global merged_data "data/ATAI_Endline_2019_Clean_Merged.dta"
global rainfall_data "data/rainfall.dta"
global final_data "`c(tmpdir)'/final_data.dta"
global final_data_with_attriters "`c(tmpdir)'/final_data_with_attriters.dta"  //Keeps observations of farmers that didn't grow cotton for power calculations 

//The randomization inference in Table B3 is very computationally intensive. Set this toggle to true to skip this table if it already exists.
global skip_ri = "True"

//Program for creating graphs in batch or interactive mode, requires Stata 16, a Python installation, and the Python package cairosvg (pip install cairosvg)
capture program drop gexport
program define gexport
 syntax, file(string) 
 if "`c(mode)'" == "batch" {
graph export "`c(tmpdir)'/graph.svg", replace width(1000)
local tmp_path "`c(tmpdir)'/graph.svg"
python: from sfi import Macro
python: import cairosvg
python: cairosvg.svg2png(url=Macro.getLocal("tmp_path"), write_to=Macro.getLocal("file"))
 } 
 else {
 	graph export "`file'", width(1000) replace
 }
end

**********************************************************
* Prepare the data for analysis (remove attriters, generate common variables, convert units, etc.)
**********************************************************

do do/data_preparation.do
save "$final_data", replace 
   
**********************************************************
* Main tables 
**********************************************************

//Table 1 - Summary Statistics, Baseline 
do do/table1.do 

//Table 2 - Treatment effect on knowledge and KT call engagement
do do/table2.do 

//Table 3 - Fertilizer application 
do do/table3.do 

//Table 4 - Fertilizer gap and yields 
do do/table4.do 

//Table 5 - Satellite VIs vs farmer-reported yields 
do do/table5.do 
 
//Table 6 - Treatment effect on yields: satellite vs survey data 
do do/table6.do 

//Table 7 - Powers gains from satellite imagery
* This is now calculated in python/bootstrap-power-calculations.py
** Run this immediately after this do file so it can pull data from the temp directory 

//Table 8 - OLS vs 2SLS calibration (comes earlier in the paper, but added later)
do do/table8.do 

//Table 9 - Fertilizer use by types
do do/table9.do  

**********************************************************
* Appendix A tables 
**********************************************************

//Table A1 - Survey completion rates 
do do/table-a1.do 

//Table A2 - Attrition 
do do/table-a2.do 

//Table A3 - Listening rates of treatment calls 
do do/table-a3.do

//Table A4 - Basal fertilizer application (moved to table9.do)
// do do/table-a4.do

//Table A5 - Fertilizer application and recommendations for 2017, 2018 (replaces earlier table A5)
do do/table-a5.do

//Table A6 - Detailed table 4 (fertilizer application and yields) for full sample (moved to table9.do)
//do do/table-a6.do

//Table A7 - Share of plot on which fertilizer was applied 
do do/table-a7.do

//Table A8 - Basal and full season fertilizer application by irrigation
do do/table-a8.do

//Table A9 - Fertilizer gap and yields by irrigation 
do do/table-a9.do

//Table A10 - Revenue 
do do/table-a10.do

**********************************************************
* Appendinx B tables (satellite yields)
**********************************************************
//Table B1 - Satellite data availability by pass 
do do/table-b1.do

//Table B2 - Satellite VIs (not generated in Stata)

//Table B3 - small vs large plots 
capture confirm file "tables/t-b3/below_median.tex"
if _rc {
	do do/table-b3.do
}
else if "$skip_ri" != "True" {
	do do/table-b3.do
}

//Table B4 - Irrigation 
do do/table-b4.do

**********************************************************
* Figures
**********************************************************

//Figure 1 - Sample satellite imagery and NDVI
* Produced in QGIS

//Figure 2 - Applied minus recommended fertilizer, basal 
do do/figure2.do 

//Figure 3 - Applied minus recommended fertilizer, total 
do do/figure3.do 

//Figure 4 - Yields 
do do/figure4.do 

//Figure 5 - Rainfall 
do do/figure5.do 

//Figure 6 - Farmer-reported yields vs satellite vegetation indices 
do do/figure6.do 

//Figure 7 - Confidence intervals with farmer-reported and satellite data 
do do/figure7.do 

//Figure 8 - Farmer-reported yields vs satellite with OLS, IV calibration 
* Comes before figure 7 in the paper, but added later so listed here
do do/figure8.do 
