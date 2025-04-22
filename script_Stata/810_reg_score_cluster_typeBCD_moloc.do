/* Project: PIRE 

Author: Yujie Zhang 
Date: 20240530

This is based on 806_reg_score_cluster_typeBCD AND 808_reg_score_cluster_moloc
Format each table .tex file so that we do not need to manualy add lines and spaces in Latex. 
Type BCD disaster measure, for math test score outcome regression. 
Limit sample to children whose mothers have not moved. 

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

global today = "20240307"

///--- Install log2html
// ssc install log2html

efolder cherry, cd("$dir_tempdata")
cd "$dir_program"

/************************************* The Main Code Starts Here *************************************/

***** Load Data

set more off
set trace off

global st_computer "yz"
global st_model "810_reg_score_cluster_typeBCD_moloc"
global st_country_file "All"

*----- Set folder name by country in the temporary result folder with code running computer 
efolder $st_computer, cd("$dir_result_temp")
efolder $st_model, cd("$dir_result_temp\\${st_computer}")
efolder $st_country_file, cd("$dir_result_temp\\${st_computer}\\${st_model}")
cd "$dir_program"
global st_file_root "$dir_result_temp\\${st_computer}\\${st_model}\\${st_country_file}"


*----- Set file name by disaster intensity type and shock measure 
global st_log_file "${st_file_root}\\reg_score"
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

u "$dir_data\\data_to_est\\est_mics_child_moloc", clear

// Keep children whose mother stay in same location with longer duration than age (sample of non-movers)
keep if modur_longer_than_kidage == 1

do 701_fan_sandbox_gen.do

global core_rhs "kid_female mo_alive fa_alive mo_inHH fa_inHH mo_elevel_E_ever mo_elevel_A_secondary"
global core_cdn "if inrange(kid_age, 5, 17)"

// global core_opt_1 "vce(robust) 				absorb(RDSE_loc_id kid_int_y kid_int_m kid_age countryfile_num#A_t_1)"
global core_opt_1 "vce(cluster RDSE_loc_id) absorb(RDSE_loc_id kid_int_y kid_int_m kid_age countryfile_num#A_t_1)"

// global core_opt_2 "vce(robust) 				absorb(countryfile_num#HH1 kid_int_y kid_int_m kid_age countryfile_num#A_t_1)"
global core_opt_2 "vce(cluster RDSE_loc_id) absorb(countryfile_num#HH1 kid_int_y kid_int_m kid_age countryfile_num#A_t_1)"

// global core_opt_3 "vce(robust) absorb(countryfile_num#HH1 kid_int_y kid_int_m kid_age countryfile_num#A_max)"

// global core_opt_4 "vce(robust) absorb(countryfile_num#HH1 kid_int_y kid_int_m kid_age countryfile_num#A_t)"


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

	la var kid_female "Female"
	la var mo_alive "Mother is alive"
	la var mo_inHH "Mother is alive $\times$ living in same HH"
	la var fa_alive "Father is alive"
	la var fa_inHH "Father is alive $\times$ living in same HH"
	la var mo_elevel_E_ever "Mother ever educated"
	la var mo_elevel_A_secondary "Mother  ever educated $\times$ has secondary"

	la var dis_A_DB_m1to12 "Had disaster in most recent 12 mo."
	la var dis_A_DB_m13to24 "Had disaster in yr prior 12 mo. ago"
	// la var dis_A_DB_g25_to_m25 "Had disaster after 1000 days until 2 yr before survey mo"
	la var dis_A_DB_g25_to_m25 "Had disaster in mid-child life"
	la var dis_A_DB_g9to24 "Had disaster in first 1000 days"

	la var dis_A_DM_m1to12 "\# of mo. with disaster in most recent 12 mo"
	la var dis_A_DM_m13to24 "\# of mo. with disaster in yr prior 12 mo ago"
	// la var dis_A_DM_g25_to_m25 "\# of mo. with disaster after 1000 days until 2 yr before survey mo"
	la var dis_A_DM_g25_to_m25 "\# of mo. with disaster in mid-child life"
	la var dis_A_DM_g9to24 "\# of mo. with disaster in first 1000 days"

end

pr_label

