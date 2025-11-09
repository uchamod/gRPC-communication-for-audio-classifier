# # app.py
# from flask import Flask, request, jsonify
# import os
# from yamnet_utils import predict_sound,class_names_from_csv
# from flask_cors import CORS
# import subprocess
# from werkzeug.utils import secure_filename
# import uuid
# import tempfile
# import logging
# import traceback
# import tensorflow_hub as hub
# import numpy as np

# #configure logging
# logging.basicConfig(level=logging.INFO)
# logger=logging.getLogger(__name__)

# app = Flask(__name__)
# CORS(app)
# # Configure a folder to temporarily store uploads
# UPLOAD_FOLDER = 'temp_uploads'
# if not os.path.exists(UPLOAD_FOLDER):
#     os.makedirs(UPLOAD_FOLDER)

# app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# # os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# # Global variables for model
# yamnet_model = None
# class_map_path=None
# class_names=None
# #load model initially
# def load_model():
#     """Load YAMNet model with error handling"""
#     global yamnet_model
#     global class_map_path
#     global class_names
#     try:
#         logger.info("Loading YAMNet model...")
#         yamnet_model = hub.load('https://tfhub.dev/google/yamnet/1')
#         class_map_path = yamnet_model.class_map_path().numpy()
#         class_names = class_names_from_csv(class_map_path)
#         logger.info("YAMNet model loaded successfully")
#         return True
#     except Exception as e:
#         logger.error(f"Failed to load YAMNet model: {str(e)}")
#         logger.error(traceback.format_exc())
#         return False
    
# @app.route('/')
# def home():
#     return "YAMNet Audio Classification API is running."
# # check status of server
# @app.route('/health', methods=['GET'])
# def health_check():
#     """Health check endpoint for Cloud Run"""
#     try:
#         if yamnet_model is None:
#             return jsonify({'status': 'unhealthy', 'message': 'Model not loaded'}), 503
#         return jsonify({'status': 'healthy', 'message': 'Service is running'}), 200
#     except Exception as e:
#         logger.error(f"Health check failed: {str(e)}")
#         return jsonify({'status': 'unhealthy', 'message': str(e)}), 503


# @app.route('/predict', methods=['POST'])
# def predict():
#     if 'audio' not in request.files:
#         return jsonify({'error': 'No audio file provided'}), 400
    
#     file = request.files['audio']
#     if file.filename == '':
#         return jsonify({'error': 'No selected file'}), 400

   
#     # Use temporary directory that gets automatically cleaned up
#     with tempfile.TemporaryDirectory(prefix='yamnet_') as temp_dir:
#         try:
#             # Generate unique filenames
#             unique_id = str(uuid.uuid4())
#             filename = secure_filename(file.filename)
#             base_name = os.path.splitext(filename)[0]
            
#             m4a_filepath = os.path.join(temp_dir, f"{base_name}_{unique_id}.m4a")
#             wav_filepath = os.path.join(temp_dir, f"{base_name}_{unique_id}.wav")

#             # Save the uploaded file
#             file.save(m4a_filepath)
#             logger.info(f"Saved temporary file to {m4a_filepath}")
            
#             # Convert using FFmpeg
#             command = [
#                 'ffmpeg',
#                 '-i', m4a_filepath,
#                 '-y',
#                 '-loglevel', 'error',
#                 wav_filepath
#             ]

#             subprocess.run(command, check=True, capture_output=True, text=True)
#             logger.info(f"Successfully converted to {wav_filepath}")
            
#             # Predict using the model
#             result = predict_sound(wav_filepath,class_names)
#             return jsonify({'prediction': result})
            
#         except subprocess.CalledProcessError as e:
#             logger.error(f"FFmpeg conversion failed: {e.stderr}")
#             return jsonify({'error': 'Audio conversion failed'}), 500
#         except Exception as e:
#             logger.error(f"Error processing audio: {str(e)}")
#             return jsonify({'error': 'Internal server error'}), 500
#         # Temporary directory and all files are automatically cleaned up here  
  
# # Cleanup function to remove old files on startup (optional)
# def cleanup_old_files():
#     """Remove any leftover files from previous runs"""
#     if os.path.exists(UPLOAD_FOLDER):
#         try:
#             for filename in os.listdir(UPLOAD_FOLDER):
#                 filepath = os.path.join(UPLOAD_FOLDER, filename)
#                 if os.path.isfile(filepath):
#                     os.remove(filepath)
#                     logger.info(f"Removed old file: {filepath}")
#         except Exception as e:
#             logger.error(f"Error cleaning up old files: {str(e)}")


# # Initialize model on startup - but don't block server start
# def initialize_model_async():
#     """Initialize the model asynchronously"""
#     import threading
#     def load_model_thread():
#         logger.info("Starting model loading in background...")
#         if load_model():
#             logger.info("Model loaded successfully in background")
#         else:
#             logger.error("Failed to load model in background")
    
#     thread = threading.Thread(target=load_model_thread)
#     thread.daemon = True
#     thread.start()

# # Start model loading immediately when module is imported
# initialize_model_async()

# if __name__ == '__main__':
#     # Clean up any leftover files from previous runs
#     cleanup_old_files()
#     app.run(
#        host='0.0.0.0',
#        port=8080,
#       )