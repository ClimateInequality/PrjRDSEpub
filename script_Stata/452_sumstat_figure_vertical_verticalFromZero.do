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

global today "20231221"

log using "$dir_log\452_sumstat_figure_verticalFromZero_$today.log", replace


efolder apple, cd("$dir_tempdata")
cd "$dir_program"

global st_computer "yz"
global st_group "ss"
efolder $st_computer, cd("$dir_figure")
efolder $st_group, cd("$dir_figure\\${st_computer}")
cd "$dir_program"

global dir_path "$dir_figure\\${st_computer}\\${st_group}"

********************************************************************************
* TASK: Create summary statistics 
********************************************************************************

/**************
Sample size 
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear
count
fre countryfile

collapse (count) n=HH2, by(countryfile kid_age)

cap drop countryfile_num
cap egen countryfile_num = group(countryfile), label
cap egen countryfile_num = group(countryfile)
fre countryfile_num
cap drop countryfile
reshape wide n, i(kid_age) j(countryfile_num)

cap gen age = 1
global lbl_legend `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local title "Sample Size Across Countries and Ages"
local title ""

graph bar (sum) n1 n2 n3 n4 n5 n6 n7 n8 n9 n10 ///
	if inrange(kid_age, 5, 17), ///
	stack ///
	over(kid_age, label(labsize(small)) axis(lcolor(none))) ///
	over(age, relabel(1 "Age of children") label(labsize(median)) axis(lcolor(none))) ///
	bargap(-30) ///
	xsize(10) legend(position(3) ring(1) cols(1) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(2000)16000) ///
	ytitle("Number of children in sample", size(median)) ///
	title("`title'", size(large)) 

gr export "$dir_path\SS1.T1.1.png", replace as(png)

/*
There is no xtitle option for graph bar according to 
https://www.stata.com/manuals/g-2graphbar.pdf

ytitle() overrides the default title for the numerical y axis; see [G-3] axis title options. There you will also find option xtitle() documented, which is irrelevant for bar charts.

To add xtitle, we create variable `age'. 
*/

/*
graph bar (sum) n1 n2 n3 n4 n5 n6 n7 n8 n9 n10 ///
	if inrange(kid_age, 5, 17), ///
	stack over(kid_age) ///
	xsize(10) legend(position(3) ring(1) cols(1) symxsize(small) symysize(small) order(${lbl_countryfile})) 
	
	bar(1, lwidth(vvthin)) ///
	bar(2, lwidth(vvthin)) ///
	bar(3, lwidth(*0.3)) ///
	bar(4, barw(thin)) ///
	bar(5, lwidth(thin)) ///
	bar(6, lwidth(thin)) ///
	bar(7, lwidth(thin)) ///
	bar(8, lwidth(thin)) ///
	bar(9, lwidth(thin)) ///
	bar(10, lwidth(thin)) ///
	

twoway (line HH2 kid_age), ///
xtitle("Age of children") ///
ytitle("") xscale(range(5(1)17)) xlabel(5(1)17) yscale(range(2000 16000)) ylabel(2000(2000)16000)
gr export "$dir_figure\India_disaster_descriptive\fig1.png", replace as(png)

*/

	
/**************
Sample Size Across Gender and Ages
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

collapse (count) n=HH2, by(kid_female kid_age)

global lbl_legend `" 0 "" 1 "Male" 2 "Female" "'

cap gen kid_age1 = kid_age - 0.2
cap gen kid_age2 = kid_age + 0.2

twoway (bar n kid_age1 if kid_female == 0, barw(0.4)) ///
	(bar n kid_age2 if kid_female == 1, barw(0.4)) ///
	if inrange(kid_age, 5, 17), ///
	legend(position(1) ring(0) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(4000(1000)8000) ///
	ytick(4000(1000)8000) ///
	yscale(range(4000(1000)8000)) ///
	ytitle("Number of children in sample", size(median)) ///
	xlabel(5(1)17) xtitle("Age of children", size(median)) ///
	title("`title'", size(large)) 

gr export "$dir_path\SS5.T1.2.png", replace as(png)

/*
cap gen age = 1

local title "Sample size across gender and ages"
local title ""

graph bar n ///
	if inrange(kid_age, 5, 17), ///
	over(kid_female, label(labsize(small)) axis(lcolor(none))) ///
	over(kid_age, label(labsize(small)) axis(lcolor(none))) ///
	over(age, relabel(1 "Age of children") label(labsize(large)) axis(lcolor(none))) ///
	bargap(-10) ///
	legend(position(1) ring(0) cols(3) symxsize(large) symysize(large) order(${lbl_female})) ///
	ylabel(4000(2000)8000) ///
	ytick(4000(2000)8000) ///
	yscale(range(4000(2000)8000)) ///
	ytitle("") ///
	title("`title'", size(large)) 

gr export "$dir_path\SS1.T1.2.png", replace as(png)
*/

