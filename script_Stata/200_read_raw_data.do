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

global today = 20230706
log using "$dir_log//200_read_raw_data_$today.log", replace



*******************************************************************************
* import dataset 
*******************************************************************************



/* use excel to transfer spss to stata 
*********************************************
*/

cap cd "$dir_mics"

cap ssc install filelist 
filelist, pattern("*.sav") 
// filelist, pattern("*.sav") save("sav_datasets_filename.dta") 

gen filename_sav = dirname + "/" + filename 
gen filename_dta = dirname + "/" + substr(filename, 1, 2) + ".dta"

export delimited using "$dir_proj_note\datasets_filename.csv", replace

/*
In the excel with dir and filenames listed, we can create commands such as 
import spss using "...", clear 
save "...", replace 
Then we can copy that into a .do file, run it to transfer all the files. 
*/


/* use STATA to transfer spss to stata 
*********************************************
*/
cap cd "$dir_mics"

cap ssc install filelist 
filelist, pattern("*.sav") 

gen filename_ = dirname + "/" + substr(filename, 1, 2)

levelsof filename_, local (levels) 
foreach l of local levels {
	import spss using "`l'.sav", clear 
	save "`l'.dta", replace 
}


/*
cap cd "$dir_mics"

cap ssc install filelist 
filelist, pattern("*.sav") 

keep if substr(dirname,3,1) == "T"

gen filename_ = dirname + "/" + substr(filename, 1, 2)

levelsof filename_, local (levels) 
foreach l of local levels {
	import spss using "`l'.sav", clear 
	save "`l'.dta", replace 
}
*/


/*

levelsof dirname, local (levels)
foreach l of local levels {
	di "`l'"
	import spss using "`l'/bh.sav", clear  
	save "`l'/bh.dta", replace 
	
	import spss using "`l'/ch.sav", clear  
	save "`l'/ch.dta", replace 
	
	import spss using "`l'/fs.sav", clear  
	save "`l'/fs.dta", replace 
	
	import spss using "`l'/hh.sav", clear  
	save "`l'/hh.dta", replace 
	
	import spss using "`l'/hl.sav", clear  
	save "`l'/hl.dta", replace 

	import spss using "`l'/mm.sav", clear  
	save "`l'/mm.dta", replace 

	import spss using "`l'/mn.sav", clear  
	save "`l'/mn.dta", replace 
	
	import spss using "`l'/wm.sav", clear  
	save "`l'/wm.dta", replace 
}
// this cannot work for the countries where some files do not exist
// file ./Bangladesh MICS6 SPSS Datasets/Bangladesh MICS6 SPSS Datasets/mm.sav not found

*/


/* save dirname and filename to excel 
*********************************************
*/
cap cd "$dir_mics"

cap ssc install filelist 
filelist, pattern("*fs.dta") 
drop country 
gen country = substr(dirname, 3, .)

export delimited using "$dir_proj_note\datasets_fs.csv", replace


*******************************************************************************
* read rawdata from MICS6 rawdata file and put into project_ADBI rawdata folder
*******************************************************************************
/* countries we want to use -------------------------
Bangladesh
Nepal
Pakistan
Mongolia
Thailand
Kyrgyzstan
Turkmenistan

some country does not have data for all modules 

*/

foreach i in "bh" "ch" "fs" "hh" "hl" "wm" "ab" "mn" {
	cap u "$dir_mics\Bangladesh MICS6 SPSS Datasets\Bangladesh MICS6 SPSS Datasets\\`i'", clear 
	cap sa "$dir_rawdata_mics\BGD2019_`i'", replace 
}

foreach i in "bh" "ch" "fs" "hh" "hl" "wm" "ab" "mn" {
	cap u "$dir_mics\Kyrgyz Republic MICS6 Datasets\Kyrgyz Republic MICS6 Datasets\\`i'", clear 
	cap sa "$dir_rawdata_mics\KGZ2018_`i'", replace 
}

foreach i in "bh" "ch" "fs" "hh" "hl" "wm" "ab" "mn" {
	cap u "$dir_mics\Mongolia MICS 2018 SPSS Datasets\Mongolia MICS 2018 SPSS Datasets\\`i'", clear 
	cap sa "$dir_rawdata_mics\MNG2018_`i'", replace 
}

foreach i in "bh" "ch" "fs" "hh" "hl" "wm" "ab" "mn" {
	cap u "$dir_mics\Nepal MICS6 Datasets\Nepal MICS6 SPSS Datasets\\`i'", clear 
	cap sa "$dir_rawdata_mics\NPL2019_`i'", replace 
}

foreach i in "bh" "ch" "fs" "hh" "hl" "wm" "ab" "mn" {
	cap u "$dir_mics\Turkmenistan MICS6 SPSS Datasets\Turkmenistan MICS6 Datasets\\`i'", clear 
	cap sa "$dir_rawdata_mics\TKM2019_`i'", replace 
}

*** Pakistan **********************************************************

foreach i in "bh" "ch" "fs" "hh" "hl" "wm" "ab" "mn" {
	cap u "$dir_mics\Pakistan (Balochistan) MICS6 Datasets\Pakistan (Baluchistan) SPSS Datasets\\`i'", clear 
	cap sa "$dir_rawdata_mics\PKB2019_`i'", replace 
}


foreach i in "bh" "ch" "fs" "hh" "hl" "wm" "ab" "mn" {
	cap u "$dir_mics\Pakistan Khyber Pakhtunkhwa MICS6 Datasets\Pakistan Khyber Pakhtunkhwa MICS6 SPSS Datasets\\`i'", clear 
	cap sa "$dir_rawdata_mics\PKK2019_`i'", replace 
}

foreach i in "bh" "ch" "fs" "hh" "hl" "wm" "ab" "mn" {
	cap u "$dir_mics\Pakistan Punjab MICS6 Datasets\\`i'", clear 
	cap sa "$dir_rawdata_mics\PKP2017_`i'", replace 
}


foreach i in "bh" "ch" "fs" "hh" "hl" "wm" "ab" "mn" {
	cap u "$dir_mics\Pakistan Sindh MICS6 Datasets\Pakistan Sindh MICS6 SPSS Datasets\\`i'", clear 
	cap sa "$dir_rawdata_mics\PKS2018_`i'", replace 
}

*** Thailand **********************************************************

foreach i in "bh" "ch" "fs" "hh" "hl" "wm" "ab" "mn" {
	cap u "$dir_mics\\Thailand MICS6 and Thailand Selected 17 Provinces MICS6 Datasets\Thailand MICS6 Datasets\Thailand MICS6 SPSS Datasets\\`i'", clear 
	cap sa "$dir_rawdata_mics\THA2019_`i'", replace 
}

foreach i in "bh" "ch" "fs" "hh" "hl" "wm" "ab" "mn" {
	cap u "$dir_mics\Thailand MICS6 and Thailand Selected 17 Provinces MICS6 Datasets\Thailand Selected 17 Provinces MICS6 Datasets\Thailand 17 Provinces MICS6 SPSS Datasets\\`i'", clear 
	cap sa "$dir_rawdata_mics\T172019_`i'", replace 
}





*******************************************************************************
* end of program 
*******************************************************************************

log close 
