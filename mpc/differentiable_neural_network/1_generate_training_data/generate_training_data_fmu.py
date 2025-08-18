"""
this script is to test the simulation of compiled fmu
"""
# import numerical package
#from pymodelica import compile_fmu
from pyfmi import load_fmu
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import numpy as np
import numpy.random as random
import pandas as pd


# simulate setup - 181-212 for July; 212-243 for August
time_stop = 1*24*3600.  
ts = 212*24*3600. + 0*3600.
te = ts + time_stop

## load fmu
fmu_name = "VirtualTestbed_NISTChillerTestbed_DemandFlexibilityInvestigation_FakeSystem_SystemForMPC_02bInputs.fmu"
fmu = load_fmu(fmu_name)
#fmu.setup_experiment(start_time = ts, stop_time=te)
# options = fmu.simulate_options()
# options['ncp'] = 60*24 # 
# options['initialize'] = True
fmu.set_log_level(3)
options = {'initialize': True,
           'ncp':int(60*24), # number of output points, need to be integer
           'result_handling': "memory",            
           'silent_mode':False}

# excite signal: - generator for exciting signals:bi,bc, Tchi,
def uniform(a,b):
    return (b-a)*random.random_sample()+a

def excite_boolean(time):
    y = np.zeros(time.shape, dtype=int)
    j = 0
    for i in time:
    #     h = int((i%86400)/3600)
    #     if h<4:
    #         y[j] = 1
    #     elif h<6:
    #         y[j] = 0
    #     elif h<19:
        y[j] = np.random.randint(0,2) # left number (inclusive) and right number (exclusive)
    #     else:
    #         y[j] = 1
        j+=1
    return y

# generate signal for every dt
dt = 15*60. # 1 hour
time_arr = np.arange(ts,te+1,dt)
bc_sig1 = excite_boolean(time_arr)
bi_sig2 = excite_boolean(time_arr)
#spe_sig2 = excite_TCHWSupSet(time_arr)

#Reform the time-series data
tim_inserted = [0]*len(time_arr)
for i in range(len(time_arr)):
    tim_inserted[i] = time_arr[i]+dt-10
for i in range(len(time_arr)):
    time_arr=np.insert(time_arr,2*i+1,tim_inserted[i])
print('time_arr_inserted:',time_arr)
sig1_inserted = [0]*len(bc_sig1)
for i in range(len(bc_sig1)):
    sig1_inserted[i] = bc_sig1[i]
for i in range(len(bc_sig1)):
    bc_sig1=np.insert(bc_sig1,2*i+1,sig1_inserted[i])
print('bc_sig1_inserted:',bc_sig1)

sig2_inserted = [0]*len(bi_sig2)
for i in range(len(bi_sig2)):
    sig2_inserted[i] = bi_sig2[i]
for i in range(len(bi_sig2)):
    bi_sig2=np.insert(bi_sig2,2*i+1,sig2_inserted[i])
print('bi_sig2_inserted:',bi_sig2)


# input
input_names = list(fmu.get_model_variables(causality=2).keys()) # ??
print("input variable names:",input_names)

#time_arr = time_arr.astype(int)
input_trac = np.transpose(np.vstack((time_arr.flatten(),bc_sig1.flatten(),bi_sig2.flatten())))
input_object = (input_names,input_trac)

# simulate fmu
res = fmu.simulate(start_time=ts,
                    final_time=te, 
                    options=options,
                    input = input_object)

# what data do we need
tim = res['time']
hour = [0]*len(tim)
for i in range(len(tim)):
    hour[i] = (tim[i] % 86400)/3600 # hour index 0~23
