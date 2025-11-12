import os
# Set log level before importing TensorFlow
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2' 

import grpc
from concurrent import futures
import protos.audio_service_pb2 as audio_service_pb2
import protos.audio_service_pb2_grpc as audio_service_pb2_grpc
import tensorflow_hub as hub
import tensorflow as tf
import numpy as np
import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- 1. YAMNet Model & Class Loading (Good, keep this) ---
logger.info("Loading YAMNet model for gRPC service...")
try:
    yamnet_model = hub.load('https://tfhub.dev/google/yamnet/1')
    class_map_path = yamnet_model.class_map_path().numpy()
    
    # Simple function to load class names (replaces yamnet_utils)
    def class_names_from_csv(class_map_csv_text):
        """Returns list of class names corresponding to score vector."""
        with tf.io.gfile.GFile(class_map_csv_text) as f:
            # Skip the header
            f.readline()
            class_names_list = []
            for row in f:
                # 'index,mid,display_name'
                _, _, display_name = row.strip().split(',', 2)
                class_names_list.append(display_name.strip('"'))
        return class_names_list
        
    class_names = class_names_from_csv(class_map_path)
    logger.info("✅ Model loaded successfully")
except Exception as e:
    logger.error(f"❌ Failed to load model: {e}")
    exit(1)


class AudioClassifierService(audio_service_pb2_grpc.AudioClassifierServicer):

    # --- 2. The New Real-Time Stream Method ---
    # Note: Make sure your .proto file defines this as:
    # rpc StreamPredict(stream AudioChunk) returns (stream PredictResponse);
    def StreamPredict(self, request_iterator, context):
        """
        Receives a stream of raw audio chunks and streams back predictions
        in real-time.
        """
        logger.info("⚡ Client connected! Starting real-time stream...")

        # YAMNet requires 16000 Hz.
        # 16000 samples * 2 bytes/sample (for 16-bit) = 32000 bytes per second.
        # We will process audio in 1-second chunks.
        BUFFER_SIZE_BYTES = 32000
        
        # This is our in-memory buffer
        audio_buffer = bytearray()

        try:
            for chunk in request_iterator:
                # Add new data to our memory buffer
                audio_buffer.extend(chunk.data)

                # Process in 1-second chunks until the buffer is too small
                while len(audio_buffer) >= BUFFER_SIZE_BYTES:
                    
                    # --- 3. This is the FFmpeg Replacement ---
                    # Get the 1-second chunk from the buffer
                    chunk_to_process = audio_buffer[:BUFFER_SIZE_BYTES]
                    
                    # Remove this chunk from the buffer (slide the window)
                    audio_buffer = audio_buffer[BUFFER_SIZE_BYTES:]

                    # Convert raw bytes (16-bit) to NumPy array
                    waveform = np.frombuffer(chunk_to_process, dtype=np.int16)

                    # --- 4. This is the YAMNet Pre-processing ---
                    # Convert int16 (-32k to +32k) to float32 (-1.0 to 1.0)
                    waveform = waveform.astype(np.float32) / 32768.0

                    # --- 5. Run Prediction ---
                    # (This replaces your 'predict_sound' utility)
                    scores, embeddings, spectrogram = yamnet_model(waveform)

                    # Aggregate scores and find the top prediction
                    prediction = np.mean(scores, axis=0)
                    top_class_index = np.argmax(prediction)
                    label = class_names[top_class_index]
                    confidence = prediction[top_class_index]

                    if confidence > 0.1: # Only send confident predictions
                        logger.info(f"🎤 Detected: {label} ({confidence:.2f})")
                        
                        # --- 6. Send Response Immediately ---
                        # We are still *inside* the loop, sending a response
                        # for every second of audio.
                        yield audio_service_pb2.PredictResponse(
                            label=label,
                            confidence=float(confidence),
                            timestamp_ms=int(time.time() * 1000)
                        )

        except grpc.RpcError as e:
            if e.code() == grpc.StatusCode.CANCELLED:
                logger.warning("Client cancelled the stream.")
            else:
                logger.error(f"gRPC Error: {e}")
        except Exception as e:
            logger.error(f"Processing Error: {e}")
        finally:
            logger.info("Client disconnected.")


def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=5))
    audio_service_pb2_grpc.add_AudioClassifierServicer_to_server(AudioClassifierService(), server)
    server.add_insecure_port('[::]:50051')
    logger.info("🎧 gRPC server started on port 50051")
    server.start()
    server.wait_for_termination()

if __name__ == "__main__":
    serve()