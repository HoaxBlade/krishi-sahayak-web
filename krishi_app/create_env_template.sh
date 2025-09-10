#!/bin/bash

# Template script to create .env file for Krishi App
# IMPORTANT: Replace YOUR_API_KEY_HERE with your actual OpenWeatherMap API key

echo "🔧 Creating .env file for Krishi App..."
echo ""

# Check if .env already exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists!"
    echo "📝 Current content:"
    cat .env
    echo ""
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted. .env file not modified."
        exit 1
    fi
fi

# Get API key from user
echo "🔑 Please enter your OpenWeatherMap API key:"
echo "   (Get it from: https://openweathermap.org/api)"
read -p "API Key: " api_key

if [ -z "$api_key" ]; then
    echo "❌ API key cannot be empty!"
    exit 1
fi

# Get Supabase configuration
echo ""
echo "🏗️ Please enter your Supabase configuration:"
echo "   (Get it from: https://supabase.com/dashboard/project/YOUR_PROJECT/settings/api)"
read -p "Supabase URL: " supabase_url
read -p "Supabase Anon Key: " supabase_anon_key

if [ -z "$supabase_url" ] || [ -z "$supabase_anon_key" ]; then
    echo "⚠️ Supabase configuration is optional but recommended for production"
    supabase_url="YOUR_SUPABASE_URL"
    supabase_anon_key="YOUR_SUPABASE_ANON_KEY"
fi

# Create .env file
cat > .env << EOF
# Weather API Configuration
OPENWEATHERMAP_API_KEY=$api_key

# Supabase Configuration
SUPABASE_URL=$supabase_url
SUPABASE_ANON_KEY=$supabase_anon_key

# App Configuration (optional)
APP_NAME=Krishi Sahayak
APP_VERSION=1.0.0
ENVIRONMENT=development
EOF

echo "✅ .env file created successfully!"
echo "📁 Location: $(pwd)/.env"
echo ""
echo "📝 Content:"
cat .env
echo ""
echo "🎉 You can now run your Flutter app!"
echo "💡 The weather service will use your real API key."
echo ""
echo "⚠️  IMPORTANT: Never commit this .env file to git!"
echo "   It's already added to .gitignore for safety."
