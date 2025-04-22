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

global today "20250415"
log using "$dir_log\312_loc_timing_disaster_$today.log", replace



efolder banana, cd("$dir_tempdata")
cd "$dir_program"

efolder location_file, cd("$dir_data\id_key_file")
cd "$dir_program"



/*******************************************************************************

# TASK: unify the location names across several files 

*******************************************************************************/
/*
### module 2.1 

input: file A1 and A2 for locaiton identifiers 
- file A1, mics_loc_id, which includes unique RDSE id for each location  
- file A2, boundary_loc_id, which includes all locaitons and corresponding aggregated and divided level 

output: file A2 with RDSE loc id 
row: finest location in file A1 
column: every column in file A2 and RDSE loc id

- [ ] algorithm
1. mat
*/

/*
u "$dir_data\id_key_file\boundary_loc_id", clear

keep if ISO_alpha_3 == "BGD"
duplicates report
duplicates tag ISO_alpha_3 finest_adm_level adm_05_loc adm_1_loc adm_2_loc, gen(flag)
fre flag
// br if flag != 0



merge 1:1 ISO_alpha_3 finest_adm_level adm_05_loc adm_1_loc adm_2_loc using "$dir_data\id_key_file\mics_loc_id"

u "$dir_data\id_key_file\mics_loc_id", clear
duplicates tag ISO_alpha_3 finest_adm_level adm_05_loc adm_1_loc adm_2_loc, gen(flag)
fre flag
br if flag != 0
*/



/*******************************************************************************

* MODULE 1. 

Output: 
row: location and disaster happended to this location 
column: 
(1) disaster ID 
(2) country 
(3) location name string 
(4) adm level, 0 or 1 or 2 

*******************************************************************************/



u "$dir_data\emdat\emdat_public_adbi_proj_country", clear 

keep if inrange(Year, 2015, 2019)

keep DisNo Year ISO Location GeoLocations AdmLevel 
// keep DisNo GeoLocations 

clonevar locname = GeoLocations
replace locname = Location if locname == ""
replace locname = ISO if locname == ""

replace locname = subinstr(locname, " (Adm1).", ",", .)
replace locname = subinstr(locname, " (Adm2).", ",", .)
replace locname = subinstr(locname, ";", ",", .)
replace locname = subinstr(locname, " District", "", .)
replace locname = subinstr(locname, " district", "", .)
replace locname = subinstr(locname, " (Administrative unit not available)", "", .)
replace locname = subinstr(locname, "Administrative unit not available", "", .)
replace locname = subinstr(locname, " Agency", "", .)
replace locname = subinstr(locname, " agency", "", .)
replace locname = subinstr(locname, " regions", "", .)
replace locname = subinstr(locname, " region", "", .)
replace locname = subinstr(locname, " Regions", "", .)
replace locname = subinstr(locname, " Region", "", .)


keep locname DisNo

split locname, parse(,) gen(loc_)

keep DisNo loc_*

reshape long loc_, i(DisNo) j(lengjing)

drop if loc_ == ""
replace loc_ = trim(loc_)

duplicates report DisNo loc 
duplicates report DisNo lengjing 
drop lengjing 
merge m:1 DisNo using "$dir_data\emdat\emdat_public_adbi_proj_country"
keep if _merge == 3
drop _merge 

keep DisNo ISO loc_ AdmLevel
order DisNo ISO loc_ AdmLevel

sa "$dir_tempdata\banana\disaster_loc", replace 



/*******************************************************************************

* MODULE 2.1 add RDSE_loc_id to boundary file to create file_A 

*******************************************************************************/

/* This will keep values of adm_1_loc and adm_2_loc in the master data, which means it is still missing for those at adm_05_loc level. 
***************************************************/

