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

global today "20230727"
log using "$dir_log\313_unify_loc_name_$today.log", replace



efolder orange, cd("$dir_tempdata")
cd "$dir_program"

efolder location_file, cd("$dir_data\id_key_file")
cd "$dir_program"



/*******************************************************************************

# TASK: unify the location names across several files 

*******************************************************************************/



/*******************************************************************************

* MODULE 1.1. get location names in EMDAT raw data 

*******************************************************************************/

u "$dir_data\emdat\emdat_public_adbi_proj_country", clear

keep if inrange(Year, 2015, 2019)

keep DisNo Year ISO Location GeoLocations AdmLevel ISO
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


keep locname DisNo ISO

split locname, parse(,) gen(loc_)

keep DisNo ISO loc_*

reshape long loc_, i(DisNo ISO) j(lengjing)

drop if loc_ == ""

duplicates report DisNo loc 
duplicates report DisNo lengjing 

sa "$dir_tempdata\disaster_loc", replace 



u "$dir_tempdata\disaster_loc", clear 

keep loc_ ISO 
duplicates drop 

// rename loc_ emdat_loc_name  
rename ISO ISO_alpha_3
rename loc_ locname 

replace locname = trim(locname)
duplicates drop 


sa "$dir_data\id_key_file\location_file\emdat_loc_name", replace 



/*******************************************************************************

* MODULE 1.2. get location names in MICS 

*******************************************************************************/

cap program drop findlocname
program define findlocname

	*** adm level 2 location names 
	preserve 

	keep Country ISO* adm_1_* adm_2_* 
	drop if adm_2_loc == ""
	duplicates drop
	gen finest_adm_level = 2
	order Country ISO* finest_adm_level, first 

	sa "$dir_tempdata\orange\loc_adm2", replace 

	restore 

	*** adm level 1 location names 
	preserve 

	keep Country ISO* adm_1_*
	drop if adm_1_loc == ""
	duplicates drop
	gen finest_adm_level = 1
	order Country ISO* finest_adm_level, first 

	sa "$dir_tempdata\orange\loc_adm1", replace 

	restore 

	*** adm level 0.5 location names 
	preserve 

	keep Country ISO* adm_05_*
	drop if adm_05_loc == ""
	duplicates drop
	gen finest_adm_level = 0.5
	order Country ISO* finest_adm_level, first 

	sa "$dir_tempdata\orange\loc_adm05", replace 

	restore

	*** adm level 0 location names 
	preserve

	keep Country ISO* 
	duplicates drop
	gen finest_adm_level = 0
	order Country ISO* finest_adm_level, first 

	sa "$dir_tempdata\orange\loc_adm0", replace 

	restore

end

u "$dir_data\id_key_file\mics_loc_id", clear

findlocname

/***** all location names together 
*************************************************/

u "$dir_tempdata\orange\loc_adm0", clear
append using "$dir_tempdata\orange\loc_adm05"
append using "$dir_tempdata\orange\loc_adm1"
append using "$dir_tempdata\orange\loc_adm2"
sa "$dir_data\id_key_file\location_file\mics_loc_adm_all", replace 

*** only leave finest adm level location name 

u "$dir_data\id_key_file\location_file\mics_loc_adm_all", clear 

gen locname = ""
replace locname = ISO_alpha_3 if finest_adm_level == 0 
replace locname = adm_05_loc if finest_adm_level == 0.5
replace locname = adm_1_loc if finest_adm_level == 1
replace locname = adm_2_loc if finest_adm_level == 2

// keep Country ISO* finest_adm_level locname
keep Country ISO* locname
duplicates drop 
// rename locname mics_loc_name 

sa "$dir_data\id_key_file\location_file\mics_loc_name", replace 



/*******************************************************************************

* MODULE 1.3. get location names in boundary_loc_id

*******************************************************************************/

u "$dir_data\id_key_file\boundary_loc_id", clear

