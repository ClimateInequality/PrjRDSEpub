// Country ID 
capture drop countryfile_num
egen countryfile_num = group(countryfile), label
capture drop ISO_alpha_3_num
egen ISO_alpha_3_num = group(ISO_alpha_3), label


// Age groupings 
capture drop kid_age_m2
recode kid_age (min/10 = 0 "Age 5 to 10") (11/17 = 1 "Age 11 to 17") (else  =. ), gen(kid_age_m2)
tab kid_age_m2

// Age groupings 
capture drop kid_age_m3
recode kid_age (min/8 = 0 "Age 5 to 8") (9/12 = 1 "Age 9 to 12") (13/17 = 2 "Age 13 to 17") (else  =. ), gen(kid_age_m3)
tab kid_age_m3
// Note: min of kid_age is age 4, not 5. 

// Age groupings 
capture drop kid_age_m4
recode kid_age (7/9 = 0 "Age 7 to 9") (10/12 = 1 "Age 10 to 12") (13/14 = 2 "Age 13 to 14") (else  =. ), gen(kid_age_m4)
tab kid_age_m4

/* Generate disaster variables */

// cluster identifer: cluster IDs are unique within country
capture drop cluster_tag 
egen cluster_tag = tag(RDSE_loc_id HH1)
capture drop cluster_tag_alt
egen cluster_tag_alt = tag(countryfile_num HH1)
codebook cluster_tag cluster_tag_alt

// MICS disaster at cluster level 
capture drop sch_close_nat_rdse_m
bys RDSE_loc_id kid_int_m: egen sch_close_nat_rdse_m = mean(sch_close_nat)
la var sch_close_nat_rdse_m "School Closure Rate in Location"

capture drop sch_close_nat_clu
bys RDSE_loc_id HH1: egen sch_close_nat_clu = mean(sch_close_nat)
capture drop sch_close_nat_clu_bi
gen sch_close_nat_clu_bi = (sch_close_nat_clu > 0 ) if sch_close_nat_clu !=.
summ sch_close_nat_rdse_m sch_close_nat_clu_bi sch_close_nat_clu sch_close_nat
la var sch_close_nat_clu_bi "Have School Closed in Cluster"

capture drop sch_minhaj_rdse_m
bys RDSE_loc_id kid_int_m: egen sch_minhaj_rdse_m = mean(sch_minhaj)
la var sch_minhaj_rdse_m "Rate of Having School Closure or Teacher Truancy in Location"

// Additional country groupings
cap drop country_group_1
cap drop country_g_1
gen country_group_1 = 0
replace country_group_1 = 1 if ISO_alpha_3 == "PAK"
recode country_group_1 (1=1 "PAK") (0=0 "Not PAK"), gen(country_g_1)
drop country_group_1

cap drop country_group_2
cap drop country_g_2
gen country_group_2 = 0
replace country_group_2 = 1 if ISO_alpha_3 == "PAK"
replace country_group_2 = 2 if ISO_alpha_3 == "BGD"
recode country_group_2 (1=1 "PAK") (2=2 "BGD") (0=0 "Not PAK or BGD"), gen(country_g_2)
drop country_group_2


// Household wealth index 
cap drop hh_wealthHigh
recode hh_windex5 (1/3=0) (4/5=1), gen(hh_wealthHigh)


cap drop hh_windex5_dm
tab hh_windex5, gen(hh_windex5_dm)

