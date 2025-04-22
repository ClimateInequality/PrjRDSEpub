/* Project: PIRE - ADBI - natural disaster and educaitonal outcome 

Author: Yujie Zhang 
Date: 20230601

*/


*******************************************************************************
* set up directory
*******************************************************************************

/* folder to work offline
************************************************************************************
if there is something change you are not ready to share/update with team member 
*/

if `main_yujie_offline' == 1 {
	
}

/*uses c(hostname) macro to identify who is running script and create correct directory macros*/

if "`current_host'" == "Econ-TU105-LT30" {
	
	// ~ below means the User on this laptop, such as "C:\Users\yjiez" or "C:\Users\yzhan292" 
	global dir_main "~\UH-ECON Dropbox\Yujie Zhang\PIRE\team\yujie_zhang\PrjRDSE" 

	global dir_program "$dir_main\program\000_github\PrjRDSE" 
	global dir_log "$dir_main\log"

	global dir_mics "~\UH-ECON Dropbox\Yujie Zhang\PIRE\team\yujie_zhang\DATA\MICS\MICS6_raw_data\asia"
	global dir_emdat "~\UH-ECON Dropbox\Yujie Zhang\PIRE\team\yujie_zhang\DATA\EMDAT"
	
	global dir_rawdata "$dir_main\rawdata" 
	global dir_rawdata_mics "$dir_main\rawdata\mics"
	
	global dir_tempdata "$dir_main\data_temp"	
	global dir_data "$dir_main\data"
	
	global dir_result_temp "$dir_main\result_temp"
	
	global dir_table "$dir_main\table"
	global dir_figure "$dir_main\figure" 
	global dir_proj_note "$dir_main\proj_note"

	global today "20230601"
	
}



if "`current_host'" == "DESKTOP-C7FORAE" {
	
	// ~ below means the User on this laptop, such as "C:\Users\yjiez" or "C:\Users\yzhan292" 
	global dir_main "~\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE" 
	
	global dir_program "$dir_main\program\000_github\PrjRDSE" 
	global dir_log "$dir_main\log"

	global dir_mics "~\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\DATA\MICS\MICS6_raw_data\asia"
	global dir_emdat "~\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\DATA\EMDAT"
	
	global dir_rawdata "$dir_main\rawdata" 
	global dir_rawdata_mics "$dir_main\rawdata\mics"
	
	global dir_tempdata "$dir_main\data_temp"	
	global dir_data "$dir_main\data"
	
	global dir_result_temp "$dir_main\result_temp"
	
	global dir_table "$dir_main\table"
	global dir_figure "$dir_main\figure" 
	global dir_proj_note "$dir_main\proj_note"
	
	global today "20230601"

}

macro list 