findlocname

/***** all location names together 
*************************************************/

u "$dir_tempdata\orange\loc_adm0", clear
append using "$dir_tempdata\orange\loc_adm05"
append using "$dir_tempdata\orange\loc_adm1"
append using "$dir_tempdata\orange\loc_adm2"
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


/*******************************************************************************

* MODULE 1.4. modify output from MODULE 1.1, MODULE 1.2, MODULE 1.3

*******************************************************************************/

u "$dir_data\id_key_file\location_file\emdat_loc_name", clear
sort ISO_alpha_3 locname
gen emdat_id = _n 
rename locname emdat_locname
rename ISO_alpha_3 emdat_ISO 
keep emdat_*
sa "$dir_tempdata\orange\emdat_loc_name", replace

u "$dir_data\id_key_file\location_file\mics_loc_name", clear 
sort ISO_alpha_3 locname
gen mics_id = _n 
rename locname mics_locname
rename ISO_alpha_3 mics_ISO
keep mics_*
sa "$dir_tempdata\orange\mics_loc_name", replace

u "$dir_data\id_key_file\location_file\boundary_loc_name", clear 
sort ISO_alpha_3 locname
gen boundary_id = _n 
rename locname boundary_locname
rename ISO_alpha_3 boundary_ISO
keep boundary_*
sa "$dir_tempdata\orange\boundary_loc_name", replace


/*******************************************************************************

* MODULE 2.1. match EMDAT and boundary_loc_id location names by similar text patterns 

*******************************************************************************/

/* STEP 1. match ******************************
*******************************************************************************/


/* 
For all location names in EMDAT, find the most similar name in boundary file.
If the names perfectly match with one name in boundary file, then keep original names. 
If they do not match, decide what name to use and replace EMDAT name with boundary name. 
为什么会有EMDAT的地名，没有boundary里可以匹配的地名的情况呢？ 
Eg. NPL, in EMDAT, there is `Gandaki', which is a province. But this it not included in boundary file name. 
*/

// ssc install matchit, replace 
// ssc install freqindex, replace
// ssc install reclink, replace

u "$dir_tempdata\orange\emdat_loc_name", clear

matchit emdat_id emdat_locname using "$dir_tempdata\orange\boundary_loc_name.dta", idusing(boundary_id) txtusing(boundary_locname) 

*** find the country where location name is from, to decide which one is good match 
merge m:1 emdat_id using "$dir_tempdata\orange\emdat_loc_name"
keep if _merge == 3
rename _merge _merge_emdat_id

merge m:1 boundary_id using "$dir_tempdata\orange\boundary_loc_name"
keep if _merge == 3
rename _merge _merge_boundary_id

sort emdat_id

replace similscore = round(similscore*100000) 
sort emdat_id emdat_ISO similscore
bys emdat_id emdat_ISO: egen highestscore = max(similscore)

sa "$dir_tempdata\orange\match_emdat_boundary", replace


/* STEP 2. check locations manually ******************************
*******************************************************************************/

/****************************** CASE 1: location names match 
*******************************************************************************/

u "$dir_tempdata\orange\match_emdat_boundary", clear

keep if highestscore == 100000 
keep if similscore == highestscore
gen uniform_locname = boundary_locname

sa "$dir_tempdata\orange\match1", replace 

/****************************** CASE 2: there is no perfect match 
*******************************************************************************/

u "$dir_tempdata\orange\match_emdat_boundary", clear

drop if highestscore == 100000 

* If location name is from different countries in EMDAT or boundary file, rule them out. 
drop if emdat_ISO != boundary_ISO

bys emdat_id: egen countmatch = count(similscore)
gen uniform_locname = ""

sa "$dir_tempdata\orange\match2", replace 

/* CASE 2.1: 
If there is only one matching then we compare them manually, make sure they make sense and chose boundary_locname as the uniform_locname. 
*************************************************/
u "$dir_tempdata\orange\match2", clear

