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

global today "20231115"
log using "$dir_log\340_mics_mother_location_$today.log", replace

efolder cherry, cd("$dir_tempdata")
cd "$dir_program"



********************************************************************************
* MICS data, obtain the location of mothers of children in main sample
********************************************************************************

/* 
https://github.com/ClimateInequality/PrjRDSE/issues/35

Step 1. Find mothers for all children. Do this by countryfile. 
In child id file, the identifiers for mother of each child: countryfile, HH1, HH2, moLN. 
In raw data of individual women for each country/region, the identifiers are HH1, HH2, LN. 
1) generate countryfile variable
2) rename LN to moLN
3) merge by identifiers 
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

	keep ${identifiers} LN WM6D WM6M WM6Y WB15* WB16* WB17* HH7* 
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

u "$dir_data\id_key_file\mics_child_id", clear

global identifiers = "countryfile HH1 HH2 moLN"


*** BGD2019
local c = "BGD2019"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
pr_mo_loc

/* Information differs by countryfile. Clean this one by one. */
clonevar mo_prior_loc_adm1 = WB17 
decode WB17, gen(mo_prior_loc_name_adm1) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 

cap drop WB16
cap drop HH7*

sa "$dir_tempdata\\cherry\\`c'", replace


*** KGZ2018
local c = "KGZ2018"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
pr_mo_loc


/* Information differs by countryfile. Clean this one by one. */
clonevar mo_prior_loc_adm1 = WB17 
decode WB17, gen(mo_prior_loc_name_adm1) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 

cap drop WB16
cap drop HH7*

sa "$dir_tempdata\\cherry\\`c'", replace


*** MNG2018
local c = "MNG2018"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
pr_mo_loc

/* Information differs by countryfile. Clean this one by one. */

// Prior location name : adm 1 
clonevar mo_prior_loc_adm1 = WB17 
decode WB17, gen(mo_prior_loc_name_adm1) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 

// Current location name : adm 1 

fre WB
bys WB17A: fre WB17 


cap drop WB16 WB17A 
cap drop HH7*

sa "$dir_tempdata\\cherry\\`c'", replace


*** NPL2019
local c = "NPL2019"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
pr_mo_loc

/* Information differs by countryfile. Clean this one by one. */
fre WB16
fre WB17 WB17A 
clonevar mo_prior_loc_adm2 = WB17 
decode WB17, gen(mo_prior_loc_name_adm2) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 
// WB17 is district, admin level 2 
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

local i = "NPL2019"
u "$dir_rawdata\mics\\`i'_fs", clear
fre HH7 HH7b HH7c
// HH7 : Region, HH7b : Domain, HH7c : Province. Region and Province are the same. What is Domain? 

sa "$dir_tempdata\\cherry\\`c'", replace



******************************* Pakistan ***************************************

*** PKK2019 
local c = "PKK2019"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
/* There is no WB15-17 variables in PKK. 
*/


*** PKP2017 
local c = "PKP2017"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	

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


/* Information differs by countryfile. Clean this one by one. */
clonevar mo_prior_loc_adm1 = WB17 
decode WB17, gen(mo_prior_loc_name_adm1) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 

cap drop WB16 WB17A 
cap drop HH7*

sa "$dir_tempdata\\cherry\\`c'", replace


*** PKS2018 
local c = "PKS2018"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	

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


/* Information differs by countryfile. Clean this one by one. */
clonevar mo_prior_loc_adm1 = WB17 
decode WB17, gen(mo_prior_loc_name_adm1) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 

cap drop WB16 WB17A 
cap drop HH7*

sa "$dir_tempdata\\cherry\\`c'", replace




******************************* Thailand ***************************************

*** THA2019 
local c = "THA2019"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
pr_mo_loc

/* Information differs by countryfile. Clean this one by one. */
clonevar mo_prior_loc_adm05 = WB17 
decode WB17, gen(mo_prior_loc_name_adm05) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 

cap drop WB16 WB17A 
cap drop HH7*

sa "$dir_tempdata\\cherry\\`c'", replace



*** T172019 
local c = "T172019"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
pr_mo_loc

