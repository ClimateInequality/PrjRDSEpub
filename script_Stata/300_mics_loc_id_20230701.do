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

global today "20230701"
log using "$dir_log\300_mics_loc_id_$today.log", replace



efolder cherry, cd("$dir_tempdata")
cd "$dir_program"


********************************************************************************
* mics geocode - this part is to try what works 
********************************************************************************

/*
u "$dir_rawdata\mics\BGD2019_hh", clear
duplicates report HH1 HH2  

cap rename HH7 geocode1 
cap rename HH7A geocode2 

fre geocode*

label list



cap program drop findgeocode 
program define findgeocode

args countryyr 

u "$dir_rawdata\mics\\`countryyr'_hh", clear

cap rename HH7 geocode1 
cap rename HH7A geocode2 

di "`countryyr'"
fre geocode*

label list labels1 
label list labels2

end

findgeocode BGD2019
findgeocode MNG2018
findgeocode NPL2019
findgeocode TKM2019

findgeocode THA2019
findgeocode T172019

findgeocode PKB2019
findgeocode PKK2019
findgeocode PKP2017
findgeocode PKS2018

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
	findgeocode `i'
}


local countryyr = "NPL2019"
u "$dir_rawdata\mics\\`countryyr'_hh", clear

cap rename HH7 geocode1 
cap rename HH7A geocode2 

di "`countryyr'"
fre geocode*

label list labels1 
label list labels2


*/


********************************************************************************
* output a table containing all location name and geocode use in MICS
********************************************************************************

cap program drop ordergeocode
program define ordergeocode 

cap rename HH7 geocode1 
cap rename HH7A geocode2 
keep Country ISO UNSDCODE geocode* mics_adm* countryfile
duplicates drop 

cap gen mics_adm1_geocode = geocode1, before(geocode1)
cap decode geocode1, gen(mics_adm1_loc)
cap drop geocode1
// cap rename geocode1 mics_adm1_loc

cap gen mics_adm2_geocode = geocode2, before(geocode2)
cap decode geocode2, gen(mics_adm2_loc)
cap drop geocode2
// cap rename geocode2 mics_adm2_loc

* some country has two admin level
cap sort mics_adm1_geocode mics_adm2_geocode
cap order Country UNSDCODE ISO mics_adm1 mics_adm1_geocode mics_adm1_loc mics_adm2 mics_adm2_geocode mics_adm2_loc

* some country has only one admin level 
cap sort mics_adm1_geocode
cap order Country UNSDCODE ISO mics_adm1 mics_adm1_geocode mics_adm1_loc 

end 



*** BGD2019
u "$dir_rawdata\mics\BGD2019_hh", clear

gen countryfile = "BGD2019"

gen Country = "Bangladesh"
gen ISO = "BGD"
cap gen UNSDCODE = "050"

gen mics_adm1 = "division"
gen mics_adm2 = "district"

ordergeocode

gen mics_adm0 = ""
gen mics_adm0_geocode = .
gen mics_adm0_loc = ""

cap order Country UNSDCODE ISO mics_adm0* mics_adm1* mics_adm2* 
cap order Country UNSDCODE ISO mics_adm0* mics_adm1*  
sort mics_adm*_geocode 

// export delimited using "$dir_proj_note\\BGD2019_hh", replace
sa "$dir_tempdata\cherry\BGD2019", replace



*** KGZ2018
u "$dir_rawdata\mics\KGZ2018_hh", clear

gen countryfile = "KGZ2018"

gen Country = "Kyrgyzstan"
gen ISO = "KGZ"
gen UNSDCODE = "417"
gen mics_adm1 = "oblast"
// cap gen mics_adm2 = "district" 

ordergeocode

gen mics_adm0 = ""
gen mics_adm0_geocode = .
gen mics_adm0_loc = ""

cap order Country UNSDCODE ISO mics_adm0* mics_adm1* mics_adm2* 
cap order Country UNSDCODE ISO mics_adm0* mics_adm1*  
sort mics_adm*_geocode 

sa "$dir_tempdata\cherry\\KGZ2018", replace



