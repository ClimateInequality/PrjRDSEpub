# -*- coding: utf-8 -*-

# =============================================================================
# /* Project: PIRE 
# 
# Author: Yujie Zhang 
# Date: 20230204
# 
# */
# 
# TASK: https://github.com/ClimateInequality/PrjRDSE/issues/7
# 
# Create data file for EMDAT disaster with location and timing to MICS location id (RDSE location id). 
# 
# =============================================================================



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



# %% Import locals, such as directory. 

# _locals_dir.py should be in the same working directory as this script. This helps when we work on multiple computers. 

locals_included = 'YES' # We can turn this off. 

if locals_included == 'YES': 
    from _locals_dir import dir_main, dir_program, dir_rawdata, dir_tempdata, dir_data
    from _locals_dir import locals_dir 
    locals_dir()



# %% 
# =============================================================================
# TASK: Construct data file where each row is specified by EMDAT disaster ID `DisNo` and RDSE_loc_id. 
# This file is linkage between disaster and location. The same logic could be applied to any disaster and any location. 
# 
# 20230803 Yujie: Code 20230801 does not have matching type. To fix it, we consider each case more carefully and use variable `finest_adm_level` in file_A. 
# =============================================================================

df_file_A = pd.read_csv(f'{dir_data}/id_key_file/file_A.csv')
df_emdat_rawdata = pd.read_csv(f'{dir_data}/emdat/emdat_public_adbi_proj_country.csv')



# %% 
# =============================================================================
# =============================================================================
# # Module 1. Prepare the location-disaster file  
# =============================================================================
# =============================================================================

# Remove all blank space in variable names 

df = df_emdat_rawdata

df.rename(columns=lambda x: x.replace(' ', ''), inplace=True)

df = df[(df['Year'] >= 1999) & (df['Year'] <= 2019)]

df = df[['DisNo', 'Year', 'ISO', 'Location', 'AdmLevel', 'GeoLocations']]

df['locname'] = df['GeoLocations']
df.loc[df['locname'].isnull(), 'locname'] = df['Location']
df.loc[df['locname'].isnull(), 'locname'] = df['ISO']



# =============================================================================
# # Modify some string from all rows. Such as (Adm1) (Adm2)
# =============================================================================

# df['locname']=df['locname'].apply(lambda x: x.replace(' (Adm2).', '').replace(' (Adm1).', ''))
# df['locname'] = df['locname'].str.replace(" (Adm1).", ",")

replacements = [
    " District",
    " district",
    "(Administrative unit not available)",    
    "Administrative unit not available",
    " Agency",
    " agency",
    " regions",
    " region",
    " Regions",
    " Region"
]

# Loop through the replacements and perform the substitution
for replacement in replacements:
    df['locname'] = df['locname'].str.replace(replacement, "", case=False)

df['locname']=df['locname'].apply(lambda x: x.replace(' (Adm2).', ','))
df['locname']=df['locname'].apply(lambda x: x.replace(' (Adm1).', ','))
df['locname']=df['locname'].apply(lambda x: x.replace(';', ','))
df['locname']=df['locname'].apply(lambda x: x.replace('()', ','))
df['locname']=df['locname'].apply(lambda x: x.replace(' ()', ','))

df = df[['DisNo', 'locname']]



# =============================================================================
# # Split all location names (string) separated by comma in varaible GeoLocations 
# =============================================================================

df = pd.DataFrame(df.locname.str.split(', ').tolist(), index=df.DisNo).stack()
df = df.reset_index([0, 'DisNo'])
df.columns = ['DisNo', 'locname']

df.rename(columns={'locname': 'loc_'}, inplace=True)

# Apply the strip() method to remove leading and trailing whitespace from 'loc_'
df['loc_'] = df['loc_'].str.strip()
df['loc_'] = df['loc_'].apply(lambda x: x.replace(',', ''))

# Drop rows where 'loc_' is an empty string
df = df[df['loc_'] != ""]