/* Information differs by countryfile. Clean this one by one. */
clonevar mo_prior_loc_adm05 = WB17 
decode WB17, gen(mo_prior_loc_name_adm05) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 

cap drop WB16 WB17A 
cap drop HH7*

sa "$dir_tempdata\\cherry\\`c'", replace



*** TKM2019 ***************************************************

local c = "TKM2019"

u "$dir_rawdata\\mics\\`c'_wm", clear
gen countryfile = "`c'", before(HH1)
	
pr_mo_loc

/* Information differs by countryfile. Clean this one by one. */
clonevar mo_prior_loc_adm1 = WB17 
decode WB17, gen(mo_prior_loc_name_adm1) 
// The location names are all in capital. Need to change it probably to be consistent with location names of children. 

cap drop WB16 WB17A 
cap drop HH7*

sa "$dir_tempdata\\cherry\\`c'", replace









************************** BELOW IS FROM OTHER CODE ****************************
************************** BELOW IS FROM OTHER CODE ****************************
************************** BELOW IS FROM OTHER CODE ****************************


/*

u "$dir_rawdata\mics\BGD2019_hh", clear
duplicates report HH1 HH2  

u "$dir_rawdata\mics\BGD2019_hl", clear
duplicates report HH1 HH2 HL1 

// u "$dir_rawdata\mics\BGD2019_tn", clear
// duplicates report HH1 HH2 TNLN

u "$dir_rawdata\mics\BGD2019_wm", clear
duplicates report HH1 HH2 LN 

u "$dir_rawdata\mics\BGD2019_bh", clear
duplicates report HH1 HH2 LN BHLN

// u "$dir_rawdata\mics\BGD2019_fg", clear
// duplicates report HH1 HH2 LN FGLN

// u "$dir_rawdata\mics\BGD2019_mm", clear
// duplicates report HH1 HH2 LN MMLN

u "$dir_rawdata\mics\BGD2019_ch", clear
duplicates report HH1 HH2 LN
 
u "$dir_rawdata\mics\BGD2019_fs", clear
duplicates report HH1 HH2 LN 

u "$dir_rawdata\mics\BGD2019_mn", clear
duplicates report HH1 HH2 LN 



duplicates tag HH1 HH2 LN, gen(flag)
fre flag


foreach i in ///
"BGD2019" ///
"NPL2019" ///
"PKB2019" ///
"PKK2019" ///
"PKP2017" ///
"PKS2018" ///
"MNG2018" ///
"THA2019" ///
"T172019" ///
"KGZ2018" ///
"TKM2019" ///
{ 
	u "$dir_rawdata\mics\\`i'_fs", clear
	duplicates report HH1 HH2 
	duplicates report HH1 HH2 LN
	codebook HH1 HH2 LN
}


/* HH1 cluster ID 
HH2 household number 
LN line number 
*/

u "$dir_rawdata\mics\BGD2019_hh", clear
duplicates report HH1 HH2  

u "$dir_rawdata\mics\BGD2019_hl", clear
duplicates report HH1 HH2 HL1 

gen micswave = 6 
cap rename HH7 geocode1 
cap rename HH7A geocode2 
cap rename HL1 LN

keep HH1 HH2 LN micswave geocode1 geocode2 
gen HH1_str = string(HH1, "%05.0f")
gen HH2_str = string(HH2, "%02.0f")
gen LN_str = string(LN, "%02.0f")
gen hhid_str = HH1_str + HH2_str
destring hhid_str, gen(hhid)
gen childno_str = HH1_str + HH2_str + LN_str

drop *_str

sort HH1 HH2 LN
gen childid = _n


rename HH1 clusterno
rename HH2 hhno
rename LN lineno

gen country = 50

cap fre geocode1 
cap fre geocode2
gen HH1_str = string(country, "%03.0f")
gen HH2_str = string(HH2, "%02.0f")
gen LN_str = string(LN, "%02.0f")

*/



********************************************************************************
* each country, get identifier for child 
********************************************************************************



*** BGD2019
u "$dir_rawdata\mics\BGD2019_fs", clear
duplicates report HH1 HH2 

keep HH1 HH2 LN HH7 HH7A

cap gen countryfile = "BGD2019"