*** MNG2018
u "$dir_rawdata\mics\MNG2018_hh", clear

gen countryfile = "MNG2018"

cap gen Country = "Mongolia"
cap gen ISO = "MNG"
cap gen UNSDCODE = "496"
cap gen mics_adm1 = "region"
// cap gen mics_adm2 = "district" 

ordergeocode

gen mics_adm0 = "region"
gen mics_adm0_geocode = mics_adm1_geocode
gen mics_adm0_loc = mics_adm1_loc

replace mics_adm1 = "" if inlist(mics_adm1_geocode, 1, 2, 3, 4) 
replace mics_adm1_loc = "" if inlist(mics_adm1_geocode, 1, 2, 3, 4) 
replace mics_adm1_geocode = . if inlist(mics_adm1_geocode, 1, 2, 3, 4) 

// gen mics_adm0 = "region" if inlist(mics_adm1_geocode, 5) 
// gen mics_adm0_geocode = mics_adm1_geocode if inlist(mics_adm1_geocode, 5) 
// gen mics_adm0_loc = mics_adm1_loc if inlist(mics_adm1_geocode, 5) 

cap order Country UNSDCODE ISO mics_adm0* mics_adm1* mics_adm2* 
cap order Country UNSDCODE ISO mics_adm0* mics_adm1*  
sort mics_adm*_geocode 

sa "$dir_tempdata\cherry\\MNG2018", replace



*** NPL2019
u "$dir_rawdata\mics\NPL2019_hh", clear

gen countryfile = "NPL2019"

cap gen Country = "Nepal"
cap gen ISO = "NPL"
cap gen UNSDCODE = "524"
cap gen mics_adm1 = "region"
// cap gen mics_adm2 = "district" 

ordergeocode

gen mics_adm0 = ""
gen mics_adm0_geocode = .
gen mics_adm0_loc = ""

cap order Country UNSDCODE ISO mics_adm0* mics_adm1* mics_adm2* 
cap order Country UNSDCODE ISO mics_adm0* mics_adm1*  
sort mics_adm*_geocode 

sa "$dir_tempdata\cherry\\NPL2019", replace



******************************* Pakistan ***************************************


cap program drop pak_add_province
program define pak_add_province 

args provinceid

rename mics_adm1* mics_adm2*
gen mics_adm1 = "province"
gen mics_adm1_geocode = `provinceid'
gen mics_adm1_loc = `provinceid'

la def PAK_province 1 "Balochistan", add 
la def PAK_province 2 "Khyber Pakhtunkhwa", add 
la def PAK_province 3 "Punjab", add 
la def PAK_province 4 "Sindh", add 
la val mics_adm1_loc PAK_province

rename mics_adm1_loc mics_adm1_loc_label
decode mics_adm1_loc_label, gen(mics_adm1_loc)
drop mics_adm1_loc_label

gen mics_adm0 = ""
gen mics_adm0_geocode = .
gen mics_adm0_loc = ""

cap order Country UNSDCODE ISO mics_adm0* mics_adm1* mics_adm2* 
cap order Country UNSDCODE ISO mics_adm0* mics_adm1*  
sort mics_adm*_geocode 

end 



*** PKB2019 
u "$dir_rawdata\mics\PKB2019_hh", clear

gen countryfile = "PKB2019"

cap gen Country = "Pakistan"
cap gen ISO = "PAK"
cap gen UNSDCODE = "586"
cap gen mics_adm1 = "district"

ordergeocode

* For Pakistan, since one data is from one province, we need to modify its existing geocode to level 2 and create level 1 geocode as the province this data is from. 
pak_add_province 1

sa "$dir_tempdata\cherry\\PKB2019", replace

*** PKK2019 
u "$dir_rawdata\mics\PKK2019_hh", clear

gen countryfile = "PKK2019"

cap gen Country = "Pakistan"
cap gen ISO = "PAK"
cap gen UNSDCODE = "586"
cap gen mics_adm1 = "district"

ordergeocode

