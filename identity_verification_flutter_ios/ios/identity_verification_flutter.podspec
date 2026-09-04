Pod::Spec.new do |s|
  s.name             = 'identity_verification_flutter'
  s.version          = '0.0.4'
  s.summary          = '腾讯身份认证 H5 刷脸桥接 Flutter 插件'
  s.description      = '封装放心签 faceIntegrate / 腾讯慧眼 H5 刷脸 WebView（WKWebView），MethodChannel com.transcend.qiyun/tencent_identity_verification，对齐 uniapp DC-WBH5FaceVerifyService 语义'
  s.homepage         = 'https://github.com/transcendtech'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'TranscendTech' => 'dev@transcendtech.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'identity_verification_flutter_ios/Sources/**/*'
  s.public_header_files = 'identity_verification_flutter_ios/Sources/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'

  # 主工程无 [CP] Embed Pods Frameworks，必须静态链接
  s.static_framework = true

  # 插件内声明 iOS 权限描述（H5 刷脸 getUserMedia 需要；即使宿主未显式声明也能避免崩溃）
  s.info_plist = {
    'NSCameraUsageDescription' => '人脸识别需要使用摄像头进行活体检测',
    'NSMicrophoneUsageDescription' => '人脸识别活体检测需要录制声音动作，请允许麦克风权限',
  }

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }


end