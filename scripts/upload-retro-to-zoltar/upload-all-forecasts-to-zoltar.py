
# import libraries
import glob
import pymmwr as pm
from pathlib import Path
import ntpath
import time
import pandas as pd
from zoltpy import functions
import os

# initialize variables
my_path = '../../model-forecasts/component-models'
df_retro = pd.read_csv('retroactive-forecasts.csv')
directory = 'master'
cdc_project_name = 'TEST cdc flusight network'

# for loop to find all csvs in forecasts
for first_path in glob.iglob(my_path + '**/**/', recursive=False):
    for csv_file in glob.iglob(first_path + '*.csv', recursive=False):
        
        # get model directory
        dir_names = [p.name for p in Path(csv_file).parents]
        curr_model_dir = dir_names[0]

        # get model timezero
        csv_file_name = ntpath.basename(csv_file)
        csv_file_list = csv_file_name.split('-')
        epi_week = int(csv_file_list[0][-2:])
        epi_year = int(csv_file_list[1])
        ew = pm.Epiweek(epi_year, epi_week)
        timezero = pm.epiweek_to_date(ew).strftime('%Y%m%d')

        # get season start year
        if epi_week <= 18:
            start_year = epi_year - 1
        else:
            start_year = epi_year
        df_retro['start_year'] = df_retro['season'].astype(str).str[0:4]
        
        # filter to check if forecast exists
        cond1 = df_retro['model-dir'] == curr_model_dir
        cond2 = df_retro['directory'] == directory
        cond3 = df_retro['start_year'] == str(start_year)
        df_filtered = df_retro[cond1 & cond2 & cond3]

        if df_filtered.empty == False:

            # get zoltar model name
            model_name = df_filtered['zoltar-name'].values[0]

            # only upload Bayesian Model Averaging for now...
            if model_name == 'Bayesian Model Averaging':
                print('\nUploading...')
                print('Project:' + cdc_project_name)
                print('Model Name:' + df_filtered['zoltar-name'].values[0])
                print('Timezero:' + timezero)
                print('File Path:' + csv_file)
                upload_file_path = os.path.abspath(csv_file)

                error_upload = []
                try:
                    functions.delete_forecast(cdc_project_name,model_name,timezero)
                    functions.upload_forecast(upload_file_path,cdc_project_name,model_name,timezero)
                except:
                    print('Could not upload: %s' % csv_file)
                    error_upload += [csv_file]

print("UPLOADS COMPLETE")
print("ERROR UPLOADING..." )
print('\n'.join(map(str, error_upload)))

