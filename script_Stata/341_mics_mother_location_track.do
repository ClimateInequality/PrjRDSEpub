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
log using "$dir_log\341_mics_mother_location_track_$today.log", replace

efolder cherry, cd("$dir_tempdata")
cd "$dir_program"



global identifiers = "countryfile HH1 HH2 moLN"
global countryfile_list "BGD2019" "KGZ2018" "MNG2018" "NPL2019" "PKK2019" "PKP2017" "PKS2018" "THA2019" "T172019" "TKM2019"
global countryfile_list_2 "KGZ2018" "MNG2018" "NPL2019" "PKK2019" "PKP2017" "PKS2018" "THA2019" "T172019" "TKM2019"


/*******************************************************************************

* Module 1. Find mothers for all children and their interview date, current location, years of duration, and prior location. 

*******************************************************************************/

/* 
https://github.com/ClimateInequality/PrjRDSE/issues/35

Module 1. Find mothers for all children and their interview date, current location, years of duration, and prior location. Do this by countryfile. 

Output: Each obs is one child's mother. 
Column: identifier of child (countryfile, HH1, HH2, LN); mother identifier (moLN); 
mother interview year, month, date; child interview year, month, date; 
mother prior location; mother years of duration; current location; 

Step 1. In child id file, the identifiers for mother of each child: countryfile, HH1, HH2, moLN. 
In raw data of individual women for each country/region, the identifiers are HH1, HH2, LN. 
1) generate countryfile variable 
2) rename LN to moLN 
3) merge by identifiers 
Step 2. Construct variables on years of duration; prior location code and name (eg. 10 Barisal in BGD). 
Step 3. Merge with children demographic information file, get children birth year and month, current location. 
*/


cap program drop pr_mo_loc 
program define pr_mo_loc

	// Check identifiers make sense. The below should all be zero. 
	count if HH1 != WM1 
	count if HH2 != WM2 
	count if LN != WM3 

	rename LN moLN 
	la var moLN "Mother line number"
	merge 1:1 ${identifiers} using "$dir_data\id_key_file\mics_child_id"
	keep if _merge == 3
	drop _merge

	order ${identifiers} LN 

	keep ${identifiers} LN WM6D WM6M WM6Y WB15* WB16* WB17* 
	// HH7* 
	// HH7 : Division 
	// HH7A : District
	// This is the same as how we obtain children location 

	* run this program for one country 
	foreach var in "WB15" "WB16" "WB17" "WB17A" {
		cap confirm v `var'
		// return code is 111 if variable __ not found in this dataset 
		if _rc != 111 {
			fre `var'
		}
	}

	cap confirm v WB15 WB16 
	if _rc != 111 {
		fre WB16 if WB15 == 95 // always live here, no migration 
		fre WB16 if WB15 < 95
		fre WB16 if WB15 > 95 | WB15 == .
	}

end 

// u "$dir_data\id_key_file\mics_child_id", clear




*** BGD2019
local c = "BGD2019"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
pr_mo_loc

clonevar mo_int_d = WM6D
clonevar mo_int_m = WM6M
clonevar mo_int_y = WM6Y

clonevar mo_duration_yr = WB15 

clonevar mo_prior_loc_adm1 = WB17 
decode WB17, gen(mo_prior_loc_adm1_name) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 

// cap drop WB16
// cap drop HH7*
keep ${identifiers} LN mo_int* mo_*
sa "$dir_tempdata\\cherry\\`c'", replace
ds, de



*** KGZ2018
local c = "KGZ2018"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
pr_mo_loc

clonevar mo_int_d = WM6D
clonevar mo_int_m = WM6M
clonevar mo_int_y = WM6Y

clonevar mo_duration_yr = WB15 

clonevar mo_prior_loc_adm1 = WB17 
decode WB17, gen(mo_prior_loc_adm1_name) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 

keep ${identifiers} LN mo_int* mo_*
sa "$dir_tempdata\\cherry\\`c'", replace
ds, de



*** MNG2018
local c = "MNG2018"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
pr_mo_loc
bys WB17A: fre WB17 
// We do not care which country they have lived in prior to moving to current place. 

clonevar mo_int_d = WM6D
clonevar mo_int_m = WM6M
clonevar mo_int_y = WM6Y

clonevar mo_duration_yr = WB15 


