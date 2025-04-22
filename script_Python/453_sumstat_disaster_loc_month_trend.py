# -*- coding: utf-8 -*-
"""
Created on Tue Jun 25 15:54:48 2024

@author: yzhan187
"""

'''
---------------------------------------------------
Project: RDSE
Author: Yujie Zhang 
Date: 240625
---------------------------------------------------

TASK: 
    Create figure: 
        SS2.T1.1 Share of Locations that Experience Disasater Shock in Each Calendar Month over 20 Years. 
        For each location in every month from lastest survey month to 20 years ago, we construct disaster indicator.
        For all locations in past 20 years, share of location-month with disaster shock of each type is shown cross calendar month of the year.  
        For all types, during summer the locations are hit by disaster for any type most. 
        This also shows focusing only on one category of disaster shocks omits large proportion of overall shocks.

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
import matplotlib.pyplot as plt
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

# Set up location id and timing variable in data files 
fig_number = 1

var_country = 'countryfile'

st_row = 'month'
st_country = 'BGD2019'

st_line1 = 'dis_intensity_A' 
st_line2 = 'dis_intensity_B'
st_line3 = 'dis_intensity_C'
st_line4 = 'dis_intensity_D'

# Import dataset 
df_AC_month_dis_intensity = pd.read_excel(f'{dir_data}/data_pivot/AC_month_dis_intensity.xlsx')
# Assign custom name to DataFrame

df = df_AC_month_dis_intensity.copy()

sm = df.describe()
column_names = df.columns.tolist()

# Drop PKB locations! We do not include PKB. 
df = df[(df[var_country] != 'PKB2019')]


# %% 

for p in range(1, 5):

    fig_number = p 
    
    if fig_number == 1:
        df1 = df
    if fig_number == 2:
        df1 = df[(df[var_country] == 'BGD2019')]
    if fig_number == 3:
        df1 = df[(df[var_country] == 'PKK2019') | (df[var_country] == 'PKP2017') | (df[var_country] == 'PKS2018')]
    if fig_number == 4:
        df1 = df[(df[var_country] != 'BGD2019') & (df[var_country] != 'PKK2019') & (df[var_country] != 'PKP2017') & (df[var_country] != 'PKS2018')]

    df2 = df1.groupby([st_row])[st_line1, st_line2, st_line3, st_line4].mean().reset_index()
    
    # Plot data 
    plt.figure(figsize=(10, 6))
    
    # plt.plot(df2[st_row], df2[st_line1], label='Any disasters')
    # plt.plot(df2[st_row], df2[st_line2], label='Floods')
    # plt.plot(df2[st_row], df2[st_line3], label='Severe disasters')
    # plt.plot(df2[st_row], df2[st_line4], label='Severe floods')
    
    plt.plot(df2[st_row], df2[st_line1], label='Any disasters', linestyle='-', marker='o')
    plt.plot(df2[st_row], df2[st_line2], label='Floods', linestyle='--', marker='s')
    plt.plot(df2[st_row], df2[st_line3], label='Severe disasters', linestyle='-.', marker='^')
    plt.plot(df2[st_row], df2[st_line4], label='Severe floods', linestyle=':', marker='x')
    
    # Add label and title
    plt.xlabel('Month')
    plt.ylabel('Share of location-month with disasters')
    # plt.title('Share of Locations that Experience Disasater Shock in Each Calendar Month over 20 Years')
    plt.xticks(ticks=range(1,13))
    plt.yticks(ticks=[i*0.05 for i in range(8)])
    plt.ylim(0, 0.35)
    # plt.grid(True, which='both', linestyle='--',linewidth=0.5)
    plt.grid(True, which='both', linestyle='--',linewidth=0.5, axis='y')
    
    plt.legend(loc='upper right')
    plt.gca().spines['top'].set_visible(False)
    plt.gca().spines['right'].set_visible(False)
    plt.gca().spines['left'].set_visible(False)
    plt.gca().spines['bottom'].set_visible(False)
    
    plt.show
    
    dir_figure = f'{dir_main}/figure/yz/'
    plt.savefig(dir_figure + f'SS2.T1.{fig_number}.png', dpi=300)
    


# %%

# dir_csv_file = f'{dir_data}/data_intermediate/.csv'
# df_EF_dishock_ratio_population.to_csv(dir_csv_file, index=False)



# %%    
# Delete temporary variables from above loop  

# for var in list(locals()):
#     if var.startswith("cherry_"):
#         del locals()[var]

# del var 
# del row 
# del index











