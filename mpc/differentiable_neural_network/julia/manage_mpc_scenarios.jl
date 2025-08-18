"""
this script is to manage mpc experiments for multiple testing scenarios (e.g., PHs, Sizes)

Author:Guowen Li
Email: guowenli@tamu.edu
Revisions:
    11/12/2024
"""

include("run_mpc_dnn.jl")
include("plot_mpc_measurements.jl")

# Define a function to run the tests for different PH values
function run_tests(PH_values, mIce_max, SOC_ini)
    # Loop through each test scenario based on PH
    for (i, PH) in enumerate(PH_values)
        println("Running test scenario $(i): PH=$(PH), mIce_max=$(mIce_max), SOC_ini=$(SOC_ini)")

        # Call the MPC function with the current hyperparameters
        run_mpc(PH=PH, mIce_max=mIce_max, SOC_ini=SOC_ini)

        # After running MPC, perform the post-processing and plotting
        plot_results(PH=PH)  # Assuming PH is the parameter passed to 'plot_results'

        println("Completed test scenario $(i)\n")
    end
end

# Main execution
if abspath(PROGRAM_FILE) == @__FILE__
    # Define the list of PH values you want to test
    PH_values = [1, 2, 4, 8, 10, 12, 16, 20, 24, 32, 40, 48]
    #PH_values = [1] # used for calculate baseline RBC control (set lower bound of uMod = -1 during unoccupied to be storage-priority control)

    # Set the constant values for mIce_max and SOC_ini
    mIce_max = 3105 * 5.0  # 3105 L water per tank from NIST testbed, Trane Calmac Model 1082A
    #mIce_max = 1550.0 # Trane Calmac Model 1045C
    SOC_ini = 0.5  # initial State-of-Charge

    # Run the tests with the defined PH values and constant parameters
    run_tests(PH_values, mIce_max, SOC_ini)
end


