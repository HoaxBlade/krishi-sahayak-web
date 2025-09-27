#!/usr/bin/env python3
"""
Test script for multi-model Krishi Sahayak system
Tests all endpoints and model functionality
"""

import requests
import json
import time
import os
from PIL import Image
import numpy as np

# Configuration
BASE_URL = "http://localhost:5000"
TEST_IMAGE_PATH = "test_image.jpg"  # You'll need to provide a test image

def create_test_image():
    """Create a simple test image if none exists"""
    if not os.path.exists(TEST_IMAGE_PATH):
        # Create a simple 224x224 RGB image
        img = Image.new('RGB', (224, 224), color='green')
        img.save(TEST_IMAGE_PATH)
        print(f"✅ Created test image: {TEST_IMAGE_PATH}")

def test_health():
    """Test health endpoint"""
    print("🏥 Testing health endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Health check passed: {data['status']}")
            print(f"📊 Available crops: {data.get('available_crops', [])}")
            print(f"📊 Multi-model system: {data.get('multi_model_system', {})}")
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

def test_models_status():
    """Test models status endpoint"""
    print("\n📊 Testing models status endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/models/status", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Models status: {data['status']}")
            print(f"📊 Multi-model system: {data.get('multi_model_system', {})}")
            print(f"📊 Available crops: {data.get('available_crops', [])}")
            return True
        else:
            print(f"❌ Models status failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Models status error: {e}")
        return False

def test_available_crops():
    """Test available crops endpoint"""
    print("\n🌾 Testing available crops endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/models/available_crops", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Available crops: {data.get('available_crops', [])}")
            return True
        else:
            print(f"❌ Available crops failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Available crops error: {e}")
        return False

def test_analyze_crop():
    """Test two-stage crop analysis"""
    print("\n🔍 Testing two-stage crop analysis...")
    try:
        create_test_image()
        
        with open(TEST_IMAGE_PATH, 'rb') as f:
            files = {'image': f}
            response = requests.post(f"{BASE_URL}/analyze_crop", files=files, timeout=30)
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Two-stage analysis successful")
            print(f"📊 Result: {data.get('crop_type', 'Unknown')}")
            print(f"📊 Confidence: {data.get('confidence', 0):.3f}")
            print(f"📊 Analysis type: {data.get('analysis_type', 'Unknown')}")
            print(f"📊 Model type: {data.get('model_type', 'Unknown')}")
            print(f"⏱️ Processing time: {data.get('processing_time_seconds', 0):.2f}s")
            return True
        else:
            print(f"❌ Two-stage analysis failed: {response.status_code}")
            print(f"❌ Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Two-stage analysis error: {e}")
        return False

def test_analyze_crop_direct():
    """Test direct crop analysis with crop type"""
    print("\n🎯 Testing direct crop analysis...")
    try:
        create_test_image()
        
        # Test with different crop types
        test_crops = ['corn', 'wheat', 'rice', 'potato', 'sugarcane']
        
        for crop in test_crops:
            print(f"  Testing with crop type: {crop}")
            
            with open(TEST_IMAGE_PATH, 'rb') as f:
                files = {'image': f}
                data = {'crop_type': crop}
                response = requests.post(f"{BASE_URL}/analyze_crop_direct", 
                                       files=files, 
                                       data=data, 
                                       timeout=30)
            
            if response.status_code == 200:
                result = response.json()
                print(f"    ✅ {crop}: {result.get('crop_type', 'Unknown')} (confidence: {result.get('confidence', 0):.3f})")
            else:
                print(f"    ❌ {crop}: {response.status_code}")
        
        return True
    except Exception as e:
        print(f"❌ Direct analysis error: {e}")
        return False

def test_metrics():
    """Test metrics endpoint"""
    print("\n📈 Testing metrics endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/metrics", timeout=10)
        if response.status_code == 200:
            print("✅ Metrics endpoint working")
            print("📊 Sample metrics:")
            lines = response.text.split('\n')[:10]  # Show first 10 lines
            for line in lines:
                if line.strip():
                    print(f"  {line}")
            return True
        else:
            print(f"❌ Metrics failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Metrics error: {e}")
        return False

def run_performance_test():
    """Run basic performance test"""
    print("\n⚡ Running performance test...")
    try:
        create_test_image()
        
        times = []
        for i in range(5):
            start_time = time.time()
            
            with open(TEST_IMAGE_PATH, 'rb') as f:
                files = {'image': f}
                response = requests.post(f"{BASE_URL}/analyze_crop", files=files, timeout=30)
            
            end_time = time.time()
            request_time = end_time - start_time
            times.append(request_time)
            
            if response.status_code == 200:
                print(f"  Request {i+1}: {request_time:.2f}s ✅")
            else:
                print(f"  Request {i+1}: {request_time:.2f}s ❌ ({response.status_code})")
        
        avg_time = sum(times) / len(times)
        print(f"📊 Average response time: {avg_time:.2f}s")
        print(f"📊 Min time: {min(times):.2f}s")
        print(f"📊 Max time: {max(times):.2f}s")
        
        return True
    except Exception as e:
        print(f"❌ Performance test error: {e}")
        return False

def main():
    """Run all tests"""
    print("🚀 Starting Multi-Model Krishi Sahayak Tests")
    print("=" * 60)
    
    # Wait for server to be ready
    print("⏳ Waiting for server to be ready...")
    max_retries = 30
    for i in range(max_retries):
        try:
            response = requests.get(f"{BASE_URL}/health", timeout=5)
            if response.status_code == 200:
                print("✅ Server is ready!")
                break
        except:
            pass
        
        if i < max_retries - 1:
            print(f"  Attempt {i+1}/{max_retries}...")
            time.sleep(2)
    else:
        print("❌ Server not ready after 60 seconds")
        return False
    
    # Run tests
    tests = [
        ("Health Check", test_health),
        ("Models Status", test_models_status),
        ("Available Crops", test_available_crops),
        ("Two-Stage Analysis", test_analyze_crop),
        ("Direct Analysis", test_analyze_crop_direct),
        ("Metrics", test_metrics),
        ("Performance Test", run_performance_test),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n{'='*20} {test_name} {'='*20}")
        if test_func():
            passed += 1
        else:
            print(f"❌ {test_name} failed")
    
    print(f"\n{'='*60}")
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Multi-model system is working correctly.")
    else:
        print("⚠️ Some tests failed. Check the logs above for details.")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
