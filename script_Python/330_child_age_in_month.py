# -*- coding: utf-8 -*-

'''
---------------------------------------------------
Project: PIRE 
Author: Yujie Zhang 
Date: 20230204
---------------------------------------------------

TASK: Create age in month variable for each child 
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


id_vars = ['countryfile', 'HH1', 'HH2', 'LN']


# %%
'''
Import dataset and define function 
-----------------------------------------------------------
'''

# Child lifecycle skeleton file 
if bl_test is True: 
    if it_test == 1:
        it_sample = 100
    elif it_test == 2:
        it_sample = 1600
    elif it_test == 3:
        it_sample = 16000

    df_YZ = pd.read_csv(f'{dir_data}/data_intermediate/YZ_simple_{it_sample}.csv')
    dir_csv_file = f'{dir_data}/data_intermediate/child_age_in_month_n{it_sample}_{st_run_computer}.csv'
    
else:
    df_YZ = pd.read_csv(f'{dir_data}/data_intermediate/YZ_child_lifecycle_skeleton.csv')
    dir_csv_file = f'{dir_data}/data_intermediate/child_age_in_month_full_{st_run_computer}.csv'



# %% 
'''
*******************************************************************************

MODULE 1. Merging 

*******************************************************************************
'''

age_in_month='age_month_mics6_to_history'

# %% 
'''
*******************************************************************************

MODULE . Find age in month for each child 
*******************************************************************************
'''

df = df_YZ[id_vars + [age_in_month]]    

df = df.sort_values(by = id_vars+ [age_in_month], ascending=[True, True, True, True, False])
df = df.drop_duplicates(subset=id_vars, keep='first')





# %% 
'''
*******************************************************************************

MODULE . Output 

*******************************************************************************
'''

# df = pd.merge(df, df_240_mics_child_pa_hh, on=['countryfile', 'HH1', 'HH2', 'LN'], how='right')

# Specify the path and filename for the CSV file and export the DataFrame to CSV
# dir_csv_file = f'{dir_data}/data_to_est/child_lifecycle_loc_date_dis_his.csv'
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




