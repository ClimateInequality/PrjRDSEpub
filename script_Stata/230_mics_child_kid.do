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

global today "20230712"

log using "$dir_log\230_mics_child_kid_$today.log", replace



********************************************************************************
* TASK: Construct MICS data child-specific attributes
********************************************************************************

/*
https://github.com/ClimateInequality/PrjRDSE/issues/1

All variables start with `kid_'. 
*/

efolder mics_fs, cd("$dir_tempdata")
efolder mics_hl, cd("$dir_tempdata")
cd "$dir_program"



********************************************************************************
* birthday, age, gender
********************************************************************************


cap program drop birthdaygender
program define birthdaygender

args countryfile 

// 	u "$dir_rawdata\mics\\`countryfile'_fs", clear
// 	local countryfile = "BGD2019"
	u "$dir_rawdata\\mics\\`countryfile'_hl", clear
	rename HL1 LN
	merge 1:1 HH1 HH2 LN using "$dir_rawdata\mics\\`countryfile'_fs"
	keep if _merge == 3
	
	gen countryfile = "`countryfile'", before(HH1)

	* birthday
	fre CB2M CB2Y FSDOB
		// Obtain info from hl.dta 
		replace CB2M = HL5M if CB2M == .
		replace CB2Y = HL5Y if CB2Y == .
		
	clonevar kid_birthm_raw_CB2M_HL5M = CB2M 
	
	decode CB2M, gen(kid_birthm_raw_decode)
	
	clonevar kid_birthm = CB2M
	replace kid_birthm = . if kid_birthm > 90

	clonevar kid_birthy_raw_CB2Y_HL5Y = CB2Y 
	
	decode CB2Y, gen(kid_birthy_raw_decode)
	
	clonevar kid_birthy = CB2Y
	replace kid_birthy = . if kid_birthy > 9000

	rename FSDOB kid_birthdate_raw 
	clonevar kid_birthdate = kid_birthdate_raw
	order kid_birthdate, after(kid_birthdate_raw)

	* age
	fre CB3
		// Obtain info from hl.dta 
		replace CB3 = ED2A if CB3 == .
		replace CB3 = HL6 if CB3 == . 
		
	rename CB3 kid_age_raw_CB3_ED2A_HL6
	clonevar kid_age = kid_age_raw
	order kid_age, after(kid_age_raw)

	* sex 
	fre HL4
	
	clonevar kid_female_raw_HL4 = HL4
	
	recode HL4 (1=0) (2=1), gen(kid_female)
	la var kid_female "Female"
	tab kid_female HL4

	la drop _all
	
	keep countryfile HH1 HH2 LN kid_birthdate* kid_birthm* kid_birthy* kid_age* kid_female*

	sa "$dir_tempdata\mics_fs\\`countryfile'", replace
	export delimited using "$dir_tempdata\mics_fs\\`countryfile'", nolabel replace

end



birthdaygender BGD2019
birthdaygender KGZ2018
birthdaygender MNG2018
birthdaygender NPL2019
birthdaygender PKB2019
birthdaygender PKK2019
birthdaygender PKP2017
birthdaygender PKS2018
birthdaygender T172019
birthdaygender THA2019
birthdaygender TKM2019



u "$dir_tempdata\mics_fs\BGD2019", clear

foreach i in ///
"NPL2019" ///
"PKB2019" ///
"PKK2019" ///
"PKP2017" ///
"PKS2018" ///
"MNG2018" ///
"T172019" ///
"THA2019" ///
"KGZ2018" ///
"TKM2019" ///
{
	append using "$dir_tempdata\mics_fs\\`i'"
}

merge 1:1 countryfile HH1 HH2 LN using "$dir_data\id_key_file\mics_child_id"
keep if _merge == 3
drop _merge
order RDSE_loc_id countryfile HH1 HH2 LN moLN faLN, first


/* save and test ********************/

sa "$dir_tempdata\230_mics_child_kid_1", replace 



