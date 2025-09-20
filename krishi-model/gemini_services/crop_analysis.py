# crop_disease_helper.py

import os
import sys
from dotenv import load_dotenv
import google.generativeai as genai

# Add krishi-model folder to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from translation.translate import translate_text

# Load environment variables from a .env file
load_dotenv()

# Set up your Gemini API key from the environment variable
genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))

def agri_gemini_service(crop, crop_disease, target_language=None):
    """
    A Gemini-based service for farmers that provides factual information
    on crop diseases in simple, clear, farmer-friendly language.
    """

    try:
        # Create a Generative Model instance
        model = genai.GenerativeModel('gemini-1.5-flash')

        # Farmer-friendly prompt
        prompt = f"""
You are an agricultural advisor for small and marginal farmers.  
Explain crop diseases in simple everyday language that a farmer can understand.  

Crop: "{crop}"  
Disease: "{crop_disease}"  

Rules:
1. Do not use technical or scientific names. Use plain words like "tiny fungus" or "small insect."
2. Structure the answer in 4 sections with these exact headings:
   - Why it is Caused?
   - How to Prevent it?
   - What are the Remedies?
   - What Can Be Used for Treatment?
3. Each section should have 2-3 short, clear sentences.
4. Only suggest proven remedies. Include one natural option and one general medicine/fungicide option in plain words.
5. End with: "Important: Always read product labels carefully and consult a local agricultural expert before using any chemical solution."
"""

        response = model.generate_content(prompt)

        if not response.text:
            return "Sorry, I could not generate information for this disease."

        # Preserve headings and line breaks
        output_text = f"**Crop: {crop}** 🌾\n**Disease: {crop_disease}**\n\n{response.text}"

        # Translate if target_language is specified
        if target_language:
            translated_text = translate_text(output_text, source="en", target_lang=target_language)
            return translated_text
        else:
            return output_text

    except Exception as e:
        return f"An error occurred: {e}"


# --- Example Usage ---
if __name__ == "__main__":
    crop_name = "Corn"
    disease_name = "Gray Leaf Spot"

    # English output
    info = agri_gemini_service(crop_name, disease_name)
    print(info)

    print("\n--- Translated (Hindi) ---\n")
    translated_info = agri_gemini_service(crop_name, disease_name, target_language="hindi")
    print(translated_info)