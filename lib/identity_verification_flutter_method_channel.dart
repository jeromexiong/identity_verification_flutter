import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'identity_verification_flutter_platform_interface.dart';

/// Method 通道名（与 Android/iOS 原生对齐）
const MethodChannel _methodChannel = MethodChannel(
  'com.transcend.qiyun/tencent_identity_verification',
);

/// 事件通道名（H5 刷脸 native → Dart 回调）
const EventChannel _eventChannel = EventChannel(
  'com.transcend.qiyun/tencent_identity_verification/events',
);

/// An implementation of [TencentIdentityVerificationPlatform] that uses method channels.
class MethodChannelTencentIdentityVerification
    extends TencentIdentityVerificationPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = _methodChannel;

  /// 事件通道订阅（startH5FaceVerify 时建立，destroyH5FaceVerify 时取消）
  StreamSubscription<Object?>? _eventSub;

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> startH5FaceVerify({
    required String h5faceUrl,
    required String h5thirdUrl,
    void Function(FaceVerifyH5Result result)? onSuccess,
    void Function(String message)? onMessage,
  }) async {
    // 先建立事件流（若同一次刷脸中途重连则先取消旧订阅）
    await _eventSub?.cancel();
    _eventSub = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final map = Map<Object?, Object?>.from(event);
        final type = map['type']?.toString();
        if (type == 'success') {
          onSuccess?.call(FaceVerifyH5Result.fromMap(map));
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
  Future<void> destroyH5FaceVerify() async {
    await methodChannel.invokeMethod<void>('destroyH5FaceVerify');
    await _eventSub?.cancel();
    _eventSub = null;
  }
}
