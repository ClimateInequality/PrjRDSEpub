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

log using "$dir_log\234_mics_pa_edu_$today.log", replace



efolder apple, cd("$dir_tempdata")
cd "$dir_program"

// cap ssc install elabel 


********************************************************************************
* TASK: MICS household/parental information file 
********************************************************************************

/*
https://github.com/ClimateInequality/PrjRDSE/issues/4
*/

/*******************************************************************************

* MODULE 1. Mother education, father education, household head education 

***************************************************************************************************************/
/* In hl.dta, each row is one member in household. 
There is melevel, felevel, helevel showing mother education, father education, and household head education, so we can directly obtain this by merge using line number of child. 

There are also other variables on education, for them, use mother's linenumber in mics_child_id.dta file and linenumber variable in hl.dta file to merge, to fine information for mother. Do the same for father. 
*/




/*******************************************************************************

* MODULE 1.0. Use melevel, felevel, helevel, to directly find parental education 

*******************************************************************************/
/* 
This may not be ideal, as in official questionnaire, we cannot find how melevel and felevel are coded. Probably they come from the education information of person MLINE and FLINE. 
MLINE (mother line number) is mother or primary caretaker's line number. Not purely natural mother line number. 

WARNING: This is included in MODULE 1.0, so do not need to worry about this now. 
*/

