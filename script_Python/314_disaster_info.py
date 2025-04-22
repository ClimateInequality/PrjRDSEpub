# -*- coding: utf-8 -*-

# =============================================================================
# Project: PIRE 
# Author: Yujie Zhang 
# Date: 20230204
# =============================================================================
# =============================================================================
# TASK: https://github.com/ClimateInequality/PrjRDSE/issues/7
# Create data file for EMDAT disaster with location and timing to MICS location id (RDSE location id). 
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

# %% Import locals, such as directory 

# When you open this .py file, the working directory is "C:\Users\yzhan187", so change working directory to `program` and then import other short names you want for other directory.

import os 

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
# =============================================================================

#  MODULE 1. Import dataset and define function 

# =============================================================================

df_emdat_rawdata = pd.read_csv(f'{dir_data}/emdat/emdat_public_adbi_proj_country.csv')
# df_315_disaster_RDSEloc = pd.read_csv(f'{dir_data}/data_intermediate/315_disaster_RDSEloc.csv')

# %% 
# =============================================================================

# MODULE 2. Simply EMDAT raw data, keep necessary rows 

# =============================================================================

# Simply EMDAT raw data, keep necessary columns
df = df_emdat_rawdata[['DisNo', 'Year', 'ISO', 'AssociatedDis', 'AssociatedDis2', 'OFDAResponse', 'Appeal', 'Declaration', 'AIDContribution000US', 'DisasterType', 'DisMagValue', 'DisMagScale', 'Latitude', 'Longitude', 'StartYear', 'StartMonth', 'StartDay', 'EndYear', 'EndMonth', 'EndDay', 'TotalDeaths', 'NoInjured', 'NoAffected', 'NoHomeless', 'TotalAffected', 'ReconstructionCostsAdjusted', 'InsuredDamagesAdjusted000', 'TotalDamagesAdjusted000US']]

# Specify the path and filename for the CSV file
dir_csv_file = f'{dir_data}/data_intermediate/314_disaster_info.csv'

# Export the DataFrame to CSV
df.to_csv(dir_csv_file, index=False)



# %%    
# Delete temporary variables from above loop  

# for var in list(locals()):
#     if var.startswith("cherry_"):
#         del locals()[var]

# del var 
# del row 
# del index




