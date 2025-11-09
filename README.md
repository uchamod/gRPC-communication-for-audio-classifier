# 🎙️ Flutter + Flask gRPC Audio Classification App

A **Flutter client** that communicates with a **Flask-based AI server** over **gRPC** to classify environmental sounds (like barking, sirens, etc.) using the **YAMNet** model from TensorFlow Hub.

---

## 🧠 Overview

This project demonstrates how to integrate **Flutter** (Dart) with a **Python Flask + TensorFlow** backend using **gRPC** instead of traditional REST APIs — enabling faster, more efficient binary data transmission for tasks like audio classification.

---

## ⚙️ Architecture

```
🎙️ Flutter App (Client)
   ↓ gRPC (Protocol Buffers)
🧠 Flask + YAMNet (Python Server)
   ↓
TensorFlow Hub Model (YAMNet)
```

* The Flutter app records or selects an audio file.
* The audio bytes are sent to the Flask AI server via **gRPC**.
* The Flask server runs **YAMNet** to classify the sound.
* The predicted label and confidence score are returned to the Flutter app.

---

## 🚀 Features

✅ Real-time audio classification (YAMNet model)
✅ gRPC-based communication (efficient + type-safe)
✅ File selection and playback in Flutter
✅ Modular, production-ready structure
✅ Easily extendable for other AI models (image, text, etc.)

---

## 🧩 Tech Stack

### Frontend (Flutter)

* Flutter SDK ≥ 3.0
* Dart ≥ 3.0
* Packages:

  * `grpc` — gRPC client communication
  * `file_picker` — select local audio files
  * `just_audio` — audio playback (optional)
  * `riverpod` — state management (optional)

### Backend (Python)

* Flask (for optional REST interface)
* `grpcio` and `grpcio-tools` — gRPC server implementation
* `tensorflow` and `tensorflow_hub` — AI inference (YAMNet model)
* `numpy` — data processing

---

## 📁 Project Structure

### Flutter (client)

```
lib/
├── generated/
│   ├── audio_service.pb.dart
│   ├── audio_service.pbgrpc.dart
│   └── ...
│
├── data/
│   ├── grpc/
│   │   └── audio_grpc_client.dart       # Handles gRPC calls
│   └── models/
│       └── audio_result.dart            # Result model
│
├── screens/
│   ├── home_screen.dart                 # UI for file selection & result
│
├── providers/
│   └── audio_provider.dart              # (Optional) Riverpod logic
│
└── main.dart                            # App entry point
```

### Flask (server)

```
server/
├── audio_service.proto                  # gRPC definition
├── audio_service_pb2.py
├── audio_service_pb2_grpc.py
├── grpc_server.py                       # Flask + gRPC setup
└── yamnet_model.py                      # YAMNet inference logic
```

---

## 📜 Proto Definition (`audio_service.proto`)

```proto
syntax = "proto3";

service AudioClassifier {
  rpc Predict (AudioRequest) returns (AudioResponse);
}

message AudioRequest {
  bytes audio_data = 1;
}

message AudioResponse {
  string label = 1;
  float confidence = 2;
}
```

---

## 🔧 Setup & Installation

### 1️⃣ Clone the repo

```bash
git clone https://github.com/yourusername/flutter-flask-grpc-audio.git
cd flutter-flask-grpc-audio
```

---

### 2️⃣ Backend Setup (Flask + gRPC)

#### Install dependencies

```bash
cd server
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### Generate Python gRPC files

```bash
python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. audio_service.proto
```

#### Run the gRPC server

```bash
python grpc_server.py
```

Server starts on port `50051`.

---

### 3️⃣ Flutter Client Setup

#### Install dependencies

```bash
cd flutter_client
flutter pub get
```

#### Generate Dart gRPC files

```bash
protoc --dart_out=grpc:lib/generated audio_service.proto
```

#### Run app

```bash
flutter run
```

---

## 🧠 How It Works

| Step | Description                                                     |
| ---- | --------------------------------------------------------------- |
| 1️⃣  | User selects or records an audio file in the Flutter app        |
| 2️⃣  | Flutter reads the file bytes and sends via gRPC to Flask server |
| 3️⃣  | Flask server processes it using YAMNet model                    |
| 4️⃣  | Model outputs a label and confidence                            |
| 5️⃣  | Flask sends the result back to Flutter                          |
| 6️⃣  | Flutter displays the prediction on screen                       |

---

---

## 🔒 Security Notes

* For development, the gRPC connection uses **insecure credentials**.
* In production, use **TLS encryption** with `ChannelCredentials.secure()` in Flutter and `ServerCredentials.createSsl()` in Flask.

---

## 🧩 Future Improvements

* 🔁 Implement **streaming gRPC** for continuous audio inference
* ⚡ Add **auth tokens** for secure access
* ☁️ Deploy the Flask gRPC server on **Google Cloud Run / AWS EC2**
* 📊 Add history and charts of detected sounds
* 🎯 Use **Firebase** for push notifications on danger sounds

---

## 🧑‍💻 Author

**Chamod Udara**
📱 Flutter Developer | 🔗 Backend Integrator
💡 Passionate about AI + Mobile synergy

---


