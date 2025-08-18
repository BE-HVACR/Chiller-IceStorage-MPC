import os
import numpy as np
import pandas as pd
from pyfmi import load_fmu
from scipy.optimize import differential_evolution
from scipy.optimize import LinearConstraint, Bounds
import time
 
 
def objective_function(x):
    model.reset()
    if current_time!= start_time:
        model.initialize()
        model.set_fmu_state(FMU_state)    
    i = 0    
    while i < PH:          
        Tlb = x[i]
        Tub = Tlb + deltaT   # assume upper limit is always 4 degree C higher than the lower limit    
       
        model.set('Tlb', Tlb)
        model.set('Tub', Tub)        
 
        options = {'initialize': (current_time==start_time)&(i==0),
                   'ncp':int(step_size/60),
                   'result_handling': "memory",
                   'filter': 'ETot.y',              
                   'silent_mode':True,
                  }
       
        res = model.simulate(start_time = current_time + i*step_size ,
                             final_time = current_time + (i+1)*step_size,                      
                             options = options)        
        i += 1
 
    # clear the log file
    # log_file_path = fmu_name.replace(".fmu", "_log.txt")
    # if os.path.exists(log_file_path):
    #     with open(log_file_path, 'w') as file:
    #         # file.write('')    
    #         file.truncate(0)
   
    return res['ETot.y'][-1]
 
 
 
if __name__ == "__main__":
    np.random.seed(0)        
    # define file name and location
    folder_path = r"D:\Dymola\Optimization"
    fmu_name = "DHP_Optimization_TestCases_Sys2Pipe2D_0CT.fmu"
    # fmu_name = "DHP_Optimization_TestCases_Sys2Pipe2D.fmu"    
    fmu_path = os.path.join(folder_path,fmu_name)
 
    start_time = 3600*24*197  #The start time.
    end_time   = start_time + 3600*24 #The final simulation time.
    step_size = 3600 # Define your own step size, unit is second, 300s = 5min
 
    # define prediction horizon and control horizon
    PH = 1 # prediction horizon
    CH = 1 # control horizon
 
    # load fmu
    model = load_fmu(fmu_path, kind='cs',
                     log_file_name = fmu_path.replace(".fmu", "_S"+str(start_time)+"_E"+str(end_time)+"_PH"+str(PH)+"_log_tmp.txt"),
                     log_level=2)
    model_opt = load_fmu(fmu_path,
                         kind='cs',
                         log_file_name = fmu_path.replace(".fmu", "_S"+str(start_time)+"_E"+str(end_time)+"_PH"+str(PH)+"_log_opt.txt"),
                         log_level=2)
 
 
    # define the bounds
    Tmax = 36 + 273.15
    Tmin = 6 + 273.15  
 
    deltaT = 4
 
    bounds = [(Tmin, Tmax)]*PH
 
    Tub_list = []
    Tlb_list = []
 
    # define the output variables
    variable_list = ['time',
                     'Tub','Tlb',
                     'TAMean', 'TBMean',
                     'm_flow_sum','plant.yMod',
                     'TMax.y','TMin.y',
                     'PTot.y','ETot.y',
                     'PSub.y','ESub.y',
                     'plant.heaPumCoo.P','plant.heaPumHea.P',
                    #  'plant.tow.P',
                     'plant.fanCoo.P','plant.fanHea.P',                      
                    ]
    # Initialize a dictionary to store results
    results_dict_opt = {key: [] for key in variable_list}
 
    current_time = start_time
 
    t0 = time.process_time()
 
    while current_time < end_time:  
        tic = time.process_time()  
       
        # Run differential evolution optimization to minimize objective_function
        result = differential_evolution(objective_function, bounds)    
 
        # Extract optimized Tlb and  Tub
        # actually this should be related to CH?
        Tlb_opt = result.x[0]
        Tub_opt = Tlb_opt + deltaT
 
        Tlb_list.append(Tlb_opt)
        Tub_list.append(Tub_opt)
       
#         model_opt.reset()
        model_opt.set('Tlb', Tlb_list[-1])
        model_opt.set('Tub', Tub_list[-1])  
 
        options = {'initialize': current_time == start_time,
                   'ncp':int(step_size/60),
                   'result_handling':"memory",
                   'filter': variable_list,
                   'silent_mode':False              
              }
       
        res_opt = model_opt.simulate(start_time=current_time,
                                     final_time=current_time + step_size*CH,
                                     options=options
                                    )
        # Append results to the corresponding list in the dictionary
        for key in variable_list:
            results_dict_opt[key].extend(res_opt[key])
 
        FMU_state = model_opt.get_fmu_state()
 
        toc = time.process_time()
 
        print ("Current time:" + str(current_time) + ' takes:' + str(toc-tic)+" second(s)")
       
        current_time += step_size*CH
 
    print ('Finish optimization in:' + str(toc-t0)+" second(s)")
    results_df_opt = pd.DataFrame(results_dict_opt)
    print('Total energy use:', results_df_opt['ETot.y'].iloc[-1]*2.77778e-10)
    # results_df_opt.to_csv(fmu_path.replace(".fmu", "_S"+str(start_time)+"_E"+str(end_time)+"_PH"+str(PH)+".csv"))
    results_df_opt.to_csv(fmu_path.replace(".fmu", "_S"+str(start_time)+"_E"+str(end_time)+"_PH"+str(PH)+"_CH"+str(step_size)+".csv"))
 
    # Terminate the model
    model.terminate() # This is important, otherwise the FMU will keep running in the background
    model_opt.terminate() # This is important, otherwise the FMU will keep running in the background