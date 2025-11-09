# yamnet_utils.py
import tensorflow as tf
import tensorflow_hub as hub
import numpy as np
import scipy.signal
import csv
from scipy.io import wavfile
import librosa
# Load YAMNet model and class labels
model = hub.load("https://tfhub.dev/google/yamnet/1")

def class_names_from_csv(csv_path):
    class_names = []
    with tf.io.gfile.GFile(csv_path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            class_names.append(row['display_name'])
    return class_names

# class_map_path = model.class_map_path().numpy()
# class_names = class_names_from_csv(class_map_path)

def ensure_sample_rate(original_sr, waveform, target_sr=16000):
    if original_sr != target_sr:
        desired_length = int(round(len(waveform) * float(target_sr) / original_sr))
        waveform = scipy.signal.resample(waveform, desired_length)
    return target_sr, waveform

def predict_sound(filepath,class_names):
     # librosa.load does it all:
    # - Opens the audio file (many formats supported, not just wav)
    # - Converts to mono by default (mono=True)
    # - Resamples to your target sample rate (sr=16000)
    # - Returns a float32 numpy array, normalized between -1.0 and 1.0
    waveform, sample_rate = librosa.load(filepath, sr=16000, mono=True)

    # The waveform is now perfectly prepared for the YAMNet model
    scores, _, _ = model(waveform)
    scores_np = scores.numpy()
    mean_scores = scores_np.mean(axis=0)
    top_class_index = mean_scores.argmax()
    top_class = class_names[top_class_index]
    return top_class
