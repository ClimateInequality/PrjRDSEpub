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

global today "20231005"

log using "$dir_log\230_mics_child_edu_$today.log", replace


********************************************************************************
* TASK: Construct MICS data educational attainment and related variable 
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



cap program drop edu_var
program define edu_var 

	********************************************************************************
	* attainment ever - grade, education level, depending on country 
	********************************************************************************

	* ever attend school
	fre CB4
		// Obtain info from hl.dta 
		replace CB4 = ED4 if CB4 == . 
		
	clonevar edu_everschool_raw_CB4_ED4 = CB4 
	
	decode CB4, gen(edu_everschool_raw_decode)

	recode CB4 (1=1) (2=0) (3/999=.), gen(edu_everschool)
	la var edu_everschool "Ever attend school"

	* highest level
	cap fre CB5A
		// Obtain info from hl.dta 
		cap replace CB5A = ED5A if CB5A == . 

	cap clonevar edu_levelhighest_raw_CB5A_ED5A = CB5A
	
	cap decode CB5A, gen(edu_levelhighest_raw_decode)

	cap clonevar edu_levelhighest = CB5A
	cap replace edu_levelhighest = . if edu_levelhighest >= 8

	* highest grade attended at that level 
	fre CB5B
		// Obtain info from hl.dta 
		replace CB5B = ED5B if CB5B == . 

	clonevar edu_gradehighest_raw_CB5B_ED5B = CB5B

	decode CB5B, gen(edu_gradehighest_raw_decode)

	clonevar edu_gradehighest = CB5B
	replace edu_gradehighest = . if edu_gradehighest >= 20 
	
	* ever completed that grade/year 
	fre CB6
		// Obtain info from hl.dta 
		replace CB6 = ED6 if CB6 == . 

	clonevar edu_complete_raw_CB6_ED6 = CB6
	
	decode CB6, gen(edu_complete_raw_decode)

	recode CB6 (1=1) (2=0) (3/999=.), gen(edu_complete)
	la var edu_complete "Ever completed that grade"

	/* highest grade one child completed 
	********************************************/
	/*
	fre CB5B

	clonevar edu_highestcomplete = CB5B 
	replace edu_highestcomplete = edu_highestcomplete - 1 if edu_complete == 0
	la var edu_highestcomplete "Highest grade ever completed"
	fre edu_highestcomplete
	*/


	********************************************************************************
	* attainment and enrollment, last year and this year 
	********************************************************************************

	// fre CB3
	// fre CB3-CB10B if CB4 == .
	// fre CB4-CB10B if CB3 == .
	// fre CB4-CB10B

	* this year, enrollment
	fre CB7
		// Obtain info from hl.dta 
		replace CB7 = ED9 if CB7 == . 
		
	clonevar edu_enrolthisy_raw_CB7_ED9 = CB7 
	decode CB7, gen(edu_enrolthisy_raw_decode)

	recode CB7 (1=1) (2=0) (3/999=.), gen(edu_enrolthisy)
	la var edu_enrolthisy "Enrolled this school year"

	* this year, level
	cap fre CB8A
		// Obtain info from hl.dta 
		cap replace CB8A = ED10A if CB8A == . 
		
	cap clonevar edu_levelthisy_raw_CB8A_ED10A = CB8A
	cap decode CB8A, gen(edu_levelthisy_raw_decode)

	cap clonevar edu_levelthisy = CB8A
	cap replace edu_levelthisy = . if edu_levelthisy >= 8

	* this year, grade
	fre CB8B
		// Obtain info from hl.dta 
		replace CB8B = ED10B if CB8B == . 
		
	clonevar edu_gradethisy_raw_CB8B_ED10B = CB8B
	
	decode CB8B, gen(edu_gradethisy_raw_decode)

	clonevar edu_gradethisy = CB8B
	replace edu_gradethisy = . if edu_gradethisy >= 20 

	* last year, enrollment
	fre CB9
		// Obtain info from hl.dta 
		replace CB9 = ED15 if CB9 == . 
		
	clonevar edu_enrollasty_raw_CB9_ED15 = CB9 
	decode CB9, gen(edu_enrollasty_raw_decode)
	
	recode CB9 (1=1) (2=0) (3/999=.), gen(edu_enrollasty)
	la var edu_enrollasty "Enrolled last school year"

	* last year, level
	cap fre CB10A
		// Obtain info from hl.dta 
		cap replace CB10A = ED16A if CB10A == . 

	cap clonevar edu_levellasty_raw_CB10A_ED16A = CB10A
	cap decode CB10A, gen(edu_levellasty_raw_decode) 

	cap clonevar edu_levellasty = CB10A
	cap replace edu_levellasty = . if edu_levellasty >= 8

	* last year, grade
	fre CB10B
		// Obtain info from hl.dta 
		replace CB10B = ED16B if CB10B == . 

	clonevar edu_gradelasty_raw_CB10B_ED16B = CB10B
	
	decode CB10B, gen(edu_gradelasty_raw_decode)

	clonevar edu_gradelasty = CB10B
	replace edu_gradelasty = . if edu_gradelasty >= 20 

