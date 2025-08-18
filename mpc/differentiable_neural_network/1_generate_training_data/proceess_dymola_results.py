"""
this script is to load and prepprocess the simulation results from Dymola, the processed dataset will be used for training the prediction models

Author: Guowen Li, guowenli@tamu.edu, 4/11/2024
"""
from buildingspy.io.outputfile import Reader
import numpy as np
import pandas as pd
import scipy.interpolate as interpolate


def get_measurement(dymola_result, names):
    """get measurements from dymola simulation results
       return a pandas data frame
    """
    dic = {}
    dic['time'] = dymola_result.values(names[0])[0]
    for name in names:
        dic[name] = dymola_result.values(name)[1]
    
    return pd.DataFrame(dic, index=dic['time'])

# load .mat file generated from Dymola
#simResFile = 'SystemForMPC_2bInputs_random-perturb-every-2hr.mat'
simResFile = 'SystemForMPC_1bInput_modeSignal_random-perturb-every-1hr'
simResult = Reader(simResFile,'dymola') # format: (time, val) = simResult.values('measurement_name')

# Get measurements 
# measurement_names = ['tesBed.TOut.y',
#                      'tesBed.weaBus.TWetBul',
#                      'tesBed.weaBus.relHum',
#                      'tesBed.weaBus.HGloHor',
#                      'bChi.y',
#                      'bIce.y',
#                      'tesBed.occSch.occupied',
#                      'tesBed.modCon.y',
#                      'tesBed.iceTan.SOC',
#                      'tesBed.chi.TSet',
#                      'tesBed.iceTan.TOutSet',
#                      'tesBed.TCHWSup.T',
#                      'tesBed.TCHWRetCoi.T',
#                      'tesBed.priPum.m_flow',
#                      'tesBed.secPum.m_flow',
#                      'tesBed.senRelPre.p_rel',
#                      'tesBed.conAHU.TSupSet',
#                      'tesBed.conAHU.TSup',
#                      'tesBed.senSupFlo.V_flow',
#                      'tesBed.conVAVCor.damVal.VDisSet_flow',
#                      'tesBed.VSupCor_flow.V_flow',
#                      'tesBed.conVAVSou.damVal.VDisSet_flow',
#                      'tesBed.VSupSou_flow.V_flow',
#                      'tesBed.conVAVEas.damVal.VDisSet_flow',
#                      'tesBed.VSupEas_flow.V_flow',
#                      'tesBed.conVAVNor.damVal.VDisSet_flow',
#                      'tesBed.VSupNor_flow.V_flow',
#                      'tesBed.conVAVWes.damVal.VDisSet_flow',
#                      'tesBed.VSupWes_flow.V_flow',
#                      'tesBed.conAHU.TZonCooSet',
#                      'tesBed.conAHU.TZonHeaSet',
#                      'tesBed.conVAVCor.TZon',
#                      'tesBed.conVAVSou.TZon',
#                      'tesBed.conVAVEas.TZon',
#                      'tesBed.conVAVNor.TZon',
#                      'tesBed.conVAVWes.TZon',
#                      'tesBed.ave.y',
#                      'tesBed.chi.P',
#                      'tesBed.priPum.P',
#                      'tesBed.secPum.P',
#                      'tesBed.fanSup.P']
measurement_names = ['tesBed.TOut.y',
                     'tesBed.weaBus.TWetBul',
                     'tesBed.weaBus.relHum',
                     'tesBed.weaBus.HGloHor',
                     'tesBed.uMod',
                     'tesBed.uModActual.y',
                     'tesBed.occSch.occupied',
                     'tesBed.modCon.y',
                     'tesBed.iceTan.SOC',
                     'tesBed.chi.TSet',
                     'tesBed.iceTan.TOutSet',
                     'tesBed.TCHWSup.T',
                     'tesBed.TCHWRetCoi.T',
                     'tesBed.priPum.m_flow',
                     'tesBed.secPum.m_flow',
                     'tesBed.senRelPre.p_rel',
                     'tesBed.conAHU.TSupSet',
                     'tesBed.conAHU.TSup',
                     'tesBed.senSupFlo.V_flow',
                     'tesBed.conVAVCor.damVal.VDisSet_flow',
                     'tesBed.VSupCor_flow.V_flow',
                     'tesBed.conVAVSou.damVal.VDisSet_flow',
                     'tesBed.VSupSou_flow.V_flow',
                     'tesBed.conVAVEas.damVal.VDisSet_flow',
                     'tesBed.VSupEas_flow.V_flow',
                     'tesBed.conVAVNor.damVal.VDisSet_flow',
                     'tesBed.VSupNor_flow.V_flow',
                     'tesBed.conVAVWes.damVal.VDisSet_flow',
                     'tesBed.VSupWes_flow.V_flow',
                     'tesBed.conAHU.TZonCooSet',
                     'tesBed.conAHU.TZonHeaSet',
                     'tesBed.conVAVCor.TZon',
                     'tesBed.conVAVSou.TZon',
                     'tesBed.conVAVEas.TZon',
                     'tesBed.conVAVNor.TZon',
                     'tesBed.conVAVWes.TZon',
                     'tesBed.ave.y',
                     'tesBed.chi.P',
                     'tesBed.priPum.P',
                     'tesBed.secPum.P',
                     'tesBed.fanSup.P']

