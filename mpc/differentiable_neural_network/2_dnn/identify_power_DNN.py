import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split, KFold
from sklearn.metrics import mean_squared_error, r2_score
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import random
import os
# Add a random seed to ensure the reproducibility of neural network's results
# Set random seeds
random.seed(42)
np.random.seed(42)
tf.random.set_seed(42)
# For complete reproducibility, you may also want to configure TensorFlow to run operations deterministically
# Ensure deterministic operations
os.environ['TF_DETERMINISTIC_OPS'] = '1'


data = pd.read_csv('prepared_data_1hr.csv',index_col=[0])

# Group by the interval of timestep (e.g., 1 hour) and pick one row of each timestep for training 
timestep = 3600 # seconds in one time step
data['time'] = (data['time'] // timestep) * timestep
data = data.groupby('time').last() # pick the last row of each timestep 

# Select features and target
features = ['tesBed.uModActual.y', # -1: Charge TES; 0: off; 1: Discharge TES; 2: Discharge chiller
            #'bChi.y', # Chiller on/off
            #'bIce.y', # TES on/off
            #'tesBed.occSch.occupied', # Occupied status
            #'tesBed.iceTan.SOC_his1',#'tesBed.iceTan.SOC', # SOC
            #'tesBed.ave.y_his1',#'tesBed.ave.y', # Average Zonal temperature 
            #'tesBed.TOut.y_his1',
            'tesBed.TOut.y', #'tesBed.TOut.y_his4','tesBed.TOut.y_his3','tesBed.TOut.y_his2', # Toa dry bulb 
            #'tesBed.weaBus.TWetBul', # Toa wet bulb
            #'tesBed.weaBus.HGloHor_his1',
            #'tesBed.weaBus.HGloHor', #'tesBed.weaBus.HGloHor_his4','tesBed.weaBus.HGloHor_his3','tesBed.weaBus.HGloHor_his2', # Global horizontal solar irradiation [W/m2]
            # 'tesBed.TCHWSup.T', # CHW supply temperature
            # 'tesBed.secPum.m_flow', # water flow rate of secondary pump
            # 'tesBed.senSupFlo.V_flow', # AHU supply air flow rate
            # 'tesBed.conAHU.TSup', # AHU supply air temperature
            #'Ptot_his1', # Total power
            ]
target = ['Ptot'] # total power of chiller + primary pump + secondary pump + AHU fan

X = data[features].values
Y = data[target].values

# Split the dataset into train and test sets randomly
x_train, x_test, y_train, y_test = train_test_split(X, Y, test_size=0.2, random_state=44)

# Split the dataset in continuous time-series
split_point = int(0.8 * len(X))  # 80% split
x_train, x_test = X[:split_point], X[split_point:]
y_train, y_test = Y[:split_point], Y[split_point:]

# Neural Network Model
def build_model(input_shape, neurons=64, learning_rate=0.001):
    '''Build neural network models from Tensorflow to support automatic differentiation
    '''
    # Initialize a Normalization layer
    normalizer = tf.keras.layers.Normalization(axis=-1)
    
    # L2 regularization factor (lambda)
    l2_lambda = 0.01

    # Create the Sequential model
    model = tf.keras.Sequential([
        ## Add the Normalization layer first
        normalizer,
        # Followed by the Dense layers
        tf.keras.layers.Dense(neurons, activation='softplus', input_shape=input_shape, kernel_regularizer=tf.keras.regularizers.L2(l2_lambda)), # activation='softplus': smooth approximation of ReLU, convex and differentiable 
        tf.keras.layers.Dense(neurons, activation='softplus', kernel_regularizer=tf.keras.regularizers.L2(l2_lambda)),
        tf.keras.layers.Dense(1)  # Single output node for regression
    ])
    optimizer = tf.keras.optimizers.Adam(learning_rate=learning_rate)
    model.compile(optimizer=optimizer, loss='mean_squared_error')
    
    # # Before returning, adapt the normalizer based on the training data. 
    # # This calculates the mean and variance of the data which will be used for scaling during both training and inference.
    # # This assumes that `x_train` is available and has been passed to this function or is globally available
    normalizer.adapt(x_train)

    return model

# # Create the neural network model
# nn_model = build_model((x_train.shape[1],))

# # Callbacks for early stopping and learning rate scheduling:
# # EarlyStopping: Stops training when the validation loss hasn't improved for a number of epochs (patience), and restores the best weights.
# # ReduceLROnPlateau: Reduces the learning rate when the validation loss stops improving, which can help the optimizer converge.
# early_stopping = tf.keras.callbacks.EarlyStopping(monitor='val_loss', patience=10, restore_best_weights=True)
# lr_scheduler = tf.keras.callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.1, patience=5)
# # To-do: Sensitivity analysis

# # Train the model
# history = nn_model.fit(
#     x_train, y_train,
#     epochs=2000,
#     batch_size=32,
#     verbose=1,
#     validation_split=0.2,
#     callbacks=[early_stopping, lr_scheduler]
# )

# nn_model.summary()

## Create the neural network model with K-Fold Cross-Validation and Random Search
kfold = KFold(n_splits=5, shuffle=True, random_state=42)
best_model = None
best_score = float('inf')
best_params = {}

# # Hyperparameter search space
# param_grid = {
#     'neurons': [16, 32, 64],
#     'batch_size': [16, 32, 64],
#     'learning_rate': [0.001, 0.01, 0.1]
# }
# Best configuration from the hyperparameter search space
param_grid = {
    'neurons': [32],
    'batch_size': [16],
    'learning_rate': [0.1]
}

# Random search
for neurons in param_grid['neurons']:
    for batch_size in param_grid['batch_size']:
        for learning_rate in param_grid['learning_rate']:
            print(f"Testing configuration: neurons={neurons}, batch_size={batch_size}, learning_rate={learning_rate}")
            fold_scores = []
            
            for train_idx, val_idx in kfold.split(X):
                x_train, x_val = X[train_idx], X[val_idx]
                y_train, y_val = Y[train_idx], Y[val_idx]
                
                # Build and train the model
                model = build_model((x_train.shape[1],), neurons=neurons, learning_rate=learning_rate)
                early_stopping = tf.keras.callbacks.EarlyStopping(monitor='val_loss', patience=10, restore_best_weights=True)
                history = model.fit(
                    x_train, y_train,
                    epochs=2000,
                    batch_size=batch_size,
                    verbose=0,
                    validation_data=(x_val, y_val),
                    callbacks=[early_stopping]
                )
                
                # Evaluate on the validation set
                y_val_pred = model.predict(x_val).flatten()
                val_score = mean_squared_error(y_val, y_val_pred)
                fold_scores.append(val_score)
            
            # Average score across folds
            avg_score = np.mean(fold_scores)
            print(f"Average MSE for configuration: {avg_score}")
            
            # Update best model if this configuration is better
            if avg_score < best_score:
                best_score = avg_score
                best_model = model
                best_params = {'neurons': neurons, 'batch_size': batch_size, 'learning_rate': learning_rate}

# Output the best parameters and model
print("Best Configuration:", best_params)
print("Best MSE:", best_score)

# Save the best model
best_model.save('./results_dnn/dnn_power_model.h5')

# history stores the loss/val in each epoch
loss_df = pd.DataFrame(history.history)
loss_df.loc[:,['loss','val_loss']].plot()
plt.show()

print("\n========Evaluation Results of Trained Model:========")
# Evaluate the model
nn_model = best_model
y_pred_train = nn_model.predict(x_train)
y_pred_test = nn_model.predict(x_test)
#This is a common situation in machine learning workflows where the model predictions are returned as a two-dimensional array, even for single output predictions.
#To make the shapes consistent for one-dimensional array
y_pred_train = y_pred_train.flatten()
y_pred_test = y_pred_test.flatten()

# Calculate metrics
r2_train = r2_score(y_train, y_pred_train)
mse_train = mean_squared_error(y_train, y_pred_train)
r2_test = r2_score(y_test, y_pred_test)
mse_test = mean_squared_error(y_test, y_pred_test)
# Print out the metrics
print(f"Training R2 Score: {r2_train}")
print(f"Training MSE: {mse_train}")
print(f"Testing R2 Score: {r2_test}")
print(f"Testing MSE: {mse_test}")

### Metrics
## ==================================================================
# Metric Results of Training Data
MSE_train = mean_squared_error(y_train,y_pred_train)
RMSE_train = MSE_train**0.5
mean_train = np.mean(y_train)
print ("\n------Metric Results of Training data------")
print("mean_train:",mean_train,"MSE_train:",MSE_train,"RMSE_train",RMSE_train)
print("NMBE_train:",MSE_train/mean_train/(len(data)*0.8-1))
print("CV(RMSE)_train:",RMSE_train/mean_train)

# Metric Results of Testing data
MSE_test = mean_squared_error(y_test,y_pred_test)
RMSE_test = MSE_test**0.5
mean_test = np.mean(y_test)
print ("\n------Metric Results of Testing data------")
print("mean_test:",mean_test,"MSE_test:",MSE_test,"RMSE_test",RMSE_test)
print("NMBE_test:",MSE_test/mean_test/(len(data)*0.2-1))
print("CV(RMSE)_test:",RMSE_test/mean_test)


## Scatter plot of training and testing results
plt.figure(figsize=(14, 6))
# Define the diagonal line (1:1 line)
min_val = min(min(y_train), min(y_test))  # Get the minimum value from both sets
max_val = max(max(y_train), max(y_test))  # Get the maximum value from both sets
diagonal = np.linspace(min_val, max_val, 100).flatten()

# Plot training results
plt.subplot(1, 2, 1)
plt.scatter(y_train, y_pred_train, label='Train', color='blue', alpha=0.6)
plt.plot(diagonal, diagonal, color='black', linestyle='--', label='1:1 Line')
plt.fill_between(diagonal, 0.85 * diagonal, 1.15 * diagonal, color='gray', alpha=0.2, label='±15% Interval')
plt.title('Training Data with R2 = {:.3f}'.format(r2_train))
plt.xlabel('True Values')
plt.ylabel('Predictions')
plt.legend()
plt.xlim([min_val, max_val])
plt.ylim([min_val, max_val])

# Plot testing results
plt.subplot(1, 2, 2)
plt.scatter(y_test, y_pred_test, label='Test', color='blue', alpha=0.6)
plt.plot(diagonal, diagonal, color='black', linestyle='--', label='1:1 Line')
plt.fill_between(diagonal, 0.85 * diagonal, 1.15 * diagonal, color='gray', alpha=0.2, label='±15% Interval')
plt.title('Testing Data with R2 = {:.3f}'.format(r2_test))
plt.xlabel('True Values')
plt.ylabel('Predictions')
plt.legend()
plt.xlim([min_val, max_val])
plt.ylim([min_val, max_val])

# Save the figure
plt.savefig('./results_dnn/power_scatter.png')
plt.show()


## Error plot
plt.figure()
# plt.subplot(311)
# plt.plot(y_train,'b-',lw=0.5,label='Target in Training')
# plt.plot(y_pred_train,'r--',lw=0.5,markevery=0.05,marker='o',markersize=2,label='Prediction in Training')
# plt.ylabel('Temperature(C)')
# plt.legend(loc='upper right')

plt.subplot(211)
plt.plot(y_test,'b-',lw=0.5,label='Target in Testing')
plt.plot(y_pred_test,'r--',lw=0.5,markevery=0.05,marker='o',markersize=2,label='Prediction in Testing')
plt.ylabel('Power(W)')
plt.legend(loc='upper right')
plt.title('Trained NN model with RMSE = {:.0f} W and CVRMSE = {:.1f}%'.format(RMSE_test, RMSE_test/mean_test*100), fontsize=14)

plt.subplot(212)
plt.plot(y_pred_test-y_test.flatten(), 'b-', label='Prediction Errors in Testing')
plt.ylabel('Relative Error(W)')
plt.legend(loc='upper right')

plt.savefig('./results_dnn/power_error.png')
plt.show()



##=====open-loop evaluation: the predicted power is used to predict the next-step power=======
# Load the trained model
nn_model = tf.keras.models.load_model('./results_dnn/dnn_power_model.h5')

data = pd.read_csv('prepared_data_1hr.csv',index_col=[0])
# Group by the interval of timestep (e.g., 1 hour) and pick one row of each timestep for training 
timestep = 3600 # seconds in one time step
data['time'] = (data['time'] // timestep) * timestep
data = data.groupby('time').mean()

# Determine the index of predicted variable in the features list dynamically
updated_var_index = features.index('Ptot_his1')

X = data[features].values
Y = data[target].values

# Determine dataset split point
split_point = int(0.5 * len(X))  # 80% split
x_train, x_test = X[:split_point], X[split_point:]
y_train, y_test = Y[:split_point], Y[split_point:]

# Define steps for open-loop testing
steps_per_hour = int(3600/timestep)
steps_per_day = int(24*3600/timestep)  # Number of steps for one day (288 for 5-minute intervals, 24 for 1-hour intervals)

# Define testing duration in days
num_days = 2  # Specify the number of days for testing
total_steps = int(num_days * steps_per_day)

# Start day for testing (e.g., if the testing starts at the 80% split)
start_day = 0  # Define the starting day (you can modify this)
start_step = int(steps_per_day * start_day)

# Ensure there are enough data points after the start_step
if start_step + total_steps > len(x_test):
    raise ValueError("Not enough data points after the chosen start day for multi-day open-loop testing.")

# Initialize variables for open-loop testing
y_open_loop = []
y_true = []

# Initialize with the first value of Power from the test dataset starting from start_step
predicted_power = x_test[start_step, updated_var_index]  # Starting with the first historical Power

# Open-loop testing loop for multi-day testing
for step in range(total_steps):
    # Get current inputs from the test dataset for the features except for 'Ptot_his1'
    current_input = x_test[start_step + step:start_step + step + 1].copy()

    # Update the Ptot_his1 feature with the predicted power for this time step
    current_input[0, updated_var_index] = predicted_power  # Update the historical Power with the predicted one

    # Predict the next step Power using the model
    predicted_power = nn_model.predict(current_input)[0][0]

    # Store the predicted Power and true Power for comparison
    y_open_loop.append(predicted_power)
    y_true.append(y_test[start_step + step][0])  # Store the true Power for the same step

# Convert results to numpy arrays for easier calculations
y_open_loop = np.array(y_open_loop)
y_true = np.array(y_true)

# Calculate the open-loop evaluation metrics (e.g., RMSE, R2 score)
mse_open_loop = np.mean((y_open_loop - y_true) ** 2)
rmse_open_loop = np.sqrt(mse_open_loop)
mean_true = np.mean(y_true)
cvrmse_open_loop = (rmse_open_loop / mean_true) * 100

# Print evaluation metrics
print(f"Open-loop RMSE: {rmse_open_loop:.0f} W")
print(f"Open-loop CV(RMSE): {cvrmse_open_loop:.2f}%")

# Plot the results with multi-day hourly intervals on the x-axis
plt.figure(figsize=(10, 5))

# Create x-axis labels for each hour across the total testing period
total_hours = total_steps // steps_per_hour  # Total number of hours for the testing period
hourly_indices = np.arange(0, total_steps, steps_per_hour)  # Indices for plotting hourly points
hour_labels = np.arange(total_hours)  # Labels for hours

# Plot the true Power values and predicted Power values
plt.plot(y_true, label='True Power', marker='o', markersize=3)
plt.plot(y_open_loop, label='Predicted Power (Open-loop)', linestyle='--', marker='x', markersize=3)

# Set the x-axis to display hourly intervals across multiple days
plt.xticks(hourly_indices, hour_labels)
plt.xlabel('Time (Hours)')
plt.ylabel('Power (W)')
plt.title(f'Open-loop Testing Results (RMSE={rmse_open_loop:.0f} W, CV(RMSE)={cvrmse_open_loop:.2f}%)')
plt.legend()
plt.grid(True)

# Save the plot and show
plt.savefig(f'./results_dnn/open_loop_test_power.png')
plt.tight_layout()
plt.show()





##===========================Sensitivity Analysis===========================
## perturb each feature in the input data by a small percentage (or value) such as 1% and observe the effect on the predicted output

def sensitivity_analysis_discrete_continuous(model, X, feature_names, discrete_features, continuous_features, perturbation=0.01):
    """
    Perform sensitivity analysis on the trained neural network model for both discrete and continuous inputs.

    Parameters:
    model: Trained neural network model.
    X: Input data (e.g., x_test) for analysis.
    feature_names: List of feature names for interpretation.
    discrete_features: Dictionary where keys are indices of discrete features and values are lists of possible discrete values.
    continuous_features: List of indices of continuous features.
    perturbation: Fraction by which to perturb the continuous features (default is 1%).

    Returns:
    sensitivity_df: DataFrame containing the sensitivity of the output to each feature.
    """
    base_prediction = model.predict(X).flatten()  # Base prediction without perturbation
    sensitivities = {}

    # Handle continuous features by applying perturbations
    for i in continuous_features:
        feature = feature_names[i]
        X_perturbed = X.copy()
        X_perturbed[:, i] *= (1 + perturbation)  # Perturb the continuous feature by a small fraction
        perturbed_prediction = model.predict(X_perturbed).flatten()
        # Calculate sensitivity as the percentage change in prediction
        #sensitivity = np.abs((perturbed_prediction - base_prediction) / base_prediction) * 100
        sensitivity = (perturbed_prediction - base_prediction) / base_prediction * 100
        sensitivities[feature] = np.mean(sensitivity)  # Store the average sensitivity for this feature

    # Handle discrete features by testing each possible value
    for i, possible_values in discrete_features.items():
        feature = feature_names[i]
        sensitivities[feature] = []
        for value in possible_values:
            X_perturbed = X.copy()
            X_perturbed[:, i] = value  # Set the discrete feature to a specific value
            perturbed_prediction = model.predict(X_perturbed).flatten()
            # Calculate sensitivity as the percentage change in prediction
            #sensitivity = np.abs((perturbed_prediction - base_prediction) / base_prediction) * 100
            sensitivity = (perturbed_prediction - base_prediction) / base_prediction * 100
            sensitivities[feature].append((value, np.mean(sensitivity)))  # Store sensitivity for each discrete value

    # Prepare the sensitivity data for output
    sensitivity_data = []
    for feature, sensitivity in sensitivities.items():
        if isinstance(sensitivity, list):  # Discrete feature (multiple values)
            for value, sens in sensitivity:
                sensitivity_data.append((f'{feature}={value}', sens))
        else:  # Continuous feature
            sensitivity_data.append((feature, sensitivity))

    sensitivity_df = pd.DataFrame(sensitivity_data, columns=['Feature', 'Sensitivity (%)'])
    sensitivity_df.sort_values(by='Sensitivity (%)', ascending=False, inplace=True)
    
    return sensitivity_df

def plot_sensitivity_analysis(sensitivity_results, discrete_features_indices, continuous_features_indices, feature_names, save_path):
    """
    Plot the sensitivity analysis results with two subplots: 
    one for discrete inputs and one for continuous inputs.
    
    Parameters:
    sensitivity_results: DataFrame with the sensitivity analysis results.
    discrete_features_indices: List of indices for discrete features in the dataset.
    continuous_features_indices: List of indices for continuous features in the dataset.
    feature_names: List of feature names.
    """
    # Extract feature names for discrete and continuous features
    discrete_feature_names = [feature_names[i] for i in discrete_features_indices]
    continuous_feature_names = [feature_names[i] for i in continuous_features_indices]

    # Separate the sensitivity results for discrete and continuous features
    discrete_sensitivity = sensitivity_results[sensitivity_results['Feature'].str.contains('|'.join(discrete_feature_names))]
    continuous_sensitivity = sensitivity_results[sensitivity_results['Feature'].str.contains('|'.join(continuous_feature_names))]

    # Create a 1x2 subplot for discrete and continuous features
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

    # Plot the discrete feature sensitivities
    discrete_sensitivity.plot(kind='bar', x='Feature', y='Sensitivity (%)', legend=False, ax=ax1, color='skyblue')
    ax1.set_title('Sensitivity Analysis for Discrete Features')
    ax1.set_ylabel('Sensitivity (%)')
    ax1.set_xlabel('Feature and Value')
    ax1.tick_params(axis='x', rotation=45)

    # Plot the continuous feature sensitivities
    continuous_sensitivity.plot(kind='bar', x='Feature', y='Sensitivity (%)', legend=False, ax=ax2, color='salmon')
    ax2.set_title('Sensitivity Analysis for Continuous Features')
    ax2.set_ylabel('Sensitivity (%)')
    ax2.set_xlabel('Feature')
    ax2.tick_params(axis='x', rotation=45)

    # Adjust layout
    plt.tight_layout()
    plt.savefig(save_path)
    plt.show()

# Load the trained model
nn_model = tf.keras.models.load_model('./results_dnn/dnn_power_model.h5')

# List of feature names (same as the features used in the model)
feature_names = ['tesBed.uModActual.y', 'tesBed.TOut.y']

# Define discrete features and their possible values
discrete_features = {
                     0: [-1, 0, 1, 2],  # 'tesBed.uModActual.y'
                    }

# Define continuous features (by index)
continuous_features = [1]  # 'tesBed.TOut.y'

# Perform sensitivity analysis on the test data
sensitivity_results = sensitivity_analysis_discrete_continuous(nn_model, x_test, feature_names, discrete_features, continuous_features)

# Print sensitivity results
print("Sensitivity Analysis Results:")
print(sensitivity_results)

# Call the plotting function after performing sensitivity analysis
plot_sensitivity_analysis(
                            sensitivity_results, 
                            discrete_features_indices=[0],  # Indices for discrete features (e.g., 'tesBed.uModActual.y')
                            continuous_features_indices=[1],  # Indices for continuous features (e.g., 'tesBed.TOut.y')
                            feature_names=feature_names,  # List of all feature names
                            save_path = './results_dnn/sensitivity_analysis_power.png',
                        )