gen mics_adm0_geocode = .
rename HH7 mics_adm1_geocode
rename HH7A mics_adm2_geocode

sa "$dir_tempdata\cherry\BGD2019", replace



*** KGZ2018
u "$dir_rawdata\mics\KGZ2018_fs", clear

keep HH1 HH2 LN HH7
 
cap gen countryfile = "KGZ2018"

gen mics_adm0_geocode = .
rename HH7 mics_adm1_geocode
gen mics_adm2_geocode = .

sa "$dir_tempdata\cherry\\KGZ2018", replace



*** MNG2018
u "$dir_rawdata\mics\MNG2018_fs", clear

keep HH1 HH2 LN HH7 

cap gen countryfile = "MNG2018"

rename HH7 mics_adm0_geocode 
gen mics_adm1_geocode = .
replace mics_adm1_geocode = mics_adm0_geocode if mics_adm0_geocode == 5 // Ulaanbaatar  
gen mics_adm2_geocode = .

sa "$dir_tempdata\cherry\\MNG2018", replace



*** NPL2019
u "$dir_rawdata\mics\NPL2019_fs", clear

keep HH1 HH2 LN HH7 

cap gen countryfile = "NPL2019"

gen mics_adm0_geocode = . 
rename HH7 mics_adm1_geocode
gen mics_adm2_geocode = .

sa "$dir_tempdata\cherry\\NPL2019", replace



******************************* Pakistan ***************************************

*** PKB2019 
u "$dir_rawdata\mics\PKB2019_fs", clear

keep HH1 HH2 LN HH7

cap gen countryfile = "PKB2019"

gen mics_adm0_geocode = .
gen mics_adm1_geocode = 1 
rename HH7 mics_adm2_geocode

sa "$dir_tempdata\cherry\\PKB2019", replace

*** PKK2019 
u "$dir_rawdata\mics\PKK2019_fs", clear

keep HH1 HH2 LN HH7

cap gen countryfile = "PKK2019"

gen mics_adm0_geocode = .
gen mics_adm1_geocode = 2 
rename HH7 mics_adm2_geocode

sa "$dir_tempdata\cherry\\PKK2019", replace

*** PKP2017 
u "$dir_rawdata\mics\PKP2017_fs", clear

cap rename hh7 HH7 
keep HH1 HH2 LN HH7

cap gen countryfile = "PKP2017"

gen mics_adm0_geocode = .
gen mics_adm1_geocode = 3 
rename HH7 mics_adm2_geocode

sa "$dir_tempdata\cherry\\PKP2017", replace

*** PKS2018 
u "$dir_rawdata\mics\PKS2018_fs", clear

keep HH1 HH2 LN HH7

cap gen countryfile = "PKS2018"

gen mics_adm0_geocode = .
gen mics_adm1_geocode = 4 
rename HH7 mics_adm2_geocode

sa "$dir_tempdata\cherry\\PKS2018", replace



******************************* Thailand ***************************************

*** THA2019 
u "$dir_rawdata\mics\THA2019_fs", clear

keep HH1 HH2 LN HH7

cap gen countryfile = "THA2019"

rename HH7 mics_adm0_geocode 
gen mics_adm1_geocode = . 
replace mics_adm1_geocode = mics_adm0_geocode if mics_adm0_geocode == 1 // Bangkok 
gen mics_adm2_geocode = .

sa "$dir_tempdata\cherry\\THA2019", replace

*** T172019 
u "$dir_rawdata\mics\T172019_fs", clear

keep HH1 HH2 LN HH7 HH7A

cap gen countryfile = "T172019"

rename HH7 mics_adm0_geocode 
rename HH7A mics_adm1_geocode
gen mics_adm2_geocode = .

sa "$dir_tempdata\cherry\\T172019", replace



*** TKM2019 ***************************************************

u "$dir_rawdata\mics\TKM2019_fs", clear

keep HH1 HH2 LN HH7

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

rename mics_adm0* adm_05*
rename mics_adm1* adm_1*
rename mics_adm2* adm_2*

merge m:1 countryfile adm_05_geocode adm_1_geocode adm_2_geocode using "$dir_data\id_key_file\mics_loc_id"

