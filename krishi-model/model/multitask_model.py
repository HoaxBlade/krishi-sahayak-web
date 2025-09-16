from tensorflow.keras.applications import MobileNetV2 # type: ignore
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout, Lambda, BatchNormalization # type: ignore
from tensorflow.keras.models import Model # type: ignore
from tensorflow.keras.regularizers import l2 # type: ignore
import tensorflow as tf # type: ignore

def build_multitask_model(num_classes):
    base = MobileNetV2(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
    for layer in base.layers[-50:]:
        layer.trainable = True
        
    x = base.output
    x = GlobalAveragePooling2D()(x)
    x = BatchNormalization()(x)
    x = Dropout(0.4)(x)

    # Classification head
    class_output = Dense(
        num_classes,
        activation='softmax',
        name='class_output',
        kernel_regularizer=l2(0.001)
    )(x)

    # Regression head (scaled sigmoid for [0–100])
    reg_output_raw = Dense(
        1,
        activation='sigmoid',
        kernel_regularizer=l2(0.001)
    )(x)

    reg_output = Lambda(lambda t: tf.keras.activations.sigmoid(t) * 100, name='reg_output')(reg_output_raw)

    model = Model(inputs=base.input, outputs={'class_output': class_output, 'reg_output': reg_output})
    return model

def build_multi_head_model(num_crop_types, num_disease_classes, input_shape=(224, 224, 3)):
    """
    Builds a MobileNetV2-based model with two output heads:
    one for crop type classification and one for disease/health status classification.
    """
    base_model = MobileNetV2(input_shape=input_shape,
                             include_top=False,
                             weights='imagenet')

    # Freeze the base model initially
    for layer in base_model.layers:
        layer.trainable = False
        
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = BatchNormalization()(x)
    x = Dense(256, activation='relu')(x)
    x = Dropout(0.5)(x)

    # Crop Type Classification Head
    crop_type_output = Dense(
        num_crop_types,
        activation='softmax',
        name='crop_type_output',
        kernel_regularizer=l2(0.001)
    )(x)

    # Disease/Health Status Classification Head
    disease_output = Dense(
        num_disease_classes,
        activation='softmax',
        name='disease_output',
        kernel_regularizer=l2(0.001)
    )(x)

    model = Model(inputs=base_model.input, outputs={'crop_type_output': crop_type_output, 'disease_output': disease_output})
    return model