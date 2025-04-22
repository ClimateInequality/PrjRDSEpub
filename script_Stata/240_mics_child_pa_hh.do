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

log using "$dir_log\240_mics_child_pa_hh_$today.log", replace



efolder apple, cd("$dir_tempdata")
cd "$dir_program"

efolder data_to_est, cd("$dir_data")
cd "$dir_program"


********************************************************************************
* TASK: MICS data file to estimate on 
********************************************************************************

/*
We constructed several files from MICS
230_mics_child: child attributes, educational outcomes group 1 (enrollment, attainment, test scores)
234_mics_pa_hh: parental and household information 
234_mics_sch_file2A: child interview date, educational outcomes group 2 (school closure, teacher truancy)

They are data_intermediate, as they include all raw variables as well as those imputed by ourselves. 
Now we want to provide cleaner, ready-to-estimate data file. 
*/

/*******************************************************************************

* MODULE 1. Merge files 

*******************************************************************************/

u "$dir_data\data_intermediate\\230_mics_child_WithRawVar", clear

merge 1:1 countryfile HH1 HH2 LN using "$dir_data\\data_intermediate\\234_mics_pa_hh_WithRawVar"
keep if _merge == 3
drop _merge 

merge 1:1 countryfile HH1 HH2 LN using "$dir_data\\data_intermediate\\234_mics_sch_file2A_WithRawVar"
keep if _merge == 3
drop _merge 

sort countryfile HH1 HH2 LN ISO_alpha_3
order RDSE_loc_id countryfile HH1 HH2 LN moLN faLN ISO_alpha_3, first 

sa "$dir_tempdata\\240_mics_child_pa_hh", replace

/*******************************************************************************

* MODULE 1.2. Convert date for NPL to Georgian calendar 

*******************************************************************************/

/*
This is related to MODULE 5 below. 

https://github.com/ClimateInequality/PrjRDSE/issues/18

In 241_mics_calendar.py, I use package nepali_datetime to convert date for NPL. 
Output file is 
dir_csv_file = f'{dir_tempdata}/241_mics_child_date_NPL.csv'

So, make sure before this step, run 241_mics_calendar.py first. 

TASK: replace variables regarding dates in old file with the new file. 
*/

import delimited using "$dir_tempdata\\241_mics_child_date_NPL.csv", case(preserve) clear
sa "$dir_tempdata\\241_mics_child_date_NPL", replace

u "$dir_tempdata\\240_mics_child_pa_hh", clear
keep if ISO_alpha_3 == "NPL"
drop kid_birthdate kid_birthm kid_birthy kid_int_d kid_int_m kid_int_y kid_int_date mo_birthm mo_birthy fa_birthm fa_birthy 

merge 1:1 countryfile HH1 HH2 LN using "$dir_tempdata\\241_mics_child_date_NPL"
drop _merge 

gen kid_birthdate = (kid_birthy - 1900)*12 + kid_birthm 

sa "$dir_tempdata\\240_mics_child_pa_hh_NPL", replace


u "$dir_tempdata\\240_mics_child_pa_hh", clear
drop if ISO_alpha_3 == "NPL"
append using "$dir_tempdata\\240_mics_child_pa_hh_NPL"

* Output
sa "$dir_tempdata\\240_mics_child_pa_hh", replace

// sa "$dir_data\data_to_est\\240_mics_child_pa_hh", replace
// export delimited using "$dir_data\data_to_est\\240_mics_child_pa_hh.csv", nolabel replace
// export delimited using "$dir_main\data_pivot_table\240_mics_child_pa_hh.csv", nolabel replace

erase "$dir_tempdata\\240_mics_child_pa_hh_NPL.dta"
erase "$dir_tempdata\\241_mics_child_date_NPL.dta"

/*******************************************************************************

* MODULE 1.3. Convert date for THA to Georgian calendar 

*******************************************************************************/

u "$dir_tempdata\\240_mics_child_pa_hh", clear

* Convert YEAR 
foreach i in kid_birthy kid_int_y mo_birthy fa_birthy {
	replace `i' = `i' - 543 if ISO_alpha_3 == "THA"
}

replace kid_birthdate = (kid_birthy - 1900)*12 + kid_birthm if ISO_alpha_3 == "THA"

/*******************************************************************************

* MODULE 1.4. For all child in all countries, recalculate the kid_birthdate (CMC) and kid_int_date

*******************************************************************************/

foreach i in kid_int_y kid_int_m kid_int_d {
	tostring `i', gen(`i'_tostr) 
	replace `i'_tostr = "0" + `i'_tostr if inrange(`i', 1, 9)
}
cap drop kid_int_date
gen kid_int_date = kid_int_y_tostr + kid_int_m_tostr + kid_int_d_tostr
destring kid_int_date, replace
drop *_tostr

sa "$dir_tempdata\\240_mics_child_pa_hh", replace



/*******************************************************************************

* MODULE 3. Clean THA and PAK 

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

/*******************************************************************************

* MODULE 2. A file with all var. 

*******************************************************************************/

sa "$dir_data\data_intermediate\\240_mics_child_pa_hh_WithRawVar", replace
export delimited using "$dir_data\data_intermediate\\240_mics_child_pa_hh_WithRawVar.csv", nolabel replace


/*******************************************************************************

* MODULE 3. A file with all var, but not raw var. 

*******************************************************************************/

drop *_raw*

sa "$dir_data\data_to_est\\240_mics_child_pa_hh", replace
export delimited using "$dir_data\data_to_est\\240_mics_child_pa_hh.csv", nolabel replace



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