end 



/*
/* construct data for each country and append 
*********************************************************/

foreach countryfile in ///
"BGD2019" ///
"NPL2019" ///
"PKB2019" ///
"PKK2019" ///
"PKP2017" ///
"PKS2018" ///
"MNG2018" ///
"T172019" ///
"THA2019" ///
"KGZ2018" ///
"TKM2019" ///
{
	u "$dir_rawdata\mics\\`countryfile'_fs", clear
	gen countryfile = "`countryfile'", before(HH1)
	edu_var 
	sa "$dir_tempdata\mics_fs\\`countryfile'", replace
}
*/



********************************************************************************
* uniform across-country year of education 
********************************************************************************
/* each country has different education system, check what is level and grade. 
*/

cap program drop levelgrade
program define levelgrade

	fre edu_levelhighest
	fre edu_gradehighest
	fre edu_gradehighest if edu_levelhighest == 0

	fre edu_levellasty
	fre edu_gradelasty
	fre edu_gradelasty if edu_levellasty == 0

	fre edu_levelthisy
	fre edu_gradethisy
	fre edu_gradethisy if edu_levelthisy == 0

	* level and grade of that level 
	tab edu_levelhighest edu_gradehighest 
	tab edu_levellasty edu_gradelasty
	tab edu_levelthisy edu_gradethisy

end

cap program drop yoelabel
program define yoelabel
	la var edu_yoe_highest "Year of educaiton ever attended"
	la var edu_yoe_lasty "Year of education attended in last school year"
	la var edu_yoe_thisy "Year of education attended in this school year"
end




*** BGD2019 ***********************************************************
local countryfile = "BGD2019"
// u "$dir_rawdata\mics\\`countryfile'_fs", clear

	u "$dir_rawdata\\mics\\`countryfile'_hl", clear
	rename HL1 LN
	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3

gen countryfile = "`countryfile'", before(HH1)
edu_var 

levelgrade


/*
gen edu_yoe_highest = edu_gradehighest
la var edu_yoe_highest "Year of educaiton ever attended"

gen edu_yoe_lasty = edu_gradelasty
la var edu_yoe_lasty "Year of education attended in last school year"

gen edu_yoe_thisy = edu_gradethisy
la var edu_yoe_thisy "Year of education attended in this school year"
*/


* year of education, generated from level and grade attended 
foreach i in "highest" "lasty" "thisy" {
	gen edu_yoe_`i' = . 
	replace edu_yoe_`i' = 0 if edu_level`i' == 0
	replace edu_yoe_`i' = edu_grade`i' if inlist(edu_level`i', 1,2,3,4)
}


keep countryfile HH1 HH2 LN edu_*
sa "$dir_tempdata\mics_fs\\`countryfile'", replace 






*** KGZ2018 ***********************************************************
local countryfile = "KGZ2018"
// u "$dir_rawdata\mics\\`countryfile'_fs", clear

	u "$dir_rawdata\\mics\\`countryfile'_hl", clear
	rename HL1 LN
	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3
	
gen countryfile = "`countryfile'", before(HH1)
edu_var 

levelgrade

