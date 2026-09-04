import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/method_channel_impl.dart';
export 'src/method_channel_impl.dart';

/// H5 刷脸完成后的结果
class FaceVerifyResult {
  final String? verifyId;
  final String? code;
  final String? message;

  const FaceVerifyResult({this.verifyId, this.code, this.message});

  factory FaceVerifyResult.fromMap(Map<Object?, Object?> map) =>
      FaceVerifyResult(
        verifyId: map['verifyId']?.toString() ?? map['VerifyId']?.toString(),
        code: map['code']?.toString() ?? map['Code']?.toString(),
        message: map['message']?.toString() ?? map['Message']?.toString(),
      );

  /// 解析 thirdUrl 回跳结果
  static ({String code, String verifyId})? fromUri(
    Uri uri, {
    String schemePattern = 'qiyun',
  }) {
    if (uri.scheme != schemePattern) {
      return null;
    }
    final code =
        uri.queryParameters['code'] ?? uri.queryParameters['Code'] ?? '';
    final verifyId =
        uri.queryParameters['verifyId'] ??
        uri.queryParameters['VerifyId'] ??
        '';
    if (verifyId.isEmpty) {
      return null;
    }
    return (code: code, verifyId: verifyId);
  }
}

/// 腾讯身份认证插件平台接口
abstract class IdentityVerificationPlatform extends PlatformInterface {
  IdentityVerificationPlatform() : super(token: _token);

  static final Object _token = Object();

  static IdentityVerificationPlatform _instance =
      MethodChannelIdentityVerification();

  static IdentityVerificationPlatform get instance => _instance;

  static set instance(IdentityVerificationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// 拉起 H5 刷脸 WebView
  Future<void> startFaceVerify({
    required String h5faceUrl,
    required String h5thirdUrl,
    void Function(FaceVerifyResult result)? onSuccess,
    void Function(String message)? onMessage,
  }) {
    throw UnimplementedError('startFaceVerify() has not been implemented.');
  }

  /// 主动关闭 WebView 容器
  Future<void> destroy() {
    throw UnimplementedError('destroy() has not been implemented.');
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
}
