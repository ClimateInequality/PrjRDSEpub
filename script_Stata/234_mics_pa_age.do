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

global today "20230729"

log using "$dir_log\234_mics_pa_age_$today.log", replace



efolder apple, cd("$dir_tempdata")
cd "$dir_program"

********************************************************************************
* TASK: MICS household/parental information file 
********************************************************************************

/*
https://github.com/ClimateInequality/PrjRDSE/issues/4
*/


/*******************************************************************************

* MODULE 2. Mother age, father age

***************************************************************************************************************/
/* In hl.dta, each row is one member in household. 
Age variable is assigned to each member. Use mother's linenumber in mics_child_id.dta file and linenumber variable in hl.dta file to merge, to fine information for mother. Do the same for father. 

	fre HL5Y HL5M // birth year and month	
	fre HL6 HL11 ED2A ED3 ED7 schage // age 
// 	count if HL6 != ED2A
	
	HL6 - most relevant variable - USE THIS ONE 
	HL11 - member age 0-17, YES or NO
	ED2A - age - should be identical to HL6 
	ED3 - member age above 3, YES or NO
	ED7 - member age 3-24, YES or NO
	schage - Age at beginning of school year
*/



/*******************************************************************************

* MODULE 2.1. Mother birth year, birth month, age 

*******************************************************************************/

cap program drop pabirth
program define pabirth

args countryfile 

	u "$dir_rawdata\mics\\`countryfile'_hl", clear
	gen countryfile = "`countryfile'", before(HH1)
	
	fre HL5Y HL5M // birth year and month
	fre HL6 // age 
	count if HL6 != ED2A

	keep countryfile HH1 HH2 HL1 HL5Y HL5M HL6 
	
	* find MOTHER birth year, birth month, age
	rename HL1 moLN
	merge 1:1 countryfile HH1 HH2 moLN using "$dir_data\id_key_file\mics_child_id"
	keep if _merge == 3
	drop _merge 
	
	clonevar mo_birthm_raw_HL5M = HL5M // raw variable
	decode HL5M, gen(mo_birthm_raw_decode) // raw variable string label 
	clonevar mo_birthm = HL5M
	la var mo_birthm "Mother birth month"

	clonevar mo_birthy_raw_HL5Y = HL5Y // raw variable
	decode HL5Y, gen(mo_birthy_raw_decode) // raw variable string label 
	clonevar mo_birthy = HL5Y
	la var mo_birthy "Mother birth year"

	clonevar mo_age_raw_HL6 = HL6 // raw variable
	decode HL6, gen(mo_age_raw_decode) // raw variable string label 
	clonevar mo_age = HL6
	replace mo_age = . if mo_age == 98 // 98 DK
	la var mo_age "Mother age"
	
	replace mo_birthy = . if mo_birthy_raw_HL5Y >= 9990	
	replace mo_birthm = . if mo_birthm_raw_HL5M >= 90
	
	keep countryfile HH1 HH2 moLN mo_* 

	sa "$dir_tempdata\apple\\`countryfile'", replace

end 


foreach i in ///
"BGD2019" ///
"KGZ2018" ///
"MNG2018" ///
"NPL2019" ///
"PKB2019" ///
"PKK2019" ///
"PKP2017" ///
"PKS2018" ///
"T172019" ///
"THA2019" ///
"TKM2019" ///
{
	pabirth `i'
}



/* Append data and merge with kid identifier file 
********************************************************/
u "$dir_tempdata\apple\BGD2019", clear

foreach i in ///
"KGZ2018" ///
"MNG2018" ///
"NPL2019" ///
"PKB2019" ///
"PKK2019" ///
"PKP2017" ///
"PKS2018" ///
"T172019" ///
"THA2019" ///
"TKM2019" ///
{
	append using "$dir_tempdata\apple\\`i'"
}

duplicates report countryfile HH1 HH2 moLN


