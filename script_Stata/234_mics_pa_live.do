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

log using "$dir_log\234_mics_pa_live_$today.log", replace



efolder apple, cd("$dir_tempdata")
cd "$dir_program"

********************************************************************************
* TASK: MICS household/parental information file 
********************************************************************************

/*
https://github.com/ClimateInequality/PrjRDSE/issues/4
*/


/*******************************************************************************

* MODULE 3. Cohabitation with parents

***************************************************************************************************************/
/* We want to know who child is living with. 


MICS6 Household Questionnaire 20200617.docx 

HL2. First, please tell me the name of each person who usually lives here, starting with the head of the household.

HL12. Is (name)'s natural mother alive?
HL13. Does (name)'s natural mother live in this household?
HL15. Where does (name)'s natural mother live?
1 ABROAD
2 IN ANOTHER HOUSEHOLD IN THE SAME REGION
3 IN ANOTHER HOUSEHOLD IN ANOTHER REGION
4 INSTITUTION IN THIS COUNTRY
8 DK	

According to HL12, HL13, if natural mother is alive and lives in household, then, HL14 - Record the line number of mother. 

HL16. Is (name)'s natural father alive?
HL17. Does (name)'s natural father live in this household?		
HL19. Where does (name)'s natural father live?
1 ABROAD
2 IN ANOTHER HOUSEHOLD IN THE SAME REGION
3 IN ANOTHER HOUSEHOLD IN ANOTHER REGION
4 INSTITUTION IN THIS COUNTRY
8 DK

According to HL16, HL17, if natural mother is alive and lives in household, then, HL18 - Record the line number of mother. 

*/


cap program drop findlive 
program define findlive

args countryfile

	u "$dir_rawdata\mics\\`countryfile'_hl", clear
	gen countryfile = "`countryfile'", before(HH1)
	
	keep countryfile HH1 HH2 HL1 HL12 HL13 HL15 HL16 HL17 HL19 
	
	rename HL1 LN
	merge 1:1 countryfile HH1 HH2 LN using "$dir_data\id_key_file\mics_child_id"
	keep if _merge == 3
	drop _merge 
	
	fre HL12 HL13 HL15
	recode HL12 (1=1) (2=0) (8=.) (9=.), gen(mo_alive)
	tab mo_alive HL12
	recode HL13 (1=1) (2=0) (8=.) (9=.), gen(mo_inHH)
	tab mo_inHH HL13
	tab mo_inHH HL12 
	clonevar mo_liveplace = HL15 
	
/*
	replace mo_liveplace = 20 if mo_inHH == 1
	la def labels11 20 "live in household", add
	la val mo_liveplace labels11
	fre mo_liveplace
	
	codebook mo_liveplace
*/

	fre HL16 HL17 HL19 
	recode HL16 (1=1) (2=0) (8=.) (9=.), gen(fa_alive)
	tab fa_alive HL16
	recode HL17 (1=1) (2=0) (8=.) (9=.), gen(fa_inHH)
	tab fa_inHH HL17
	tab fa_inHH HL16 
	clonevar fa_liveplace = HL19 
	
	drop HL12 HL13 HL15 HL16 HL17 HL19 

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
	findlive `i'
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

duplicates report countryfile HH1 HH2 LN


merge 1:1 countryfile HH1 HH2 LN using "$dir_data\id_key_file\mics_child_id"
keep if _merge == 3
drop _merge
order RDSE_loc_id ISO_alpha_3 countryfile HH1 HH2 LN moLN faLN, first

/* In raw data, if mother is not alive, the question on if mother is living in the same household is skipped. 
We want to take this variable as 0 if mother is not alive. 
*/

replace mo_inHH = 0 if mo_alive == 0 
replace fa_inHH = 0 if fa_alive == 0 

bys fa_alive: fre fa_inHH
bys mo_alive: fre mo_inHH

la var mo_alive "Mother is alive"
la var fa_alive "Father is alive"

la var mo_inHH "Mother is living in same HH"
la var fa_inHH "Father is living in same HH"


gen child_live_with_pa = (mo_inHH == 1 & fa_inHH == 1)
la var child_live_with_pa "Child live with both parents in HH"

sa "$dir_tempdata\234_mics_pa_live", replace
