/*
u "$dir_data\id_key_file\mics_loc_id", clear

keep if finest_adm_level == 0.5
merge 1:m ISO_alpha_3 adm_05_loc using "$dir_data\id_key_file\boundary_loc_id"
keep if _merge == 3

sa "$dir_tempdata\banana\file_A_05", replace

u "$dir_data\id_key_file\mics_loc_id", clear

keep if finest_adm_level == 1
merge 1:m ISO_alpha_3 adm_1_loc using "$dir_data\id_key_file\boundary_loc_id" 
keep if _merge == 3

sa "$dir_tempdata\banana\file_A_1", replace

u "$dir_data\id_key_file\mics_loc_id", clear

keep if finest_adm_level == 2
merge 1:m ISO_alpha_3 adm_2_loc using "$dir_data\id_key_file\boundary_loc_id" 
keep if _merge == 3

sa "$dir_tempdata\banana\file_A_2", replace

append using "$dir_tempdata\banana\file_A_1"
append using "$dir_tempdata\banana\file_A_05"

drop _merge 
sort RDSE_loc_id 
sa "$dir_tempdata\banana\file_A", replace 
*/



*** THIS IS NOT NECESSARY IF WE USE UNIFORM NAMES ********************************************
*** change province name for NPL ***

u "$dir_data\id_key_file\mics_loc_id", clear

replace adm_1_loc = "Province No 1" if ISO_alpha_3 == "NPL" & adm_1_geocode == 1
replace adm_1_loc = "Province No 2 Madhesh" if ISO_alpha_3 == "NPL" & adm_1_geocode == 2
replace adm_1_loc = "Province No 3 Bagmati" if ISO_alpha_3 == "NPL" & adm_1_geocode == 3
replace adm_1_loc = "Province No 4 Gandaki" if ISO_alpha_3 == "NPL" & adm_1_geocode == 4
replace adm_1_loc = "Province No 5 Lumbini" if ISO_alpha_3 == "NPL" & adm_1_geocode == 5
replace adm_1_loc = "Province No 6 Karnali" if ISO_alpha_3 == "NPL" & adm_1_geocode == 6
replace adm_1_loc = "Province No 7 Sudur Pashchim" if ISO_alpha_3 == "NPL" & adm_1_geocode == 7

replace adm_1_loc = "Osh city" if adm_1_loc == "Osh c"
replace adm_1_loc = "Bishkek city" if adm_1_loc == "Bishkek c"

sa "$dir_data\id_key_file\mics_loc_id", replace

*** THIS IS NOT NECESSARY IF WE USE UNIFORM NAMES ********************************************

u "$dir_data\id_key_file\mics_loc_id", clear

keep if finest_adm_level == 0.5
drop adm_1* adm_2*

merge 1:m ISO_alpha_3 adm_05_loc using "$dir_data\id_key_file\boundary_loc_id" 
sort ISO_alpha_3 finest_adm_level adm_05_loc adm_1_loc adm_2_loc
drop if RDSE_loc_id == .

sa "$dir_tempdata\banana\file_A_05", replace



u "$dir_data\id_key_file\mics_loc_id", clear

keep if finest_adm_level == 1
drop adm_2*

merge 1:m ISO_alpha_3 adm_1_loc using "$dir_data\id_key_file\boundary_loc_id" 
sort ISO_alpha_3 finest_adm_level adm_05_loc adm_1_loc adm_2_loc
drop if RDSE_loc_id == .

sa "$dir_tempdata\banana\file_A_1", replace



u "$dir_data\id_key_file\mics_loc_id", clear

keep if finest_adm_level == 2

merge 1:m ISO_alpha_3 adm_2_loc using "$dir_data\id_key_file\boundary_loc_id" 
sort ISO_alpha_3 finest_adm_level adm_05_loc adm_1_loc adm_2_loc
keep if _merge == 3

sa "$dir_tempdata\banana\file_A_2", replace



append using "$dir_tempdata\banana\file_A_1"
append using "$dir_tempdata\banana\file_A_05"

drop _merge 
sort RDSE_loc_id 
sa "$dir_data\id_key_file\file_A", replace 
export delimited using "$dir_data\id_key_file\file_A.csv", replace






/*******************************************************************************

* WHATEVER THE BELOW IS DOING **************************************************

*******************************************************************************/



u "$dir_tempdata\banana\disaster_loc", clear
export delimit "$dir_tempdata\banana\disaster_loc.csv", replace

