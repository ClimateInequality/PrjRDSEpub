# -*- coding: utf-8 -*-

'''
---------------------------------------------------
Project: PIRE 
Author: Yujie Zhang 
Date: 20230204
---------------------------------------------------

TASK: https://github.com/ClimateInequality/PrjRDSE/issues/7

Create data file for EMDAT disaster with location and timing to MICS location id (RDSE location id). 
    Row: disaster X location X timing 
    Column: (1) disaster id (2) location id (3) calendar month (or year, depending on which timing level we use) (4) start month/year of this disaster (5) end month/year of this disaster 
    Note: Column (1)-(3) are essential, others are optional as the informaiton will be duplicated. 
    
Create data file for MICS child lifecycle timing file -  MICS_child_negative_lifecycle_skeleton. 
    Row: MICS child X timing 
    Column: (1) location id (2) MICS child id (3) lifecycle calendar month (or year, depending on which timing level we use) (4) the age expressed by monthly or yearly corresponding to that calendar month (5) birth year and month (6) interview year and month 
    Note: Column (1)-(4) are essential, others are optional as the informaiton will be duplicated.         
    
WARNING:
-----------
This script is separated into:
    317_disaster_RDSEloc_timing.py
    321_YZ.py

'''

'''
Clear all variables and data frames from the current workspace
-------------------------------------------------------------------------------
'''

for var in list(globals()):
    if not var.startswith("__"):
        del globals()[var]

for var in list(locals()):
    if not var.startswith("__"):
        del locals()[var]
        
'''
Install packages by typing the below in system terminal and import packages
-------------------------------------------------------------------------------
'''

# pip3 install pandas
# pip install pandasgui
# from pandasgui import show
# show(df)

import os
import pandas as pd
# import numpy as np
# import math
# import matplotlib.pyplot as plt
# import seaborn as sns
from datetime import datetime

# Remove normal warnings
import warnings
warnings.simplefilter('ignore')

'''
Import locals, such as directory
'''

# When you open this .py file, the working directory is "C:\Users\yzhan187", so change working directory to `program` and then import other short names you want for other directory.

dir_program = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\program\000_github\PrjRDSE"

# Change the working directory
os.chdir(dir_program)
# Print the current working directory
print("Current working directory: {0}".format(os.getcwd())) 

# _locals_dir.py should be in the same working directory as this script. This helps when we work on multiple computers. 

locals_included = 'YES' # We can turn this off. 

if locals_included == 'YES': 
    import _locals_dir
    from _locals_dir import dir_main, dir_program, dir_rawdata, dir_tempdata, dir_data
    from _locals_dir import locals_dir 
    locals_dir()



# %% 
'''
Import dataset and define function 
-------------------------------------------------------------------------------
'''

# df_emdat_rawdata = pd.read_csv(f'{dir_data}/emdat/emdat_public_adbi_proj_country.csv')
df_315_disaster_RDSEloc = pd.read_csv(f'{dir_data}/data_intermediate/315_disaster_RDSEloc.csv')
df_314_disaster_info = pd.read_csv(f'{dir_data}/data_intermediate/314_disaster_info.csv')


# WARNING: (f'{dir_data}/data_intermediate/234_mics_sch_file2A.csv') and (f'{dir_data}/data_intermediate/230_mics_child.csv') did not convert calendar for Nepal and Thailand. Use the $dir_data\data_to_est\\240_mics_child_pa_hh instead. 

# df_232_mics_sch_file2A = pd.read_csv(f'{dir_data}/data_intermediate/234_mics_sch_file2A.csv')
# df_230_mics_child = pd.read_csv(f'{dir_data}/data_intermediate/230_mics_child.csv')

df_240_mics_child_pa_hh = pd.read_csv(f'{dir_data}/data_to_est/240_mics_child_pa_hh.csv')


# ----------------------------------------------
# Function to translate Gregorian calendar to "elaspsed time" (we refer it as calendar month here). It is the months difference between current month and Jan 1900.
# ----------------------------------------------

# def calculate_months_since_1900(row):
#     specified_date = datetime(int(row['StartYear']), int(row['StartMonth']), 1)
#     start_date = datetime(1900, 1, 1)
#     months_difference = (specified_date.year - start_date.year) * 12 + (specified_date.month - start_date.month)
#     return months_difference

# df['StartMonthsSince1900'] = df.apply(calculate_months_since_1900, axis=1)

