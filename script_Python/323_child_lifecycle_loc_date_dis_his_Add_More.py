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

# AC file, location disaster history 
# dis_intensity_type = 'A'
# dis_intensity_type = 'B'
# dis_intensity_type = 'C'
dis_intensity_type = 'D'

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

df_AC_month_dis = pd.read_csv(f'{dir_data}/data_to_est/AC_month_dis_intensity_{dis_intensity_type}.csv')
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
    dir_csv_file = f'{dir_data}/data_to_est/child_lifecycle_loc_date_{dis_intensity_type}_full_{st_run_computer}_Add_More.csv'



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

# df = df_AC_month_dis
df = df_AC_month_dis.drop(['month_mics6_to_history', 'year', 'month'], axis=1)

# 2. Merge with child X month skeleton file (YZ file) 

df_YZ = pd.merge(df_YZ, df, left_on=['RDSE_loc_id', 'cld_month_mics6_to_history'], right_on=['RDSE_loc_id', 'cld_month_mics6_to_history'], how='left')

id_vars = ['countryfile', 'HH1', 'HH2', 'LN']
df_store = df_mics_child_id

# df = df.drop(['RDSE_loc_affect', 'cld_month'], axis=1)
# df = df.drop(['RDSE_loc_affect', 'cld_month', 'cld_month_mics6_to_history'], axis=1)

# Check column name without opening data 
# column_names = df.columns.tolist()
# print(column_names)


# rows_missing = df[df['month_mics6_to_history'].isna()]
# rows_missing = df[df['age_month_mics6_to_history'].isna()]

# df = df.iloc[1:54321]

# %% 
'''
*******************************************************************************

MODULE 2. Generate Calendar and Lifecycle Categories

*******************************************************************************

1. Group by each child, sort from the most recent to earlier month

2. Construct past years variable:
    
    critically to sort from the most recent to earlier month, based on month sorting!
    
    generate date_is_past_12month:
        = 0 for 12 >= rownumber >=1 (most recent year)
        = 1 for 10 x 12 >= rownumber >= 12 (9 years prior to most recent)
        = NA for other montsh
        
    Construct past ages variable:
        based on not month sorting, but age conditioning
        
        generate age_bf_0: BEFORE birth, IN prenatal period
            
        generate age_bf_2y: BEFORE 2 years old 
            
        generate age_bf_33m: Before 33 months, IN first 1000 days 
            
        generate age_bf_6y: BEFORE School starting age
        
        generate age_at_6y: AT school starting age
        
        generate age_bf_13y: BEFORE school ending age
        
        generate age_at_13y: AT school ending age
        
        generate age_all_life: BEFORE interview month 
            = 1 for age >= -9 (most recent year)
            = NA for other month    

We already have child-specific date-frame variables from YZ file. 
We should be able to generate categories directly??? YES. 
We should write a function to create the variables. The year or month number should be argument.
It is better to set up a starting timing and ending timing. Categorize period in between as 1, every other time as 0. Then calculate the binary indicator or share for just 1. Or maybe just set the period in between as 1, others all as None. 
'''

'''
*******************************************************************************

MODULE 3. Generate Aggregate Statistics from Categories

*******************************************************************************

1. Construct interview-date-specific history aggregated to different backward window
    Group by each child and date_is_past_12month
    generate "bi_past_year", "bi_b12_9years", which is 1 if there is any month with 1 for disaster during the "0" and "1" period.
    generate "fl_mth_past_year", "fl_mth_b12_9years", which is share of month out of total month with disaster during the "0" and "1" period.

2. Construct interview-date-child-age-specific lifecycle aggregated to different critical period
    Group by each child and age_f18m_life
    generate "bi_critical_year", "bi_noncritical_9years", which is 1 if there is any month with 1 for disaster during the "0" and "1" period. 
    generate "cts_mth_critical_year", "cts_mth_noncritical_9years", which is share of month out of total month with disaster during the "0" and "1" period.
'''

# If we do not have month_mics6_to_history 
# df = df.sort_values(by=['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'cld_month_mics6_to_history'], ascending=[True, True, True, True, True, False])
# df = df.sort_values(by=['RDSE_loc_id', 'countryfile', 'HH1', 'HH2', 'LN', 'month_mics6_to_history'], ascending=[True, True, True, True, True, True])

# =============================================================================
# df['row_number'] = df.groupby(['countryfile', 'HH1', 'HH2', 'LN']).cumcount() + 1
# rows_mismatch = df[df['month_mics6_to_history'] != df['row_number']]
# # All match, which should be be the case. 
# =============================================================================



