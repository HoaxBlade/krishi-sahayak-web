from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout
from tensorflow.keras.models import Model
from tensorflow.keras.regularizers import l2

def build_multitask_model(num_classes):
    base = MobileNetV2(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
    base.trainable = False

    x = base.output
    x = GlobalAveragePooling2D()(x)
    x = Dropout(0.3)(x)

    # Classification head
    class_output = Dense(
        num_classes,
        activation='softmax',
        name='class_output',
        kernel_regularizer=l2(0.001)  # L2 regularization
    )(x)

    # Regression head
    reg_output = Dense(
        1,
        activation='sigmoid',  # [0,1]
        name='reg_output',
        kernel_regularizer=l2(0.001)
    )(x)

    reg_output_scaled = reg_output * 100  # scale to [0, 100]

    model = Model(inputs=base.input, outputs=[class_output, reg_output_scaled])
    return model