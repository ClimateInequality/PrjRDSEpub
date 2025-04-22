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
    
WARNING
--------------
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

df_315_disaster_RDSEloc = pd.read_csv(f'{dir_data}/data_intermediate/315_disaster_RDSEloc.csv')
df_314_disaster_info = pd.read_csv(f'{dir_data}/data_intermediate/314_disaster_info.csv')

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
dir_csv_file = f'{dir_data}/data_intermediate/disaster_RDSEloc_month.csv'
df_panel.to_csv(dir_csv_file, index=False)




# %%    
# Delete temporary variables from above loop  

# for var in list(locals()):
#     if var.startswith("cherry_"):
#         del locals()[var]

# del var 
# del row 
# del index