def calculate_months_since_1900(row, year_col, month_col):
    '''
    If year is greater than 5000, or month does not belong to [1,12], then calendar month should be None. 
    Else, calculate the month between current (year, month) variable and January, 1900. 
    '''
    if row[year_col] > 5000 or row[month_col] > 20: 
        return None
    else: 
        specified_date = datetime(int(row[year_col]), int(row[month_col]), 1)
        start_date = datetime(1900, 1, 1)
        months_difference = (specified_date.year - start_date.year) * 12 + (specified_date.month - start_date.month)
        return months_difference

# ----------------------------------------------
# Function to convert "MonthsSince1900" into "Year" and "Month" columns.
# ----------------------------------------------

def convert_months_since_1900(months_since_1900):
    '''
    Parameters
    ----------
    months_since_1900 : float/integer 

    Returns
    -------
    If months_since_1990 is None, then `years` and `months` will also be None. 
    If months_since_1990 has value, then calculate the corresponding year and month. 
    
    Implement
    ---------
    df[['year', 'month']] = df[timing_var].apply(convert_months_since_1900).apply(pd.Series)
    '''
    years, months = divmod(months_since_1900, 12)
    return years + 1900, months + 1



# %% 
'''
*******************************************************************************

MODULE 1. Create disaster_RDSEloc_timing file: disaster_RDSEloc_year

*******************************************************************************
'''

# STEP 1. Merge file with original disaster file to obtain the timing of disaster 

df = df_315_disaster_RDSEloc # Specify the file working on mainly 

df = pd.merge(df, df_314_disaster_info, on='DisNo', how='left')
# df = df[['DisNo', 'RDSE_loc_affect', 'StartYear', 'StartMonth', 'StartDay', 'EndYear', 'EndMonth', 'EndDay']]
df = df[['DisNo', 'RDSE_loc_affect', 'StartYear', 'EndYear']]

df = df.sort_values(by = ['DisNo', 'RDSE_loc_affect'])

# STEP 2. Transform date (year, month) into uniform time measure 

# Drop disasters where we do not know start year/month or end year/month 
df = df[df['StartYear'].notna() & df['EndYear'].notna()]

# STEP 3. Expand time of disaster to panel 

# 1. Array of Months in the Survey
df['ar_year'] = df['EndYear'] - df['StartYear'] + 1    # This is number of years 
df['ID'] = range(1, len(df) + 1)     # Create unique ID 

# 2. Sort and generate variable equal to sorted index
df_panel = df.loc[df.index.repeat(df['ar_year'])]

# 3. Panel now construct exactly which year in survey, note that all needed is sort index
# Note sorting not needed, all rows identical now
df_panel['year_in_dis'] = df_panel.groupby('ID').cumcount() + 1

df_panel['cld_year_in_dis'] = df_panel['StartYear'] + df_panel['year_in_dis'] - 1

# STEP 4. Simplify data file, keep necessary columns

df_panel = df_panel[['DisNo', 'RDSE_loc_affect', 'StartYear', 'EndYear', 'cld_year_in_dis']]

df_panel = df_panel.drop_duplicates()

# STEP 5. Output: disaster X location X year in disaster data file  

# Specify the path and filename for CSV file and export DataFrame to CSV
dir_csv_file = f'{dir_data}/data_intermediate/316_disaster_RDSEloc_year.csv'
df_panel.to_csv(dir_csv_file, index=False)



# %% 
'''
*******************************************************************************

MODULE 2. Create disaster_RDSEloc_timing file: disaster_RDSEloc_month

*******************************************************************************
'''

# STEP 1. Merge file with original disaster file to obtain the timing of disaster 

df = df_315_disaster_RDSEloc # Specify the file working on mainly 

df = pd.merge(df, df_314_disaster_info, on='DisNo', how='left')
# df = df[['DisNo', 'RDSE_loc_affect', 'StartYear', 'StartMonth', 'StartDay', 'EndYear', 'EndMonth', 'EndDay']]
df = df[['DisNo', 'RDSE_loc_affect', 'StartYear', 'StartMonth', 'EndYear', 'EndMonth']]

df = df.sort_values(by = ['DisNo', 'RDSE_loc_affect'])

# STEP 2. Transform date (year, month) into uniform time measure 

'''
Simple version, only consider months for disaster. 
We want to expand this into panel, and imagine we use 201905 to denote May, 2019. 
For one row, starting month is 201905, ending month is 201108, then the difference will be 797 months, then the algorithm for `1.3 Expanding to Panel` in https://fanwangecon.github.io/R4Econ/summarize/count/htmlpdfr/fs_count_basics.html will not be applicable. 
Solution to this is using the amount of months between the date and 1990 Jan 1st. 
For example, 2015 April will be identical to value 1383. 
'''

