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

global today "20230709"
log using "$dir_log\301_mics_hh_id_$today.log", replace

efolder cherry, cd("$dir_tempdata")
cd "$dir_program"



********************************************************************************
* MICS data, create household identifiers 
********************************************************************************

/* 
https://github.com/ClimateInequality/PrjRDSE/issues/3
*/

*** BGD2019
u "$dir_rawdata\mics\BGD2019_hh", clear
duplicates report HH1 HH2 

keep HH1 HH2 HH7 HH7A

cap gen countryfile = "BGD2019"

gen mics_adm0_geocode = .
rename HH7 mics_adm1_geocode
rename HH7A mics_adm2_geocode

sa "$dir_tempdata\cherry\BGD2019", replace


*** KGZ2018
u "$dir_rawdata\mics\KGZ2018_hh", clear

keep HH1 HH2 HH7
 
cap gen countryfile = "KGZ2018"

gen mics_adm0_geocode = .
rename HH7 mics_adm1_geocode
gen mics_adm2_geocode = .

sa "$dir_tempdata\cherry\\KGZ2018", replace



*** MNG2018
u "$dir_rawdata\mics\MNG2018_hh", clear

keep HH1 HH2 HH7 

cap gen countryfile = "MNG2018"

rename HH7 mics_adm0_geocode 
gen mics_adm1_geocode = .
replace mics_adm1_geocode = mics_adm0_geocode if mics_adm0_geocode == 5 // Ulaanbaatar  
gen mics_adm2_geocode = .

sa "$dir_tempdata\cherry\\MNG2018", replace



*** NPL2019
u "$dir_rawdata\mics\NPL2019_hh", clear

keep HH1 HH2 HH7 

cap gen countryfile = "NPL2019"

gen mics_adm0_geocode = . 
rename HH7 mics_adm1_geocode
gen mics_adm2_geocode = .

sa "$dir_tempdata\cherry\\NPL2019", replace



******************************* Pakistan ***************************************

*** PKB2019 
u "$dir_rawdata\mics\PKB2019_hh", clear

keep HH1 HH2 HH7

cap gen countryfile = "PKB2019"

gen mics_adm0_geocode = .
gen mics_adm1_geocode = 1 
rename HH7 mics_adm2_geocode

sa "$dir_tempdata\cherry\\PKB2019", replace

*** PKK2019 
u "$dir_rawdata\mics\PKK2019_hh", clear

keep HH1 HH2 HH7

cap gen countryfile = "PKK2019"

gen mics_adm0_geocode = .
gen mics_adm1_geocode = 2 
rename HH7 mics_adm2_geocode

sa "$dir_tempdata\cherry\\PKK2019", replace


*** PKP2017 
u "$dir_rawdata\mics\PKP2017_hh", clear

keep HH1 HH2 HH7

cap gen countryfile = "PKP2017"

gen mics_adm0_geocode = .
gen mics_adm1_geocode = 3 
rename HH7 mics_adm2_geocode

sa "$dir_tempdata\cherry\\PKP2017", replace


*** PKS2018 
u "$dir_rawdata\mics\PKS2018_hh", clear

keep HH1 HH2 HH7

cap gen countryfile = "PKS2018"

gen mics_adm0_geocode = .
gen mics_adm1_geocode = 4 
rename HH7 mics_adm2_geocode

sa "$dir_tempdata\cherry\\PKS2018", replace



******************************* Thailand ***************************************

*** THA2019 
u "$dir_rawdata\mics\THA2019_hh", clear

keep HH1 HH2 HH7

cap gen countryfile = "THA2019"

rename HH7 mics_adm0_geocode 
gen mics_adm1_geocode = . 
replace mics_adm1_geocode = mics_adm0_geocode if mics_adm0_geocode == 1 // Bangkok 
gen mics_adm2_geocode = .

sa "$dir_tempdata\cherry\\THA2019", replace

*** T172019 
u "$dir_rawdata\mics\T172019_hh", clear

keep HH1 HH2 HH7 HH7A

cap gen countryfile = "T172019"

rename HH7 mics_adm0_geocode 
rename HH7A mics_adm1_geocode
gen mics_adm2_geocode = .

sa "$dir_tempdata\cherry\\T172019", replace



*** TKM2019 ***************************************************

u "$dir_rawdata\mics\TKM2019_hh", clear

keep HH1 HH2 HH7

cap gen countryfile = "TKM2019"

gen mics_adm0_geocode = . 
rename HH7 mics_adm1_geocode
gen mics_adm2_geocode = .

sa "$dir_tempdata\cherry\\TKM2019", replace




********************************************************************************
* append all geocode used in MICS into one table 
********************************************************************************


u "$dir_tempdata\cherry\\BGD2019", clear

foreach i in ///
"KGZ2018" ///
"MNG2018" ///
"NPL2019" ///
"PKB2019" ///
"PKK2019" ///
"PKP2017" ///
"PKS2018" ///
"THA2019" ///
"T172019" ///
"TKM2019" ///
{
	append using "$dir_tempdata\cherry\\`i'"
}


rename mics_adm0* adm_05* // Regional level, which is finer than whole country, but more aggregated than admin level 1, is defined as admin level 0.5. 
rename mics_adm1* adm_1*
rename mics_adm2* adm_2*

merge m:1 countryfile adm_05_geocode adm_1_geocode adm_2_geocode using "$dir_data\id_key_file\mics_loc_id"
fre _merge if HH1 != .
keep if _merge == 3 
keep HH1 HH2 countryfile RDSE_loc_id
order countryfile HH1 HH2 RDSE_loc_id



sa "$dir_data\id_key_file\mics_hh_id", replace
export delimited using "$dir_data\id_key_file\mics_hh_id", replace




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


