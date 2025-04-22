# -*- coding: utf-8 -*-

'''
---------------------------------------------------
Project: PIRE 
Author: Yujie Zhang 
Date: 20230204
---------------------------------------------------

TASK: https://github.com/ClimateInequality/PrjRDSE/issues/23

WARNING:
-----------
    This is a simple version of file "Child Lifecycle-specific and Location-Date-specific Disaster Histories". Only consider: 
        # If one child has experienced disaster in last 12 months
        # If one child has experienced disaster in this interview month and last 1 month
        
    For advanced and systematic construction, move to 323_child_lifecycle_loc_date_dis_his.py.

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

'''
Import dataset and define function 
-----------------------------------------------------------
'''

df_316_disaster_RDSEloc_month = pd.read_csv(f'{dir_data}/data_intermediate/316_disaster_RDSEloc_month.csv')
# This file should include RDSE location, month in disaster (month difference between current month and 1900 January), and corresponding Western calendar year and month. 

df_316_disaster_RDSEloc_year = pd.read_csv(f'{dir_data}/data_intermediate/316_disaster_RDSEloc_year.csv')

df_316_MICS_child_prenatal_to_mics6_month = pd.read_csv(f'{dir_data}/data_intermediate/316_MICS_child_prenatal_to_mics6_month.csv')

df_316_MICS_child_prenatal_to_mics6_year = pd.read_csv(f'{dir_data}/data_intermediate/316_MICS_child_prenatal_to_mics6_year.csv')

df_316_MICS_child_month_int_cover = pd.read_csv(f'{dir_data}/data_intermediate/316_MICS_child_month_int_cover.csv')

df_317_AC_month_dis_exist_alltype = pd.read_csv(f'{dir_data}/data_intermediate/317_AC_month_dis_exist_alltype.csv')

df_240_mics_child_pa_hh = pd.read_csv(f'{dir_data}/data_to_est/240_mics_child_pa_hh.csv')



# %% 
'''
*******************************************************************************

MODULE 1. 

*******************************************************************************
'''

# Reshape AC file into location X month jointly defined disaster history file.

df = df_317_AC_month_dis_exist_alltype 
df = pd.melt(df, id_vars=['RDSE_loc_affect'], var_name='cld_month', value_name='dis_exist')
df = df.sort_values(by='RDSE_loc_affect')
df = df.reset_index(drop=True) # Reset the index after sorting
df1 = df

# Merge with child X month (covered by MICS6 interview, which is essentially the last 12 months before interview). 

df1['cld_month'] = pd.to_numeric(df1['cld_month'], errors='coerce')
print(df1['cld_month'].dtype) # int64

df = pd.merge(df_316_MICS_child_month_int_cover, df1, left_on=['RDSE_loc_id', 'cld_month_int_cover'], right_on=['RDSE_loc_affect', 'cld_month'], how='left')

df = df.sort_values(by=['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'cld_month_int_cover'], 
                    ascending=[True, True, True, True, True, False])
df = df[['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'ISO_alpha_3', 'kid_int_y', 'kid_int_m', 'cld_month_int_cover', 'dis_exist']]
df['dis_exist'].fillna(0, inplace=True)

df2 = df

# If one child has experienced disaster in last 12 months

df['maxnum'] = df.groupby(['countryfile', 'HH1', 'HH2', 'LN'])['dis_exist'].transform('max')
df = df.sort_values(by=['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'cld_month_int_cover'], 
                    ascending=[True, True, True, True, True, False])
df = df.drop_duplicates(subset=['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN'], keep='first')
df = df[['countryfile', 'HH1', 'HH2', 'LN', 'maxnum']]

df.rename(columns={'maxnum': 'exp_dis_last_12m'}, inplace=True)

df = pd.merge(df, df_240_mics_child_pa_hh, on=['countryfile', 'HH1', 'HH2', 'LN'], how='right')
df_mics_child_pa_hh_exp_dis_last_12m = df

# If one child has experienced disaster in this interview month and last 1 month

df = df2
df = df.groupby(['countryfile', 'HH1', 'HH2', 'LN']).head(2)
df['maxnum'] = df.groupby(['countryfile', 'HH1', 'HH2', 'LN'])['dis_exist'].transform('max')
df = df.sort_values(by=['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'cld_month_int_cover'], 
                    ascending=[True, True, True, True, True, False])
df = df.drop_duplicates(subset=['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN'], keep='first')
df = df[['countryfile', 'HH1', 'HH2', 'LN', 'maxnum']]

df.rename(columns={'maxnum': 'exp_dis_last_2m'}, inplace=True)



df = pd.merge(df, df_mics_child_pa_hh_exp_dis_last_12m, on=['countryfile', 'HH1', 'HH2', 'LN'], how='right')
df_mics_child_pa_hh_exp_dis = df

df_simple = df[['countryfile', 'HH1', 'HH2', 'LN', 'exp_dis_last_2m', 'exp_dis_last_12m']]

# Specify the path and filename for the CSV file and export the DataFrame to CSV
dir_csv_file = f'{dir_data}/data_to_est/mics_child_pa_hh_exp_dis.csv'
df.to_csv(dir_csv_file, index=False)

dir_csv_file = f'{dir_data}/data_to_est/mics_exp_dis.csv'
df_simple.to_csv(dir_csv_file, index=False)
    
# %% 
# Delete temporary variables from above loop  

# for var in list(locals()):
#     if var.startswith("cherry_"):
#         del locals()[var]

# del var 
# del row 
# del index




