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

# ++++++++++++++ To set up if you want to only test subsample. ++++++++++++++

bl_test = False
it_test = 2
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


# ++++++++++++++ To simplify, assign the disaster type. ++++++++++++++

# AC file, location disaster history 
# dis_intensity_type = 'A'
# dis_intensity_type = 'B'
# dis_intensity_type = 'C'
# dis_intensity_type = 'D'


# %%
'''
Import dataset and define function 
-----------------------------------------------------------
'''

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
    dir_csv_file = f'{dir_data}/data_to_est/child_lifecycle_loc_date_alltype_n{it_sample}_{st_run_computer}_DM_Add_m1to3_12.csv'
    
else:
    df_YZ = pd.read_csv(f'{dir_data}/data_intermediate/YZ_child_lifecycle_skeleton.csv')
    dir_csv_file = f'{dir_data}/data_to_est/child_lifecycle_loc_date_alltype_full_{st_run_computer}_DM_Add_m1to3_12.csv'


id_vars = ['countryfile', 'HH1', 'HH2', 'LN']



# %%
'''
*******************************************************************************

MODULE 2. Dictionary to store items to loop over with later 

*******************************************************************************
'''

# ++++++++++++++ Dictionary to store all the disaster type. ++++++++++++++

dict_distype = {}

for key_type in range(1, 5): 
    if key_type == 1:
        dis_intensity_type = 'A'
    if key_type == 2:
        dis_intensity_type = 'B'
    if key_type == 3:
        dis_intensity_type = 'C'
    if key_type == 4:
        dis_intensity_type = 'D'
        
    # Assign values to each key in dictionary. 
    dict_distype[key_type] = {
        "dis_intensity_type": dis_intensity_type
    }

# ++++++++++++++ Dictionary to store all the periods we want to include. ++++++++++++++

dict_timing = {}

for key in (3, 7):  # Adjust the range as needed
        
    start_g = -9999
    end_g = 9999
    start_m = -9999
    end_m = 9999    

    #--------------- date in the interview month  
    if key == 3:
        start_m = 1
        end_m = 3
    # # -------------- date in the most recent month before interview month 
    # # This one compared to last one above, can avoid the case where child is in fact interviewed on a day before any disaster happens in the same month. In the case when disaster happened after child interview, we may will make mistake treating the child as having experienced disaster before interview. 
    # if key == 4:
    #     start_m = 1
    #     end_m = 4
    # #--------------- date in the interview month and most recent month 
    # if key == 5:
    #     start_m = 1
    #     end_m = 5
    # #--------------- date most recent year == in past 12 month
    # if key == 6:
    #     start_m = 1
    #     end_m = 6  

    #--------------- date most recent year == in past 12 month
    if key == 7:
        start_m = 1
        end_m = 12
    
    # Assign values to each key in dictionary. 
    dict_timing[key] = {
        "start_m": start_m,
        "end_m": end_m,
        "start_g": start_g,
        "end_g": end_g
    }



# %% 
'''
*******************************************************************************

MODULE 3. Function to generate DM variables 

*******************************************************************************
'''


def fn_dis_var_DM(df, id_vars, month_history, start_month, end_month, age_in_month, start_age, end_age, df_store, A, B, E):
    '''
    Description
    -----------
    Similar to the above fn. 
    This combines MODULE 2 and 3 together. First, generate date_or_age_category variables, then calculate the indicator of if any disaster happens in that period, and then the share of months experiencing disaster in that period. 
    
    Parameters
    ----------
    id_vars : child identifier, here it is a group of variables. 
    A : disaster existence indicator in that month for that child. => disaster intensity score 
    B : calendar and lifecycle category. 
    E : new column to generate, number of rows for certain value. ===> variable DM 
    
    Returns
    -------

    '''

    df[B] = None
    df[B][(start_month <= df[month_history]) & (df[month_history] <= end_month) & (start_age <= df[age_in_month]) & (df[age_in_month] <= end_age)] = 1   # This should work faster than above line. Last line command is terrible idea, do not run loops in Python DataFrame by rows. 
    
    # Group by ID and column B, find number of rows with column A being 1  
    df[E] = df.groupby(id_vars + [B])[A].transform(lambda x: round((x == 1).sum()))
    
    # Drop date_or_age_category, useless columns
    df = df.drop([B], axis=1)
    
    # Keep only the first obs for each group by child id and starting month, keep only id and new DB DS DM var, add them into id file. 
    # By this, we each time add two columns to a file with each obs being each MICS child. 
    
    df = df.sort_values(by = id_vars+ [E], ascending=[True, True, True, True, False])
    df1 = df.drop_duplicates(subset=id_vars, keep='first')
    df1 = df1[id_vars + [E]]         
    df_store = pd.merge(df_store, df1, left_on=id_vars, right_on=id_vars, how='left')

    # Keep df light for next round of using this function. 
    df = df.drop([E], axis=1)

    return df_store, df
    # return df makes sure to renew df. Otherwise, there are more and more columns in df. 



# %% 
'''
*******************************************************************************

MODULE 4. Implement with loop 

*******************************************************************************
'''

# This df_store is where we add more and more column in 
df_store = df_mics_child_id.copy()

month_history='month_mics6_to_history'
age_in_month='age_month_mics6_to_history'

# ///// Loop A. Loop over disaster intensity type, stored in dictionary dict_distype

for key_type in range(1, 5):

    dis_intensity_type = dict_distype[key_type]["dis_intensity_type"]
     
    df_AC_month_dis = pd.read_csv(f'{dir_data}/data_to_est/AC_month_dis_intensity_{dis_intensity_type}.csv')

    # 1. Obtain file on location X month disaster history
    # df = df_AC_month_dis
    df = df_AC_month_dis.drop(['month_mics6_to_history', 'year', 'month'], axis=1)

    # 2. Merge with child X month skeleton file (YZ file) 
    df_YZ_distype = pd.merge(df_YZ, df, left_on=['RDSE_loc_id', 'cld_month_mics6_to_history'], right_on=['RDSE_loc_id', 'cld_month_mics6_to_history'], how='left')

    df = df_YZ_distype.copy()
    
    # ///// Loop B. Loop over timing (period), stored in dictionary dict_timing
    
    for key in (3, 7): 
        
        start_month = dict_timing[key]["start_m"]
        end_month = dict_timing[key]["end_m"]
        start_age = dict_timing[key]["start_g"]
        end_age = dict_timing[key]["end_g"]

        # ----- Naming rule is different for this type 
        if key in range(3, 8): 

            df_store, df = fn_dis_var_DM(df, id_vars, month_history = month_history, start_month = start_month, end_month = end_month, age_in_month = age_in_month, start_age = start_age, end_age = end_age, df_store=df_store, A=f'dis_intensity_{dis_intensity_type}', B=f'life_m{start_month}_to_m{end_month}', E=f'dis_{dis_intensity_type}_DM_m{start_month}to{end_month}')



# %% 
'''
*******************************************************************************

MODULE 5. Output 

*******************************************************************************
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