/**************
Share of Children with Mother or Father Alive by Ages
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

collapse (mean) n1=mo_alive n2=fa_alive , by(kid_age)
replace n1 = n1*100
replace n2 = n2*100

global lbl_legend `" 0 "" 1 "Mother being alive" 2 "Father being alive" "'

local title "Share of Children with Mother or Father Alive by Ages"
local title ""

cap gen kid_age1 = kid_age - 0.2
cap gen kid_age2 = kid_age + 0.2

twoway (bar n1 kid_age1, barw(0.4)) ///
	(bar n2 kid_age2, barw(0.4)) ///
	if inrange(kid_age, 5, 17), ///
	legend(position(1) ring(1) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children (%)") ///
	xlabel(5(1)17) xtitle("Age of children") ///
	title("`title'", size(large)) 

gr export "$dir_path\SS5.T2.1.png", replace as(png)

/**************
Share of Parents Living with  Mother or Father by Ages
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

collapse (mean) n1=mo_inHH n2=fa_inHH , by(kid_age)
replace n1 = n1*100
replace n2 = n2*100

global lbl_legend `" 0 "" 1 "Mother lives in HH" 2 "Father lives in HH" "'

local title "Share of Parents Living with  Mother or Father by Ages"
local title ""

cap gen kid_age1 = kid_age - 0.2
cap gen kid_age2 = kid_age + 0.2

twoway (bar n1 kid_age1, barw(0.4)) ///
	(bar n2 kid_age2, barw(0.4)) ///
	if inrange(kid_age, 5, 17), ///
	legend(position(1) ring(1) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children (%)") ///
	xlabel(5(1)17) xtitle("Age of children") ///
	title("`title'", size(large)) 

gr export "$dir_path\SS5.T3.1.png", replace as(png)

/**************
Share of Children Ever Enrolled in Any Education Program of School by Ages and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

collapse (mean) n=E_ever, by(countryfile kid_age)
replace n = n*100

global lbl_legend `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T2.5"
local title "Share of Children Ever Enrolled in Any Education Program of School by Ages and Countries"
local title ""

twoway (connected n kid_age if countryfile == "BGD2019") ///
	(connected n kid_age if countryfile == "KGZ2018") ///
	(connected n kid_age if countryfile == "MNG2018") ///
	(connected n kid_age if countryfile == "NPL2019") ///
	(connected n kid_age if countryfile == "PKK2019") ///
	(connected n kid_age if countryfile == "PKP2017") ///
	(connected n kid_age if countryfile == "PKS2018") ///
	(connected n kid_age if countryfile == "THA2019") ///
	(connected n kid_age if countryfile == "T172019") ///
	(connected n kid_age if countryfile == "TKM2019") ///
	if inrange(kid_age, 5, 17), ///
	legend(position(3) ring(1) cols(1) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children (%)") ///
	xlabel(5(1)17) xtitle("Age of children") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)

/*
cap drop countryfile_num
cap egen countryfile_num = group(countryfile), label
xtset countryfile_num kid_age
xtline n, overlay 
*/