********************************************************************************
* relationship to household head
********************************************************************************

local countryfile = "BGD2019"

cap program drop relation
program define relation 

args countryfile 

	u "$dir_rawdata\mics\\`countryfile'_hl", clear

	gen countryfile = "`countryfile'", before(HH1)
	rename HL1 LN 
	duplicates report HH1 HH2 LN 
	
	fre HL3 
	
	clonevar kid_relationtohead_raw_HL3 = HL3 
	
	decode HL3, gen(kid_relationtohead_raw_decode)
	
	clonevar kid_relationtohead = HL3 
	replace kid_relationtohead = . if kid_relationtohead > 90

	keep countryfile HH1 HH2 LN kid_relationtohead*

	sa "$dir_tempdata\mics_hl\\`countryfile'", replace

end 

relation BGD2019

relation BGD2019
relation KGZ2018
relation MNG2018
relation NPL2019
relation PKB2019
relation PKK2019
relation PKP2017
relation PKS2018
relation T172019
relation THA2019
relation TKM2019



u "$dir_tempdata\mics_hl\BGD2019", clear

foreach i in ///
"NPL2019" ///
"PKB2019" ///
"PKK2019" ///
"PKP2017" ///
"PKS2018" ///
"MNG2018" ///
"T172019" ///
"THA2019" ///
"KGZ2018" ///
"TKM2019" ///
{
	append using "$dir_tempdata\mics_hl\\`i'"
}

duplicates report countryfile HH1 HH2 LN


merge 1:1 countryfile HH1 HH2 LN using "$dir_tempdata\230_mics_child_kid_1"
// merge 1:1 countryfile HH1 HH2 LN using "$dir_data\id_key_file\mics_child_id"
keep if _merge == 3
drop _merge
order RDSE_loc_id countryfile HH1 HH2 LN moLN faLN, first


/* save and test ********************/

sa "$dir_tempdata\230_mics_child_kid", replace 

/*
fre kid_relationtohead
fre kid_age countryfile if inlist(kid_relationtohead, 1, 2)
tab kid_age kid_relationtohead
*/



********************************************************************************
* delete temparory data files 
********************************************************************************

// shell rd "$dir_tempdata\cherry" /s /q
// shell rm -r "$dir_tempdata\cherry" /s /q

* delete all files in folder
cd "$dir_tempdata"
shell rd "mics_hl" /s /q
shell rd "mics_fs" /s /q
cd "$dir_program"

* delete folder
cap rmdir "$dir_tempdata\mics_hl"
cap rmdir "$dir_tempdata\mics_fs"




/*

/* BELOW IS FROM 203_BGD_label_var_construct_20230610 ********************************/
/* BELOW IS FROM 203_BGD_label_var_construct_20230610 ********************************/
/* BELOW IS FROM 203_BGD_label_var_construct_20230610 ********************************/




********************************************************************************
* identifier for cluser, household, individual, interview
********************************************************************************

/*
count if HH1 != FS1 
count if HH2 != FS2 
count if LN != FS3

rename HH1 clusterno
rename HH2 hhno
rename LN lineno
*/

rename FS4 motherlineno

* interview info
rename FS7D interviewday
rename FS7M interviewmo
rename FS7Y interviewyr

rename FS8H interviewstarhr
rename FS8M interviewstarmin
rename FS11H interviewendhr
rename FS11M interviewendmin

rename FL2H interviewchildstarthr
rename FL2M interviewchildstartmin



********************************************************************************
* read score 
********************************************************************************

// fre FL19W*
// fre FL20A-FL23F

/* [word] -----------------------------------
This is more like a speaking test? We put this with story comprehension together as reading test to calculate read score. This is also how MICS categorize. 
*/

forvalues i = 1(1)72 {
	rename FL19W`i' readword`i'
}

rename FL20A readwordattempt
rename FL20B readwordmiss
rename FL21 readstory


