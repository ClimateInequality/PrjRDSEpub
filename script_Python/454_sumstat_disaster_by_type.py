# -*- coding: utf-8 -*-
"""
Created on Wed Jul 17 16:15:20 2024

@author: yzhan187
"""

'''
---------------------------------------------------
Project: PIRE 
Author: Yujie Zhang 
Date: 20230204
---------------------------------------------------

TASK: https://github.com/ClimateInequality/PrjRDSE/issues/40

Summarize type B, C, D disasters. 

Output: disaster intensity file. 
    Row: one single disaster 
    Column: (1) disaster id (2) intensity type; characteristics: (3) country (4) year 

Output: dis_A 
Disaster existence of all type. 0 if nothing, 1 if there is any type of disaster. 
 
Output: dis_B 
Disaster existence of flood. 0 if nothing, 1 if there is flood. 

Output: dis_C
Disaster 0 or 1, EM_DAT more death-injure and impacted: DI >= X1 > 0 OR IMP >= Y1 >= 0

Output: dis_D 
Disaster 0 or 1, EM_DAT high death-injure and impacted: DI >= X1 > 0 OR IMP >= Y1 >= 0



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

# pip install openpyxl
# pip3 install pandas
# pip install pandasgui
# from pandasgui import show
# show(df)

import os
import pandas as pd
import numpy as np
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

df_314_disaster_info = pd.read_csv(f'{dir_data}/data_intermediate/314_disaster_info.csv')
# df_disaster_info = pd.read_csv(f'{dir_data}/data_intermediate/disaster_info.csv')
df_disaster_RDSEloc_month = pd.read_csv(f'{dir_data}/data_intermediate/disaster_RDSEloc_month.csv')
# df_YZ_loc_skeleton = pd.read_csv(f'{dir_data}/data_intermediate/YZ_loc_skeleton.csv')
# df_file_A = pd.read_csv(f'{dir_data}/id_key_file/file_A.csv')

# Set up location id and timing variable in data files 
disno='DisNo'
year='Year'
country='ISO'
disastertype='DisasterType'


# %%
'''
*******************************************************************************

Output: dis_intensity_A
Disaster existence. 0 if nothing, 1 if there is any type of disaster. 

*******************************************************************************

'''

df1 = df_314_disaster_info.copy()
df1 = df1[(df1['Year']>=1999) & (df1['Year']<=2019)]
# There are 490 events. 

df = df_disaster_RDSEloc_month.copy()
df = df[['DisNo']]
df = df.drop_duplicates()

df = pd.merge(df, df_314_disaster_info, on='DisNo',how='left')

df_A = df.copy()

# This df_allmergedevents will be the foundational df. 
df_allmergedevents = df.copy()


# %% 
'''
*******************************************************************************

Output: dis_intensity_B 
Disaster existence of flood. 0 if nothing, 1 if there is flood. 

*******************************************************************************
'''

df = df_allmergedevents.copy()
df = df[df['DisasterType'] == 'Flood'] 

df_B = df.copy()


# %% 
'''
*******************************************************************************

Output: dis_intensity_C
Disaster 0 or 1, EM_DAT more death-injure and impacted: DI >= X1 > 0 OR IMP >= Y1 >= 0

*******************************************************************************
'''
df = df_allmergedevents.copy()

df['total_deaths_injured'] = df['TotalDeaths'] + df['NoInjured']
# df['log_total_affected'] = np.log(df['TotalAffected'])
df['total_affected'] = df['TotalAffected']

X = 500
Y = 5000
df = df[(df['total_deaths_injured'] > X) | (df['total_affected'] > Y)]

df_C = df.copy()


# %% 
'''
*******************************************************************************

Output: dis_intensity_D 
Disaster 0 or 1, flood, EM_DAT high death-injure and impacted: DI >= X1 > 0 OR IMP >= Y1 >= 0

*******************************************************************************
'''

df = df_allmergedevents.copy()

df = df[df['DisasterType'] == 'Flood'] 

df['total_deaths_injured'] = df['TotalDeaths'] + df['NoInjured']
# df['log_total_affected'] = np.log(df['TotalAffected'])
df['total_affected'] = df['TotalAffected']

X = 500
Y = 5000
df = df[(df['total_deaths_injured'] > X) | (df['total_affected'] > Y)]

df_D = df.copy()


# %% 
'''
*******************************************************************************

Output: dis_intensity_D 
Disaster 0 or 1, flood, EM_DAT high death-injure and impacted: DI >= X1 > 0 OR IMP >= Y1 >= 0

*******************************************************************************
'''

for i in df_A, df_B, df_C, df_D:

    tab_type_i = i.groupby(disastertype).size().reset_index(name='Count')
    tab_country_i = i.groupby(country).size().reset_index(name='Count')
    tab_type_country_i = i.pivot_table(index=country, columns=disastertype, aggfunc='size', fill_value=0)


dataframes = {
    'df_A': df_A,
    'df_B': df_B,
    'df_C': df_C,
    'df_D': df_D
}

# Dictionary to store results
results = {}

for name, df in dataframes.items():
    tab_type_name = f'tab_type_{name}'
    tab_country_name = f'tab_country_{name}'
    tab_type_country_name = f'tab_type_country_{name}'
    
    results[tab_type_name] = df.groupby(disastertype).size().reset_index(name='Count')
    results[tab_country_name] = df.groupby(country).size().reset_index(name='Count')
    results[tab_type_country_name] = df.pivot_table(index=country, columns=disastertype, aggfunc='size', fill_value=0)





# Create an Excel writer object
with pd.ExcelWriter(f'{dir_data}/data_intermediate/sumstat_disaster_by_type.xlsx', engine='openpyxl') as writer:
    # Write each DataFrame to a different sheet
    df_A.to_excel(writer, sheet_name='df_A', index=False)
    df_B.to_excel(writer, sheet_name='df_B', index=False)
    df_C.to_excel(writer, sheet_name='df_C', index=False)
    df_D.to_excel(writer, sheet_name='df_D', index=False)








