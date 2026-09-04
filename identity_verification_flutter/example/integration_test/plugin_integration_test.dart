// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:identity_verification_flutter/identity_verification_flutter.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('startFaceVerify / destroy smoke', (WidgetTester tester) async {
    final plugin = IdentityVerification();
    // 真机冒烟：拉起 H5 刷脸 WebView（缺真实 verifyId 时仅验证「不抛异常」）
    await plugin.startFaceVerify(
      h5faceUrl: 'https://mobile.fangxinqian.cn/faceIntegrate?faceType=1',
      h5thirdUrl: 'qiyun://signcert/callback',
    );
    await plugin.destroy();
    expect(true, isTrue);
  });
}
