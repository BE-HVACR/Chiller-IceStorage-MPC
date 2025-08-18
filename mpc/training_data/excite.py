
from pyfmi import load_fmu
import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import pandas as pd
import scipy.interpolate as interpolate
import numpy.random as random

## load fmu
model = "testbed.fmu"
fmu = load_fmu(model)

## generate excitation signal
# Operation mode: 
ope_low = 1
ope_hig = 5

# TCHWST
tchws_low = 273.15-8
tchws_high = 273.15 + 10

# TZone set
tzone_low = 273.15+20
tzone_hig = 273.15+28

# dpSecPumLoo
dpSec_low = 60000
dpSec_hig = 120000

## construct signal generator

def uniform(a,b):
    return (b-a)*random.random_sample()+a

def excite_ope(time):
    # hour index
    y = np.zeros(time.shape)
    j=0
    for i in time:
        h = int((i%86400)/3600)
        if h<6:
             y[j] = 5 # charging
        elif h<8:
            y[j] = 4 # discharging using chillers only
        elif h<19:
            y[j] = 3 # discharging using ice tank only
        else:
            y[j] = 5 # charging
        j+=1
    return y

def excite_tchws(time):
    y = np.zeros(time.shape)
    j = 0
    for i in time:
        h = int((i%86400)/3600)
        if h<6:
             y[j] = 273.15+uniform(-8,0) # charging
        elif h<8:
            y[j] = 273.15+uniform(0,10) # discharging using chillers only
        elif h<19:
            y[j] = 273.15+uniform(0,10) # discharging using ice tank only
        else:
            y[j] = 273.15+uniform(-8,0) # charging
        
        j+=1
    return y

def excite_tzone(time):
    y = np.zeros(time.shape)
    j=0
    for i in time:
        h = int((i%86400)/3600)
        if h<6:
             y[j] = 273.15+30 
        elif h<19:
            y[j] = 273.15+uniform(20,28)
        else:
            y[j] = 273.15+30

        j+=1
    return y

def excite_dpsec(time):
    y = np.zeros(time.shape)
    j=0
    for i in time:
        h = int((i%86400)/3600)
        if h<6:
             y[j] =0
        elif h<19:
            y[j] = 60000*uniform(1.,2.)
        else:
            y[j] = 0
        j+=1
    return y

## main simulation loop
ts = 207*24*3600.
te = ts + 2*24*3600.
dt = 60*5

# generate signal for every dt
time_arr = np.arange(ts,te+1,dt)
ope_sig = excite_ope(time_arr)
tchws_sig = excite_tchws(time_arr)
tzone_sig = excite_tzone(time_arr)
dpsec_sig = excite_dpsec(time_arr)


# make input_object for fmu
input_names = fmu.get_model_variables(causality=2).keys()
print input_names

input_trac = np.transpose(np.vstack((time_arr.flatten(),ope_sig.flatten(), dpsec_sig.flatten(), tchws_sig.flatten(), tzone_sig.flatten())))
input_object = (input_names,input_trac)

res = fmu.simulate(ts, te, input=input_object)

# plot 
# plot to see the signals
fig = plt.figure(figsize=(12,12))
fig.add_subplot(411)
plt.plot(time_arr, ope_sig, 'b-', linewidth=1)
plt.ylabel('operation status')
plt.ylim([-1,6])
plt.xticks(np.arange(ts,te,4*3600),[])

fig.add_subplot(412)
plt.plot(time_arr, tchws_sig-273.15, 'b-', linewidth=1)
plt.ylabel('TCHWS')
plt.ylim([-10,12])
plt.xticks(np.arange(ts,te,4*3600),[])

fig.add_subplot(413)
plt.plot(time_arr, tzone_sig-273.15, 'b-', linewidth=1)
plt.ylabel('TZone')
plt.ylim([18,32])
plt.xticks(np.arange(ts,te,4*3600),[])

fig.add_subplot(414)
plt.plot(time_arr, dpsec_sig, 'b-', linewidth=1)
plt.ylabel('dp CHW')
plt.ylim([0,150000])
plt.xticks(np.arange(ts,te,4*3600),np.arange(0,49,4))
plt.xlabel('Hours')

plt.savefig("signal.pdf")


# plot to see system responses
t = res['time']
ice_mod = res['iceTank.stoCon.y']
dpCHWS = res['senRelPre.p_rel']
TCHWSChi = res['chi.TEvaLvg']
TZone_cor = res['conVAVCor.TZon']
TZone_sou = res['conVAVSou.TZon']
TZone_eas = res['conVAVEas.TZon']
TZone_nor = res['conVAVNor.TZon']
TZone_wes = res['conVAVWes.TZon']
TZone_set = res['TZonCooSet']
soc = res['iceTank.SOC']
T_oa = res['TOut.y']
pow_chi = res['chi.P']
pow_priPum = res['priPum.P']
pow_secPum = res['secPum.P']
pow_fan = res['fanSup.P']
pow_tot = pow_chi + pow_priPum + pow_secPum + pow_fan
T_sa = res['TSup.T']
dpSA = res['dpDisSupFan.p_rel']

# export data out for training MPC models
# interpolate at every minutes
dt_m = 60
t_m = np.arange(ts,te+1,dt_m)

df_orig = pd.DataFrame({'ice_mode':ice_mod,
                        'dpCHWS':dpCHWS,
                        'TCHWSChi':TCHWSChi-273.15,
                        'TZone_cor':TZone_cor-273.15,
                        'TZone_sou':TZone_sou-273.15,
                        'TZone_eas':TZone_eas-273.15,
                        'TZone_nor':TZone_nor-273.15,
                        'TZone_wes':TZone_wes-273.15,
                        'TZone_set':TZone_set-273.15,
                        'T_oa':T_oa-273.15,
                        'dpSA':dpSA,
                        'soc':soc,
                        'T_sa':T_sa-273.15,
                        'power':pow_tot},index=t)
columns = df_orig.columns
print df_orig 
df_orig.to_csv('origin_data.csv')

def interp(t_old,x_old,t_new,columns):
	intp = interpolate.interp1d(t_old, x_old, kind='linear')
	x_new = intp(t_new)
	x_new = pd.DataFrame(x_new, index=t_new, columns=columns)
	return x_new

df_interp = pd.DataFrame(index=t_m)
for column in columns:
    print column
    df = interp(t,df_orig[column].values, t_m, [column])
    df_interp[column] = df[column]

df_interp.to_csv('training_data.csv')