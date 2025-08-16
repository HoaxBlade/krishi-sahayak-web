# Environment Variables Setup Guide

## Overview

This app uses environment variables to securely store API keys and configuration values.

## Required Setup

### 1. Install flutter_dotenv

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

Then run:

```bash
flutter pub get
```

### 2. Create .env file

Create a `.env` file in your `krishi_app` root directory with the following content:

```bash
# Weather API Configuration
OPENWEATHERMAP_API_KEY=your_actual_api_key_here

# App Configuration (optional)
APP_NAME=Krishi Sahayak
APP_VERSION=1.0.0
ENVIRONMENT=development
```

### 3. Get Your OpenWeatherMap API Key

1. Go to [openweathermap.org](https://openweathermap.org/api)
2. Sign up for a free account
3. Navigate to "My API Keys"
4. Copy your API key
5. Replace `your_actual_api_key_here` in the `.env` file

### 4. Add .env to .gitignore

Make sure your `.env` file is in `.gitignore` to keep your API keys secure:

```gitignore
# Environment variables
.env
```

## How It Works

The `ConfigService` automatically loads your `.env` file and makes the values available throughout the app:

```dart
// In any service or widget
final configService = ConfigService();
final apiKey = configService.openWeatherMapApiKey;
```

## Security Notes

- ✅ **DO**: Keep your `.env` file in `.gitignore`
- ✅ **DO**: Use different API keys for development and production
- ❌ **DON'T**: Commit API keys to version control
- ❌ **DON'T**: Share your `.env` file publicly

## Troubleshooting

### "API key not found" error

- Check that your `.env` file exists in the `krishi_app` root directory
- Verify the variable name is exactly `OPENWEATHERMAP_API_KEY`
- Make sure there are no extra spaces or quotes around the value

### "Failed to load environment configuration" error

- Ensure `flutter_dotenv` is added to `pubspec.yaml`
- Run `flutter pub get` after adding the dependency
- Check that the `.env` file path is correct