/*

	cap program drop elevelmerge 
	program define elevelmerge 

	args countryfile 

	local countryfile = "BGD2019"

		u "$dir_rawdata\mics\\`countryfile'_fs", clear
		gen countryfile = "`countryfile'"
		keep countryfile HH1 HH2 LN melevel 
	// 	rename melevel melevel_fs 

		u "$dir_rawdata\mics\\`countryfile'_hl", clear
		gen countryfile = "`countryfile'"
		rename HL1 LN
		
		merge 1:1 countryfile HH1 HH2 LN using "$dir_data\id_key_file\mics_child_id"
		keep if _merge == 3
		drop _merge 

		fre melevel felevel helevel 
		keep countryfile HH1 HH2 HL1 melevel felevel helevel
	// 	rename melevel melevel_hl
	// 	rename felevel felevel_hl
	// 	rename helevel helevel_hl

		
		clonevar mo_elevel_raw = melevel // raw variable
		decode melevel, gen(mo_elevel_raw_decode) // raw variable string label 
		clonevar mo_elevel = melevel
		la var mo_elevel "Mother education"

		clonevar fa_elevel_raw = felevel // raw variable
		decode felevel, gen(fa_elevel_raw_decode) // raw variable string label 
		clonevar fa_elevel = felevel
		la var fa_elevel "Father education"

		clonevar head_elevel_raw = helevel // raw variable
		decode helevel, gen(head_elevel_raw_decode) // raw variable string label 
		clonevar head_elevel = helevel
		la var head_elevel "HH head education"

		drop melevel felevel helevel

	// 	sa "$dir_tempdata\apple\\`countryfile'", replace

	end 



	********************************************************
	elevelmerge BGD2019

	*** missing/DK to missing value 
	replace mo_elevel = . if inlist(mo_elevel_raw, 9)
	replace fa_elevel = . if inlist(fa_elevel_raw, 5, 9)
	replace head_elevel = . if inlist(head_elevel_raw, 9)

	local countryfile = "BGD2019"
	sa "$dir_tempdata\apple\\`countryfile'", replace



	********************************************************
	elevelmerge KGZ2018

	*** missing/DK to missing value 
	replace mo_elevel = . if inlist(mo_elevel_raw, 7)
	replace fa_elevel = . if inlist(fa_elevel_raw, 7)
	// replace head_elevel = . if inlist(head_elevel_raw, 9)

	local countryfile = "KGZ2018"
	sa "$dir_tempdata\apple\\`countryfile'", replace



	********************************************************
	elevelmerge MNG2018

	*** no information, missing/DK to missing value 
	replace mo_elevel = . if inlist(mo_elevel_raw, 7, 9)
	replace fa_elevel = . if inlist(fa_elevel_raw, 7, 9)
	replace head_elevel = . if inlist(head_elevel_raw, 9)

	local countryfile = "MNG2018"
	sa "$dir_tempdata\apple\\`countryfile'", replace



	********************************************************
	// elevelmerge NPL2019
	// cannot work 

	local countryfile = "NPL2019"

		u "$dir_rawdata\mics\\`countryfile'_hl", clear
		gen countryfile = "`countryfile'"
		
	// 	fre ED4 ED4A ED5A ED10A ED16A helevel1 helevel2 melevel2 melevel1 melevel2 felevel1 felevel2
		
		fre melevel* felevel* helevel* 
		keep countryfile HH1 HH2 HL1 melevel* felevel* helevel* 
		rename HL1 LN
		merge 1:1 countryfile HH1 HH2 LN using "$dir_data\id_key_file\mics_child_id"
		keep if _merge == 3
		drop _merge 
		
		drop *elevel1
		rename *elevel2 *elevel
		
		clonevar mo_elevel_raw = melevel // raw variable
		decode melevel, gen(mo_elevel_raw_decode) // raw variable string label 
		clonevar mo_elevel = melevel
		la var mo_elevel "Mother education"

		clonevar fa_elevel_raw = felevel // raw variable
		decode felevel, gen(fa_elevel_raw_decode) // raw variable string label 
		clonevar fa_elevel = felevel
		la var fa_elevel "Father education"

		clonevar head_elevel_raw = helevel // raw variable
		decode helevel, gen(head_elevel_raw_decode) // raw variable string label 
		clonevar head_elevel = helevel
		la var head_elevel "HH head education"

		drop melevel felevel helevel

	*** missing/DK to missing value 
	// replace mo_elevel = . if inlist(mo_elevel_raw, 7)
	replace fa_elevel = . if inlist(fa_elevel_raw, 9, 10)
	replace head_elevel = . if inlist(head_elevel_raw, 9)

	local countryfile = "NPL2019"
	sa "$dir_tempdata\apple\\`countryfile'", replace



	********************************************************
	elevelmerge PKB2019

	*** biological father not in the household, missing/DK to missing value 
	replace mo_elevel = . if mo_elevel_raw >= 5
	replace fa_elevel = . if fa_elevel_raw >= 5
	replace head_elevel = . if head_elevel_raw >= 5

	local countryfile = "PKB2019"
	sa "$dir_tempdata\apple\\`countryfile'", replace



	********************************************************
	elevelmerge PKK2019

	*** biological father not in the household, missing/DK to missing value 
	replace mo_elevel = . if mo_elevel_raw >= 5
	replace fa_elevel = . if fa_elevel_raw >= 5
	replace head_elevel = . if head_elevel_raw >= 5

	local countryfile = "PKK2019"
	sa "$dir_tempdata\apple\\`countryfile'", replace



	********************************************************
	elevelmerge PKP2017

	*** biological father not in the household, missing/DK to missing value 
	replace mo_elevel = . if mo_elevel_raw >= 5
	replace fa_elevel = . if fa_elevel_raw >= 5
	replace head_elevel = . if head_elevel_raw >= 5

	local countryfile = "PKP2017"
	sa "$dir_tempdata\apple\\`countryfile'", replace



	********************************************************
	elevelmerge PKS2018

	*** biological father not in the household, missing/DK to missing value 
	replace mo_elevel = . if mo_elevel_raw >= 5
	replace fa_elevel = . if fa_elevel_raw >= 5
	replace head_elevel = . if head_elevel_raw >= 5

	local countryfile = "PKS2018"
	sa "$dir_tempdata\apple\\`countryfile'", replace



	********************************************************
	elevelmerge T172019

	*** biological father not in the household, missing/DK to missing value 
	replace mo_elevel = . if mo_elevel_raw >= 5
	replace fa_elevel = . if fa_elevel_raw >= 5
	replace head_elevel = . if head_elevel_raw >= 5

	local countryfile = "T172019"
	sa "$dir_tempdata\apple\\`countryfile'", replace



	********************************************************
	elevelmerge THA2019

	*** biological father not in the household, missing/DK to missing value 
	replace mo_elevel = . if mo_elevel_raw >= 5
	replace fa_elevel = . if fa_elevel_raw >= 5
	replace head_elevel = . if head_elevel_raw >= 5

	local countryfile = "THA2019"
	sa "$dir_tempdata\apple\\`countryfile'", replace



	********************************************************
	elevelmerge TKM2019

	*** biological father not in the household, missing/DK to missing value 
	replace mo_elevel = . if mo_elevel_raw >= 5
	replace fa_elevel = . if fa_elevel_raw >= 5
	replace head_elevel = . if head_elevel_raw >= 5

	local countryfile = "TKM2019"
	sa "$dir_tempdata\apple\\`countryfile'", replace



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

	duplicates report countryfile HH1 HH2 LN
	// 174,422 OBS

	merge 1:1 countryfile HH1 HH2 LN using "$dir_data\id_key_file\mics_child_id"
	// keep if _merge == 3
	drop _merge
	order RDSE_loc_id ISO_alpha_3 countryfile HH1 HH2 LN moLN faLN, first

	sa "$dir_tempdata\234_mics_pa_hh_1_1", replace

*/