# =============================================================================
# # rows_with_missing_values = df[df['StartYear'].isna() & df['StartMonth'].isna()]
# # 0 obs
# rows_with_missing_values = df[~df['StartYear'].isna() & df['StartMonth'].isna()]
# # 5 obs, PAK 2009 
# # rows_with_missing_values = df[df['StartYear'].isna() & ~df['StartMonth'].isna()]
# # 0 obs
# 
# # rows_with_missing_values = df[df['EndYear'].isna() & df['EndMonth'].isna()]
# # 0 obs
# rows_with_missing_values = df[~df['EndYear'].isna() & df['EndMonth'].isna()]
# # 53 obs
# # rows_with_missing_values = df[df['EndYear'].isna() & ~df['EndMonth'].isna()]
# # 0 obs
# 
# # Check what disasters they are if they miss end year or month
# rows_with_missing_values = pd.merge(rows_with_missing_values, df_314_disaster_info, on='DisNo', how='left')
# # All of them are drought. Some of them are serious, 1999-9122-PAK, heat wave, 143 people died. 
# rows_with_missing_values = rows_with_missing_values.drop(columns = 'RDSE_loc_affect')
# rows_with_missing_values = rows_with_missing_values.drop_duplicates()
# # 7 disasters
# =============================================================================

# Way 1: Drop disasters where we do not know start year/month or end year/month 
df = df[df['StartYear'].notna() & df['StartMonth'].notna() & df['EndYear'].notna() & df['EndMonth'].notna()]

# =============================================================================
# # Way 2: Impute month with below assumption
#     # If there is StartYear and StartMonth, and EndYear, but no EndMonth, assume EndMonth = 12
#     # If there is StartYear and EndYear, assume StartMonth=1 & EndMonth=12
# # =============================================================================
# # def assume_EndMonth(row):
# #     if not pd.isna(row['StartYear']) and not pd.isna(row['StartMonth']) and not pd.isna(row['EndYear']): 
# #         return 12
# #     else: 
# #         return None
# 
# # df['EndMonth'] = df.apply(assume_EndMonth, axis=1)
# # =============================================================================
# 
# df['StartMonth'] = df['StartMonth'].fillna(1)    
# df['EndMonth'] = df['EndMonth'].fillna(12)
# =============================================================================

# Translate Gregorian calendar into calendar month
df['StartMonthsSince1900'] = df.apply(calculate_months_since_1900, args=('StartYear','StartMonth'), axis=1)
df['EndMonthsSince1900'] = df.apply(calculate_months_since_1900, args=('EndYear','EndMonth'), axis=1)

# STEP 3. Expand time of disaster to panel 

'''
Input: Each row of the file is disaster ID (DisNo) and location id (RDSE_loc_id) jointly identified. 
There is starting date and ending date for each disaster. 

Output: https://github.com/ClimateInequality/PrjRDSE/issues/7
Rows: Each unit of observation is at the location * month * disaster level
Columns: disaster-id, location-id, year/month
'''

# 1. Array of Months in the Survey
df['ar_month'] = df['EndMonthsSince1900'] - df['StartMonthsSince1900'] + 1    # This is number of years 
df['ID'] = range(1, len(df) + 1)     # Create unique ID 

# 2. Sort and generate variable equal to sorted index
df_panel = df.loc[df.index.repeat(df['ar_month'])]

# 3. Panel now construct exactly which year in survey, note that all needed is sort index
# Note sorting not needed, all rows identical now
df_panel['month_in_dis'] = df_panel.groupby('ID').cumcount() + 1

df_panel['cld_month_in_dis'] = df_panel['StartMonthsSince1900'] + df_panel['month_in_dis'] - 1
# `cld_month_in_dis` means calendar month in disaster. 


# STEP 4. Transform uniform time measure into date (year, month) 
'''
This step may not be necessary, as we also need uniform time measure to merge with MICS child life. 
But it is more straightforward to check those columns. 
'''

# Apply the function to the "MonthsSince1900" column
df_panel[['in_dis_y', 'in_dis_m']] = df_panel['cld_month_in_dis'].apply(convert_months_since_1900).apply(pd.Series)

# STEP 5. Simplify data file, keep necessary columns

