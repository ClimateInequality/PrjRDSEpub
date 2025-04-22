# -*- coding: utf-8 -*-

'''
---------------------------------------------------
Project: PIRE 
Author: Yujie Zhang 
Date: 20230204
---------------------------------------------------

TASK: https://github.com/ClimateInequality/PrjRDSE/issues/7

Create data file for MICS child lifecycle timing file -  MICS_child_negative_lifecycle_skeleton. 
    Row: MICS child X timing 
    Column: (1) location id (2) MICS child id (3) lifecycle calendar month (or year, depending on which timing level we use) (4) the age expressed by monthly or yearly corresponding to that calendar month (5) birth year and month (6) interview year and month 
    Note: Column (1)-(4) are essential, others are optional as the informaiton will be duplicated.   


https://github.com/ClimateInequality/PrjRDSE/issues/23

Output: YZ file. 
This file will be used to generate child lifecycle-specific and location-date-specific disaster history.

    Row: child X month 
        Number of rows for each child, regardless of age, generate (if looking back M years for AC exercise): max(age+1, M)*12    
    Column: 
        (1) location id (2) child id 
        (3) calendar month (CMC-1900) 
        (4) number of month from now - MICS6 interview month - to history 
        (5) child age in that month - this should go from now - MICS6 interview month - to history 

WARNING
-------
This script is advanced version of 316_disaster_RDSEloc_mics_child.py, which generates above files with timing being year, month, etc. But we do not need year if we have month.       
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
-------------------------------------------------------------------------------
'''

bl_test = True
it_test = 3
st_run_computer = "yz"
verbose = True

# When you open this .py file, the working directory is "C:\Users\yzhan187", so change working directory to `program` and then import other short names you want for other directory.
if st_run_computer == "yz":
    dir_program = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\program\000_github\PrjRDSE"
elif st_run_computer == "fw":
    dir_program = r"C:\Users\fan\Documents\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\program\000_github\PrjRDSE"
elif st_run_computer == "yz_49D":
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

df_240_mics_child_pa_hh = pd.read_csv(f'{dir_data}/data_to_est/240_mics_child_pa_hh.csv')

# To test code, take only first {it_sample} rows. 
if bl_test is True: 
    if it_test == 1:
        it_sample = 100
    elif it_test == 2:
        it_sample = 1600
    elif it_test == 3:
        it_sample = 16000
        
    df = df_240_mics_child_pa_hh.head(it_sample)
    dir_csv_file = f'{dir_data}/data_intermediate/YZ_simple_{it_sample}.csv'
    
else:
    df = df_240_mics_child_pa_hh
    dir_csv_file = f'{dir_data}/data_intermediate/YZ_child_lifecycle_skeleton_{st_run_computer}.csv'

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

    '''
    years, months = divmod(months_since_1900, 12)
    return years + 1900, months + 1



# %% 
'''
*******************************************************************************

MODULE 6. Create MICS_child_negative_lifecycle_skeleton file: YZ file

*******************************************************************************
'''

# STEP 1. file input 

df = df[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'kid_age', 'kid_birthy', 'kid_birthm', 'kid_int_y', 'kid_int_m']]

# Set up M years of location history 
N = 20



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

# 4. Age point in month 
'''
Two cases: 
    (1) prenatal month < history month, i.e. (age+1)*12 < N*12, ar_month_1 < ar_month_2. 
    
    For example, child Anna is age 6, born in 2012 Sept, interviewed in 2019 May, then her BirthMonthsSince1900 = 1352, IntMonthsSince1900 = 1432, ar_month_1 = 91, ar_month_2 = 121 if we want to track back to 10 years ago. Then ar_month for Anna will be 121, as we track back to 10 years ago for the place Anna is living in, although Anna only lives there for 6 years. The age_month_prenatal_to_mics6 is the monthly age point of her lifecycle, 80, 79, 78, ..., 0, -1, ..., -10 (conception), -11, -12, ..., -30, -40. 
    Anna cannot be living -40 months before her birth. We can replace the unreasonalble months into None. 
    
    (2) prenatal month > history month, i.e. (age+1)*12 > N*12, ar_month_1 > ar_month_2.
'''

df_panel['age_month_mics6_to_history'] = df_panel['cld_month_mics6_to_history'] - df_panel['BirthMonthsSince1900']

# df_panel['age_month_mics6_to_prenatal'] = df_panel['age_month_mics6_to_history'].apply(lambda x: None if x < -10 else x)



# %% STEP 4. Simplify data file, keep necessary columns

# df_panel = df_panel.drop(['ar_month_1', 'ar_month_2', 'ar_month', 'ID'], axis=1)
# df_panel = df_panel.drop(['kid_age', 'kid_birthy', 'kid_birthm', 'kid_int_y', 'kid_int_m'], axis=1)
# df_panel = df_panel.drop(['kid_birthm_1forNaN', 'BirthMonthsSince1900', 'IntMonthsSince1900', ], axis=1)

df_panel = df_panel.drop_duplicates()

# Keep it light!!! 
id_loc = ['RDSE_loc_id']
id_vars = ['countryfile', 'HH1', 'HH2', 'LN']

cld_month_mics6_to_history = ['cld_month_mics6_to_history']
month_mics6_to_history = ['month_mics6_to_history']
age_mics6_to_history = ['age_month_mics6_to_history']

df_panel = df_panel[id_loc + id_vars + month_mics6_to_history + cld_month_mics6_to_history + age_mics6_to_history]



# %% STEP 5. Output: MICS child X timing (month)

# Specify the path and filename for the CSV file and export DataFrame to CSV
# dir_csv_file = f'{dir_data}/data_intermediate/YZ_child_lifecycle_skeleton.csv'
df_panel.to_csv(dir_csv_file, index=False)



# %%    
# Delete temporary variables from above loop  

# for var in list(locals()):
#     if var.startswith("cherry_"):
#         del locals()[var]

# del var 
# del row 
# del index





