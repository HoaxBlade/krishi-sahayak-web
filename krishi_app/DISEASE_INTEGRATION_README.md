# Disease Information Integration

This template provides comprehensive disease information for crop analysis results using Google's Gemini AI API.

## Features

### 🦠 **Disease Information Model** (`models/disease_info.dart`)

- Complete disease data structure with symptoms, causes, prevention, and treatment
- Severity levels and environmental conditions
- Helper methods for data validation and color coding

### 🤖 **Gemini AI Service** (`services/gemini_disease_service.dart`)

- Integration with Google Gemini API for disease descriptions
- Structured prompts for consistent AI responses
- Fallback to default information when API fails
- Environment variable configuration for API key

### 🎨 **Disease Details Dialog** (`widgets/disease_details_dialog.dart`)

- Beautiful tabbed interface with 4 sections:
  - **Overview**: Description, seasonality, environmental conditions
  - **Symptoms**: Visual symptoms with color-coded indicators
  - **Prevention**: Actionable prevention methods
  - **Treatment**: Treatment options and recommendations
- Responsive design with proper error handling
- Image display for analyzed crop photos

### 📱 **Enhanced Crop Screen** (`screens/crop_screen.dart`)

- "Learn More" button for diseased crops
- Loading states during API calls
- Error handling with user-friendly messages
- Separate views for healthy vs diseased crops

## Setup Instructions

### 1. **Get Gemini API Key**

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Copy the key

### 2. **Configure Environment Variables**

Add your API key to the `.env` file in your Flutter app root:

```env
GEMINI_API_KEY=your_actual_api_key_here
```

### 3. **Update pubspec.yaml**

Ensure you have the required dependencies:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
  http: ^1.1.0
```

### 4. **Load Environment Variables**

In your `main.dart`, load the environment variables:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

## Usage

### **For Diseased Crops:**

When a disease is detected, users can:

1. Tap the "Learn More" button in the analysis list
2. View comprehensive disease information in a tabbed dialog
3. Get actionable prevention and treatment advice

### **For Healthy Crops:**

Shows basic analysis details without disease-specific information.

## API Response Format

The Gemini API is prompted to return structured JSON:

```json
{
  "diseaseName": "Early Blight",
  "cropType": "Tomato",
  "description": "A fungal disease that affects tomato plants...",
  "symptoms": ["Dark spots on leaves", "Yellowing of foliage"],
  "causes": ["High humidity", "Poor air circulation"],
  "preventionMethods": ["Proper spacing", "Avoid overhead watering"],
  "treatmentOptions": ["Fungicide application", "Remove infected leaves"],
  "severity": "moderate",
  "seasonality": "Common in warm, humid conditions",
  "environmentalConditions": "Favored by temperatures 75-85°F"
}
```

## Customization

### **Modify Prompts**

Edit the `_buildDiseasePrompt()` method in `gemini_disease_service.dart` to customize the AI responses.

### **Add More Information**

Extend the `DiseaseInfo` model to include additional fields like:

- Economic impact
- Resistant varieties
- Cultural practices
- Monitoring techniques

### **Styling**

Customize the dialog appearance by modifying `disease_details_dialog.dart`:

- Colors and themes
- Layout and spacing
- Icon choices
- Animation effects

## Error Handling

The system includes comprehensive error handling:

- API failures fall back to default information
- Network issues show user-friendly messages
- Invalid responses are handled gracefully
- Loading states provide user feedback

## Future Enhancements

- **Caching**: Store disease information locally to reduce API calls
- **Offline Mode**: Cache common diseases for offline access
- **Multilingual**: Support for multiple languages
- **Images**: Include disease symptom images
- **Notifications**: Alert farmers about disease outbreaks
- **Expert Consultation**: Connect with agricultural experts