keep if countmatch == 1

/* NPL
https://en.wikipedia.org/wiki/Janakpur

Janakpurdham or Janakpur (Nepali: जनकपुर, Nepali pronunciation: [d͡zʌnʌkpur]) is a sub-metropolitan city in Dhanusha District, Madhesh Province, Nepal. 
---------------------------------------------------*/
replace uniform_locname = "Dhanusha" if emdat_locname == "Janakpur"

/* MNG
https://en.wikipedia.org/wiki/Azad_Kashmir

Azad Jammu and Kashmir (/ˌɑːzæd kæʃˈmɪər/;[7] Urdu: آزاد جموں و کشمیر, transl. 'Free Jammu and Kashmir' listen (help·info)),[8] abbreviated as AJK and colloquially referred to as simply Azad Kashmir, is a region administered by Pakistan as a nominally self-governing entity[9] and constituting the western portion of the larger Kashmir region, which has been the subject of a dispute between India and Pakistan since 1947.
---------------------------------------------------*/



replace uniform_locname = boundary_locname if uniform_locname == ""

drop countmatch

sa "$dir_tempdata\orange\match2_1", replace


/* CASE 2.2: 
If there are more than one matching then we compare them manually and chose boundary_locname as the uniform_locname. Most likely, the highestscore matching makes sense. 
*************************************************/
u "$dir_tempdata\orange\match2", clear

drop if countmatch == 1

/* MNG
Mongolia, EMDAT name => possible boundary file name => uniform name 

### Darxan-Uul => Darxan, Darkhan-Uul => Darkhan-Uul

Darkhan is the second-largest city in Mongolia and the capital of Darkhan-Uul Aimag (Darkhan-Uul Province).
wikipedia: Darkhan-Uul 

### O'vorxangai => O'ndorxangai, Ovorkhangai => Ovorkhangai

wikipedia: O'dor Xangai, Ovor Hangai 
O'vorxangai is referred as Ovor Hangai. 
O'ndorxangai is referred as O'dor Xangai. 
Check raw data from EMDAT, find O'vorxangai is at adm level 1. 
In boundary file, O'ndorxangai is at adm level 2. Ovorkhangai is at admin level 1. So, O'vorxangai must be the same as Ovorkhangai. 
---------------------------------------------------*/
replace uniform_locname = "Darkhan-Uul" if emdat_locname == "Darxan-Uul"
replace uniform_locname = "Ovorkhangai" if emdat_locname == "O'vorxangai"

/* PAK

### Chitral => Chitral Upper, Chitral Lower

https://en.wikipedia.org/wiki/Chitral_District

Chitral District is split into Upper and Lower Chitral District in 2018. 

### Kohistan => Kohistan Upper, Kohistan Lower, Kolai Palas Kohistan

https://en.wikipedia.org/wiki/Kohistan_District,_Pakistan

Kohistan (Urdu: کوہستان; "Land of Mountains"), also called Indus Kohistan (سندھُ کوہستان),[2][3] was an administrative district within the Hazara region of Khyber Pakhtunkhwa Province in Pakistan that was bifurcated into Upper Kohistan and Lower Kohistan in 2014, and Kolai-Palas in 2017.
---------------------------------------------------*/
replace uniform_locname = "Chitral Upper, Chitral Lower" if emdat_locname == "Chitral"
replace uniform_locname = "Kohistan Upper, Kohistan Lower, Kolai Palas Kohistan" if emdat_locname == "Kohistan"