df_panel = df_panel[['DisNo', 'RDSE_loc_affect', 'StartYear', 'StartMonth', 'EndYear', 'EndMonth', 'cld_month_in_dis', 'in_dis_y', 'in_dis_m']]
# df_panel = df_panel[['DisNo', 'RDSE_loc_affect', 'StartYear', 'StartMonth', 'EndYear', 'EndMonth', 'cld_month_in_dis']]

df_panel = df_panel.drop_duplicates()
# From 3425 to 3424 obs. 

# STEP 6. Output: disaster X location X month in disaster data file  

# Specify the path and filename for CSV file and export DataFrame to CSV
dir_csv_file = f'{dir_data}/data_intermediate/316_disaster_RDSEloc_month.csv'
df_panel.to_csv(dir_csv_file, index=False)



# %% 
'''
*******************************************************************************

MODULE 3. Create MICS_child_life_timing file: MICS_child_life_year

*******************************************************************************
'''

# STEP 1. file input 

df = df_240_mics_child_pa_hh
# df = df[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'kid_birthdate', 'kid_birthm', 'kid_birthy', 'kid_int_y', 'kid_int_m']]
df = df[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'kid_age', 'kid_birthy', 'kid_int_y']]

# STEP 2. Transform date (year, month) into uniform time measure 

# No birth year, with age => birth year === interview year - age 
def find_kid_birthy(row):
    if pd.isna(row['kid_birthy']) and not pd.isna(row['kid_age']):
        return row['kid_int_y'] - row['kid_age']
    else: 
        return row['kid_birthy']
    
df['kid_birthy'] = df.apply(find_kid_birthy, axis=1)

# No age, with birth year => age === interview year - birthy ear 
def find_kid_age(row):
    if pd.isna(row['kid_age']) and not pd.isna(row['kid_birthy']):
        return row['kid_int_y'] - row['kid_birthy']
    else: 
        return row['kid_age']

df['kid_age'] = df.apply(find_kid_age, axis=1)

df = df[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'kid_birthy', 'kid_int_y', 'kid_age']]
df = df[df['kid_birthy'].notna()]

# STEP 3. Expand time of disaster to panel 

# 1. Array of Years in the Survey
df['ar_year'] = df['kid_int_y'] - df['kid_birthy'] + 1    # Number of months
df['ID'] = range(1, len(df) + 1)     # Create unique ID 

# 2. Sort and generate variable equal to sorted index
# Only keep the children we know birth information
df = df[df['ar_year'].notna()]
df_panel = df.loc[df.index.repeat(df['ar_year'])]

# 3. Panel now construct exactly which year in survey, note that all needed is sort index
# Note sorting not needed, all rows identical now
df_panel['year_prenatal_to_mics6'] = df_panel.groupby('ID').cumcount() + 1

df_panel['cld_year_prenatal_to_mics6'] = df_panel['kid_birthy'] - 1 + df_panel['year_prenatal_to_mics6'] 
# `cld_month_prenatal_to_mics6` means calendar month from conception to MICS6 interview. 

# 4. Calculate the age of child in that calendar year (age point)
df_panel['kid_age_pt'] = df_panel['year_prenatal_to_mics6'] - 1

# STEP 4. Simplify data file, keep necessary columns

df_panel = df_panel[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'kid_birthy', 'kid_int_y', 'kid_age', 'cld_year_prenatal_to_mics6', 'kid_age_pt']]

# df_panel = df_panel.drop_duplicates()
# There should not be duplicates, and there is no duplicates. 

# STEP 5. Output: MICS child X timing (year)

# Specify the path and filename for the CSV file and export DataFrame to CSV
dir_csv_file = f'{dir_data}/data_intermediate/316_MICS_child_prenatal_to_mics6_year.csv'
df_panel.to_csv(dir_csv_file, index=False)

df_316_MICS_child_prenatal_to_mics6_year = df_panel

# %% 
'''
*******************************************************************************

MODULE 4. Create MICS_child_life_timing file: MICS_child_life_month

*******************************************************************************
'''

# STEP 1. file input 

df = df_240_mics_child_pa_hh
# df = df[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'kid_birthdate', 'kid_birthm', 'kid_birthy', 'kid_int_y', 'kid_int_m']]
df = df[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'kid_age', 'kid_birthy', 'kid_birthm', 'kid_int_y', 'kid_int_m']]

# STEP 2. Transform date (year, month) into uniform time measure 

# No birth year, with age => birth year === interview year - age 
def find_kid_birthy(row):
    if pd.isna(row['kid_birthy']) and not pd.isna(row['kid_age']):
        return row['kid_int_y'] - row['kid_age']
    else: 
        return row['kid_birthy']
    