/*******************************************************************************

* MODULE 1.2. Use ED* group of variable to find edu info of mother / father 

*******************************************************************************/

/* STEP 1. Find original education variable

***************************************************************/

cap program drop elevelmerge 
program define elevelmerge 

args countryfile parentLN
* parentLN should be moLN for mother line number OR faLN for father line number 

	u "$dir_rawdata\mics\\`countryfile'_hl", clear
	gen countryfile = "`countryfile'", before(HH1)
	
	fre ED4 ED5A ED5B ED6
	keep countryfile HH1 HH2 HL1 ED4 ED5A ED5B ED6
	rename HL1 `parentLN'
	merge 1:1 countryfile HH1 HH2 `parentLN' using "$dir_data\id_key_file\mics_child_id"
	keep if _merge == 3
	drop _merge 
	
	*** clone the raw varialbe as *_raw 
	*** store raw variable string label into *_raw_decode 
	*** create new variable to recode in the future 
	clonevar edu_everschool_raw_ED4 = ED4 
	decode ED4, gen(edu_everschool_raw_decode) 
// 	clonevar edu_everschool = ED4
	recode ED4 (1=1) (2=0) (3/999=.), gen(edu_everschool)
	
	clonevar edu_levelhighest_raw_ED5A = ED5A 
	decode ED5A, gen(edu_levelhighest_raw_decode) 
// 	clonevar edu_levelhighest = ED5A
	cap clonevar edu_levelhighest = ED5A
	cap replace edu_levelhighest = . if edu_levelhighest >= 8

	clonevar edu_gradehighest_raw_ED5B = ED5B 
	decode ED5B, gen(edu_gradehighest_raw_decode) 
// 	clonevar edu_gradehighest = ED5B
	clonevar edu_gradehighest = ED5B
	replace edu_gradehighest = . if edu_gradehighest >= 20 

	clonevar edu_complete_raw_ED6 = ED6 
	decode ED6, gen(edu_complete_raw_decode) 
// 	clonevar edu_complete = ED6
	recode ED6 (1=1) (2=0) (3/999=.), gen(edu_complete)

	drop ED4 ED5A ED5B ED6	

end

//	ssc install labutil 
//	ssc install labutil2

cap program drop moLNedulabel
program define moLNedulabel

	la var edu_everschool "ever attend school"
	la var edu_levelhighest "highest level of edu attended"
	la var edu_gradehighest "highest grade attended at that level"
	la var edu_complete "ever completed that grade"
	la var edu_yoe_highest "year of education ever attended"
	
	* mass change variable name and label 
	rename edu_* mo_edu_*
	labvarch mo_edu_*, pref("Mother ")

end 

cap program drop faLNedulabel
program define faLNedulabel

	la var edu_everschool "ever attend school"
	la var edu_levelhighest "highest level of edu attended"
	la var edu_gradehighest "highest grade attended at that level"
	la var edu_complete "ever completed that grade"
	la var edu_yoe_highest "year of education ever attended"

	* mass change variable name and label 	
	rename edu_* fa_edu_*
	labvarch fa_edu_*, pref("Father ")

end 


/* STEP 2. Find year of education for each country 

This part is adopted from 230_mics_child_edu.do. 
For different country, education system is different, and we want to a uniform year of education. 
***************************************************************/

********************************************************
cap program drop findyoe 
program define findyoe 

