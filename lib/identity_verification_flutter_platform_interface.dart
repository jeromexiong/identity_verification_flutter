import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'identity_verification_flutter_method_channel.dart';

/// H5 刷脸完成后的结果（对齐 uniapp DC-WBH5FaceVerifyService success 回调）
class FaceVerifyH5Result {
  /// 刷脸会话标识（后端 verifyId）
  final String? verifyId;

  /// 回调 code（H5 完成跳 thirdUrl 时附带）
  final String? code;

  /// 结果描述 / 附加信息
  final String? message;

  const FaceVerifyH5Result({this.verifyId, this.code, this.message});

  factory FaceVerifyH5Result.fromMap(Map<Object?, Object?> map) =>
      FaceVerifyH5Result(
        verifyId: map['verifyId']?.toString() ?? map['VerifyId']?.toString(),
        code: map['code']?.toString() ?? map['Code']?.toString(),
        message: map['message']?.toString() ?? map['Message']?.toString(),
      );
}

abstract class TencentIdentityVerificationPlatform extends PlatformInterface {
  /// Constructs a TencentIdentityVerificationPlatform.
  TencentIdentityVerificationPlatform() : super(token: _token);

  static final Object _token = Object();

  static TencentIdentityVerificationPlatform _instance =
      MethodChannelTencentIdentityVerification();

  /// The default instance of [TencentIdentityVerificationPlatform] to use.
  ///
  /// Defaults to [MethodChannelTencentIdentityVerification].
  static TencentIdentityVerificationPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TencentIdentityVerificationPlatform] when
  /// they register themselves.
  static set instance(TencentIdentityVerificationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// 拉起 H5 刷脸 WebView（对齐 uniapp DC-WBH5FaceVerifyService.startH5FaceVerify）
  ///
  /// [h5faceUrl] 腾讯慧眼 H5 刷脸页地址（放心签 faceIntegrate）
  /// [h5thirdUrl] 刷脸完成后要跳转的接入方地址（thirdUrl 回跳）
  /// [onSuccess] 刷脸完成跳转 thirdUrl 后的回调
  /// [onMessage] H5 页面 window.tencentApi.postMessage 消息桥回调
  Future<void> startH5FaceVerify({
    required String h5faceUrl,
    required String h5thirdUrl,
    void Function(FaceVerifyH5Result result)? onSuccess,
    void Function(String message)? onMessage,
  }) {
    throw UnimplementedError('startH5FaceVerify() has not been implemented.');
  }

  /// 主动关闭插件 WebView（对齐 uniapp destroyH5FaceVerify）
  Future<void> destroyH5FaceVerify() {
    throw UnimplementedError('destroyH5FaceVerify() has not been implemented.');
  }
}