* For Pakistan, since one data is from one province, we need to modify it existing geocode to level 2 and create level 1 geocode as the province this data is from. 
pak_add_province 2

sa "$dir_tempdata\cherry\\PKK2019", replace

*** PKP2017 
u "$dir_rawdata\mics\PKP2017_hh", clear

gen countryfile = "PKP2017"

cap gen Country = "Pakistan"
cap gen ISO = "PAK"
cap gen UNSDCODE = "586"
cap gen mics_adm1 = "district"

ordergeocode

* For Pakistan, since one data is from one province, we need to modify it existing geocode to level 2 and create level 1 geocode as the province this data is from. 
pak_add_province 3

sa "$dir_tempdata\cherry\\PKP2017", replace

*** PKS2018 
u "$dir_rawdata\mics\PKS2018_hh", clear

gen countryfile = "PKS2018"

cap gen Country = "Pakistan"
cap gen ISO = "PAK"
cap gen UNSDCODE = "586"
cap gen mics_adm1 = "district"

ordergeocode

* For Pakistan, since one data is from one province, we need to modify it existing geocode to level 2 and create level 1 geocode as the province this data is from. 
pak_add_province 4

sa "$dir_tempdata\cherry\\PKS2018", replace


// /* Pakistan code 
// */
// u "$dir_tempdata\cherry\\PKB2019", clear
// append using "$dir_tempdata\cherry\\PKK2019"
// append using "$dir_tempdata\cherry\\PKP2017"
// append using "$dir_tempdata\cherry\\PKS2018"
// sa "$dir_tempdata\cherry\\PAK", replace



******************************* Thailand ***************************************

*** THA2019 
u "$dir_rawdata\mics\THA2019_hh", clear

gen countryfile = "THA2019"

cap gen Country = "Thailand"
cap gen ISO = "THA"
cap gen UNSDCODE = "764"
cap gen mics_adm1 = "region"

ordergeocode

* For Thailand, there are two data files. For THA file, there is only one admin level, region. 
// rename mics_adm1* mics_adm2*
// gen mics_adm1 = "province"
// gen mics_adm1_geocode = 1 
// gen mics_adm1_loc = 1 

sa "$dir_tempdata\cherry\\THA2019", replace



*** T172019
u "$dir_rawdata\mics\T172019_hh", clear

gen countryfile = "T172019"

fre HH7 HH7A
tab HH7 HH7A

* For Thailand, there are two data files. For T17 file, 17 provinces are picked out of region Central, North, Northeast, and South. So for this file, mics_adm1 and mics_adm2 are both created. 
cap gen Country = "Thailand"
cap gen ISO = "THA"
cap gen UNSDCODE = "764"
cap gen mics_adm1 = "region"
cap gen mics_adm2 = "province"

ordergeocode

sa "$dir_tempdata\cherry\\T172019", replace


*** append both files and modify 
u "$dir_tempdata\cherry\\THA2019", clear
append using "$dir_tempdata\cherry\\T172019"

rename mics_adm1* mics_adm0*
rename mics_adm2* mics_adm1*

replace mics_adm1_geocode = 1 if mics_adm0_geocode == 1 
replace mics_adm1_loc = "Bangkok" if mics_adm0_loc == "Bangkok"

cap order Country UNSDCODE ISO mics_adm0* mics_adm1* mics_adm2* 
cap order Country UNSDCODE ISO mics_adm0* mics_adm1*  
// sort mics_adm*_geocode

sa "$dir_tempdata\cherry\\THA", replace





*** TKM2019 ***************************************************

u "$dir_rawdata\mics\TKM2019_hh", clear

gen countryfile = "TKM2019"

cap gen Country = "Turkmenistan"
cap gen ISO = "TKM"
cap gen UNSDCODE = "795"
cap gen mics_adm1 = "region"
// cap gen mics_adm2 = "district" 

ordergeocode