* this should differ across countries 

tab edu_levelhighest edu_gradehighest 
fre edu_levelhighest edu_gradehighest 
	
foreach i in "highest" {
	gen edu_yoe_`i' = . 
	replace edu_yoe_`i' = 0 if edu_level`i' == 0
	replace edu_yoe_`i' = edu_grade`i' if inlist(edu_level`i', 1,2,3,4)
}

fre edu_yoe_*

end 

local countryfile = "BGD2019"
	
foreach parentLN in "moLN" "faLN" {
	elevelmerge `countryfile' `parentLN'
	findyoe
	`parentLN'edulabel 
	sa "$dir_tempdata\apple\\`countryfile'_`parentLN'", replace
}



********************************************************
cap program drop findyoe 
program define findyoe 

* this should differ across countries 

tab edu_levelhighest edu_gradehighest 
fre edu_levelhighest edu_gradehighest 
	
foreach i in "highest" {
	gen edu_yoe_`i' = . 
	replace edu_yoe_`i' = 0 if inlist(edu_level`i', 0)
	replace edu_yoe_`i' = edu_grade`i' if inlist(edu_level`i', 1, 2, 3)
	replace edu_yoe_`i' = 11 + edu_grade`i' if inlist(edu_level`i', 5)
	replace edu_yoe_`i' = 9 + edu_grade`i' if inlist(edu_level`i', 4)
}

fre edu_yoe_*

end 

local countryfile = "KGZ2018"
	
foreach parentLN in "moLN" "faLN" {
	elevelmerge `countryfile' `parentLN'
	findyoe
	`parentLN'edulabel 
	sa "$dir_tempdata\apple\\`countryfile'_`parentLN'", replace
}



********************************************************
cap program drop findyoe 
program define findyoe 

* this should differ across countries 

tab edu_levelhighest edu_gradehighest 
fre edu_levelhighest edu_gradehighest 
	
foreach i in "highest" {
	gen edu_yoe_`i' = . 
	replace edu_yoe_`i' = 0 if inlist(edu_level`i', 0)
	replace edu_yoe_`i' = edu_grade`i' if inlist(edu_level`i', 1) & edu_grade`i' <= 12 
	replace edu_yoe_`i' = 9 + edu_grade`i' if inlist(edu_level`i', 3) & edu_grade`i' <= 12 
	replace edu_yoe_`i' = 12 + edu_grade`i' if inlist(edu_level`i', 4) & edu_grade`i' <= 12 
	replace edu_yoe_`i' = 16 if inlist(edu_level`i', 21, 22)
	replace edu_yoe_`i' = 20 if inlist(edu_level`i', 30)
}

fre edu_yoe_*

end 

/* 
gradehighest => BACHELORS => 13 years of education. 

gradehighest => MASTER'S FIRST GRADE, MASTER'S SECOND GRADE => all treated as 16 years of education. 

gradehighest => DOCTOR => 20 years of education. 
*/

local countryfile = "MNG2018"
	
foreach parentLN in "moLN" "faLN" {
	elevelmerge `countryfile' `parentLN'
	findyoe
	`parentLN'edulabel 
	sa "$dir_tempdata\apple\\`countryfile'_`parentLN'", replace
}



********************************************************
cap program drop findyoe 
program define findyoe 

* this should differ across countries 

tab edu_levelhighest edu_gradehighest 
fre edu_levelhighest edu_gradehighest 
	
foreach i in "highest" {
	gen edu_yoe_`i' = .
	replace edu_yoe_`i' = 0 if edu_grade`i' == 0 
	replace edu_yoe_`i' = edu_grade`i' if inrange(edu_grade`i', 1, 12) 
	replace edu_yoe_`i' = 13 if edu_grade`i' == 13 
	replace edu_yoe_`i' = 16 if edu_grade`i' == 14
}

fre edu_yoe_*

end 

local countryfile = "NPL2019"
	
foreach parentLN in "moLN" "faLN" {
	elevelmerge `countryfile' `parentLN'
	findyoe
	`parentLN'edulabel 
	sa "$dir_tempdata\apple\\`countryfile'_`parentLN'", replace
}



********************************************************
cap program drop findyoe 
program define findyoe 

