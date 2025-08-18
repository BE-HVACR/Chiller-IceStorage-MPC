'''
Using true model (fmu) for MPC controller
Using Pybobyqa package for continuous variable optimization problem
'''

import pybobyqa
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import json
import os
from pyfmi import load_fmu
from datetime import datetime


class PerfectMPC(object):
    def __init__(self, 
                PH,
                CH,
                time,
                ts,
                dt,
                fmu_model, 
                fmu_generator="dymola",
                measurement_names = [],
                control_names = [],
                uncontrollable_names = [],
                price = [],
                u_lb = [],
                u_ub = [],
                u_start = []):
        # MPC settings
        self.PH = PH 
        self.CH = CH
        self.dt = dt 
        self.time = time
        self.ts = ts
        #self.control_name_order = control_name_order

        # MPC models
        self.fmu_model = fmu_model
        self.fmu_generator = fmu_generator
        self.fmu_output_names = measurement_names
        self._fmu_results = [] # store intermediate fmu results during optimization
        self.fmu_options = self.fmu_model.simulate_options()
        self.fmu_options["result_handling"] = "memory"
        #self.fmu_options["filter"] = self.fmu_output_names
        self.fmu_options["ncp"] = int(self.dt/60.)
        self.fmu_options["silent_mode"] = False

        # define fmu model inputs for optimization: here we assume we only optimize control inputs (time-varying variabels in Modelica instead of parameter)
        self.fmu_input_names = control_names
        self.fmu_uncontrollable_names = uncontrollable_names
        self.ni = len(control_names)

        # some building settings
        self.occ_start = 6
        self.occ_end = 19

        # predictors
        self.price = price

        # control input bounds
        self.u_lb = u_lb
        self.u_ub = u_ub
        self.u_start = u_start

        # mpc tuning
        self.weights = [100., 2500., 0., 0.] # energy cost, temperature, du, uSet
        #self.u0 = self.u_lb*self.PH
        self.u0 = self.u_start*self.PH
        self.u_ch_prev = self.u_start*self.PH

        # optimizer settings
        self.global_solution = False # require global solution if true. usually need more running time.


    def get_fmu_states(self):
        """ Return fmu states as a hash table"""

        return self._get_fmu_states()
    
    def _get_fmu_states(self):
        states = {}
        if self.fmu_generator == "jmodelica":
            names = self.fmu_model.get_states_list()
            for name in names:
                states[name] = float(self.fmu_model.get(name))               
        elif self.fmu_generator == "dymola":
            states = self.fmu_model.get_fmu_state()
        else:
            ValueError("FMU Generator not supported")
            
        return states

    def set_mpc_states(self, states):
        self._states_ = states

    def set_fmu_states(self, states):
        """ Set fmu states"""
        self._set_fmu_states(states)

    def _set_fmu_states(self, states):
        if self.fmu_generator == "jmodelica":
            for name in states.keys():
                self.fmu_model.set(name, states[name])
        elif self.fmu_generator == "dymola":
            self.fmu_model.set_fmu_state(states)
            
    def set_time(self, time):
        self.set_fmu_time(time)
        self.set_mpc_time(time)

    def set_fmu_time(self, time):
        self.fmu_model.time = float(time)

    def set_mpc_time(self, time):
        self.time = time

    def initialize_fmu(self):
        self.fmu_model.setup_experiment(start_time = self.time)
        self.fmu_model.initialize()
        #self.fmu_options['initialize'] = False

    def reset_fmu(self):
        """
        reset fmu and options
        """
        if self.fmu_generator == "jmodelica":
            self.fmu_model.reset()
        if self.fmu_generator == "dymola":
            self.fmu_model.reset()
        self.fmu_model.time = self.time

    def simulate(self, start_time, final_time, input = None, states={}):
        """ simulate fmu from given states"""
        if states:
            self.set_fmu_states(states)

        # call simulate()    
        self._fmu_results = self.fmu_model.simulate(start_time=start_time, final_time=final_time, input=input, options=self.fmu_options)
        print("\nself.fmu_options:",self.fmu_options)
         
        # return states and measurments
        states_next = self.get_fmu_states()
        outputs = self.get_fmu_outputs()

        return states_next, outputs

    def get_fmu_outputs(self):
        """ Get fmu outputs as dataframe for the objective function calculation"""
        outputs_dict = {}
        for output_name in self.fmu_output_names:
            outputs_dict[output_name] = self._fmu_results[output_name]

        time = self._fmu_results['time']
        outputs = pd.DataFrame(outputs_dict, index=time)

        return outputs

    def optimize(self):
        """ The optimization follows the following procedures:
            1. initialize fmu model and save initial states
            2. call optimizer to optimize the objective function and return optimal control inputs
            3. apply control inputs for next step, and return states and measurements
            4. recursively do step 2 and step 3 until the end time
        """
        #u0 = self.u0 
        u0 = [0.5,0.5]*self.PH
        lower = self.u_lb*self.PH 
        upper =self.u_ub*self.PH 

        soln = pybobyqa.solve(self.objective, u0, maxfun=1000, bounds=(
                lower, upper), seek_global_minimum=False, print_progress=True, \
                scaling_within_bounds=True)

        return soln

    def objective(self, u):
        """ return objective values at a prediction horizon
            
            1. transfer control variables generated from optimizer to fmu inputs
            2. call simulate() and return key measurements
            3. calculate and return MPC objective based on key measurements
        """
        print("\nobjective_u",u)
        # fetch simulation settings
        ts = self.time 
        te = self.time + self.PH*self.dt
        ini_reset = False
        if self.fmu_generator == "dymola":
            # self.fmu_model.reset()
            self.fmu_model.setup_experiment(start_time = 212*24*3600.+3*24*3600.+0*3600., stop_time=212*24*3600.+3*24*3600.+24*3600.)
            if ts == 212*24*3600.+3*24*3600.+0*3600.:
                self.fmu_model.reset()
                #self.fmu_model.setup_experiment(start_time = ts, stop_time=te)
                #self.fmu_model.initialize()
                self.set_fmu_states(self._states_)
                #self.fmu_options['initialize'] = False
                ini_reset = True
            else:
                self.fmu_model.reset()
                #self.fmu_model.setup_experiment(start_time = ts, stop_time=te)
                #self.fmu_model.initialize()
                self.set_fmu_states(self._states_)
                #self.fmu_options['initialize'] = False
                ini_reset = True
            #self.fmu_model.time = ts   # need to check if this is also true for jmodelica
        
        # transfer inputs
        input_object = self._transfer_inputs(u, piecewise_constant=True)
        #print("\ninput_object:",input_object)
        
        #_, outputs = self.simulate(ts, te, input=input_object, states=self._states_)
        #_, outputs = self.simulate(ts, te, input=input_object)
        outputs = pd.DataFrame()
        start_time=ts

        for i in range(self.PH):
            options = {'initialize': ini_reset&(i==0),
                        'ncp':int(self.dt/60),
                        'result_handling': "memory",            
                        'silent_mode':False}
            print("\noptions:",options)
            # set inputs for fmu model
            self.fmu_model.set('bc',u[0+i*2])
            self.fmu_model.set('bi',u[1+i*2])
            # call simulate()    
            self._fmu_results = self.fmu_model.simulate(start_time=start_time, final_time=start_time+self.dt, options=options) #self.fmu_options
            #print("\nself.fmu_options:",self.fmu_options)
            # return measurments
            output_i = self.get_fmu_outputs()
            if outputs.empty:
                outputs = pd.concat([outputs, output_i], axis=0)
            else:
                # Skip the first row of output_i if it matches the last row of output_i-1
                outputs = pd.concat([outputs, output_i.iloc[1:]], axis=0)      
            # update time clock
            start_time += self.dt
        
        # interpolate outputs as 1 min data and CH (e.g., 1-hour) average
        t_intp = np.arange(ts, te, 60)
        outputs = self._sample(self._interpolate(outputs, t_intp), self.dt)

        # post processing the results to calculate objective terms
        energy_cost = self._calculate_energy_cost(outputs)
        temp_violations = self._calculate_temperature_violation(outputs)
        action_changes = self._calculate_action_changes(u)
        uSet_violations = self._calculate_uSet_violation(outputs)
        #print(energy_cost)
        #print(temp_violations)
        #print(action_changes)
        '''
        objective = [-self.weights[0]*energy_cost[i] + \
                     self.weights[1]*temp_violations[i]*temp_violations[i] +
                     self.weights[2]*action_changes[i]*action_changes[i] for i in range(self.PH)]
        '''
        
        term_energy = 0
        term_temp = 0
        term_du = 0
        term_uSet = 0
        
        for i in range(self.PH):
            term_energy += self.weights[0]*energy_cost[i]
            
            term_temp += self.weights[1]*(temp_violations[0][i]**2 +
                                          temp_violations[1][i]**2 +
                                          temp_violations[2][i]**2 +
                                          temp_violations[3][i]**2 +
                                          temp_violations[4][i]**2) 
            if ts == self.ts:
                pass
            else:
                term_uSet += self.weights[3]*(uSet_violations[i]**2)
            
        for i in range(self.ni*self.PH):
            term_du += self.weights[2]*action_changes[i]**2

        print("\nterm_energy:",term_energy)
        print("\nterm_temp:",term_temp)
        print("\nterm_du:",term_du)
        print("\nterm_uSet:",term_uSet)
        objective = term_energy + term_temp + term_du + term_uSet
        '''
        objective = [self.weights[0]*energy_cost[i] + 
                     self.weights[1]*(temp_violations[0][i]*temp_violations[0][i] +
                                      temp_violations[1][i]*temp_violations[1][i] +
                                      temp_violations[2][i]*temp_violations[2][i] +
                                      temp_violations[3][i]*temp_violations[3][i] +
                                      temp_violations[4][i]*temp_violations[4][i])+
                     self.weights[2]*action_changes[i]*action_changes[i] for i in range(self.PH)]
        '''
        print("\nobjective:",objective)
        
        return(objective)

    def _interpolate(self, df, new_index):
        """Interpolate a dataframe along its index based on a new index
        """
        df_out = pd.DataFrame(index=new_index)
        df_out.index.name = df.index.name
        
        for col_name, col in df.items():
            df_out[col_name] = np.interp(new_index, df.index, col)
        return df_out
    
    def _sample(self, df, freq):
        """ 
            assume df is interpolated at 1-min interval
        """
        index_sampled = np.arange(df.index[0], df.index[-1]+1, freq)
        df_sampled = df.groupby(df.index//freq).mean()
        df_sampled.index = index_sampled

        return df_sampled

    def _calculate_energy_cost(self, outputs):
        price = self.price # 24-hour prices
        t = outputs.index
        pow_list = ['chi.P',
                    'priPum.P',
                    'secPum.P',
                    'fanSup.P']
        
        power = np.zeros(len(t))
        for p in pow_list:
            power += np.array(outputs[p])

        energy_cost = []
        #for ti in t:
        for i, ti in enumerate(t):
            h_index = int(ti % 86400/3600)
            energy_cost.append(max(0., power[i]/1000*price[h_index]*self.dt/3600.))

        return energy_cost

    def _calculate_temperature_violation(self, outputs):
        # define nonlinear temperature constraints
        # zone temperature bounds - need check with the high-fidelty model
        T_upper = [30.0 for i in range(24)]
        T_upper[self.occ_start:self.occ_end] = [24.2]*(self.occ_end-self.occ_start)
        T_lower = [12.0 for i in range(24)]
        T_lower[self.occ_start:self.occ_end] = [12.]*(self.occ_end-self.occ_start) # 23.

        # zone temperarture
        t = outputs.index
        
        zone_temp_list = ['conVAVCor.TZon',
                          'conVAVSou.TZon',
                          'conVAVEas.TZon',
                          'conVAVNor.TZon',
                          'conVAVWes.TZon']
        temp = []
        for zone_temp in zone_temp_list:
            temp_z = np.array(outputs[zone_temp])-273.15
            temp.append(temp_z.tolist())
        #print("\ntemp:",temp)
        
        violations = []
        for z in range(len(zone_temp_list)):
            overshoot = []
            undershoot = []
            violations_z = []
            
            for i, ti in enumerate(t):
                h_index = int(ti % 86400/3600)
                overshoot.append(max(temp[z][i] - T_upper[h_index], 0.0))
                undershoot.append(max(T_lower[h_index] - temp[z][i], 0.0))
                violations_z.append(overshoot[i]+undershoot[i])
                
            violations.append(violations_z)
        #print("\ntemp_violation:",violations)
            
        return violations
    
    def _calculate_action_changes(self, u):
        # # of inputs
        ni = self.ni
        # get bounds
        u_lb = self.u_lb
        u_ub = self.u_ub
        u_ch_prev = self.u_ch_prev

        du_nomalizer = [1./(u_ub[i] - u_lb[i]) for i in range(len(u_lb))]*self.PH
        
        du = []
        for i in range(self.PH):
            ui = u[i*ni:ni*(i+1)]
            dui_nomalizer = du_nomalizer[i*ni:ni*(i+1)]
            dui = [abs(ui[j] - u_ch_prev[j])*dui_nomalizer[j] for j in range(ni)] 
            u_ch_prev = ui
            du += dui

        return du
    
    def _calculate_uSet_violation(self, outputs):
        # measured supply air temperarture and its setpoint
        t = outputs.index
        meas = outputs['TSup.T'] - 273.15  
        setpoint = outputs['conAHU.TSupSet'] - 273.15  
        
        # define nonlinear temperature constraints
        # supply air temperature should follow its setpoint within 10% bounds
        bound = 0.2
        uFollow_upper = [35 for i in range(24)]
        uFollow_lower = [0 for i in range(24)]
        
        # calculate violations
        overshoot = []
        undershoot = []
        violations = []
        
        for i, ti in enumerate(t):
            h_index = int(ti % 86400/3600)
        
            uFollow_upper[h_index] = setpoint[ti] + bound
            uFollow_lower[h_index] = setpoint[ti] - bound
            
            overshoot.append(max(meas[ti] - uFollow_upper[h_index], 0.0))
            undershoot.append(max(uFollow_lower[h_index] - meas[ti], 0.0))
            violations.append(overshoot[i]+undershoot[i])
        #print("\nuSet_violation:",violations)
        
        return violations
    
    def _transfer_inputs(self, u, piecewise_constant=False):
        """
        transfer optimizier outputs to fmu input objects
        :param u: optimization vectors from optimizer
        :type u: numpy.array or list
        """
        nu = len(u)
        ni = self.ni

        if nu != self.PH*ni:
            ValueError("The number of optimization variables are not equal to the number of control inputs !!!")
        
        ts = self.time 
        te = ts + self.PH*self.dt 
        u_trans = []
        t = np.arange(ts, te+1, self.dt).tolist()

        for i, input_name in enumerate(self.fmu_input_names):
            u_trans.append([u[(i+h*ni)]for h in range(self.PH)])

        t_input = t[:-1]

        # if need piecewise constant inputs instead of linear inpterpolation as default
        if piecewise_constant:
            t_piecewise = []
            # get piecewise constant time index
            for i, ti in enumerate(t[:-1]):
                t_piecewise += t[i:i+2]
            # get piecewise constant control input signals between steps
            u_trans_piecewise = []
            for j in u_trans:
                u_trans_j = []
                for i in range(len(j)):
                    u_trans_j += [j[i]]*2
                u_trans_piecewise.append(u_trans_j)

            t_input = t_piecewise
            u_trans = u_trans_piecewise
        # generate input object for fmu
        input_traj = np.transpose(np.vstack((t_input, u_trans)))
        input_object = (self.fmu_input_names, input_traj)
        
        return input_object

    def set_u0(self, u_ph_prev):
        """ set initial guess for the optimization at current step """
        self.u0 = list(u_ph_prev[self.ni:]) + self.u_lb
        #self.u0 = u_ph_prev

    def set_u_ch_prev(self, u_ch_prev):
        """save actions at previous step """
        self.u_ch_prev = u_ch_prev
        
if __name__ == "__main__":
    ## load Modelica model - VAV system virtual teatbed
    model = load_fmu('VirtualTestbed_NISTChillerTestbed_DemandFlexibilityInvestigation_FakeSystem_SystemForMPC_02bInputs_0RealtoBool.fmu',
                      log_file_name = 'optimization_model_log.txt', 
                      kind='CS', log_level=3) # Enable logging for more information; kind='CS' means co-simulation
    virtual_building = load_fmu('VirtualTestbed_NISTChillerTestbed_DemandFlexibilityInvestigation_FakeSystem_SystemForMPC_02bInputs_0RealtoBool.fmu',
                      log_file_name = 'virtual_building_log.txt', 
                      kind='CS', log_level=3)
    # states_names = model.get_states_list()
    # states = [float(model.get(state)) for state in states_names]
    #print("\ninitial states from fmu:", states)
    np.random.seed(100)
    PH = 1
    CH = 1
    dt = 4*15*60.
    ts = 212*24*3600.+3*24*3600.+0*3600.
    period = 24*60*60.  
    te = ts + period

    price = [0.0640, 0.0640, 0.0640, 0.0640,
             0.0640, 0.0640, 0.0640, 0.0640,
             0.1391, 0.1391, 0.1391, 0.1391,
             0.3548, 0.3548, 0.3548, 0.3548,
             0.3548, 0.3548, 0.1391, 0.1391,
             0.1391, 0.1391, 0.1391, 0.0640]

    measurement_names = ['occSch.occupied',
                         'modCon.y',
                         'senSupFlo.V_flow',
                         'TSup.T',
                         'conAHU.TSupSet',
                         'chi.TSet',
                         'iceTan.TOutSet',
                         'TCHWSup.T',
                         'TCHWRetCoi.T',
                         'conVAVCor.TZon',
                         'conVAVSou.TZon',
                         'conVAVEas.TZon',
                         'conVAVNor.TZon',
                         'conVAVWes.TZon',
                         'iceTan.SOC',
                         'TOut.y',
                         'weaBus.TWetBul',
                         'chi.on',
                         'iceTan.stoCon.y',
                         'chi.P',
                         'priPum.P',
                         'secPum.P',
                         'fanSup.P']
    
    inputs = ['bc', 'bi']

    control_names = []
    active_names = []
    for name in inputs:
        if name.endswith('_activate'):
            active_names.append(name)
        else:
            control_names.append(name)

    uncontrollable_names = []
    output_names = measurement_names + uncontrollable_names
    
    u_lb = [0.4, 0.4]
    u_ub = [0.6, 0.6]
    u_start = [0.5, 0.5]

    mpc = PerfectMPC(PH = PH,
                    CH = CH,
                    time = ts,
                    ts = ts,
                    dt = dt,
                    fmu_model = model, 
                    fmu_generator="dymola",
                    measurement_names = measurement_names + uncontrollable_names,
                    control_names = control_names,
                    uncontrollable_names = uncontrollable_names,
                    price = price,
                    u_lb = u_lb,
                    u_ub = u_ub,
                    u_start = u_start)
    
    """
    states0 = mpc.get_fmu_states()
    mpc.set_fmu_time(ts)
    mpc.set_fmu_states(states0)
    print(mpc.fmu_model.time)
    _, out = mpc.simulate(ts, ts+60.)
    print(mpc.fmu_model.time)
    print(out.tail())
    mpc.fmu_options['initialize'] = False 
    #mpc.fmu_model.setup_experiment(start_time=ts)
    #mpc.fmu_model.initialize()
    mpc.set_fmu_time(ts)
    mpc.set_fmu_states(states0)
    print(mpc.fmu_model.time)
    _, out = mpc.simulate(ts, ts+60.)
    print(mpc.fmu_model.time)
    print(out)
    """
   
    virtual_building_options={'ncp':int(dt/60),
                              'result_handling':"memory",
                              'filter': output_names,
                              'silent_mode':False,
                              'initialize':True} # initialize virtual building at the start time and then False #virtual_building.initialize()

    states = mpc.get_fmu_states()

    results = pd.DataFrame()
    u_opt = []
    t_opt = []

    t = ts
    while t < te:
        # set starting states
        mpc.set_time(t)
        mpc.set_mpc_states(states)   #self._states_ = states
        
        opt_start_time = datetime.now()
        # start MPC optimization
        print('\nstart MPC optimization:')
        optimum = mpc.optimize()

        # calculate optimization execution time
        opt_end_time = datetime.now()
        opt_elapsed_time = opt_end_time - opt_start_time
        hours, remainder = divmod(opt_elapsed_time.seconds, 3600)
        minutes, seconds = divmod(remainder, 60)
        print("============================================================================================================")
        print(f"Optimization execution time for single time step: {hours} hours, {minutes} minutes, {seconds} seconds")
        print("============================================================================================================")

        u_opt_ph = optimum.x 
        f_opt_ph = optimum.f
        u_opt_ch = u_opt_ph[:mpc.ni]
        
        # need revisit u0 design
        mpc.set_u0(u_opt_ph)
        mpc.set_u_ch_prev(u_opt_ch)

        # apply optimal control actions to virtual buildings
        if mpc.fmu_generator == "jmodelica":
            mpc.reset_fmu()
            mpc.initialize_fmu()
           
        elif mpc.fmu_generator == "dymola":
            mpc.set_fmu_time(t)
        
        #mpc.set_fmu_states(states)
        virtual_building.set_fmu_state(states)
        
        # for i, active in enumerate(active_names):
        #     mpc.fmu_model.set(active, '1')
        for i, name in enumerate(control_names):
            #mpc.fmu_model.set(name, u_opt_ch[i])
            virtual_building.set(name, u_opt_ch[i])
        '''
        # simulate from saved states    
        states_next, outputs = mpc.simulate(t, t+dt, states = states)
        '''

        # call simulate()    
        #mpc._fmu_results = mpc.fmu_model.simulate(start_time=t, final_time=t+dt, options=mpc.fmu_options)
        results_virtual_building =virtual_building.simulate(start_time=t, final_time=t+dt, options=virtual_building_options) # To-do: virtual_building.fmu_options??

        # return states and measurments
        #states_next = mpc.get_fmu_states()
        states_next = virtual_building.get_fmu_state()
        #outputs = mpc.get_fmu_outputs()
        outputs_dict = {}
        for output_name in output_names:
            outputs_dict[output_name] = results_virtual_building[output_name]
        outputs = pd.DataFrame(outputs_dict, index=results_virtual_building['time'])
        print("\nfmu outputs:",outputs.tail(1))
        
        if mpc.fmu_generator == "dymola":
            #mpc.fmu_options['initialize'] = False
            virtual_building_options['initialize'] = False
        
        # save results for future use
        t_opt.append(t)
        u_opt.append([float(i) for i in u_opt_ch])
        print("u_opt:",u_opt)
        results = pd.concat([results, outputs], axis=0)
        
        # update mpc clcok
        t += dt
        print('\nCurrent time (h):',(t % 86400)/3600,'~',((t+dt) % 86400)/3600)
        # update mpc states
        states = states_next
        print('===================================================================')

    # let's save the simualtion results 
    final = {'u_opt': u_opt,
             't_opt': t_opt}

    with open('results/u_opt_PH'+str(PH)+'.json', 'w') as outfile:
        json.dump(final, outfile) 
    results.to_csv('results/results_opt_PH'+str(PH)+'.csv')