# Find duplicates based on 'DisNo' and 'loc' columns
duplicate_rows = df[df.duplicated(subset=['DisNo', 'loc_'], keep=False)]

# Merge file with original disaster file 
df = pd.merge(df, df_emdat_rawdata, on='DisNo', how='left')

df = df[['DisNo', 'ISO', 'loc_', 'AdmLevel']]
df = df.sort_values(by = ['DisNo', 'ISO', 'loc_', 'AdmLevel'])

df_disaster = df 



# %%
# =============================================================================
# =============================================================================
# # Module 2. 
# =============================================================================
# =============================================================================



# Create one empty data frame with same columns as in df_disaster file . We will add rows to this file, instead of just adding one column to df_disaster and fill in  that one column for each row. So that when there are different cases for one row to be matched, we can explode that row into multiple rows defined by the row itself and matching type. 

df = pd.DataFrame(columns = df_disaster.columns.tolist()) 
df['RDSE_loc_affect'] = None
df['match_type'] = None

cherry_values = df['AdmLevel'].unique()
print(cherry_values)



# Define the function findlocation  

def findlocation(df, cherry_row, emdat_level, mics_level):
    
    print(f'EMDAT adm level = {emdat_level}')
    print(f'MICS adm level = {mics_level}')
    
    cherry_match_type = f'EMDAT {emdat_level} to MICS {mics_level}'
    cherry_row_type = cherry_row[(cherry_row['finest_adm_level'] == mics_level)]
    
    cherry_extract_row['RDSE_loc_affect'] = list(cherry_row_type['RDSE_loc_id'].unique()) 
    cherry_extract_row['match_type'] = cherry_match_type
    df = df.append(cherry_extract_row, ignore_index=True)
    
    return df 

# df = findlocation(df=df, cherry_row=cherry_row, emdat_level=0, mics_level=2)


        
# %%
# Using iterrows() to iterate through each row of the DataFrame

for index, row in df_disaster.iterrows():
    
    cherry_extract_row = df_disaster.loc[index]
    cherry_extract_row['RDSE_loc_affect'] = None
    cherry_extract_row['match_type'] = None
    
    cherry_emdat_loc = row['loc_']
    cherry_emdat_iso = row['ISO'] 
        
    if row['AdmLevel'] == '2':
        
        ########## CASE: emdat location is adm level 2
        
        cherry_row = df_file_A[(df_file_A['adm_2_loc'] == cherry_emdat_loc) & (df_file_A['ISO_alpha_3'] == cherry_emdat_iso)]
        
        ##### Separate matching types and update df
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=2, mics_level=2)
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=2, mics_level=1)
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=2, mics_level=0.5)
    
    
    if row['AdmLevel'] == '1':
        
        ########## CASE: emdat location is adm level 1
        
        cherry_row = df_file_A[(df_file_A['adm_1_loc'] == cherry_emdat_loc) & (df_file_A['ISO_alpha_3'] == cherry_emdat_iso)]
        
        ##### Separate matching types 
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=1, mics_level=2)
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=1, mics_level=1)
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=1, mics_level=0.5)
        
    
    if row['AdmLevel'] != '1' and row['AdmLevel'] != '2':

        ########## CASE: emdat location is adm level 2
        
        cherry_row = df_file_A[(df_file_A['adm_2_loc'] == cherry_emdat_loc) & (df_file_A['ISO_alpha_3'] == cherry_emdat_iso)]
        
        ##### Separate matching types 
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=2, mics_level=2)
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=2, mics_level=1)
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=2, mics_level=0.5)
        
        ########## CASE: emdat location is adm level 1
        
        cherry_row = df_file_A[(df_file_A['adm_1_loc'] == cherry_emdat_loc) & (df_file_A['ISO_alpha_3'] == cherry_emdat_iso)]
        
        ##### Separate matching types 
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=1, mics_level=2)
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=1, mics_level=1)
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=1, mics_level=0.5)    

        ########## CASE: emdat location is adm level 0.5

        cherry_row = df_file_A[(df_file_A['adm_05_loc'] == cherry_emdat_loc) & (df_file_A['ISO_alpha_3'] == cherry_emdat_iso)]
        
        ##### Separate matching types 
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=0.5, mics_level=2)
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=0.5, mics_level=1)
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=0.5, mics_level=0.5)       
        
        ########## CASE: emdat location is adm level 0 (country) 
        
        cherry_row = df_file_A[(df_file_A['ISO_alpha_3'] == cherry_emdat_iso) & (df_file_A['ISO_alpha_3'] == cherry_emdat_loc)]
        
        ##### Separate matching types 
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=0, mics_level=2)
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=0, mics_level=1)
        df = findlocation(df=df, cherry_row=cherry_row, emdat_level=0, mics_level=0.5) 
        
        