* this should differ across countries 

tab edu_levelhighest edu_gradehighest 
fre edu_levelhighest edu_gradehighest 
	
foreach i in "highest" {
	gen edu_yoe_`i' = .
	replace edu_yoe_`i' = 0 if edu_level`i' == 0 
	replace edu_yoe_`i' = edu_grade`i' if edu_level`i' == 1 
	
	replace edu_yoe_`i' = 5 + edu_grade`i' if edu_level`i' == 2 & edu_grade`i' <= 3
	replace edu_yoe_`i' = 5 if edu_level`i' == 2 & edu_grade`i' == 4
	replace edu_yoe_`i' = 5 if edu_level`i' == 2 & edu_grade`i' == 5
	replace edu_yoe_`i' = 6 if edu_level`i' == 2 & edu_grade`i' == 6 
	replace edu_yoe_`i' = 7	if edu_level`i' == 2 & edu_grade`i' == 7 
	
	replace edu_yoe_`i' = 8 + edu_grade`i' if edu_level`i' == 3 & edu_grade`i' <= 4 
	replace edu_yoe_`i' = 12 if edu_level`i' == 3 & inrange(edu_grade`i', 5, 7)
	
	replace edu_yoe_`i' = 12 + edu_grade`i' if edu_level`i' == 4 & inrange(edu_grade`i', 0, 7)
	
	replace edu_yoe_`i' = . if edu_yoe_`i' > 90
}


fre edu_yoe_*

end 

local countryfile = "PKB2019"
	
foreach parentLN in "moLN" "faLN" {
	elevelmerge `countryfile' `parentLN'
	findyoe
	`parentLN'edulabel 
	sa "$dir_tempdata\apple\\`countryfile'_`parentLN'", replace
}



********************************************************
local countryfile = "PKK2019"
	
foreach parentLN in "moLN" "faLN" {
	elevelmerge `countryfile' `parentLN'
	findyoe
	`parentLN'edulabel 
	sa "$dir_tempdata\apple\\`countryfile'_`parentLN'", replace
}



********************************************************
local countryfile = "PKP2017"
	
foreach parentLN in "moLN" "faLN" {
	elevelmerge `countryfile' `parentLN'
	findyoe
	`parentLN'edulabel 
	sa "$dir_tempdata\apple\\`countryfile'_`parentLN'", replace
}



********************************************************
local countryfile = "PKS2018"
	
foreach parentLN in "moLN" "faLN" {
	elevelmerge `countryfile' `parentLN'
	findyoe
	`parentLN'edulabel 
	sa "$dir_tempdata\apple\\`countryfile'_`parentLN'", replace
}



********************************************************
cap program drop findyoe 
program define findyoe 

* this should differ across countries 

tab edu_levelhighest edu_gradehighest 
fre edu_levelhighest edu_gradehighest 
	
