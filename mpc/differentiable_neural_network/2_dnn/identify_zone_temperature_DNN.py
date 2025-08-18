import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
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

def zone_temp_DNN(data, features, target, zonNam):
    print(type(features))
    X = data[features].values
    Y = data[target].values

    # Split the dataset into train and test sets randomly
    x_train, x_test, y_train, y_test = train_test_split(X, Y, test_size=0.2, random_state=44)

    # # Split the dataset in continuous time-series
    # split_point = int(0.8 * len(X))  # 80% split
    # x_train, x_test = X[:split_point], X[split_point:]
    # y_train, y_test = Y[:split_point], Y[split_point:]

    # Neural Network Model
    def build_model(input_shape):
        '''Build neural network models from Tensorflow to support automatic differentiation
        '''
        # Initialize a Normalization layer
        normalizer = tf.keras.layers.Normalization(axis=-1)
        
        # L2 regularization factor (lambda)
        l2_lambda = 0.01

        # Create the Sequential model
        model = tf.keras.Sequential([
            # Add the Normalization layer first
            normalizer,
            # Followed by the Dense layers
            tf.keras.layers.Dense(64, activation='relu', input_shape=input_shape, # activation='softplus'
                                  kernel_regularizer=tf.keras.regularizers.L2(l2_lambda),
                                  ),
            tf.keras.layers.Dense(64, activation='relu',
                                  kernel_regularizer=tf.keras.regularizers.L2(l2_lambda),
                                  ),
            tf.keras.layers.Dense(1)  # Single output node for regression
        ])
        model.compile(optimizer='adam', loss='mean_squared_error')
        
        # Before returning, adapt the normalizer based on the training data. 
        # This calculates the mean and variance of the data which will be used for scaling during both training and inference.
        normalizer.adapt(x_train)

        return model

    # Create the neural network model
    nn_model = build_model((x_train.shape[1],))

    # Callbacks for early stopping and learning rate scheduling:
    # EarlyStopping: Stops training when the validation loss hasn't improved for a number of epochs (patience), and restores the best weights.
    # ReduceLROnPlateau: Reduces the learning rate when the validation loss stops improving, which can help the optimizer converge.
    early_stopping = tf.keras.callbacks.EarlyStopping(monitor='val_loss', patience=10, restore_best_weights=True)
    lr_scheduler = tf.keras.callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.1, patience=5)
    # Sensitivity analysis

    # Train the model
    history = nn_model.fit(x_train, y_train,
                            epochs=2000,
                            batch_size=32,
                            verbose=1,
                            validation_split=0.2,
                            callbacks=[early_stopping, lr_scheduler]
                            )

    nn_model.summary()

    # Evaluate the model
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
    
    print("\n========Results of Model Training for:",zonNam,"zone temperature:========")
    # Define the diagonal line (1:1 line)
    min_val = min(min(y_train), min(y_test))  # Get the minimum value from both sets
    max_val = max(max(y_train), max(y_test))  # Get the maximum value from both sets
    diagonal = np.linspace(min_val, max_val, 100).flatten()
    
    # Plotting training and testing results
    plt.figure(figsize=(14, 6))

    plt.subplot(1, 2, 1)
    plt.scatter(y_train, y_pred_train, label='Train', color='blue', alpha=0.6)
    plt.plot(diagonal, diagonal, color='black', linestyle='--', label='1:1 Line')
    plt.fill_between(diagonal, 0.85 * diagonal, 1.15 * diagonal, color='gray', alpha=0.2, label='±15% Interval')
    plt.title('Training Data with R2 = {:.3f}'.format(r2_train))
    plt.xlabel('True Values')
    plt.ylabel('Predictions')
    plt.legend()
    # Set the x and y limits to ensure the same range
    plt.xlim([min_val, max_val])
    plt.ylim([min_val, max_val])
    # plt.xlim([20, 30])
    # plt.ylim([20, 30])    

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
    # plt.xlim([20, 30])
    # plt.ylim([20, 30])    
        
    plt.savefig('./results_dnn/Tz_'+str(zonNam)+'_Tset24_DNN_scatter.png')
    plt.show()

    # Save the model
    nn_model.save('./results_dnn/dnn_model_'+str(zonNam)+'_temperature.h5')

    # To load the model later
    # loaded_model = tf.keras.models.load_model('dnn_model.h5')


    ### Metrics
    ## ==================================================================
    # Metric Results of Training Data
    MSE_train = mean_squared_error(y_train,y_pred_train)
    RMSE_train = MSE_train**0.5
    mean_train = np.mean(y_train)
    print ("\n------Metric Results of Training data------")
    print(f"R2_train: {r2_train}")
    print("mean_train:",mean_train,"MSE_train:",MSE_train,"RMSE_train",RMSE_train)
    print("NMBE_train:",MSE_train/mean_train/(len(data)*0.8-7))
    print("CV(RMSE)_train:",RMSE_train/mean_train)

    # Metric Results of Testing data
    MSE_test = mean_squared_error(y_test,y_pred_test)
    RMSE_test = MSE_test**0.5
    mean_test = np.mean(y_test)
    print ("\n------Metric Results of Testing data------")
    print(f"R2_test: {r2_test}")
    print("mean_test:",mean_test,"MSE_test:",MSE_test,"RMSE_test",RMSE_test)
    print("NMBE_test:",MSE_test/mean_test/(len(data)*0.2-7))
    print("CV(RMSE)_test:",RMSE_test/mean_test)

    # plot
    plt.figure()
    # plt.subplot(311)
    # plt.plot(y_train,'b-',lw=0.5,label='Target in Training')
    # plt.plot(y_pred_train,'r--',lw=0.5,markevery=0.05,marker='o',markersize=2,label='Prediction in Training')
    # plt.ylabel('Temperature(C)')
    # plt.legend(loc='upper right')

    plt.subplot(211)
    plt.plot(y_test,'b-',lw=0.5,label='Target in Testing')
    plt.plot(y_pred_test,'r--',lw=0.5,markevery=0.05,marker='o',markersize=2,label='Prediction in Testing')
    plt.ylabel('Temperature(°C)')
    plt.legend(loc='upper right')
    plt.title('Trained NN model with RMSE = {:.3f}°C'.format(RMSE_test))

    plt.subplot(212)
    plt.plot(y_pred_test-y_test.flatten(), 'b-', label='Prediction Errors in Testing')
    plt.ylabel('Error(°C)')
    #plt.title('Prediction Errors in Testing')
    plt.legend(loc='upper right')

    plt.savefig('./results_dnn/Tz_'+str(zonNam)+'_Tset24_DNN_error.png')
    plt.show()

    # history stores the loss/val in each epoch
    loss_df = pd.DataFrame(history.history)
    loss_df.loc[:,['loss','val_loss']].plot()
    plt.show()