/* THA

EMDAT => boundary file => uniform name 

### Buriram => Buri Ram, Kra Buri => Buri Ram 

https://en.wikipedia.org/wiki/Buriram

### Phachinburi => Phetchaburi, Prachin Buri, Phachi => Phachinburi

Phetchaburi or Phet Buri, is a town, capital of Phetchaburi province. 
Prachin Buri is Prachinburi province. 
Phachi may be a district. 
Google returns Prachin Buri if you search for Phachinburi.

### Si Saket => Sisaket, Doi Saket => Sisaket 

https://en.wikipedia.org/wiki/Trat_province
---------------------------------------------------*/
replace uniform_locname = "Buri Ram" if emdat_locname == "Buriram"
replace uniform_locname = "Phachinburi" if emdat_locname == "Phachinburi"
replace uniform_locname = "Si Saket" if emdat_locname == "Sisaket"



sort emdat_id highestscore
bys emdat_id: keep if _n == _N

replace uniform_locname = boundary_locname if uniform_locname == "" 

drop countmatch

duplicates tag emdat_id emdat_locname uniform_locname, gen(flag)
br if flag != 0 

duplicates drop emdat_locname uniform_locname, force 
drop flag

sa "$dir_tempdata\orange\match2_2", replace



/****************************** CASE 3: check those not matched
*******************************************************************************/
/* 
For some cases, location names from EMDAT do not have matching at all from boundary file. 

For some cases, there is match, but location names are from different country, i.e. no match. 
They got dropped in this line: 
`
* If location name is from different countries in EMDAT or boundary file, rule them out. 
drop if emdat_ISO != boundary_ISO
`
*/

************** append ABOVE types of matching ***************
u "$dir_tempdata\orange\match1", clear
append using "$dir_tempdata\orange\match2_1"
append using "$dir_tempdata\orange\match2_2"
// sort emdat_id 
merge m:1 emdat_id using "$dir_tempdata\orange\emdat_loc_name"
keep if _merge != 3
drop _merge

/* KGZ 

### Ozgon

https://en.wikipedia.org/wiki/%C3%96zg%C3%B6n
---------------------------------------------------*/
replace uniform_locname = "Uzgen" if emdat_locname == "Ozgon"


/* NPL 

### Bheri

https://en.wikipedia.org/wiki/Bheri,_Jajarkot

Bheri (Nepali: भेरी) (earlier; Bheri Malika) is an urban municipality located in Jajarkot District of Karnali Province of Nepal.

### Dhawalagiri

https://en.wikipedia.org/wiki/Dhawalagiri

Dhaulagiri was divided into four districts; since 2015 these districts have been redesignated as part of Gandaki Province.

### Koshi 

https://en.wikipedia.org/wiki/Koshi_Province

The province is named Koshi after the Koshi River, which is the largest river in the country. On 1 March 2023 the former temporary name of the province, Province No. 1, was changed to Koshi Province.

### Mahakali

https://en.wikipedia.org/wiki/Mahakali_Zone

### Mechi

https://en.wikipedia.org/wiki/Mechi_Zone

### Narayani 

https://en.wikipedia.org/wiki/Narayani_Zone

### Rapti

https://en.wikipedia.org/wiki/Rapti_Zone

Rapti was divided into five districts; since 2015 the three eastern districts (and the eastern part of Rukum District) have been redesignated as part of Lumbini Province, while Salyan District and the western part of Rukum District have been redesignated as part of Karnali Province.

### Runtigadhi 

https://en.wikipedia.org/wiki/Runtigadhi_Rural_Municipality

### Sagarmatha

https://en.wikipedia.org/wiki/Sagarmatha_Zone

### Seti 

https://en.wikipedia.org/wiki/Seti_Zone
---------------------------------------------------*/
replace uniform_locname = "Province No 7 Sudur Pashchim" if emdat_locname == "Mahakali"
replace uniform_locname = "Province No 1" if emdat_locname == "Mechi"
replace uniform_locname = "Province No 3 Bagmati, Province No 2 Madhesh" if emdat_locname == "Narayani"
replace uniform_locname = "Province No 1, Province No 2 Madhesh" if emdat_locname == "Sagarmatha"
replace uniform_locname = "Jajarkot" if emdat_locname == "Bheri"
replace uniform_locname = "Province No 4 Gandaki" if emdat_locname == "Dhawalagiri"
replace uniform_locname = "Province No 1" if emdat_locname == "Koshi"
replace uniform_locname = "Province No 5 Lumbini, Province No 6 Karnali" if emdat_locname == "Rapti"
replace uniform_locname = "Rolpa" if emdat_locname == "Runtigadhi (Rolpa)"
replace uniform_locname = "Province No 7 Sudur Pashchim" if emdat_locname == "Seti"

