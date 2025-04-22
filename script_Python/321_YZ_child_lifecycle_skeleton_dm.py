# -*- coding: utf-8 -*-

'''
---------------------------------------------------
Project: PIRE 
Author: Yujie Zhang 
Date: 20230204
---------------------------------------------------

TASK: Add dummy for YZ child skeleton file. 

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
# from datetime import datetime
import pickle

# Remove normal warnings
import warnings
warnings.simplefilter('ignore')

'''
Import locals, such as directory
-------------------------------------------------------------------------------
'''
bl_test = False
it_test = 3
st_run_computer = "yz"

verbose = True

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

# df_disaster_info = pd.read_csv(f'{dir_data}/data_intermediate/disaster_info.csv')
# df_disaster_RDSEloc_month = pd.read_csv(f'{dir_data}/data_intermediate/disaster_RDSEloc_month.csv')
# This file should include RDSE location, month in disaster (month difference between current month and 1900 January), and corresponding Western calendar year and month. 

# df_YZ_child_lifecycle_skeleton = pd.read_csv(f'{dir_data}/data_intermediate/YZ_child_lifecycle_skeleton.csv')
df_file_A = pd.read_csv(f'{dir_data}/id_key_file/file_A.csv')

# Set up location id and timing variable in data files 
location_id_in_skeleton='RDSE_loc_id'
timing_var_in_skeleton='cld_month_mics6_to_history'

location_id='RDSE_loc_affect'
timing_var='cld_month_in_dis'

id_vars = ['countryfile', 'HH1', 'HH2', 'LN']

# Use disaster id X location X timing file, then add column of intensity score. 
# This file will be updated by adding more columns, each column is one intensity type. 
# df_disaster_RDSEloc_month_add_intensity = df_disaster_RDSEloc_month[['DisNo', 'RDSE_loc_affect', 'cld_month_in_dis']]

# Child lifecycle skeleton file 
if bl_test is True: 
    if it_test == 1:
        it_sample = 100
    elif it_test == 2:
        it_sample = 1600
    elif it_test == 3:
        it_sample = 16000

    df_YZ_child_lifecycle_skeleton = pd.read_csv(f'{dir_data}/data_intermediate/YZ_simple_{it_sample}.csv')
    dir_csv_file = f'{dir_tempdata}/YZ_child_lifecycle_skeleton_dm_n{it_sample}_{st_run_computer}.csv'
    
else:
    df_YZ_child_lifecycle_skeleton = pd.read_csv(f'{dir_data}/data_intermediate/YZ_child_lifecycle_skeleton.csv')
    dir_csv_file = f'{dir_tempdata}/YZ_child_lifecycle_skeleton_dm_{st_run_computer}.csv'


# =============================================================================
# This is too slow, should not use this, but just use operation in Pandas. 
# df['cld_year'] = df['cld_month_mics6_to_history'] // 1900  # Column B is the integer division of A by 1900
# df['cld_month'] = df['cld_month_mics6_to_history'] % 1900 + 1
# 
# def convert_months_since_1900(months_since_1900):
#     '''
#     Parameters
#     ----------
#     months_since_1900 : float/integer 
# 
#     Returns
#     -------
#     If months_since_1990 is None, then `years` and `months` will also be None. 
#     If months_since_1990 has value, then calculate the corresponding year and month. 
#     
#     Implement
#     ---------
#     df[['year', 'month']] = df[timing_var].apply(convert_months_since_1900).apply(pd.Series)
#     '''
#     years, months = divmod(months_since_1900, 12)
#     return years + 1900, months + 1
# =============================================================================





# %% 
'''
*******************************************************************************

Modify skeleton file and generate other columns 

*******************************************************************************
'''
# df = merged_df

# df.drop(columns=['month_mics6_to_history'], inplace=True)

# df = df_YZ_child_lifecycle_skeleton.copy()

df = df_YZ_child_lifecycle_skeleton

age_month = 'age_month_mics6_to_history'
cld_month = 'cld_month_mics6_to_history'
number_of_month = 'month_mics6_to_history'


# Obtain country name
# -------------------------------------
# We can also obtain more geo-info from file_A including regional name 
df1 = df_file_A[['RDSE_loc_id', 'ISO_alpha_3']]
df1 = df1.drop_duplicates()
df = pd.merge(df, df1, left_on=location_id_in_skeleton, right_on=['RDSE_loc_id'], how='left') 


# =============================================================================
# B='dm_age_bf_33m'
# month_age_or_history='age_month_mics6_to_history'
# 
# # Generate categorical variable. 
# df[B] = df.groupby((0 <= df[month_age_or_history]) & (df[month_age_or_history] <= 33))[month_age_or_history].transform('count')
# df[B] = (df[B] > 0).astype(int)
# 
# # This one line is the same as above two lines. 
# df[B] = df.groupby((0 <= df[month_age_or_history]) & (df[month_age_or_history] <= 33))[month_age_or_history].transform('count').gt(0).astype(int)
# 
# summary = df[B].describe()
# =============================================================================

