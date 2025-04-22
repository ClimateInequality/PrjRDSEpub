# -*- coding: utf-8 -*-
"""
/* 
Project: PIRE 
Author: Yujie Zhang 
Date: 20230204
*/
"""

# %% Clear all variables and data frames from the current workspace

for var in list(globals()):
    if not var.startswith("__"):
        del globals()[var]

for var in list(locals()):
    if not var.startswith("__"):
        del locals()[var]

# %% Install packages by typing the below in system terminal. Import modules

# pip3 install pandas
# pip install pandasgui
# from pandasgui import show
# show(df)

# import os
import pandas as pd
# import numpy as np
# import math
# import matplotlib.pyplot as plt
# import seaborn as sns

# Remove normal warnings
import warnings
warnings.simplefilter('ignore')

# %% Import locals, such as directory 

# When you open this .py file, the working directory is "C:\Users\yzhan187", so change working directory to `program` and then import other short names you want for other directory.

import os 

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

# =============================================================================
# TASK: https://github.com/ClimateInequality/PrjRDSE/issues/18
# Unify the date for Nepal and Thailand, date of birth and interview date. 

# This script is only for Nepal. 
# Input: data file for MICS child in Nepal
# Column - child id; child birth year, month; interview year, month, day; mother birth year, month; father birth year, month; All dates are in Nepal calendar. It is okay that variables are not completely raw data, as we changed "missing value" labeled as 9999 (or similar numbers) into real missing values. 

# Output: NPL child all date variable data 
# Row - each child 
# Column - child id; child birth year, month; interview year, month, day; mother birth year, month; father birth year, month; All dates should be in western calendar. 
# =============================================================================

# %% 
# =============================================================================

#  MODULE 1. Import dataset and define function 

# =============================================================================

df_230_mics_child = pd.read_csv(f'{dir_data}/data_intermediate/230_mics_child.csv')
df_234_mics_pa_hh = pd.read_csv(f'{dir_data}/data_intermediate/234_mics_pa_hh.csv')
df_234_mics_sch_file2A = pd.read_csv(f'{dir_data}/data_intermediate/234_mics_sch_file2A.csv')

# Keep necessary column 
# df1 = df_230_mics_child[['countryfile', 'HH1', 'HH2', 'LN', 'ISO_alpha_3', 'kid_age_raw', 'kid_birthdate_raw', 'kid_birthm', 'kid_birthy']] 
# df2 = df_234_mics_pa_hh[['countryfile', 'HH1', 'HH2', 'LN', 'mo_birthy', 'mo_birthm', 'mo_age', 'fa_birthy', 'fa_birthm', 'fa_age']] 
# df3 = df_234_mics_sch_file2A[['countryfile', 'HH1', 'HH2', 'LN', 'kid_int_y', 'kid_int_m', 'kid_int_d']] 
df1 = df_230_mics_child[['countryfile', 'HH1', 'HH2', 'LN', 'ISO_alpha_3', 'kid_birthm', 'kid_birthy']] 
df2 = df_234_mics_pa_hh[['countryfile', 'HH1', 'HH2', 'LN', 'mo_birthy', 'mo_birthm', 'fa_birthy', 'fa_birthm']] 
df3 = df_234_mics_sch_file2A[['countryfile', 'HH1', 'HH2', 'LN', 'kid_int_y', 'kid_int_m', 'kid_int_d']] 

# Merge the first dataset with the second dataset
df = df1.merge(df2, on=['countryfile', 'HH1', 'HH2', 'LN'], how='inner').merge(df3, on=['countryfile', 'HH1', 'HH2', 'LN'], how='inner')

del df1, df2, df3

# Only work on Nepal, DO NOT COMPLICATE THINGS!
df = df[df['ISO_alpha_3'] == 'NPL']
# df = df_NPL[['countryfile', 'HH1', 'HH2', 'LN', 'ISO_alpha_3', 'kid_age_raw', 'kid_birthm', 'kid_birthy', 'kid_int_y', 'kid_int_m', 'kid_int_d']]


