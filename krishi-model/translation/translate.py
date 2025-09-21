from googletrans import Translator

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

translator = Translator()

def translate_text(
    text: str,
    source: str = "en",
    target_lang: str = "hindi",
    max_chunk_size: int = 5000,
    verbose: bool = False
) -> str:
    """
    Translate text from source language to target Indian language.
    Automatically batches text ≤ max_chunk_size without breaking words.

    Args:
        text (str): Input text to translate.
        source (str): Source language code (default: "en").
        target_lang (str): Target language name (must exist in INDIAN_LANGUAGES).
        max_chunk_size (int): Maximum characters per translation batch.
        verbose (bool): If True, print debug info.

    Returns:
        str: Translated text or error message.
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

        translated_chunks = []
        for idx, chunk in enumerate(chunks, start=1):
            try:
                translated = translator.translate(chunk, src=source, dest=target).text
                translated_chunks.append(translated)
                if verbose:
                    print(f"[Chunk {idx}] Success")
            except Exception as ce:
                if verbose:
                    print(f"[Chunk {idx}] Failed: {ce}")
                translated_chunks.append(chunk)  # fallback to original text

        return " ".join(translated_chunks).strip()

    except Exception as e:
        return f"Translation failed: {e}"


# Example usage
if __name__ == "__main__":
    text = (
        "Spray your corn with recommended fungicides like propiconazole or tebuconazole "
        "when you see orange-brown spots, plant resistant varieties, keep plants spaced well, "
        "and remove infected crop residues to control common rust."
    )
    translated = translate_text(text, source="en", target_lang="hindi", verbose=True)
    print(f"\nTranslated Text:\n{translated}")
