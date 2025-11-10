import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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
  static const int _sampleRate = 44100;
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
  };
  final String backendUrl = 'http://192.168.75.148:5000/predict';

  AudioDataProvider({required this.isRecordingEnable, required this.context}) {
    // Calculate buffer size for 5-second chunks

    _bufferSizeTarget = _sampleRate * _chunkDurationSeconds ~/ 4;
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
      // 2. Clear previous state and start the stream
      await _audioStreamSubscription?.cancel();
      _audioBuffer = [];
      _lastChunkTime = DateTime.now();
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.aacLc, //  Using AAC for m4a format
          sampleRate: _sampleRate,
          numChannels: 1, // Mono
          bitRate: 128000, // 128 kbps for good quality
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
      // Combine all buffered chunks into one piece for analysis
      final combinedData = _combineAudioChunks();
      _audioBuffer.clear(); // Clear buffer after taking the data
      _lastChunkTime = DateTime.now();

      // Send for analysis without waiting (fire and forget)
      _analyzeAudioData(combinedData);
    }
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

  //analysis audio data
  Future<void> _analyzeAudioData(Uint8List audioData) async {
    try {
      // Create temporary file for analysis
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/temp_chunk_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      await tempFile.writeAsBytes(audioData);
      // // Write PCM data as WAV file
      // await _writePCMAsWAV(audioData, tempFile);

      // Analyze the audio file
      await _analyzeAudioFile(tempFile.path);

      // Clean up
      await tempFile.delete();
    } catch (e) {
      print('Error analyzing audio data: $e');
    }
  }

  //ssend multipart  request to backend
  Future<void> _analyzeAudioFile(String audioPath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://34.87.171.135/predict'),
      );
      var audioFile = await http.MultipartFile.fromPath('audio', audioPath);
      request.files.add(audioFile);

      var response = await request.send().timeout(Duration(minutes: 5));

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        Map<String, dynamic> result = json.decode(responseBody);
        await _processAnalysisResult(result);
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception('Network error: Check if Flask server is running on $e');
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: Server took too long to responde $e');
    } catch (e) {
      print('Error analyzing audio file: $e');
    }
  }

  //check response data
  Future<void> _processAnalysisResult(Map<String, dynamic> result) async {
    try {
      String prediction = result['prediction'] ?? '';
      // double confidence = result['top_confidence']?.toDouble() ?? 0.0;
      if (_warnableSounds.contains(prediction)) {
        print('Detected from audio: $prediction');
      }

      print('nothing detect from audio');
    } catch (e) {
      print('Error processing analysis result: $e');
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
