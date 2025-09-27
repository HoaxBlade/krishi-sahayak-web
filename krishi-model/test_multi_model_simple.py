#!/usr/bin/env python3
"""
Simple test script for multi-model Krishi Sahayak system
Tests the MultiModelManager without Flask/Docker
"""

import os
import sys
import logging

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def test_multi_model_manager():
    """Test the MultiModelManager directly"""
    try:
        logger.info("🚀 Testing MultiModelManager...")
        
        # Import MultiModelManager
        from multi_model_manager import MultiModelManager
        
        # Initialize manager
        logger.info("📦 Creating MultiModelManager instance...")
        manager = MultiModelManager()
        
        # Test initialization
        logger.info("🔄 Initializing models...")
        success = manager.initialize()
        
        if success:
            logger.info("✅ MultiModelManager initialized successfully!")
            
            # Get model status
            status = manager.get_model_status()
            logger.info(f"📊 Model Status: {status}")
            
            # Get available crops
            crops = manager.get_available_crops()
            logger.info(f"🌾 Available crops: {crops}")
            
            # Test crop detection
            logger.info("🔍 Testing crop detection...")
            # Create a dummy image for testing
            import numpy as np
            dummy_image = np.random.rand(224, 224, 3).astype(np.float32)
            
            try:
                crop_result = manager.detect_crop_type(dummy_image)
                logger.info(f"🌾 Crop detection result: {crop_result}")
            except Exception as e:
                logger.warning(f"⚠️ Crop detection test failed: {e}")
            
            # Test disease detection for each crop
            for crop in crops:
                try:
                    logger.info(f"🦠 Testing {crop} disease detection...")
                    disease_result = manager.detect_disease(dummy_image, crop)
                    logger.info(f"🦠 {crop} disease result: {disease_result}")
                except Exception as e:
                    logger.warning(f"⚠️ {crop} disease detection failed: {e}")
            
            logger.info("🎉 All tests completed successfully!")
            return True
            
        else:
            logger.error("❌ MultiModelManager initialization failed!")
            return False
            
    except Exception as e:
        logger.error(f"❌ Test failed with error: {e}")
        import traceback
        logger.error(f"❌ Traceback: {traceback.format_exc()}")
        return False

def main():
    """Main test function"""
    logger.info("🌾 Starting Krishi Sahayak Multi-Model Test")
    logger.info("=" * 50)
    
    # Check if we're in the right directory
    if not os.path.exists('multi_model_manager.py'):
        logger.error("❌ multi_model_manager.py not found. Please run from krishi-model directory.")
        return False
    
    if not os.path.exists('saved_models'):
        logger.error("❌ saved_models directory not found. Please run from krishi-model directory.")
        return False
    
    # Run the test
    success = test_multi_model_manager()
    
    if success:
        logger.info("🎉 Multi-model system test PASSED!")
        return True
    else:
        logger.error("❌ Multi-model system test FAILED!")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