clonevar mo_prior_loc_adm1 = WB17 
decode WB17, gen(mo_prior_loc_adm1_name) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 
// Current location name : adm 1 aimag
// Prior location name : adm 0.5 region 

keep ${identifiers} LN mo_int* mo_*
sa "$dir_tempdata\\cherry\\`c'", replace
ds, de 



*** NPL2019
local c = "NPL2019"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
pr_mo_loc
fre WB16
fre WB17 WB17A 

bys WB17A: fre WB17 
// Only when she lives in another district prior to moving to current place, the name of that districe is recorded. 

// WB17A whether same or another district prior to moving to current place 
// WB17 district prior to moving to current place 
fre WB17A
fre WB17 if WB17A == 1 // If mother lives in same district, then prior place name is missing. However, we do not observe district name of current location. 
fre WB17 if WB17A == 2 // If mother lives in different district (have migrated), then we know the prior place name. 
fre WB17 if WB17A == 6
tab WB17 WB17A

cap drop WB16 WB17
cap drop HH7*

/*
local i = "NPL2019"
u "$dir_rawdata\mics\\`i'_fs", clear
fre HH7 HH7b HH7c
// HH7 : Region, HH7b : Domain, HH7c : Province. Region and Province are the same. What is Domain? Ignore Domain. 
*/

local c = "NPL2019"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)

pr_mo_loc

clonevar mo_int_d = WM6D
clonevar mo_int_m = WM6M
clonevar mo_int_y = WM6Y

clonevar mo_duration_yr = WB15 

clonevar mo_prior_loc_adm2 = WB17 
decode WB17, gen(mo_prior_loc_adm2_name) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 
// WB17 is district, admin level 2 

keep ${identifiers} LN mo_int* mo_*
sa "$dir_tempdata\\cherry\\`c'", replace
ds, de 



******************************* Pakistan ***************************************

*** PKK2019 
local c = "PKK2019"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
/* There is no WB15-17 variables in PKK. We know nothing about migratory history of mothers in PKK. 
*/


*** PKP2017 
local c = "PKP2017"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
cap program drop pr_mo_loc_PKP
program define pr_mo_loc_PKP

	// Check identifiers make sense. The below should all be zero. 
	count if HH1 != WM1 
	count if HH2 != WM2 
	count if LN != WM3 

	rename LN moLN 
	la var moLN "Mother line number"
	merge 1:1 ${identifiers} using "$dir_data\id_key_file\mics_child_id"
	keep if _merge == 3
	drop _merge

	order ${identifiers} LN 

	keep ${identifiers} LN WM6D WM6M WM6Y WB15* WB16* WB17* hh7* hh6*

	* run this program for one country 
	foreach var in "WB15" "WB16" "WB17" "WB17A" {
		cap confirm v `var'
		// return code is 111 if variable __ not found in this dataset 
		if _rc != 111 {
			fre `var'
		}
	}

	cap confirm v WB15 WB16 
	if _rc != 111 {
		fre WB16 if WB15 == 95 // always live here, no migration 
		fre WB16 if WB15 < 95
		fre WB16 if WB15 > 95 | WB15 == .
	}

end 

pr_mo_loc_PKP

clonevar mo_int_d = WM6D
clonevar mo_int_m = WM6M
clonevar mo_int_y = WM6Y

clonevar mo_duration_yr = WB15 

clonevar mo_prior_loc_adm1 = WB17 
decode WB17, gen(mo_prior_loc_adm1_name) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 
// WB17 label: region prior to moving to current place. It is in fact province: Punjab, Sindh, Balochistan, AJK, KPK, ICT

keep ${identifiers} LN mo_int* mo_*
sa "$dir_tempdata\\cherry\\`c'", replace
ds, de 



*** PKS2018 
local c = "PKS2018"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)

cap program drop pr_mo_loc_PKS
program define pr_mo_loc_PKS	

	// Check identifiers make sense. The below should all be zero. 
	count if HH1 != WM1 
	count if HH2 != WM2 
	count if LN != WM3 

	rename LN moLN 
	la var moLN "Mother line number"
	merge 1:1 ${identifiers} using "$dir_data\id_key_file\mics_child_id"
	keep if _merge == 3
	drop _merge

	order ${identifiers} LN 

	keep ${identifiers} LN WM6D WM6M WM6Y WB15* WB16* WB17* HH6 HH7 hh7r

	* run this program for one country 
	foreach var in "WB15" "WB16" "WB17" "WB17A" {
		cap confirm v `var'
		// return code is 111 if variable __ not found in this dataset 
		if _rc != 111 {
			fre `var'
		}
	}

	cap confirm v WB15 WB16 
	if _rc != 111 {
		fre WB16 if WB15 == 95 // always live here, no migration 
		fre WB16 if WB15 < 95
		fre WB16 if WB15 > 95 | WB15 == .
	}

