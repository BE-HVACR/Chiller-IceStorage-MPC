"""
(Julia version) This script is used to run the formulated MPC with the virtual building testbed.

Author: Guowen Li
Email: guowenli@tamu.edu
Revisions:
    11/12/2024: MPC optimization framework with diffential neural network models in Julia
                Convert from Python to Julia: https://www.codeconvert.ai/python-to-julia-converter
"""

using PyFMI # load testbed
using DataFrames
using JSON
using CSV
using Interpolations
using Dates
using .mpc_dnn # load MPC

function run_mpc(PH=12, mIce_max=3105.0 * 5, SOC_ini=0.5)
    """
    Run MPC optimization problem with adjustable parameters.

    Parameters:
    - PH: Prediction horizon (default: 12)
    - mIce_max: Maximum mass of ice (default: 15 kg)
    - SOC_ini: Initial state of charge (default: 0.5)
    """
    # Use the provided PH, mIce_max, and SOC_ini values in your MPC calculations
    println("Running MPC with PH=$PH, mIce_max=$mIce_max, SOC_ini=$SOC_ini")
    
    function get_measurement(fmu_result, names)
        if !in("time", names)
            push!(names, "time")
        end

        dic = Dict{String, Any}()
        for name in names
            dic[name] = fmu_result[name][end]
        end

        # return a DataFrame
        return DataFrame(dic, index=[dic["time"]])
    end

    function interpolate_dataframe(df, new_index)
        """Interpolate a dataframe along its index based on a new index"""
        df_out = DataFrame(index=new_index)
        df_out.index.name = df.index.name

        for col_name in names(df)
            df_out[!, col_name] = interp(new_index, df.index, df[!, col_name])
        end
        return df_out
    end

    function FILO(a_list, x)
        """First in Last out: 
        x: scalar
        """
        push!(a_list, x)
        pop!(a_list, 1)

        return a_list
    end

    function get_states(states, measurement, Tz_pred)
        """Update current states using measurement data"""
        # read list
        Tz_core_his = states["Tz_core_his_meas"]
        Tz_east_his = states["Tz_east_his_meas"]
        Tz_north_his = states["Tz_north_his_meas"]
        Tz_south_his = states["Tz_south_his_meas"]
        Tz_west_his = states["Tz_west_his_meas"]
        Tz_ave_his = states["Tz_ave_his_meas"]
        Toa_his = states["To_his_meas"]
        GHI_his = states["GHI_his_meas"]
        SOC_his = states["SOC_his_meas"]
        P_his = states["P_his_meas"]
        Tz_core_his_pred = states["Tz_core_his_pred"]
        Tz_east_his_pred = states["Tz_east_his_pred"]
        Tz_north_his_pred = states["Tz_north_his_pred"]
        Tz_south_his_pred = states["Tz_south_his_pred"]
        Tz_west_his_pred = states["Tz_west_his_pred"]
    
        # read scalar
        Tz_core = measurement["conVAVCor.TZon"][1] - 273.15 # K to C
        Tz_east = measurement["conVAVEas.TZon"][1] - 273.15 # K to C
        Tz_north = measurement["conVAVNor.TZon"][1] - 273.15 # K to C
        Tz_south = measurement["conVAVSou.TZon"][1] - 273.15 # K to C
        Tz_west = measurement["conVAVWes.TZon"][1] - 273.15 # K to C
        Tz_ave = measurement["ave.y"][1] - 273.15 # K to C
        Toa = measurement["TOut.y"][1] - 273.15  # K to C
        GHI = measurement["weaBus.HGloHor"][1] # [W/m2]
        SOC = measurement["iceTan.SOC"][1]
        P = max(measurement["chi.P"][1], 0) + max(measurement["priPum.P"][1], 0) +
            max(measurement["secPum.P"][1], 0) + max(measurement["fanSup.P"][1], 0)
        Tz_core_pred = Tz_pred["core"]
        Tz_east_pred = Tz_pred["east"]
        Tz_north_pred = Tz_pred["north"]    
        Tz_south_pred = Tz_pred["south"]
        Tz_west_pred = Tz_pred["west"]    
    
        # new dict
        states["Tz_core_his_meas"] = pushfirst!(Tz_core_his, Tz_core)
        states["Tz_east_his_meas"] = pushfirst!(Tz_east_his, Tz_east)
        states["Tz_north_his_meas"] = pushfirst!(Tz_north_his, Tz_north)
        states["Tz_south_his_meas"] = pushfirst!(Tz_south_his, Tz_south)
        states["Tz_west_his_meas"] = pushfirst!(Tz_west_his, Tz_west)
        states["Tz_ave_his_meas"] = pushfirst!(Tz_ave_his, Tz_ave)
        states["To_his_meas"] = pushfirst!(Toa_his, Toa)
        states["GHI_his_meas"] = pushfirst!(GHI_his, GHI)
        states["SOC_his_meas"] = pushfirst!(SOC_his, SOC)
        states["P_his_meas"] = pushfirst!(P_his, P)
        states["Tz_core_his_pred"] = pushfirst!(Tz_core_his_pred, Tz_core_pred)
        states["Tz_east_his_pred"] = pushfirst!(Tz_east_his_pred, Tz_east_pred)
        states["Tz_north_his_pred"] = pushfirst!(Tz_north_his_pred, Tz_north_pred)
        states["Tz_south_his_pred"] = pushfirst!(Tz_south_his_pred, Tz_south_pred)
        states["Tz_west_his_pred"] = pushfirst!(Tz_west_his_pred, Tz_west_pred)
    
        println("\nstates_updated:")
        # Iterate and print every element in the dictionary states 
        for (key, values) in states
            println("$key: $values")
        end
    
        return states
    end    

    function get_price(time, dt, PH)
        # unite - $/kwh
        price_tou = [0.0640, 0.0640, 0.0640, 0.0640,
                      0.0640, 0.0640, 0.0640, 0.0640,
                      0.1391, 0.1391, 0.1391, 0.1391,
                      0.3548, 0.3548, 0.3548, 0.3548,
                      0.3548, 0.3548, 0.1391, 0.1391,
                      0.1391, 0.1391, 0.1391, 0.0640]
        # assume hourly TOU pricing
        t_ph = time:dt:time + dt * PH
        price_ph = [price_tou[Int(mod(t, 86400) / 3600) + 1] for t in t_ph]
    
        return price_ph
    end    
    
    function read_temperature(weather_file::String, dt::Float64)
        """Read temperature and solar radiance from epw file. 
            This module serves as an ideal weather predictor.
        :return: a data frame at an interval of defined time_step
        """
        dat = CSV.File(weather_file) |> DataFrame
        tem_sol_h = dat[:, [:temp_air]]  # celsius
        index_h = 3600:3600:(3600 * (nrow(tem_sol_h) + 1))
        tem_sol_h.index = index_h
    
        # interpolate temperature into simulation steps
        index_step = 3600:dt:(3600 * (nrow(tem_sol_h) + 1))
    
        return interpolate_dataframe(tem_sol_h, index_step)
    end
    
    function get_Toa(time::Float64, dt::Float64, PH::Int, Toa_year::DataFrame)
        index_ph = time:dt:(time + dt * PH)
        Toa = Toa_year[index_ph, :]
    
        return collect(reshape(Toa[:, :], :))
    end
    
    function read_RH(weather_file::String, dt::Float64)  # Relative Humidity
        """Read Relative Humidity from epw file. 
            This module serves as an ideal weather predictor.
        :return: a data frame at an interval of defined time_step
        """
        dat = CSV.File(weather_file) |> DataFrame
    
        RH_h = dat[:, [:relative_humidity]] .* 0.01  # convert from 100% to [0,1]
        index_h = 3600:3600:(3600 * (nrow(RH_h) + 1))
        RH_h.index = index_h
    
        # interpolate relative humidity into simulation steps
        index_step = 3600:dt:(3600 * (nrow(RH_h) + 1))
    
        return interpolate_dataframe(RH_h, index_step)
    end
    
    function get_RHoa(time::Float64, dt::Float64, PH::Int, RHoa_year::DataFrame)
        index_ph = time:dt:(time + dt * PH)
        RHoa = RHoa_year[index_ph, :]
    
        return collect(reshape(RHoa[:, :], :))
    end
    
    function read_GHI(weather_file::String, dt::Float64)  # Global horizontal solar irradiation [W/m2]
        """Read global horizontal solar irradiation from epw file. 
            This module serves as an ideal weather predictor.
        :return: a data frame at an interval of defined time_step
        """
        dat = CSV.File(weather_file) |> DataFrame
        GHI_h = dat[:, [:ghi]]  # Direct and diffuse horizontal radiation recv’d during 60 minutes prior to timestamp, Wh/m^2
        index_h = 3600:3600:(3600 * (nrow(GHI_h) + 1))
        GHI_h.index = index_h
    
        # interpolate into simulation steps
        index_step = 3600:dt:(3600 * (nrow(GHI_h) + 1))
    
        return interpolate_dataframe(GHI_h, index_step)
    end
    
    function get_GHI(time::Float64, dt::Float64, PH::Int, GHI_year::DataFrame)
        index_ph = time:dt:(time + dt * PH)
        GHI = GHI_year[index_ph, :]
    
        return collect(reshape(GHI[:, :], :))
    end
    
    
    # Load FMU
    ## ============================================================
    # Set the environment variable for the Dymola license
    if !haskey(ENV, "DYMOLA_RUNTIME_LICENSE")
        ENV["DYMOLA_RUNTIME_LICENSE"] = "c:/programdata/dassaultsystemes/dymola/dymola.lic"
    end
    # load Modelica model - VAV system virtual testbed
    hvac = load_fmu("VirtualTestbed_NISTChillerTestbed_DemandFlexibilityInvestigation_FakeSystem_SystemForMPC_01bInput_0modeSignal.fmu", log_level=3)

    # Set the initial parameter value
    # 3105 L/tank from NIST testbed, Calmac part number 1082A
    # https://www.trane.com/commercial/north-america/us/en/products-systems/energy-storage-solutions/calmac-model-a-tank.html
    mIce_max = mIce_max
    hvac.set("mIce_max", mIce_max) # Nominal mass of ice in the tank, original 3105*5 kg, 
    SOC_ini = SOC_ini
    hvac.set("mIce_start", SOC_ini * mIce_max) # Start value of ice mass in the tank, original SOC = 0.5

    # fmu settings
    options = hvac.simulate_options()
    options["ncp"] = 100 # number of output points, need to be integer
    options["initialize"] = true
    measurement_names = [
        "time",
        "TOut.y",
        "weaBus.TWetBul",
        "weaBus.relHum",
        "weaBus.HGloHor",
        "uMod",
        "uModActual.y",
        "occSch.occupied",
        "modCon.y",
        "iceTan.SOC",
        "chi.TSet",
        "iceTan.TOutSet",
        "TCHWSup.T",
        "TCHWRetCoi.T",
        "priPum.m_flow",
        "secPum.m_flow",
        "senRelPre.p_rel",
        "conAHU.TSupSet",
        "conAHU.TSup",
        "senSupFlo.V_flow",
        "conVAVCor.damVal.VDisSet_flow",
        "VSupCor_flow.V_flow",
        "conVAVSou.damVal.VDisSet_flow",
        "VSupSou_flow.V_flow",
        "conVAVEas.damVal.VDisSet_flow",
        "VSupEas_flow.V_flow",
        "conVAVNor.damVal.VDisSet_flow",
        "VSupNor_flow.V_flow",
        "conVAVWes.damVal.VDisSet_flow",
        "VSupWes_flow.V_flow",
        "conAHU.TZonCooSet",
        "conAHU.TZonHeaSet",
        "conVAVCor.TZon",
        "conVAVSou.TZon",
        "conVAVEas.TZon",
        "conVAVNor.TZon",
        "conVAVWes.TZon",
        "ave.y",
        "chi.P",
        "priPum.P",
        "secPum.P",
        "fanSup.P"
    ]
    # options["filter"] = measurement_names
    
    # Define simulation period
    t_start = 212 * 24 * 3600 + 31 * 24 * 3600  # July 1st is Day181, August 1st is Day212, September 1st is Day 243, original test on Day 221
    t_period = 2 * 24 * 3600.0
    t_end = t_start + t_period  # simulation end time
    te_warm = t_start + 1 * 3600.0  # warm up time
    dt = 4 * 15 * 60.0  # MPC timestep
    PH = PH  # Assuming PH is defined elsewhere
    CH = 1
    number_inputs = 1  # 1 mode input signal
    
    # Predictors
    predictor = Dict()
    # energy prices
    predictor["price"] = get_price(t_start, dt, PH)
    # outdoor air conditions
    weather_file = "USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw"
    Toa_year = read_temperature(weather_file, dt)
    predictor["Toa"] = get_Toa(t_start + dt, dt, PH, Toa_year)
    RHoa_year = read_RH(weather_file, dt)
    predictor["RHoa"] = get_RHoa(t_start + dt, dt, PH, RHoa_year)
    GHI_year = read_GHI(weather_file, dt)
    predictor["GHI"] = get_GHI(t_start + dt, dt, PH, GHI_year)
    
    # Initialize states
    # historical Toa measurements
    Toa_his_meas_ini = get_Toa(t_start - 3 * dt, dt, 4, Toa_year)
    GHI_his_meas_ini = get_GHI(t_start - 3 * dt, dt, 4, GHI_year)
    
    # states
    states_ini = Dict(
        "Tz_core_his_meas" => fill(24.0, 4),  # Unit: Celsius
        "Tz_east_his_meas" => fill(24.0, 4),
        "Tz_north_his_meas" => fill(24.0, 4),
        "Tz_south_his_meas" => fill(24.0, 4),
        "Tz_west_his_meas" => fill(24.0, 4),
        "Tz_ave_his_meas" => fill(24.0, 4),
        "To_his_meas" => Toa_his_meas_ini,  # Unit: Celsius
        "GHI_his_meas" => GHI_his_meas_ini,
        "SOC_his_meas" => fill(SOC_ini, 4),
        "P_his_meas" => fill(0.0, 4),
        "Tz_core_his_pred" => fill(24.0, 4),  # Unit: Celsius
        "Tz_east_his_pred" => fill(24.0, 4),
        "Tz_north_his_pred" => fill(24.0, 4),
        "Tz_south_his_pred" => fill(24.0, 4),
        "Tz_west_his_pred" => fill(24.0, 4)
    )  # initial states used for MPC models
    
    # Initialize mpc case
    measurement_ini = Dict()
    measurement = measurement_ini
    
    case = mpc_case(
        PH=PH,
        CH=CH,
        time=t_start,
        dt=dt,
        measurement=measurement_ini,
        states=states_ini,
        predictor=predictor
    )
    
    # Input variables for fmu
    inputs = ["uMod"] # -1: Charge TES; 0: off; 1: Discharge TES; 2: Discharge chiller
    
    # Initialize start time
    ts = t_start
    println("t_start: ", t_start)
    println("t_end: ", t_end)
    
    # Initialize inputs
    uMPC_ini = [0] # -1: Charge TES; 0: off; 1: Discharge TES; 2: Discharge chiller
    uMPC = uMPC_ini
    states = states_ini
    
    # Initialize outputs
    results = DataFrame()
    t_opt = []
    u_opt = []
    Tz_core_pred_opt = []
    Tz_east_pred_opt = []
    Tz_north_pred_opt = []
    Tz_south_pred_opt = []
    Tz_west_pred_opt = []
    P_pred_opt = []
    SOC_pred_opt = []
    warmup = true    

    ## main loop
    while ts < t_end
        te = ts + dt * CH
        println("\n============================================================================================")
        push!(t_opt, ts)
        println("Simulation time Clock (hour): ", (ts % 86400) / 3600, " ~ ", ((te) % 86400) / 3600)

        # Generate control action from MPC
        if !warmup  # Activate MPC after warmup
            println("Prediction Horizon (hour): ", PH * dt / 3600)
            # Update MPC case
            set_time(case, ts)
            set_measurement(case, measurement)
            set_states(case, states)
            set_predictor(case, predictor)
            set_u_prev(case, u_opt_ch)

            # Call optimizer
            res, solver_status = optimize(case)
            if solver_status["return_status"] == "INFEASIBLE"
                u_opt_ph = case.u_start
            else
                u_opt_ph = res["x"]
            end
            
            # [uMod, ε]
            uMPC = [u_opt_ph[1]]
            uMPC = [Int(u) for u in uMPC]  # Convert to int since input mode is integer

            # Get the control action for the control horizon
            u_opt_ch = u_opt_ph[1:1]
            println("\nControl input: ", u_opt_ch)

            # Update predictions after MPC predictor is called, otherwise use measurement
            P_pred = Float64(get_power_pred(case, u_opt_ch))
            SOC_pred = Float64(get_SOC_pred(case, u_opt_ch))
            Tz_core_pred = Float64(get_core_temp_pred(case, u_opt_ch))
            Tz_east_pred = Float64(get_east_temp_pred(case, u_opt_ch))
            Tz_north_pred = Float64(get_north_temp_pred(case, u_opt_ch))
            Tz_south_pred = Float64(get_south_temp_pred(case, u_opt_ch))
            Tz_west_pred = Float64(get_west_temp_pred(case, u_opt_ch))

            # Get all open-loop predicted values
            P_pred_ph, SOC_pred_ph, Tz_core_pred_ph, Tz_east_pred_ph, Tz_north_pred_ph, Tz_south_pred_ph, Tz_west_pred_ph = get_open_loop_preds(case, res["x"])
            println("\nP_pred_ph: ", P_pred_ph)
            println("SOC_pred_ph: ", SOC_pred_ph)
            println("Tz_core_pred_ph: ", Tz_core_pred_ph)
            println("Tz_east_pred_ph: ", Tz_east_pred_ph)
            println("Tz_north_pred_ph: ", Tz_north_pred_ph)
            println("Tz_south_pred_ph: ", Tz_south_pred_ph)
            println("Tz_west_pred_ph: ", Tz_west_pred_ph, "\n")
            
            # Update start points for optimizer using previous optimum value
            set_u_start(case, u_opt_ph)
        end

        # Advance building simulation by one step
        for (i, var) in enumerate(inputs)
            set(hvac, var, uMPC[i])
        end
        res = simulate(hvac, start_time=ts, final_time=te, options=options)
        # Update clock
        ts = te

        # Get measurement
        measurement = get_measurement(res, measurement_names)

        # Update MPC model states
        if warmup
            Tz_core_pred = measurement["conVAVCor.TZon"][1] - 273.15  # deg C
            Tz_east_pred = measurement["conVAVEas.TZon"][1] - 273.15
            Tz_north_pred = measurement["conVAVNor.TZon"][1] - 273.15
            Tz_south_pred = measurement["conVAVSou.TZon"][1] - 273.15
            Tz_west_pred = measurement["conVAVWes.TZon"][1] - 273.15
            P_pred = max(measurement["chi.P"][1], 0) + max(measurement["priPum.P"][1], 0) +
                        max(measurement["secPum.P"][1], 0) + max(measurement["fanSup.P"][1], 0)
            SOC_pred = measurement["iceTan.SOC"][1]
            u_opt_ch = uMPC_ini  # Need to have the same unit as MPC optimizer
        end
        
        Tz_pred = Dict("core" => Tz_core_pred,
                        "east" => Tz_east_pred,
                        "north" => Tz_north_pred,
                        "south" => Tz_south_pred,
                        "west" => Tz_west_pred)   
        states = get_states(states, measurement, Tz_pred)

        # Update predictor
        predictor["price"] = get_price(ts, dt, PH)
        predictor["Toa"] = get_Toa(ts+dt, dt, PH, Toa_year)
        predictor["RHoa"] = get_RHoa(ts+dt, dt, PH, RHoa_year)
        predictor["GHI"] = get_GHI(ts+dt, dt, PH, GHI_year)

        # Update FMU settings
        options["initialize"] = false

        # Update warmup flag for next step
        warmup = ts < te_warm

        # Save optimal results of the control horizon for future simulation
        push!(u_opt, uMPC)
        push!(Tz_core_pred_opt, Tz_core_pred)
        push!(Tz_east_pred_opt, Tz_east_pred)
        push!(Tz_north_pred_opt, Tz_north_pred)
        push!(Tz_south_pred_opt, Tz_south_pred)
        push!(Tz_west_pred_opt, Tz_west_pred)
        push!(P_pred_opt, P_pred)
        push!(SOC_pred_opt, SOC_pred)
        
        # Save measurements into DataFrame and as a CSV file at the end
        outputs_dict = Dict()
        output_names = measurement_names
        for output_name in output_names
            outputs_dict[output_name] = res[output_name]
        end
        outputs_dict["Tz_core_pred"] = Tz_core_pred + 273.15
        outputs_dict["Tz_east_pred"] = Tz_east_pred + 273.15
        outputs_dict["Tz_north_pred"] = Tz_north_pred + 273.15
        outputs_dict["Tz_south_pred"] = Tz_south_pred + 273.15
        outputs_dict["Tz_west_pred"] = Tz_west_pred + 273.15
        outputs_dict["Ptot_meas"] = max(measurement["chi.P"][1], 0) + max(measurement["priPum.P"][1], 0) +
                                    max(measurement["secPum.P"][1], 0) + max(measurement["fanSup.P"][1], 0)
        outputs_dict["P_pred"] = P_pred
        outputs_dict["SOC_pred"] = SOC_pred
        outputs_dict["Elec_rate"] = get_price(ts-dt, dt, 1)[1]  # [$/kWh]
        outputs = DataFrame(outputs_dict)
        outputs[!, :time] = res["time"]
        results = vcat(results, outputs)
    end
    
    ## Save results  
    final = Dict("u_opt" => u_opt,
                    "Tz_core_pred_opt" => Tz_core_pred_opt,
                    "Tz_east_pred_opt" => Tz_east_pred_opt,
                    "Tz_north_pred_opt" => Tz_north_pred_opt,
                    "Tz_south_pred_opt" => Tz_south_pred_opt,
                    "Tz_west_pred_opt" => Tz_west_pred_opt,
                    "P_pred_opt" => P_pred_opt,
                    "SOC_pred_opt" => SOC_pred_opt,
                    "t_opt" => t_opt)

    # Save measurements and prediction values as CSV file
    CSV.write("./results/results_measurements_PH$(PH).csv", results)
    # End of MPC experiment
    println("\nMPC simulation finished!")
end
    
# If you have any main method to run, make sure it is not triggered when imported
if abspath(PROGRAM_FILE) == @__FILE__
    run_mpc()
end
    
    