occupied = res['occSch.occupied']
mod = res['modCon.y']
Vahu = res['senSupFlo.V_flow']
TahuSup = res['TSup.T']
TChiSet = res['chi.TSet']
TiceTanSet = res['iceTan.TOutSet']
TCHWSup = res['TCHWSup.T']
TCHWRetCoi = res['TCHWRetCoi.T']
TZonCor = res['conVAVCor.TZon']
TZonSou = res['conVAVSou.TZon']
TZonEas = res['conVAVEas.TZon']
TZonNor = res['conVAVNor.TZon']
TZonWes = res['conVAVWes.TZon']
TZonAvg = (res['conVAVCor.TZon']+res['conVAVSou.TZon']+res['conVAVEas.TZon']+res['conVAVNor.TZon']+ res['conVAVWes.TZon'])/5
SOC = res['iceTan.SOC']
Toa = res['TOut.y']
Toawet = res['weaBus.TWetBul']
chiOn = res['chi.on']
iceTanMod = res['iceTan.stoCon.y']
PTot = abs(res['chi.P'])+abs(res['priPum.P'])+abs(res['secPum.P'])+abs(res['fanSup.P'])
Pchi = res['chi.P']
PpriPum = res['priPum.P']
PsecPum = res['secPum.P']
Pfan = res['fanSup.P']


# interpolate data
train_data = pd.DataFrame({'T_zone_core':np.array(TZonCor),
                            'T_zone_South':np.array(TZonSou),
                            'T_zone_East':np.array(TZonEas),
                            'T_zone_North':np.array(TZonNor),
                            'T_zone_West':np.array(TZonWes),
                            'T_zone_avg':np.array(TZonAvg),
                            'State_of_charge':np.array(SOC),
                            'T_oa':np.array(Toa),
                            'T_oawet':np.array(Toawet),
                            'P_tot':np.array(PTot),
                            'P_chi':np.array(Pchi),
                            'P_priPum':np.array(PpriPum),
                            'P_secPum':np.array(PsecPum),
                            'P_fan':np.array(Pfan),
                            'chiOn':np.array(chiOn),
                            'iceTanMod':np.array(iceTanMod),
                            'mod':np.array(mod),
                            'Vahu':np.array(Vahu),
                            'TahuSup':np.array(TahuSup),
                            'TChiSet':np.array(TChiSet),
                            'TiceTanSet':np.array(TiceTanSet),
                            'TCHWSup':np.array(TCHWSup),
                            'TCHWRetCoi':np.array(TCHWRetCoi),
                            'occupied':np.array(occupied),
                            'hour':np.array(hour)}, index=tim)

def interp(df, new_index):
    """Return a new DataFrame with all columns values interpolated
    to the new_index values."""
    df_out = pd.DataFrame(index=new_index)
    df_out.index.name = df.index.name

    for colname, col in df.iteritems():
        df_out[colname] = np.interp(new_index, df.index, col)

    return df_out

train_data.to_csv('train_data_fmu_original.csv')

#interpolate one minute data
train_data_tim = np.arange(ts,te+1,60) 
train_data = interp(train_data, train_data_tim)
#average every 15 minutes
train_data_15 = train_data.groupby(train_data.index//900).mean()
train_data_15.to_csv('train_data_fmu_15min.csv')

# # set mean values for each control horizon N/A!!!
# #train_data_groupmean = train_data.groupby(['b_c','b_i','T_chi','T_iceTan'],sort=False).mean().reset_index()
# #train_data_groupmean.to_csv('train_data_mean_Power.csv')
# train_data_groupmean = train_data.groupby(['reaMod','TCHWSupSet'],sort=False).mean().reset_index() # 'mod'
# train_data_groupmean.to_csv('train_data_4_mean.csv')

# clean folder after simulation
def deleteFiles(fileList):
    """ Deletes the output files of the simulator.

    :param fileList: List of files to be deleted.

    """
    import os

    for fil in fileList:
        try:
            if os.path.exists(fil):
                os.remove(fil)
        except OSError as e:
            print ("Failed to delete '" + fil + "' : " + e.strerror)


# filelist = [fmu_name+'_result.mat', fmu_name+'_log.txt']
# deleteFiles(filelist)
