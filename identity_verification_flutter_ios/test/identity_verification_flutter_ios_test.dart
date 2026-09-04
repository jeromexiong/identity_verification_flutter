import 'package:flutter_test/flutter_test.dart';
import 'package:identity_verification_flutter_ios/identity_verification_flutter_ios.dart';
import 'package:identity_verification_flutter_platform_interface/identity_verification_flutter_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registerWith sets instance', () {
    IdentityVerificationIos.registerWith();
    expect(
      IdentityVerificationPlatform.instance,
      isInstanceOf<IdentityVerificationIos>(),
    );
  });
}