# %% 
# =============================================================================

#  MODULE 2. Translate the date for NPL 

# =============================================================================

'''
# Convert NPL calendar to Western calendar. 
# https://github.com/amitgaru2/nepali-datetime
# https://pypi.org/project/nepali-datetime/
'''
# pip install nepali-datetime
# import datetime
import nepali_datetime

# =============================================================================

#  MODULE 2.0 Tryout area 

# =============================================================================

# =============================================================================
# pip install nepali-converter
# from nepali_converter import bs_to_ad

# dt = datetime.date(2018, 11, 7)
# nepali_datetime.date.from_datetime_date(dt)
# dt = datetime.date(df['kid_birthy'], df['kid_birthm'], df['kid_birthd'])
# 
# heyheyhey = nepali_datetime.date(1999, 7, 25).to_datetime_date()
# 
# # Sample DataFrame
# data = {'kid_birthd': ['2022-01-15', '2019-04-10', '2020-08-25']}
# df = pd.DataFrame(data)
# 
# # Define a function to extract the year from 'kid_birthd'
# def extract_year(row):
#     birthdate = row['kid_birthd']
#     year = pd.to_datetime(birthdate).year
#     return year
# 
# # Apply the function to each row
# df['birth_year'] = df.apply(extract_year, axis=1)
# 
# # The resulting DataFrame will have a new column 'birth_year' containing the birth year
# print(df)

# def convert_to_western(row):
#     if row['kid_birthy'] == 9999 or row['kid_birthm'] == 99: 
#             return pd.Series({'year_western': None, 'month_western': None, 'day_western': None})
#     else: 
#         western_date = nepali_datetime.date(row['kid_birthy'], row['kid_birthm'], row['kid_birthd']).to_datetime_date()
#         year_western = pd.to_datetime(western_date).year 
#         month_western = pd.to_datetime(western_date).month 
#         day_western = pd.to_datetime(western_date).day 
#         return pd.Series({'year_western': year_western, 'month_western': month_western, 'day_western': day_western})
# =============================================================================



def convert_to_western(row, year_col, month_col, day_col):
    if row[year_col] == 9999 or row[month_col] == 99 or row[day_col] == 99: 
        return pd.Series({'year_western': None, 'month_western': None, 'day_western': None})
    else: 
        western_date = nepali_datetime.date(row[year_col], row[month_col], row[day_col]).to_datetime_date()
        year_western = pd.to_datetime(western_date).year 
        month_western = pd.to_datetime(western_date).month 
        day_western = pd.to_datetime(western_date).day 
        return pd.Series({'year_western': year_western, 'month_western': month_western, 'day_western': day_western})

# =============================================================================
# MODULE 2.1. MICS child birth date 
# =============================================================================

df['kid_birthy'] = df['kid_birthy'].fillna(9999)        # To use nepali_datetime, ('year must be in 1975..2100', 9999), 9999 value cannot work for nepali_datetime.date
df['kid_birthm'] = df['kid_birthm'].fillna(99)          # ('month must be in 1..12', 99)
# Assume all children birth day is the first day of birth month
df['kid_birthd'] = 1

df['kid_birthy'] = df['kid_birthy'].astype(int)
df['kid_birthm'] = df['kid_birthm'].astype(int)
df['kid_birthd'] = df['kid_birthd'].astype(int)

# Apply the function to birth year, month, and day to obtain birth year, month, and day in Western calendar. Generate three columns. 
df[['kid_birthy_AD', 'kid_birthm_AD', 'kid_birthd_AD']] = df.apply(convert_to_western, axis=1, args=('kid_birthy', 'kid_birthm', 'kid_birthd'))

# Check missing values 
rows_with_missing_values = df[df['kid_birthy_AD'].isna()]

# %%
# =============================================================================
# MODULE 2.2. MICS child interview date
# =============================================================================