/* Turkmenistan has four admin levels, valayat in this dataset is provincial level (admin level 1)
Provinces (Welayatlar): Turkmenistan is divided into five provinces, also known as welayatlar. The provinces are:

a. Ahal Province (Ahal welaýaty)
b. Balkan Province (Balkan welaýaty)
c. Dashoguz Province (Daşoguz welaýaty)
d. Lebap Province (Lebap welaýaty)
e. Mary Province (Mary welaýaty)

Cities (Şäherler): The administrative divisions also include cities, which have a separate status and local administration. Some major cities in Turkmenistan include Ashgabat (the capital), Turkmenabat, Dashoguz, Mary, and Balkanabat.

Ashgabat, the capital city of Turkmenistan, does not belong to any specific province (welayat). It is designated as a separate administrative entity known as the "city of Ashgabat" (Ashgabat şäheri).

While Ashgabat is not part of any province, it has its own local administration and government structure that is distinct from the provincial level. The city of Ashgabat is directly under the central government's jurisdiction and is managed independently.

*/

sa "$dir_tempdata\cherry\\TKM2019", replace



********************************************************************************
* append all geocode used in MICS into one table 
********************************************************************************

/* This does not work well if we allow the label from one dataset to be assigned to the new data being appended to it. I first export data file in csv format, then import again, in this case, all label will be transformed into string.
*/

/*
cd "$dir_tempdata\cherry"

foreach i in "BGD" "KGZ" "MNG" "NPL" "PAK" "THA" "TKM" {
	u "`i'", clear
	export delimited using "`i'", replace
}

foreach i in "BGD" "KGZ" "MNG" "NPL" "PAK" "THA" "TKM" {
	import delimited using "`i'", clear
	sa "`i'", replace
}

u "BGD", clear
foreach i in "KGZ" "MNG" "NPL" "PAK" "THA" "TKM" {
	append using "`i'", force
}

cd "$dir_program"


efolder loc_id, cd("$dir_data")

sa "$dir_data\loc_id\mics_loc_id", replace
export delimited using "$dir_data\loc_id\mics_loc_id", replace
*/



/*
20230716 Yujie --------------------------------------
The above is not a good idea. Use `decode` to generate new string variable based on the "encoded" numeric variable and its value label. You do this to data from each country, then do not need to worry about this while appending them all. 
*/

// u "$dir_tempdata\cherry\\BGD", clear
// foreach i in "KGZ" "MNG" "NPL" "PAK" "THA" "TKM" {
// 	append using "$dir_tempdata\cherry\\`i'"
// }



u "$dir_tempdata\cherry\\BGD2019", clear

foreach i in ///
"KGZ2018" ///
"MNG2018" ///
"NPL2019" ///
"PKB2019" ///
"PKK2019" ///
"PKP2017" ///
"PKS2018" ///
"THA" ///
"TKM2019" ///
{
	append using "$dir_tempdata\cherry\\`i'"
}



efolder id_key_file, cd("$dir_data")
cd "$dir_program"

sa "$dir_data\id_key_file\mics_loc_id", replace



********************************************************************************
* create location id, polish data file 
********************************************************************************

/* Create location id uniquely identifying each location to merge with other file. 
*/


u "$dir_data\id_key_file\mics_loc_id", clear

/* Admin level 0 is usually referred to as [country]. So, it is not a good idea to use it to denote [region] division. 
Change this variable to another name - mics_adm_05
Also change other admin level variable names. 
*/

rename ISO ISO_alpha_3

rename mics_adm0* adm_05*
rename mics_adm1* adm_1*
rename mics_adm2* adm_2*

sort ISO_alpha_3 countryfile adm_05_geocode adm_1_geocode adm_2_geocode, stable
gen RDSE_loc_id = _n
order RDSE_loc_id, first

/* Denote which level the finest admin level is for each country 
*/

gen finest_adm_level = 0.5
replace finest_adm_level = 1 if adm_1_geocode != .
replace finest_adm_level = 2 if adm_2_geocode != .

order finest_adm_level, after(ISO_alpha_3)



sa "$dir_data\id_key_file\mics_loc_id", replace
export delimited using "$dir_data\id_key_file\mics_loc_id", replace




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
cap rmdir "$dir_tempdata\cherry"


