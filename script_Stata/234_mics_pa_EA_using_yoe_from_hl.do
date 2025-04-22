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

log using "$dir_log\mics_pa_EA_using_yoe_from_hl_$today.log", replace



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

* MODULE. EA for parents based on mo_edu_everschool, mo_edu_yoe_highest, mo_edu_complete

*******************************************************************************/


u "$dir_data\\data_intermediate\234_mics_pa_hh_WithRawVar", clear

clean_THA_PAK




/*******************************************************************************

* MODULE 1. Enrollment ever and Attainment highest

*******************************************************************************/

fre *edu_everschool


*-------------------------------------------------------------------------------
* Enrollment
*-------------------------------------------------------------------------------

*** Enrolled ever or not 
******************************************************************************** 
gen mo_E_ever = mo_edu_everschool
la var mo_E_ever "Mother ever enrolled"

gen fa_E_ever = fa_edu_everschool
la var fa_E_ever "Father ever enrolled"



/*******************************************************************************

* MODULE 2. Grade, Attainment

*******************************************************************************/


*-------------------------------------------------------------------------------
*  Attainment 
*-------------------------------------------------------------------------------
/* We can also use grade variables. Below I am using yoe variables */

*** Highest Attainment 
********************************************************************************
/*

fre mo_edu_complete
tab mo_edu_yoe_highest mo_edu_complete 

cap drop mo_A_max 
gen mo_A_max = . 
la var mo_A_max "Mother attainment (highest)"
replace mo_A_max = mo_edu_yoe_highest - 1 	if mo_edu_complete == . | mo_edu_complete == 0
replace mo_A_max = mo_edu_yoe_highest - 1 	if mo_edu_complete == 1 
replace mo_A_max = 0 if mo_A_max == -1 

fre mo_edu_yoe_highest
fre mo_A_max
tab mo_edu_yoe_highest mo_A_max

*/


cap program drop pr_findAmax
program define pr_findAmax

args p

	fre `p'_edu_complete
	tab `p'_edu_yoe_highest `p'_edu_complete 

	cap drop `p'_A_max 
	gen `p'_A_max = . 
	la var `p'_A_max "`p'ther attainment (highest)"
	replace `p'_A_max = `p'_edu_yoe_highest - 1 	if `p'_edu_complete == . | `p'_edu_complete == 0
	replace `p'_A_max = `p'_edu_yoe_highest - 1 	if `p'_edu_complete == 1 
	replace `p'_A_max = 0 if `p'_A_max == -1 

	fre `p'_edu_yoe_highest
	fre `p'_A_max
	tab `p'_edu_yoe_highest `p'_A_max

end

pr_findAmax mo
pr_findAmax fa



/*******************************************************************************

* MODULE 4. Skipping pattern in survey, should not have attainment if not enrolled 

*******************************************************************************/


/*** Check several things 

(1) 
Only mothers who have ever enrolled have information on yoe. Correct. 
76,505 mothers have been enrolled in school. 

(2)
Only fathers who have ever enrolled have information on yoe. Correct. 
81,337 fathers have been enrolled in school. 

*/

tab mo_edu_yoe_highest mo_edu_everschool 
tab fa_edu_yoe_highest fa_edu_everschool 

fre mo_edu_everschool fa_edu_everschool

/*

mo_edu_everschool -- Mother ever attend school
-----------------------------------------------------------
              |      Freq.    Percent      Valid       Cum.
--------------+--------------------------------------------
Valid   0     |      55272      38.26      41.85      41.85
        1     |      76797      53.16      58.15     100.00
        Total |     132069      91.42     100.00           
Missing .     |      12402       8.58                      
Total         |     144471     100.00                      
-----------------------------------------------------------

fa_edu_everschool -- Father ever attend school
-----------------------------------------------------------
              |      Freq.    Percent      Valid       Cum.
--------------+--------------------------------------------
Valid   0     |      35209      24.37      30.16      30.16
        1     |      81516      56.42      69.84     100.00
        Total |     116725      80.79     100.00           
Missing .     |      27746      19.21                      
Total         |     144471     100.00                      
-----------------------------------------------------------

*/

bys mo_edu_everschool: fre mo_edu_yoe_highest


bys fa_edu_everschool: fre fa_edu_yoe_highest



/*** Check several things 

(3) 
Only mothers who have ever enrolled have information on yoe. Correct. 
76,505 mothers have been enrolled in school. 

(2)
Only fathers who have ever enrolled have information on yoe. Correct. 
81,337 fathers have been enrolled in school. 

*/

fre *_age

/*******************************************************************************

* MODULE FINAL. Keep necessary var 

*******************************************************************************/

drop *_raw*

keep RDSE_loc_id-ISO_alpha_3 mo_E_ever fa_E_ever mo_A_max fa_A_max


sa "$dir_data\data_intermediate\mics_pa_EA_using_yoe_from_hl", replace 
export delimited using "$dir_data\data_intermediate\\mics_pa_EA_using_yoe_from_hl.csv", nolabel replace






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