/**************
Share of Children Ever Enrolled in Any Education Program of School by Gender and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

collapse (mean) n=E_ever, by(countryfile kid_female)
replace n = n*100
cap drop countryfile_num
cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "Male" 2 "Female" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T2.6"
local title "Share of Children Ever Enrolled in Any Education Program of School by Gender and Countries"
local title ""

cap gen countryfile_num1 = countryfile_num - 0.2
cap gen countryfile_num2 = countryfile_num + 0.2

twoway (bar n countryfile_num1 if kid_female == 0, barw(0.4)) ///
	(bar n countryfile_num2 if kid_female == 1, barw(0.4)), ///
	legend(position(1) ring(1) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children (%)") ///
	xlabel(${lbl_xaxis}, angle(45)) xtitle("Country/region") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)


/**************
Average of Years of Education Completed by Ages and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

collapse (mean) n=A_t, by(countryfile kid_age)

global lbl_legend `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T4.1"
local title "Average of Years of Education Completed by Ages and Countries"
local title ""

twoway (connected n kid_age if countryfile == "BGD2019") ///
	(connected n kid_age if countryfile == "KGZ2018") ///
	(connected n kid_age if countryfile == "MNG2018") ///
	(connected n kid_age if countryfile == "NPL2019") ///
	(connected n kid_age if countryfile == "PKK2019") ///
	(connected n kid_age if countryfile == "PKP2017") ///
	(connected n kid_age if countryfile == "PKS2018") ///
	(connected n kid_age if countryfile == "THA2019") ///
	(connected n kid_age if countryfile == "T172019") ///
	(connected n kid_age if countryfile == "TKM2019") ///
	if inrange(kid_age, 5, 17), ///
	legend(position(3) ring(1) cols(1) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(2)12) ///
	ytick(0(2)12) ///
	yscale(range(0(2)12)) ///
	ytitle("Year of education") ///
	xlabel(5(1)17) xtitle("Age of children") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)

/**************
Average of Years of Education Completed by Gender and Countries (All Available Ages)
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

collapse (mean) n=A_t, by(countryfile kid_female)

cap drop countryfile_num
cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "Male" 2 "Female" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T4.2"
local title "Average of Years of Education Completed by Gender and Countries (All Available Ages)"
local title ""

cap gen countryfile_num1 = countryfile_num - 0.2
cap gen countryfile_num2 = countryfile_num + 0.2

twoway (bar n countryfile_num1 if kid_female == 0, barw(0.4)) ///
	(bar n countryfile_num2 if kid_female == 1, barw(0.4)), ///
	legend(position(1) ring(1) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(1)5) ///
	ytick(0(1)5) ///
	yscale(range(0(1)5)) ///
	ytitle("Year of education") ///
	xlabel(${lbl_xaxis}, angle(45)) xtitle("Country/region") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)

/**************
Enrollment Rate in This Year by Ages and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

collapse (mean) n=E_t, by(countryfile kid_age)
replace n = n*100

global lbl_legend `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T2.1"
local title "Enrollment Rate in This Year by Ages and Countries"
local title ""

twoway (connected n kid_age if countryfile == "BGD2019") ///
	(connected n kid_age if countryfile == "KGZ2018") ///
	(connected n kid_age if countryfile == "MNG2018") ///
	(connected n kid_age if countryfile == "NPL2019") ///
	(connected n kid_age if countryfile == "PKK2019") ///
	(connected n kid_age if countryfile == "PKP2017") ///
	(connected n kid_age if countryfile == "PKS2018") ///
	(connected n kid_age if countryfile == "THA2019") ///
	(connected n kid_age if countryfile == "T172019") ///
	(connected n kid_age if countryfile == "TKM2019") ///
	if inrange(kid_age, 5, 17), ///
	legend(position(3) ring(1) cols(1) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children (%)") ///
	xlabel(5(1)17) xtitle("Age of children") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)

/**************
Enrollment Rate in This Year by Gender and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

collapse (mean) n=E_t, by(countryfile kid_female)
replace n = n*100

cap drop countryfile_num
cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "Male" 2 "Female" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T2.2"
local title "Enrollment Rate in This Year by Gender and Countries"
local title ""

cap gen countryfile_num1 = countryfile_num - 0.2
cap gen countryfile_num2 = countryfile_num + 0.2

twoway (bar n countryfile_num1 if kid_female == 0, barw(0.4)) ///
	(bar n countryfile_num2 if kid_female == 1, barw(0.4)), ///
	legend(position(1) ring(1) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children (%)") ///
	xlabel(${lbl_xaxis}, angle(45)) xtitle("Country/region") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)














/**************
Retention Rate in This Year by Ages and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

keep if kid_age >= 8

collapse (mean) n=R_t, by(countryfile kid_age)
replace n = n*100

global lbl_legend `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T6.1"
local title "Retention Rate in This Year by Ages and Countries"
local title ""

twoway (connected n kid_age if countryfile == "BGD2019") ///
	(connected n kid_age if countryfile == "KGZ2018") ///
	(connected n kid_age if countryfile == "MNG2018") ///
	(connected n kid_age if countryfile == "NPL2019") ///
	(connected n kid_age if countryfile == "PKK2019") ///
	(connected n kid_age if countryfile == "PKP2017") ///
	(connected n kid_age if countryfile == "PKS2018") ///
	(connected n kid_age if countryfile == "THA2019") ///
	(connected n kid_age if countryfile == "T172019") ///
	(connected n kid_age if countryfile == "TKM2019") ///
	if inrange(kid_age, 5, 17), ///
	legend(position(3) ring(1) cols(1) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)50) ///
	ytick(0(10)50) ///
	yscale(range(0(10)50)) ///
	ytitle("Share of children (%)") ///
	xlabel(8(1)17) xtitle("Age of children") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)

/**************
Retention Rate in This Year by Gender and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

keep if kid_age >= 8

collapse (mean) n=R_t, by(countryfile kid_female)
replace n = n*100

cap drop countryfile_num
cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "Male" 2 "Female" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T6.2"
local title "Retention Rate in This Year by Gender and Countries"
local title ""

cap gen countryfile_num1 = countryfile_num - 0.2
cap gen countryfile_num2 = countryfile_num + 0.2

twoway (bar n countryfile_num1 if kid_female == 0, barw(0.4)) ///
	(bar n countryfile_num2 if kid_female == 1, barw(0.4)), ///
	legend(position(1) ring(1) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)50) ///
	ytick(0(10)50) ///
	yscale(range(0(10)50)) ///
	ytitle("Share of children (%)") ///
	xlabel(${lbl_xaxis}, angle(45)) xtitle("Country/region") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)




/**************
* Progression Rate in This Year by Ages and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

keep if kid_age >= 8

collapse (mean) n=P_t_1, by(countryfile kid_age)
replace n = n*100

global lbl_legend `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T5.1"
local title "Progression Rate in This Year by Ages and Countries"
local title ""

twoway (connected n kid_age if countryfile == "BGD2019") ///
	(connected n kid_age if countryfile == "KGZ2018") ///
	(connected n kid_age if countryfile == "MNG2018") ///
	(connected n kid_age if countryfile == "NPL2019") ///
	(connected n kid_age if countryfile == "PKK2019") ///
	(connected n kid_age if countryfile == "PKP2017") ///
	(connected n kid_age if countryfile == "PKS2018") ///
	(connected n kid_age if countryfile == "THA2019") ///
	(connected n kid_age if countryfile == "T172019") ///
	(connected n kid_age if countryfile == "TKM2019") ///
	if inrange(kid_age, 5, 17), ///
	legend(position(3) ring(1) cols(1) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children (%)") ///
	xlabel(8(1)17) xtitle("Age of children") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)

/**************
Progression Rate in This Year by Gender and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

keep if kid_age >= 8

collapse (mean) n=P_t_1, by(countryfile kid_female)
replace n = n*100

cap drop countryfile_num
cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "Male" 2 "Female" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T5.2"
local title "Progression Rate in This Year by Gender and Countries"
local title ""

cap gen countryfile_num1 = countryfile_num - 0.2
cap gen countryfile_num2 = countryfile_num + 0.2

twoway (bar n countryfile_num1 if kid_female == 0, barw(0.4)) ///
	(bar n countryfile_num2 if kid_female == 1, barw(0.4)), ///
	legend(position(1) ring(1) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children (%)") ///
	xlabel(${lbl_xaxis}, angle(45)) xtitle("Country/region") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)


/**************
Average of Math Test Score by Ages and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

keep if inrange(kid_age, 7, 14)

collapse (mean) n=math_score_total, by(countryfile kid_age)

global lbl_legend `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T7.1"
local title "Average of Math Test Score by Ages and Countries"
local title ""

twoway (connected n kid_age if countryfile == "BGD2019") ///
	(connected n kid_age if countryfile == "KGZ2018") ///
	(connected n kid_age if countryfile == "MNG2018") ///
	(connected n kid_age if countryfile == "NPL2019") ///
	(connected n kid_age if countryfile == "PKK2019") ///
	(connected n kid_age if countryfile == "PKP2017") ///
	(connected n kid_age if countryfile == "PKS2018") ///
	(connected n kid_age if countryfile == "THA2019") ///
	(connected n kid_age if countryfile == "T172019") ///
	(connected n kid_age if countryfile == "TKM2019") ///
	if inrange(kid_age, 5, 17), ///
	legend(position(3) ring(1) cols(1) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(5)20 21) ///
	ytick(0(5)20 21) ///
	yscale(range(0(5)20 21)) ///
	ytitle("Average of math test score") ///
	xlabel(7(1)14) xtitle("Age of children") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)

/**************
Average of Math Test Score by Gender and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

keep if inrange(kid_age, 7, 14)

collapse (mean) n=math_score_total, by(countryfile kid_female)

cap drop countryfile_num
cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "Male" 2 "Female" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T7.2"
local title "Average of Math Test Score by Gender and Countries"
local title ""

cap gen countryfile_num1 = countryfile_num - 0.2
cap gen countryfile_num2 = countryfile_num + 0.2

twoway (bar n countryfile_num1 if kid_female == 0, barw(0.4)) ///
	(bar n countryfile_num2 if kid_female == 1, barw(0.4)), ///
	legend(position(1) ring(1) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(5)20 21) ///
	ytick(0(5)20 21) ///
	yscale(range(0(5)20 21)) ///
	ytitle("Average of math test score") ///
	xlabel(${lbl_xaxis}, angle(45)) xtitle("Country/region") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)



/**************
Math Test Sample Size by Ages and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

keep if inrange(kid_age, 7, 14)

collapse (mean) n=S_math_bi, by(countryfile kid_age)
replace n = n*100

global lbl_legend `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T1.5.a"
local title "Math Test Sample Size by Ages and Countries"
local title ""

twoway (connected n kid_age if countryfile == "BGD2019") ///
	(connected n kid_age if countryfile == "KGZ2018") ///
	(connected n kid_age if countryfile == "MNG2018") ///
	(connected n kid_age if countryfile == "NPL2019") ///
	(connected n kid_age if countryfile == "PKK2019") ///
	(connected n kid_age if countryfile == "PKP2017") ///
	(connected n kid_age if countryfile == "PKS2018") ///
	(connected n kid_age if countryfile == "THA2019") ///
	(connected n kid_age if countryfile == "T172019") ///
	(connected n kid_age if countryfile == "TKM2019") ///
	if inrange(kid_age, 5, 17), ///
	legend(position(3) ring(1) cols(1) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children having math test score (%)") ///
	xlabel(7(1)14) xtitle("Age of children") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)

/**************
Math Test Sample Size by Enrollment Status in Current Year Across Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

keep if inrange(kid_age, 7, 14)

collapse (mean) n=S_math_bi, by(countryfile E_t)
replace n = n*100

cap drop countryfile_num
cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "Not enrolled" 2 "Enrolled" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T1.5.b"
local title "Math Test Sample Size by Enrollment Status in Current Year Across Countries"
local title ""

cap gen countryfile_num1 = countryfile_num - 0.2
cap gen countryfile_num2 = countryfile_num + 0.2

twoway (bar n countryfile_num1 if E_t == 0, barw(0.4)) ///
	(bar n countryfile_num2 if E_t == 1, barw(0.4)), ///
	legend(position(1) ring(1) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children having math test score (%)") ///
	xlabel(${lbl_xaxis}, angle(45)) xtitle("Country/region") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)


/**************
Reading Test Sample Size by Ages and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

keep if inrange(kid_age, 7, 14)

collapse (mean) n=S_read_bi, by(countryfile kid_age)
replace n = n*100

global lbl_legend `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T1.6.a"
local title "Reading Test Sample Size by Ages and Countries"
local title ""

twoway (connected n kid_age if countryfile == "BGD2019") ///
	(connected n kid_age if countryfile == "KGZ2018") ///
	(connected n kid_age if countryfile == "MNG2018") ///
	(connected n kid_age if countryfile == "NPL2019") ///
	(connected n kid_age if countryfile == "PKK2019") ///
	(connected n kid_age if countryfile == "PKP2017") ///
	(connected n kid_age if countryfile == "PKS2018") ///
	(connected n kid_age if countryfile == "THA2019") ///
	(connected n kid_age if countryfile == "T172019") ///
	(connected n kid_age if countryfile == "TKM2019") ///
	if inrange(kid_age, 5, 17), ///
	legend(position(3) ring(1) cols(1) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children having reading test score (%)") ///
	xlabel(7(1)14) xtitle("Age of children") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)

/**************
Reading Test Sample Size by Enrollment Status in Current Year Across Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

keep if inrange(kid_age, 7, 14)

collapse (mean) n=S_read_bi, by(countryfile E_t)
replace n = n*100

cap drop countryfile_num
cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "Not enrolled" 2 "Enrolled" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T1.6.b"
local title "Reading Test Sample Size by Enrollment Status in Current Year Across Countries"
local title ""

cap gen countryfile_num1 = countryfile_num - 0.2
cap gen countryfile_num2 = countryfile_num + 0.2

twoway (bar n countryfile_num1 if E_t == 0, barw(0.4)) ///
	(bar n countryfile_num2 if E_t == 1, barw(0.4)), ///
	legend(position(1) ring(1) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children having reading test score (%)") ///
	xlabel(${lbl_xaxis}, angle(45)) xtitle("Country/region") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)







/**************
Average of Reading Test Score by Ages and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

keep if inrange(kid_age, 7, 14)

collapse (mean) n=read_score_total, by(countryfile kid_age)

global lbl_legend `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T8.1"
local title "Average of Reading Test Score by Ages and Countries"
local title ""

twoway (connected n kid_age if countryfile == "BGD2019") ///
	(connected n kid_age if countryfile == "KGZ2018") ///
	(connected n kid_age if countryfile == "MNG2018") ///
	(connected n kid_age if countryfile == "NPL2019") ///
	(connected n kid_age if countryfile == "PKK2019") ///
	(connected n kid_age if countryfile == "PKP2017") ///
	(connected n kid_age if countryfile == "PKS2018") ///
	(connected n kid_age if countryfile == "THA2019") ///
	(connected n kid_age if countryfile == "T172019") ///
	(connected n kid_age if countryfile == "TKM2019") ///
	if inrange(kid_age, 5, 17), ///
	legend(position(3) ring(1) cols(1) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(68(2)78) ///
	ytick(68(2)78) ///
	yscale(range(68(2)78)) ///
	ytitle("Average of reading test score") ///
	xlabel(7(1)14) xtitle("Age of children") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)

/**************
Average of Reading Test Score in This Year by Gender and Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

keep if inrange(kid_age, 7, 14)

collapse (mean) n=read_score_total, by(countryfile kid_female)

cap drop countryfile_num
cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "Male" 2 "Female" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T8.2"
local title "Average of Reading Test Score in This Year by Gender and Countries"
local title ""

cap gen countryfile_num1 = countryfile_num - 0.2
cap gen countryfile_num2 = countryfile_num + 0.2

twoway (bar n countryfile_num1 if kid_female == 0, barw(0.4)) ///
	(bar n countryfile_num2 if kid_female == 1, barw(0.4)), ///
	legend(position(1) ring(1) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(68(2)78) ///
	ytick(68(2)78) ///
	yscale(range(68(2)78)) ///
	ytitle("Average of reading test score") ///
	xlabel(${lbl_xaxis}, angle(45)) xtitle("Country/region") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)




/**************
Share of Children Whose Mother Has Some Education
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

collapse (mean) n1=mo_elevel_E_ever n2=mo_elevel_A_secondary, by(countryfile)
replace n1=n1*100
replace n2=n2*100

cap drop countryfile_num
cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "Mother ever educated" 2 "Mother has secondary school education" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS5.T4.1"
local title "Share of Children Whose Mother Has Some Education"
local title ""

cap gen countryfile_num1 = countryfile_num - 0.2
cap gen countryfile_num2 = countryfile_num + 0.2

twoway (bar n1 countryfile_num1, barw(0.4)) ///
	(bar n2 countryfile_num2, barw(0.4)), ///
	legend(position(1) ring(1) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children (%)") ///
	xlabel(${lbl_xaxis}, angle(45)) xtitle("Country/region") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)



/**************
Share of Children with Both or One Parent Alive by Ages
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

cap drop pa_alive
egen pa_alive = group(mo_alive fa_alive), label
fre pa_alive
la def pa_alive 1 "No parents alive" 2 "Only father alive" 3 "Only mother alive" 4 "Both parents alive", replace 
la val pa_alive pa_alive
fre pa_alive
drop if pa_alive == .
keep if inrange(kid_age, 5, 17)

tab pa_alive, gen(pa_alive_dm)

collapse (mean) n1=pa_alive_dm1 n2=pa_alive_dm2 n3=pa_alive_dm3 n4=pa_alive_dm4, by(kid_age)
foreach v of varlist n1-n4 {
	replace `v'=`v'*100
}

// cap drop countryfile_num
// cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "No parents alive" 2 "Only father alive" 3 "Only mother alive" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS5.T2.2"
local title "Share of Children with Both or One Parent Alive by Ages"
local title ""

cap gen countryfile_num1 = countryfile_num - 0.2
cap gen countryfile_num2 = countryfile_num + 0.2

cap gen age = 1

graph bar (sum) n1 n2 n3 ///
	, ///
	stack ///
	over(kid_age, label(labsize(small)) axis(lcolor(none))) ///
	over(age, relabel(1 "Age of children") label(labsize(m)) axis(lcolor(none))) ///
	bargap(-30) ///
	xsize(10) legend(position(6) ring(1) cols(4) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(5)15) ///
	ytick(0(5)15) ///
	yscale(range(0(5)15)) ///
	ytitle("Share of children (%)") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)


/**************
Share of Children (Age $\ge$ 12) with Both or One Parent Alive by Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

cap drop pa_alive
egen pa_alive = group(mo_alive fa_alive), label
fre pa_alive
la def pa_alive 1 "No parents alive" 2 "Only father alive" 3 "Only mother alive" 4 "Both parents alive", replace 
la val pa_alive pa_alive
fre pa_alive
drop if pa_alive == .
keep if inrange(kid_age, 12, 17) // NOTE: We keep only children above 12 here!!!

tab pa_alive, gen(pa_alive_dm)

collapse (mean) n1=pa_alive_dm1 n2=pa_alive_dm2 n3=pa_alive_dm3 n4=pa_alive_dm4, by(countryfile)
foreach v of varlist n1-n4 {
	replace `v'=`v'*100
}

cap drop countryfile_num
cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "No parents alive" 2 "Only father alive" 3 "Only mother alive" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS5.T2.3"
local title "Share of Children (Age $\ge$ 12) with Both or One Parent Alive by Countries"
local title ""

cap gen countryfile_num1 = countryfile_num - 0.2
cap gen countryfile_num2 = countryfile_num + 0.2

cap gen country = 1

graph bar (sum) n1 n2 n3 ///
	, ///
	stack ///
	over(countryfile_num, relabel(${lbl_xaxis}) label(labsize(small)) axis(lcolor(none))) ///
	over(country, relabel(1 "Country/region") label(labsize(m)) axis(lcolor(none))) ///
	bargap(-30) ///
	xsize(10) legend(position(6) ring(1) cols(4) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(5)15) ///
	ytick(0(5)15) ///
	yscale(range(0(5)15)) ///
	ytitle("Share of children (%)") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)




/**************
Share of Children Living with Both or One Parent by Ages
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

cap drop pa_inHH
egen pa_inHH = group(mo_inHH fa_inHH), label
fre pa_inHH
la def pa_inHH 1 "No parents living in HH" 2 "Only father living in HH" 3 "Only mother living in HH" 4 "Both parents living in HH", replace 
la val pa_inHH pa_inHH
fre pa_inHH
drop if pa_inHH == .
keep if inrange(kid_age, 5, 17)

tab pa_inHH, gen(pa_inHH_dm)

collapse (mean) n1=pa_inHH_dm1 n2=pa_inHH_dm2 n3=pa_inHH_dm3 n4=pa_inHH_dm4, by(kid_age)
foreach v of varlist n1-n4 {
	replace `v'=`v'*100
}

// cap drop countryfile_num
// cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "No parents living in HH" 2 "Only father living in HH" 3 "Only mother living in HH" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS5.T3.2"
local title "Share of Children Living with Both or One Parent by Ages"
local title ""

cap gen countryfile_num1 = countryfile_num - 0.2
cap gen countryfile_num2 = countryfile_num + 0.2

cap gen age = 1

graph bar (sum) n1 n2 n3 ///
	, ///
	stack ///
	over(kid_age, label(labsize(small)) axis(lcolor(none))) ///
	over(age, relabel(1 "Age of children") label(labsize(m)) axis(lcolor(none))) ///
	bargap(-30) ///
	xsize(10) legend(position(6) ring(1) cols(4) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(5)50) ///
	ytick(0(5)50) ///
	yscale(range(0(5)50)) ///
	ytitle("Share of children (%)") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)


/**************
Share of Children (Age $\ge$ 12) Living with Both or One Parent by Countries
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

cap drop pa_inHH
egen pa_inHH = group(mo_inHH fa_inHH), label
fre pa_inHH
la def pa_inHH 1 "No parents living in HH" 2 "Only father living in HH" 3 "Only mother living in HH" 4 "Both parents living in HH", replace 
la val pa_inHH pa_inHH
fre pa_inHH
drop if pa_inHH == .
keep if inrange(kid_age, 12, 17) // NOTE: We keep only children above 12 here!!!

tab pa_inHH, gen(pa_inHH_dm)

collapse (mean) n1=pa_inHH_dm1 n2=pa_inHH_dm2 n3=pa_inHH_dm3 n4=pa_inHH_dm4, by(countryfile)
foreach v of varlist n1-n4 {
	replace `v'=`v'*100
}

cap drop countryfile_num
cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "No parents living in HH" 2 "Only father living in HH" 3 "Only mother living in HH" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS5.T3.3"
local title "Share of Children (Age $\ge$ 12) Living with Both or One Parent by Countries"
local title ""

cap gen countryfile_num1 = countryfile_num - 0.2
cap gen countryfile_num2 = countryfile_num + 0.2

cap gen country = 1

graph bar (sum) n1 n2 n3 ///
	, ///
	stack ///
	over(countryfile_num, relabel(${lbl_xaxis}) label(labsize(small)) axis(lcolor(none))) ///
	over(country, relabel(1 "Country/region") label(labsize(m)) axis(lcolor(none))) ///
	bargap(-30) ///
	xsize(10) legend(position(6) ring(1) cols(4) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(5)50) ///
	ytick(0(5)50) ///
	yscale(range(0(5)50)) ///
	ytitle("Share of children (%)") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)










/**************
* Enrollment transition prob. by ages 
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

keep if inrange(kid_age, 5, 17)

keep if E_t_1 == 1
tab E_t, gen(E_t_dm)

collapse (mean) n1=E_t_dm1 n2=E_t_dm2, by(kid_age)
foreach v of varlist n1-n2 {
	replace `v'=`v'*100
}

// cap drop countryfile_num
// cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "Not enrolled this year" 2 "Enrolled this year" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T3.1"
local title "Enrollment Rate in This Year Conditional on \textbf{Enrolled} Last Year"
local title ""

cap gen age = 1

graph bar (sum) n1 n2 ///
	, ///
	stack ///
	over(kid_age, label(labsize(small)) axis(lcolor(none))) ///
	over(age, relabel(1 "Age of children") label(labsize(m)) axis(lcolor(none))) ///
	bargap(-30) ///
	xsize(10) legend(position(6) ring(1) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children (%)") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)



/**************
* Enrollment transition prob. by ages 
*************/