// merge m:1 ISO_alpha_3 mics_adm0_geocode mics_adm1_geocode mics_adm2_geocode using "$dir_data\id_key_file\mics_loc_id"

fre _merge if HH1 != .
keep if _merge == 3 
keep HH1 HH2 LN countryfile RDSE_loc_id ISO_alpha_3
order countryfile HH1 HH2 LN RDSE_loc_id ISO_alpha_3
sort countryfile HH1 HH2 LN RDSE_loc_id ISO_alpha_3



sa "$dir_data\id_key_file\mics_child_id", replace
export delimited using "$dir_data\id_key_file\mics_child_id", replace



/*
They can all uniquely identify one observations. 

duplicates report RDSE_loc_id HH1 HH2 
duplicates report RDSE_loc_id HH1 HH2 LN
duplicates report countryfile HH1 HH2 LN
*/


********************************************************************************
* find line number for mother and father 
********************************************************************************

/* what variable should be used as line number for father and mother??? 

MLINE is identical to HL20, mother or primary caretaker line number. 
FLINE is identical to HL18, only except for value 0 (not in the household). 
DECISION: use biological father as father, biological mother as mother, to obtain parental information. 

Check BGD2019 as example. 

MLINE: 1-26 value makes sense, but what is 90? From HL20, we know that 90 means NO ONE. 
FLINE: 0 is Not in household 

Conclusion: MILNE is identical to HL20, which considers natural mother and primary caretaker as "mother". 
If natural mother is alive and lives in household, then line number is recorded. 
If natural mother is alive but does not live in household, then the place where natural mogher lives is recorded, and records the line number of primary caretaker. If  or alive but not in the same household, 

Is there chance that primary caretaker is the father? YES. 
Check HL20 and HL18, FLINE.
*/

/*
u "$dir_rawdata\mics\\BGD2019_hl", clear // hh member

keep HH1 HH2 HL1 MLINE FLINE
rename HL1 LN
gen countryfile = "BGD2019"
duplicates report HH1 HH2 LN
fre MLINE FLINE

sa "$dir_tempdata\cherry\\BGD2019", replace
*/


* The below program is not used. Put that into a program to avoid implementing it. 
cap program drop checkparentline
program define checkparentline

	local countryfile = "BGD2019"

	u "$dir_rawdata\mics\\`countryfile'_hl", clear // hh member
	gen countryfile = "`countryfile'"

	keep HH1 HH2 HL1 HL12-HL20 MLINE FLINE
	rename HL1 LN
	clonevar moLN = HL14 
	clonevar faLN = HL18

	duplicates report HH1 HH2 LN

	fre moLN MLINE 
	fre faLN FLINE

	fre HL16 HL17 HL18 if FLINE == 0
	tab HL16 HL17 if FLINE == 0
	tab HL16 FLINE if FLINE == 0

	fre HL16
	fre FLINE if HL16 != 1 // HL16 = 1 YES, 2 NO, 8 DK, 9 NO RESPONSE
	fre FLINE if HL16 == 2 
	fre FLINE if HL16 == 8
	fre FLINE if HL16 == 9 
	fre FLINE if HL16 == . 
	tab HL16 FLINE if HL16 != 1


	sa "$dir_tempdata\cherry\\`countryfile'", replace


	count if HL14 == HL18 & HL14 != . & HL18 != . // mother line number equals father line number??? This cannot be correct??? 
	count if HL20 == HL14 & HL20 != . & HL14 != .
	count if HL20 == HL18 & HL20 != . & HL18 != .
	count if HL20 != HL14 & HL20 != HL18 & HL14 != . & HL20 != . & HL18 != .

	fre HL20 HL18 if HL20 == HL18 

	count if MLINE == FLINE 
	br HH1 HH2 HL1 HL14 HL18 HL20 MLINE FLINE if MLINE == FLINE 

	gen molinenatural = (MLINE == HL14) // mother line number matches natural mother line number 
	gen falinenatural = (FLINE == HL18) // father line number matches natural father line number  
	fre molinenatural falinenatural
	bys molinenatural: fre HL12 HL13 HL15 
	bys falinenatural: fre HL16 HL17 HL19 

	tab molinenatural HL12 
	tab molinenatural HL13 
	tab molinenatural HL15

	bys HL12: fre molinenatural
	fre molinenatural if HL12 == 1 & HL13 == 1 

	fre HL13 if HL12 != 1 // mother is not alive 
	fre HL13 if HL12 == 1 // mother is alive 

	fre molinenatural if HL12 == 1 & HL13 == 1 // mother alive and live in same household
	fre molinenatural if HL12 == 1 & HL13 != 1 // mother alive but not live in household => for all of them, MLINE do not match natural mother's line number 

	gen molinecaretaker = (MLINE == HL20) // mother line number matches primary caretaker line number 
	fre molinecaretaker // all of them match => Conclusion: MLINE is the same as HL20 

