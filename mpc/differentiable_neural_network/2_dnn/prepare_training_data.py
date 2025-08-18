import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

data = pd.read_csv('../1_generate_training_data/train_data_1hr.csv',index_col=[0])
#data = pd.read_csv('../1_generate_training_data/train_data_5min.csv',index_col=[0])
## Data pre-processing
# add column of total power prediction
Ptot = np.round(data['tesBed.chi.P'] + data['tesBed.priPum.P'] + data['tesBed.secPum.P'] + data['tesBed.fanSup.P'], 2)
# Apply element-wise maximum with 0
Ptot = np.maximum(Ptot, 0)
data.insert(len(data.columns),"Ptot",Ptot.values)
data['tesBed.conVAVCor.TZon'] = data['tesBed.conVAVCor.TZon'] -273.15
data['tesBed.conVAVEas.TZon'] = data['tesBed.conVAVEas.TZon'] -273.15
data['tesBed.conVAVNor.TZon'] = data['tesBed.conVAVNor.TZon'] -273.15
data['tesBed.conVAVSou.TZon'] = data['tesBed.conVAVSou.TZon'] -273.15
data['tesBed.conVAVWes.TZon'] = data['tesBed.conVAVWes.TZon'] -273.15
data['tesBed.ave.y'] = data['tesBed.ave.y'] -273.15
data['tesBed.TOut.y'] = data['tesBed.TOut.y'] -273.15
data['tesBed.weaBus.TWetBul'] = data['tesBed.weaBus.TWetBul'] -273.15
data['tesBed.conAHU.TSup'] = data['tesBed.conAHU.TSup'] -273.15
print(data.head())

def shift_future_data(data,n_shift=1,varNam='Ptot'):
    '''Add future-n-step target data to the row
    '''
    data_nex = pd.DataFrame(data[varNam])
    for i in range(n_shift):
        data_nex[varNam+str('_nex')+str(i+1)] = data[varNam].values
        data_nex[varNam+str('_nex')+str(i+1)]=data_nex[varNam+str('_nex')+str(i+1)].shift(periods=-i-1).values
    data_nex=data_nex.drop(columns=[varNam])
    # add the shifted data to the dataset
    data = pd.concat([data,data_nex],axis=1)
    return data

def shift_historical_data(data,n_shift=4,varNam='Ptot'):
    '''Add future-n-step target data to the row
    '''
    data_his = pd.DataFrame(data[varNam])
    for i in range(n_shift):
        data_his[varNam+str('_his')+str(i+1)] = data[varNam].values
        data_his[varNam+str('_his')+str(i+1)]=data_his[varNam+str('_his')+str(i+1)].shift(periods=i+1).values
    data_his=data_his.drop(columns=[varNam])
    # add the shifted data to the dataset
    data = pd.concat([data,data_his],axis=1)
    return data

# prepare data to make sure each row inclues the features and target
data = shift_future_data(data,n_shift=1,varNam='Ptot')
data = shift_future_data(data,n_shift=1,varNam='tesBed.occSch.occupied')
data = shift_future_data(data,n_shift=1,varNam='tesBed.conVAVCor.TZon')
data = shift_future_data(data,n_shift=1,varNam='tesBed.conVAVSou.TZon')
data = shift_future_data(data,n_shift=1,varNam='tesBed.conVAVEas.TZon')
data = shift_future_data(data,n_shift=1,varNam='tesBed.conVAVNor.TZon')
data = shift_future_data(data,n_shift=1,varNam='tesBed.conVAVWes.TZon')
data = shift_future_data(data,n_shift=1,varNam='tesBed.conVAVCor.damVal.VDisSet_flow')
data = shift_future_data(data,n_shift=1,varNam='tesBed.conAHU.TSupSet')


data = shift_historical_data(data,n_shift=4,varNam='tesBed.conVAVCor.TZon')
data = shift_historical_data(data,n_shift=4,varNam='tesBed.conVAVSou.TZon')
data = shift_historical_data(data,n_shift=4,varNam='tesBed.conVAVEas.TZon')
data = shift_historical_data(data,n_shift=4,varNam='tesBed.conVAVNor.TZon')
data = shift_historical_data(data,n_shift=4,varNam='tesBed.conVAVWes.TZon')
data = shift_historical_data(data,n_shift=4,varNam='tesBed.ave.y')
data = shift_historical_data(data,n_shift=4,varNam='tesBed.TOut.y')
data = shift_historical_data(data,n_shift=4,varNam='tesBed.weaBus.TWetBul')
data = shift_historical_data(data,n_shift=4,varNam='tesBed.weaBus.relHum')
data = shift_historical_data(data,n_shift=4,varNam='tesBed.weaBus.HGloHor')
data = shift_historical_data(data,n_shift=4,varNam='tesBed.iceTan.SOC')
data = shift_historical_data(data,n_shift=4,varNam='Ptot')

# add step changes of certain varaibales
data['delta_SOC'] = data['tesBed.iceTan.SOC'] - data['tesBed.iceTan.SOC_his1']
data['delta_Power'] = data['Ptot'] - data['Ptot_his1']
data['delta_Tz_core'] = data['tesBed.conVAVCor.TZon'] - data['tesBed.conVAVCor.TZon_his1']
data['delta_Tz_south'] = data['tesBed.conVAVSou.TZon'] - data['tesBed.conVAVSou.TZon_his1']
data['delta_Tz_east'] = data['tesBed.conVAVEas.TZon'] - data['tesBed.conVAVEas.TZon_his1']
data['delta_Tz_north'] = data['tesBed.conVAVNor.TZon'] - data['tesBed.conVAVNor.TZon_his1']
data['delta_Tz_west'] = data['tesBed.conVAVWes.TZon'] - data['tesBed.conVAVWes.TZon_his1']
print(data.head())

# data for training is ready and saved
data.dropna(inplace=True)
data.to_csv('prepared_data_1hr.csv')
#data.to_csv('prepared_data_5min.csv')
print('==========training data is successfully saved!===============')
