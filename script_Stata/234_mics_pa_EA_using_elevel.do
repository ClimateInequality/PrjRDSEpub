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

log using "$dir_log\234_mics_pa_EA_using_elevel_$today.log", replace



****************************************************************************************************************************************************************
************************ Main Code Starts Here *****************************************************************************************************************
****************************************************************************************************************************************************************


********************************************************************************
* TASK: Construct MICS data parent education var 
********************************************************************************

/*
https://github.com/ClimateInequality/PrjRDSE/issues/1

All variables start with `edu'. 
Keep AMS model in mind. There are 3 groups of variables. 
A -> Attainment 
E -> Enrollment 
P -> Progression 

Construct Grade (uniform variable - year of education - across country), Enrollment. 
In 250_mics_EAPSO, construct E A P R S O variable. 
*/

efolder mics_fs, cd("$dir_tempdata")
efolder mics_hl, cd("$dir_tempdata")
cd "$dir_program"



/*******************************************************************************

* MODULE. Clean THA and PAK file 

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


/*******************************************************************************

* MODULE. Compare mo_elevel_raw_decode_fs, mo_elevel_raw_decode_hl, fa_elevel_raw_decode_hl

*******************************************************************************/


u "$dir_data\\data_intermediate\234_mics_pa_hh_WithRawVar", clear

clean_THA_PAK



*** Browse and decide to use both melevel_fs and melevel_hl 

gen mo_elevel_raw_decode = mo_elevel_raw_decode_fs
replace mo_elevel_raw_decode = mo_elevel_raw_decode_hl if mo_elevel_raw_decode == "" 
 

foreach var in "mo_elevel_raw_decode" {
	
	cap elabel drop lbl_`var'
	elabel define lbl_`var' 99 "No meaning"
	// local j = "   Lower Basic (Gr 1-5)"
	// elabel define lbl_elevel_allcountry 1 "`j'", modify
	local i = 1
	levelsof `var', local(levels) 
	foreach j of local levels {
		di "`j'"
		elabel define lbl_`var' `i' "`j'", modify
		local i = `i' + 1
	}

	elabel list lbl_`var'

	cap drop `var'_n
	gen `var'_n = . 

	local i = 1
	levelsof `var', local(levels) 
	foreach j of local levels {
		replace `var'_n = `i' if `var' == "`j'"
		local i = `i' + 1
	}

	la val `var'_n lbl_`var'
// 	fre `var'  
// 	fre `var'_n
// 	tab `var' `var'_n
	
}

// fre mo_elevel_raw_decode_n

cap drop fa_elevel_raw_decode_n 
clonevar fa_elevel_raw_decode_n = fa_elevel_raw_decode_hl_n

// fre fa_elevel_raw_decode_n



/*******************************************************************************

* MODULE 1. Enrollment ever 

*******************************************************************************/

*** Change no information/missing/DK to real missing 

*** mother ever educated 

fre mo_elevel_raw_decode_n



cap drop mo_elevel_E_ever 
gen mo_elevel_E_ever = .
replace mo_elevel_E_ever = . if inlist(mo_elevel_raw_decode_n, 15, 16)
replace mo_elevel_E_ever = 0 if inlist(mo_elevel_raw_decode_n, 17, 18, 19, 20)
replace mo_elevel_E_ever = 1 if inrange(mo_elevel_raw_decode_n, 1, 14) | inrange(mo_elevel_raw_decode_n, 21, 31)

tab mo_elevel_raw_decode_n mo_elevel_E_ever


*** father ever educated 

fre fa_elevel_raw_decode_n

cap drop fa_elevel_E_ever 
gen fa_elevel_E_ever = .
replace fa_elevel_E_ever = . if inlist(fa_elevel_raw_decode_n, 6, 9, 15, 16, 17)
replace fa_elevel_E_ever = 0 if inlist(fa_elevel_raw_decode_n, 18, 19, 20, 21)
replace fa_elevel_E_ever = 1 if inrange(fa_elevel_raw_decode_n, 1, 5) | inrange(fa_elevel_raw_decode_n, 7, 8) | inrange(fa_elevel_raw_decode_n, 10, 14) | inrange(fa_elevel_raw_decode_n, 22, 30)

tab fa_elevel_raw_decode_n fa_elevel_E_ever

la var mo_elevel_E_ever "Mother ever educated"
la var fa_elevel_E_ever "Father ever educated"


/*******************************************************************************

* MODULE 2. Have secondary school education or not 

*******************************************************************************/

*** Change no information/missing/DK to real missing 

fre mo_elevel_raw_decode_n

cap drop mo_elevel_A_secondary
gen mo_elevel_A_secondary = .
replace mo_elevel_A_secondary = . if inlist(mo_elevel_raw_decode_n, 15, 16)
replace mo_elevel_A_secondary = 0 if inlist(mo_elevel_raw_decode_n, 1, 3, 5, 10, 11, 13, 14, 17, 18, 19, 20, 21, 22, 25, 27)
replace mo_elevel_A_secondary = 1 if inlist(mo_elevel_raw_decode_n, 2, 4, 6, 7, 8, 9, 12, 23, 24, 26, 28, 29, 30, 31)

replace mo_elevel_A_secondary = 1 if inlist(mo_elevel_raw_decode_n, 25) & ISO_alpha_3 == "BGD"
replace mo_elevel_A_secondary = 1 if inlist(mo_elevel_raw_decode_n, 25) & ISO_alpha_3 == "PAK"


