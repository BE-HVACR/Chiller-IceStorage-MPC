# Create the Python virtual environment with Conda
conda env create -f environment.yml

# After creation, activate the environment
conda activate mpc-py38

# Updating an Existing Environment
conda env update -f environment.yml

# Install Knitro
Use "pip install ." at the directoty of "setup.py" or "python setup.py install" to install the Knitro