import 'package:flutter/material.dart';
import 'package:flutter_client/data/data_provider/audio_data_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    bool _isEnable = false;
    final AudioDataProvider _audioDataProvider = AudioDataProvider(
      context: context,
      isRecordingEnable: _isEnable,
    );
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Audio Classifire with gRPC",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 1,
                  backgroundColor: Colors.lightGreenAccent,
                  padding: EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () async {
                 await _audioDataProvider.startRecordings();
                },
                child: Text(
                  "Start Listening",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
