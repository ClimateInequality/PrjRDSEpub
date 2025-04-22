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

global today "20240311"
log using "$dir_log\343_mics_mother_loc_measure_$today.log", replace

efolder cherry, cd("$dir_tempdata")
cd "$dir_program"



global identifiers = "countryfile HH1 HH2 moLN"
global countryfile_list "BGD2019" "KGZ2018" "MNG2018" "NPL2019" "PKK2019" "PKP2017" "PKS2018" "THA2019" "T172019" "TKM2019"
global countryfile_list_2 "KGZ2018" "MNG2018" "NPL2019" "PKK2019" "PKP2017" "PKS2018" "THA2019" "T172019" "TKM2019"


/*******************************************************************************

* Module 1. Share of 

*******************************************************************************/

/* 
https://github.com/ClimateInequality/PrjRDSE/issues/35


*/


u "$dir_data\\data_intermediate\\mics_mother_location_track", clear

// Share of children whose mothers have been living in the same place since their birth year. 

cap drop modur_longer_than_kidage
gen modur_longer_than_kidage = . 
replace modur_longer_than_kidage = 1 if mo_duration_yr >= kid_age+1 
replace modur_longer_than_kidage = 0 if mo_duration_yr < kid_age+1 
replace modur_longer_than_kidage = . if mo_duration_yr == . 
la var modur_longer_than_kidage "Mothers have been living in current place since children's birth year"

fre modur_longer_than_kidage
tab modur_longer_than_kidage
sum modur_longer_than_kidage, de 

bys countryfile: fre modur_longer_than_kidage

// Dummy for child age since conception> mother duration in current place. 

cap drop modur_shorter_than_kidage
gen modur_shorter_than_kidage = . 
replace modur_shorter_than_kidage = 1 if mo_duration_yr <= kid_age+1 
replace modur_shorter_than_kidage = 0 if mo_duration_yr > kid_age+1 
replace modur_shorter_than_kidage = . if mo_duration_yr == . 
la var modur_shorter_than_kidage "Child has moved since conception"

fre modur_shorter_than_kidage
tab modur_shorter_than_kidage
sum modur_shorter_than_kidage, de 

bys countryfile: fre modur_shorter_than_kidage

// For each child, calculate the share of years in her life during which she lives in this place. 

cap drop kid_share 
gen kid_share = . 
replace kid_share = mo_duration_yr/(kid_age+1) if mo_duration_yr != . & kid_age != . 

cap drop kid_share_yrinplace
gen kid_share_yrinplace = . 
replace kid_share_yrinplace = kid_share if kid_share < 1
replace kid_share_yrinplace = 1 if kid_share >= 1 
replace kid_share_yrinplace = . if kid_share == . 
la var kid_share_yrinplace "Child's share of life length living in current place"
drop kid_share 

sum kid_share_yrinplace, de
tab kid_share_yrinplace
fre kid_share_yrinplace

bys countryfile kid_age: sum kid_share_yrinplace, de
bys countryfile: sum kid_share_yrinplace, de
bys ISO_alpha_3: sum kid_share_yrinplace, de


_pctile kid_share_yrinplace, percentiles(1 5 10 15 20 25)
// Results of percentiles are stored in r(r1) r(r2) r(r3) r(r4) r(r5)
foreach i of numlist 1(1)5 {
	di "r(r`i') = `r(r`i')'"
}


sa "$dir_data\\data_intermediate\\mics_mother_loc_measure", replace


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