u "$dir_tempdata\banana\file_A", clear
export delimit "$dir_tempdata\banana\file_A.csv", replace


local emdatlocation = loc_ in 1

u "$dir_tempdata\banana\file_A", clear
keep if adm_2_loc == "`emdatlocation'"







u "$dir_tempdata\banana\file_A", clear

keep if finest_adm_level == 2
duplicates report ISO_alpha_3 adm_2_loc

sa "$dir_tempdata\banana\file_A_adm_2", replace





u "$dir_tempdata\banana\disaster_loc", clear

fre AdmLevel
replace AdmLevel = "0" if AdmLevel == ""

keep if AdmLevel == "2"

rename ISO ISO_alpha_3 
rename loc_ adm_2_loc 
drop _merge
merge m:1 ISO_alpha_3 adm_2_loc using "$dir_tempdata\banana\file_A_adm_2"
keep if _merge == 3 
drop _merge 
gen matchtype = 1 
la def matchtype 1 "EMDAT adm 2 == MICS adm 2"
la val matchtype matchtype








u "$dir_tempdata\banana\disaster_loc", clear

fre AdmLevel
replace AdmLevel = "0" if AdmLevel == ""

egen emdat_loc_id = group(ISO loc_)

sort ISO loc_

sa "$dir_tempdata\banana\disaster_loc_id", replace

keep ISO loc_ emdat_loc_id
duplicates drop

sa "$dir_tempdata\banana\emdat_loc_id", replace

u "$dir_tempdata\banana\emdat_loc_id", clear
rename ISO ISO_alpha_3
rename loc_ adm_2_loc 
merge 1:m ISO_alpha_3 adm_2_loc using "$dir_tempdata\banana\file_A"
keep if _merge == 3
drop _merge 
sa "$dir_tempdata\banana\emdat_loc_id_2to2", replace


u "$dir_tempdata\banana\emdat_loc_id", clear
rename ISO ISO_alpha_3
rename loc_ adm_1_loc 
merge 1:m ISO_alpha_3 adm_1_loc using "$dir_tempdata\banana\file_A"
keep if _merge == 3
drop _merge 
sa "$dir_tempdata\banana\emdat_loc_id_1to1", replace


keep if AdmLevel == "2"

rename ISO ISO_alpha_3 
rename loc_ adm_2_loc 
drop _merge
merge m:1 ISO_alpha_3 adm_2_loc using "$dir_tempdata\banana\file_A_adm_2"
keep if _merge == 3 
drop _merge 
gen matchtype = 1 
la def matchtype 1 "EMDAT adm 2 == MICS adm 2"
la val matchtype matchtype





/*******************************************************************************

* MODULE 3. 

*******************************************************************************/

u "$dir_data\id_key_file\boundary_loc_id", clear

findlocname

/***** all location names together 
*************************************************/

u "$dir_tempdata\banana\loc_adm0", clear
append using "$dir_tempdata\banana\loc_adm05"
append using "$dir_tempdata\banana\loc_adm1"
append using "$dir_tempdata\banana\loc_adm2"
sa "$dir_data\id_key_file\location_file\boundary_loc_adm_all", replace 


*** only leave finest adm level location name 
u "$dir_data\id_key_file\location_file\boundary_loc_adm_all", clear 

gen locname = ""
replace locname = ISO_alpha_3 if finest_adm_level == 0 
replace locname = adm_05_loc if finest_adm_level == 0.5
replace locname = adm_1_loc if finest_adm_level == 1
replace locname = adm_2_loc if finest_adm_level == 2

// keep Country ISO* finest_adm_level locname
keep Country ISO* locname
duplicates drop 
// rename locname boundary_loc_name 

sa "$dir_data\id_key_file\location_file\boundary_loc_name", replace 





********************************************************************************
* delete temparory data files 
********************************************************************************

// shell rd "$dir_tempdata\banana" /s /q
// shell rm -r "$dir_tempdata\banana" /s /q

* delete all files in folder "banana"
cd "$dir_tempdata"
shell rd "banana" /s /q
cd "$dir_program"

* delete folder "banana"
rmdir "$dir_tempdata\banana"


