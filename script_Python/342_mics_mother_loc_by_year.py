# -*- coding: utf-8 -*-

'''
---------------------------------------------------
Project: PIRE 
Author: Yujie Zhang 
Date: 20230204
---------------------------------------------------

TASK: https://github.com/ClimateInequality/PrjRDSE/issues/35

## Module 2. Create mother migratory history file. 

    Output: Each obs is one mother X time yearly. 
    Column: identifier of child (countryfile, HH1, HH2, LN); mother identifier (moLN); 
year; location (adm05, adm1, adm2 level, whichever applies)
    Note: 
        
WARNING
--------------
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

df_mics_mother_location_track = pd.read_csv(f'{dir_data}/data_intermediate/mics_mother_location_track.csv')

df = df_mics_mother_location_track.copy()

# STEP 1. Expand time of disaster to panel 

'''
Input: Each row of the file is mother ID (countryfile, HH1, HH2, moLN). 
There is starting date (kid_birthy) and ending date (mother interview time: mo_int_y) for each disaster. 
Current location: RDSE_loc_id. 

Output: 
Rows: Each unit of observation is mother X year
Columns: mother id (and child id), year, location 
'''

df.dropna(subset=['mo_int_y'], inplace=True)

df['kid_birthy'] = df.apply(lambda row: row['mo_int_y']-row['kid_age'] if pd.isna(row['kid_birthy']) else row['kid_birthy'], axis=1)
df.dropna(subset=['kid_birthy'], inplace=True)

df = df.drop(columns=['kid_birthm', 'kid_age', 'mo_int_m', 'mo_int_d'])


# 1. Array of years
df['ar_'] = df['mo_int_y'] - df['kid_birthy'] + 1    # This is number of years 
df['ID'] = range(1, len(df) + 1)     # Create unique ID 

# 2. Sort and generate variable equal to sorted index
df_panel = df.loc[df.index.repeat(df['ar_'])]

# 3. Panel now construct exactly which year in survey, note that all needed is sort index
# Note sorting not needed, all rows identical now
df_panel['num_year'] = df_panel.groupby('ID').cumcount() + 1

df_panel['year'] = df_panel['kid_birthy'] + df_panel['num_year'] - 1
# `yr_between` means year between child birth year and mother interview year inlusively. 



# STEP 2. Get location for each year

# If mother interview year - 2015 (example for one year) <= duration of stay, then the location in that year should be current location. Otherwise, it should be prior location. Since prior location is already there in all other variables, we do not need to repeat them. Use -99 to denote it should be prior location. 

df_panel['loc_in_year'] = df_panel.apply(lambda row: row['RDSE_loc_id'] if row['mo_int_y']-row['year'] <= row['mo_duration_yr'] else -99, axis=1)


# STEP 3. Simplify data file, keep necessary columns

df_panel = df_panel[['']]

df_panel = df_panel.drop_duplicates()


# STEP 4. Output: mother X year 

# Specify the path and filename for CSV file and export DataFrame to CSV
dir_csv_file = f'{dir_data}/data_intermediate/mics_mother_loc_by_year.csv'
df_panel.to_csv(dir_csv_file, index=False)

# %% What we want to know from this file. 

# Are children born in the same place? How large is the proportion if they are not born in the place they live in during survey? 




# %%    
# Delete temporary variables from above loop  

# for var in list(locals()):
#     if var.startswith("cherry_"):
#         del locals()[var]

# del var 
# del row 
# del index





