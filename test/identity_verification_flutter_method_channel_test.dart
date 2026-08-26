import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_verification_flutter/identity_verification_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelTencentIdentityVerification platform =
      MethodChannelTencentIdentityVerification();
  const MethodChannel channel = MethodChannel(
    'com.transcend.qiyun/tencent_identity_verification',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getPlatformVersion') {
            return '42';
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('startH5FaceVerify invokes method channel with args', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          calls.add(methodCall);
          return null;
        });
    await platform.startH5FaceVerify(
      h5faceUrl: 'https://mobile.fangxinqian.cn/faceIntegrate?faceType=1',
      h5thirdUrl: 'qiyun://signcert/callback',
    );
    await platform.destroyH5FaceVerify();
    expect(calls.map((c) => c.method), [
      'startH5FaceVerify',
      'destroyH5FaceVerify',
    ]);
    expect(
      calls[0].arguments['h5faceUrl'],
      'https://mobile.fangxinqian.cn/faceIntegrate?faceType=1',
    );
    expect(calls[0].arguments['h5thirdUrl'], 'qiyun://signcert/callback');
  });
}
