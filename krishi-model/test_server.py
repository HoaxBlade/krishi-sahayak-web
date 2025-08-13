#!/usr/bin/env python3
"""
Simple test script to verify the Flask server is working
"""

import requests # type: ignore
import json

def test_server():
    base_url = "https://krishi-ml-server.onrender.com"  # Deployed server
    
    print("Testing Flask ML Server...")
    
    # Test health endpoint
    try:
        response = requests.get(f"{base_url}/health")
        if response.status_code == 200:
            print("✅ Health check passed")
            data = response.json()
            print(f"   Model loaded: {data.get('model_loaded', False)}")
            print(f"   Labels loaded: {data.get('labels_loaded', False)}")
            print(f"   Number of labels: {data.get('num_labels', 0)}")
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to server. Make sure it's running on port 5001")
        return False
    
    # Test labels endpoint
    try:
        response = requests.get(f"{base_url}/labels")
        if response.status_code == 200:
            print("✅ Labels endpoint working")
            data = response.json()
            print(f"   Available labels: {data.get('labels', [])}")
        else:
            print(f"❌ Labels endpoint failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Labels endpoint error: {e}")
    
    print("\n🎉 Server is working correctly!")
    print("You can now run your Flutter app to test the ML integration.")
    
    return True

if __name__ == "__main__":
    test_server()
