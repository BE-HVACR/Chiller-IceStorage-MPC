import pandas as pd
import scipy.interpolate as interpolate
import numpy as np


def interp(t_old,x_old,t_new,columns):
	intp = interpolate.interp1d(t_old, x_old, kind='linear')
	x_new = intp(t_new)
	x_new = pd.DataFrame(x_new, index=t_new, columns=columns)
	return x_new

ts = 207*24*3600.
te = ts + 2*24*3600.
dt = 60*5

dt_m = 60
t_m = np.arange(ts,te+1,dt_m)

df_orig = pd.read_csv('origin_data.csv',index_col=[0])
columns = df_orig.columns


t = df_orig.index
print t
df_interp = pd.DataFrame(index=t_m)
print df_interp


for column in columns:
    print column
    df = interp(t,df_orig[column].values, t_m, [column])
    df_interp[column] = df[column]

df_interp.to_csv('training_data.csv')