/* get 1 score if one word is correct, 0 if incorrect or missing ---------------
Instead of adding scores for reading using correct words, we can use [total number of words incorrect of missed] directly. 
If needed, we can check if [total number of words incorrect or missed] is consistent with [word1] - [word72], but by now we are not doing this. 
*/

gen readwordcorrect = 72-readwordmiss
fre readwordcorrect
count if readwordmiss == . & readwordcorrect !=.

/* [story comprehension]
*/

rename FL22A readcomp1
rename FL22B readcomp2
rename FL22C readcomp3
rename FL22D readcomp4
rename FL22E readcomp5

fre readcomp*

foreach i of varlist readcomp1-readcomp5 {
	recode `i' (1=1) (2/9=0), gen(`i'_score)	
} 

fre readcomp*_score

/* add all score and deal with missing value ------------------------------
Child missing all questions on math (recognize symbol, compare numbers, add numbers, identify next number) should be missing because maybe she does not take exam at all. 
For obs where all math1-math15 are missing value, the final math_score should also be missing, but now it is 0 as rowtotal treats missing value as zero 
*/

egen read_score = rowtotal(readwordcorrect readcomp*_score)
// br math*score

egen read_countmissing = rowmiss(readwordcorrect readcomp*_score)
replace read_score = . if read_countmissing == 6 

la var read_score "Reading score"




********************************************************************************
* math score 
********************************************************************************

/* [child recognizes symbol] ------------------------
Before other math questions, they test children ability to recognize number symbol. 

FL23. Turn the page in the READING & NUMBERS BOOK so the child is looking at the list of numbers. Make sure the child is looking at this page.

Now here are some numbers. I want you to point to each number and tell me what the number is. 

We can add this into math score
*/

rename FL23A mathsym1
rename FL23B mathsym2
rename FL23C mathsym3
rename FL23D mathsym4
rename FL23E mathsym5
rename FL23F mathsym6

fre mathsym*

foreach i of varlist mathsym1-mathsym6 {
	recode `i' (1=1) (2=0) (3=0), gen(`i'_score)	
} 

/* [Child identities bigger of two numbers]
[Child adds numbers correctly]
[Child identifies next number]
*/

rename FL24A mathbig1
rename FL24B mathbig2
rename FL24C mathbig3
rename FL24D mathbig4
rename FL24E mathbig5

fre mathbig*


rename FL25A mathadd1
rename FL25B mathadd2
rename FL25C mathadd3
rename FL25D mathadd4
rename FL25E mathadd5

fre mathadd*

rename FL27A mathnext1
rename FL27B mathnext2
rename FL27C mathnext3
rename FL27D mathnext4
rename FL27E mathnext5

fre mathadd*

foreach i of varlist mathbig1-mathbig5 {
	recode `i' (1=1) (2=0) (3=0), gen(`i'_score)	
} 

foreach i of varlist mathadd1-mathadd5 {
	recode `i' (1=1) (2=0) (3=0), gen(`i'_score)	
} 

foreach i of varlist mathnext1-mathnext5 {
	recode `i' (1=1) (2=0) (3=0) (7=0), gen(`i'_score)	
} 

fre math*_score

/* add all math score and deal with missing value ------------------------------
Child missing all questions on math (recognize symbol, compare numbers, add numbers, identify next number) should be missing because maybe she does not take exam at all. 
For obs where all math1-math15 are missing value, the final math_score should also be missing, but now it is 0 as rowtotal treats missing value as zero 
*/

egen math_score = rowtotal(math*_score)
// br math*score

egen math_countmissing = rowmiss(math*_score)
replace math_score = . if math_countmissing == 21 

la var math_score "Math score"


********************************************************************************
* school closure and teacher absenteeism 
********************************************************************************

fre PR12A PR12C PR13

gen schclose = . 
replace schclose = 1 if PR12A == 1
replace schclose = 0 if PR12A == 2 
la var schclose "School close"

