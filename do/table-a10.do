use "$final_data", clear 

eststo clear 

// Create a t-a9 folder to store outputs if it doesn't exist 
capture mkdir "tables/t-a10/"

* Generate a revenue minus fertilizer costs variable before winsorizing inputs 
egen expected_total_revenue = rowtotal(expected_storage_revenue total_sale_revenue), missing
generate revenue_minus_fertilizer = expected_total_revenue - fertilizers_spent 

winsor2 cotton_sold_kg, replace cuts(0 99)

eststo: regress cotton_sold_kg i.treatment i.block_id, robust
summarize cotton_sold_kg if treatment == 0, meanonly
local varMean: di %3.2f `r(mean)'
estadd scalar depMean = `varMean'

winsor2 cotton_stored_kg, replace cuts(0 99)

eststo: regress cotton_stored_kg i.treatment i.block_id, robust
summarize cotton_stored_kg if treatment == 0, meanonly
local varMean: di %3.2f `r(mean)'
estadd scalar depMean = `varMean'

winsor2 total_sale_revenue, replace cuts(0 99)

eststo: regress total_sale_revenue i.treatment i.block_id, robust
summarize total_sale_revenue if treatment == 0, meanonly
local varMean: di %3.2f `r(mean)'
estadd scalar depMean = `varMean'

winsor2 expected_total_revenue, replace cuts(0 99)

eststo: regress expected_total_revenue i.treatment i.block_id, robust
summarize expected_total_revenue if treatment == 0, meanonly
local varMean: di %3.2f `r(mean)'
estadd scalar depMean = `varMean' 

generate average_sale_price = total_sale_revenue/cotton_sold_kg

eststo: regress average_sale_price i.treatment i.block_id, robust
summarize average_sale_price if treatment == 0, meanonly
local varMean: di %3.2f `r(mean)'
estadd scalar depMean = `varMean'

winsor2 revenue_minus_fertilizer, replace cuts(0 99)

eststo: regress revenue_minus_fertilizer i.treatment i.block_id, robust
summarize revenue_minus_fertilizer if treatment == 0, meanonly
local varMean: di %3.2f `r(mean)'
estadd scalar depMean = `varMean' 

esttab using "tables/t-a10/sales.tex", replace frag se r2 not label ///
tex star(* 0.10 ** 0.05 *** 0.01) ///
noomitted nobaselevels noconstant ///
scalars("depMean Control mean of dependent variable") indicate("Block FE = *block*") ///
mtitles("Sold (kg)" "Stored (kg)" "Sales Revenue (Rs)" "\makecell[c]{Expected Total \\ Revenue (Rs)}" "\makecell[c]{Av. Price \\ (Rs/kg)}" "\makecell[c]{Revenue minus \\ fertilizer costs (Rs)}")

