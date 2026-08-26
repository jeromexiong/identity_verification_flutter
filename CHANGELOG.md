## 0.0.5

- **迁移到 Built-in Kotlin**（对齐 Flutter 3.44+ 新标准）：
  - 移除 legacy `kotlin-android` 插件 + `kotlinOptions`，改用 `kotlin.compilerOptions{}` DSL（jvmTarget 17）。
  - 提升最低 Flutter 版本到 3.44 / Dart 3.12（KGP 2.0+ 要求）。
- 修复：插件 Android 构建 JVM target 与 example 模板不一致（Java 21 vs Kotlin 17）→ 统一 Java 17 + Kotlin 17。

## 0.0.4

- **独立发布**：包名从 `tencent_identity_verification` 更改为 `identity_verification_flutter`
  （仓库 https://github.com/jeromexiong/identity_verification_flutter，发布 pub.dev）。
- 对外 Dart API 不变：类名 `TencentIdentityVerification` / `TencentIdentityVerificationPlatform` /
  `MethodChannelTencentIdentityVerification`，MethodChannel/EventChannel 名不变。
- Android native 包名 `com.transcend.qiyun.tencent_identity_verification` 不变（宿主兼容）。
- 补全 LICENSE（MIT）+ pubspec 元信息（homepage/repository/issue_tracker）。

## 0.0.3

- 优化显示：Android Toolbar（白底黑字标题 + 返回箭头）、iOS UINavigationController（白底 + chevron 返回）、状态栏白底深色图标（Android SYSTEM_UI_FLAG_LIGHT_STATUS_BAR / iOS darkContent）。
- 优化兼容（对齐腾讯官方 https://cloud.tencent.com/document/product/1007/61076）：
  - UA 上送 `;kyc/h5face;kyc/2.0`（Android userAgentString / iOS customUserAgent）
  - WebView 摄像头/麦克风授权（Android onPermissionRequest grant / iOS requestMediaCapturePermissionFor grant）
  - 内联媒体播放（Android mediaPlaybackRequiresUserGesture=false / iOS allowsInlineMediaPlayback=true）
- 修复：宿主缺少 RECORD_AUDIO/NSMicrophoneUsageDescription 导致 H5 录制超时；iOS 媒体授权 API 版本标注。

## 0.0.1

- 腾讯身份认证 H5 刷脸桥接（放心签 faceIntegrate / 腾讯慧眼 H5 WebView 容器）。
- MethodChannel `com.transcend.qiyun/tencent_identity_verification`：
  - `startH5FaceVerify({h5faceUrl, h5thirdUrl}, onSuccess, onMessage)` — 拉起 H5 刷脸 WebView
  - `destroyH5FaceVerify()` — 关闭 WebView 容器
- EventChannel `com.transcend.qiyun/tencent_identity_verification/events`：
  - `success` 事件（刷脸完成跳 thirdUrl 回调，带 verifyId/code）
  - `message` 事件（H5 页面 `window.tencentApi.postMessage` 消息桥）
- Android：WebView 容器 Activity + JS 桥 + thirdUrl 拦截（对齐 uniapp `DC-WBH5FaceVerifyService`）。
- iOS：WKWebView 容器 + WKScriptMessageHandler + thirdUrl 拦截。
- Dart 侧 `TencentIdentityVerification` 单例 + `parseCallbackResult`（thirdUrl 回跳解析）。
