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
log using "$dir_log\311_boundary_loc_id_$today.log", replace



efolder cherry, cd("$dir_tempdata")
cd "$dir_program"

********************************************************************************
* check out all geo boundary files downloaded 
********************************************************************************

/*
https://data.humdata.org/dataset/cod-ab-bgd

They are supposed to be uniform across countries, but Turkmenistan does not have the file, which makes me think we should be careful with the files. They combine resource from other websites probably. 

*/


/*
*** BGD
clear
import excel "$dir_rawdata\loc_id\boundary_shapefile\bgd_adminboundaries_tabulardata.xlsx", sheet("ADM2") firstrow

sort ADM1_PCODE ADM2_PCODE
keep ADM2_EN ADM2_PCODE ADM1_EN ADM1_PCODE ADM0_EN ADM0_PCODE

sa "$dir_tempdata\cherry\BGD", replace 


*** KGZ
clear
import excel "$dir_rawdata\loc_id\boundary_shapefile\kgz_adminboundaries_tabulardata.xlsx", sheet("ADM2") firstrow

sort ADM1_PCODE ADM2_PCODE
keep ADM2_EN ADM2_PCODE ADM1_EN ADM1_PCODE ADM0_EN ADM0_PCODE

*** MNG
clear
import excel "$dir_rawdata\loc_id\boundary_shapefile\mng_adminboundaries_tabulardata.xlsx", sheet("ADM2") firstrow

sort ADM1_PCODE ADM2_PCODE
keep ADM2_EN ADM2_PCODE ADM1_EN ADM1_PCODE ADM0_EN ADM0_PCODE

/* For MNG, we need region. 
*/

*** NPL
clear
import excel "$dir_rawdata\loc_id\boundary_shapefile\npl_adminboundaries_tabulardata.xlsx", sheet("ADM2") firstrow

sort ADM1_PCODE ADM2_PCODE
keep ADM2_EN ADM2_PCODE ADM1_EN ADM1_PCODE ADM0_EN ADM0_PCODE

/* ADM1_EN shows seven provinces. We call them province No. 1 - No. 7. 
*/

*** PAK
clear
import excel "$dir_rawdata\loc_id\boundary_shapefile\pak_adminboundaries_tabulardata.xlsx", sheet("ADM2") firstrow

sort ADM1_PCODE ADM2_PCODE
keep ADM2_EN ADM2_PCODE ADM1_EN ADM1_PCODE ADM0_EN ADM0_PCODE

*** THA
clear
import excel "$dir_rawdata\loc_id\boundary_shapefile\tha_adminboundaries_tabulardata.xlsx", sheet("ADM2") firstrow

sort ADM1_PCODE ADM2_PCODE
keep ADM2_EN ADM2_PCODE ADM1_EN ADM1_PCODE ADM0_EN ADM0_PCODE

*/



cap program drop countryboundary
program define countryboundary

	args countryiso 

	clear
	import excel "$dir_rawdata\loc_id\boundary_shapefile\\`countryiso'_adminboundaries_tabulardata.xlsx", sheet("ADM2") firstrow

	sort ADM1_PCODE ADM2_PCODE
	keep ADM2_EN ADM2_PCODE ADM1_EN ADM1_PCODE ADM0_EN ADM0_PCODE

	order ADM0_EN ADM0_PCODE ADM1_PCODE ADM1_EN ADM2_PCODE ADM2_EN 
	rename ADM0_EN Country
	rename ADM0_PCODE ISO_alpha_2

	rename ADM1_EN adm_1_loc 
	rename ADM2_EN adm_2_loc 

	rename ADM1_PCODE adm_1_pcode
	rename ADM2_PCODE adm_2_pcode

	sa "$dir_tempdata\cherry\\`countryiso'", replace 

end


