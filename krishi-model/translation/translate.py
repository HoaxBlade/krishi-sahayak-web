from deep_translator import GoogleTranslator

# Comprehensive mapping of Indian state official languages + prominent regional dialects
INDIAN_LANGUAGES = {
    "assamese": "as",
    "bengali": "bn",
    "bhojpuri": "bho",
    "dogri": "doi",
    "gujarati": "gu",
    "hindi": "hi",
    "kannada": "kn",
    "konkani": "gom",
    "maithili": "mai",
    "malayalam": "ml",
    "marathi": "mr",
    "meiteilon (manipuri)": "mni-Mtei",
    "mizo": "lus",
    "nepali": "ne",
    "odia (oriya)": "or",
    "punjabi": "pa",
    "sanskrit": "sa",
    "sindhi": "sd",
    "tamil": "ta",
    "telugu": "te",
    "urdu": "ur",
    "english": "en"
}

def translate_text(
    text: str,
    source: str = "en",
    target_lang: str = "hindi",
    max_chunk_size: int = 5000
) -> str:
    """
    Translate text from source language to target Indian language.
    Automatically batches text ≤ max_chunk_size without breaking words.
    """
    try:
        target = INDIAN_LANGUAGES.get(target_lang.lower())
        if not target:
            raise ValueError(f"Language '{target_lang}' not supported.")

        words = text.split()
        chunks, current_chunk = [], ""

        for word in words:
            if len(current_chunk) + len(word) + 1 <= max_chunk_size:
                current_chunk += word + " "
            else:
                chunks.append(current_chunk.strip())
                current_chunk = word + " "

        if current_chunk:
            chunks.append(current_chunk.strip())

        translated_chunks = [
            GoogleTranslator(source=source, target=target).translate(chunk)
            for chunk in chunks
        ]

        return " ".join(translated_chunks).strip()

    except Exception as e:
        return f"Translation failed: {e}"

# Example usage
if __name__ == "__main__":
    text = "Spray your corn with recommended fungicides like propiconazole or tebuconazole when you see orange-brown spots, plant resistant varieties, keep plants spaced well, and remove infected crop residues to control common rust."
    translated = translate_text(text, source="en", target_lang="hindi")
    print(f"Translated Text: {translated}")