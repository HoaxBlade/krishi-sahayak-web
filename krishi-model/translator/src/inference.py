import argparse
from transformers import pipeline
import yaml

# --- Configuration Loading ---
def load_config(config_path="config/config.yaml"):
    with open(config_path, 'r') as file:
        return yaml.safe_load(file)

config = load_config()

# --- Model Loading ---
# Load the Helsinki-NLP/opus-mt-en-hi model using the Hugging Face pipeline
translator = pipeline("translation", model="Helsinki-NLP/opus-mt-en-hi")

# --- Translation Function ---
def translate_sentence(english_sentence: str) -> str:
    # The pipeline expects a list of strings and returns a list of dictionaries
    result = translator(english_sentence)
    # Extract the translated text from the result
    hindi_translation = result[0]['translation_text']
    return hindi_translation

# --- Command-Line Interface ---
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="English to Hindi Translation Model Inference")
    parser.add_argument("sentence", type=str, help="The English sentence to translate.")
    args = parser.parse_args()

    translated_sentence = translate_sentence(args.sentence)
    print(f"English: {args.sentence}")
    print(f"Hindi: {translated_sentence}")