merge 1:1 countryfile HH1 HH2 moLN using "$dir_data\id_key_file\mics_child_id"
// keep if _merge == 3
drop _merge
order RDSE_loc_id ISO_alpha_3 countryfile HH1 HH2 LN moLN faLN, first

sa "$dir_tempdata\234_mics_pa_hh_2_1", replace



/*******************************************************************************

* MODULE 2.2. Father birth year, birth month, age 

*******************************************************************************/

cap program drop pabirth
program define pabirth

args countryfile 

	u "$dir_rawdata\mics\\`countryfile'_hl", clear
	gen countryfile = "`countryfile'", before(HH1)
	
	fre HL5Y HL5M // birth year and month
	fre HL6 // age 
	count if HL6 != ED2A

	keep countryfile HH1 HH2 HL1 HL5Y HL5M HL6 
	
	* find FATHER birth year, birth month, age
	rename HL1 faLN
	merge 1:1 countryfile HH1 HH2 faLN using "$dir_data\id_key_file\mics_child_id"
	keep if _merge == 3
	drop _merge 
	
	clonevar fa_birthm_raw_HL5M = HL5M // raw variable
	decode HL5M, gen(fa_birthm_raw_decode) // raw variable string label 
	clonevar fa_birthm = HL5M
	la var fa_birthm "Father birth month"

	clonevar fa_birthy_raw_HL5Y = HL5Y // raw variable
	decode HL5Y, gen(fa_birthy_raw_decode) // raw variable string label 
	clonevar fa_birthy = HL5Y
	la var fa_birthy "Father birth year"

	clonevar fa_age_raw_HL6 = HL6 // raw variable
	decode HL6, gen(fa_age_raw_decode) // raw variable string label 
	clonevar fa_age = HL6
	replace fa_age = . if fa_age == 98 // 98 DK
	la var fa_age "Father age"

	fre HL5Y HL5M // birth year and month
	fre HL6 // age 
	
	replace fa_birthy = . if fa_birthy_raw_HL5Y >= 9990	
	replace fa_birthm = . if fa_birthm_raw_HL5M >= 90
	
	keep countryfile HH1 HH2 faLN fa_* 

	sa "$dir_tempdata\apple\\`countryfile'", replace

end 


foreach i in ///
"BGD2019" ///
"KGZ2018" ///
"MNG2018" ///
"NPL2019" ///
"PKB2019" ///
"PKK2019" ///
"PKP2017" ///
"PKS2018" ///
"T172019" ///
"THA2019" ///
"TKM2019" ///
{
	pabirth `i'
}



/* Append data and merge with kid identifier file 
********************************************************/
u "$dir_tempdata\apple\BGD2019", clear

foreach i in ///
"KGZ2018" ///
"MNG2018" ///
"NPL2019" ///
"PKB2019" ///
"PKK2019" ///
"PKP2017" ///
"PKS2018" ///
"T172019" ///
"THA2019" ///
"TKM2019" ///
{
	append using "$dir_tempdata\apple\\`i'"
}

duplicates report countryfile HH1 HH2 faLN


merge 1:1 countryfile HH1 HH2 faLN using "$dir_data\id_key_file\mics_child_id"
// keep if _merge == 3
drop _merge
order RDSE_loc_id ISO_alpha_3 countryfile HH1 HH2 LN moLN faLN, first

sa "$dir_tempdata\234_mics_pa_hh_2_2", replace



/* MODULE 2.3. Merge father and mother birth info
*******************************************************************************/

u "$dir_tempdata\234_mics_pa_hh_2_1", clear
merge 1:1 countryfile HH1 HH2 LN using "$dir_tempdata\234_mics_pa_hh_2_2"
drop _merge 

sa "$dir_tempdata\234_mics_pa_age", replace
erase "$dir_tempdata\234_mics_pa_hh_2_1.dta"
erase "$dir_tempdata\234_mics_pa_hh_2_2.dta"