/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Table. reg_score_1. 
Change FE, why we want to have country X A_max FE  
------------------------------------------------------------------------------*/

global dis_history "dis_shock_DB_m1to12 dis_shock_DB_m13to24 dis_shock_DM_g25_to_m25 dis_shock_DM_g9to24"


foreach itype in "1" "2" "3" {

	rename ${dis_shock_`itype'}_D* dis_shock_D*
	
	global col_`itype' " reghdfe math_score_total ${dis_history}  ${core_rhs}  ${core_cdn}, ${core_opt_1} "

	${col_`itype'}
	cap estadd local FE_withincountry "Y"
	cap estadd local FE_int_y "Y"
	cap estadd local FE_int_m "Y"
	cap estadd local FE_age "Y"	
	cap estadd local FE_country_X_A_t_1 "Y"
	
	est store reg_`itype'
	esttab reg_`itype'
	
	rename dis_shock_D* ${dis_shock_`itype'}_D* 

}

global est_tab_col " reg_1 reg_2 reg_3 "
global st_tab_tex  "${st_log_file}_1_WithinCountryLocationFE.tex"
global st_tab_html  "${st_log_file}_1_WithinCountryLocationFE.html"



cap program drop pr_fakevar
program define pr_fakevar

	/* Create fake variable so that variable label can be captured and show in table. */
	cap drop dis_shock_DB_m1to12  dis_shock_DB_m13to24 dis_shock_DM_g25_to_m25 dis_shock_DM_g9to24
	gen dis_shock_DB_m1to12 = . 
	la var dis_shock_DB_m1to12 "Had disaster in recent 12 mo."
	gen dis_shock_DB_m13to24 = .
	la var dis_shock_DB_m13to24 "Had disaster in yr prior 12 mo. ago"
	gen dis_shock_DM_g25_to_m25 = .
	la var dis_shock_DM_g25_to_m25 "\# of mo. with disaster in mid-child life"
	gen dis_shock_DM_g9to24 = . 
	la var dis_shock_DM_g9to24 "\# of mo. with disaster in the first 1000 days"

end 

pr_fakevar

/* Output to html -----------------
-------------------------*/

	esttab $est_tab_col using "${st_tab_html}", replace /// 
		keep( dis_shock_DB_m1to12 dis_shock_DB_m13to24 dis_shock_DM_g25_to_m25 dis_shock_DM_g9to24 ///
	kid_female mo_alive fa_alive mo_inHH fa_inHH mo_elevel_E_ever mo_elevel_A_secondary ) ///
		order( dis_shock_DB_m1to12 dis_shock_DB_m13to24 dis_shock_DM_g25_to_m25 dis_shock_DM_g9to24 ///
	kid_female mo_alive fa_alive mo_inHH fa_inHH mo_elevel_E_ever mo_elevel_A_secondary ) ///
		cells(b(star fmt(3)) se(par fmt (3))) ///
		label varwidth(50) nomtitle collabels(none) compress alignment(D{.}{.}{-1}) ///
		star(* 0.10 ** 0.05 *** 0.01) ///
		substitute(\_ _) ///
		scalars( "N Obs." "FE_withincountry Within country location FE" "FE_int_y Interview year FE" "FE_int_m Interview month FE" "FE_age Child age FE" "FE_country_X_cluster Country X cluster FE" "FE_country_X_A_t_1 Country X attainment t FE" ) ///
		nonotes 


/* Output to tex -----------------
-------------------------*/

cap program drop pr_fakevar_1
program define pr_fakevar_1

	/* Create fake variable so that variable label can be captured and show in table. */
	cap drop dis_shock_DB_m1to12  dis_shock_DB_m13to24 dis_shock_DM_g25_to_m25  dis_shock_DM_g9to24
	cap drop ${dis_history}
	gen dis_shock_DB_m1to12 = . 
	gen dis_shock_DB_m13to24 = .
	gen dis_shock_DM_g25_to_m25 = .
	gen dis_shock_DM_g9to24 = . 
	
	la var dis_shock_DB_m1to12 "in recent 12 mo."
	la var dis_shock_DB_m13to24 "in yr prior 12 mo. ago"
	la var dis_shock_DM_g25_to_m25 "($ > $ 1000 days) \& ($ < $ yr. before last yr.)"
	la var dis_shock_DM_g9to24 "in the first 1000 days"

	foreach v of varlist $dis_history {
		label variable `v' `"\hspace{3mm} `: variable label `v''"'
	}

end 

pr_fakevar_1

	global it_reg_n = 3

	scalar it_esttad_n = 5
	matrix mt_bl_estd = J(it_esttad_n, $it_reg_n, 0)
	matrix rownames mt_bl_estd = FE_withincountry FE_int_y FE_int_m FE_age FE_country_X_A_t_1
	matrix colnames mt_bl_estd = reg_1 reg_2 reg_3 

	global st_estd_rownames : rownames mt_bl_estd

	global slb_estd_1 "Within country location FE"
	global slb_estd_2 "Interview year FE"
	global slb_estd_3 "Interview month FE"
	global slb_estd_4 "Child age FE"
	global slb_estd_5 "Attainment $ t $ $\times$ country FE"
	
#delimit;

	global notewrap1 "
		\addlinespace[0.3em]
		\multicolumn{4}{l}{\textit{\textbf{Recent} experience: had disaster}} \\
		\addlinespace[0.2em] %
		";

	global notewrap2 "
		\addlinespace[0.3em]
		\multicolumn{4}{l}{\textit{\textbf{Mid-child life} experience: \# of mo. with disaster}} \\
		\addlinespace[0.2em] %
		";

	global notewrap3 "
		\addlinespace[0.3em]
		\multicolumn{4}{l}{\textit{\textbf{Early-life} experience: \# of mo. with disaster}} \\
		\addlinespace[0.2em] %
		";

	global notewrap4 "
		\addlinespace[0.3em]
		\cmidrule(l{20pt}r{4pt}){2-4}
		\addlinespace[0.2em] %
		";
	
	global slb_fot_lst_spc "\vspace*{0mm}\hspace*{2mm}"
	;
	
	global slb_titling_bottom `"
	stats(N $st_estd_rownames,
			fmt(%9.0g)
			labels("\midrule Observations"
			"\midrule ${slb_fot_lst_spc}${slb_estd_1}"
			"${slb_fot_lst_spc}${slb_estd_2}"
			"${slb_fot_lst_spc}${slb_estd_3}"
			"${slb_fot_lst_spc}${slb_estd_4}"
			"${slb_fot_lst_spc}${slb_estd_5}"
			))"';


	esttab $est_tab_col using "${st_tab_tex}", replace 
		keep( ${dis_history} 
	kid_female mo_alive fa_alive mo_inHH fa_inHH mo_elevel_E_ever mo_elevel_A_secondary ) 
		order( ${dis_history} 
	kid_female mo_alive fa_alive mo_inHH fa_inHH mo_elevel_E_ever mo_elevel_A_secondary ) 
		cells(b(star fmt(3)) se(par fmt (3))) 
		label varwidth(50) nomtitle collabels(none) compress alignment(D{.}{.}{-1}) 
		star(* 0.10 ** 0.05 *** 0.01)
		substitute(\_ _)
		${slb_titling_bottom}
		nonotes 
		plain 
		refcat(dis_shock_DB_m1to12 "${notewrap1}" dis_shock_DM_g25_to_m25 "${notewrap2}" 
	dis_shock_DM_g9to24 "${notewrap3}" kid_female "${notewrap4}", nolabel) 
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
drop ${dis_history}





/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Table. 3. Heterogeneity across ages
------------------------------------------------------------------------------*/

global v_age = "kid_age_m4"

global dis_recent_1 "dis_shock_DB_m1to12"
global dis_recent_2 "dis_shock_DB_m13to24"
global dis_midlife "dis_shock_DM_g25_to_m25"
global dis_earlylife "dis_shock_DM_g9to24"


foreach itype in "1" "2" "3" {

	rename ${dis_shock_`itype'}_D* dis_shock_D*
	
	global col_`itype' " reghdfe math_score_total c.${dis_recent_1}#i.${v_age} c.${dis_recent_2}#i.${v_age} c.${dis_midlife}#i.${v_age} c.${dis_earlylife}#i.${v_age} 		${core_rhs} ${core_cdn}, ${core_opt_1} "

	${col_`itype'}
	cap estadd local FE_withincountry "Y"
	cap estadd local FE_int_y "Y"
	cap estadd local FE_int_m "Y"
	cap estadd local FE_age "Y"	
	cap estadd local FE_country_X_A_t_1 "Y"
	
	return list 
	mat li r(table)
	
	est store reg_`itype'
	esttab reg_`itype'
	
	rename dis_shock_D* ${dis_shock_`itype'}_D* 

}
	
global est_tab_col " reg_1 reg_2 reg_3 "
global st_tab_tex  "${st_log_file}_3_${v_age}.tex"
global st_tab_html  "${st_log_file}_3_${v_age}.html"


pr_fakevar

/* Output to html -----------------
-------------------------*/
	  
	esttab $est_tab_col using "${st_tab_html}", replace ///  
	  keep( 0.${v_age}#c.dis_shock_DM_g25_to_m25  1.${v_age}#c.dis_shock_DM_g25_to_m25 2.${v_age}#c.dis_shock_DM_g25_to_m25 ///
	0.${v_age}#c.dis_shock_DM_g9to24  1.${v_age}#c.dis_shock_DM_g9to24 2.${v_age}#c.dis_shock_DM_g9to24 ) ///
	  order( 0.${v_age}#c.dis_shock_DM_g25_to_m25  1.${v_age}#c.dis_shock_DM_g25_to_m25 2.${v_age}#c.dis_shock_DM_g25_to_m25 ///
	0.${v_age}#c.dis_shock_DM_g9to24  1.${v_age}#c.dis_shock_DM_g9to24 2.${v_age}#c.dis_shock_DM_g9to24 ) ///
	  cells(b(star fmt(3)) se(par fmt (3))) ///
	  label varwidth(50) nomtitle collabels(none) compress alignment(D{.}{.}{-1}) ///
	  star(* 0.10 ** 0.05 *** 0.01) ///
	  substitute(\_ _) ///
	  scalars( "N Obs." "FE_withincountry Within country location FE" "FE_int_y Interview year FE" "FE_int_m Interview month FE" "FE_age Child age FE" "FE_country_X_cluster Country X cluster FE" "FE_country_X_A_t_1 Country X attainment t FE" ) ///
	  nonotes 	  



/* Output to tex -----------------
-------------------------*/

	global it_reg_n = 3

	scalar it_esttad_n = 5
	matrix mt_bl_estd = J(it_esttad_n, $it_reg_n, 0)
	matrix rownames mt_bl_estd = FE_withincountry FE_int_y FE_int_m FE_age FE_country_X_A_t_1
	matrix colnames mt_bl_estd = reg_1 reg_2 reg_3 

	global st_estd_rownames : rownames mt_bl_estd

	global slb_estd_1 "Within country location FE"
	global slb_estd_2 "Interview year FE"
	global slb_estd_3 "Interview month FE"
	global slb_estd_4 "Child age FE"
	global slb_estd_5 "Attainment $ t $ $\times$ country FE"
	
#delimit;
	
	global slb_fot_lst_spc "\vspace*{0mm}\hspace*{2mm}"
	;
	
	global slb_titling_bottom `"
	stats(N $st_estd_rownames,
			fmt(%9.0g)
			labels("\midrule Observations"
			"\midrule ${slb_fot_lst_spc}${slb_estd_1}"
			"${slb_fot_lst_spc}${slb_estd_2}"
			"${slb_fot_lst_spc}${slb_estd_3}"
			"${slb_fot_lst_spc}${slb_estd_4}"
			"${slb_fot_lst_spc}${slb_estd_5}"
			))"';
	
	global notewrap1 "
		\addlinespace[0.2em]
		\multicolumn{4}{l}{\textbf{\# of mo. with disaster in mid-child life}} \\
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
		0.${v_age}#c.${dis_midlife} "${slb_dis_ele_spc} $\times$ Age 7--9"
		1.${v_age}#c.${dis_midlife} "${slb_dis_ele_spc} $\times$ Age 10--12"
		2.${v_age}#c.${dis_midlife} "${slb_dis_ele_spc} $\times$ Age 13--14"
		0.${v_age}#c.${dis_earlylife} "${slb_dis_ele_spc} $\times$ Age 7--9"
		1.${v_age}#c.${dis_earlylife} "${slb_dis_ele_spc} $\times$ Age 10--12"
		2.${v_age}#c.${dis_earlylife} "${slb_dis_ele_spc} $\times$ Age 13--14"
	";
	
	global slb_panel_main "
		coeflabels($slb_coef_label_panel)
		";
	
	
			
	esttab $est_tab_col using "${st_tab_tex}", replace 
		keep( 0.${v_age}#c.${dis_midlife}  1.${v_age}#c.${dis_midlife}  2.${v_age}#c.${dis_midlife} 
	0.${v_age}#c.${dis_earlylife}  1.${v_age}#c.${dis_earlylife}  2.${v_age}#c.${dis_earlylife} ) 
		order( 0.${v_age}#c.${dis_midlife}  1.${v_age}#c.${dis_midlife}  2.${v_age}#c.${dis_midlife} 
	0.${v_age}#c.${dis_earlylife}  1.${v_age}#c.${dis_earlylife}  2.${v_age}#c.${dis_earlylife} ) 
		cells(b(star fmt(3)) se(par fmt (3))) 
		label varwidth(50) nomtitle collabels(none) compress alignment(D{.}{.}{-1}) 
		star(* 0.10 ** 0.05 *** 0.01)
		substitute(\_ _)
		${slb_panel_main}
		${slb_titling_bottom}
		nonotes 
		plain 
		refcat(0.${v_age}#c.${dis_midlife} "${notewrap1}" 0.${v_age}#c.${dis_earlylife} "${notewrap2}", nolabel) 
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
drop ${dis_history}

	  

	  
	  
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Table. 6. Heterogeneity across gender 
------------------------------------------------------------------------------*/

foreach itype in "1" "2" "3" {

	rename ${dis_shock_`itype'}_D* dis_shock_D*
	
	global col_`itype' " reghdfe math_score_total c.${dis_recent_1}#i.kid_female c.${dis_recent_2}#i.kid_female c.${dis_midlife}#i.kid_female c.${dis_earlylife}#i.kid_female  		${core_rhs} ${core_cdn}, ${core_opt_1} "

	${col_`itype'}
	cap estadd local FE_withincountry "Y"
	cap estadd local FE_int_y "Y"
	cap estadd local FE_int_m "Y"
	cap estadd local FE_age "Y"	
	cap estadd local FE_country_X_A_t_1 "Y"
	
	return list 
	mat li r(table)
	
	est store reg_`itype'
	esttab reg_`itype'
	
	rename dis_shock_D* ${dis_shock_`itype'}_D* 

}
	
global est_tab_col " reg_1 reg_2 reg_3 "
global st_tab_tex  "${st_log_file}_6.tex"
global st_tab_html  "${st_log_file}_6.html"


pr_fakevar

/* Output to html -----------------
-------------------------*/
  
	esttab $est_tab_col using "${st_tab_html}", replace /// 
	  keep( 0.kid_female#c.dis_shock_DM_g25_to_m25  1.kid_female#c.dis_shock_DM_g25_to_m25 ///
	0.kid_female#c.dis_shock_DM_g9to24  1.kid_female#c.dis_shock_DM_g9to24 ) ///
	  order( 0.kid_female#c.dis_shock_DM_g25_to_m25  1.kid_female#c.dis_shock_DM_g25_to_m25 ///
	0.kid_female#c.dis_shock_DM_g9to24  1.kid_female#c.dis_shock_DM_g9to24 ) ///
	  cells(b(star fmt(3)) se(par fmt (3))) ///
	  label varwidth(50) nomtitle collabels(none) compress alignment(D{.}{.}{-1}) ///
	  star(* 0.10 ** 0.05 *** 0.01) ///
	  substitute(\_ _) ///
  	  scalars( "N Obs." "FE_withincountry Within Country Location FE" "FE_int_y Interview Year FE" "FE_int_m Interview Month FE" "FE_age Child Age FE" "FE_country_X_cluster Country X Cluster FE" "FE_country_X_A_t_1 Country X Attainment t FE" ) ///
	  nonotes 
	  

/* Output to tex -----------------
-------------------------*/

	global it_reg_n = 3

	scalar it_esttad_n = 5
	matrix mt_bl_estd = J(it_esttad_n, $it_reg_n, 0)
	matrix rownames mt_bl_estd = FE_withincountry FE_int_y FE_int_m FE_age FE_country_X_A_t_1
	matrix colnames mt_bl_estd = reg_1 reg_2 reg_3 

	global st_estd_rownames : rownames mt_bl_estd

	global slb_estd_1 "Within country location FE"
	global slb_estd_2 "Interview year FE"
	global slb_estd_3 "Interview month FE"
	global slb_estd_4 "Child age FE"
	global slb_estd_5 "Attainment $ t $ $\times$ country FE"
	
#delimit;
	
	global slb_fot_lst_spc "\vspace*{0mm}\hspace*{2mm}"
	;
	
	global slb_titling_bottom `"
	stats(N $st_estd_rownames,
			fmt(%9.0g)
			labels("\midrule Observations"
			"\midrule ${slb_fot_lst_spc}${slb_estd_1}"
			"${slb_fot_lst_spc}${slb_estd_2}"
			"${slb_fot_lst_spc}${slb_estd_3}"
			"${slb_fot_lst_spc}${slb_estd_4}"
			"${slb_fot_lst_spc}${slb_estd_5}"
			))"';
	
	global notewrap1 "
		\addlinespace[0.2em]
		\multicolumn{4}{l}{\textbf{\# of mo. with disaster in mid-child life}} \\
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
		0.kid_female#c.${dis_midlife} "${slb_dis_ele_spc} $\times$ Male"
		1.kid_female#c.${dis_midlife} "${slb_dis_ele_spc} $\times$ Female"
		0.kid_female#c.${dis_earlylife} "${slb_dis_ele_spc} $\times$ Male"
		1.kid_female#c.${dis_earlylife} "${slb_dis_ele_spc} $\times$ Female"
	";
	
	global slb_panel_main "
		coeflabels($slb_coef_label_panel)
		";
	
	
			
	esttab $est_tab_col using "${st_tab_tex}", replace 
		keep( 0.kid_female#c.${dis_midlife}  1.kid_female#c.${dis_midlife}  
	0.kid_female#c.${dis_earlylife}  1.kid_female#c.${dis_earlylife}   ) 
		order( 0.kid_female#c.${dis_midlife}  1.kid_female#c.${dis_midlife}  
	0.kid_female#c.${dis_earlylife}  1.kid_female#c.${dis_earlylife}   ) 
		cells(b(star fmt(3)) se(par fmt (3))) 
		label varwidth(50) nomtitle collabels(none) compress alignment(D{.}{.}{-1}) 
		star(* 0.10 ** 0.05 *** 0.01)
		substitute(\_ _)
		${slb_panel_main}
		${slb_titling_bottom}
		nonotes 
		plain 
		refcat(0.kid_female#c.${dis_midlife} "${notewrap1}" 0.kid_female#c.${dis_earlylife} "${notewrap2}", nolabel) 
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
drop ${dis_history}

	  

	  
	  
/*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------*/
/* Table. 7. Heterogeneity across ages + gender
------------------------------------------------------------------------------*/

global v_age = "kid_age_m4"

foreach itype in "1" "2" "3" {

	rename ${dis_shock_`itype'}_D* dis_shock_D*
	
	global col_`itype' " reghdfe math_score_total c.${dis_recent_1}#i.kid_female#i.${v_age} c.${dis_recent_2}#i.kid_female#i.${v_age} c.${dis_midlife}#i.kid_female#i.${v_age} c.${dis_earlylife}#i.kid_female#i.${v_age}  		${core_rhs} ${core_cdn}, ${core_opt_1} "

	${col_`itype'}
	cap estadd local FE_withincountry "Y"
	cap estadd local FE_int_y "Y"
	cap estadd local FE_int_m "Y"
	cap estadd local FE_age "Y"	
	cap estadd local FE_country_X_A_t_1 "Y"
	
	return list 
	mat li r(table)
	
	est store reg_`itype'
	esttab reg_`itype'
	
	rename dis_shock_D* ${dis_shock_`itype'}_D* 

}

global est_tab_col " reg_1 reg_2 reg_3 "
global st_tab_tex  "${st_log_file}_7_${v_age}.tex"
global st_tab_html  "${st_log_file}_7_${v_age}.html"


pr_fakevar


/* Output to html -----------------
-------------------------*/

	esttab $est_tab_col using "${st_tab_html}", replace ///
		keep( 0.kid_female#0.${v_age}#c.${dis_midlife} 0.kid_female#1.${v_age}#c.${dis_midlife} 0.kid_female#2.${v_age}#c.${dis_midlife} ///
		1.kid_female#0.${v_age}#c.${dis_midlife} 1.kid_female#1.${v_age}#c.${dis_midlife} 1.kid_female#2.${v_age}#c.${dis_midlife} ///
		0.kid_female#0.${v_age}#c.${dis_earlylife} 0.kid_female#1.${v_age}#c.${dis_earlylife} 0.kid_female#2.${v_age}#c.${dis_earlylife} ///
		1.kid_female#0.${v_age}#c.${dis_earlylife} 1.kid_female#1.${v_age}#c.${dis_earlylife} 1.kid_female#2.${v_age}#c.${dis_earlylife} ) ///
		order( 0.kid_female#0.${v_age}#c.${dis_midlife} 0.kid_female#1.${v_age}#c.${dis_midlife} 0.kid_female#2.${v_age}#c.${dis_midlife} ///
		1.kid_female#0.${v_age}#c.${dis_midlife} 1.kid_female#1.${v_age}#c.${dis_midlife} 1.kid_female#2.${v_age}#c.${dis_midlife} ///
		0.kid_female#0.${v_age}#c.${dis_earlylife} 0.kid_female#1.${v_age}#c.${dis_earlylife} 0.kid_female#2.${v_age}#c.${dis_earlylife} ///
		1.kid_female#0.${v_age}#c.${dis_earlylife} 1.kid_female#1.${v_age}#c.${dis_earlylife} 1.kid_female#2.${v_age}#c.${dis_earlylife} ) ///
		cells(b(star fmt(3)) se(par fmt (3))) ///
		label varwidth(50) nomtitle collabels(none) compress alignment(D{.}{.}{-1}) ///
		star(* 0.10 ** 0.05 *** 0.01) ///
		substitute(\_ _) ///
		scalars( "N Obs." "FE_withincountry Within country location FE" "FE_int_y Interview year FE" "FE_int_m Interview month FE" "FE_age Child age FE" "FE_country_X_cluster Country X cluster FE" "FE_country_X_A_t_1 Country X attainment t FE" ) ///
		nonotes 


		
/* Output to tex -----------------
-------------------------*/

	global it_reg_n = 3

	scalar it_esttad_n = 5
	matrix mt_bl_estd = J(it_esttad_n, $it_reg_n, 0)
	matrix rownames mt_bl_estd = FE_withincountry FE_int_y FE_int_m FE_age FE_country_X_A_t_1
	matrix colnames mt_bl_estd = reg_1 reg_2 reg_3 

	global st_estd_rownames : rownames mt_bl_estd

	global slb_estd_1 "Within country location FE"
	global slb_estd_2 "Interview year FE"
	global slb_estd_3 "Interview month FE"
	global slb_estd_4 "Child age FE"
	global slb_estd_5 "Attainment $ t $ $\times$ country FE"
	
#delimit;
	
	global slb_fot_lst_spc "\vspace*{0mm}\hspace*{2mm}"
	;
	
	global slb_titling_bottom `"
	stats(N $st_estd_rownames,
			fmt(%9.0g)
			labels("\midrule Observations"
			"\midrule ${slb_fot_lst_spc}${slb_estd_1}"
			"${slb_fot_lst_spc}${slb_estd_2}"
			"${slb_fot_lst_spc}${slb_estd_3}"
			"${slb_fot_lst_spc}${slb_estd_4}"
			"${slb_fot_lst_spc}${slb_estd_5}"
			))"';
	
	global notewrap1 "
		\addlinespace[0.2em]
		\multicolumn{4}{l}{\textbf{\# of mo. with disaster in mid-child life}} \\
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
		0.kid_female#0.${v_age}#c.${dis_midlife} "${notewrap_p1} ${slb_dis_ele_spc} $\times$ Age 7--9"
		0.kid_female#1.${v_age}#c.${dis_midlife} "${slb_dis_ele_spc} $\times$ Age 10--12"
		0.kid_female#2.${v_age}#c.${dis_midlife} "${slb_dis_ele_spc} $\times$ Age 13--14"
		1.kid_female#0.${v_age}#c.${dis_midlife} "${notewrap_p2} ${slb_dis_ele_spc} $\times$ Age 7--9"
		1.kid_female#1.${v_age}#c.${dis_midlife} "${slb_dis_ele_spc} $\times$ Age 10--12"
		1.kid_female#2.${v_age}#c.${dis_midlife} "${slb_dis_ele_spc} $\times$ Age 13--14"
		
		0.kid_female#0.${v_age}#c.${dis_earlylife} "${notewrap_p1} ${slb_dis_ele_spc} $\times$ Age 7--9"
		0.kid_female#1.${v_age}#c.${dis_earlylife} "${slb_dis_ele_spc} $\times$ Age 10--12"
		0.kid_female#2.${v_age}#c.${dis_earlylife} "${slb_dis_ele_spc} $\times$ Age 13--14"
		1.kid_female#0.${v_age}#c.${dis_earlylife} "${notewrap_p2} ${slb_dis_ele_spc} $\times$ Age 7--9"
		1.kid_female#1.${v_age}#c.${dis_earlylife} "${slb_dis_ele_spc} $\times$ Age 10--12"
		1.kid_female#2.${v_age}#c.${dis_earlylife} "${slb_dis_ele_spc} $\times$ Age 13--14"
	";
	
	global slb_panel_main "
		coeflabels($slb_coef_label_panel)
	";

				
	esttab $est_tab_col using "${st_tab_tex}", replace 
		keep( 0.kid_female#0.${v_age}#c.${dis_midlife} 0.kid_female#1.${v_age}#c.${dis_midlife} 0.kid_female#2.${v_age}#c.${dis_midlife} 
	1.kid_female#0.${v_age}#c.${dis_midlife} 1.kid_female#1.${v_age}#c.${dis_midlife} 1.kid_female#2.${v_age}#c.${dis_midlife} 
	0.kid_female#0.${v_age}#c.${dis_earlylife} 0.kid_female#1.${v_age}#c.${dis_earlylife} 0.kid_female#2.${v_age}#c.${dis_earlylife} 
	1.kid_female#0.${v_age}#c.${dis_earlylife} 1.kid_female#1.${v_age}#c.${dis_earlylife} 1.kid_female#2.${v_age}#c.${dis_earlylife} ) 
		order( 0.kid_female#0.${v_age}#c.${dis_midlife} 0.kid_female#1.${v_age}#c.${dis_midlife} 0.kid_female#2.${v_age}#c.${dis_midlife} 
	1.kid_female#0.${v_age}#c.${dis_midlife} 1.kid_female#1.${v_age}#c.${dis_midlife} 1.kid_female#2.${v_age}#c.${dis_midlife} 
	0.kid_female#0.${v_age}#c.${dis_earlylife} 0.kid_female#1.${v_age}#c.${dis_earlylife} 0.kid_female#2.${v_age}#c.${dis_earlylife} 
	1.kid_female#0.${v_age}#c.${dis_earlylife} 1.kid_female#1.${v_age}#c.${dis_earlylife} 1.kid_female#2.${v_age}#c.${dis_earlylife} ) 
		cells(b(star fmt(3)) se(par fmt (3))) 
		label varwidth(50) nomtitle collabels(none) compress alignment(D{.}{.}{-1}) 
		star(* 0.10 ** 0.05 *** 0.01)
		substitute(\_ _)
		${slb_panel_main}
		${slb_titling_bottom}
		nonotes 
		plain 
		refcat(0.kid_female#0.${v_age}#c.${dis_midlife} "${notewrap1}" 
	0.kid_female#0.${v_age}#c.${dis_earlylife} "${notewrap2}", nolabel) 
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
drop ${dis_history}

	  