df['kid_birthy'] = df.apply(find_kid_birthy, axis=1)

# No age, with birth year => age === interview year - birthy ear 
def find_kid_age(row):
    if pd.isna(row['kid_age']) and not pd.isna(row['kid_birthy']):
        return row['kid_int_y'] - row['kid_birthy']
    else: 
        return row['kid_age']

df['kid_age'] = df.apply(find_kid_age, axis=1)

# =============================================================================
# # Check the missing value in birth year and birth month column 
# rows_with_missing_values_A = df[df['kid_birthy'].isna() & df['kid_birthm'].isna()]
# # 3560 obs 
# 
# rows_with_missing_values_B = df[df['kid_birthy'].isna() & ~df['kid_birthm'].isna()]
# # 0 obs, so everyone without month info must also have no birth year. 
# 
# rows_with_missing_values_C = df[~df['kid_birthy'].isna() & df['kid_birthm'].isna()]
# # 3204 obs, with birth year, but no birth month
# =============================================================================

# Assumption: 
    # If birth year is missing, then birth month must be missing, and we do not make assumption.  
    # If birth year is not missing, but birth month is missing, then we assume birth month is January in birth year. 
    # If birth year is not missing, and birth month is not missing, then birth month will just be the birth month from raw data. 
def assume_kid_birthm_1forNaN(row):
    if pd.isna(row['kid_birthy']): 
        return row['kid_birthm']
    if not pd.isna(row['kid_birthy']):
        if pd.isna(row['kid_birthm']):
            return 1
        if not pd.isna(row['kid_birthm']):
            return row['kid_birthm']

df['kid_birthm_1forNaN'] = df.apply(assume_kid_birthm_1forNaN, axis=1)

# Cannot convert float NaN to integer, so impute missing value to 9999 for now
df['kid_birthy'] = df['kid_birthy'].fillna(9999)        
df['kid_birthm'] = df['kid_birthm'].fillna(99)          

df['kid_birthy'] = df['kid_birthy'].astype(int)
df['kid_birthm'] = df['kid_birthm'].astype(int)

# Translate Gregorian calendar into calendar month
# df['BirthMonthsSince1900'] = df.apply(calculate_months_since_1900, args=('kid_birthy','kid_birthm'), axis=1)
df['BirthMonthsSince1900'] = df.apply(calculate_months_since_1900, args=('kid_birthy','kid_birthm_1forNaN'), axis=1)
df['PrenatalMonthsSince1900'] = df['BirthMonthsSince1900'] - 10
df['IntMonthsSince1900'] = df.apply(calculate_months_since_1900, args=('kid_int_y','kid_int_m'), axis=1)

rows_with_missing_values_A = df[df['kid_birthy']==9999]
# 3560 obs 

# STEP 3. Expand time of disaster to panel 

# 1. Array of Months in the Survey
df['ar_month'] = df['IntMonthsSince1900'] - df['PrenatalMonthsSince1900'] + 1    # Number of months
df['ID'] = range(1, len(df) + 1)     # Create unique ID 

# 2. Sort and generate variable equal to sorted index
# Replace missing values with 0. Otherwise, ERROR: repeats may not contain negative values.
# df['ar_month'] = df['ar_month'].fillna(0)

# Only keep the children we know birth information
df = df[df['ar_month'].notna()]
df_panel = df.loc[df.index.repeat(df['ar_month'])]

# =============================================================================
# # Calculate the minimum and maximum values in the specified column
# min_value = df['ar_month'].min()
# max_value = df['ar_month'].max()
# 
# # Print the range of values
# print(f"Range of values in 'ar_month': {min_value} to {max_value}")
# 60 to 228 
# =============================================================================

# 3. Panel now construct exactly which year in survey, note that all needed is sort index
# Note sorting not needed, all rows identical now
df_panel['month_prenatal_to_mics6'] = df_panel.groupby('ID').cumcount() + 1

df_panel['cld_month_prenatal_to_mics6'] = df_panel['PrenatalMonthsSince1900'] + df_panel['month_prenatal_to_mics6'] - 1
# `cld_month_prenatal_to_mics6` means calendar month from conception to MICS6 interview. 

# STEP 4. Transform uniform time measure into date (year, month) 
'''
This step may not be necessary, as we also need uniform time measure to merge with other timing file. 
It takes long time for this step. Do not run this. 
22459105 obs, too large to retrive. 
'''

