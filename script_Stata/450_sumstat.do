/* Project: PIRE 

Author: Yujie Zhang 
Date: 20230204

*/

cls
clear all
pause off
set more off
cap log close
macro drop _all
cap set maxvar 50000



********************************************************************************
* set up directory
********************************************************************************

local main_yujie_offline "0"

local current_host "`c(hostname)'"

if "`locals_included'" == "" {
	// Very important to use -include- and not -do- or -run- here, as -include- will carry over the local macros generated within an outside-file, but -do- and -run- will delete local macros once the outside-file is finished running. 
	include _locals.do
}

global today "20240307"

log using "$dir_log\450_sumstat_$today.log", replace



efolder apple, cd("$dir_tempdata")
cd "$dir_program"

efolder data_to_est, cd("$dir_data")
cd "$dir_program"


********************************************************************************
* TASK: Create summary statistics 
********************************************************************************

u "$dir_data\data_to_est\\est_mics_child", clear


/*******************************************************************************

* MODULE 1. summary 

*******************************************************************************/

global var_edu "E_ever E_t_1 E_t A_max A_t_1 A_t P_t_1 R_t S_read_bi S_math_bi read_score_total math_score_total O_sch_close_nat_bi O_sch_tea_abs_bi sch_close_nat sch_tea_abs" 

cap program drop sumstat 
program define sumstat

args fileanme 

	est clear  // clear the stored estimates
	estpost tabstat ///
	$var_edu ///
	, c(stat) stat(mean sd min max n) 

	ereturn list // list the stored locals

	esttab using "$dir_table\\`fileanme'.tex", replace ////
	cells("mean(fmt(%6.2fc)) sd(fmt(%6.2fc)) min max count(fmt(%6.0fc))") nonumber ///
	nomtitle nonote noobs label booktabs ///
	collabels("Mean" "SD" "Min" "Max" "N")  ///
	// title("Table 1 with title generated in Stata \label{table1stata}")

end

sumstat sum_all_var_edu



// global var_other "kid_age kid_female mo_age fa_age mo_edu_everschool mo_edu_yoe_highest fa_edu_everschool fa_edu_yoe_highest child_live_with_pa hh_wscore" 


global var_other "kid_age kid_female mo_age fa_age mo_*_E_ever mo_*_A_secondary fa_*_E_ever fa_*_A_secondary mo_inHH fa_inHH" 


cap program drop sumstat 
program define sumstat

args fileanme 

	est clear  // clear the stored estimates
	estpost tabstat ///
	$var_other ///
	, c(stat) stat(mean sd min max n) 

	ereturn list // list the stored locals

	esttab using "$dir_table\\`fileanme'.tex", replace ////
	cells("mean(fmt(%6.2fc)) sd(fmt(%6.2fc)) min max count(fmt(%6.0fc))") nonumber ///
	nomtitle nonote noobs label booktabs ///
	collabels("Mean" "SD" "Min" "Max" "N")  ///
	// title("Table 1 with title generated in Stata \label{table1stata}")

end

sumstat sum_all_var_other

global var_dis "dis_A_DB_m1to1 dis_A_DB_m2to12 dis_A_DB_m13to24 dis_A_DB_m25to120 dis_A_DB_m121to240 dis_A_DB_g9to24 dis_A_DB_g9to0 dis_A_DB_g60to72 dis_A_DB_g25_to_m25 dis_A_DB_g1_to_m25"

cap program drop sumstat 
program define sumstat

args fileanme 

	est clear  // clear the stored estimates
	estpost tabstat ///
	$var_dis ///
	, c(stat) stat(mean sd min max n) 

	ereturn list // list the stored locals

	esttab using "$dir_table\\`fileanme'.tex", replace ////
	cells("mean(fmt(%6.2fc)) sd(fmt(%6.2fc)) min max count(fmt(%6.0fc))") nonumber ///
	nomtitle nonote noobs label booktabs ///
	collabels("Mean" "SD" "Min" "Max" "N")  ///
	// title("Table 1 with title generated in Stata \label{table1stata}")

end

sumstat sum_all_var_dis




************ by country *************
global var_edu "E_t E_t_1 A_max P_t_1 R_t read_score_total math_score_total sch_close_nat sch_tea_abs" 

cap program drop sumstat 
program define sumstat