end
	
	
	
cap program drop findparentline
program define findparentline

args countryfile
	
	u "$dir_rawdata\mics\\`countryfile'_hl", clear // hh member
	gen countryfile = "`countryfile'", before(HH1)

	keep countryfile HH1 HH2 HL1 HL12-HL20 MLINE FLINE
	rename HL1 LN
	clonevar moLN = HL14 // use natural mother line number as mother line number 
	clonevar faLN = HL18 // use natural father line number as father line number 
	clonevar mocareLN = HL20 // line number of mother or primary caretaker who can be father or other member in hh 
	
	keep countryfile HH1 HH2 LN moLN faLN
	sort countryfile HH1 HH2 LN 
	duplicates report HH1 HH2 LN

	sa "$dir_tempdata\cherry\\`countryfile'", replace

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
"THA2019" ///
"T172019" ///
"TKM2019" ///
{
	findparentline `i'
}



/* append file to create one file containing all parents line number for every household member 
*******************************************************************************/

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

sa "$dir_data\id_key_file\mics_linenumber", replace




u "$dir_data\id_key_file\mics_child_id", clear
merge 1:1 countryfile HH1 HH2 LN using "$dir_data\id_key_file\mics_linenumber"
keep if _merge == 3
drop _merge

sa "$dir_data\id_key_file\mics_child_id", replace



/*******************************************************************************

* MODULE 3. Clean THA and PAK 

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

sa "$dir_data\id_key_file\mics_child_id", replace
export delimited "$dir_data\id_key_file\mics_child_id.csv", nolabel replace




/*



*** get parents lineno
u "$dir_tempdata\parent_edu_age", clear
drop melevel felevel hhmemberage
sa "$dir_tempdata\parent_lineno", replace

u "$dir_tempdata\BGD2019_fs_merge", clear
duplicates report HH1 HH2 LN
merge 1:1 HH1 HH2 LN using "$dir_tempdata\parent_lineno"

drop if _merge != 3
drop _merge 

sa "$dir_tempdata\BGD2019_fs_merge", replace 



*** mother age and education 
u "$dir_tempdata\parent_edu_age", clear
drop motherlineno fatherlineno felevel
rename LN motherlineno
rename hhmemberage motherage 
la var motherage "Mother age"
rename melevel motheredulevel
sa "$dir_tempdata\mother", replace

u "$dir_tempdata\BGD2019_fs_merge", clear
duplicates report HH1 HH2 motherlineno
merge 1:1 HH1 HH2 motherlineno using "$dir_tempdata\mother"

drop if _merge != 3
drop _merge

sa "$dir_tempdata\BGD2019_fs_merge", replace 



*** father age and education 
u "$dir_tempdata\parent_edu_age", clear
drop motherlineno fatherlineno melevel
rename LN fatherlineno
rename hhmemberage fatherage 
la var fatherage "Father age"
rename felevel fatheredulevel
sa "$dir_tempdata\father", replace

u "$dir_tempdata\BGD2019_fs_merge", clear
duplicates report HH1 HH2 fatherlineno
merge 1:1 HH1 HH2 fatherlineno using "$dir_tempdata\father"

drop if _merge == 2
drop _merge

sa "$dir_tempdata\BGD2019_fs_merge", replace 



order mother*, last
order father*, last
order urban geocode* wscore-PSU, last


// duplicates report HH1 HH2
// duplicates report HH1 HH2 motherlineno

sa "$dir_tempdata\BGD2019_fs_merge", replace 


*/














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