/* PAK 

### AJK

### Bolan 

https://en.wikipedia.org/wiki/Kachhi_District

### FATA

https://en.wikipedia.org/wiki/Federally_Administered_Tribal_Areas

### KP Tribals 

### North-West Frontier

https://en.wikipedia.org/wiki/North-West_Frontier_Province
---------------------------------------------------*/
replace uniform_locname = "Azad Kashmir" if emdat_locname == "AJK"
replace uniform_locname = "" if emdat_locname == "Federally Administered Tribal Areas"
replace uniform_locname = "Khyber Pakhtunkhwa" if emdat_locname == "KP Tribals"
replace uniform_locname = "Khyber Pakhtunkhwa" if emdat_locname == "North-West Frontier"
replace uniform_locname = "Kachhi" if emdat_locname == "Bolan"

sa "$dir_tempdata\orange\match3", replace





/* STEP 3. append all cases and double check ******************************
*******************************************************************************/

u "$dir_tempdata\orange\match1", clear
append using "$dir_tempdata\orange\match2_1"
append using "$dir_tempdata\orange\match2_2"
append using "$dir_tempdata\orange\match3"
sa "$dir_tempdata\orange\uniform_locname_emdat", replace

codebook emdat_id
codebook emdat_locname

u "$dir_tempdata\orange\emdat_loc_name", clear

codebook emdat_id
codebook emdat_locname

u "$dir_tempdata\orange\uniform_locname_emdat", clear
keep emdat_* boundary_* uniform_locname
sort emdat_id 
sa "$dir_tempdata\uniform_locname_emdat", replace





/*******************************************************************************

* MODULE 2.2. match MICS and boundary_loc_id location names by similar text patterns 

*******************************************************************************/

/* STEP 1. match ******************************
*******************************************************************************/
/* 
For all location names in MICS, find the most similar name in boundary file.
If the names perfectly match with one name in boundary file, then keep original names. 
If they do not match, decide what name to use and replace EMDAT name with boundary name. 
有没有可能 MICS 里面的地名，没有boundary里可以匹配的地名的情况呢？ 
*/

// ssc install matchit, replace 
// ssc install freqindex, replace
// ssc install reclink, replace

u "$dir_tempdata\orange\mics_loc_name", clear

matchit mics_id mics_locname using "$dir_tempdata\orange\boundary_loc_name.dta", idusing(boundary_id) txtusing(boundary_locname) 

*** find the country where location name is from, to decide which one is good match 
merge m:1 mics_id using "$dir_tempdata\orange\mics_loc_name"
keep if _merge == 3
rename _merge _merge_mics_id

merge m:1 boundary_id using "$dir_tempdata\orange\boundary_loc_name"
keep if _merge == 3
rename _merge _merge_boundary_id

sort mics_id, stable 

replace similscore = round(similscore*100000) 
sort mics_id mics_ISO similscore
bys mics_id mics_ISO: egen highestscore = max(similscore)

sa "$dir_tempdata\orange\match_mics_boundary", replace



/* STEP 2. check locations manually ******************************
*******************************************************************************/

/****************************** CASE 1: location names match 
*******************************************************************************/

u "$dir_tempdata\orange\match_mics_boundary", clear

keep if highestscore == 100000 
keep if similscore == highestscore
drop if mics_ISO != boundary_ISO
gen uniform_locname = boundary_locname

sa "$dir_tempdata\orange\match1", replace 