df_result = get_measurement(simResult, measurement_names)
df_result.to_csv('train_data_original.csv')


# Group by the interval of timestep (e.g., 1 hour) of the training dataset and pick the first row of each timestep 
df_result['time'] = (df_result['time'] // 3600) * 3600
#df_resampled = df_result.groupby('time').first() # pick the first row of each timestep 
df_resampled = df_result.groupby('time').last() # pick the last row of each timestep 
#df_resampled = df_result.groupby('time').mean() # aggregate with mean (Note: this method may not to correct, e.g., boolean values could be aggregated to be a non 0/1 values)

# If you want to have 'time_interval' as a column instead of an index, reset the index
df_resampled.reset_index(inplace=True)


# Format the 'time' column to a DateTimeIndex
# For example, '%m-%d %H:%M:%S' will give you the month-day hour:minute:second
df_resampled['formatted_time'] = pd.to_datetime(df_resampled['time'], unit='s', origin='unix')
df_resampled['formatted_time'] = df_resampled['formatted_time'].dt.strftime('%m-%d %H:%M')
# Insert 'formatted_time' as the second column (position 1 because of 0-indexing)
df_resampled.insert(1, 'formatted_time', df_resampled.pop('formatted_time'))


# save the dataset for training model
df_resampled.to_csv('train_data_1hr.csv')
print("\nDataset has been saved!")

# # Group by the interval of timestep (e.g., 15 minutes) and pick one row of each timestep 
# df_result['time'] = (df_result['time'] // 900) * 900
# #df_resampled = df_result.groupby('time').first() # pick the first row of each timestep 
# df_resampled = df_result.groupby('time').last() # pick the last row of each timestep 
# #df_resampled = df_result.groupby('time').mean() # aggregate with mean (Note: this method may not to correct, e.g., boolean values could be aggreated to be a non 0/1 values)

# # If you want to have 'time_interval' as a column instead of an index, reset the index
# df_resampled.reset_index(inplace=True)


# # Format the 'time' column to a DateTimeIndex
# # For example, '%m-%d %H:%M:%S' will give you the month-day hour:minute:second
# df_resampled['formatted_time'] = pd.to_datetime(df_resampled['time'], unit='s', origin='unix')
# df_resampled['formatted_time'] = df_resampled['formatted_time'].dt.strftime('%m-%d %H:%M')
# # Insert 'formatted_time' as the second column (position 1 because of 0-indexing)
# df_resampled.insert(1, 'formatted_time', df_resampled.pop('formatted_time'))


# # save the dataset for training model
# df_resampled.to_csv('train_data_15min.csv')
# print("\nDataset has been saved!")