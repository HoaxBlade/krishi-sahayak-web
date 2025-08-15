#!/bin/bash

# Script to create .env file for Krishi App

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

# Create .env file
cat > .env << 'EOF'
# Weather API Configuration
OPENWEATHERMAP_API_KEY=bf5945787401f51daf7ce7f1fe7a2779

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