# %%
# =============================================================================
# From the above, there should be 3120 rows. 
# =============================================================================

df = df.sort_values(by = ['ISO', 'AdmLevel', 'loc_'])

# Check the data file, make sure all EMDAT location is looped over
rows_with_empty_value = df[df['RDSE_loc_affect'].isnull()]
del rows_with_empty_value

# Drop rows where RDSE_loc_affect is empty
# df = df.dropna(subset=['RDSE_loc_affect'])

# Filter out the rows where this column is nan or an empty list
df.dropna(subset=['RDSE_loc_affect'], inplace=True)
df = df[df['RDSE_loc_affect'].apply(lambda x: len(x) > 0)]

# Find duplicates based on 'DisNo' and 'loc' columns
duplicate_rows = df[df.duplicated(subset=['DisNo', 'ISO', 'loc_'], keep=False)]
del duplicate_rows

# Mongolia: Bayanzu'rx shows up in both adm 2 and adm 1 level location. Same case for Bulgan, Selenge, Su'xbaatar. 

# Thailand: Because in file A, we gave all location unique id for both national file and 17 provinces file and correspondingly, after regions have location id, and also for some provinces in those regions, there are other id. We decided to drop observations from Thailand national data for whom we do not know the province, and they will be dropped in later steps. 





# %%
# =============================================================================
# =============================================================================
# # Module 3. 
# =============================================================================
# =============================================================================

# Keep columns, and reshape. Right now each row is disaster-location name specific, meaning that `DisNo` and `loc_` uniquely identify one observation. We want to reshape into a file where `DisNo` and `RDSE_loc_affect` can uniquely identify each observation. 

# df = df[['DisNo', 'RDSE_loc_affect', 'match_type']]
df = df.explode('RDSE_loc_affect')

df = df.sort_values(by = ['DisNo', 'RDSE_loc_affect', 'match_type'])

duplicate_rows_2 = df[df.duplicated(subset=['DisNo', 'RDSE_loc_affect', 'match_type'], keep=False)]
duplicate_rows_2 = duplicate_rows_2.sort_values(by = ['DisNo', 'ISO', 'RDSE_loc_affect', 'match_type', 'loc_', 'AdmLevel'])
del duplicate_rows_2

# The duplicated cases make sense, as they are matching from smaller location in EMDAT to large location in MICS. So duplicates in terms of MICS location id (RDSE_loc_affect_) and matching type exist. 

df = df[['DisNo', 'RDSE_loc_affect', 'match_type']]
df = df.drop_duplicates()



# %%
# =============================================================================
# Output 
# =============================================================================

# Specify the path and filename for the CSV file

dir_csv_file = f'{dir_data}/data_intermediate/315_disaster_RDSEloc.csv'

# Export the DataFrame to CSV

df.to_csv(dir_csv_file, index=False)





# %%    
# Delete temporary variables from above loop  

for var in list(locals()):
    if var.startswith("cherry_"):
        del locals()[var]

del var 
del row 
del index




