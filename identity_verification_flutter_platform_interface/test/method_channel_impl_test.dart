import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_verification_flutter_platform_interface/identity_verification_flutter_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelIdentityVerification();
  const channel = MethodChannel(
    'com.transcend.qiyun/tencent_identity_verification',
  );

  test('default instance is MethodChannelIdentityVerification', () {
    expect(
      IdentityVerificationPlatform.instance,
      isInstanceOf<MethodChannelIdentityVerification>(),
    );
  });

  test('FaceVerifyResult.fromMap handles case-insensitive keys', () {
    final r = FaceVerifyResult.fromMap({'verifyId': 'V1', 'code': '0'});
    expect(r.verifyId, 'V1');
    expect(r.code, '0');

    final r2 = FaceVerifyResult.fromMap({'VerifyId': 'V2', 'Code': '1'});
    expect(r2.verifyId, 'V2');
    expect(r2.code, '1');
  });

  test('FaceVerifyResult.fromUri extracts callback params', () {
    final r = FaceVerifyResult.fromUri(
      Uri.parse('qiyun://signcert/callback?code=0&verifyId=V1'),
    );
    expect(r, isNotNull);
    expect(r!.verifyId, 'V1');
    expect(r.code, '0');

    expect(FaceVerifyResult.fromUri(Uri.parse('https://example.com')), isNull);
  });

  test('startFaceVerify invokes method channel with args', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      calls.add(methodCall);
      return null;
    });

    await platform.startFaceVerify(
      h5faceUrl: 'https://mobile.fangxinqian.cn/faceIntegrate?faceType=1',
      h5thirdUrl: 'qiyun://signcert/callback',
    );
    await platform.destroy();

    expect(calls.map((c) => c.method), [
      'startH5FaceVerify',
      'destroyH5FaceVerify',
    ]);
    expect(
      calls[0].arguments['h5faceUrl'],
      'https://mobile.fangxinqian.cn/faceIntegrate?faceType=1',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
