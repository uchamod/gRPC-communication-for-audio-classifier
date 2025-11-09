# app.py
from flask import Flask, request, jsonify
import os
from yamnet_utils import predict_sound,class_names_from_csv
from flask_cors import CORS
import subprocess
from werkzeug.utils import secure_filename
import uuid
import tempfile
import logging
import traceback
import tensorflow_hub as hub
import numpy as np
import threading
import time
from functools import wraps

#configure logging
logging.basicConfig(level=logging.INFO)
logger=logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)
# Configure a folder to temporarily store uploads
UPLOAD_FOLDER = 'temp_uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Global variables for model
yamnet_model = None
class_map_path=None
class_names=None
model_loaded = threading.Event()
model_loading_error = None
#load model initially
def load_model():
    """Load YAMNet model with error handling"""
    global yamnet_model
    global class_map_path
    global class_names
    global model_loading_error
    try:
        logger.info("Loading YAMNet model...")
        yamnet_model = hub.load('https://tfhub.dev/google/yamnet/1')
        class_map_path = yamnet_model.class_map_path().numpy()
        class_names = class_names_from_csv(class_map_path)
        logger.info("YAMNet model loaded successfully")
        model_loaded.set()  # Signal that model is ready
        return True
    except Exception as e:
        model_loading_error = str(e)
        logger.error(f"Failed to load YAMNet model: {str(e)}")
        logger.error(traceback.format_exc())
        model_loaded.set()  # Set event even on error to prevent hanging
        return False
    

def require_model(f):
    """Decorator to ensure model is loaded before processing requests"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Wait for model to load (with timeout)
        if not model_loaded.wait(timeout=180):  # 180 second timeout
            return jsonify({'error': 'Model loading timeout'}), 503
        
        if model_loading_error:
            return jsonify({'error': f'Model loading failed: {model_loading_error}'}), 503
            
        if yamnet_model is None:
            return jsonify({'error': 'Model not available'}), 503
            
        return f(*args, **kwargs)
    return decorated_function  
  
@app.route('/')
def home():
    return "YAMNet Audio Classification API is running."
# check status of server
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for Cloud Run"""
    try:
        if not model_loaded.is_set():
            return jsonify({'status': 'loading', 'message': 'Model is still loading'}), 202
        
        if model_loading_error:
            return jsonify({'status': 'unhealthy', 'message': f'Model loading failed: {model_loading_error}'}), 503
        
        if yamnet_model is None:
            return jsonify({'status': 'unhealthy', 'message': 'Model not loaded'}), 503
        
        return jsonify({'status': 'healthy', 'message': 'Service is running'}), 200
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({'status': 'unhealthy', 'message': str(e)}), 503
    
#check model status
@app.route('/model-status', methods=['GET'])
def model_status():
    """Check if model is ready for predictions"""
    if not model_loaded.is_set():
        return jsonify({'status': 'loading', 'message': 'Model is still loading'}), 202
    
    if model_loading_error:
        return jsonify({'status': 'error', 'message': model_loading_error}), 503
        
    if yamnet_model is None:
        return jsonify({'status': 'error', 'message': 'Model not available'}), 503
        
    return jsonify({'status': 'ready', 'message': 'Model is ready for predictions'}), 200

# predict sound
@app.route('/predict', methods=['POST'])
@require_model
def predict():
    start_time = time.time()

    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file provided'}), 400
    
    file = request.files['audio']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

   # Check file size (limit to 10MB)
    file.seek(0, os.SEEK_END)
    file_size = file.tell()
    file.seek(0)

    if file_size > 10 * 1024 * 1024:  # 10MB limit
        return jsonify({'error': 'File too large. Maximum size is 10MB'}), 400
    
    # Use temporary directory that gets automatically cleaned up
    with tempfile.TemporaryDirectory(prefix='yamnet_') as temp_dir:
        try:
            # Generate unique filenames
            unique_id = str(uuid.uuid4())
            filename = secure_filename(file.filename)
            base_name = os.path.splitext(filename)[0]
            
            input_filepath = os.path.join(temp_dir, f"{base_name}_{unique_id}{os.path.splitext(filename)[1]}")
            wav_filepath = os.path.join(temp_dir, f"{base_name}_{unique_id}.wav")

            # Save the uploaded file
            file.save(input_filepath)
            logger.info(f"Saved temporary file to {input_filepath}")
            
            # Convert using FFmpeg
            command = [
                'ffmpeg',
                '-i', input_filepath,
                '-y',
                '-ar', '16000',  # YAMNet expects 16kHz
                '-ac', '1',      # Mono
                '-f', 'wav',
                '-loglevel', 'error',
                '-hide_banner',
                wav_filepath
            ]


            conversion_start = time.time()
            result = subprocess.run(command, check=True, capture_output=True, text=True, timeout=30)
            conversion_time = time.time() - conversion_start
            logger.info(f"Audio conversion completed in {conversion_time:.2f}s")

            # Predict using the model
            prediction_start = time.time()
            prediction_result = predict_sound(wav_filepath,class_names)
            prediction_time = time.time() - prediction_start
           # return jsonify({'prediction': result})
            
            total_time = time.time() - start_time
            logger.info(f"Total processing time: {total_time:.2f}s (conversion: {conversion_time:.2f}s, prediction: {prediction_time:.2f}s)")
            return jsonify({
                'prediction': prediction_result,
                'processing_time': {
                    'total': round(total_time, 2),
                    'conversion': round(conversion_time, 2),
                    'prediction': round(prediction_time, 2)
                }
            })
        except subprocess.TimeoutExpired:
            logger.error("FFmpeg conversion timed out")
            return jsonify({'error': 'Audio conversion timed out'}), 500
        except subprocess.CalledProcessError as e:
            logger.error(f"FFmpeg conversion failed: {e.stderr}")
            return jsonify({'error': 'Audio conversion failed. Please check file format.'}), 500
        except Exception as e:
            logger.error(f"Error processing audio: {str(e)}")
            logger.error(traceback.format_exc())
            return jsonify({'error': 'Internal server error'}), 500

        # Temporary directory and all files are automatically cleaned up here  
  
# Cleanup function to remove old files on startup (optional)
def cleanup_old_files():
    """Remove any leftover files from previous runs"""
    if os.path.exists(UPLOAD_FOLDER):
        try:
            for filename in os.listdir(UPLOAD_FOLDER):
                filepath = os.path.join(UPLOAD_FOLDER, filename)
                if os.path.isfile(filepath):
                    os.remove(filepath)
                    logger.info(f"Removed old file: {filepath}")
        except Exception as e:
            logger.error(f"Error cleaning up old files: {str(e)}")


# Initialize model on startup - but don't block server start
def initialize_model_async():
    """Initialize the model in a separate thread"""
    logger.info("Starting model loading in background...")
    thread = threading.Thread(target=load_model)
    thread.daemon = True
    thread.start()
    return thread

# Start model loading immediately when module is imported
model_thread=initialize_model_async()

if __name__ == '__main__':
    # Wait for model to load when running directly
    logger.info("Waiting for model to load...")
    if model_loaded.wait(timeout=180):  # 2 minute timeout for direct run
        if model_loading_error:
            logger.error(f"Model loading failed: {model_loading_error}")
        else:
            logger.info("Model loaded successfully")
    else:
        logger.error("Model loading timed out")
    # Clean up any leftover files from previous runs
    cleanup_old_files()
    app.run(
       host='0.0.0.0',
       port=8080,
       debug=False
      )
