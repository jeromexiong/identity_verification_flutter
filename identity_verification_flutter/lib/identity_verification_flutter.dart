/// 腾讯身份认证 H5 刷脸桥接 Flutter 插件
///
/// 导出 [IdentityVerification]（新名）和 [TencentIdentityVerification]（deprecated 别名）、
/// [FaceVerifyResult]（新名）和 [FaceVerifyH5Result]（deprecated 别名）。
library;

import 'package:identity_verification_flutter_platform_interface/identity_verification_flutter_platform_interface.dart';

export 'package:identity_verification_flutter_platform_interface/identity_verification_flutter_platform_interface.dart'
    show FaceVerifyResult, IdentityVerificationPlatform;

/// 腾讯身份认证插件（H5 刷脸桥接）
///
/// ```dart
/// final plugin = IdentityVerification();
/// await plugin.startFaceVerify(
///   h5faceUrl: 'https://...',
///   h5thirdUrl: 'qiyun://signcert/callback',
///   onSuccess: (result) { ... },
///   onMessage: (message) { ... },
/// );
/// ```
class IdentityVerification {
  IdentityVerification._();

  static final IdentityVerification _instance = IdentityVerification._();

  /// 单例
  factory IdentityVerification() => _instance;

  /// 拉起 H5 刷脸 WebView
  Future<void> startFaceVerify({
    required String h5faceUrl,
    required String h5thirdUrl,
    void Function(FaceVerifyResult result)? onSuccess,
    void Function(String message)? onMessage,
  }) {
    return IdentityVerificationPlatform.instance.startFaceVerify(
      h5faceUrl: h5faceUrl,
      h5thirdUrl: h5thirdUrl,
      onSuccess: onSuccess,
      onMessage: onMessage,
    );
  }

  /// 主动关闭 WebView 容器
  Future<void> destroy() {
    return IdentityVerificationPlatform.instance.destroy();
  }

  // ── Deprecated 别名 ──

  @Deprecated('Use startFaceVerify instead')
  Future<void> startH5FaceVerify({
    required String h5faceUrl,
    required String h5thirdUrl,
    void Function(FaceVerifyResult result)? onSuccess,
    void Function(String message)? onMessage,
  }) => startFaceVerify(
    h5faceUrl: h5faceUrl,
    h5thirdUrl: h5thirdUrl,
    onSuccess: onSuccess,
    onMessage: onMessage,
  );

  @Deprecated('Use destroy instead')
  Future<void> destroyH5FaceVerify() => destroy();

  @Deprecated('Use FaceVerifyResult.fromUri instead')
  static ({String code, String verifyId})? parseCallbackResult(
    Uri uri, {
    String schemePattern = 'qiyun',
  }) => FaceVerifyResult.fromUri(uri, schemePattern: schemePattern);
}

/// @Deprecated — use [IdentityVerification] instead
@Deprecated('Use IdentityVerification instead')
typedef TencentIdentityVerification = IdentityVerification;

/// @Deprecated — use [FaceVerifyResult] instead
@Deprecated('Use FaceVerifyResult instead')
typedef FaceVerifyH5Result = FaceVerifyResult;
