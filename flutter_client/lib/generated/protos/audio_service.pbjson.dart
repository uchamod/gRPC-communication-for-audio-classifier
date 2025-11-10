// This is a generated file - do not edit.
//
// Generated from protos/audio_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use audioChunkDescriptor instead')
const AudioChunk$json = {
  '1': 'AudioChunk',
  '2': [
    {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
    {'1': 'sample_rate', '3': 2, '4': 1, '5': 5, '10': 'sampleRate'},
    {'1': 'channels', '3': 3, '4': 1, '5': 5, '10': 'channels'},
    {'1': 'is_last', '3': 4, '4': 1, '5': 8, '10': 'isLast'},
    {'1': 'session_id', '3': 5, '4': 1, '5': 3, '10': 'sessionId'},
  ],
};

/// Descriptor for `AudioChunk`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioChunkDescriptor = $convert.base64Decode(
    'CgpBdWRpb0NodW5rEhIKBGRhdGEYASABKAxSBGRhdGESHwoLc2FtcGxlX3JhdGUYAiABKAVSCn'
    'NhbXBsZVJhdGUSGgoIY2hhbm5lbHMYAyABKAVSCGNoYW5uZWxzEhcKB2lzX2xhc3QYBCABKAhS'
    'BmlzTGFzdBIdCgpzZXNzaW9uX2lkGAUgASgDUglzZXNzaW9uSWQ=');

@$core.Deprecated('Use predictResponseDescriptor instead')
const PredictResponse$json = {
  '1': 'PredictResponse',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'confidence', '3': 2, '4': 1, '5': 2, '10': 'confidence'},
    {'1': 'timestamp_ms', '3': 3, '4': 1, '5': 3, '10': 'timestampMs'},
    {'1': 'session_id', '3': 4, '4': 1, '5': 3, '10': 'sessionId'},
  ],
};

/// Descriptor for `PredictResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List predictResponseDescriptor = $convert.base64Decode(
    'Cg9QcmVkaWN0UmVzcG9uc2USFAoFbGFiZWwYASABKAlSBWxhYmVsEh4KCmNvbmZpZGVuY2UYAi'
    'ABKAJSCmNvbmZpZGVuY2USIQoMdGltZXN0YW1wX21zGAMgASgDUgt0aW1lc3RhbXBNcxIdCgpz'
    'ZXNzaW9uX2lkGAQgASgDUglzZXNzaW9uSWQ=');
