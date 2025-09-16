import tensorflow as tf
import numpy as np
import pickle
import os
import yaml
import mlflow
import mlflow.tensorflow
from sklearn.model_selection import train_test_split
from translation_model import Encoder, Decoder, BahdanauAttention # Assuming translation_model.py is in the same directory

# Load configuration
with open('config/config.yaml', 'r') as f:
    config = yaml.safe_load(f)

data_params = config['data_params']
model_params = config['model_params']

# Define paths
PROCESSED_DATA_DIR = data_params['processed_data_path']
MODELS_DIR = 'models/'

# Load data
english_sequences = np.load(os.path.join(PROCESSED_DATA_DIR, 'padded_english_sequences.npy'))
hindi_sequences = np.load(os.path.join(PROCESSED_DATA_DIR, 'padded_hindi_sequences.npy'))

with open(os.path.join(PROCESSED_DATA_DIR, 'english_vocab.pkl'), 'rb') as f:
    english_vocab = pickle.load(f)

with open(os.path.join(PROCESSED_DATA_DIR, 'hindi_vocab.pkl'), 'rb') as f:
    hindi_vocab = pickle.load(f)

# Vocabulary sizes
BUFFER_SIZE = len(english_sequences)
BATCH_SIZE = model_params['batch_size']
embedding_dim = model_params['embedding_dim']
units = model_params['latent_dim']
english_vocab_size = len(english_vocab)
hindi_vocab_size = len(hindi_vocab)
max_english_len = english_sequences.shape[1]
max_hindi_len = hindi_sequences.shape[1]

# Create id_to_word mappings
english_id_to_word = {idx: word for word, idx in english_vocab.items()}
hindi_id_to_word = {idx: word for word, idx in hindi_vocab.items()}

# Create tf.data datasets
dataset = tf.data.Dataset.from_tensor_slices((english_sequences, hindi_sequences))
dataset = dataset.shuffle(BUFFER_SIZE).batch(BATCH_SIZE, drop_remainder=True)
dataset = dataset.prefetch(tf.data.AUTOTUNE) # Prefetch for performance

# Split data into training and validation sets
# This is a simplified split. For a real project, you might want to ensure no data leakage.
# Using .take() and .skip() on a shuffled dataset might not result in a perfect split,
# but for demonstration purposes and faster iteration, it's acceptable.
num_batches = tf.data.experimental.cardinality(dataset).numpy()
train_size = int(0.8 * num_batches)

train_dataset = dataset.take(train_size)
val_dataset = dataset.skip(train_size)

# Initialize models
encoder = Encoder(english_vocab_size, embedding_dim, units, BATCH_SIZE)
decoder = Decoder(hindi_vocab_size, embedding_dim, units, BATCH_SIZE)

optimizer = tf.keras.optimizers.Adam()
loss_object = tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True, reduction='none')

def loss_function(real, pred):
    mask = tf.math.logical_not(tf.math.equal(real, 0))
    loss_ = loss_object(real, pred)
    mask = tf.cast(mask, dtype=loss_.dtype)
    loss_ *= mask
    return tf.reduce_mean(loss_)

# Training step
@tf.function
def train_step(inp, targ, enc_hidden):
    loss = 0

    with tf.GradientTape() as tape:
        enc_output, enc_hidden_h, enc_hidden_c = encoder(inp, enc_hidden)
        dec_hidden = [enc_hidden_h, enc_hidden_c]
        dec_input = tf.expand_dims([hindi_vocab['<sos>']] * BATCH_SIZE, 1)

        # Teacher forcing - feeding the target as the next input
        for t in range(1, targ.shape[1]):
            # passing enc_output to the decoder
            predictions, dec_hidden_h, dec_hidden_c, _ = decoder(dec_input, dec_hidden, enc_output)
            dec_hidden = [dec_hidden_h, dec_hidden_c]
            loss += loss_function(targ[:, t], predictions)

            # using teacher forcing
            dec_input = tf.expand_dims(targ[:, t], 1)

    batch_loss = (loss / int(targ.shape[1]))
    variables = encoder.trainable_variables + decoder.trainable_variables
    gradients = tape.gradient(loss, variables)
    optimizer.apply_gradients(zip(gradients, variables))
    return batch_loss

