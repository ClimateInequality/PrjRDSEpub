/* Project: PIRE 

Author: Yujie Zhang 
Date: 20240530

This is based on 806_reg_enroll_cluster_typeBCD AND 808_reg_enroll_cluster_moloc
Format each table .tex file so that we do not need to manualy add lines and spaces in Latex. 
Type BCD disaster measure, for enrollment outcome regression. 
Limit sample to those whose mothers have not moved. 

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

global today = "20240530"

///--- Install log2html
// ssc install log2html

efolder cherry, cd("$dir_tempdata")
cd "$dir_program"

/************************************* The Main Code Starts Here *************************************/

***** Load Data

set more off
set trace off

u "$dir_data\\data_to_est\\est_mics_child", clear


global st_computer "yz"
global st_model "806_reg_enroll_cluster_typeBCD"
global st_country_file "All"

*----- Set folder name by country in the temporary result folder with code running computer 
efolder $st_computer, cd("$dir_result_temp")
efolder $st_model, cd("$dir_result_temp\\${st_computer}")
efolder $st_country_file, cd("$dir_result_temp\\${st_computer}\\${st_model}")
cd "$dir_program"
global st_file_root "$dir_result_temp\\${st_computer}\\${st_model}\\${st_country_file}"


*----- Set file name by disaster intensity type and shock measure 
global st_log_file "${st_file_root}\\reg_enroll"
global st_tab_html "${st_log_file}_tab.html"
global st_tab_rtf  "${st_log_file}_tab.rtf"
global st_tab_tex  "${st_log_file}_tab_texbody.tex"

*--- Start log
cap log close
log using "${st_log_file}" , replace
log on

set trace off
set tracedepth 1



***** Generate variables and global 

do 701_fan_sandbox_gen.do


global core_rhs "c.E_t_1#i.kid_age_m3 c.A_t#i.kid_age_m3 c.E_t_1#i.countryfile_num c.A_t#i.countryfile_num kid_female mo_alive fa_alive mo_inHH fa_inHH mo_elevel_E_ever mo_elevel_A_secondary"
global core_cdn "if inrange(kid_age, 5, 17)"

// global core_opt "vce(robust) absorb(RDSE_loc_id kid_int_y kid_int_m kid_age)"
global core_opt "vce(cluster RDSE_loc_id)  absorb(RDSE_loc_id kid_int_y kid_int_m kid_age)"

// global core_opt_1 "vce(robust) absorb(countryfile_num#HH1 kid_int_y kid_int_m kid_age)"
global core_opt_1 "vce(cluster RDSE_loc_id)  absorb(countryfile_num#HH1 kid_int_y kid_int_m kid_age)"

	
global dis_shock_1 "dis_B"
global dis_shock_2 "dis_C"
global dis_shock_3 "dis_D"
// Each column is for one type. 
// In general there should be 3 columns with type B, C, and D intensity. 
// Estimation in every column follows the first column of the tables by type A intensity, including within country location FE, instead of cluster FE. 

global TypeB "Flood"
global TypeC "Severe disaster"
global TypeD "Severe flood"


cap program drop pr_label
program define pr_label

	la var E_t_1 "Enrollment in year $ t-1 $"
	la var A_t "Attainment at start of $ t $"
	la var kid_female "Female"
	la var mo_alive "Mother is alive"
	la var fa_alive "Father is alive"
	la var mo_inHH "Mother is alive $\times$ living in same HH"
	la var fa_inHH "Father is alive $\times$ living in same HH"
	la var mo_elevel_E_ever "Mother ever educated" 
	la var mo_elevel_A_secondary "Mother ever educated $\times$ has secondary education"

end

pr_label



/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Table. enroll_1. effects of disaster on enrollment, type B C D 
------------------------------------------------------------------------------*/