# train the model for zone temperature prediction
features_core = ['tesBed.uModActual.y',
                 #'tesBed.iceTan.SOC_his1',
                 #'tesBed.conVAVCor.TZon_his4','tesBed.conVAVCor.TZon_his3','tesBed.conVAVCor.TZon_his2',
                 'tesBed.conVAVCor.TZon_his1', 
                 #'tesBed.TOut.y_his4','tesBed.TOut.y_his3','tesBed.TOut.y_his2',
                 #'tesBed.TOut.y_his1',
                 #'tesBed.TOut.y',
                 #'tesBed.weaBus.HGloHor_his4','tesBed.weaBus.HGloHor_his3','tesBed.weaBus.HGloHor_his2',
                 #'tesBed.weaBus.HGloHor_his1', 
                 #'tesBed.weaBus.HGloHor',
                 ]
features_east = ['tesBed.uModActual.y',
                 'tesBed.conVAVEas.TZon_his1', 
                 ]
features_north = ['tesBed.uModActual.y',
                  'tesBed.conVAVNor.TZon_his1', 
                 ]
features_south = ['tesBed.uModActual.y',
                  'tesBed.conVAVSou.TZon_his1', 
                 ]
features_west = ['tesBed.uModActual.y',
                 'tesBed.conVAVWes.TZon_his1', 
                 ]

target_core = ['tesBed.conVAVCor.TZon']
target_east = ['tesBed.conVAVEas.TZon']
target_north = ['tesBed.conVAVNor.TZon']
target_south = ['tesBed.conVAVSou.TZon']
target_west = ['tesBed.conVAVWes.TZon']

zone_temp_DNN(data=data, features=features_core, target=target_core, zonNam='core')
zone_temp_DNN(data=data, features=features_east, target=target_east, zonNam='east')
zone_temp_DNN(data=data, features=features_north, target=target_north, zonNam='north')
zone_temp_DNN(data=data, features=features_south, target=target_south, zonNam='south')
zone_temp_DNN(data=data, features=features_west, target=target_west, zonNam='west')


