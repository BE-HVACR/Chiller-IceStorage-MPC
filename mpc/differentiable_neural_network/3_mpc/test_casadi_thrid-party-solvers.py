import casadi as ca
import os
import knitro
# os.environ['GUROBI_HOME'] = r'C:\gurobi1103\win64'
# os.environ['GUROBI_VERSION'] = r'110'
# os.environ['GRB_LICENSE_FILE'] = r'C:\gurobi1103\gurobi.lic'
# os.environ['PATH'] += r';C:\gurobi1103\win64\bin'
# os.environ['CASADIPATH'] = r'C:\ProgramData\anaconda3\envs\mpc-py38\Lib\site-packages\casadi'

# # Test casadi - Knitro
# # Ensure Knitro is in the system path
# os.environ["KNITRO_VERSION"] = r"1032"  # Adjust path as necessary
# os.environ["KNITRODIR"] = r"C:/Program Files/Artelys/Knitro1410"  # Adjust path as necessary
# os.environ["PATH"] += os.pathsep + "C:/Program Files/Artelys/Knitro1410/lib"

# Define a simple optimization problem
# Objective: Minimize f(x) = x^2
x = ca.MX.sym('x')  # Define a symbolic variable x
objective = x**2    # Objective function f(x) = x^2

# Define the NLP (nonlinear programming) problem
nlp = {'x': x, 'f': objective}

# Solver options for Knitro
# https://www.artelys.com/app/docs/knitro/3_referenceManual/userOptions.html#
solver_options = {
                "knitro.maxtime_real": 900,  # Maximum allowable real time before termination
                "knitro.ftol": 1e-3,  # Tolerance for stopping on small (feasible) changes to the objective
                "knitro.xtol": 1e-3,  # Tolerance for stopping on small changes to the solution estimate
                "knitro.feastol": 1e-3,  # Specifies the final relative stopping tolerance for the feasibility error
                "knitro.opttol": 1e-3,  #Specifies the final relative stopping tolerance for the optimality error
                "knitro.maxit": 1000,  # Maximum number of iterations
                "knitro.algorithm": 0,  # Choose an appropriate algorithm based on the problem
                "knitro.ms_enable": 1,  # Enable multi-start (optional)
                "knitro.mip_multistart":1, # enable a mixed-integer multistart heuristic at the branch-and-bound level
                 }

# Initialize the solver with Knitro
#os.environ["ARTELYS_LICENSE"] = r"C:\Users\guowenli\knitro\Artelys\artelys_lic_2024-11-13_trial_full_knitro_14.0_Guowen_Li_f6-50-c4-41-f6.txt"  # Adjust path as necessary
#try:
solver = ca.nlpsol('minlp_solver', 'knitro', nlp, solver_options)

# Initial guess for x
x0 = 10

# Solve the problem
solution = solver(x0=x0)
print("Optimal solution:", solution['x'])
# except Exception as e:
#     print("Error:", e)


# # Define decision variables
# x = ca.MX.sym('x', 2)  # 2 decision variables

# # Define the quadratic objective function: minimize 1/2 x^T Q x + c^T x . That is x1**2 + x2**2 + x1 +x2
# Q = ca.DM([[2, 0], [0, 2]])  # Positive definite matrix for quadratic term
# c = ca.DM([1, 1])            # Linear term
# objective = 0.5 * ca.mtimes([x.T, Q, x]) + ca.mtimes(c.T, x)

# # Define the quadratic constraint: x[0]^2 + x[1]^2 <= 1
# #g = ca.sumsqr(x)  # This represents the quadratic constraint x[0]^2 + x[1]^2
# g = ca.sum1(x) # linear constraint

# # Define the QP problem structure explicitly
# qp_problem = {
#     'x': x,           # Decision variables
#     'f': objective,   # Objective function
#     'g': g            # Quadratic constraint
# }

# # Gurobi solver options
# solver_options = {
#                 "gurobi.displayInterval":1,
#                 "gurobi.MIPGap": 1e-2,  # Solution tolerance (MIP gap)
#                 "gurobi.MIPFocus": 1, # Focus on finding feasible solutions
#                 "gurobi.NonConvex": 1, #-1, -2
#                 "gurobi.scaleFlag": 1,
#                 "gurobi.IntFeasTol": 1e-06,
#                 #"gurobi.SolFiles": 'log',
#                 "gurobi.PreMIQCPForm": 2,
#                 "gurobi.TIME_LIMIT": 360,  # TimeLimit in seconds
#                 "gurobi.NodeMethod": 1,  # 0, 1, 2
#                 #"gurobi.OutputFlag": 1,  # Enable solver output
#                 #"gurobi.Heuristics": 0.5,  # Heuristic parameter to improve performance
#                 #"gurobi.Presolve": 2,  # Enable aggressive presolve
#                 # "gurobi.NodeLimit": 10000,  # Limit on the number of nodes explored
#                 "error_on_fail": False,
#                 "discrete": [True,True],
#                 }
# # Create the quadratic solver using qpsol
# solver = ca.qpsol('solver', 'gurobi', qp_problem, solver_options) # for qpsol with gurobi, linear constraint matters!

# # # test for ipopt solver
# #solver = ca.nlpsol('nlp_solver', 'ipopt', qp_problem) 

# # # test for Bonmin solver
# # solver_options = {
# #                 "bonmin.time_limit": 360,  # Time limit in seconds
# #                 "bonmin.tol": 1e-2,  # Solution tolerance
# #                 "bonmin.max_iter": 10000,  # Increase max iterations if feasible
# #                 "bonmin.cutoff_decr": 1e-2,  # Increase the threshold for accepting better solutions
# #                 "discrete": [True,True]
# #                 }
# # solver = ca.nlpsol('nlp_solver', 'bonmin', qp_problem, solver_options)

# # # test for Knitro solver
# # solver_options = {
# #                 'knitro.outlev': 1,      # Print output level (0 for silent, 1 for basic output)
# #                 'knitro.maxit': 1000,    # Maximum number of iterations
# #                 'knitro.feastol': 1e-6,  # Feasibility tolerance
# #                 'knitro.mipmethod': 1,    # Algorithm for mixed-integer problems (1 for branch-and-bound)
# #                 'discrete': [True,True],
# #                 }
# # solver = ca.nlpsol('solver', 'knitro', qp_problem, solver_options)

# # Initial guess for variables
# x0 = [10, 0]
# #x0 = [2, 0]

# # Variable bounds (box constraints)
# lbx = [1.9, -1.5]
# ubx = [10.1, 10]

# # Constraint bounds
# lbg = [-100]  # lower bound
# ubg = [10]              # Upper bound corresponds to the circle x^2 + y^2 <= 10

# # Solve the QP problem
# res = solver(x0=x0, lbx=lbx, ubx=ubx, lbg=lbg, ubg=ubg)

# # Get the solution
# solution = res['x']
# print("QP Optimal solution:", solution)
# print("QP Objective value:", res['f'])


