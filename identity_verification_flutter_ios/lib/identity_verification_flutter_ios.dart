import 'package:identity_verification_flutter_platform_interface/identity_verification_flutter_platform_interface.dart';

/// iOS implementation of identity_verification_flutter.
class IdentityVerificationIos
    extends MethodChannelIdentityVerification {
  /// Constructs a IdentityVerificationIos.
  IdentityVerificationIos();

  /// Registers this class as the default instance of
  /// [IdentityVerificationPlatform].
  static void registerWith() {
    IdentityVerificationPlatform.instance = IdentityVerificationIos();
  }
}
