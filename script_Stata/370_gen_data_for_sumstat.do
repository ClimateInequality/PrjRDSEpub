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

global today "20240307"

log using "$dir_log\370_gen_data_for_sumstat_$today.log", replace



efolder apple, cd("$dir_tempdata")
cd "$dir_program"

efolder data_to_est, cd("$dir_data")
cd "$dir_program"


********************************************************************************
* TASK: MICS data file, create EAPSO outcomes  
********************************************************************************

/*
https://github.com/ClimateInequality/PrjRDSE/issues/1


*/


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

* MODULE 1. Merge other variables with EAPRSO 

*******************************************************************************/

u "$dir_data\data_intermediate\\mics_child_EAPRS", clear 

merge 1:1 countryfile HH1 HH2 LN using "$dir_data\data_intermediate\mics_child_O" 
drop _merge

merge 1:1 countryfile HH1 HH2 LN using "$dir_data\data_intermediate\240_mics_child_pa_hh_WithRawVar" 
drop _merge

merge 1:1 countryfile HH1 HH2 LN using "$dir_data\data_intermediate\234_mics_pa_EA_using_elevel"
drop _merge 

clean_THA_PAK

sa "$dir_data\data_to_est\\mics_child_pa_hh_EAPRSO_WithRawVar", replace
export delimited using "$dir_data\data_to_est\\mics_child_pa_hh_EAPRSO_WithRawVar.csv", nolabel replace


* Keep variables we need 
drop *_raw*

sa "$dir_data\data_to_est\\mics_child_pa_hh_EAPRSO", replace
export delimited using "$dir_data\data_to_est\\mics_child_pa_hh_EAPRSO.csv", nolabel replace



/*******************************************************************************

* Generate files we want to have summary statistics ****************************

*******************************************************************************/


/*******************************************************************************

* MODULE . ss1 
https://github.com/ClimateInequality/PrjRDSE/issues/26

*******************************************************************************/

u "$dir_data\data_to_est\\mics_child_pa_hh_EAPRSO", clear 
sa "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO", replace
export delimited using "$dir_data\data_summarize\\ss1_mics_child_pa_hh_EAPRSO_$today.csv", nolabel replace


/*******************************************************************************

* MODULE . ss4
https://github.com/ClimateInequality/PrjRDSE/issues/29

*******************************************************************************/

u "$dir_data\data_to_est\\mics_child_pa_hh_EAPRSO", clear 
keep RDSE_loc_id-ISO_alpha_3 path E_* G_* A_* P_* R_* S_* O_* kid_age kid_female sch_close_nat sch_tea_abs

sa "$dir_data\data_summarize\\ss4_mics_child_sch_EAPRSO", replace

export delimited using "$dir_data\data_summarize\\ss4_mics_child_sch_EAPRSO_$today.csv", nolabel replace

fre E_*

de E_ever-R_t



/*******************************************************************************

* MODULE . ss5
https://github.com/ClimateInequality/PrjRDSE/issues/25

*******************************************************************************/

u "$dir_data\data_to_est\\mics_child_pa_hh_EAPRSO", clear 

*------ keep child attributes, parent and household attributes, and EAPSO var 
*------ have EAPRS variable, do not need the edu_* used to construct EAPRS
drop edu_* 
drop read_score_wordcorrect read_score_comp math_score_sym math_score_big math_score_add math_score_next

sa "$dir_data\data_summarize\\ss5_mics_child_sch_EAPRSO", replace
export delimited using "$dir_data\data_summarize\\ss5_mics_child_sch_EAPRSO_$today.csv", nolabel replace



/*******************************************************************************

* MODULE . ss6
https://github.com/ClimateInequality/PrjRDSE/issues/24

*******************************************************************************/

u "$dir_data\data_to_est\\mics_child_pa_hh_EAPRSO", clear 

*------ No need to check EAPRS again, but to keep description info of sample 
drop path path E_* G_* A_* P_* R_* S_* O_* 
drop sch_close_nat sch_tea_abs
drop edu_*
drop read_score_wordcorrect read_score_comp math_score_sym math_score_big math_score_add math_score_next
drop read_score_total math_score_total
drop mo_edu_* fa_edu_*

sa "$dir_data\data_summarize\\ss6_mics_child_sch_EAPRSO", replace
export delimited using "$dir_data\data_summarize\\ss6_mics_child_sch_EAPRSO_$today.csv", nolabel replace


/*******************************************************************************

* MODULE 4. Append disaster var. 

*******************************************************************************/

*** Add age_in_month variable for each child 

import delimited using "$dir_data\\data_intermediate\\child_age_in_month_full_yz.csv", case(preserve) clear
sa "$dir_data\\data_intermediate\\child_age_in_month_full_yz", replace

*** Add DB DS variables 

import delimited using "$dir_data\\data_to_est\\child_lifecycle_loc_date_dis_his_DB_DS.csv", case(preserve) clear
sa "$dir_data\\data_to_est\\child_lifecycle_loc_date_dis_his_DB_DS", replace

