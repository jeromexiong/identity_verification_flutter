import 'dart:async';

import 'identity_verification_flutter_platform_interface.dart';

export 'identity_verification_flutter_platform_interface.dart'
    show FaceVerifyH5Result;

/// 腾讯身份认证插件（H5 刷脸桥接，对齐 uniapp DC-WBH5FaceVerifyService 语义）
///
/// 接入方式（宿主 pubspec）：
/// ```yaml
/// dependencies:
///   identity_verification_flutter:
///     path: plugins/identity_verification_flutter
/// ```
class TencentIdentityVerification {
  TencentIdentityVerification._();

  static final TencentIdentityVerification _instance =
      TencentIdentityVerification._();

  /// 单例
  factory TencentIdentityVerification() => _instance;

  /// 拉起 H5 刷脸 WebView（对齐 uniapp startH5FaceVerify）
  ///
  /// [h5faceUrl] 腾讯慧眼 H5 刷脸页地址（放心签 faceIntegrate，可含 verifyId/rd）
  /// [h5thirdUrl] 刷脸完成后要跳转的接入方地址（thirdUrl 回跳）
  /// [onSuccess] 刷脸完成跳转 thirdUrl 后的回调（带 verifyId/code）
  /// [onMessage] H5 页面 window.tencentApi.postMessage 消息桥回调
  Future<void> startH5FaceVerify({
    required String h5faceUrl,
    required String h5thirdUrl,
    void Function(FaceVerifyH5Result result)? onSuccess,
    void Function(String message)? onMessage,
  }) {
    return TencentIdentityVerificationPlatform.instance.startH5FaceVerify(
      h5faceUrl: h5faceUrl,
      h5thirdUrl: h5thirdUrl,
      onSuccess: onSuccess,
      onMessage: onMessage,
    );
  }

  /// 主动关闭插件 WebView（对齐 uniapp destroyH5FaceVerify）
  Future<void> destroyH5FaceVerify() {
    return TencentIdentityVerificationPlatform.instance.destroyH5FaceVerify();
  }

  /// 解析 thirdUrl 回跳结果：`qiyun://signcert/callback?code=xxx&verifyId=yyy`
  ///
  /// 返回 null 表示非回跳 URL（不处理）。键兼容 `code/verifyId` 与 `Code/VerifyId`。
  static ({String code, String verifyId})? parseCallbackResult(
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