# Apply the function to the "MonthsSince1900" column
# df_panel[['prenatal_to_mics6_y', 'prenatal_to_mics6_m']] = df_panel['cld_month_prenatal_to_mics6'].apply(convert_months_since_1900).apply(pd.Series)

# STEP 5. Simplify data file, keep necessary columns

df_panel = df_panel[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'cld_month_prenatal_to_mics6']]

df_panel = df_panel.drop_duplicates()

# STEP 6. Output: MICS child X timing (month)

# Specify the path and filename for the CSV file and export DataFrame to CSV
dir_csv_file = f'{dir_data}/data_intermediate/316_MICS_child_prenatal_to_mics6_month.csv'
df_panel.to_csv(dir_csv_file, index=False)





# %% 
'''
*******************************************************************************

MODULE 5. Create MICS_child_interview_timing file: MICS_child_interview_month

*******************************************************************************
'''

# Consider the period covered in questionnaire about school closure and teacher truancy. "In last 12 months, have your school been closed at least on 1 day". We take interview month, then travel back 12 months and take this as "interview period". The variable will be `cld_month_int_cover`.

# STEP 1. file 

df = df_240_mics_child_pa_hh 
df = df[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'ISO_alpha_3', 'kid_int_m', 'kid_int_y']]

# STEP 2. Transform date (year, month) into uniform time measure 

# Translate Gregorian calendar into calendar month
df['IntMonthsSince1900'] = df.apply(calculate_months_since_1900, args=('kid_int_y','kid_int_m'), axis=1)

# STEP 3. Expand time of disaster to panel 

# 1. Array of Months in the Survey
df['ar_month'] = 12 # This is number of months 
df['ID'] = range(1, len(df) + 1)     # Create unique ID 

# 2. Sort and generate variable equal to sorted index
df_panel = df.loc[df.index.repeat(df['ar_month'])]

# 3. Panel now construct exactly which year in survey, note that all needed is sort index
# Note sorting not needed, all rows identical now
df_panel['month_int_cover'] = df_panel.groupby('ID').cumcount() + 1

df_panel['cld_month_int_cover'] = df_panel['IntMonthsSince1900'] - df_panel['month_int_cover'] + 1
# `cld_month_in_dis` means calendar month in disaster. 

# STEP 4. Transform uniform time measure into date (year, month) 
'''
# This step may not be necessary, as we also need uniform time measure to merge with other timing file. 
# But it is more straightforward to check those columns. 
'''

# Apply the function to the "MonthsSince1900" column
# df_panel[['int_cover_y', 'int_cover_m']] = df_panel['cld_month_int_cover'].apply(convert_months_since_1900).apply(pd.Series)

# STEP 5. Simplify data file, keep necessary columns

df_panel = df_panel[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'ISO_alpha_3', 'kid_int_y','kid_int_m', 'cld_month_int_cover']]
# df_panel = df_panel[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'ISO_alpha_3', 'cld_month_int_cover']]

df_panel = df_panel.drop_duplicates()
# 1944180 obs 

# Quick check for THA and NPL 
df_NPL_THA = df_panel[(df_panel['ISO_alpha_3'] == 'NPL') | (df_panel['ISO_alpha_3'] == 'THA')]

# STEP 6. Output 

# Specify the path and filename for the CSV file
dir_csv_file = f'{dir_data}/data_intermediate/316_MICS_child_month_int_cover.csv'

# Export the DataFrame to CSV
df_panel.to_csv(dir_csv_file, index=False)





# %% 
'''
*******************************************************************************

MODULE 6. Create MICS_child_negative_lifecycle_skeleton file: YZ file

*******************************************************************************

https://github.com/ClimateInequality/PrjRDSE/issues/23

This file will be used to generate child lifecycle-specific and location-date-specific disaster history.

row: child X month 
    number of rows for each child, regardless of age, generate (if looking back M years for AC exercise): max(age+1, M)*12
    
column: (1) RDSE location id (2) child id (3) calendar month (CMC calendar) (4) child age in that month 

'''

# STEP 1. file input 

df = df_240_mics_child_pa_hh
# df = df[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'kid_birthdate', 'kid_birthm', 'kid_birthy', 'kid_int_y', 'kid_int_m']]
df = df[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'kid_age', 'kid_birthy', 'kid_birthm', 'kid_int_y', 'kid_int_m']]

# Set up M years of location history 
N = 20

# To test code, take only first 100 rows 
df = df.head(100)


# %% STEP 2. Transform date (year, month) into uniform time measure 