##=====open-loop evaluation: the predicted zonal temperature is used to predict the next-step zonal temperature=======
def open_loop_zone_temp_DNN(model_path, data, features, target, updated_var_name, start_day, num_days, zonNam):
    # Load the trained model
    nn_model = tf.keras.models.load_model(model_path)

    # Select features and target
    X = data[features].values
    Y = data[target].values

    # Determine the index of predicted variable in the features list dynamically
    updated_var_index = features.index(updated_var_name)

    # Determine dataset split point
    split_point = int(0.5 * len(X))  # 80% split
    x_train, x_test = X[:split_point], X[split_point:]
    y_train, y_test = Y[:split_point], Y[split_point:]

    # Define steps for open-loop testing
    steps_per_hour = int(3600/timestep)
    steps_per_day = int(24*3600/timestep)  # Number of steps for one day (288 for 5-minute intervals, 24 for 1-hour intervals)

    # Total steps for multi-day testing
    total_steps = int(num_days * steps_per_day)

    # Start testing from a given day
    start_step = int(steps_per_day * start_day)

    # Ensure there are enough data points after the start_step
    if start_step + total_steps > len(x_test):
        raise ValueError("Not enough data points after the chosen start day for multi-day open-loop testing.")

    # Initialize variables for open-loop testing
    y_open_loop = []
    y_true = []

    # Initialize with the first value from the test dataset starting from start_step
    predicted_value = x_test[start_step, updated_var_index]  # Starting with the first historical value (for temperature prediction)

    # Open-loop testing loop for multi-day testing
    for step in range(total_steps):
        # Get current inputs from the test dataset for the features except for the target variable
        current_input = x_test[start_step + step:start_step + step + 1].copy()

        # Update the historical value feature with the predicted value for this time step
        current_input[0, updated_var_index] = predicted_value

        # Predict the next step value using the model
        predicted_value = max(20, min(nn_model.predict(current_input)[0][0], 30)) # add bounds for predicted temperature

        # Store the predicted value and true value for comparison
        y_open_loop.append(predicted_value)
        y_true.append(y_test[start_step + step][0])

    # Convert results to numpy arrays for easier calculations
    y_open_loop = np.array(y_open_loop)
    y_true = np.array(y_true)

    # Calculate evaluation metrics
    mse_open_loop = np.mean((y_open_loop - y_true) ** 2)
    rmse_open_loop = np.sqrt(mse_open_loop)
    mean_true = np.mean(y_true)
    cvrmse_open_loop = (rmse_open_loop / mean_true) * 100
    r2_open_loop = r2_score(y_true, y_open_loop)

    # Print evaluation metrics
    print(f"Open-loop RMSE: {rmse_open_loop:.3f}°C")
    print(f"Open-loop CV(RMSE): {cvrmse_open_loop:.2f}%")
    print(f"Open-loop R2: {r2_open_loop:.2f}")

    # Plot the results with multi-day hourly intervals on the x-axis
    plt.figure(figsize=(10, 5))

    # Create x-axis labels for each hour across the total testing period
    total_hours = total_steps // steps_per_hour  # Total number of hours for the testing period
    hourly_indices = np.arange(0, total_steps, steps_per_hour)  # Indices for plotting hourly points
    hour_labels = np.arange(total_hours)  # Labels for hours

    # Plot the true and predicted values
    plt.plot(y_true, label='True', marker='o', markersize=3)
    plt.plot(y_open_loop, label='Predicted (Open-loop)', linestyle='--', marker='x', markersize=3)

    # Set the x-axis to display hourly intervals across multiple days
    plt.xticks(hourly_indices, hour_labels)
    plt.xlabel('Time (Hours)')
    plt.ylabel('Temperature (°C)')
    plt.title(f'Open-loop Testing Results (RMSE={rmse_open_loop:.2f}°C, R2={r2_open_loop:.2f})')
    plt.legend()
    plt.grid(True)
    plt.savefig('./results_dnn//open_loop_test_'+str(zonNam)+'_zone.png')

    # Show the plot
    plt.show()


# plot open-loop testing
open_loop_zone_temp_DNN(
    model_path='./results_dnn/dnn_model_core_temperature.h5',
    data=data,
    features=features_core,
    target=target_core,
    updated_var_name='tesBed.conVAVCor.TZon_his1',  # Variable to update during open-loop
    start_day=0,  # Start day 
    num_days=2,  # testing days
    zonNam='core',
    )

open_loop_zone_temp_DNN(
    model_path='./results_dnn/dnn_model_east_temperature.h5',
    data=data,
    features=features_east,
    target=target_east,
    updated_var_name='tesBed.conVAVEas.TZon_his1',  # Variable to update during open-loop
    start_day=0,  # Start day
    num_days=2,  # testing days
    zonNam='east',
    )

open_loop_zone_temp_DNN(
    model_path='./results_dnn/dnn_model_north_temperature.h5',
    data=data,
    features=features_north,
    target=target_north,
    updated_var_name='tesBed.conVAVNor.TZon_his1',  # Variable to update during open-loop
    start_day=0,  # Start day
    num_days=2,  # testing days
    zonNam='north',
    )

open_loop_zone_temp_DNN(
    model_path='./results_dnn/dnn_model_south_temperature.h5',
    data=data,
    features=features_south,
    target=target_south,
    updated_var_name='tesBed.conVAVSou.TZon_his1',  # Variable to update during open-loop
    start_day=0,  # Start day
    num_days=2,  # testing days
    zonNam='south',
    )

open_loop_zone_temp_DNN(
    model_path='./results_dnn/dnn_model_west_temperature.h5',
    data=data,
    features=features_west,
    target=target_west,
    updated_var_name='tesBed.conVAVWes.TZon_his1',  # Variable to update during open-loop
    start_day=0,  # Start day
    num_days=2,  # testing days
    zonNam='west',
    )