end

pr_mo_loc_PKS

clonevar mo_int_d = WM6D
clonevar mo_int_m = WM6M
clonevar mo_int_y = WM6Y

clonevar mo_duration_yr = WB15 

clonevar mo_prior_loc_adm1 = WB17 
decode WB17, gen(mo_prior_loc_adm1_name) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 
// WB17 label: region prior to moving to current place. It is in fact province: Punjab, Sindh, Balochistan, AJK, KPK, ICT

keep ${identifiers} LN mo_int* mo_*
sa "$dir_tempdata\\cherry\\`c'", replace
ds, de 



******************************* Thailand ***************************************

*** THA2019 
local c = "THA2019"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
pr_mo_loc

clonevar mo_int_d = WM6D
clonevar mo_int_m = WM6M
clonevar mo_int_y = WM6Y

clonevar mo_duration_yr = WB15 

clonevar mo_prior_loc_adm05 = WB17 
decode WB17, gen(mo_prior_loc_adm05_name) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 

keep ${identifiers} LN mo_int* mo_*
sa "$dir_tempdata\\cherry\\`c'", replace
ds, de 



*** T172019 
local c = "T172019"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
pr_mo_loc

clonevar mo_int_d = WM6D
clonevar mo_int_m = WM6M
clonevar mo_int_y = WM6Y

clonevar mo_duration_yr = WB15 

clonevar mo_prior_loc_adm05 = WB17 
decode WB17, gen(mo_prior_loc_adm05_name) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 

keep ${identifiers} LN mo_int* mo_*
sa "$dir_tempdata\\cherry\\`c'", replace
ds, de 



*** TKM2019 ***************************************************

local c = "TKM2019"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
pr_mo_loc

clonevar mo_int_d = WM6D
clonevar mo_int_m = WM6M
clonevar mo_int_y = WM6Y

clonevar mo_duration_yr = WB15 

clonevar mo_prior_loc_adm1 = WB17 
decode WB17, gen(mo_prior_loc_adm1_name) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 

keep ${identifiers} LN mo_int* mo_*
sa "$dir_tempdata\\cherry\\`c'", replace
ds, de


********************************************************************************
* Step 3. Merge with children demographic information file, get children birth year and month, current location. 
********************************************************************************

// Append all country files 
local c = "BGD2019"
u "$dir_tempdata\\cherry\\`c'", clear
foreach i in "${countryfile_list_2}" {
	cap append using "$dir_tempdata\\cherry\\`i'"
}

sa "$dir_data\\data_intermediate\\mics_mother_location_track", replace

// Obtain child year of birth 

/*******************************************************************************

* Clean THA and PAK 

*******************************************************************************/
u "$dir_data\id_key_file\mics_child_id", clear


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


u "$dir_data\\data_intermediate\\230_mics_child", clear
clean_THA_PAK
drop if countryfile == "PKB2019"
count

merge 1:1 countryfile HH1 HH2 LN using "$dir_data\\data_intermediate\\mics_mother_location_track"

/*
. fre _merge

_merge -- Matching result from merge
-----------------------------------------------------------------------
                          |      Freq.    Percent      Valid       Cum.
--------------------------+--------------------------------------------
Valid   1 Master only (1) |      43036      29.79      29.79      29.79
        3 Matched (3)     |     101435      70.21      70.21     100.00
        Total             |     144471     100.00     100.00           
-----------------------------------------------------------------------
*/

// keep if _merge == 3 // Only keep children with mothers information available. 
drop _merge 
count

sort countryfile HH1 HH2 LN 
order RDSE_loc_id countryfile HH1 HH2 LN moLN faLN ISO_alpha_3, first 
keep RDSE_loc_id countryfile HH1 HH2 LN moLN faLN ISO_alpha_3 kid_age kid_birthm kid_birthy mo_*

sa "$dir_data\\data_intermediate\\mics_mother_location_track", replace
export delimited using "$dir_data\data_intermediate\\mics_mother_location_track.csv", nolabel replace





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