# There is no missing value for interview year, month, and day. So apply function directly. 
df[['kid_int_y_AD', 'kid_int_m_AD', 'kid_int_d_AD']] = df.apply(convert_to_western, axis=1, args=('kid_int_y', 'kid_int_m', 'kid_int_d'))

# %%
# =============================================================================
# MODULE 2.3. MICS mother birth date 
# =============================================================================

df['mo_birthy'] = df['mo_birthy'].fillna(9999)       
df['mo_birthm'] = df['mo_birthm'].fillna(99)          
df['mo_birthd'] = 1

df['mo_birthy'] = df['mo_birthy'].astype(int)
df['mo_birthm'] = df['mo_birthm'].astype(int)
df['mo_birthd'] = df['mo_birthd'].astype(int)

# Apply the function to birth year, month, and day to obtain birth year, month, and day in Western calendar. Generate three columns. 
df[['mo_birthy_AD', 'mo_birthm_AD', 'mo_birthd_AD']] = df.apply(convert_to_western, axis=1, args=('mo_birthy', 'mo_birthm', 'mo_birthd'))

# Check missing values 
rows_with_missing_values = df[df['mo_birthy_AD'].isna()]

# %%
# =============================================================================
# MODULE 2.4. MICS father birth date 
# =============================================================================

df['fa_birthy'] = df['fa_birthy'].fillna(9999)       
df['fa_birthm'] = df['fa_birthm'].fillna(99)         
df['fa_birthd'] = 1

df['fa_birthy'] = df['fa_birthy'].astype(int)
df['fa_birthm'] = df['fa_birthm'].astype(int)
df['fa_birthd'] = df['fa_birthd'].astype(int)

# Apply the function to birth year, month, and day to obtain birth year, month, and day in Western calendar. Generate three columns. 
df[['fa_birthy_AD', 'fa_birthm_AD', 'fa_birthd_AD']] = df.apply(convert_to_western, axis=1, args=('fa_birthy', 'fa_birthm', 'fa_birthd'))

# Check missing values 
# rows_with_missing_values = df[df['fa_birthy_AD'].isna()]



# %% 
# =============================================================================

#  MODULE 3. Keep necessary columns and output data 

# =============================================================================
# Output: NPL child all date variable data 
# Row - each child 
# Column - child id; child birth year, month; interview year, month, day; mother birth year, month; father birth year, month
# =============================================================================

# Drop the "fake" birth day columns 
df.drop(columns=['kid_birthy', 'kid_birthm', 'kid_birthd'], inplace=True)
df.drop(columns=['kid_int_y', 'kid_int_m', 'kid_int_d'], inplace=True)
df.drop(columns=['mo_birthy', 'mo_birthm', 'mo_birthd'], inplace=True)
df.drop(columns=['fa_birthy', 'fa_birthm', 'fa_birthd'], inplace=True)

df.drop(columns=['kid_birthd_AD', 'mo_birthd_AD', 'fa_birthd_AD'], inplace=True)

df.drop(columns=['ISO_alpha_3'], inplace=True)

# Remove the '_AD' suffix from all column names
# df.rename(columns={'kid_birthy_AD': 'kid_birthy'}, inplace=True)
df.columns = [col.rstrip('_AD') for col in df.columns]


# Specify the path and filename for the CSV file
dir_csv_file = f'{dir_tempdata}/241_mics_child_date_NPL.csv'

# Export the DataFrame to CSV
df.to_csv(dir_csv_file, index=False)

# =============================================================================
# merged_df = df_A.merge(df_B, on='id', suffixes=('', '_to_drop'))
# # In this case, columns from DataFrame B with the same name as columns in DataFrame A will be retained, and columns from DataFrame B will have the "_to_drop" suffix to indicate that they can be safely dropped.
# 
# df = df[[col for col in df.columns if not col.endswith('_to_drop')]]
# =============================================================================



# %%    
# Delete temporary variables from above loop  

# for var in list(locals()):
#     if var.startswith("cherry_"):
#         del locals()[var]

# del var 
# del row 
# del index




