import 'package:flutter_test/flutter_test.dart';
import 'package:identity_verification_flutter_android/identity_verification_flutter_android.dart';
import 'package:identity_verification_flutter_platform_interface/identity_verification_flutter_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registerWith sets instance', () {
    IdentityVerificationAndroid.registerWith();
    expect(
      IdentityVerificationPlatform.instance,
      isInstanceOf<IdentityVerificationAndroid>(),
    );
  });
}
