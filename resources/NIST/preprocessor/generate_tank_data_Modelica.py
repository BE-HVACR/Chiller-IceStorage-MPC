# import from future to make Python2 behave like Python3
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals
from future import standard_library
standard_library.install_aliases()
from builtins import *
from io import open
# end of from future import

import pandas as pd
import os 

# get current directory
path = os.path.dirname(os.path.abspath(__file__))
par_path = os.path.join(path, os.pardir)
print(par_path)
# point to measurement location
mea_folder = 'measurement'
#mea_file = 'discharging-chiller-ice-day3.xlsx'
mea_file = 'charging-chiller2.xlsx'
mea_path = os.path.join(par_path,mea_folder,mea_file)
# read data
dat = pd.read_excel(mea_path,header=1)
print(dat)

tank_meas_names = ['Tank Inlet Temp [C]','Tank Oulet Temp [C]','Tank Flow Rate [kg/hr]','Ice Inventory [%]']
tank_meas = dat[tank_meas_names]
print(tank_meas)
print(len(tank_meas))

steps = len(tank_meas)
dt = 10.

outTable = 'charging-chiller2.txt'
if os.path.exists(outTable):
	os.remove(outTable)

f = open(outTable,'w')
f.writelines('#1 \n')
f.writelines('double tab('+str(steps)+',5)\n')
for i in range(steps):
	f.writelines(str(i*dt)+' '+str(tank_meas.loc[i,tank_meas_names[0]])+' '+str(tank_meas.loc[i,tank_meas_names[1]])+' '+str(tank_meas.loc[i,tank_meas_names[2]]/3600.)+' '+str(tank_meas.loc[i,tank_meas_names[3]]/100)+'\n')
f.close()
    