// tab CB3 edu_gradethisy if edu_levelthisy == 4
fre edu_levelhighest
/*
gen edu_yoe_highest = . 
replace edu_yoe_highest = edu_gradehighest if inlist(edu_levelhighest, 0, 1, 2, 3)
replace edu_yoe_highest = 11 + edu_gradehighest if inlist(edu_levelhighest, 5)
replace edu_yoe_highest = 9 + edu_gradehighest if inlist(edu_levelhighest, 4)
la var edu_yoe_highest "Year of educaiton ever attended"
*/


* year of education, generated from highest level and grade attended 
foreach i in "highest" "lasty" "thisy" {
	gen edu_yoe_`i' = . 
	replace edu_yoe_`i' = 0 if inlist(edu_level`i', 0)
	replace edu_yoe_`i' = edu_grade`i' if inlist(edu_level`i', 1, 2, 3)
	replace edu_yoe_`i' = 9 + edu_grade`i' if inlist(edu_level`i', 4)
	replace edu_yoe_`i' = 11 + edu_grade`i' if inlist(edu_level`i', 5)
}

// tab edu_yoe_highest edu_levelhighest


keep countryfile HH1 HH2 LN edu_*
sa "$dir_tempdata\mics_fs\\`countryfile'", replace 




*** MNG2018 ***********************************************************
local countryfile = "MNG2018"
// u "$dir_rawdata\mics\\`countryfile'_fs", clear

	u "$dir_rawdata\\mics\\`countryfile'_hl", clear
	rename HL1 LN
	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3
	
gen countryfile = "`countryfile'", before(HH1)
edu_var 

levelgrade

// tab CB3 edu_gradethisy if edu_levelthisy == 4
fre edu_levelhighest


* year of education, generated from highest level and grade attended 
foreach i in "highest" "lasty" "thisy" {
	gen edu_yoe_`i' = . 
	replace edu_yoe_`i' = 0 if inlist(edu_level`i', 0)
	replace edu_yoe_`i' = edu_grade`i' if inlist(edu_level`i', 1)
	replace edu_yoe_`i' = 9 + edu_grade`i' if inlist(edu_level`i', 3)
	replace edu_yoe_`i' = 12 + edu_grade`i' if inlist(edu_level`i', 4)
}

tab edu_yoe_highest edu_levelhighest

keep countryfile HH1 HH2 LN edu_*
sa "$dir_tempdata\mics_fs\\`countryfile'", replace 



*** NPL2019 ***********************************************************
local countryfile = "NPL2019"
// u "$dir_rawdata\mics\\`countryfile'_fs", clear

	u "$dir_rawdata\\mics\\`countryfile'_hl", clear
	rename HL1 LN
	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3
	
gen countryfile = "`countryfile'", before(HH1)
edu_var 

// levelgrade
tab CB3 edu_gradethisy 
tab CB3 edu_gradehighest
fre edu_gradehighest edu_gradelasty edu_gradethisy
tab edu_gradelasty edu_gradethisy

* year of education, generated from highest level and grade attended 
foreach i in "highest" "lasty" "thisy" {
	gen edu_yoe_`i' = .
	replace edu_yoe_`i' = 0 if edu_grade`i' == 0 
	replace edu_yoe_`i' = edu_grade`i' if edu_grade`i' != 0 
	replace edu_yoe_`i' = . if edu_grade`i' == 99 
}


keep countryfile HH1 HH2 LN edu_*
sa "$dir_tempdata\mics_fs\\`countryfile'", replace 




*** TKM2019 ***********************************************************
local countryfile = "TKM2019"
// u "$dir_rawdata\mics\\`countryfile'_fs", clear

	u "$dir_rawdata\\mics\\`countryfile'_hl", clear
	rename HL1 LN
	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3
	
gen countryfile = "`countryfile'", before(HH1)
edu_var 

levelgrade

tab CB3 edu_levelhighest if inlist(edu_levelhighest, 2,3,4)
tab CB3 edu_levellasty if inlist(edu_levellasty, 2,3,4)
tab CB3 edu_levelthisy if inlist(edu_levelthisy, 2,3,4)


