# identity_verification_flutter_platform_interface

[![pub package](https://img.shields.io/pub/v/identity_verification_flutter.svg)](https://pub.dev/packages/identity_verification_flutter)

A common platform interface for the [identity_verification_flutter](https://github.com/jeromexiong/identity_verification_flutter) plugin.

## Usage

To implement a new platform-specific implementation of `identity_verification_flutter`, extend `IdentityVerificationPlatform` with an implementation that performs the platform-specific behavior, and when you register your plugin, set the default `IdentityVerificationPlatform` by calling `IdentityVerificationPlatform.instance = MyPlatformIdentityVerification()`.
