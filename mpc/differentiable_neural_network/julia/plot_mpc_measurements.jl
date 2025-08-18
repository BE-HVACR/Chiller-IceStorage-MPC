"""
This script plots the measurements and MPC optimized output/predictions from the optimization results.

Author: Guowen Li
Email: guowenli@tamu.edu
Revisions:
    11/12/2024
"""

using DataFrames
using CSV
using Plots
using JSON

function plot_results(PH=12)
    """
    Plot and evaluate MPC results based on the provided PH value.

    Parameters:
    - PH: Prediction horizon used in the MPC (default: 12)
    """
    println("Plotting results for PH=$PH")

    # Show plot in interactive window
    show_plot = false

    # Load CSV file as DataFrame
    df_mpc_results = CSV.File("./results/results_measurements_PH$(PH).csv") |> DataFrame

    # Convert time from seconds to hours and use relative time (starting at 0)
    df_mpc_results[!, :time_hr] = (df_mpc_results.time .- first(df_mpc_results.time)) ./ 3600

    # Helper function to shade occupied periods
    function shade_occupied_periods(ax, df, start_time_col, end_time_col)
        for row in eachrow(df)
            if row.occSch_occupied == 1
                plot!(ax, [row[start_time_col], row[end_time_col]], [0, 1], color=:grey, fillalpha=0.1, label="")
            end
        end
    end

    # Plot 1: Chiller and TES details (6x1 subplots)
    p = plot(layout = (6, 1), size = (1200, 1400))

    # 1st subplot: Electricity rate
    plot!(p[1, 1], df_mpc_results.time_hr, df_mpc_results.Elec_rate, label="Time-of-Use", color=:black)
    ylabel!(p[1, 1], "\$ / kWh")
    title!(p[1, 1], "Peak price = 0.3548 \$ / kWh; Middle price = 0.1391 \$ / kWh; Valley price = 0.0640 \$ / kWh")
    shade_occupied_periods(p[1, 1], df_mpc_results, :time_hr, :time_hr)
    legend!(p[1, 1], :top_left)

    # 2nd subplot: Chiller and TES ON/OFF
    plot!(p[2, 1], df_mpc_results.time_hr, df_mpc_results.uModActual_y, label="Actual mode", color=:blue)
    plot!(p[2, 1], df_mpc_results.time_hr, df_mpc_results.uMod, label="Input mode", color=:black, linestyle=:dashdot)
    title!(p[2, 1], "Operation mode = -1 (Charge TES); 0 (off); 1 (Discharge TES); 2 (Discharge chiller)")
    ylabel!(p[2, 1], "Mode")
    ylim!(p[2, 1], -1.1, 2.1)
    shade_occupied_periods(p[2, 1], df_mpc_results, :time_hr, :time_hr)
    legend!(p[2, 1], :top_left)

    # 3rd subplot: State of Charge (SOC)
    plot!(p[3, 1], df_mpc_results.time_hr, df_mpc_results.iceTan_SOC, label="Measured SOC", color=:black)
    plot!(p[3, 1], df_mpc_results.time_hr, df_mpc_results.SOC_pred, label="Predicted SOC", linestyle=:dot, color=:black)
    ylabel!(p[3, 1], "SOC")
    ylim!(p[3, 1], 0, 1)
    shade_occupied_periods(p[3, 1], df_mpc_results, :time_hr, :time_hr)
    legend!(p[3, 1], :top_left)

    # 4th subplot: Power
    total_power = df_mpc_results[:, [:chi_P, :priPum_P, :secPum_P, :fanSup_P]]
    power_sum = sum(total_power, dims=2)
    plot!(p[4, 1], df_mpc_results.time_hr, power_sum, label="Measured power", color=:black)
    plot!(p[4, 1], df_mpc_results.time_hr, df_mpc_results.P_pred, label="Predicted power", linestyle=:dot, color=:black)
    ylabel!(p[4, 1], "Total Power [W]")
    ylim!(p[4, 1], 0, 25000)
    shade_occupied_periods(p[4, 1], df_mpc_results, :time_hr, :time_hr)
    legend!(p[4, 1], :top_left)

    # 5th subplot: Outdoor Air Temperature
    plot!(p[5, 1], df_mpc_results.time_hr, df_mpc_results.TOut_y .- 273.15, label="OA dry-bulb temperature", color=:black)
    plot!(p[5, 1], df_mpc_results.time_hr, df_mpc_results.weaBus_TWetBul .- 273.15, label="OA wet-bulb temperature", linestyle=:solid, color=:grey)
    ylabel!(p[5, 1], "Temperature (°C)")
    shade_occupied_periods(p[5, 1], df_mpc_results, :time_hr, :time_hr)
    legend!(p[5, 1], :top_left)

    # 6th subplot: Solar irradiance
    plot!(p[6, 1], df_mpc_results.time_hr, df_mpc_results.weaBus_HGloHor, label="Global horizontal solar irradiance", color=:black)
    ylabel!(p[6, 1], "Solar irradiance (W/m²)")
    shade_occupied_periods(p[6, 1], df_mpc_results, :time_hr, :time_hr)
    legend!(p[6, 1], :top_left)

    display(p)
    mkpath("./results")
    savefig(p, "./results/Chiller_TES_PH$(PH).png")
    if show_plot
        display(p)
    end

    # Plot 2: Zonal temperature and airflow rate (5x2 subplots)
    p2 = plot(layout = (5, 2), size = (1200, 1000))

    zones = ["Core", "East", "North", "South", "West"]
    for (i, zone) in enumerate(zones)
        # Left column: Zonal temperature
        plot!(p2[2*i-1, 1], df_mpc_results.time_hr, df_mpc_results[!, Symbol("conAHU.TZonCooSet")] .- 273.15, label="Bounds", linestyle=:dash, color=:black, linewidth=0.5)
        plot!(p2[2*i-1, 1], df_mpc_results.time_hr, df_mpc_results[!, Symbol("conAHU.TZonHeaSet")] .- 273.15, label="Bounds", linestyle=:dash, color=:black, linewidth=0.5)
        plot!(p2[2*i-1, 1], df_mpc_results.time_hr, df_mpc_results[!, Symbol("conVAV$(zone[1:3]).TZon")] .- 273.15, label="Measured", color=:blue)
        plot!(p2[2*i-1, 1], df_mpc_results.time_hr, df_mpc_results[!, Symbol("Tz_$(lowercase(zone))_pred")] .- 273.15, label="Predicted", linestyle=:dot, color=:blue)
        ylabel!(p2[2*i-1, 1], "$(zone) Zone Temp (°C)")
        shade_occupied_periods(p2[2*i-1, 1], df_mpc_results, :time_hr, :time_hr)
        legend!(p2[2*i-1, 1], :top_left)

        # Right column: Airflow rate
        plot!(p2[2*i, 1], df_mpc_results.time_hr, df_mpc_results[!, Symbol("VSup$(zone[1:3])_flow.V_flow")], label="Measured", color=:blue)
        plot!(p2[2*i, 1], df_mpc_results.time_hr, df_mpc_results[!, Symbol("conVAV$(zone[1:3]).damVal.VDisSet_flow")], label="Setpoint", linestyle=:solid, color=:grey)
        ylabel!(p2[2*i, 1], "$(zone) Airflow Rate (m³/s)")
        legend!(p2[2*i, 1], :top_left)
    end

    display(p2)
    savefig(p2, "./results/zone_temp_flowrate_PH$(PH).png")
    if show_plot
        display(p2)
    end

    # Define Time-of-Use electricity rate - $/kWh
    price_tou = [0.0640, 0.0640, 0.0640, 0.0640,
                 0.0640, 0.0640, 0.0640, 0.0640,
                 0.1391, 0.1391, 0.1391, 0.1391,
                 0.3548, 0.3548, 0.3548, 0.3548,
                 0.3548, 0.3548, 0.1391, 0.1391,
                 0.1391, 0.1391, 0.1391, 0.0640]

    function get_metrics(Ptot, TZone, price_tou, nsteps_h=4)
        """
        Calculate metrics such as energy cost, temperature violations, and load during high and low price periods.

        Parameters:
        - Ptot: Array of total power
        - TZone: Matrix of zone temperatures
        - price_tou: Time-of-use electricity rates
        - nsteps_h: Number of steps per hour (default is 4 for 15-minute intervals)

        Returns:
        - metrics: A matrix containing energy costs, temperature violations, and loads
        """
        energy_cost = Float64[]
        temp_violation = []
        high_price_load = Float64[]
        low_price_load = Float64[]

        for i in 1:length(Ptot)
            hindex = (div(i - 1, nsteps_h) % 24) + 1

            # Calculate energy cost
            power = Ptot[i]
            price = price_tou[hindex]
            push!(energy_cost, power / 1000.0 / nsteps_h * price)

            # Calculate high and low price period loads
            if price == 0.3548 || price == 0.1391
                push!(high_price_load, power / 1000.0 / nsteps_h)
                push!(low_price_load, 0.0)
            elseif price == 0.0640
                push!(low_price_load, power / 1000.0 / nsteps_h)
                push!(high_price_load, 0.0)
            end

            # Calculate temperature violations for each zone
            T_upper = 30.0
            T_lower = 18.0
            violations = [max(TZone[i, k] - 273.15 - T_upper, 0) + max(T_lower - (TZone[i, k] - 273.15), 0) for k in 1:size(TZone, 2)]
            push!(temp_violation, violations)
        end

        metrics = hcat(energy_cost, temp_violation, high_price_load, low_price_load)
        return metrics
    end

    # Group by time steps (15 minutes) and calculate metrics
    PTot = sum(df_mpc_results[:, [:chi_P, :priPum_P, :secPum_P, :fanSup_P]], dims=2)
    TZones = Matrix(df_mpc_results[:, [:conVAVCor_TZon, :conVAVEas_TZon, :conVAVNor_TZon, :conVAVSou_TZon, :conVAVWes_TZon]])
    metrics = get_metrics(PTot, TZones, price_tou)
    metrics_df = DataFrame(metrics, [:energy_cost, :temp_violation1, :temp_violation2, :temp_violation3, :temp_violation4, :temp_violation5, :high_price_period_load, :low_price_period_load])

    # Save results to JSON
    mkpath("./results")
    mpc_results_metrics = Dict(
        "energy" => sum(PTot) / 1000,
        "energy_cost" => sum(metrics_df[:, :energy_cost]),
        "max_temp_violation" => maximum(metrics_df[:, [:temp_violation1, :temp_violation2, :temp_violation3, :temp_violation4, :temp_violation5]]),
        "high_price_period_load" => sum(metrics_df[:, :high_price_period_load]),
        "low_price_period_load" => sum(metrics_df[:, :low_price_period_load])
    )

    open("./results/mpc_performance_metrics_PH$(PH).json", "w") do outfile
        JSON.print(outfile, mpc_results_metrics)
    end
    println("\nPost-processing finished!")
end

# If there's a main method, ensure it won't trigger when importing
if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    plot_results(PH=12)
end
