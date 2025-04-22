# -*- coding: utf-8 -*-

'''
---------------------------------------------------
Project: PIRE 
Author: Yujie Zhang 
Date: 20230204
---------------------------------------------------

TASK: Create location history timing skeleton file 

Output: YZ_location_skeleton
    Row: location X timing 
    Column: location id, timing variable (CMC month, number of month from MICS6 into history, which should be 1~20*12 as we go back to 20 years ago)

DESCRIPTION 
-----------    
    This skeleton file is served for AC location disaster history file: AC_month_dis_A, AC_month_dis_B, AC_month_dis_C, AC_month_dis_D
    For different disaster intensity method, the AC file has different number of rows. Probably because only locations that ever have disasters are included in the file. 
    
    We want skeleton file for location X timing point from MICS6 into history, like the YZ file. We can get this from YZ file. 
    
    ### Algorithm to create AC location disaster history file: 
    1. Drop child id, leave only location id, timing variable (CMC month, number of month from MICS6 into history, which should be 1~20*12 as we go back to 20 years ago). 
    2. Duplicates drop. 
    3. Merge this with disaster X location X timing data. Use location id and CMC month. 
    4. Merge with disaster_intensity file where one row is one disaster, columns are disaster id and intensity score. Merge using disaster id. 
    5. Keep only follow column: 1) location id 2) CMC month 3) number of month from MICS6 to history 4) disaster intensity score 
    6. Fill in disaster intensity score missing value with 0. Note that for method A-D of creating disaster intensity score, they are all 0 or 1, which is clarified in #22.   
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

# bl_test = True
# it_test = 3
st_run_computer = "yz"
# verbose = True

# When you open this .py file, the working directory is "C:\Users\yzhan187", so change working directory to `program` and then import other short names you want for other directory.
if st_run_computer == "yz":
    dir_program = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\program\000_github\PrjRDSE"
elif st_run_computer == "fw":
    dir_program = r"C:\Users\fan\Documents\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\program\000_github\PrjRDSE"

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

df_YZ_child_lifecycle_skeleton = pd.read_csv(f'{dir_data}/data_intermediate/YZ_child_lifecycle_skeleton.csv')

df_mics_child_pa_hh = pd.read_csv(f'{dir_data}/data_to_est/240_mics_child_pa_hh.csv')

df_mics_child = pd.read_csv(f'{dir_data}/data_intermediate/230_mics_child.csv')
df_mics_pa_hh = pd.read_csv(f'{dir_data}/data_intermediate/234_mics_pa_hh.csv')
df_mics_sch_file2A = pd.read_csv(f'{dir_data}/data_intermediate/234_mics_sch_file2A.csv')


def convert_months_since_1900(months_since_1900):
    '''
    Parameters
    ----------
    months_since_1900 : float/integer 

    Returns
    -------
    If months_since_1990 is None, then `years` and `months` will also be None. 
    If months_since_1990 has value, then calculate the corresponding year and month. 
    
    Implemention
    ------------
    df[['year', 'month']] = df[timing_var].apply(convert_months_since_1900).apply(pd.Series)

    '''
    years, months = divmod(months_since_1900, 12)
    return years + 1900, months + 1

# %%
'''
*******************************************************************************

Create location history timing skeleton file 

*******************************************************************************

Output: YZ_location_skeleton
    Row: location X timing 
    Column: location id, timing variable (CMC month, number of month from MICS6 into history, which should be 1~20*12 as we go back to 20 years ago)
'''

df = df_YZ_child_lifecycle_skeleton 

# Check column name without opening data 
column_names = df.columns.tolist()
print(column_names)
# df = df[['RDSE_loc_id', 'month_mics6_to_history', 'cld_month_mics6_to_history']]
# df = df.drop_duplicates()

summary = df.groupby('RDSE_loc_id')['month_mics6_to_history'].agg(['sum', 'mean', 'count', 'max', 'min'])

summary1 = df['month_mics6_to_history'].agg(['mean', 'count', 'max', 'min'])
print(summary1)
summary2 = df['cld_month_mics6_to_history'].agg(['mean', 'count', 'max', 'min'])
print(summary2)



# =============================================================================
# monthCMC_max = 1444
# monthCMC = 1175
# [yr, mo] = convert_months_since_1900(monthCMC)
# summary2['y','m'] = convert_months_since_1900(summary2['min'])
# =============================================================================

monthCMC_max, monthCMC_min = df['cld_month_mics6_to_history'].agg(['max', 'min'])

df = df_mics_child_pa_hh
df = df[['RDSE_loc_id']]
df = df.drop_duplicates()
df['monthCMC_max'] = monthCMC_max
df['monthCMC_min'] = monthCMC_min


# %% STEP 3. Expand time of month to panel 

# 1. Array of Months in the Survey

# Number of months
df['ar_month'] = df['monthCMC_max'] - df['monthCMC_min'] + 1    

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
df_panel['cld_month_mics6_to_history'] = df_panel['monthCMC_max'] - df_panel['month_mics6_to_history'] + 1



# %% STEP 4. Simplify data file, keep necessary columns

# df_panel = df_panel.drop(['ar_month_1', 'ar_month_2', 'ar_month', 'ID'], axis=1)
# df_panel = df_panel.drop(['kid_age', 'kid_birthy', 'kid_birthm', 'kid_int_y', 'kid_int_m'], axis=1)
# df_panel = df_panel.drop(['kid_birthm_1forNaN', 'BirthMonthsSince1900', 'IntMonthsSince1900', ], axis=1)

df_panel = df_panel.drop_duplicates()

# Keep it light!!! 
id_loc = ['RDSE_loc_id']
id_vars = []

cld_month_mics6_to_history = ['cld_month_mics6_to_history']
month_mics6_to_history = ['month_mics6_to_history']

df_panel = df_panel[id_loc + id_vars + month_mics6_to_history + cld_month_mics6_to_history]

# Convert this into western calendar year and month (NOT NECESSARY, BUT FOR CONVENIENCE)
timing_var = 'cld_month_mics6_to_history'
df_panel[['year', 'month']] = df_panel[timing_var].apply(convert_months_since_1900).apply(pd.Series)


# %% STEP 5. Output: MICS child X timing (month)

# Specify the path and filename for the CSV file and export DataFrame to CSV
dir_csv_file = f'{dir_data}/data_intermediate/YZ_loc_skeleton.csv'
df_panel.to_csv(dir_csv_file, index=False)






# %% Browse and double check 

df = df_panel
column_names = df.columns.tolist()
print(column_names)
# df = df[['RDSE_loc_id', 'month_mics6_to_history', 'cld_month_mics6_to_history']]
# df = df.drop_duplicates()

summary = df.groupby('RDSE_loc_id')['month_mics6_to_history'].agg(['count', 'max', 'min'])

summary1 = df['month_mics6_to_history'].agg(['mean', 'count', 'max', 'min'])
print(summary1)
summary2 = df[['cld_month_mics6_to_history', 'year', 'month']].agg(['mean', 'count', 'max', 'min'])
print(summary2)


# %%    
# Delete temporary variables from above loop  

# for var in list(locals()):
#     if var.startswith("cherry_"):
#         del locals()[var]

# del var 
# del row 
# del index





