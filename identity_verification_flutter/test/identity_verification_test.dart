import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:identity_verification_flutter/identity_verification_flutter.dart';
import 'package:identity_verification_flutter_platform_interface/identity_verification_flutter_platform_interface.dart';

class FakePlatform with MockPlatformInterfaceMixin
    implements IdentityVerificationPlatform {
  final calls = <String>[];

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> startFaceVerify({
    required String h5faceUrl,
    required String h5thirdUrl,
    void Function(FaceVerifyResult result)? onSuccess,
    void Function(String message)? onMessage,
  }) async {
    calls.add('start:$h5faceUrl|$h5thirdUrl');
    onSuccess?.call(const FaceVerifyResult(verifyId: 'V1', code: '0'));
    onMessage?.call('hello');
  }

  @override
  Future<void> destroy() async {
    calls.add('destroy');
  }

  @override
  // ignore: deprecated_member_use_from_same_package
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

  @override
  // ignore: deprecated_member_use_from_same_package
  Future<void> destroyH5FaceVerify() => destroy();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('startFaceVerify forwards args + dispatches callbacks', () async {
    final fake = FakePlatform();
    final prev = IdentityVerificationPlatform.instance;
    IdentityVerificationPlatform.instance = fake;

    final successResults = <FaceVerifyResult>[];
    final messages = <String>[];
    try {
      await IdentityVerification().startFaceVerify(
        h5faceUrl: 'https://mobile.fangxinqian.cn/faceIntegrate?faceType=1',
        h5thirdUrl: 'qiyun://signcert/callback',
        onSuccess: successResults.add,
        onMessage: messages.add,
      );
      await IdentityVerification().destroy();
    } finally {
      IdentityVerificationPlatform.instance = prev;
    }

    expect(fake.calls, [
      'start:https://mobile.fangxinqian.cn/faceIntegrate?faceType=1|qiyun://signcert/callback',
      'destroy',
    ]);
    expect(successResults.single.verifyId, 'V1');
    expect(messages.single, 'hello');
  });

  test('deprecated startH5FaceVerify still works', () async {
    final fake = FakePlatform();
    final prev = IdentityVerificationPlatform.instance;
    IdentityVerificationPlatform.instance = fake;
    try {
      // ignore: deprecated_member_use_from_same_package
      await IdentityVerification().startH5FaceVerify(
        h5faceUrl: 'https://example.com',
        h5thirdUrl: 'qiyun://cb',
      );
    } finally {
      IdentityVerificationPlatform.instance = prev;
    }
    expect(fake.calls.single, 'start:https://example.com|qiyun://cb');
  });

  test('FaceVerifyResult.fromUri extracts callback params', () {
    final r = FaceVerifyResult.fromUri(
      Uri.parse('qiyun://signcert/callback?code=0&verifyId=V_123'),
    );
    expect(r, isNotNull);
    expect(r!.verifyId, 'V_123');
    expect(r.code, '0');
    expect(FaceVerifyResult.fromUri(Uri.parse('https://x.com')), isNull);
  });

  test('deprecated typedefs compile', () {
    // ignore: deprecated_member_use_from_same_package
    expect(TencentIdentityVerification(), isA<IdentityVerification>());
    // ignore: deprecated_member_use_from_same_package
    expect(const FaceVerifyH5Result(verifyId: 'V1'), isA<FaceVerifyResult>());
  });
}
