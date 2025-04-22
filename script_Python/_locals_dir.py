# -*- coding: utf-8 -*-
"""
Created on Thu Aug 10 13:31:31 2023

@author: yzhan187

/* Project: PIRE 

Author: Yujie Zhang 
Date: 20230204

*/

TASK: locals 

"""

# %% 

# Install packages by typing the below in system terminal

# pip3 install pandas
# pip install pandasgui
# from pandasgui import show
# show(df)

import os
# import pandas as pd
# import numpy as np
# import math
# import matplotlib.pyplot as plt
# import seaborn as sns

# Remove normal warnings
import warnings
warnings.simplefilter('ignore')

import socket
current_host = socket.gethostname()
print(current_host)

# %% 

# Print the current working directory
print("Current working directory: {0}".format(os.getcwd()))

if current_host == 'ECON-M222-31': 

    # Store the working directory
    dir_main = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE"
    dir_program = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\program\000_github\PrjRDSE"
    dir_rawdata = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\rawdata"
    dir_tempdata = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\data_temp"
    dir_data = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\data"
    dir_table = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\table"
    
elif current_host == 'DESKTOP-44CKBTI': 

    # Store the working directory
    dir_main = r"C:\Users\fan\Documents\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE"
    dir_program = r"C:\Users\fan\Documents\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\program\000_github\PrjRDSE"
    dir_rawdata = r"C:\Users\fan\Documents\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\rawdata"
    dir_tempdata = r"C:\Users\fan\Documents\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\data_temp"
    dir_data = r"C:\Users\fan\Documents\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\data"
    dir_table = r"C:\Users\fan\Documents\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\table"

elif current_host == 'ECON-TU49D-01': 

    # Store the working directory
    dir_main = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE"
    dir_program = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\program\000_github\PrjRDSE"
    dir_rawdata = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\rawdata"
    dir_tempdata = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\data_temp"
    dir_data = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\data"
    dir_table = r"C:\Users\yzhan187\Dropbox (UH-ECON)\PIRE\team\yujie_zhang\PrjRDSE\table"

elif current_host == 'DESKTOP-C7FORAE': 
    
    # Store the working directory
    from pathlib import Path
    dir_main = Path("~") / "Dropbox (UH-ECON)" / "PIRE" / "team" / "yujie_zhang" / "PrjRDSE" 
    dir_program = Path("~") / "Dropbox (UH-ECON)" / "PIRE" / "team" / "yujie_zhang" / "PrjRDSE" / "program" / "000_github" / "PrjRDSE"
    dir_rawdata = Path("~") / "Dropbox (UH-ECON)" / "PIRE" / "team" / "yujie_zhang" / "PrjRDSE" / "rawdata"
    dir_tempdata = Path("~") / "Dropbox (UH-ECON)" / "PIRE" / "team" / "yujie_zhang" / "PrjRDSE" / "data_temp"
    dir_data = Path("~") / "Dropbox (UH-ECON)" / "PIRE" / "team" / "yujie_zhang" / "PrjRDSE" / "data"


elif current_host == 'Econ-TU105-LT30': 

    # Store the working directory
    dir_main = r"C:\Users\yzhan187\UH-ECON Dropbox\Yujie Zhang\PIRE\team\yujie_zhang\PrjRDSE"
    dir_program = r"C:\Users\yzhan187\UH-ECON Dropbox\Yujie Zhang\PIRE\team\yujie_zhang\PrjRDSE\program\000_github\PrjRDSE"
    dir_rawdata = r"C:\Users\yzhan187\UH-ECON Dropbox\Yujie Zhang\PIRE\team\yujie_zhang\PrjRDSE\rawdata"
    dir_tempdata = r"C:\Users\yzhan187\UH-ECON Dropbox\Yujie Zhang\PIRE\team\yujie_zhang\PrjRDSE\data_temp"
    dir_data = r"C:\Users\yzhan187\UH-ECON Dropbox\Yujie Zhang\PIRE\team\yujie_zhang\PrjRDSE\data"
    dir_table = r"C:\Users\yzhan187\UH-ECON Dropbox\Yujie Zhang\PIRE\team\yujie_zhang\PrjRDSE\table"

def locals_dir(): 
    
    # Change the working directory
    os.chdir(dir_program)
    
    # Print the current working directory
    print("Current working directory: {0}".format(os.getcwd())) 




























