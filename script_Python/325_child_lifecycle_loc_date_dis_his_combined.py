# -*- coding: utf-8 -*-

'''
---------------------------------------------------
Project: PIRE 
Author: Yujie Zhang 
Date: 20230204
---------------------------------------------------

TASK: https://github.com/ClimateInequality/PrjRDSE/issues/23
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

# Remove normal warnings
import warnings
warnings.simplefilter('ignore')

'''
Import locals, such as directory
-------------------------------------------------------------------------------
'''

bl_test = False
it_test = 1 
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
-----------------------------------------------------------
'''

df_AC = {}
for dis_intensity_type in ['A', 'B', 'C', 'D']:
    name_file = f'{dir_data}/data_to_est/AC_month_dis_intensity_{dis_intensity_type}.csv'
    name_df = f'AC_month_dis_intensity_{dis_intensity_type}'
    df_AC[name_df] = pd.read_csv(name_file)

df_child_lifecycle_loc_date = {}
for dis_intensity_type in ['A', 'B', 'C', 'D']:
    name_file = f'{dir_data}/data_to_est/child_lifecycle_loc_date_{dis_intensity_type}_full_{st_run_computer}.csv'
    name_df = f'child_lifecycle_loc_date_{dis_intensity_type}'
    df_child_lifecycle_loc_date[name_df] = pd.read_csv(name_file)
    
df_child_lifecycle_loc_date_Add_More = {}
for dis_intensity_type in ['A', 'B', 'C', 'D']:
    name_file = f'{dir_data}/data_to_est/child_lifecycle_loc_date_{dis_intensity_type}_full_{st_run_computer}_Add_More.csv'
    name_df = f'child_lifecycle_loc_date_{dis_intensity_type}'
    df_child_lifecycle_loc_date_Add_More[name_df] = pd.read_csv(name_file)
    
df_mics_child_id = pd.read_csv(f'{dir_data}/id_key_file/mics_child_id.csv')


# Child lifecycle skeleton file 
if bl_test is True: 
    if it_test == 1:
        it_sample = 100
    elif it_test == 2:
        it_sample = 1600
    elif it_test == 3:
        it_sample = 16000

    df_YZ = pd.read_csv(f'{dir_data}/data_intermediate/YZ_simple_{it_sample}.csv')
    dir_csv_file = f'{dir_data}/data_to_est/child_lifecycle_loc_date_{dis_intensity_type}_n{it_sample}_{st_run_computer}.csv'
    
else:
    df_YZ = pd.read_csv(f'{dir_data}/data_intermediate/YZ_child_lifecycle_skeleton.csv')
    dir_csv_file = f'{dir_data}/data_to_est/child_lifecycle_loc_date_{dis_intensity_type}_full_{st_run_computer}.csv'



# df_240_mics_child_pa_hh = pd.read_csv(f'{dir_data}/data_to_est/240_mics_child_pa_hh.csv')



# %% 
'''
*******************************************************************************

MODULE 1. Merging 

*******************************************************************************
'''

# =============================================================================
# # 1. Obtain file on location X month disaster history. 
# # Reshape AC file from wide to long. Each row is location X month. We already have that, 317_AC_month_dis_exist_alltype is supposed in this format, wide data file. 
# df = pd.melt(df_AC_month_dis, id_vars=['RDSE_loc_affect'], var_name='cld_month', value_name='dis_exist')
# df1 = df.sort_values(by='RDSE_loc_affect').reset_index(drop=True) # Reset the index after sorting
# 
# # 2. Merge with child X month skeleton file (YZ file). 
# df1['cld_month'] = pd.to_numeric(df1['cld_month'], errors='coerce')
# print(df1['cld_month'].dtype) # int64
# =============================================================================




# 1. Obtain file on location X month disaster history

# 2. Merge with child X month skeleton file (YZ file) 

df = pd.merge(df_child_lifecycle_loc_date['child_lifecycle_loc_date_A'], df_child_lifecycle_loc_date['child_lifecycle_loc_date_B'], on=['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'moLN', 'faLN', 'ISO_alpha_3'], how='left')

df = pd.merge(df, df_child_lifecycle_loc_date['child_lifecycle_loc_date_C'], on=['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'moLN', 'faLN', 'ISO_alpha_3'], how='left')

df = pd.merge(df, df_child_lifecycle_loc_date['child_lifecycle_loc_date_D'], on=['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'ISO_alpha_3'], how='left')

df = pd.merge(df, df_child_lifecycle_loc_date_Add_More['child_lifecycle_loc_date_A'], on=['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'moLN', 'faLN', 'ISO_alpha_3'], how='left')

df = pd.merge(df, df_child_lifecycle_loc_date_Add_More['child_lifecycle_loc_date_B'], on=['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'moLN', 'faLN', 'ISO_alpha_3'], how='left')

df = pd.merge(df, df_child_lifecycle_loc_date_Add_More['child_lifecycle_loc_date_C'], on=['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'moLN', 'faLN', 'ISO_alpha_3'], how='left')

df = pd.merge(df, df_child_lifecycle_loc_date_Add_More['child_lifecycle_loc_date_D'], on=['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'moLN', 'faLN', 'ISO_alpha_3'], how='left')


df.drop(columns=['moLN', 'faLN'], inplace=True)

# %% 
'''
*******************************************************************************

MODULE 4. Simply and Make Long File 

*******************************************************************************

The variable for exist or share of disaster existence in period is at child id level already, so we only need to slice the first row in group (child id). 
'''

# =============================================================================
# month_age_or_history = ['month_mics6_to_history']
# df = df.sort_values(by = id_vars+ month_age_or_history, ascending=[True, True, True, True, True])
# df = df.drop_duplicates(subset=id_vars, keep='first')
# 
# # Since the disaster intensity may change based on its definition, we localize it. 
# dis_intensity = [f'dis_intensity_{dis_intensity_type}']
# month_mics6_to_history = ['month_mics6_to_history']
# age_mics6_to_history = ['age_month_mics6_to_history']
# 
# df = df_store.drop(dis_intensity + month_mics6_to_history + age_mics6_to_history, axis=1)
# 
# =============================================================================




# %% 
'''
*******************************************************************************

MODULE 5. Merge with MICS Child File 

*******************************************************************************

Obtain other child attributes. Prepare for double-check and sum stat.
We may not do this to keep file light. 
'''

# df = pd.merge(df, df_240_mics_child_pa_hh, on=['countryfile', 'HH1', 'HH2', 'LN'], how='right')

# Specify the path and filename for the CSV file and export the DataFrame to CSV
dir_csv_file = f'{dir_data}/data_to_est/child_lifecycle_loc_date_dis_his_DB_DS.csv'
df.to_csv(dir_csv_file, index=False)

# if verbose:
#     df.shape()






# %% 
# Delete temporary variables from above loop  

# for var in list(locals()):
#     if var.startswith("cherry_"):
#         del locals()[var]

# del var 
# del row 
# del index