/****************************** CASE 2: there is no perfect match 
*******************************************************************************/

u "$dir_tempdata\orange\match_mics_boundary", clear

drop if highestscore == 100000 

* If location name is from different countries in MICS or boundary file, rule them out. 
drop if mics_ISO != boundary_ISO

bys mics_id: egen countmatch = count(similscore)
gen uniform_locname = ""

sa "$dir_tempdata\orange\match2", replace 

/* CASE 2.1: 
If there is only one matching then we compare them manually, make sure they make sense and chose boundary_locname as the uniform_locname. 
*************************************************/
u "$dir_tempdata\orange\match2", clear

keep if countmatch == 1

/* BGD

### Chapai Nawabganj

https://en.wikipedia.org/wiki/Chapai_Nawabganj_District

Because of its importance, Alivardi Khan founded Nowabganj town which in course of time known as Nawabganj.

### Chattogram

https://en.wikipedia.org/wiki/Chittagong#

### Jashore

https://www.wikidata.org/wiki/Q1862981
---------------------------------------------------*/
replace uniform_locname = "Chittagong" if mics_locname == "Chattogram"
replace uniform_locname = "Jessore" if mics_locname == "Jashore"

/* PAK

### Dera Ismail Khan

https://en.wikipedia.org/wiki/Dera_Ismail_Khan

Dera Ismail Khan (/deɪrʌ-ɪsmaɪ.iːl-xɑːn/; Balochi: ڈیرہ عِسمائیل خان, Urdu and Saraiki: ڈیرہ اسماعیل خان, Pashto: ډېره اسماعيل خان), abbreviated as D.I. Khan,[3] is a city and capital of Dera Ismail Khan District, located in Khyber Pakhtunkhwa, Pakistan.

### Shahdad Kot

https://en.wikipedia.org/wiki/Shahdadkot_Tehsil
https://en.wikipedia.org/wiki/Qambar_Shahdadkot_District

Shahdadkot (Sindhi: شھدادڪوٽ; Urdu: شہدادکوٹ) is the most populated and largest Tehsil of Qambar Shahdadkot District of Sindh, Pakistan.
---------------------------------------------------*/
replace uniform_locname = "D. I. Khan" if mics_locname == "Dera Ismail Khan"
replace uniform_locname = "Kambar Shahdad Kot" if mics_locname == "Shahdad Kot"

replace uniform_locname = boundary_locname if uniform_locname == ""

drop countmatch

sa "$dir_tempdata\orange\match2_1", replace



/* CASE 2.2: 
If there are more than one matching then we compare them manually and chose boundary_locname as the uniform_locname. Most likely, the highestscore matching makes sense. 
*************************************************/
u "$dir_tempdata\orange\match2", clear

drop if countmatch == 1

replace uniform_locname = "Chitral Upper, Chitral Lower" if mics_locname == "Chitral"
replace uniform_locname = "Dera Ghazi Khan" if mics_locname == "DG Khan"
replace uniform_locname = "Kohistan Upper, Kohistan Lower, Kolai Palas Kohistan" if mics_locname == "Kohistan"
replace uniform_locname = "Rahim Yar Khan" if mics_locname == "RY Khan"

replace uniform_locname = "Buri Ram" if mics_locname == "Buriram"



sort mics_id highestscore
bys mics_id: keep if _n == _N

replace uniform_locname = boundary_locname if uniform_locname == "" 

drop countmatch

duplicates tag mics_id mics_locname uniform_locname, gen(flag)
br if flag != 0 

duplicates drop mics_locname uniform_locname, force 
drop flag

sa "$dir_tempdata\orange\match2_2", replace



/****************************** CASE 3: check those not matched
*******************************************************************************/
/* 
For some cases, location names from MICS do not have matching at all from boundary file. 

For some cases, there is match, but location names are from different country, i.e. no match. 
They got dropped in this line: 
`
* If location name is from different countries in EMDAT or boundary file, rule them out. 
drop if emdat_ISO != boundary_ISO
`
*/