def train_model(epochs):
    checkpoint_dir = os.path.join(MODELS_DIR, 'checkpoints')
    checkpoint_prefix = os.path.join(checkpoint_dir, "ckpt")
    checkpoint = tf.train.Checkpoint(optimizer=optimizer,
                                     encoder=encoder,
                                     decoder=decoder)

    if not os.path.exists(checkpoint_dir):
        os.makedirs(checkpoint_dir)

    # MLflow Tracking
    with mlflow.start_run():
        mlflow.log_params(data_params)
        mlflow.log_params(model_params)

        best_val_loss = float('inf')
        
        for epoch in range(epochs):
            enc_hidden = encoder.initialize_hidden_state()
            total_train_loss = 0

            for (batch, (inp, targ)) in enumerate(train_dataset.as_numpy_iterator()):
                batch_loss = train_step(inp, targ, enc_hidden)
                total_train_loss += batch_loss

                if batch % 100 == 0:
                    print(f'Epoch {epoch+1} Batch {batch} Train Loss {batch_loss.numpy():.4f}')

            avg_train_loss = total_train_loss / len(train_dataset)
            mlflow.log_metric("train_loss", avg_train_loss.numpy(), step=epoch)

            # Validation loss (simplified, not using BLEU for now)
            total_val_loss = 0
            for (batch, (inp, targ)) in enumerate(val_dataset.as_numpy_iterator()):
                enc_output, enc_hidden_h, enc_hidden_c = encoder(inp, enc_hidden)
                dec_hidden = [enc_hidden_h, enc_hidden_c]
                dec_input = tf.expand_dims([hindi_vocab['<sos>']] * BATCH_SIZE, 1) # Changed <start> to <sos>
                val_batch_loss = 0
                for t in range(1, targ.shape[1]):
                    predictions, dec_hidden_h, dec_hidden_c, _ = decoder(dec_input, dec_hidden, enc_output)
                    dec_hidden = [dec_hidden_h, dec_hidden_c]
                    val_batch_loss += loss_function(targ[:, t], predictions)
                    dec_input = tf.expand_dims(targ[:, t], 1)
                total_val_loss += (val_batch_loss / int(targ.shape[1]))

            avg_val_loss = total_val_loss / len(val_dataset)
            mlflow.log_metric("val_loss", avg_val_loss.numpy(), step=epoch)

            print(f'Epoch {epoch+1} Train Loss {avg_train_loss:.4f} Val Loss {avg_val_loss:.4f}')

            # Saving the model every 2 epochs
            if (epoch + 1) % 2 == 0:
                checkpoint.save(file_prefix=checkpoint_prefix)
                print(f'Checkpoint saved for epoch {epoch+1}')

            # Register the model if it has the best validation loss
            if avg_val_loss < best_val_loss:
                best_val_loss = avg_val_loss
                mlflow.tensorflow.log_model(
                    tf_model=encoder,
                    artifact_path="encoder_model",
                    registered_model_name="TranslationEncoder",
                    signature=mlflow.models.infer_signature(english_sequences, encoder(english_sequences[:1], encoder.initialize_hidden_state())[0])
                )
                mlflow.tensorflow.log_model(
                    tf_model=decoder,
                    artifact_path="decoder_model",
                    registered_model_name="TranslationDecoder",
                    signature=mlflow.models.infer_signature(tf.expand_dims([hindi_vocab['<sos>']] * BATCH_SIZE, 1), decoder(tf.expand_dims([hindi_vocab['<sos>']] * BATCH_SIZE, 1), [encoder.initialize_hidden_state()[1], encoder.initialize_hidden_state()[2]], encoder(english_sequences[:1], encoder.initialize_hidden_state())[0])[0])
                )
                print(f"Model registered with MLflow Model Registry for epoch {epoch+1} with validation loss: {best_val_loss:.4f}")

        print("Final model saved.")

if __name__ == '__main__':
    # Ensure models directory exists
    if not os.path.exists(MODELS_DIR):
        os.makedirs(MODELS_DIR)
    train_model(epochs=model_params['epochs'])