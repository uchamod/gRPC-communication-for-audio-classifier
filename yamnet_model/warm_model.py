# warm_model.py - Script to pre-warm the model
import os
import sys
import time
import logging
import tensorflow_hub as hub
from yamnet_utils import class_names_from_csv

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def warm_model():
    """Pre-warm the YAMNet model"""
    try:
        logger.info("Starting model pre-warming...")
        start_time = time.time()
        
        # Load the model
        yamnet_model = hub.load('https://tfhub.dev/google/yamnet/1')
        logger.info(f"Model loaded in {time.time() - start_time:.2f}s")
        
        # Load class names
        class_map_path = yamnet_model.class_map_path().numpy()
        class_names = class_names_from_csv(class_map_path)
        logger.info(f"Class names loaded. Total classes: {len(class_names)}")
        
        # Create a dummy prediction to fully initialize
        import numpy as np
        dummy_audio = np.random.random(16000).astype(np.float32)  # 1 second of random audio
        
        # Run inference
        _, embeddings, spectrogram = yamnet_model(dummy_audio)
        logger.info(f"Dummy prediction completed. Model fully warmed.")
        
        total_time = time.time() - start_time
        logger.info(f"Model pre-warming completed successfully in {total_time:.2f}s")
        
        return True
        
    except Exception as e:
        logger.error(f"Model pre-warming failed: {str(e)}")
        return False

if __name__ == "__main__":
    success = warm_model()
    sys.exit(0 if success else 1)