************** append ABOVE types of matching ***************
u "$dir_tempdata\orange\match1", clear
append using "$dir_tempdata\orange\match2_1"
append using "$dir_tempdata\orange\match2_2"
// sort emdat_id 
merge m:1 mics_id using "$dir_tempdata\orange\mics_loc_name"
keep if _merge != 3
drop _merge

/* NPL

### Province name 

https://en.wikipedia.org/wiki/Dera_Ismail_Khan

Dera Ismail Khan (/deɪrʌ-ɪsmaɪ.iːl-xɑːn/; Balochi: ڈیرہ عِسمائیل خان, Urdu and Saraiki: ڈیرہ اسماعیل خان, Pashto: ډېره اسماعيل خان), abbreviated as D.I. Khan,[3] is a city and capital of Dera Ismail Khan District, located in Khyber Pakhtunkhwa, Pakistan.

### Shahdad Kot

https://en.wikipedia.org/wiki/Shahdadkot_Tehsil
https://en.wikipedia.org/wiki/Qambar_Shahdadkot_District

Shahdadkot (Sindhi: شھدادڪوٽ; Urdu: شہدادکوٹ) is the most populated and largest Tehsil of Qambar Shahdadkot District of Sindh, Pakistan.
---------------------------------------------------*/

replace uniform_locname = "Province No 1" if strpos(mics_locname, "1")
replace uniform_locname = "Province No 2 Madhesh" if strpos(mics_locname, "2")
replace uniform_locname = "Province No 3 Bagmati" if strpos(mics_locname, "3")
replace uniform_locname = "Province No 4 Gandaki" if strpos(mics_locname, "GANDAKI")
replace uniform_locname = "Province No 5 Lumbini" if strpos(mics_locname, "5")
replace uniform_locname = "Province No 6 Karnali" if strpos(mics_locname, "KARNALI")
replace uniform_locname = "Province No 7 Sudur Pashchim" if strpos(mics_locname, "SUDO")

replace uniform_locname = "Bajaur" if mics_locname == "Bajor"
replace uniform_locname = "Leiah" if mics_locname == "Layyah"

replace uniform_locname = "Ahal" if strpos(mics_locname, "AKHAL")
replace uniform_locname = "Asgabat" if strpos(mics_locname, "ASHGA")
replace uniform_locname = "Balkan" if strpos(mics_locname, "BALKAN")
replace uniform_locname = "Dashhowuz" if strpos(mics_locname, "DASHO")
replace uniform_locname = "Lebap" if strpos(mics_locname, "LEBAP")
replace uniform_locname = "Mary" if strpos(mics_locname, "MARY")


sa "$dir_tempdata\orange\match3", replace





/* STEP 3. append all cases and double check ******************************
*******************************************************************************/

u "$dir_tempdata\orange\match1", clear
append using "$dir_tempdata\orange\match2_1"
append using "$dir_tempdata\orange\match2_2"
append using "$dir_tempdata\orange\match3"
sa "$dir_tempdata\orange\uniform_locname_mics", replace

codebook mics_id
codebook mics_locname

u "$dir_tempdata\orange\mics_loc_name", clear

codebook mics_id
codebook mics_locname


u "$dir_tempdata\orange\uniform_locname_mics", clear
keep mics_* boundary_* uniform_locname
sort mics_id 
sa "$dir_tempdata\uniform_locname_mics", replace




********************************************************************************
* delete temparory data files 
********************************************************************************

// shell rd "$dir_tempdata\orange" /s /q
// shell rm -r "$dir_tempdata\orange" /s /q

* delete all files in folder "orange"
cd "$dir_tempdata"
shell rd "orange" /s /q
cd "$dir_program"

* delete folder "orange"
rmdir "$dir_tempdata\orange"