foreach i in "highest" {
	gen edu_yoe_`i' = .
	replace edu_yoe_`i' = 0 if edu_level`i' == 0 
	replace edu_yoe_`i' = edu_grade`i' if edu_level`i' == 1 
	
	replace edu_yoe_`i' = 6 + edu_grade`i' if edu_level`i' == 2 & inlist(edu_grade`i', 1, 2, 3)
	replace edu_yoe_`i' = 6 + edu_grade`i' if edu_level`i' == 3 & inlist(edu_grade`i', 4, 5, 6)
	replace edu_yoe_`i' = 9 + edu_grade`i' if edu_level`i' == 4 & inlist(edu_grade`i', 1,2,3)
	replace edu_yoe_`i' = 12 + edu_grade`i' if edu_level`i' == 5 & inlist(edu_grade`i', 1,2)
	replace edu_yoe_`i' = 12 + edu_grade`i' if edu_level`i' == 6 & inlist(edu_grade`i', 1,2,3,4,5,6)
	replace edu_yoe_`i' = 16 + edu_grade`i' if edu_level`i' == 7 & inlist(edu_grade`i', 1,2)
	replace edu_yoe_`i' = 20 if edu_level`i' == 8
	
	replace edu_yoe_`i' = . if edu_yoe_`i' > 90
}

fre edu_yoe_*

end 

local countryfile = "T172019"
	
foreach parentLN in "moLN" "faLN" {
	elevelmerge `countryfile' `parentLN'
	findyoe
	`parentLN'edulabel 
	sa "$dir_tempdata\apple\\`countryfile'_`parentLN'", replace
}



********************************************************
local countryfile = "THA2019"
	
foreach parentLN in "moLN" "faLN" {
	elevelmerge `countryfile' `parentLN'
	findyoe
	`parentLN'edulabel 
	sa "$dir_tempdata\apple\\`countryfile'_`parentLN'", replace
}



********************************************************
cap program drop findyoe 
program define findyoe 

* this should differ across countries 

tab edu_levelhighest edu_gradehighest 
fre edu_levelhighest edu_gradehighest 
	
foreach i in "highest" {
	gen edu_yoe_`i' = .
	replace edu_yoe_`i' = 0 if edu_level`i' == 0 
	replace edu_yoe_`i' = edu_grade`i' if edu_level`i' == 1 & inrange(edu_grade`i', 1, 11)
	replace edu_yoe_`i' = 11 + edu_grade`i' if edu_level`i' == 2 & inlist(edu_grade`i', 1,2)
	replace edu_yoe_`i' = 13 + edu_grade`i' if edu_level`i' == 3 & inlist(edu_grade`i', 1,2,3,4)
	replace edu_yoe_`i' = 11 + edu_grade`i' if edu_level`i' == 4 & inlist(edu_grade`i', 1,2,3,4,5,6)
	replace edu_yoe_`i' = . if edu_yoe_`i' > 90
}

fre edu_yoe_*

end 

local countryfile = "TKM2019"
	
foreach parentLN in "moLN" "faLN" {
	elevelmerge `countryfile' `parentLN'
	findyoe
	`parentLN'edulabel 
	sa "$dir_tempdata\apple\\`countryfile'_`parentLN'", replace
}



/* Append data and merge with kid identifier file ******* MOTHER 
********************************************************/
local parentLN = "moLN"

u "$dir_tempdata\apple\BGD2019_`parentLN'", clear

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
	append using "$dir_tempdata\apple\\`i'_`parentLN'"
}

duplicates report countryfile HH1 HH2 LN
// 157,484 OBS


merge 1:1 countryfile HH1 HH2 `parentLN' using "$dir_data\id_key_file\mics_child_id"
// keep if _merge == 3
drop _merge
order RDSE_loc_id ISO_alpha_3 countryfile HH1 HH2 LN moLN faLN, first

sa "$dir_tempdata\234_mics_pa_hh_1_2_`parentLN'", replace


/* Append data and merge with kid identifier file ******* FATHER 
********************************************************/
local parentLN = "faLN"

u "$dir_tempdata\apple\BGD2019_`parentLN'", clear

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
	append using "$dir_tempdata\apple\\`i'_`parentLN'"
}

duplicates report countryfile HH1 HH2 LN
// 139,927 OBS


merge 1:1 countryfile HH1 HH2 `parentLN' using "$dir_data\id_key_file\mics_child_id"
// keep if _merge == 3
drop _merge
order RDSE_loc_id ISO_alpha_3 countryfile HH1 HH2 LN moLN faLN, first

sa "$dir_tempdata\234_mics_pa_hh_1_2_`parentLN'", replace







/*******************************************************************************

* MODULE 1.3. Use melevel, from fs.dta; melevel and felevel from hl.dta

*******************************************************************************/

/* 
In children 5-17 raw data, which is fs.dta, each obs is one child, and there is a var melevel. There is no felevel. 
We do not know how they construct the var as there is no question recording "mother education" or "father education" in children 5-17 questionnaire. 
In household individual raw data, hl.dta, each obs is one individual in household. 
Earlier, I believe melevel in fs.dta are obtained from hl.dta, so only use melevel and felevel in hl.dta. 
However, it seems that melevel from fs.dta can be different from melevel from hl.dta. 
So, I want to keep them all and compare. 
*/

cap program drop elevelmerge_TEST
program define elevelmerge_TEST

args countryfile 

// local countryfile = "BGD2019"

	u "$dir_rawdata\mics\\`countryfile'_hl", clear
	gen countryfile = "`countryfile'"
	fre melevel felevel helevel 
// 	keep countryfile HH1 HH2 HL1 melevel felevel helevel
	keep countryfile HH1 HH2 HL1 melevel felevel 
	rename HL1 LN
	rename melevel melevel_hl
	rename felevel felevel_hl
// 	rename helevel helevel_hl // Do not need hh head education 

	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3
	drop _merge 

	keep countryfile HH1 HH2 LN melevel* felevel* 
	rename melevel melevel_fs
	
	fre *elevel* 
	
	foreach i in "hl" "fs" {
		decode melevel_`i' , gen(mo_elevel_raw_decode_`i') // raw variable string label 
		rename melevel_`i' mo_elevel_raw_`i' // raw variable
	}
	
	foreach i in "hl" {
		decode felevel_`i', gen(fa_elevel_raw_decode_`i') // raw variable string label 
		rename felevel_`i' fa_elevel_raw_`i' // raw variable
	}
	
/*
	*** Rename value label by adding suffix to this single label, the below returns value label name 
	elabel list (mo_elevel_raw_fs)	
	// di "`r(name)'"
	elabel rename `r(name)' lbl_elevel_fs_`countryfile', nomemory

	elabel list (mo_elevel_raw_hl)
	elabel rename `r(name)' lbl_elevel_hl_`countryfile', nomemory

	*** Add suffix to all labels in this data 
	// elabel rename * *_`countryfile', nomemory	
*/
	
	sa "$dir_tempdata\apple\\`countryfile'", replace

end 

/*------------------------------------------------------------------------------ 

Output: each unit is one child 
Column: 
	(1) identifier 
	(2) country-specific mother education from fs.dta, mother education from hl.dta, father education from hl.dta, each var has value with different label, also another set of var with just string label 
	(3) across-country uniform value and label for melevel_fs, melevel_hl, felevel_hl

STEPS: 

1. For each countryfile: 
	(1) Obtain melevel from hl.dta and merge with fs.dta. 
	(2) Keep only identifiers and melevel_fs, melevel_hl, felevel_hl variables. 
	(3) Decode them, so we have labels remained. 
2. Merge all countryfile. 
3. Create a label capturing all possible labels 
4. Create a variable with numbers associated with those labels

------------------------------------------------------------------------------*/

cap program drop elevelmerge
program define elevelmerge

args countryfile 

	u "$dir_rawdata\mics\\`countryfile'_hl", clear
	gen countryfile = "`countryfile'", before(HH1)
	fre melevel felevel helevel 
	keep countryfile HH1 HH2 HL1 melevel felevel 
	rename HL1 LN
	rename melevel melevel_hl
	rename felevel felevel_hl

	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3
	drop _merge 

	keep countryfile HH1 HH2 LN melevel* felevel* 
	rename melevel melevel_fs
	
	fre *elevel* 
	
	foreach i in "hl" "fs" {
		decode melevel_`i' , gen(mo_elevel_raw_decode_`i') // raw variable string label 
		rename melevel_`i' mo_elevel_raw_`i' // raw variable
	}
	
	foreach i in "hl" {
		decode felevel_`i', gen(fa_elevel_raw_decode_`i') // raw variable string label 
		rename felevel_`i' fa_elevel_raw_`i' // raw variable
	}

	sa "$dir_tempdata\apple\\`countryfile'", replace

end 


********** NPL2019 *********************************

cap program drop elevelmerge_NPL
program define elevelmerge_NPL

local countryfile = "NPL2019"

	u "$dir_rawdata\mics\\`countryfile'_hl", clear
	gen countryfile = "`countryfile'", before(HH1)
	fre melevel* felevel* helevel* 
	keep countryfile HH1 HH2 HL1 melevel2 felevel2 
	rename HL1 LN
	rename melevel2 melevel_hl
	rename felevel2 felevel_hl

	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3
	drop _merge 

	keep countryfile HH1 HH2 LN melevel* felevel* 
	drop melevel1
	rename melevel2 melevel_fs
	
	fre melevel* felevel

	foreach i in "hl" "fs" {
		decode melevel_`i' , gen(mo_elevel_raw_decode_`i') // raw variable string label 
		rename melevel_`i' mo_elevel_raw_`i' // raw variable
	}
	
	foreach i in "hl" {
		decode felevel_`i', gen(fa_elevel_raw_decode_`i') // raw variable string label 
		rename felevel_`i' fa_elevel_raw_`i' // raw variable
	}
	
	sa "$dir_tempdata\apple\\`countryfile'", replace

end

elevelmerge_NPL


********** All other countries *********************************

foreach i in ///
"BGD2019" ///
"KGZ2018" ///
"MNG2018" ///
"PKK2019" ///
"PKP2017" ///
"PKS2018" ///
"T172019" ///
"THA2019" ///
"TKM2019" ///
{
	elevelmerge `i'
}


********** Merge all country files *********************************

u "$dir_tempdata\\apple\\BGD2019"

foreach i in ///
"KGZ2018" ///
"MNG2018" ///
"NPL2019" ///
"PKK2019" ///
"PKP2017" ///
"PKS2018" ///
"T172019" ///
"THA2019" ///
"TKM2019" ///
{
	append using "$dir_tempdata\apple\\`i'"
}



*********** Create a label capturing all possible labels **********

/*
cap elabel drop lbl_allcountry_mo_elevel_raw_decode_hl
elabel define lbl_elevel_allcountry 99 "No meaning"
// local j = "   Lower Basic (Gr 1-5)"
// elabel define lbl_elevel_allcountry 1 "`j'", modify
local i = 1
levelsof mo_elevel_raw_decode_hl, local(levels) 
foreach j of local levels {
	di "`j'"
	elabel define lbl_allcountry_mo_elevel_raw_decode_hl `i' "`j'", modify
	local i = `i' + 1
}

elabel list lbl_allcountry_mo_elevel_raw_decode_hl
*/


*** Create this for melevel in fs and hl, felevel in fs to check if they are indeed using same label
/*
It turns out that label for below three variables are different. 
*/

foreach var in "mo_elevel_raw_decode_fs" "mo_elevel_raw_decode_hl" "fa_elevel_raw_decode_hl" {
	
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

}

*********** Create a variable with numbers **********

/*
gen mo_elevel_raw_decode_hl_NUM = . 

local i = 1
levelsof mo_elevel_raw_decode_hl, local(levels) 
foreach j of local levels {
	replace mo_elevel_raw_decode_hl_NUM = `i' if mo_elevel_raw_decode_hl == "`j'"
	local i = `i' + 1
}

fre mo_elevel_raw_decode_hl_NUM 
fre mo_elevel_raw_decode_hl
* Good, they match!
*/

foreach var in "mo_elevel_raw_decode_fs" "mo_elevel_raw_decode_hl" "fa_elevel_raw_decode_hl" {
	
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



merge 1:1 countryfile HH1 HH2 LN using "$dir_data\id_key_file\mics_child_id"
keep if _merge == 3
drop _merge
order RDSE_loc_id ISO_alpha_3 countryfile HH1 HH2 LN moLN faLN, first

sa "$dir_tempdata\234_mics_pa_hh_1_3", replace



/*******************************************************************************

* MODULE 2. Choose files to merge and keep as final parents education variable

*******************************************************************************/

/*

u "$dir_tempdata\234_mics_pa_hh_1_2_moLN", clear
merge 1:1 countryfile HH1 HH2 LN using "$dir_tempdata\234_mics_pa_hh_1_2_faLN"
drop _merge 

merge 1:1 countryfile HH1 HH2 LN using "$dir_tempdata\234_mics_pa_hh_1_1"
drop _merge

sa "$dir_tempdata\234_mics_pa_edu", replace
*/


// erase "$dir_tempdata\234_mics_pa_hh_1_1.dta"
// erase "$dir_tempdata\234_mics_pa_hh_1_2_moLN.dta"
// erase "$dir_tempdata\234_mics_pa_hh_1_2_faLN.dta"

u "$dir_tempdata\234_mics_pa_hh_1_2_moLN", clear
merge 1:1 countryfile HH1 HH2 LN using "$dir_tempdata\234_mics_pa_hh_1_2_faLN"
drop _merge 
merge 1:1 countryfile HH1 HH2 LN using "$dir_tempdata\234_mics_pa_hh_1_3"
drop _merge 

sa "$dir_tempdata\234_mics_pa_edu", replace















