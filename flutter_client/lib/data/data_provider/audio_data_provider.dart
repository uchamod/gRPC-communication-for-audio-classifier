import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_client/data/grpc/audio_grpc_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioDataProvider {
  final AudioRecorder _recorder = AudioRecorder();
  final BuildContext context;
  final bool isRecordingEnable;
  bool _isRecording = true;

  DateTime? _lastChunkTime; // Track time between chunks
  // Stream-based chunk processing
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  List<Uint8List> _audioBuffer = [];
  int _bufferSizeTarget = 0; // Will be calculated based on sample rate

  // Configuration
  static const int _sampleRate = 16000;
  static const int _chunkDurationSeconds = 5;
  static const int _analysisIntervalSeconds = 8;
  final Set<String> _warnableSounds = {
    'Bark',
    'Crying, Sobbing',
    'Groan',
    'Screaming',
    'Shout',
    'Yell',
    'Emergency vehicle',
    'Fire engine, fire truck (siren)',
    'Fire alarm',
    'whimper',
    'Gunshot, gunfire',
    'Explosion',
    'Crash',
    'Children shouting',
    'Wail, moan',
    'Biting',
    'Wild animals',
    'Fire',
    'Siren',
    'Police car (siren)',
    'Speech',
  };
  final String backendUrl = 'http://192.168.75.148:5000/predict';
  final AudioGrpcClient _grpcClient;
  int _sessionId = DateTime.now().millisecondsSinceEpoch; // unique session id

  AudioDataProvider({
    required this.isRecordingEnable,
    required this.context,
    required String grpcHost,
  }) : _grpcClient = AudioGrpcClient(host: grpcHost) {
    // Calculate buffer size for 5-second chunks
    _bufferSizeTarget = _sampleRate * _chunkDurationSeconds ~/ 4;
    _grpcClient.init();
  }

  // call to start full streaming session with server
  Future<void> _startGrpcSession() async {
    await _grpcClient.startSession(
      onResponse: (resp) {
        // This callback runs on each server response
        try {
          final String label = resp.label;
          final double confidence = resp.confidence;
          // do whatever you did before: check warnable sounds
          if (_warnableSounds.contains(label)) {
            print(
              '⚠️ Detected from server: $label (${(confidence * 100).toStringAsFixed(1)}%)',
            );
            // show notification or UI update as required
          } else {
            print(
              'Detected (not warnable): $label ${(confidence * 100).toStringAsFixed(1)}%',
            );
          }
        } catch (e) {
          print('Error processing server response: $e');
        }
      },
      onError: (err) {
        print('gRPC stream error: $err');
      },
      onDone: () {
        print('gRPC stream done by server.');
      },
    );
  }

  //start recording
  Future<void> startRecordings() async {
    if (!isRecordingEnable) return;

    final status = await Permission.microphone.request();
    if (status.isDenied) {
      _showPermissionError();
      return;
    }

    try {
      // Start gRPC session before streaming audio
      await _startGrpcSession();
      // 2. Clear previous state and start the stream
      await _audioStreamSubscription?.cancel();
      _audioBuffer = [];
      _lastChunkTime = DateTime.now();
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits, //  Using AAC for m4a format
          sampleRate: 16000,
          numChannels: 1, // Mono
          // bitRate: 128000, // 128 kbps for good quality
        ),
      );
      print("Audio stream started successfully ✅");
      // 3. Listen to the stream for both analysis and file saving
      _audioStreamSubscription = stream.listen((data) {
        // Add timestamp to first chunk
        if (_audioBuffer.isEmpty) {
          _lastChunkTime = DateTime.now();
        }

        // A. Add data to the buffer for real-time analysis
        _audioBuffer.add(data);

        // Check if the buffer is full enough for analysis
        _processAudioBuffer();
      });

      _isRecording = true;
    } catch (err) {
      print('Error starting recording ❌: $err');
    }
  }

  void _processAudioBuffer() {
    // Check both size and time conditions for sending chunks
    int currentBufferSize = _audioBuffer.fold(
      0,
      (sum, chunk) => sum + chunk.length,
    );
    final timeSinceLastChunk =
        DateTime.now().difference(_lastChunkTime!).inSeconds;

    if (currentBufferSize >= _bufferSizeTarget ||
        timeSinceLastChunk >= _analysisIntervalSeconds) {
      final combinedData = _combineAudioChunks();
      _audioBuffer.clear();
      _lastChunkTime = DateTime.now();

      // If gRPC session is not started, start it
      if (_outgoingSessionNotStarted()) {
        _startGrpcSession();
      }

      // Send chunk directly to gRPC
      _sendChunkToGrpc(combinedData);
    }
  }

  // Send bytes to gRPC
  void _sendChunkToGrpc(Uint8List audioBytes) {
    try {
      _grpcClient.sendChunk(
        audioBytes,
        sampleRate: _sampleRate,
        channels: 1,
        isLast: false,
        sessionId: _sessionId,
      );
    } catch (e) {
      print('Error sending chunk to gRPC: $e');
    }
  }

  bool _outgoingSessionNotStarted() {
    // simple check based on grpc client's internal controller presence
    // add a getter in AudioGrpcClient if you want; for now, check if _outController != null
    // But since _outController is private, we can add a small public flag or rely on try/catch:
    // For brevity assume we have started it earlier with _startGrpcSession() when starting recording.
    return true; // replace with real condition or call _startGrpcSession() at startRecordings()
  }

  //for procssing
  Uint8List _combineAudioChunks() {
    // This is a more efficient way to combine lists of bytes
    final builder = BytesBuilder();
    for (final chunk in _audioBuffer) {
      builder.add(chunk);
    }
    return builder.toBytes();
  }

  // When user stops recording, tell server it's the last chunk and close
  Future<void> stopRecordings() async {
    try {
      _isRecording = false;
      await _audioStreamSubscription?.cancel();

      // send an empty final chunk marked is_last = true to indicate session end
      _grpcClient.sendChunk(
        Uint8List(0),
        sampleRate: _sampleRate,
        channels: 1,
        isLast: true,
        sessionId: _sessionId,
      );
      await _grpcClient.endSession();
      await _grpcClient.shutdown();
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  void _showPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        elevation: 1,
        backgroundColor: Colors.deepPurple,
        content: Text('Microphone permission required for recording'),
      ),
    );
  }
}