foreach i in "BGD" "KGZ" "MNG" "PAK" "THA" {
	countryboundary `i'
}


*** NPL
/* ADM2_EN and ADM2_PCODE are not admin level 2 variables, but admin level 3 geoinfo! 

https://en.wikipedia.org/wiki/Administrative_divisions_of_Nepal

Nepal should have 7 provinces for admin level 1, and 77 districts for admin level 2. 
*/

local countryiso = "NPL"

clear
import excel "$dir_rawdata\loc_id\boundary_shapefile\\`countryiso'_adminboundaries_tabulardata.xlsx", sheet("ADM2") firstrow


keep DISTRICT_EN DISTRICT_PCODE ADM1_EN ADM1_PCODE ADM0_EN ADM0_PCODE
rename DISTRICT_EN ADM2_EN 
rename DISTRICT_PCODE ADM2_PCODE

duplicates drop

sort ADM1_PCODE ADM2_PCODE

order ADM0_EN ADM0_PCODE ADM1_PCODE ADM1_EN ADM2_PCODE ADM2_EN 
rename ADM0_EN Country
rename ADM0_PCODE ISO_alpha_2

rename ADM1_EN adm_1_loc 
rename ADM2_EN adm_2_loc 

rename ADM1_PCODE adm_1_pcode
rename ADM2_PCODE adm_2_pcode

sa "$dir_tempdata\cherry\\`countryiso'", replace 



*** TKM
clear
import excel "$dir_rawdata\loc_id\boundary_shapefile\tkm_adminboundaries_tabulardata.xlsx", sheet("ADM1") firstrow

// sort ADM1_PCODE ADM2_PCODE
// keep ADM2_EN ADM2_PCODE ADM1_EN ADM1_PCODE ADM0_EN ADM0_PCODE

sort ADM1_PCODE
keep ADM1_EN ADM1_PCODE ADM0_EN ADM0_PCODE

order ADM0_EN ADM0_PCODE ADM1_PCODE ADM1_EN 
rename ADM0_EN Country
rename ADM0_PCODE ISO_alpha_2

rename ADM1_EN adm_1_loc 

rename ADM1_PCODE adm_1_pcode

// br if adm_1_loc == "Asgabat"
// br if strpos(adm_1_loc, "gabat")
replace adm_1_loc = "Asgabat" if adm_1_pcode == "TM06"

sa "$dir_tempdata\cherry\\TKM", replace 




********************************************************************************
* Mongolia, need region division 
********************************************************************************

/*
https://montsame.mn/en/read/214091#:~:text=Alongside%20being%20developed%20on%20the,the%20territory%20as%20microeconomic%20regions.

I am checking the different names referred as for the same location. Name used in montsame == Name used in humdata == Name used in EMDAT 

Bayan-Ulgii == Bayan-Olgii == Bayan-O'lgii
Arkhangai == Arxangai == Arxangai
Khuvsgul == Khovsgol == Xo'vsgol 
Tuv == To'v == To'v

Khentii == Hentii

Gobisumber == Govisumber 
Dornogobi == Dornogovi 
Dundgobi == Dundgovi
Umnugobi == Omnogovi

Gobi-Altai == Govi-Altai

Uvurkhangai == Ovorkhangai



*** chatgpt *** may not be trustable 

In Mongolia, the country is divided into aimags (provinces), which are further grouped into larger administrative units called regions. The regions in Mongolia are primarily defined for administrative and governance purposes. The number of regions and their specific boundaries can vary over time due to administrative changes. However, as of my knowledge cutoff in September 2021, Mongolia is divided into six regions:

Eastern Region (Dornod)

Provinces included: Dornod, Sukhbaatar, Khentii
Central Region (Tuv)

Provinces included: Tuv, Ulaanbaatar (capital city)
Western Region (Uvs)

Provinces included: Uvs, Bayan-Ulgii, Khovd, Zavkhan
Khangai Region (Arkhangai)

Provinces included: Arkhangai, Bayankhongor, Bulgan, Govi-Altai, Khovsgol, Orkhon, Uvurkhangai
Gobi Region (South Gobi)

Provinces included: Dundgovi, Dornogovi, Govi-Sumber, Omnogovi
Far Eastern Region (Dornod)

Provinces included: Dornod, Sukhbaatar, Khentii


*/

u "$dir_tempdata\cherry\\MNG", clear 


levelsof adm_1_loc if Country == "Mongolia"

/*
`"Arxangai"' `"Bayan-Olgii"' `"Bayankhongor"' `"Bulgan"' `"Darkhan-Uul"' `"Dornod"' `"Dornogovi"' `"Dundgovi"' `"Govi-Altai"' `"Govisumber"' `"Hentii"' `"Khovd"' `"Khovsgol"' `"Omnogovi"' `"Orkhon"' `"Ovorkhangai"' `"Selenge"' `"Sukhbaatar"' `"To'v"' `"Ulaanbaatar"' `"Uvs"' `"Zavkhan"'

*/

gen adm_05_loc = ""

replace adm_05_loc = "Ulaanbaatar" if Country == "Mongolia" & inlist(adm_1_loc, "Ulaanbaatar")

replace adm_05_loc = "Western" if Country == "Mongolia" & inlist(adm_1_loc, "Khovd", "Bayan-Olgii", "Uvs")

replace adm_05_loc = "Khangai" if Country == "Mongolia" & inlist(adm_1_loc, "Selenge", "Darkhan-Uul", "Orkhon", "Bulgan", "Arxangai", "Khovsgol", "Zavkhan") 

replace adm_05_loc = "Central" if Country == "Mongolia" & inlist(adm_1_loc, "To'v")

replace adm_05_loc = "Estern" if Country == "Mongolia" & inlist(adm_1_loc, "Hentii", "Dornod", "Sukhbaatar")

replace adm_05_loc = "Gobi" if Country == "Mongolia" & inlist(adm_1_loc, "Govisumber", "Dornogovi", "Dundgovi", "Omnogovi")

replace adm_05_loc = "Altai" if Country == "Mongolia" & inlist(adm_1_loc, "Govi-Altai", "Bayankhongor", "Ovorkhangai")



sa "$dir_tempdata\cherry\\MNG", replace 



********************************************************************************
* Thailand, need region division 
********************************************************************************

/*
https://en.wikipedia.org/wiki/Regions_of_Thailand

Grouping systems
A six-region system is commonly used for geographical and scientific purposes. This system dates to 1935.[1] It was formalised in 1977 by the National Geographical Committee, which was appointed by the National Research Council. It divides the country into the following regions:

Northern Thailand
Northeastern Thailand
Western Thailand
Central Thailand
Eastern Thailand
Southern Thailand
The four-region system, used in some administrative and statistical contexts, and also as a loose cultural grouping, includes the western and eastern regions within the central region, while grouping the provinces of Sukhothai, Phitsanulok, Phichit, Kamphaeng Phet, Phetchabun, Nakhon Sawan, and Uthai Thani in the northern region. This is also the regional system most commonly used on national television, when discussing regional events. It divides the country into the following regions:

Northern Thailand
Northeastern Thailand (Isan)
Central Thailand
Southern Thailand

For each, we check provinces included. 

In the four-region classification system, northern Thailand gains the eight upper-central-region provinces: Kamphaeng Phet, Nakhon Sawan, Phetchabun, Phichit, Phitsanulok, Sukhothai, Uthai Thani and Tak, bringing the total to 17 provinces.


In MICS data, there are central, north, northeast, south four regions. So, we assume MICS is using the four-region system. 
We can also check what provinces are included for each region in MICS: 

adm_05_loc	adm_1	adm_1_geocode	adm_1_loc
Central	province	18	Chai Nat
Central	province	27	Sa Kaeo
Central	province	70	Ratchaburi
Central	province	71	Kanchanaburi
North	province	58	Mae Hong Son
North	province	63	Tak
Northeast	province	31	Buriram
Northeast	province	33	Sisaket
Northeast	province	35	Yasothon
Northeast	province	46	Kalasin
Northeast	province	48	Nakhon Phanom
South	province	90	Songkhla
South	province	91	Satun
South	province	93	Phatthalung
South	province	94	Pattani
South	province	95	Yala
South	province	96	Narathiwat

*/



u "$dir_tempdata\cherry\\THA", clear 

levelsof adm_1_loc if Country == "Thailand"

/*

`"Amnat Charoen"' `"Ang Thong"' `"Bangkok"' `"Bueng Kan"' `"Buri Ram"' `"Chachoengsao"' `"Chai Nat"' `"Chaiyaphum"' `"Chanthaburi"' `"Chia
> ng Mai"' `"Chiang Rai"' `"Chon Buri"' `"Chumphon"' `"Kalasin"' `"Kamphaeng Phet"' `"Kanchanaburi"' `"Khon Kaen"' `"Krabi"' `"Lampang"' `
> "Lamphun"' `"Loei"' `"Lop Buri"' `"Mae Hong Son"' `"Maha Sarakham"' `"Mukdahan"' `"Nakhon Nayok"' `"Nakhon Pathom"' `"Nakhon Phanom"' `"
> Nakhon Ratchasima"' `"Nakhon Sawan"' `"Nakhon Si Thammarat"' `"Nan"' `"Narathiwat"' `"Nong Bua Lam Phu"' `"Nong Khai"' `"Nonthaburi"' `"
> Pathum Thani"' `"Pattani"' `"Phangnga"' `"Phatthalung"' `"Phayao"' `"Phetchabun"' `"Phetchaburi"' `"Phichit"' `"Phitsanulok"' `"Phra Nak
> hon Si Ayutthaya"' `"Phrae"' `"Phuket"' `"Prachin Buri"' `"Prachuap Khiri Khan"' `"Ranong"' `"Ratchaburi"' `"Rayong"' `"Roi Et"' `"Sa Ka
> eo"' `"Sakon Nakhon"' `"Samut Prakan"' `"Samut Sakhon"' `"Samut Songkhram"' `"Saraburi"' `"Satun"' `"Si Sa Ket"' `"Sing Buri"' `"Songkhl
> a"' `"Sukhothai"' `"Suphan Buri"' `"Surat Thani"' `"Surin"' `"Tak"' `"Trang"' `"Trat"' `"Ubon Ratchathani"' `"Udon Thani"' `"Uthai Thani
> "' `"Uttaradit"' `"Yala"' `"Yasothon"'

*/

/*
replace adm_05_loc = "Bangkok" if Country == "Thailand" & adm_1_loc == "Bangkok"

replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Ang Thong"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Ayutthaya"
// replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Bangkok (Special Administrative Area)"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Chachoengsao"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Chai Nat"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Chanthaburi"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Chonburi"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Kanchanaburi"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Lopburi"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Nakhon Nayok"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Nakhon Pathom"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Nonthaburi"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Pathum Thani"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Phetchaburi"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Prachinburi"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Prachuap Khiri Khan"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Ratchaburi"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Rayong"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Sa Kaeo"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Samut Prakan"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Samut Sakhon"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Samut Songkhram"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Saraburi"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Sing Buri"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Suphan Buri"
replace adm_05_loc = "Central" if Country == "Thailand" & adm_1_loc == "Trat"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Chiang Mai"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Chiang Rai"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Kamphaeng Phet"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Lampang"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Lamphun"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Mae Hong Son"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Nakhon Sawan"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Nan"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Phayao"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Phetchabun"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Phichit"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Phitsanulok"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Phrae"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Sukhothai"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Tak"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Uthai Thani"
replace adm_05_loc = "North" if Country == "Thailand" & adm_1_loc == "Uttaradit"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Amnat Charoen"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Bueng Kan"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Buri Ram"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Chaiyaphum"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Kalasin"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Khon Kaen"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Loei"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Maha Sarakham"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Mukdahan"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Nakhon Phanom"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Nakhon Ratchasima (Korat)"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Nong Bua Lamphu"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Nong Khai"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Roi Et"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Sakon Nakhon"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Sisaket"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Surin"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Ubon Ratchathani"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Udon Thani"
replace adm_05_loc = "Northeast" if Country == "Thailand" & adm_1_loc == "Yasothon"
replace adm_05_loc = "South" if Country == "Thailand" & adm_1_loc == "Chumphon"
replace adm_05_loc = "South" if Country == "Thailand" & adm_1_loc == "Krabi"
replace adm_05_loc = "South" if Country == "Thailand" & adm_1_loc == "Nakhon Si Thammarat"
replace adm_05_loc = "South" if Country == "Thailand" & adm_1_loc == "Narathiwat"
replace adm_05_loc = "South" if Country == "Thailand" & adm_1_loc == "Pattani"
replace adm_05_loc = "South" if Country == "Thailand" & adm_1_loc == "Phang Nga"
replace adm_05_loc = "South" if Country == "Thailand" & adm_1_loc == "Phatthalung"
replace adm_05_loc = "South" if Country == "Thailand" & adm_1_loc == "Phuket"
replace adm_05_loc = "South" if Country == "Thailand" & adm_1_loc == "Ranong"
replace adm_05_loc = "South" if Country == "Thailand" & adm_1_loc == "Satun"
replace adm_05_loc = "South" if Country == "Thailand" & adm_1_loc == "Songkhla"
replace adm_05_loc = "South" if Country == "Thailand" & adm_1_loc == "Surat Thani"
replace adm_05_loc = "South" if Country == "Thailand" & adm_1_loc == "Trang"
replace adm_05_loc = "South" if Country == "Thailand" & adm_1_loc == "Yala"

/* There is still some strings not matched. */
br if adm_05_loc == "" & Country == "Thailand"
levelsof adm_1_loc if adm_05_loc == "" & Country == "Thailand"

*/




/* Matches two columns or two datasets based on similar text patterns 
*******************************************************************************/

// ssc install matchit, replace 
// ssc install freqindex, replace
// ssc install reclink, replace

u "$dir_tempdata\cherry\\THA", clear
replace adm_1_loc = "Sisaket" if adm_1_loc == "Si Sa Ket"
sa "$dir_tempdata\cherry\\THA", replace

*** prepare boundary file 
keep adm_1_loc 
duplicates drop
rename adm_1_loc adm_1_loc_boundary
sort adm_1_loc_boundary
gen id_boundary = _n

sa "$dir_tempdata\cherry\\tha_boundary", replace



*** prepare file with region and province division from wikipedia 
clear
import excel "$dir_rawdata\loc_id\boundary_shapefile\\tha_region_province.xlsx", sheet("Sheet1") firstrow 

sa "$dir_tempdata\cherry\\tha_region_province", replace

keep adm_1_loc
rename adm_1_loc adm_1_loc_province
sort adm_1_loc_province
gen id_province = _n

sa "$dir_tempdata\cherry\\tha_province", replace 



*** match province name from boundary file with that in region-province file 
u "$dir_tempdata\cherry\\tha_boundary", clear

matchit id_boundary adm_1_loc_boundary using "$dir_tempdata\cherry\\tha_province.dta", idusing(id_province) txtusing(adm_1_loc_province) 

// matchit id_mics adm_1_loc_mics using "$dir_tempdata\cherry\\tha_province.dta", idusing(id_province) txtusing(adm_1_loc_province) override

// reclink adm_1_loc using "$dir_tempdata\cherry\\thailand_province", idmaster(adm_1_loc_province) idusing(adm_1_loc) gen(matchscore)

/* pick the most matching string 
manually compare those, leave the observation with highestscore
without replacing similscore by integer, highestscore == similscore may not work correctly.  
Bangkok and Sisaket do not match. In MICS, it is Sisaket. 

*/

replace similscore = round(similscore*100000) 
bys adm_1_loc_province: egen highestscore = max(similscore)
// drop if highestscore == 1 & similscore != 1 
keep if highestscore == similscore

sort id_boundary

drop similscore highestscore
drop id*
rename adm_1_loc_province adm_1_loc

merge 1:1 adm_1_loc using "$dir_tempdata\cherry\\tha_region_province"
// all provinces matched 
drop _merge
drop adm_1_loc 
rename adm_1_loc_boundary adm_1_loc

sa "$dir_tempdata\cherry\\tha_region", replace


u "$dir_tempdata\cherry\\THA", clear
merge m:1 adm_1_loc using "$dir_tempdata\cherry\\tha_region"
// all provinces matched
drop _merge 

drop adm_05 adm_1
sort adm_05_loc adm_1_loc adm_2_loc
order Country ISO_alpha_2 adm_05 adm_05_loc adm_1* adm_2* 
replace adm_05_loc = "Bangkok" if adm_1_loc == "Bangkok"

sa "$dir_tempdata\cherry\\THA", replace 







********************************************************************************
* output a table containing all location name and geocode 
********************************************************************************

u "$dir_tempdata\cherry\\BGD", clear
foreach i in "KGZ" "MNG" "NPL" "PAK" "THA" "TKM" {
	append using "$dir_tempdata\cherry\\`i'", force
}

sa "$dir_data\id_key_file\boundary_loc_id", replace 

********************************************************************************
* modify some names as we need name string to match with mics and emdat data 
********************************************************************************

u "$dir_data\id_key_file\boundary_loc_id", clear 

gen ISO_alpha_3 = "", after(ISO_alpha_2)
replace ISO_alpha_3 = "BGD" if ISO_alpha_2 == "BD"
replace ISO_alpha_3 = "KGZ" if ISO_alpha_2 == "KG"
replace ISO_alpha_3 = "MNG" if ISO_alpha_2 == "MN"
replace ISO_alpha_3 = "NPL" if ISO_alpha_2 == "NP"
replace ISO_alpha_3 = "PAK" if ISO_alpha_2 == "PK"
replace ISO_alpha_3 = "THA" if ISO_alpha_2 == "TH"
replace ISO_alpha_3 = "TKM" if ISO_alpha_2 == "TM"

order Country ISO_alpha_2 ISO_alpha_3 adm_05_loc adm_1_pcode adm_1_loc adm_2_pcode adm_2_loc 
sort Country ISO_alpha_2 ISO_alpha_3 adm_05_loc adm_1_loc adm_2_loc

sa "$dir_data\id_key_file\boundary_loc_id", replace 



/* Denote which level the finest admin level is for each country 
*******************************************************************************/

gen finest_adm_level = 0.5
replace finest_adm_level = 1 if adm_1_loc != ""
replace finest_adm_level = 2 if adm_2_loc != ""

order finest_adm_level, after(ISO_alpha_3)

sa "$dir_data\id_key_file\boundary_loc_id", replace 



/* THA duplicated names 

There are two districts having name as Bang Sai, both in province Phra Nakhon Si Ayutthaya province, central Thailand. We change the name as "Bang Sai 1404" and "Bang Sai 1413"

https://en.wikipedia.org/wiki/Bang_Sai_district_(1404)

https://en.wikipedia.org/wiki/Bang_Sai_district_(1413)
*******************************************************************************/

duplicates tag ISO_alpha_3 finest_adm_level adm_05_loc adm_1_loc adm_2_loc, gen(flag)
fre flag
br if flag != 0
drop flag
replace adm_2_loc = "Bang Sai 1404" if adm_2_loc == "Bang Sai" & adm_2_pcode == "TH1404"
replace adm_2_loc = "Bang Sai 1413" if adm_2_loc == "Bang Sai" & adm_2_pcode == "TH1413"

sa "$dir_data\id_key_file\boundary_loc_id", replace 



/* NPL province names 

For Nepal, the province name is empty. Fill them with pcode of location. 
Check EMDAT, I find NPL location names are not using "Province No.1", but rather province names. 
So, I put province names in the boundary file. 
*******************************************************************************/

replace adm_1_loc = "Province No 1" if ISO_alpha_3 == "NPL" & adm_1_pcode == "NP01"
replace adm_1_loc = "Province No 2 Madhesh" if ISO_alpha_3 == "NPL" & adm_1_pcode == "NP02"
replace adm_1_loc = "Province No 3 Bagmati" if ISO_alpha_3 == "NPL" & adm_1_pcode == "NP03"
replace adm_1_loc = "Province No 4 Gandaki" if ISO_alpha_3 == "NPL" & adm_1_pcode == "NP04"
replace adm_1_loc = "Province No 5 Lumbini" if ISO_alpha_3 == "NPL" & adm_1_pcode == "NP05"
replace adm_1_loc = "Province No 6 Karnali" if ISO_alpha_3 == "NPL" & adm_1_pcode == "NP06"
replace adm_1_loc = "Province No 7 Sudur Pashchim" if ISO_alpha_3 == "NPL" & adm_1_pcode == "NP07"

sa "$dir_data\id_key_file\boundary_loc_id", replace 



/* KGZ independent city, same adm level as region (oblast)

https://en.wikipedia.org/wiki/Regions_of_Kyrgyzstan

The capital, Bishkek, is administered as an independent city of republican significance, as well as being the capital of Chüy Region. Osh also has independent city status since 2003.
*******************************************************************************/

local countryiso = "KGZ"

clear
import excel "$dir_rawdata\loc_id\boundary_shapefile\\`countryiso'_adminboundaries_tabulardata.xlsx", sheet("ADM1") firstrow

keep ADM1_EN ADM1_PCODE ADM0_EN ADM0_PCODE

duplicates drop

sort ADM1_PCODE 

order ADM0_EN ADM0_PCODE ADM1_PCODE ADM1_EN 
rename ADM0_EN Country
rename ADM0_PCODE ISO_alpha_2

rename ADM1_EN adm_1_loc 

rename ADM1_PCODE adm_1_pcode

gen ISO_alpha_3 = "KGZ"
gen finest_adm_level = 1
replace adm_1_loc = subinstr(adm_1_loc, "(", "", .)
replace adm_1_loc = subinstr(adm_1_loc, ")", "", .)

sa "$dir_tempdata\cherry\\`countryiso'_APPEND", replace 


u "$dir_data\id_key_file\boundary_loc_id", clear 
append using "$dir_tempdata\cherry\\`countryiso'_APPEND" 
sa "$dir_data\id_key_file\boundary_loc_id", replace 


sort ISO_alpha_3 finest_adm_level adm_05_loc adm_1_loc adm_2_loc

sa "$dir_data\id_key_file\boundary_loc_id", replace 
export delimited using "$dir_data\id_key_file\boundary_loc_id.csv", replace



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