// Secondary for BGD 

// gen mo_elevel_A_secondary = 1
// replace mo_elevel_A_secondary = . if inlist(mo_elevel_raw_decode_n, 15, 16, 17)
// replace mo_elevel_A_secondary = 0 if inlist(mo_elevel_raw_decode_n, 1, 3, 5, 10, 11, 12, 14, 21, 22, 25, 26, 27)

tab mo_elevel_raw_decode_n mo_elevel_A_secondary

fre fa_elevel_raw_decode_n

cap drop fa_elevel_A_secondary 
gen fa_elevel_A_secondary = 1
replace fa_elevel_A_secondary = . if inlist(fa_elevel_raw_decode_n, 15, 16, 17, 6, 9) | fa_elevel_raw_decode_n ==.
replace fa_elevel_A_secondary = 0 if inlist(fa_elevel_raw_decode_n, 1, 3, 5, 12, 13, 14, 18, 19, 20, 21, 22, 23, 26)

// replace fa_elevel_A_secondary = 1 if inlist(fa_elevel_raw_decode_n, 25) & ISO_alpha_3 == "BGD"
// replace fa_elevel_A_secondary = 1 if inlist(fa_elevel_raw_decode_n, 25) & ISO_alpha_3 == "PAK"


tab fa_elevel_raw_decode_n fa_elevel_A_secondary

la var mo_elevel_A_secondary "Mother has secondary sch education"
la var fa_elevel_A_secondary "Father has secondary sch education"

/*******************************************************************************

* MODULE 3. Binary var to show availability 

*******************************************************************************/


gen mo_elevel_E_ever_bi = (mo_elevel_E_ever != .)
la var mo_elevel_E_ever_bi  "Have info on if mother is educated"

gen fa_elevel_E_ever_bi = (fa_elevel_E_ever != .)
la var fa_elevel_E_ever_bi  "Have info on if father is educated"

gen mo_elevel_A_secondary_bi = (mo_elevel_A_secondary != .)
la var mo_elevel_A_secondary_bi "Have info on if mother has secondary sch education"

gen fa_elevel_A_secondary_bi = (fa_elevel_A_secondary != .)
la var fa_elevel_A_secondary_bi "Have info on if father has secondary sch education"

cap program drop pr_checkeduvar
program define pr_checkeduvar

	bys ISO_alpha_3: fre *_bi

	bys ISO_alpha_3: sum mo_elevel_A_secondary mo_elevel_E_ever
	// The E_ever should be higher than A_secondary 

	bys ISO_alpha_3: tab mo_elevel_raw_decode_n mo_elevel_A_secondary, r

	bys ISO_alpha_3: tab mo_elevel_raw_decode_n mo_elevel_E_ever, r

	bys ISO_alpha_3: tab fa_elevel_raw_decode_n fa_elevel_A_secondary

	tab ISO_alpha_3 mo_elevel_A_secondary, r

	tab ISO_alpha_3 fa_elevel_A_secondary, r


	tab ISO_alpha_3 mo_elevel_E_ever, r

	tab ISO_alpha_3 fa_elevel_E_ever, r

	tab RDSE_loc_id mo_elevel_A_secondary if ISO_alpha_3 == "BGD", r

	tab ISO_alpha_3 mo_elevel_A_secondary, r
	tab ISO_alpha_3 mo_elevel_E_ever, r

end 


/*******************************************************************************

* MODULE FINAL. Keep necessary var 

*******************************************************************************/

drop *_raw*

keep RDSE_loc_id-ISO_alpha_3 mo_elevel_E_ever* fa_elevel_E_ever* mo_elevel_A_secondary* fa_elevel_A_secondary*

sa "$dir_data\data_intermediate\234_mics_pa_EA_using_elevel", replace 
export delimited using "$dir_data\data_intermediate\\234_mics_pa_EA_using_elevel.csv", nolabel replace






****************************************************************************************************************************************************************
************************ Main Code Ends Here *****************************************************************************************************************
****************************************************************************************************************************************************************


********************************************************************************
* delete temparory data files 
********************************************************************************

// shell rd "$dir_tempdata\cherry" /s /q
// shell rm -r "$dir_tempdata\cherry" /s /q

* delete all files in folder
cd "$dir_tempdata"
shell rd "mics_hl" /s /q
shell rd "mics_fs" /s /q
cd "$dir_program"

* delete folder
cap rmdir "$dir_tempdata\mics_hl"
cap rmdir "$dir_tempdata\mics_fs"




/* check consistency for highest grade ever completed and grade attended this year 
************************************************************************/

cap program drop checkconsistency
program define checkconsistency

tab edu_gradelasty edu_gradethisy
tab edu_gradehighest edu_gradethisy

br countryfile edu_* if edu_gradehighest > edu_gradethisy
tab edu_gradehighest edu_gradethisy if edu_gradehighest > edu_gradethisy

fre edu_levelhighest if edu_gradehighest ==. 
fre edu_yoe_highest if edu_gradehighest ==. 

fre edu_levelthisy if edu_gradethisy ==. 
fre edu_yoe_thisy if edu_gradethisy ==. 

fre edu_levellasty if edu_gradelasty ==. 
fre edu_yoe_lasty if edu_gradelasty ==. 

end













