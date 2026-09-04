import 'package:identity_verification_flutter_platform_interface/identity_verification_flutter_platform_interface.dart';

/// Android implementation of identity_verification_flutter.
class IdentityVerificationAndroid
    extends MethodChannelIdentityVerification {
  /// Constructs a IdentityVerificationAndroid.
  IdentityVerificationAndroid();

  /// Registers this class as the default instance of
  /// [IdentityVerificationPlatform].
  static void registerWith() {
    IdentityVerificationPlatform.instance = IdentityVerificationAndroid();
  }
}