*** Add DM variables 

import delimited using "$dir_data\\data_to_est\\child_lifecycle_loc_date_D_full_yz_DM.csv", case(preserve) clear
sa "$dir_data\\data_to_est\\child_lifecycle_loc_date_D_full_yz_DM", replace

import delimited using "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DM.csv", case(preserve) clear
sa "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DM", replace

*** Add DB DS more variables 

import delimited using "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add.csv", case(preserve) clear
sa "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add", replace

*** Add variables DB DS for time span m1to3 m1to12 

import delimited using "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add_m1to3.csv", case(preserve) clear
sa "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add_m1to3", replace

import delimited using "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add_m1to12.csv", case(preserve) clear
sa "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add_m1to12", replace

*** Add variables DM for time span m1to3 m1to12 

import delimited using "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DM_Add_m1to3_12.csv", case(preserve) clear
sa "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DM_Add_m1to3_12", replace

// import delimited using "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DM_Add_m1to12.csv", case(preserve) clear
// sa "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DM_Add_m1to12", replace



/// MERGE ///

u "$dir_data\data_to_est\\mics_child_pa_hh_EAPRSO", clear 
merge 1:1 countryfile HH1 HH2 LN using "$dir_data\\data_intermediate\\child_age_in_month_full_yz"
drop _merge 

merge 1:1 countryfile HH1 HH2 LN using "$dir_data\data_to_est\\child_lifecycle_loc_date_dis_his_DB_DS"
drop _merge 

merge 1:1 countryfile HH1 HH2 LN using "$dir_data\data_to_est\\child_lifecycle_loc_date_D_full_yz_DM"
drop _merge 
merge 1:1 countryfile HH1 HH2 LN using "$dir_data\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DM"
drop _merge 

merge 1:1 countryfile HH1 HH2 LN using "$dir_data\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add"
drop _merge 

merge 1:1 countryfile HH1 HH2 LN using "$dir_data\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add_m1to3"
drop _merge 
merge 1:1 countryfile HH1 HH2 LN using "$dir_data\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add_m1to12"
drop _merge 

merge 1:1 countryfile HH1 HH2 LN using "$dir_data\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DM_Add_m1to3_12"
drop _merge 

rename age_month_mics6_to_history kid_age_in_month
order kid_age_in_month, after(kid_age)
la var kid_age_in_month "Age in Mo."

order RDSE_loc_id countryfile HH1 HH2 LN moLN faLN ISO_alpha_3, first
order dis_A* ///
 dis_B* ///
 dis_C* ///
 dis_D* ///
 , last



qui ds, v(30) 
foreach j in "dis_A_DB" "dis_A_DS" "dis_A_DM" "dis_B_DB" "dis_B_DS" "dis_B_DM" "dis_C_DB" "dis_C_DS" "dis_C_DM" "dis_D_DB" "dis_D_DS" "dis_D_DM" {
	local count = 0
	foreach var of varlist `r(varlist)' {
	  if substr("`var'", 1, 8) == "`j'" {
		local count = `count' + 1
	  }
	}
	di "`count' variables start with `j'"
}



sa "$dir_data\data_to_est\\est_mics_child", replace

	
/*******************************************************************************

* MODULE 5. Label

*******************************************************************************/

u "$dir_data\data_to_est\\est_mics_child", clear