gen teacherabs = . 
replace teacherabs = 1 if PR12C == 2 | PR13 == 1 
replace teacherabs = 0 if PR12C == 2 | PR13 == 2
la var teacherabs "Teacher absent"

fre schclose teacherabs 



********************************************************************************
* drop 
********************************************************************************

drop FS1-FS3 
drop FSINT FS5 FS6 FS9 FS10 
// fre FS17
drop FS12-FSFIN

drop CB4-CB10B
drop CL1A-CL6X CL7-CL13 FCD2A-FCD2K
drop FCD3-FCD5 FCF1-FCF26 
drop PR3-PR10 PR11A-PR11B // homework, parents go to school due to 
drop FLINTRO FL1 FL3 FL4A-FL18

drop readword1-readword72 readwordattempt-readcomp5 
drop mathsym1-mathsym6 mathbig1-mathbig5 mathadd1-mathadd5 mathnext1-mathnext5 FL27_shift
drop readwordcorrect-readcomp5_score 
drop mathsym1_score-mathnext5_score

drop ED5A ED5B FSAGE FSDOI FSDOB schage
drop windex10-windex10r

drop fselevel fsdisability caretakerdis melevel
drop HH4 HH52 

sa "$dir_tempdata\BGD2019_fs_merge", replace



********************************************************************************
* parent info and household info 
********************************************************************************

u "$dir_rawdata\mics\BGD2019_hl", clear // hh member

keep HH1 HH2 HL1 melevel felevel MLINE FLINE HL6
rename HL6 hhmemberage
rename HL1 LN
rename MLINE motherlineno 
rename FLINE fatherlineno

// duplicates report HH1 HH2 LN

sa "$dir_tempdata\parent_edu_age", replace



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



sa "$dir_data\BGD2019_child", replace






/*

/*
u "$dir_rawdata\mics\BGD2019_hh", clear // household

fre HHSEX HHAGE ethnicity helevel

keep HH1 HH2 HHSEX HHAGE ethnicity helevel

rename HHSEX hhsex 
rename HHAGE hhage

sa "$dir_tempdata\BGD2019_hh_merge", replace 


u "$dir_rawdata\mics\BGD2019_wm", clear // women 

u "$dir_rawdata\mics\BGD2019_bh", clear // birth history

u "$dir_rawdata\mics\NPL2019_fs", clear // kid under 5

u "$dir_rawdata\mics\BGD2019_mn", clear // men 


*/

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

*/



********************************************************************************
* summary stat
********************************************************************************





cap program drop sumstat 
program define sumstat

args fileanme 

est clear  // clear the stored estimates
estpost tabstat ///
enroldrop enrollastyr enrolthisyr /// 
edulevel /// 
read_score math_score ///
schclose teacherabs ///
kidfemale kidage motherage fatherage /// 
windex5 ///
, c(stat) stat(mean sd min max n) 

ereturn list // list the stored locals

esttab using "$dir_table/`fileanme'.tex", replace ////
cells("mean(fmt(%6.2fc)) sd(fmt(%6.2fc)) min max count(fmt(%6.0fc))") nonumber ///
nomtitle nonote noobs label booktabs ///
collabels("Mean" "SD" "Min" "Max" "N")  ///
// title("Table 1 with title generated in Stata \label{table1stata}")

end

sumstat sum_all







cap program drop sumstat 
program define sumstat

args fileanme 

est clear  // clear the stored estimates
estpost tabstat ///
kidfemale kidage motherage fatherage /// 
windex5 ///
, c(stat) stat(mean sd min max n) by(geocode2) 

ereturn list // list the stored locals

esttab using "$dir_table/`fileanme'.tex", replace ////
cells("mean(fmt(%6.2fc)) sd(fmt(%6.2fc)) min max count(fmt(%6.0fc))") nonumber ///
nomtitle nonote noobs label booktabs ///
collabels("Mean" "SD" "Min" "Max" "N")  ///
// title("Table 1 with title generated in Stata \label{table1stata}")