u "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", clear

keep if inrange(kid_age, 5, 17)

keep if E_t_1 == 0
tab E_t, gen(E_t_dm)

collapse (mean) n1=E_t_dm1 n2=E_t_dm2, by(kid_age)
foreach v of varlist n1-n2 {
	replace `v'=`v'*100
}

// cap drop countryfile_num
// cap egen countryfile_num = group(countryfile), label

global lbl_legend `" 0 "" 1 "Not enrolled this year" 2 "Enrolled this year" "'
global lbl_xaxis `" 1 "BGD2019" 2 "KGZ2018" 3 "MNG2018" 4 "NPL2019" 5 "PKK2019" 6 "PKP2017" 7 "PKS2018" 8 "T172019" 9 "THA2019" 10 "TKM2019" "'

local export "SS1.T3.2"
local title "Enrollment Rate in This Year Conditional on \textbf{Not} Enrolled Last Year"
local title ""

cap gen age = 1

graph bar (sum) n1 n2 ///
	, ///
	stack ///
	over(kid_age, label(labsize(small)) axis(lcolor(none))) ///
	over(age, relabel(1 "Age of children") label(labsize(m)) axis(lcolor(none))) ///
	bargap(-30) ///
	xsize(10) legend(position(6) ring(1) cols(3) symxsize(large) symysize(large) order(${lbl_legend})) ///
	ylabel(0(10)100) ///
	ytick(0(10)100) ///
	yscale(range(0(10)100)) ///
	ytitle("Share of children (%)") ///
	title("`title'", size(large)) 

gr export "$dir_path\\`export'.png", replace as(png)









********************************************************************************
* delete temparory data files 
********************************************************************************

// shell rd "$dir_tempdata\cherry" /s /q
// shell rm -r "$dir_tempdata\cherry" /s /q

* delete all files in folder "cherry"
cd "$dir_tempdata"
shell rd "apple" /s /q
cd "$dir_program"

* delete folder "cherry"
rmdir "$dir_tempdata\apple"








