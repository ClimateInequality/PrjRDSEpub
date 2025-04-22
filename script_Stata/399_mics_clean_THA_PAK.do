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

global today "20230720"
// log using "$dir_log\301_mics_child_id_$today.log", replace

efolder cherry, cd("$dir_tempdata")
cd "$dir_program"



/*******************************************************************************

* MODULE 3. Clean THA and PAK 

*******************************************************************************/
import delimited "$dir_data\data_to_est\child_lifecycle_loc_date_A_full_yz", case(preserve) clear


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
	order RDSE_loc_id countryfile HH1 HH2 LN ISO_alpha_3, first 

end 

clean_THA_PAK

export delimited "$dir_data\data_to_est\child_lifecycle_loc_date_A_full_yz.csv", nolabel replace 



/*



*** get parents lineno
u "$dir_tempdata\parent_edu_age", clear
drop melevel felevel hhmemberage
sa "$dir_tempdata\parent_lineno", replace

u "$dir_tempdata\BGD2019_fs_merge", clear
duplicates report HH1 HH2 LN
merge 1:1 HH1 HH2 LN using "$dir_tempdata\parent_lineno"

drop if _merge != 3
drop _merge 

sa "$dir_tempdata\BGD2019_fs_merge", replace 



*** mother age and education 
u "$dir_tempdata\parent_edu_age", clear
drop motherlineno fatherlineno felevel
rename LN motherlineno
rename hhmemberage motherage 
la var motherage "Mother age"
rename melevel motheredulevel
sa "$dir_tempdata\mother", replace

u "$dir_tempdata\BGD2019_fs_merge", clear
duplicates report HH1 HH2 motherlineno
merge 1:1 HH1 HH2 motherlineno using "$dir_tempdata\mother"

drop if _merge != 3
drop _merge

sa "$dir_tempdata\BGD2019_fs_merge", replace 



*** father age and education 
u "$dir_tempdata\parent_edu_age", clear
drop motherlineno fatherlineno melevel
rename LN fatherlineno
rename hhmemberage fatherage 
la var fatherage "Father age"
rename felevel fatheredulevel
sa "$dir_tempdata\father", replace

u "$dir_tempdata\BGD2019_fs_merge", clear
duplicates report HH1 HH2 fatherlineno
merge 1:1 HH1 HH2 fatherlineno using "$dir_tempdata\father"

drop if _merge == 2
drop _merge

sa "$dir_tempdata\BGD2019_fs_merge", replace 



order mother*, last
order father*, last
order urban geocode* wscore-PSU, last


// duplicates report HH1 HH2
// duplicates report HH1 HH2 motherlineno

sa "$dir_tempdata\BGD2019_fs_merge", replace 


*/














********************************************************************************
* delete temparory data files 
********************************************************************************

// shell rd "$dir_tempdata\cherry" /s /q
// shell rm -r "$dir_tempdata\cherry" /s /q

* delete all files in folder "cherry"
cd "$dir_tempdata"
shell rd "cherry" /s /q
cd "$dir_program"

* delete folder "cherry"
rmdir "$dir_tempdata\cherry"