cap program drop pr_label_dis_intensity
program define pr_label_dis_intensity

	la var ISO_alpha_3 "ISO"

	/*
	la var dis_A_bi_in_past_12m "Experienced any disaster in past 12m"
	la var dis_A_fl_in_past_12m "Share of months experiencing any disaster in past 12m"
	la var dis_A_bi_in_12m_ago_to_10y "Experienced any disaster in 10y prior to 12m"
	la var dis_A_fl_in_12m_ago_to_10y "Share of months experiencing any disaster in 10y prior to 12m"
	la var dis_A_bi_age_bf_33m "Experienced any disaster in first 33m of life"
	la var dis_A_cts_age_bf_33m "Share of months experiencing any disaster in first 33m of life"
	la var dis_A_bi_age_bf_0 "Experienced any disaster in prenatal period"
	la var dis_A_cts_age_bf_0 "Share of months experiencing any disaster in prenatal period"
	*/

	* Clear label for disaster intensity 
	foreach i of varlist dis_* {
		la var `i' ""
	}

	// des dis_*, fullname

	// Error if you use 
	//----- labvarch *_DB_*, pref("\$DB") 
	//----- labvarch *_DB_*, pref("$DB") 
	// This is the same as below 
	//----- labvarch *_DB_*, pref("\$" "DB") 
	//----- labvarch *_DB_*, pref("$" "DB") 
	//----- labvarch *_DB_*, pref("$ DB") 
	labvarch *_DB_*, pref("\$ DB") 
	labvarch *_DS_*, pref("\$ DS") 
	labvarch *_DM_*, pref("\$ DM") 
	
	labvarch dis_A_*, suff("_{A}\$ ") 
	labvarch dis_B_*, suff("_{B}\$ ")
	labvarch dis_C_*, suff("_{C}\$ ")
	labvarch dis_D_*, suff("_{D}\$ ")
	 
	labvarch *_m1to1, suff("in survey mo")
	labvarch *_m2to2, suff("in last mo")
	labvarch *_m1to2, suff("in most recent 2 mo")
	labvarch *_m2to12, suff("in this yr prior survey mo")
	labvarch *_m2to24, suff("in recent 2 yr prior survey mo")
	labvarch *_m13to24, suff("in yr prior 12 mo ago")
	labvarch *_m2to120, suff("in 10 yr prior survey mo")
	labvarch *_m121to240, suff("in 20 yr prior 10 yr ago")
	labvarch *_m2to240, suff("in 20 yr prior survey mo")
	labvarch *_m13to120, suff("in 10 yr ago until this yr")
	labvarch *_m25to120, suff("in 10 yr ago until 2 yr Ago")
	labvarch *_m13to240, suff("in 20 yr ago until this yr")
	labvarch *_m25to240, suff("in 20 yr ago until 2 yr ago")
	labvarch *_g9to24, suff("in first 1000 days of life")
	labvarch *_g9to0, suff("in prenatal period")
	labvarch *_g60to72, suff("in age 5 to 6")
	labvarch *_g36to156, suff("in childhood (3-13)")
	labvarch *_g157to204, suff("in adolescent (14-17)")
	labvarch *_g25_to_m25, suff("after 1000 days until 2 yr before survey mo")
	labvarch *_g1_to_m25, suff("from birth until 2 yr before survey mo")

	labvarch *_m1to3, suff("in most recent 3 mo")
// 	labvarch *_m1to4, suff("in most recent 4 mo")
// 	labvarch *_m1to5, suff("in most recent 5 mo")
// 	labvarch *_m1to6, suff("in most recent 6 mo")
	labvarch *_m1to12, suff("in most recent 12 mo")

end 

pr_label_dis_intensity





sa "$dir_data\data_to_est\\est_mics_child", replace




	
/*******************************************************************************

* MODULE 6. School Closure Measures 

*******************************************************************************/


u "$dir_data\\data_to_est\\est_mics_child", clear

/* Variable capturing interview year and month */

cap drop kid_int_m_str kid_int_y_str kid_int_y_m_str
tostring kid_int_m, gen(kid_int_m_str)
tostring kid_int_y, gen(kid_int_y_str)
gen kid_int_y_m_str = ""
replace kid_int_y_m_str = kid_int_y_str + "0" + kid_int_m_str if inrange(kid_int_m, 1, 9)
replace kid_int_y_m_str = kid_int_y_str + kid_int_m_str if inrange(kid_int_m, 10, 12)



/* Combine school closure due to natural disaster variable with teacher truancy experiecing variable */

tab sch_close_nat sch_tea_abs

cap drop sch_minhaj
gen sch_minhaj = (sch_close_nat == 1 | sch_tea_abs == 1)
replace sch_minhaj = . if kid_age <= 6 | kid_age >= 15
replace sch_minhaj = . if E_t == 0 | E_t == . 
la var sch_minhaj "School Closed or Teacher Absent"


cap drop child_live_with_pa
gen child_live_with_pa = (mo_inHH == 1 & fa_inHH == 1)
la var child_live_with_pa "Child live with both parents"

sa "$dir_data\\data_to_est\\est_mics_child", replace








/*******************************************************************************

* MODULE 

*******************************************************************************/

cap program drop pr_clean_dis_time_span 
program define pr_clean_dis_time_span

	import delimited using "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add_m1to3_12.csv", case(preserve) clear

	drop *_m1to4 *_m1to5 *_m1to6

	export delimited using "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add_m1to3", nolabel replace 

	sa "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add_m1to3", replace




	import delimited using "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add_m1to3_12.csv", case(preserve) clear

	drop *_m1to3

	export delimited using "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add_m1to4_5_6", nolabel replace 

	sa "$dir_data\\data_to_est\\child_lifecycle_loc_date_alltype_full_yz_DB_DS_Add_m1to4_5_6", replace 

end 


/*******************************************************************************

* Save data as .dta format

*******************************************************************************/

// import delimited using "$dir_data\\data_to_est\\est_mics_child_moloc.csv", case(preserve) clear
// sa "$dir_data\\data_to_est\\est_mics_child_moloc", replace

u "$dir_data\\data_to_est\\est_mics_child", clear
merge 1:1 RDSE_loc_id countryfile HH1 HH2 LN moLN faLN ISO_alpha_3 using "$dir_data\data_intermediate\mics_mother_location_track"
drop _merge

gen modur_longer_than_kidage = (mo_duration_yr >= kid_age + 1)
replace modur_longer_than_kidage = . if kid_age == .
replace modur_longer_than_kidage = . if mo_duration_yr == .

sa "$dir_data\\data_to_est\\est_mics_child_moloc", replace



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








