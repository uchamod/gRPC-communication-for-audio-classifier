import 'dart:async';
import 'dart:typed_data';

import 'package:fixnum/src/int64.dart';
import 'package:flutter_client/generated/protos/audio_service.pbgrpc.dart';
import 'package:grpc/grpc.dart';

class AudioGrpcClient {
  final String host;
  final int port;
  late ClientChannel _channel;
  late AudioClassifierClient _stub;

  // Stream controller for outgoing AudioChunk messages
  StreamController<AudioChunk>? _outController;

  // Server -> client response stream
  Stream<PredictResponse>? _responseStream;
  StreamSubscription<PredictResponse>? _responseSub;

  AudioGrpcClient({required this.host, this.port = 50051});

  void init() {
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        idleTimeout: Duration(minutes: 1),
      ),
    );
    _stub = AudioClassifierClient(_channel);
  }

  /// Start a new streaming session and return the response stream.
  /// Optionally pass a callback for each server response.
  Future<void> startSession({
    required void Function(PredictResponse) onResponse,
    required void Function(Object) onError,
    required void Function() onDone,
  }) async {
    _outController = StreamController<AudioChunk>();
    // Call the bidi-streaming RPC using the outgoing stream
    final responseStream = _stub.streamPredict(_outController!.stream);
    _responseStream = responseStream;
    _responseSub = _responseStream!.listen(
      (resp) => onResponse(resp),
      onError: (err) => onError(err),
      onDone: () => onDone(),
      cancelOnError: false,
    );
  }

  /// Send chunk to server (non-blocking)
  void sendChunk(
    Uint8List bytes, {
    int sampleRate = 44100,
    int channels = 1,
    bool isLast = false,
    int? sessionId,
  }) {
    if (_outController == null || _outController!.isClosed) return;
    final chunk =
        AudioChunk()
          ..data = bytes
          ..sampleRate = sampleRate
          ..channels = channels
          ..isLast = isLast;
    if (sessionId != null) chunk.sessionId = Int64(sessionId);
    _outController!.add(chunk);
  }

  /// Close outgoing stream (tell server we're done)
  Future<void> endSession() async {
    await _outController?.close();
    await _responseSub?.cancel();
    _outController = null;
    _responseStream = null;
    _responseSub = null;
  }

  Future<void> shutdown() async {
    try {
      await _channel.shutdown();
    } catch (_) {
      print("shut down failed");
    }
  }
}
