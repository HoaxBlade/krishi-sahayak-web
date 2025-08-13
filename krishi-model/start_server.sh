#!/bin/bash

echo "🚀 Starting Krishi ML Server..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install/upgrade requirements
echo "📥 Installing/upgrading requirements..."
pip install -r requirements.txt

# Start the server
echo "🌐 Starting Flask server..."
python main_production.py
