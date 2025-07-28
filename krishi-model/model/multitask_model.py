from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout, Lambda, BatchNormalization
from tensorflow.keras.models import Model
from tensorflow.keras.regularizers import l2
import tensorflow as tf

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