# =============================================================================
# Dummy for critical age or period 
# =============================================================================

def date_or_age_category(df, month_age_or_history, start_month, end_month, B):
    
    # Generate date_or_age_category
    df[B] = df.groupby((start_month <= df[month_age_or_history]) & (df[month_age_or_history] <= end_month))[month_age_or_history].transform('count').gt(0).astype(int)

    return df

# Dummy for critical age period: first 1000 days of life 
# --------------------------------------------------------------
df = date_or_age_category(df, start_month=0, end_month=33, month_age_or_history=age_month, B='dm_age_bf_33m')

# Dummy for critical age period: first 1000 days of life 
# --------------------------------------------------------------
df = date_or_age_category(df, start_month=-10, end_month=-1, month_age_or_history=age_month, B='dm_age_bf_0')


# Dummy for critical age period: at school starting age, 6 years old
# ---------------------------------------------------------------------------
df = date_or_age_category(df, start_month=5*12, end_month=6*12, month_age_or_history=age_month, B='dm_age_at_5or6')

# Dummy for critical age period: at school ending age, 13 years old
# ---------------------------------------------------------------------------
df = date_or_age_category(df, start_month=13*12, end_month=14*12, month_age_or_history=age_month, B='dm_age_at_13or14')



# Dummy for most recent month 
# -------------------------------------
df = date_or_age_category(df, start_month=1, end_month=2, month_age_or_history=number_of_month, B='dm_date_in_past_1m')

# Dummy for most recent year 
# -------------------------------------
df = date_or_age_category(df, start_month=1, end_month=12, month_age_or_history=number_of_month, B='dm_date_in_past_12m')

# Dummy for most recent 12m to 10 years
# ------------------------------------------
df = date_or_age_category(df, start_month=12, end_month=12*10, month_age_or_history=number_of_month, B='dm_date_in_12m_ago_to_10y')



# Generate calendar year and month
# --------------------------------------
df['cld_year'] = df[cld_month] // 1900  # Column B is the integer division of A by 1900
df['cld_month'] = df[cld_month] % 1900 + 1

# Generate age in year, age in month 
# -------------------------------------
df.rename(columns={age_month: 'age_month'}, inplace=True)
df['age_year'] = df['age_month'] // 12



# =============================================================================
# THIS IS FROM 323_child_lifecycle_loc_date_dis_his.py
# 
# 
# # date_in_past_12m
# df = date_or_age_category_exist_share(df, id_vars, start_month=1, end_month=12, month_age_or_history='month_mics6_to_history', A='dis_exist', B='date_in_past_12m', C='dis_exist_bi_in_past_12m', D='dis_exist_fl_in_past_12m')
# 
# # date_in_12m_ago_to_10y
# df = date_or_age_category_exist_share(df, id_vars, start_month=12, end_month=12*10, month_age_or_history='month_mics6_to_history', A='dis_exist', B='date_in_12m_ago_to_10y', C='dis_exist_bi_in_12m_ago_to_10y', D='dis_exist_fl_in_12m_ago_to_10y')
# 
# # age_bf_33m: Before 33 months, IN first 1000 days 
# df = date_or_age_category_exist_share(df, id_vars, start_month=0, end_month=33, month_age_or_history='age_month_mics6_to_history', A='dis_exist',  B='age_bf_33m', C='dis_exist_bi_age_bf_33m', D='dis_exist_cts_age_bf_33m')
# 
# #  age_bf_0: BEFORE birth, IN prenatal period
# df = date_or_age_category_exist_share(df, id_vars, start_month=-10, end_month=-1, month_age_or_history='age_month_mics6_to_history', A='dis_exist', B='age_bf_0', C='dis_exist_bi_age_bf_0', D='dis_exist_cts_age_bf_0')
#     
# =============================================================================


# %% 



# Specify the path and filename for CSV file and export DataFrame to CSV
# -----------------------------------------------------------------------------
# dir_csv_file = f'{dir_data}/data_to_est/JE_month_dis_intensity.csv'
df.to_csv(dir_csv_file, index=False)




# =============================================================================
# del df1, df_file_A, df_YZ_child_lifecycle_skeleton
# 
# # Specify the filename for the pickle file
# # filename = 'data.pkl'
# filename = os.path.abspath('data.pkl')
# 
# # Load the DataFrame from the pickle file in script B
# with open(filename, 'rb') as file:
#     loaded_df = pickle.load(file)
# =============================================================================

    
# %%    
# Delete temporary variables from above loop  

# for var in list(locals()):
#     if var.startswith("cherry_"):
#         del locals()[var]

# del var 
# del row 
# del index




