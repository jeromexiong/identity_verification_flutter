import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:identity_verification_flutter/identity_verification_flutter.dart';
import 'package:identity_verification_flutter/identity_verification_flutter_method_channel.dart';
import 'package:identity_verification_flutter/identity_verification_flutter_platform_interface.dart';

class FakeTencentIdentityVerificationPlatform
    with MockPlatformInterfaceMixin
    implements TencentIdentityVerificationPlatform {
  final calls = <String>[];
  FaceVerifyH5Result? successResult;
  String? message;

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> startH5FaceVerify({
    required String h5faceUrl,
    required String h5thirdUrl,
    void Function(FaceVerifyH5Result result)? onSuccess,
    void Function(String message)? onMessage,
  }) async {
    calls.add('start:$h5faceUrl|$h5thirdUrl');
    onSuccess?.call(
      successResult ?? const FaceVerifyH5Result(verifyId: 'V1', code: '0'),
    );
    onMessage?.call(message ?? 'hello');
  }

  @override
  Future<void> destroyH5FaceVerify() async {
    calls.add('destroy');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('$MethodChannelTencentIdentityVerification is the default instance', () {
    expect(
      TencentIdentityVerificationPlatform.instance,
      isInstanceOf<MethodChannelTencentIdentityVerification>(),
    );
  });

  test('startH5FaceVerify forwards args + dispatches callbacks', () async {
    final fake = FakeTencentIdentityVerificationPlatform();
    final prev = TencentIdentityVerificationPlatform.instance;
    TencentIdentityVerificationPlatform.instance = fake;

    final successResults = <FaceVerifyH5Result>[];
    final messages = <String>[];
    try {
      await TencentIdentityVerification().startH5FaceVerify(
        h5faceUrl: 'https://mobile.fangxinqian.cn/faceIntegrate?faceType=1',
        h5thirdUrl: 'qiyun://signcert/callback',
        onSuccess: successResults.add,
        onMessage: messages.add,
      );
      await TencentIdentityVerification().destroyH5FaceVerify();
    } finally {
      TencentIdentityVerificationPlatform.instance = prev;
    }

    expect(fake.calls, [
      'start:https://mobile.fangxinqian.cn/faceIntegrate?faceType=1|qiyun://signcert/callback',
      'destroy',
    ]);
    expect(successResults.single.verifyId, 'V1');
    expect(successResults.single.code, '0');
    expect(messages.single, 'hello');
  });

  test('parseCallbackResult extracts code + verifyId (case-insensitive)', () {
    final r = TencentIdentityVerification.parseCallbackResult(
      Uri.parse(
        'qiyun://signcert/callback?code=0&verifyId=U_20260708153805964442678333440',
      ),
    );
    expect(r, isNotNull);
    expect(r!.verifyId, 'U_20260708153805964442678333440');
    expect(r.code, '0');

    final r2 = TencentIdentityVerification.parseCallbackResult(
      Uri.parse('https://example.com/not-callback'),
    );
    expect(r2, isNull);
  });
}