end

sumstat sum_demo



cap program drop sumstat 
program define sumstat

args fileanme 

est clear  // clear the stored estimates
estpost tabstat ///
schclose teacherabs ///
, c(stat) stat(mean sd min max n) by(geocode2)

ereturn list // list the stored locals

esttab using "$dir_table/`fileanme'.tex", replace ////
cells("mean(fmt(%6.2fc)) sd(fmt(%6.2fc)) min max count(fmt(%6.0fc))") nonumber ///
nomtitle nonote noobs label booktabs ///
collabels("Mean" "SD" "Min" "Max" "N")  ///
// title("Table 1 with title generated in Stata \label{table1stata}")

end

sumstat sum_schclose_teacherabs



cap program drop sumstat 
program define sumstat

args fileanme 

est clear  // clear the stored estimates
estpost tabstat ///
enroldrop enrollastyr enrolthisyr /// 
edulevel /// 
read_score math_score ///
, c(stat) stat(mean sd min max n) by(geocode2)

ereturn list // list the stored locals

esttab using "$dir_table/`fileanme'.tex", replace ////
cells("mean(fmt(%6.2fc)) sd(fmt(%6.2fc)) min max count(fmt(%6.0fc))") nonumber ///
nomtitle nonote noobs label booktabs ///
collabels("Mean" "SD" "Min" "Max" "N")  ///
// title("Table 1 with title generated in Stata \label{table1stata}")

end

sumstat sum_edu_outcome








/* for all variable, order by variable type ----------------
*/

// ssc install sum2docx, replace 

local kidvar " kidage kidfemale "
local parent " motherage motheredulevel fatherage fatheredulevel "
// local demovar " cityid gdp fiscialexpenditure educexpenditure professionals gyms theater librarybooks "


cap putdocx begin
putdocx paragraph, halign(center)
putdocx save sumstat.docx, replace

foreach v in `kidvar' `parent' {
	sum2docx `v'* using sumstat.docx, append stats(N mean(%9.1f) sd(%9.1f) min(%9.1g) median(%9.1g) max(%9.1g)) title("Table 1: sum stat for `v'")
}








cap program drop regmaryr
program define regmaryr

args filename

cd "$dir_table"

reg `filename' kidage schclose teacherabs motherage fatherage windex5, cluster(geocode2)
outreg
outreg2 using `filename'.xls, label excel replace ctitle(`fileanme') bdec(3) sdec(2) tdec(2) pdec(2) cdec(2) rdec(2)

cd "$dir_program"

end


regmaryr enroldrop 
regmaryr enrolthisyr
regmaryr enrollastyr
regmaryr edulevel
regmaryr read_score
regmaryr math_score



cap program drop regmaryr
program define regmaryr

args filename

cd "$dir_table"

reg `filename' schclose motherage fatherage windex5, cluster(geocode2)
outreg
outreg2 using `filename'_schclose.xls, label excel replace ctitle(`fileanme') bdec(3) sdec(2) tdec(2) pdec(2) cdec(2) rdec(2)

cd "$dir_program"

end


regmaryr enroldrop 
regmaryr enrolthisyr
regmaryr enrollastyr
regmaryr edulevel
regmaryr read_score
regmaryr math_score


cap program drop regmaryr
program define regmaryr

args filename

cd "$dir_table"

reg `filename' teacherabs motherage fatherage windex5, cluster(geocode2)
outreg
outreg2 using `filename'_schclose.xls, label excel replace ctitle(`fileanme') bdec(3) sdec(2) tdec(2) pdec(2) cdec(2) rdec(2)

cd "$dir_program"

end


regmaryr enroldrop 
regmaryr enrolthisyr
regmaryr enrollastyr
regmaryr edulevel
regmaryr read_score
regmaryr math_score




fre everschool



************************************
regmaryr reg_maryr_all_1980