foreach itype in "1" "2" "3" {

	rename ${dis_shock_`itype'}_D* dis_shock_D*
	
	global col_`itype' " reghdfe E_t dis_shock_DB_m1to12 dis_shock_DM_g9to24 E_t_1 A_t ${core_rhs} ${core_cdn}, ${core_opt} "

	${col_`itype'}
	cap estadd local control_E_t_1_X_age_m3 "Y"
	cap estadd local control_A_t_X_age_m3 "Y"
	cap estadd local control_E_t_1_X_countryfile "Y"
	cap estadd local control_A_t_X_countryfile "Y"
	
	cap estadd local FE_withincountry "Y"
	cap estadd local FE_int_y "Y"
	cap estadd local FE_int_m "Y"
	cap estadd local FE_age "Y"		
	
	est store reg_`itype'
	esttab reg_`itype'
	
	rename dis_shock_D* ${dis_shock_`itype'}_D* 

}
	
global est_tab_col " reg_1 reg_2 reg_3 "
global st_tab_tex  "${st_log_file}_1.tex"
global st_tab_html  "${st_log_file}_1.html"


/* Create fake variable so that variable label can be captured and show in table. */
cap drop dis_shock_DB_m1to12  dis_shock_DM_g9to24
gen dis_shock_DB_m1to12 = . 
la var dis_shock_DB_m1to12 "Had disaster in recent 12 mo."
gen dis_shock_DM_g9to24 = . 
la var dis_shock_DM_g9to24 "\# of mo. with disaster in the first 1000 days"



/* Output to html -----------------
-------------------------*/

	esttab $est_tab_col using "${st_tab_html}", replace /// 
		keep( dis_shock_DB_m1to12 dis_shock_DM_g9to24 E_t_1 A_t kid_female mo_alive fa_alive mo_inHH fa_inHH mo_elevel_E_ever mo_elevel_A_secondary ) ///
		order( dis_shock_DB_m1to12 dis_shock_DM_g9to24 E_t_1 A_t kid_female mo_alive fa_alive mo_inHH fa_inHH mo_elevel_E_ever mo_elevel_A_secondary ) ///
		cells(b(star fmt(3)) se(par fmt (3))) ///
		label varwidth(50) nomtitle collabels(none) compress alignment(D{.}{.}{-1}) ///
		star(* 0.10 ** 0.05 *** 0.01) ///
		substitute(\_ _) ///
		scalars( "N Obs." "FE_withincountry Within Country Location FE" "FE_int_y Interview Year FE" "FE_int_m Interview Month FE" "FE_age Child Age FE" "control_E_t_1_X_age_m3 Enrollment t-1 X Age Group Controls" "control_A_t_X_age_m3 Attainment t X Age Group Controls" "control_E_t_1_X_countryfile Enrollment t-1 X Country Controls" "control_A_t_X_countryfile Attainment t X Country Controls" ) ///
		nonotes 
		
		
/* Output to tex -----------------
-------------------------*/

	global it_reg_n = 3 

	scalar it_esttad_n = 8
	matrix mt_bl_estd = J(it_esttad_n, $it_reg_n, 0)
	matrix rownames mt_bl_estd = FE_withincountry FE_int_y FE_int_m FE_age control_E_t_1_X_age_m3 control_A_t_X_age_m3 control_E_t_1_X_countryfile control_A_t_X_countryfile
	
	global st_estd_rownames : rownames mt_bl_estd
		
	global slb_estd_1 "Within country location FE"
	global slb_estd_2 "Interview year FE"
	global slb_estd_3 "Interview month FE"
	global slb_estd_4 "Child age FE"
	global slb_estd_5 "Enrollment $ t-1 $ $\times$ age group FE"
	global slb_estd_6 "Attainment $ t $ $\times$ age group FE"
	global slb_estd_7 "Enrollment $ t-1 $ $\times$ country FE"
	global slb_estd_8 "Attainment $ t $ $\times$ country FE"

#delimit;

	global slb_fot_lst_spc "\vspace*{0mm}\hspace*{2mm}";
	
	global slb_titling_bottom `"
	stats(N $st_estd_rownames,
			fmt(%9.0g)
			labels("\midrule Observations"
			"\midrule ${slb_fot_lst_spc}${slb_estd_1}"
			"${slb_fot_lst_spc}${slb_estd_2}"
			"${slb_fot_lst_spc}${slb_estd_3}"
			"${slb_fot_lst_spc}${slb_estd_4}"
			"${slb_fot_lst_spc}${slb_estd_5}"
			"${slb_fot_lst_spc}${slb_estd_6}"
			"${slb_fot_lst_spc}${slb_estd_7}"
			"${slb_fot_lst_spc}${slb_estd_8}"
			))"';

	global notewrap1 "
		\cmidrule(l{20pt}r{4pt}){2-4} 
		%
	";
	
			
	esttab $est_tab_col using "${st_tab_tex}", replace 
		keep( dis_shock_DB_m1to12 dis_shock_DM_g9to24 E_t_1 A_t kid_female mo_alive fa_alive mo_inHH fa_inHH mo_elevel_E_ever mo_elevel_A_secondary ) 
		order( dis_shock_DB_m1to12 dis_shock_DM_g9to24 E_t_1 A_t kid_female mo_alive fa_alive mo_inHH fa_inHH mo_elevel_E_ever mo_elevel_A_secondary ) 
		cells(b(star fmt(3)) se(par fmt (3))) 
		label varwidth(50) nomtitle collabels(none) compress alignment(D{.}{.}{-1}) 
		star(* 0.10 ** 0.05 *** 0.01) 
		substitute(\_ _) 
		${slb_titling_bottom}
		nonotes 
		plain 
		refcat(E_t_1 "${notewrap1}", nolabel) 
		prehead("{"
		"\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
		"\begin{tabular}{l*{3}{D{.}{.}{-1}}}"
		"\toprule"
		"&\multicolumn{1}{c}{(1)}         &\multicolumn{1}{c}{(2)}         &\multicolumn{1}{c}{(3)}         \\"
		"&\multicolumn{1}{c}{${TypeB}}         &\multicolumn{1}{c}{${TypeC}}         &\multicolumn{1}{c}{${TypeD}}         \\"
		"\midrule"
		)
		postfoot("\bottomrule" 
		"\end{tabular}" 
		"}"
		)
	;

#delimit cr 


/* Drop the fake variable. */
drop dis_shock_DB_m1to12 dis_shock_DM_g9to24




/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Table enroll_3. Heterogeneity across ages 
------------------------------------------------------------------------------*/


foreach itype in "1" "2" "3" {

	rename ${dis_shock_`itype'}_D* dis_shock_D*

	global col_`itype' " reghdfe E_t c.dis_shock_DB_m1to12#i.kid_age_m3 c.dis_shock_DM_g9to24#i.kid_age_m3 E_t_1 A_t ${core_rhs} ${core_cdn}, ${core_opt} "

	${col_`itype'}
	cap estadd local control_E_t_1_X_age_m3 "Y"
	cap estadd local control_A_t_X_age_m3 "Y"
	cap estadd local control_E_t_1_X_countryfile "Y"
	cap estadd local control_A_t_X_countryfile "Y"
	
	cap estadd local FE_withincountry "Y"
	cap estadd local FE_int_y "Y"
	cap estadd local FE_int_m "Y"
	cap estadd local FE_age "Y"
	
	return list 
	mat li r(table)
	est store reg_`itype'
	esttab reg_`itype'
	
	rename dis_shock_D* ${dis_shock_`itype'}_D*
	
}
	
global est_tab_col " reg_1 reg_2 reg_3 "
global st_tab_tex  "${st_log_file}_3.tex"
global st_tab_html  "${st_log_file}_3.html"


/* Create fake variable so that variable label can be captured and show in table. */
cap drop dis_shock_DB_m1to12  dis_shock_DM_g9to24
gen dis_shock_DB_m1to12 = . 
la var dis_shock_DB_m1to12 "Had disaster in recent 12 mo."
gen dis_shock_DM_g9to24 = . 
la var dis_shock_DM_g9to24 "\# of mo. with disaster in the first 1000 days"


/* Output to html -----------------
-------------------------*/

	esttab $est_tab_col using "${st_tab_html}", replace /// 
	  keep( 0.kid_age_m3#c.dis_shock_DB_m1to12  1.kid_age_m3#c.dis_shock_DB_m1to12 2.kid_age_m3#c.dis_shock_DB_m1to12 ///
	0.kid_age_m3#c.dis_shock_DM_g9to24  1.kid_age_m3#c.dis_shock_DM_g9to24 2.kid_age_m3#c.dis_shock_DM_g9to24 ///
	E_t_1 A_t kid_female mo_alive fa_alive mo_inHH fa_inHH mo_elevel_E_ever mo_elevel_A_secondary ) ///
	  order( 0.kid_age_m3#c.dis_shock_DB_m1to12  1.kid_age_m3#c.dis_shock_DB_m1to12 2.kid_age_m3#c.dis_shock_DB_m1to12 ///
	0.kid_age_m3#c.dis_shock_DM_g9to24  1.kid_age_m3#c.dis_shock_DM_g9to24 2.kid_age_m3#c.dis_shock_DM_g9to24 ///
	E_t_1 A_t kid_female mo_alive fa_alive mo_inHH fa_inHH mo_elevel_E_ever mo_elevel_A_secondary ) ///
	  cells(b(star fmt(3)) se(par fmt (3))) ///
	  label varwidth(50) nomtitle collabels(none) compress alignment(D{.}{.}{-1}) ///
	  star(* 0.10 ** 0.05 *** 0.01) ///
	  substitute(\_ _) ///
	  scalars( "N Obs." "FE_withincountry Within Country Location FE" "FE_country_X_cluster Country X Cluster FE" "FE_int_y Interview Year FE" "FE_int_m Interview Month FE" "FE_age Child Age FE" "control_E_t_1_X_age_m3 Enrollment t-1 X Age Group Controls" "control_A_t_X_age_m3 Attainment t X Age Group Controls" "control_E_t_1_X_countryfile Enrollment t-1 X Country Controls" "control_A_t_X_countryfile Attainment t X Country Controls" ) ///
	  nonotes 
	  

/* Output to tex -----------------
-------------------------*/

	global it_reg_n = 3 

	scalar it_esttad_n = 8
	matrix mt_bl_estd = J(it_esttad_n, $it_reg_n, 0)
	matrix rownames mt_bl_estd = FE_withincountry FE_int_y FE_int_m FE_age control_E_t_1_X_age_m3 control_A_t_X_age_m3 control_E_t_1_X_countryfile control_A_t_X_countryfile
	
	global st_estd_rownames : rownames mt_bl_estd
		
	global slb_estd_1 "Within country location FE"
	global slb_estd_2 "Interview year FE"
	global slb_estd_3 "Interview month FE"
	global slb_estd_4 "Child age FE"
	global slb_estd_5 "Enrollment $ t-1 $ $\times$ age group FE"
	global slb_estd_6 "Attainment $ t $ $\times$ age group FE"
	global slb_estd_7 "Enrollment $ t-1 $ $\times$ country FE"
	global slb_estd_8 "Attainment $ t $ $\times$ country FE"

#delimit;

	global slb_fot_lst_spc "\vspace*{0mm}\hspace*{2mm}";
	
	global slb_titling_bottom `"
	stats(N $st_estd_rownames,
			fmt(%9.0g)
			labels("\midrule Observations"
			"\midrule ${slb_fot_lst_spc}${slb_estd_1}"
			"${slb_fot_lst_spc}${slb_estd_2}"
			"${slb_fot_lst_spc}${slb_estd_3}"
			"${slb_fot_lst_spc}${slb_estd_4}"
			"${slb_fot_lst_spc}${slb_estd_5}"
			"${slb_fot_lst_spc}${slb_estd_6}"
			"${slb_fot_lst_spc}${slb_estd_7}"
			"${slb_fot_lst_spc}${slb_estd_8}"
			))"';
	
	global notewrap1 "
		\addlinespace[0.2em]
		\multicolumn{4}{l}{\textbf{Had disaster in recent 12 mo.}} \\
		\addlinespace[0.2em] 
		%
	";
	
	global notewrap2 "
		\addlinespace[0.2em]
		\multicolumn{4}{l}{\textbf{\# of mo. with disaster in the first 1000 days}} \\
		\addlinespace[0.2em]
		%
	";
	
	global slb_dis_ele_spc "\hspace*{5mm}";
	
	global slb_coef_label_panel "
		0.kid_age_m3#c.dis_shock_DB_m1to12 "${slb_dis_ele_spc} $\times$ Age 5--8"
		1.kid_age_m3#c.dis_shock_DB_m1to12 "${slb_dis_ele_spc} $\times$ Age 9--12"
		2.kid_age_m3#c.dis_shock_DB_m1to12 "${slb_dis_ele_spc} $\times$ Age 13--17"
		
		0.kid_age_m3#c.dis_shock_DM_g9to24 "${slb_dis_ele_spc} $\times$ Age 5--8"
		1.kid_age_m3#c.dis_shock_DM_g9to24 "${slb_dis_ele_spc} $\times$ Age 9--12"
		2.kid_age_m3#c.dis_shock_DM_g9to24 "${slb_dis_ele_spc} $\times$ Age 13--17"
	";
	
	global slb_panel_main "
		coeflabels($slb_coef_label_panel)
		";
		
		
			
	esttab $est_tab_col using "${st_tab_tex}", replace 
		keep( 0.kid_age_m3#c.dis_shock_DB_m1to12  1.kid_age_m3#c.dis_shock_DB_m1to12 2.kid_age_m3#c.dis_shock_DB_m1to12 
	0.kid_age_m3#c.dis_shock_DM_g9to24  1.kid_age_m3#c.dis_shock_DM_g9to24 2.kid_age_m3#c.dis_shock_DM_g9to24  ) 
		order( 0.kid_age_m3#c.dis_shock_DB_m1to12  1.kid_age_m3#c.dis_shock_DB_m1to12 2.kid_age_m3#c.dis_shock_DB_m1to12 
	0.kid_age_m3#c.dis_shock_DM_g9to24  1.kid_age_m3#c.dis_shock_DM_g9to24 2.kid_age_m3#c.dis_shock_DM_g9to24  ) 
		cells(b(star fmt(3)) se(par fmt (3))) 
		label varwidth(50) nomtitle collabels(none) compress alignment(D{.}{.}{-1}) 
		star(* 0.10 ** 0.05 *** 0.01) 
		substitute(\_ _) 
		${slb_panel_main}
		${slb_titling_bottom}
		nonotes 
		plain 
		refcat(0.kid_age_m3#c.dis_shock_DB_m1to12 "${notewrap1}" 0.kid_age_m3#c.dis_shock_DM_g9to24 "${notewrap2}", nolabel) 
		prehead("{"
		"\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
		"\begin{tabular}{l*{3}{D{.}{.}{-1}}}"
		"\toprule"
		"&\multicolumn{1}{c}{(1)}         &\multicolumn{1}{c}{(2)}         &\multicolumn{1}{c}{(3)}         \\"
		"&\multicolumn{1}{c}{${TypeB}}         &\multicolumn{1}{c}{${TypeC}}         &\multicolumn{1}{c}{${TypeD}}         \\"
		"\midrule"
		)
		postfoot("\bottomrule" 
		"\end{tabular}" 
		"}"
		)
	;

#delimit cr 
	   

/* Drop the fake variable. */
drop dis_shock_DB_m1to12 dis_shock_DM_g9to24




/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Table enroll_7. heterogeneity across age and gender 
------------------------------------------------------------------------------*/

foreach itype in "1" "2" "3" {

	rename ${dis_shock_`itype'}_D* dis_shock_D*

	global col_`itype' " reghdfe E_t c.dis_shock_DB_m1to12#i.kid_female#i.kid_age_m3 c.dis_shock_DM_g9to24#i.kid_female#i.kid_age_m3  ${core_rhs} ${core_cdn}, ${core_opt} "

	${col_`itype'}
	cap estadd local control_E_t_1_X_age_m3 "Y"
	cap estadd local control_A_t_X_age_m3 "Y"
	cap estadd local control_E_t_1_X_countryfile "Y"
	cap estadd local control_A_t_X_countryfile "Y"
	
	cap estadd local FE_withincountry "Y"
	cap estadd local FE_int_y "Y"
	cap estadd local FE_int_m "Y"
	cap estadd local FE_age "Y"
	
	return list 
	mat li r(table)
	est store reg_`itype'
	esttab reg_`itype'
	
	rename dis_shock_D* ${dis_shock_`itype'}_D*
	
}
  
global est_tab_col " reg_1 reg_2 reg_3 "
global st_tab_tex  "${st_log_file}_7.tex"
global st_tab_html  "${st_log_file}_7.html"


/* Create fake variable so that variable label can be captured and show in table. */
cap drop dis_shock_DB_m1to12  dis_shock_DM_g9to24
gen dis_shock_DB_m1to12 = . 
la var dis_shock_DB_m1to12 "Had disaster in recent 12 mo."
gen dis_shock_DM_g9to24 = . 
la var dis_shock_DM_g9to24 "\# of mo. with disaster in the first 1000 days"


/* Output to html -----------------
-------------------------*/

	esttab $est_tab_col using "${st_tab_html}", replace /// 
	  keep( 0.kid_female#0.kid_age_m3#c.dis_shock_DB_m1to12 0.kid_female#1.kid_age_m3#c.dis_shock_DB_m1to12 0.kid_female#2.kid_age_m3#c.dis_shock_DB_m1to12 ///
	  1.kid_female#0.kid_age_m3#c.dis_shock_DB_m1to12 1.kid_female#1.kid_age_m3#c.dis_shock_DB_m1to12 1.kid_female#2.kid_age_m3#c.dis_shock_DB_m1to12 ///
	  0.kid_female#0.kid_age_m3#c.dis_shock_DM_g9to24 0.kid_female#1.kid_age_m3#c.dis_shock_DM_g9to24 0.kid_female#2.kid_age_m3#c.dis_shock_DM_g9to24 ///
	  1.kid_female#0.kid_age_m3#c.dis_shock_DM_g9to24 1.kid_female#1.kid_age_m3#c.dis_shock_DM_g9to24 1.kid_female#2.kid_age_m3#c.dis_shock_DM_g9to24 ) ///
	  order( 0.kid_female#0.kid_age_m3#c.dis_shock_DB_m1to12 0.kid_female#1.kid_age_m3#c.dis_shock_DB_m1to12 0.kid_female#2.kid_age_m3#c.dis_shock_DB_m1to12 ///
	  1.kid_female#0.kid_age_m3#c.dis_shock_DB_m1to12 1.kid_female#1.kid_age_m3#c.dis_shock_DB_m1to12 1.kid_female#2.kid_age_m3#c.dis_shock_DB_m1to12 ///
	  0.kid_female#0.kid_age_m3#c.dis_shock_DM_g9to24 0.kid_female#1.kid_age_m3#c.dis_shock_DM_g9to24 0.kid_female#2.kid_age_m3#c.dis_shock_DM_g9to24 ///
	  1.kid_female#0.kid_age_m3#c.dis_shock_DM_g9to24 1.kid_female#1.kid_age_m3#c.dis_shock_DM_g9to24 1.kid_female#2.kid_age_m3#c.dis_shock_DM_g9to24 ) ///
	  cells(b(star fmt(3)) se(par fmt (3))) ///
	  label varwidth(50) nomtitle collabels(none) compress alignment(D{.}{.}{-1}) ///
	  star(* 0.10 ** 0.05 *** 0.01) ///
	  substitute(\_ _) ///
	  scalars( "N Obs." "FE_withincountry Within Country Location FE" "FE_country_X_cluster Country X Cluster FE" "FE_int_y Interview Year FE" "FE_int_m Interview Month FE" "FE_age Child Age FE" "control_E_t_1_X_age_m3 Enrollment t-1 X Age Group Controls" "control_A_t_X_age_m3 Attainment t X Age Group Controls" "control_E_t_1_X_countryfile Enrollment t-1 X Country Controls" "control_A_t_X_countryfile Attainment t X Country Controls" ) ///
	  nonotes 
	  

/* Output to tex -----------------
-------------------------*/

	global it_reg_n = 3 

	scalar it_esttad_n = 8
	matrix mt_bl_estd = J(it_esttad_n, $it_reg_n, 0)
	matrix rownames mt_bl_estd = FE_withincountry FE_int_y FE_int_m FE_age control_E_t_1_X_age_m3 control_A_t_X_age_m3 control_E_t_1_X_countryfile control_A_t_X_countryfile
	
	global st_estd_rownames : rownames mt_bl_estd
		
	global slb_estd_1 "Within country location FE"
	global slb_estd_2 "Interview year FE"
	global slb_estd_3 "Interview month FE"
	global slb_estd_4 "Child age FE"
	global slb_estd_5 "Enrollment $ t-1 $ $\times$ age group FE"
	global slb_estd_6 "Attainment $ t $ $\times$ age group FE"
	global slb_estd_7 "Enrollment $ t-1 $ $\times$ country FE"
	global slb_estd_8 "Attainment $ t $ $\times$ country FE"

#delimit;

	global slb_fot_lst_spc "\vspace*{0mm}\hspace*{2mm}";
	
	global slb_titling_bottom `"
	stats(N $st_estd_rownames,
			fmt(%9.0g)
			labels("\midrule Observations"
			"\midrule ${slb_fot_lst_spc}${slb_estd_1}"
			"${slb_fot_lst_spc}${slb_estd_2}"
			"${slb_fot_lst_spc}${slb_estd_3}"
			"${slb_fot_lst_spc}${slb_estd_4}"
			"${slb_fot_lst_spc}${slb_estd_5}"
			"${slb_fot_lst_spc}${slb_estd_6}"
			"${slb_fot_lst_spc}${slb_estd_7}"
			"${slb_fot_lst_spc}${slb_estd_8}"
			))"';
	
	global notewrap1 "
		\addlinespace[0.2em]
		\multicolumn{4}{l}{\textbf{Had disaster in recent 12 mo.}} \\
		\addlinespace[0.2em] 
		%
	";
	
	global notewrap2 "
		\addlinespace[0.2em]
		\multicolumn{4}{l}{\textbf{\# of mo. with disaster in the first 1000 days}} \\
		\addlinespace[0.2em]
		%
	";
	
	global notewrap_p1 "
		\multicolumn{2}{l}{\hspace*{5mm} $\times$ Male}\\
		\addlinespace[0.3em]
	";
	
	global notewrap_p2 "
		\multicolumn{2}{l}{\hspace*{5mm} $\times$ Female}\\
		\addlinespace[0.3em]
	";
	
	global slb_dis_ele_spc "\hspace*{10mm}"
	;

	global slb_coef_label_panel "
		0.kid_female#0.kid_age_m3#c.dis_shock_DB_m1to12 "${notewrap_p1} ${slb_dis_ele_spc} $\times$ Age 5--8"
		0.kid_female#1.kid_age_m3#c.dis_shock_DB_m1to12 "${slb_dis_ele_spc} $\times$ Age 9--12"
		0.kid_female#2.kid_age_m3#c.dis_shock_DB_m1to12 "${slb_dis_ele_spc} $\times$ Age 13--17"
		1.kid_female#0.kid_age_m3#c.dis_shock_DB_m1to12 "${notewrap_p2} ${slb_dis_ele_spc} $\times$ Age 5--8"
		1.kid_female#1.kid_age_m3#c.dis_shock_DB_m1to12 "${slb_dis_ele_spc} $\times$ Age 9--12"
		1.kid_female#2.kid_age_m3#c.dis_shock_DB_m1to12 "${slb_dis_ele_spc} $\times$ Age 13--17"
		
		0.kid_female#0.kid_age_m3#c.dis_shock_DM_g9to24 "${notewrap_p1} ${slb_dis_ele_spc} $\times$ Age 5--8"
		0.kid_female#1.kid_age_m3#c.dis_shock_DM_g9to24 "${slb_dis_ele_spc} $\times$ Age 9--12"
		0.kid_female#2.kid_age_m3#c.dis_shock_DM_g9to24 "${slb_dis_ele_spc} $\times$ Age 13--17"
		1.kid_female#0.kid_age_m3#c.dis_shock_DM_g9to24 "${notewrap_p2} ${slb_dis_ele_spc} $\times$ Age 5--8"
		1.kid_female#1.kid_age_m3#c.dis_shock_DM_g9to24 "${slb_dis_ele_spc} $\times$ Age 9--12"
		1.kid_female#2.kid_age_m3#c.dis_shock_DM_g9to24 "${slb_dis_ele_spc} $\times$ Age 13--17"	
	";
	
	global slb_panel_main "
		coeflabels($slb_coef_label_panel)
		";
		
		
	esttab $est_tab_col using "${st_tab_tex}", replace 			
		keep( 0.kid_female#0.kid_age_m3#c.dis_shock_DB_m1to12 0.kid_female#1.kid_age_m3#c.dis_shock_DB_m1to12 0.kid_female#2.kid_age_m3#c.dis_shock_DB_m1to12 
	1.kid_female#0.kid_age_m3#c.dis_shock_DB_m1to12 1.kid_female#1.kid_age_m3#c.dis_shock_DB_m1to12 1.kid_female#2.kid_age_m3#c.dis_shock_DB_m1to12 
	0.kid_female#0.kid_age_m3#c.dis_shock_DM_g9to24 0.kid_female#1.kid_age_m3#c.dis_shock_DM_g9to24 0.kid_female#2.kid_age_m3#c.dis_shock_DM_g9to24 
	1.kid_female#0.kid_age_m3#c.dis_shock_DM_g9to24 1.kid_female#1.kid_age_m3#c.dis_shock_DM_g9to24 1.kid_female#2.kid_age_m3#c.dis_shock_DM_g9to24 ) 
		order( 0.kid_female#0.kid_age_m3#c.dis_shock_DB_m1to12 0.kid_female#1.kid_age_m3#c.dis_shock_DB_m1to12 0.kid_female#2.kid_age_m3#c.dis_shock_DB_m1to12 
	1.kid_female#0.kid_age_m3#c.dis_shock_DB_m1to12 1.kid_female#1.kid_age_m3#c.dis_shock_DB_m1to12 1.kid_female#2.kid_age_m3#c.dis_shock_DB_m1to12 
	0.kid_female#0.kid_age_m3#c.dis_shock_DM_g9to24 0.kid_female#1.kid_age_m3#c.dis_shock_DM_g9to24 0.kid_female#2.kid_age_m3#c.dis_shock_DM_g9to24 
	1.kid_female#0.kid_age_m3#c.dis_shock_DM_g9to24 1.kid_female#1.kid_age_m3#c.dis_shock_DM_g9to24 1.kid_female#2.kid_age_m3#c.dis_shock_DM_g9to24 ) 
		cells(b(star fmt(3)) se(par fmt (3))) 
		label varwidth(50) nomtitle collabels(none) compress alignment(D{.}{.}{-1}) 
		star(* 0.10 ** 0.05 *** 0.01) 
		substitute(\_ _) 
		${slb_panel_main}
		${slb_titling_bottom}
		nonotes 
		plain 
		refcat( 0.kid_female#0.kid_age_m3#c.dis_shock_DB_m1to12 "${notewrap1}" 
			0.kid_female#0.kid_age_m3#c.dis_shock_DM_g9to24 "${notewrap2}", nolabel) 
		prehead("{"
		"\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
		"\begin{tabular}{l*{3}{D{.}{.}{-1}}}"
		"\toprule"
		"&\multicolumn{1}{c}{(1)}         &\multicolumn{1}{c}{(2)}         &\multicolumn{1}{c}{(3)}         \\"
		"&\multicolumn{1}{c}{${TypeB}}         &\multicolumn{1}{c}{${TypeC}}         &\multicolumn{1}{c}{${TypeD}}         \\"
		"\midrule"
		)
		postfoot("\bottomrule" 
		"\end{tabular}" 
		"}"
		)
	;

#delimit cr 
	   

/* Drop the fake variable. */
drop dis_shock_DB_m1to12 dis_shock_DM_g9to24