# No birth year, with age => birth year === interview year - age 
def find_kid_birthy(row):
    if pd.isna(row['kid_birthy']) and not pd.isna(row['kid_age']):
        return row['kid_int_y'] - row['kid_age']
    else: 
        return row['kid_birthy']
    
df['kid_birthy'] = df.apply(find_kid_birthy, axis=1)

# No age, with birth year => age === interview year - birthy ear 
def find_kid_age(row):
    if pd.isna(row['kid_age']) and not pd.isna(row['kid_birthy']):
        return row['kid_int_y'] - row['kid_birthy']
    else: 
        return row['kid_age']

df['kid_age'] = df.apply(find_kid_age, axis=1)

# =============================================================================
# # Check the missing value in birth year and birth month column 
# rows_with_missing_values_A = df[df['kid_birthy'].isna() & df['kid_birthm'].isna()]
# # 3560 obs 
# 
# rows_with_missing_values_B = df[df['kid_birthy'].isna() & ~df['kid_birthm'].isna()]
# # 0 obs, so everyone without month info must also have no birth year. 
# 
# rows_with_missing_values_C = df[~df['kid_birthy'].isna() & df['kid_birthm'].isna()]
# # 3204 obs, with birth year, but no birth month
# =============================================================================

# Assumption: 
    # If birth year is missing, then birth month must be missing, and we do not make assumption.  
    # If birth year is not missing, but birth month is missing, then we assume birth month is January in birth year. 
    # If birth year is not missing, and birth month is not missing, then birth month will just be the birth month from raw data. 
def assume_kid_birthm_1forNaN(row):
    if pd.isna(row['kid_birthy']): 
        return row['kid_birthm']
    if not pd.isna(row['kid_birthy']):
        if pd.isna(row['kid_birthm']):
            return 1
        if not pd.isna(row['kid_birthm']):
            return row['kid_birthm']

df['kid_birthm_1forNaN'] = df.apply(assume_kid_birthm_1forNaN, axis=1)

# Cannot convert float NaN to integer, so impute missing value to 9999 for now
df['kid_birthy'] = df['kid_birthy'].fillna(9999)        
df['kid_birthm'] = df['kid_birthm'].fillna(99)          

df['kid_birthy'] = df['kid_birthy'].astype(int)
df['kid_birthm'] = df['kid_birthm'].astype(int)

# Translate Gregorian calendar into calendar month
# df['BirthMonthsSince1900'] = df.apply(calculate_months_since_1900, args=('kid_birthy','kid_birthm'), axis=1)
df['BirthMonthsSince1900'] = df.apply(calculate_months_since_1900, args=('kid_birthy','kid_birthm_1forNaN'), axis=1)
df['IntMonthsSince1900'] = df.apply(calculate_months_since_1900, args=('kid_int_y','kid_int_m'), axis=1)

rows_with_missing_values_A = df[df['kid_birthy']==9999]
# 3560 obs 

# %% STEP 3. Expand time of month to panel 

# 1. Array of Months in the Survey

# Number of months
# The below line only goes back to 10 months before child is born, from then to interview month. But we want either prenatal month or longest AC history month, which is max[(age+1)*12, N*12]

# Number of months from conception to interview month 
df['ar_month_1'] = df['IntMonthsSince1900'] - (df['BirthMonthsSince1900'] - 10) + 1    

# Number of months from history month to interview month (length of history)
df['ar_month_2'] = N*12 + 1 

df['ar_month'] = df[['ar_month_1', 'ar_month_2']].apply(max, axis=1)

df['ID'] = range(1, len(df) + 1)     # Create unique ID 

# 2. Sort and generate variable equal to sorted index
# Replace missing values with 0. Otherwise, ERROR: repeats may not contain negative values.
# df['ar_month'] = df['ar_month'].fillna(0)

# Only keep the children we know birth information
df = df[df['ar_month'].notna()]
df_panel = df.loc[df.index.repeat(df['ar_month'])]

# =============================================================================
# # Calculate the minimum and maximum values in the specified column
# min_value = df['ar_month'].min()
# max_value = df['ar_month'].max()
# 
# # Print the range of values
# print(f"Range of values in 'ar_month': {min_value} to {max_value}")
# 60 to 228 
# =============================================================================

# 3. Panel now construct exactly which year in survey, note that all needed is sort index. Note sorting not needed, all rows identical now

# month_mics6_to_history: number of month from MICS6 interview month into history 
df_panel['month_mics6_to_history'] = df_panel.groupby('ID').cumcount() + 1

