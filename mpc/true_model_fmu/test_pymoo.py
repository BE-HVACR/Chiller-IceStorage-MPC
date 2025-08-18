'''
Test of Pymoo package for binary optimization problem
'''

import numpy as np
from pymoo.core.problem import ElementwiseProblem
from pymoo.algorithms.soo.nonconvex.ga import GA
from pymoo.optimize import minimize


def my_objective_function(x):
    # Hypothetical complex model (for the sake of example, a simple function)
    # Let's say the function has some non-linear behavior
    value = -(x[0] and x[1])  # Objective is to maximize the occurrence of both ones
    return value

class BinaryOptimizationProblem(ElementwiseProblem):
    def __init__(self):
        super().__init__(n_var=2,  # Number of variables
                         n_obj=1,  # Number of objectives
                         n_constr=0,  # Number of constraints
                         xl=np.array([0, 0]),  # Lower bounds for variables
                         xu=np.array([1, 1]),  # Upper bounds for variables
                         elementwise_evaluation=True, type_var=np.bool)  # Element-wise evaluation

    def _evaluate(self, x, out, *args, **kwargs):
        # # Our objective function applied
        # f = my_objective_function(x)
        # out["F"] = np.array([f], dtype=np.float)
        # Function to maximize the occurrence of both ones
        out["F"] = -np.sum(x)  # Negative sum to simulate maximization of 1s

# Define the problem
problem = BinaryOptimizationProblem()

# Choose a genetic algorithm as the optimizer
algorithm = GA(pop_size=20, 
               crossover_prob=0.9, 
               mutation_prob=0.1, 
               eliminate_duplicates=True)

# Perform the optimization
result = minimize(problem,
                  algorithm,
                  termination=('n_gen', 200),
                  seed=1,
                  verbose=True)

print("Best solution found: \nX = ", result.X.astype(float)) # althought X should be type of int, use float to avoid rounding issues
print("Number of 1s (objective to maximize): ", result.F[0]*-1)  # Output the number of 1s, negated
