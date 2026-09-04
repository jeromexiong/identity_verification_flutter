import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../identity_verification_flutter_platform_interface.dart';

const MethodChannel _methodChannel = MethodChannel(
  'com.transcend.qiyun/tencent_identity_verification',
);

const EventChannel _eventChannel = EventChannel(
  'com.transcend.qiyun/tencent_identity_verification/events',
);

/// [IdentityVerificationPlatform] 的 MethodChannel 默认实现
class MethodChannelIdentityVerification
    extends IdentityVerificationPlatform {
  @visibleForTesting
  final methodChannel = _methodChannel;

  StreamSubscription<Object?>? _eventSub;

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> startFaceVerify({
    required String h5faceUrl,
    required String h5thirdUrl,
    void Function(FaceVerifyResult result)? onSuccess,
    void Function(String message)? onMessage,
  }) async {
    await _eventSub?.cancel();
    _eventSub = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final map = Map<Object?, Object?>.from(event);
        final type = map['type']?.toString();
        if (type == 'success') {
          onSuccess?.call(FaceVerifyResult.fromMap(map));
        } else if (type == 'message') {
          onMessage?.call(map['payload']?.toString() ?? '');
        }
      }
    });

    await methodChannel.invokeMethod<void>('startH5FaceVerify', {
      'h5faceUrl': h5faceUrl,
      'h5thirdUrl': h5thirdUrl,
    });
  }

  @override
  Future<void> destroy() async {
    await methodChannel.invokeMethod<void>('destroyH5FaceVerify');
    await _eventSub?.cancel();
    _eventSub = null;
  }
}