* year of education, generated from highest level and grade attended 
foreach i in "highest" "lasty" "thisy" {
	gen edu_yoe_`i' = .
	replace edu_yoe_`i' = 0 if edu_level`i' == 0 
	replace edu_yoe_`i' = edu_grade`i' if edu_level`i' == 1 & inrange(edu_grade`i', 1, 11)
	replace edu_yoe_`i' = 12 if inlist(edu_level`i', 2,3,4)
	replace edu_yoe_`i' = . if edu_yoe_`i' > 90
}


keep countryfile HH1 HH2 LN edu_*
sa "$dir_tempdata\mics_fs\\`countryfile'", replace 




*** PAKISTAN ***********************************************************
*** how to generate years of education *********************************

cap program drop levelgrade_pak 
program define levelgrade_pak

tab CB3 if edu_levelhighest == 2 & edu_gradehighest == 6
tab CB3 if edu_levelhighest == 3 & edu_gradehighest > 4
tab CB3 if edu_levellasty == 3 & edu_gradelasty > 4
tab CB3 edu_gradehighest if edu_levelhighest == 4

end

cap program drop findyoe 
program define findyoe

* year of education, generated from highest level and grade attended 
foreach i in "highest" "lasty" "thisy" {
	gen edu_yoe_`i' = .
	replace edu_yoe_`i' = 0 if edu_level`i' == 0 
	replace edu_yoe_`i' = edu_grade`i' if edu_level`i' == 1 
	
	replace edu_yoe_`i' = 5 + edu_grade`i' if edu_level`i' == 2 & edu_grade`i' <= 3
	replace edu_yoe_`i' = 5 if edu_level`i' == 2 & edu_grade`i' == 4
	replace edu_yoe_`i' = 5 if edu_level`i' == 2 & edu_grade`i' == 5
	replace edu_yoe_`i' = 6 if edu_level`i' == 2 & edu_grade`i' == 6 
	replace edu_yoe_`i' = 7	if edu_level`i' == 2 & edu_grade`i' == 7 
	
	replace edu_yoe_`i' = 8 + edu_grade`i' if edu_level`i' == 3 & edu_grade`i' <= 4 
	replace edu_yoe_`i' = 12 if edu_level`i' == 3 & inrange(edu_grade`i', 5, 10)
	
	replace edu_yoe_`i' = 13 if edu_level`i' == 4 
	
	replace edu_yoe_`i' = . if edu_yoe_`i' > 90
}

end 

*** PKB2019 ***********************************************************
local countryfile = "PKB2019"
// u "$dir_rawdata\mics\\`countryfile'_fs", clear

	u "$dir_rawdata\\mics\\`countryfile'_hl", clear
	rename HL1 LN
	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3
	
gen countryfile = "`countryfile'", before(HH1)
edu_var 

******************************************************************************************************
******************************************************************************************************
/*
levelgrade
*/

findyoe

keep countryfile HH1 HH2 LN edu_*
sa "$dir_tempdata\mics_fs\\`countryfile'", replace 



*** PKK2019 ***********************************************************
local countryfile = "PKK2019"
// u "$dir_rawdata\mics\\`countryfile'_fs", clear

	u "$dir_rawdata\\mics\\`countryfile'_hl", clear
	rename HL1 LN
	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3
	
gen countryfile = "`countryfile'", before(HH1)
edu_var 
******************************************************************************************************
******************************************************************************************************
/*
levelgrade

tab CB3 edu_gradehighest if edu_levelhighest == 2 & edu_gradehighest > 3
/* age 12, lower secondary, grade 6. This child should be in grade 1 for lower secondary. 
*/

*/

findyoe

keep countryfile HH1 HH2 LN edu_*
sa "$dir_tempdata\mics_fs\\`countryfile'", replace 



*** PKP2017 ***********************************************************
local countryfile = "PKP2017"
// u "$dir_rawdata\mics\\`countryfile'_fs", clear

	u "$dir_rawdata\\mics\\`countryfile'_hl", clear
	rename HL1 LN
	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3
	
gen countryfile = "`countryfile'", before(HH1)
edu_var 
******************************************************************************************************
******************************************************************************************************
/*
levelgrade
*/

findyoe

keep countryfile HH1 HH2 LN edu_*
sa "$dir_tempdata\mics_fs\\`countryfile'", replace 