# `month_history_to_mics6` means calendar month from the month we want to go back in history to MICS6 interview. 
df_panel['cld_month_mics6_to_history'] = df_panel['IntMonthsSince1900'] - df_panel['month_mics6_to_history'] + 1

# %% 4. Age point in month 
'''
Two cases: 
    (1) prenatal month < history month, i.e. (age+1)*12 < N*12, ar_month_1 < ar_month_2. 
    
    For example, child Anna is age 6, born in 2012 Sept, interviewed in 2019 May, then her BirthMonthsSince1900 = 1352, IntMonthsSince1900 = 1432, ar_month_1 = 91, ar_month_2 = 121 if we want to track back to 10 years ago. Then ar_month for Anna will be 121, as we track back to 10 years ago for the place Anna is living in, although Anna only lives there for 6 years. The age_month_prenatal_to_mics6 is the monthly age point of her lifecycle, 80, 79, 78, ..., 0, -1, ..., -10 (conception), -11, -12, ..., -30, -40. 
    Anna cannot be living -40 months before her birth. We can replace the unreasonalble months into None. 
    
    (2) prenatal month > history month, i.e. (age+1)*12 > N*12, ar_month_1 > ar_month_2.
'''

df_panel['age_month_mics6_to_history'] = df_panel['cld_month_mics6_to_history'] - df_panel['BirthMonthsSince1900']

df_panel['age_month_mics6_to_prenatal'] = df_panel['age_month_mics6_to_history'].apply(lambda x: None if x < -10 else x)

# %% STEP 4. Transform CMC month measure into year

# 1. Number of year from MICS6 to history 

# Divide moonthly age point by 12 and take only the integer, get rid of remainder. 
df_panel['year_mics6_to_history'] = df_panel['month_mics6_to_history'].apply(lambda x: None if x is None else x // 12)

# 2. Calender year from MICS6 to history
 
# Apply function convert_months_since_1900 to the "cld_month_mics6_to_history" column
df_panel[['mics6_to_history_y', 'mics6_to_history_m']] = df_panel['cld_month_mics6_to_history'].apply(convert_months_since_1900).apply(pd.Series)

# 3. Age in year from MICS6 to history 

# Divide moonthly age point by 12 and take only the integer, get rid of remainder. 
df_panel['age_year_mics6_to_history'] = df_panel['age_month_mics6_to_history'].apply(lambda x: None if x is None else x // 12)

# 4. Age in year from MICS6 to prenatal 

# Divide moonthly age point by 12 and take only the integer, get rid of remainder. 
df_panel['age_year_mics6_to_prenatal'] = df_panel['age_month_mics6_to_prenatal'].apply(lambda x: None if x is None else x // 12)

# %% STEP 5. Simplify data file, keep necessary columns

df_panel = df_panel.drop(['ar_month_1', 'ar_month_2', 'ar_month', 'ID'], axis=1)
# df_panel = df_panel[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'cld_month_prenatal_to_mics6']]

# Change order of columns 
df_panel = df_panel[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 
                     'kid_age', 'kid_birthy', 'kid_birthm', 'kid_int_y', 'kid_int_m', 
                     'BirthMonthsSince1900', 'IntMonthsSince1900', 
                     'month_mics6_to_history', 'year_mics6_to_history', 
                     'cld_month_mics6_to_history', 'mics6_to_history_y', 'mics6_to_history_m', 
                     'age_month_mics6_to_history', 'age_year_mics6_to_history', 
                     'age_month_mics6_to_prenatal', 'age_year_mics6_to_prenatal'
                     ]]

df_panel = df_panel.drop_duplicates()


# %% STEP 6. Output: MICS child X timing (month)

# Specify the path and filename for the CSV file and export DataFrame to CSV
dir_csv_file = f'{dir_data}/data_intermediate/child_lifecycle_skeleton_YZ.csv'
df_panel.to_csv(dir_csv_file, index=False)

# 316_MICS_child_mics6_to_history_month.csv


# Keep it light!!! 
df = df_panel[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 
                     'month_mics6_to_history', 
                     'cld_month_mics6_to_history', 
                     'age_month_mics6_to_history'
                     ]]

# Specify the path and filename for the CSV file and export DataFrame to CSV
dir_csv_file = f'{dir_data}/data_intermediate/YZ.csv'
df.to_csv(dir_csv_file, index=False)




# %%    
# Delete temporary variables from above loop  

# for var in list(locals()):
#     if var.startswith("cherry_"):
#         del locals()[var]

# del var 
# del row 
# del index





