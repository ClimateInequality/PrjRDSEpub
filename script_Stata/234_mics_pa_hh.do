/* Project: PIRE 
Task: browse MICS6 data

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

global today "20231017"

log using "$dir_log\234_mics_hh_$today.log", replace



efolder apple, cd("$dir_tempdata")
cd "$dir_program"

********************************************************************************
* TASK: MICS household/parental information file 
********************************************************************************

/*
https://github.com/ClimateInequality/PrjRDSE/issues/4
*/


do 234_mics_pa_age
do 234_mics_pa_edu
do 234_mics_pa_live
do 234_mics_hh_wealth

u "$dir_tempdata\234_mics_pa_age", clear
merge 1:1 countryfile HH1 HH2 LN using "$dir_tempdata\234_mics_pa_edu"
drop _merge 
merge 1:1 countryfile HH1 HH2 LN using "$dir_tempdata\234_mics_pa_live"
drop _merge 
merge 1:1 countryfile HH1 HH2 LN using "$dir_tempdata\234_mics_hh_wealth"
drop _merge 

sort countryfile HH1 HH2 LN ISO_alpha_3
order RDSE_loc_id countryfile HH1 HH2 LN moLN faLN ISO_alpha_3, first 

// sa "$dir_data\\data_intermediate\\234_mics_pa_hh", replace

// erase "$dir_tempdata\234_mics_pa_age.dta"
// erase "$dir_tempdata\234_mics_pa_edu.dta"
// erase "$dir_tempdata\234_mics_pa_live.dta"
// erase "$dir_tempdata\234_mics_hh_wealth.dta"




/*******************************************************************************

* Clean THA and PAK 

*******************************************************************************/

cap program drop clean_THA_PAK
program define clean_THA_PAK
		
	/*
	u "$dir_data\id_key_file\mics_loc_id", clear

	levelsof RDSE_loc_id if countryfile == "THA2019" & adm_1_loc == ""
	// 233 234 235 236

	levelsof RDSE_loc_id if countryfile == "PKB2019"
	// 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117
	*/

	// u "$dir_data\data_intermediate\230_mics_child", clear
	drop if inlist(RDSE_loc_id, 233, 234, 235, 236)
	count if ISO_alpha_3 == "THA"
	// 9608

	drop if countryfile == "PKB2019"
	// levelsof RDSE_loc_id if countryfile == "PKB2019"
	// 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117

	levelsof RDSE_loc_id if countryfile == "PKB2019", local(levels)
	foreach l of local levels {
		drop if RDSE_loc_id == `l'
	}

	sort countryfile HH1 HH2 LN ISO_alpha_3
	order RDSE_loc_id countryfile HH1 HH2 LN moLN faLN ISO_alpha_3, first 

end 

clean_THA_PAK


sa "$dir_data\\data_intermediate\234_mics_pa_hh_WithRawVar", replace

export delimited using "$dir_data\\data_intermediate\234_mics_pa_hh_WithRawVar.csv", nolabel replace
// export delimited using "$dir_main\data_pivot_table\234_mics_pa_hh.csv", nolabel replace







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