*** PKS2018 ***********************************************************
local countryfile = "PKS2018"
// u "$dir_rawdata\mics\\`countryfile'_fs", clear

	u "$dir_rawdata\\mics\\`countryfile'_hl", clear
	rename HL1 LN
	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3
	
gen countryfile = "`countryfile'", before(HH1)
edu_var 
******************************************************************************************************
******************************************************************************************************
/*
levelgrade

tab CB3 edu_gradehighest if edu_levelhighest == 2 & edu_gradehighest > 3
/* 
             |    Highest grade attended at that level
Age of child |         4          5          6          7 |     Total
-------------+--------------------------------------------+----------
          10 |         1          0          0          0 |         1 ===> 5 yoe
          12 |         0          1          0          1 |         2 ===> 5 yoe
          13 |         0          0          2          1 |         3 ===> 6, 7 yoe
          14 |         0          0          0          1 |         1 ===> 7 yoe
          15 |         0          0          1          0 |         1 ===> 6 yoe 
          16 |         0          0          1          0 |         1 ===> 6 yoe 
-------------+--------------------------------------------+----------
       Total |         1          1          4          3 |         9 

*/

*/

findyoe

keep countryfile HH1 HH2 LN edu_*
sa "$dir_tempdata\mics_fs\\`countryfile'", replace 







*** THAILAND ***********************************************************
*** how to generate years of education *********************************

cap program drop findyoe 
program define findyoe

* year of education, generated from highest level and grade attended 
foreach i in "highest" "lasty" "thisy" {
	gen edu_yoe_`i' = .
	replace edu_yoe_`i' = 0 if edu_level`i' == 0 
	replace edu_yoe_`i' = edu_grade`i' if edu_level`i' == 1 
	
	replace edu_yoe_`i' = 6 + edu_grade`i' if edu_level`i' == 2 & inlist(edu_grade`i', 1, 2, 3)
	replace edu_yoe_`i' = 6 + edu_grade`i' if edu_level`i' == 3 & inlist(edu_grade`i', 4, 5, 6)
	replace edu_yoe_`i' = 9 if edu_level`i' == 4
	
	replace edu_yoe_`i' = . if edu_yoe_`i' > 90
}

end 

*** T172019 ***********************************************************
local countryfile = "T172019"
// u "$dir_rawdata\mics\\`countryfile'_fs", clear

	u "$dir_rawdata\\mics\\`countryfile'_hl", clear
	rename HL1 LN
	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3
	
gen countryfile = "`countryfile'", before(HH1)
edu_var 

******************************************************************************************************
******************************************************************************************************
levelgrade

findyoe

tab edu_yoe_highest edu_levelhighest

keep countryfile HH1 HH2 LN edu_*
sa "$dir_tempdata\mics_fs\\`countryfile'", replace 



*** THA2019 ***********************************************************
local countryfile = "THA2019"
// u "$dir_rawdata\mics\\`countryfile'_fs", clear

	u "$dir_rawdata\\mics\\`countryfile'_hl", clear
	rename HL1 LN
	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3
	
gen countryfile = "`countryfile'", before(HH1)
edu_var 
******************************************************************************************************
******************************************************************************************************
levelgrade

tab CB3 edu_gradethisy if edu_levelthisy == 4

findyoe

tab edu_yoe_highest edu_levelhighest

keep countryfile HH1 HH2 LN edu_*
sa "$dir_tempdata\mics_fs\\`countryfile'", replace 




********************************************************************************
********************************************************************************
********************** append data files ***************************************


u "$dir_tempdata\mics_fs\BGD2019", clear

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
	append using "$dir_tempdata\mics_fs\\`i'"
}

yoelabel 

label drop _all
duplicates report countryfile HH1 HH2 LN


// merge 1:1 countryfile HH1 HH2 LN using "$dir_data\230_mics_child"
merge 1:1 countryfile HH1 HH2 LN using "$dir_data\id_key_file\mics_child_id"
keep if _merge == 3
drop _merge
order RDSE_loc_id countryfile HH1 HH2 LN moLN faLN ISO_alpha_3, first

/* save and test ********************/

sa "$dir_tempdata\230_mics_child_edu", replace 






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













