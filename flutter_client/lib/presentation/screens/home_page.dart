import 'package:flutter/material.dart';
import 'package:flutter_client/data/data_provider/audio_data_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AudioDataProvider _audioDataProvider;
  bool _isRecording = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _audioDataProvider = AudioDataProvider(
      isRecordingEnable: true,
      context: context,
      grpcHost: "10.254.132.148",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SingleChildScrollView(
            clipBehavior: Clip.none,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _isRecording
                        ? "Listening..."
                        : "Audio Classifire with gRPC",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 1,
                      backgroundColor: _isRecording ? Colors.red : Colors.green,
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                    ),
                    onPressed: () async {
                      if (_isRecording) {
                        await _audioDataProvider.stopRecordings();
                        setState(() {
                          _isRecording = false;
                        });
                        return;
                      }
                      await _audioDataProvider.startRecordings();
                      setState(() {
                        _isRecording = true;
                      });
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
        ),
      ),
    );
  }
}