args fileanme country 

	est clear  // clear the stored estimates
	estpost tabstat ///
	$var_edu if ISO_alpha_3 == "`country'" ///
	, c(stat) stat(mean sd min max n) 

	ereturn list // list the stored locals

	esttab using "$dir_table\\`fileanme'_`country'.tex", replace ////
	cells("mean(fmt(%6.2fc)) sd(fmt(%6.2fc)) min max count(fmt(%6.0fc))") nonumber ///
	nomtitle nonote noobs label booktabs ///
	collabels("Mean" "SD" "Min" "Max" "N")  ///
	// title("Table 1 with title generated in Stata \label{table1stata}")

end

// levelsof ISO_alpha_3, local(levels)
foreach l in BGD KGZ MNG NPL PAK THA TKM {
	sumstat sum_all_var_edu `l'
}


cap program drop sumstat 
program define sumstat

args fileanme country 

	est clear // clear the stored estimates
	eststo BGD: estpost summarize ///
	$var_edu if ISO_alpha_3 == "BGD"
	eststo KGZ: estpost summarize ///
	$var_edu if ISO_alpha_3 == "KGZ"
	eststo MNG: estpost summarize ///
	$var_edu if ISO_alpha_3 == "MNG"
	eststo NPL: estpost summarize ///
	$var_edu if ISO_alpha_3 == "NPL"
	eststo PAK: estpost summarize ///
	$var_edu if ISO_alpha_3 == "PAK"
	eststo THA: estpost summarize ///
	$var_edu if ISO_alpha_3 == "THA"
	eststo TKM: estpost summarize ///
	$var_edu if ISO_alpha_3 == "TKM"

	ereturn list // list the stored locals

	esttab using "$dir_table\\`fileanme'_BY_COUNTRY.tex", replace ////
	cells("mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0))") ///
	label ///
	collabels("Mean" "SD")  ///
	// title("Table 1 with title generated in Stata \label{table1stata}")

end

sumstat sum_all_var_edu




global var_other "kid_age kid_female mo_age fa_age mo_*_E_ever mo_*_A_secondary fa_*_E_ever fa_*_A_secondary mo_inHH fa_inHH" 


cap program drop sumstat 
program define sumstat

args fileanme country 

	est clear  // clear the stored estimates
	estpost tabstat ///
	$var_other if ISO_alpha_3 == "`country'" ///
	, c(stat) stat(mean sd min max n) 

	ereturn list // list the stored locals

	esttab using "$dir_table\\`fileanme'_`country'.tex", replace ////
	cells("mean(fmt(%6.2fc)) sd(fmt(%6.2fc)) min max count(fmt(%6.0fc))") nonumber ///
	nomtitle nonote noobs label booktabs ///
	collabels("Mean" "SD" "Min" "Max" "N")  ///
	// title("Table 1 with title generated in Stata \label{table1stata}")

end

// levelsof ISO_alpha_3, local(levels)
foreach l in BGD KGZ MNG NPL PAK THA TKM {
	sumstat sum_all_var_other `l'
}



global var_dis "dis_A_DB_m1to1 dis_A_DB_m2to12 dis_A_DB_g9to24 dis_A_DB_g9to0 dis_A_DB_g60to72 dis_A_DB_g25_to_m25 dis_A_DB_g1_to_m25"

cap program drop sumstat 
program define sumstat

args fileanme country 

	est clear  // clear the stored estimates
	estpost tabstat ///
	$var_dis if ISO_alpha_3 == "`country'" ///
	, c(stat) stat(mean sd min max n) 

	ereturn list // list the stored locals

	esttab using "$dir_table\\`fileanme'_`country'.tex", replace ////
	cells("mean(fmt(%6.2fc)) sd(fmt(%6.2fc)) min max count(fmt(%6.0fc))") nonumber ///
	nomtitle nonote noobs label booktabs ///
	collabels("Mean" "SD" "Min" "Max" "N")  ///
	// title("Table 1 with title generated in Stata \label{table1stata}")

end

// levelsof ISO_alpha_3, local(levels)
foreach l in BGD KGZ MNG NPL PAK THA TKM {
	sumstat sum_all_var_dis `l'
}







********************************************************************************
* delete temparory data files 
********************************************************************************

// shell rd "$dir_tempdata\cherry" /s /q
// shell rm -r "$dir_tempdata\cherry" /s /q

* delete all files in folder "cherry"
cd "$dir_tempdata"
shell rd "apple" /s /q
cd "$dir_program"

* delete folder "cherry"
rmdir "$dir_tempdata\apple"