def date_or_age_category_exist_share(df, id_vars, month_age_or_history, start_month, end_month, df_store, A, B, C, D):
    '''
    Description
    -----------
    This combines MODULE 2 and 3 together. First, generate date_or_age_category variables, then calculate the indicator of if any disaster happens in that period, and then the share of months experiencing disaster in that period. 
    
    Parameters
    ----------
    id_vars : child identifier, here it is a group of variables. 
    A : disaster existence indicator in that month for that child. => disaster intensity score 
    B : calendar and lifecycle category. 
    C : new column to generate, 1 or 0. Specify column name in argument. 
    D : new column to generate, share of rows for certain value. Specify column name in argument. 
    
    Returns
    -------
    There are columns child_id, A, B. Column A = 0, 1 or None. Column B = 1 or None. I want to create column C. For each child_id, in rows where B=1, if there is any row where A=1, then all the rows of this child_id should have C=1. If not, C=0.
    
    There are columns child_id, A, B. Column A=0,1 or None. Column B=1 or None. I want to create column D. For each child_id, in rows where B=1, calculate the share of rows where value for A is 1, and put that share in column D.
    '''
    
    # Generate date_or_age_category
    df = df_YZ.copy()
    df[B] = None
    # df.loc[(start_month <= df[month_age_or_history]) & (df[month_age_or_history] <= end_month), B] = 1
    df[B][(start_month <= df[month_age_or_history]) & (df[month_age_or_history] <= end_month)] = 1   # This should work faster than above line 

    # Group by ID and column B, find maximum of column A values in rows 
    df['findmax'] = df.groupby(id_vars + [B])[A].transform('max')
    # Group by ID, generate column C with value being maximum of 'findmax' 
    df[C] = df.groupby(id_vars)['findmax'].transform('max')    
    
    # Group by ID and column B, find share of rows with column A being 1 
    df['findshare'] = df.groupby(id_vars + [B])[A].transform(lambda x: round((x == 1).mean(), 2))
    # Group by ID, generate column C with value being maximum of 'findshare' 
    df[D] = df.groupby(id_vars)['findshare'].transform('max')
    
    # Drop date_or_age_category, useless columns
    df = df.drop([B], axis=1)
    df = df.drop(['findmax', 'findshare'], axis=1)
    
    # Keep only the first obs for each group by child id and starting month, keep only id and new DB DS var, add them into id file. 
    # By this, we each time add two columns to a file with each obs being each MICS child. 
    # month_age_or_history = ['month_mics6_to_history']
    df = df.sort_values(by = id_vars+ ['month_mics6_to_history'], ascending=[True, True, True, True, True])
    df1 = df.drop_duplicates(subset=id_vars, keep='first')
    df1 = df1[id_vars + [C, D]]         
    df_store = pd.merge(df_store, df1, left_on=id_vars, right_on=id_vars, how='left')


    return df_store


# =============================================================================
# start_month=1
# end_month=2
# month_age_or_history='month_mics6_to_history'
# B='date_in_past_12m'
# df[B] = None
# df[B][(start_month <= df[month_age_or_history]) & (df[month_age_or_history] <= end_month)] = 1
# =============================================================================

# C=f'dis_{dis_intensity_type}_DB_m{start_month}to{end_month}'
# D=f'dis_{dis_intensity_type}_DS_m{start_month}to{end_month}'



#--------------- m 13 to 120  
# --- date in 10 years before the year before most recent year (if interview in 2018, then 2008-2016)
start_month = 1*12+1
end_month = 10*12
df_store = date_or_age_category_exist_share(df, id_vars, month_age_or_history='month_mics6_to_history', start_month=start_month, end_month=end_month, df_store=df_store, A=f'dis_intensity_{dis_intensity_type}', B=f'date_m{start_month}to{end_month}', C=f'dis_{dis_intensity_type}_DB_m{start_month}to{end_month}', D=f'dis_{dis_intensity_type}_DS_m{start_month}to{end_month}')


#--------------- m 25 to 120 
start_month = 2*12+1
end_month = 10*12
df_store = date_or_age_category_exist_share(df, id_vars, month_age_or_history='month_mics6_to_history', start_month=start_month, end_month=end_month, df_store=df_store, A=f'dis_intensity_{dis_intensity_type}', B=f'date_m{start_month}to{end_month}', C=f'dis_{dis_intensity_type}_DB_m{start_month}to{end_month}', D=f'dis_{dis_intensity_type}_DS_m{start_month}to{end_month}')


#--------------- m 13 to 240
start_month = 1*12+1
end_month = 20*12
df_store = date_or_age_category_exist_share(df, id_vars, month_age_or_history='month_mics6_to_history', start_month=start_month, end_month=end_month, df_store=df_store, A=f'dis_intensity_{dis_intensity_type}', B=f'date_m{start_month}to{end_month}', C=f'dis_{dis_intensity_type}_DB_m{start_month}to{end_month}', D=f'dis_{dis_intensity_type}_DS_m{start_month}to{end_month}')


#--------------- m 25 to 240
start_month = 2*12+1
end_month = 20*12
df_store = date_or_age_category_exist_share(df, id_vars, month_age_or_history='month_mics6_to_history', start_month=start_month, end_month=end_month, df_store=df_store, A=f'dis_intensity_{dis_intensity_type}', B=f'date_m{start_month}to{end_month}', C=f'dis_{dis_intensity_type}_DB_m{start_month}to{end_month}', D=f'dis_{dis_intensity_type}_DS_m{start_month}to{end_month}')


# %% 
'''
*******************************************************************************

MODULE 4. Simplify and Make Long File 

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
# dir_csv_file = f'{dir_data}/data_to_est/child_lifecycle_loc_date_dis_his.csv'
df_store.to_csv(dir_csv_file, index=False)

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




