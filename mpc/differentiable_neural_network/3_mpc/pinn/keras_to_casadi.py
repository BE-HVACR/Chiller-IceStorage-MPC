"""
Module: keras_to_casadi.py
Description: Converts a trained Keras model (including Dense, BatchNormalization, Normalization, Lambda, and custom masking layers)
             into a CasADi symbolic function for use in optimization frameworks (e.g., MPC).
"""

import tensorflow as tf
import casadi as ca
import numpy as np

def casadi_activation(x, act_name):
    """Map Keras activation functions to CasADi expressions."""
    act_name = act_name.lower() if act_name else None
    if act_name in ['relu']:
        return ca.fmax(x, 0)
    elif act_name in ['sigmoid']:
        return 1 / (1 + ca.exp(-x))
    elif act_name in ['tanh']:
        return ca.tanh(x)
    elif act_name in ['softplus']:
        return ca.log(1 + ca.exp(x))
    elif act_name in ['linear', None]:
        return x
    else:
        raise NotImplementedError(f"Unsupported activation: {act_name}")

def convert_keras_to_casadi(keras_model_path):
    """
    Convert a trained Keras model (.h5 or .keras) to a CasADi function.

    Args:
        keras_model_path (str): Path to the Keras model file.

    Returns:
        casadi.Function: CasADi symbolic function equivalent to the Keras model.
    """
    keras_model = tf.keras.models.load_model(keras_model_path, compile=False, custom_objects={
        'PowerOutputMasked': PowerOutputMasked
    })

    layers = keras_model.layers
    x_dim = keras_model.input_shape[-1]
    x_sym = ca.MX.sym('x', x_dim)
    z = x_sym

    for layer in layers:
        if isinstance(layer, tf.keras.layers.InputLayer):
            continue  # Skip input layer

        elif isinstance(layer, tf.keras.layers.Normalization):
            mean = layer.mean.numpy()
            var = layer.variance.numpy()
            epsilon = 1e-6  # small value for numerical stability

            mean = ca.DM(mean).T  # reshape to column vector
            var = ca.DM(var).T
            z = (z - mean) / ca.sqrt(var + epsilon)

        elif isinstance(layer, tf.keras.layers.Dense):
            W, b = layer.get_weights()
            W = W.T
            z = ca.mtimes(W, z) + b
            z = casadi_activation(z, layer.activation.__name__)

        elif isinstance(layer, tf.keras.layers.BatchNormalization):
            gamma, beta, mean, var = layer.get_weights()
            epsilon = layer.epsilon
            z = gamma * (z - mean) / ca.sqrt(var + epsilon) + beta

        elif isinstance(layer, tf.keras.layers.Lambda):
            func = layer.function
            if hasattr(func, '__name__') and func.__name__ == '<lambda>':
                z = ca.fmin(ca.fmax(z, 0.0), 1.0)
            else:
                raise NotImplementedError("Only tf.clip_by_value lambda layers are supported.")

        elif isinstance(layer, tf.keras.layers.Dropout):
            continue  # Skip dropout during inference

        elif layer.__class__.__name__ == 'PowerOutputMasked':
            uMod = x_sym[0]  # Assumes uModActual is the first feature
            mask = ca.if_else(uMod != 0, 1.0, 0.0)
            z = z * mask

        else:
            raise NotImplementedError(f"Unsupported layer type: {type(layer)}")

    return ca.Function('nn_casadi', [x_sym], [z])

class PowerOutputMasked(tf.keras.layers.Layer):
    def call(self, inputs, power_pred):
        uMod = inputs[:, 0:1]
        mask = tf.cast(tf.not_equal(uMod, 0), tf.float32)
        return power_pred * mask