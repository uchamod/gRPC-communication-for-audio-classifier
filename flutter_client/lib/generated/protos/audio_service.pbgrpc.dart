// This is a generated file - do not edit.
//
// Generated from protos/audio_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'audio_service.pb.dart' as $0;

export 'audio_service.pb.dart';

@$pb.GrpcServiceName('ai.AudioClassifier')
class AudioClassifierClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  AudioClassifierClient(super.channel, {super.options, super.interceptors});

  /// Bidirectional streaming: client sends AudioChunk stream, server replies with PredictResponse stream
  $grpc.ResponseStream<$0.PredictResponse> streamPredict(
    $async.Stream<$0.AudioChunk> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$streamPredict, request, options: options);
  }

  // method descriptors

  static final _$streamPredict =
      $grpc.ClientMethod<$0.AudioChunk, $0.PredictResponse>(
          '/ai.AudioClassifier/StreamPredict',
          ($0.AudioChunk value) => value.writeToBuffer(),
          $0.PredictResponse.fromBuffer);
}

@$pb.GrpcServiceName('ai.AudioClassifier')
abstract class AudioClassifierServiceBase extends $grpc.Service {
  $core.String get $name => 'ai.AudioClassifier';

  AudioClassifierServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.AudioChunk, $0.PredictResponse>(
        'StreamPredict',
        streamPredict,
        true,
        true,
        ($core.List<$core.int> value) => $0.AudioChunk.fromBuffer(value),
        ($0.PredictResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.PredictResponse> streamPredict(
      $grpc.ServiceCall call, $async.Stream<$0.AudioChunk> request);
}
