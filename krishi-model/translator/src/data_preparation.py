import os
from datasets import load_dataset
from transformers import AutoTokenizer
import re
import collections
import numpy as np
import pickle
import yaml

# This file will contain code for dataset identification, download, and preprocessing.

# Load configuration
with open('config/config.yaml', 'r') as f:
    config = yaml.safe_load(f)

data_params = config['data_params']

def clean_text(text):
    """
    Cleans the input text by removing extra spaces and converting to lowercase.
    """
    text = text.lower()
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def tokenize_and_build_vocab(dataset, lang_code, tokenizer_name="Helsinki-NLP/opus-mt-en-hi", max_vocab_size=data_params['vocab_size']):
    """
    Tokenizes sentences and builds a vocabulary for a given language.
    """
    tokenizer = AutoTokenizer.from_pretrained(tokenizer_name)
    
    all_tokens = []
    tokenized_sentences = []

    for entry in dataset:
        text = entry['translation'][lang_code]
        cleaned_text = clean_text(text)
        tokens = tokenizer.tokenize(cleaned_text)
        all_tokens.extend(tokens)
        tokenized_sentences.append(tokens)

    # Build vocabulary
    word_counts = collections.Counter(all_tokens)
    sorted_vocab = sorted(word_counts, key=word_counts.get, reverse=True)
    
    # Add special tokens
    vocab = {"<pad>": 0, "<unk>": 1, "<sos>": 2, "<eos>": 3}
    for i, word in enumerate(sorted_vocab):
        if len(vocab) < max_vocab_size:
            vocab[word] = len(vocab)
        else:
            break
    
    return tokenized_sentences, vocab, tokenizer

def text_to_sequences(tokenized_sentences, vocab):
    """
    Converts tokenized sentences to numerical sequences.
    """
    numerical_sequences = []
    for tokens in tokenized_sentences:
        seq = [vocab.get(token, vocab["<unk>"]) for token in tokens]
        numerical_sequences.append(seq)
    return numerical_sequences

def pad_sequences(sequences, max_len=None, padding_value=0):
    """
    Pads sequences to a uniform length.
    """
    if max_len is None:
        max_len = max(len(seq) for seq in sequences)
    
    padded_sequences = np.full((len(sequences), max_len), padding_value, dtype=np.int32)
    for i, seq in enumerate(sequences):
        length = min(len(seq), max_len)
        padded_sequences[i, :length] = seq[:length]
    return padded_sequences

def download_and_load_dataset(dataset_name="cfilt/iitb-english-hindi"):
    """
    Downloads and loads the specified English-Hindi parallel corpus from Hugging Face.
    """
    print(f"Attempting to load dataset: {dataset_name}")
    try:
        dataset = load_dataset(dataset_name, "default")
        print("Dataset loaded successfully!")
        print(dataset)
        return dataset
    except Exception as e:
        print(f"Error loading dataset: {e}")
        return None

if __name__ == "__main__":
    # Ensure the data directory exists
    os.makedirs(data_params['processed_data_path'], exist_ok=True)

    # Step 1 & 2: Identify and Download the dataset
    raw_dataset = download_and_load_dataset()

    if raw_dataset:
        print("Dataset download and initial loading complete. Starting preprocessing...")

        # Take a smaller subset of the dataset for prototyping
        subset_size = data_params['subset_size']
        print(f"Using a subset of {subset_size} examples from the training set.")
        subset_dataset = raw_dataset['train'].select(range(subset_size))

        # Extract English and Hindi sentences from the subset
        english_sentences = [entry['translation']['en'] for entry in subset_dataset]
        hindi_sentences = [entry['translation']['hi'] for entry in subset_dataset]

        # Tokenize and build vocabulary for English
        print("Processing English data...")
        tokenized_english, english_vocab, english_tokenizer = tokenize_and_build_vocab(subset_dataset, 'en')
        english_sequences = text_to_sequences(tokenized_english, english_vocab)
        
        # Tokenize and build vocabulary for Hindi
        print("Processing Hindi data...")
        tokenized_hindi, hindi_vocab, hindi_tokenizer = tokenize_and_build_vocab(subset_dataset, 'hi')
        hindi_sequences = text_to_sequences(tokenized_hindi, hindi_vocab)

        # Set a fixed maximum sequence length to prevent memory issues
        fixed_max_seq_len = data_params['max_sequence_length']

        print(f"Using fixed maximum sequence length for padding: {fixed_max_seq_len}")

        # Pad sequences
        padded_english_sequences = pad_sequences(english_sequences, max_len=fixed_max_seq_len)
        padded_hindi_sequences = pad_sequences(hindi_sequences, max_len=fixed_max_seq_len)

        print("Preprocessing complete. Saving processed data...")

        # Save processed data
        np.save(os.path.join(data_params['processed_data_path'], "padded_english_sequences.npy"), padded_english_sequences)
        np.save(os.path.join(data_params['processed_data_path'], "padded_hindi_sequences.npy"), padded_hindi_sequences)

        with open(os.path.join(data_params['processed_data_path'], "english_vocab.pkl"), "wb") as f:
            pickle.dump(english_vocab, f)
        with open(os.path.join(data_params['processed_data_path'], "hindi_vocab.pkl"), "wb") as f:
            pickle.dump(hindi_vocab, f)
        
        print(f"Processed data saved to '{data_params['processed_data_path']}' directory.")

    else:
        print("Failed to download or load the dataset. Please check the dataset name or your internet connection.")