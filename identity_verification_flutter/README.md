# identity_verification_flutter

[![pub package](https://img.shields.io/pub/v/identity_verification_flutter.svg)](https://pub.dev/packages/identity_verification_flutter)

腾讯身份认证 H5 刷脸桥接 Flutter 插件（放心签 faceIntegrate / 腾讯慧眼 H5 WebView 容器）。

> 仓库：https://github.com/jeromexiong/identity_verification_flutter ｜ pub.dev：[`identity_verification_flutter`](https://pub.dev/packages/identity_verification_flutter)

## 架构（Federated Plugin）

本插件采用 [Flutter federated plugin](https://docs.flutter.dev/development/packages-and-plugins/developing-packages#federated-plugins) 架构（对齐 [url_launcher](https://github.com/flutter/packages/tree/main/packages/url_launcher)）：

| 包                                                 | 职责                                    |
| -------------------------------------------------- | --------------------------------------- |
| `identity_verification_flutter`                    | App-facing 包 — 对外 API                |
| `identity_verification_flutter_platform_interface` | 平台接口 + MethodChannel 默认实现       |
| `identity_verification_flutter_android`            | Android 原生代码 + dartPluginClass 注册 |
| `identity_verification_flutter_ios`                | iOS 原生代码 + dartPluginClass 注册     |

宿主只需依赖 `identity_verification_flutter`，平台包自动传递依赖。

对齐 uniapp 插件 `DC-WBH5FaceVerifyService` 语义（`startH5FaceVerify` / `destroyH5FaceVerify` /
`window.tencentApi.postMessage` 消息桥）。

## 接入（宿主 pubspec）

```yaml
dependencies:
  identity_verification_flutter: ^0.0.4
```

或本地 path 依赖（从宿主仓库内）：

```yaml
dependencies:
  identity_verification_flutter:
    path: plugins/identity_verification_flutter
```

## API

```dart
import 'package:identity_verification_flutter/identity_verification_flutter.dart';

final plugin = TencentIdentityVerification();

// 拉起 H5 刷脸（完整 CA：先协议页 documenttext → 用户同意 → faceIntegrate 人脸 H5）
await plugin.startH5FaceVerify(
  h5faceUrl: 'https://mobile.fangxinqian.cn/faceIntegrate?faceType=1&verifyId=...',
  h5thirdUrl: 'qiyun://signcert/callback',   // 刷脸完成后要跳转的接入方地址
  onSuccess: (result) {
    // result.verifyId / result.code — 刷脸完成回调
  },
  onMessage: (message) {
    // H5 页面 window.tencentApi.postMessage 消息桥
  },
);

// 关闭 WebView 容器（刷脸完成或用户取消后调用）
await plugin.destroyH5FaceVerify();

// thirdUrl 回跳解析
final parsed = TencentIdentityVerification.parseCallbackResult(uri);
// parsed.verifyId, parsed.code
```

### 平台契约

- MethodChannel：`com.transcend.qiyun/tencent_identity_verification`
- EventChannel：`com.transcend.qiyun/tencent_identity_verification/events`
  - `success`：`{ type: "success", verifyId, code, message }`
  - `message`：`{ type: "message", payload }`

### Android

- `H5FaceVerifyActivity`：全屏 WebView 容器，注入 `window.tencentApi.postMessage` JS 桥，
  `shouldOverrideUrlLoading` 拦截 `h5thirdUrl` → 发 `success`。
- Manifest 权限：`INTERNET` / `ACCESS_NETWORK_STATE` / `CAMERA` / `RECORD_AUDIO`（H5 刷脸需相机/麦克风）。

### iOS

- `H5FaceVerifyViewController`：WKWebView 容器 + `WKScriptMessageHandler`（名 `tencentApi`），
  `decidePolicyFor` 拦截 `h5thirdUrl` → 发 `success`。
- Podfile 静态链接（`use_frameworks! :linkage => :static`）。

## 显示（导航栏 / 状态栏 / 进度条 / 暗夜模式）

对齐 Flutter 页面 `AppTdNavBar` 风格（亮色白底黑字 / 暗色黑底白字）：

| 元素       | Android                                                                                                                                                            | iOS                                                                                                                                                                                   |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 顶部导航栏 | `Toolbar` 白底 + 黑字标题「人脸识别」 + 返回箭头（appcompat `abc_ic_ab_back_material`）                                                                            | `UINavigationController` 白底 + 黑字标题 + `chevron.left` 返回按钮                                                                                                                    |
| 返回行为   | WebView 可回退则 `goBack`，否则返回关闭                                                                                                                            | 同左（`canGoBack` → `goBack`，否则 `dismiss`）                                                                                                                                        |
| 状态栏     | 白底 + 深色图标（`SYSTEM_UI_FLAG_LIGHT_STATUS_BAR`，API23+；API<23 默认黑底）                                                                                      | `preferredStatusBarStyle = .darkContent`（白底深色文字）                                                                                                                              |
| 进度条     | 顶部 2dp 细进度条（`onProgressChanged` 驱动，完成后隐藏）                                                                                                          | —                                                                                                                                                                                     |
| 暗夜模式   | 跟随系统：`@style/H5FaceVerifyTheme`（values 亮色 / values-night 暗色）+ `uiMode` configChanges + toolbar/状态栏按 `isDark` 切换（黑底白字 / 黑色背景 + 浅色图标） | 跟随系统：`applyTheme()` 按 `traitCollection.userInterfaceStyle` 切换导航栏/背景（白↔黑）+ `preferredStatusBarStyle`（darkContent↔lightContent）+ `traitCollectionDidChange` 实时刷新 |

## 兼容（对齐腾讯官方兼容性指引）

参考：https://cloud.tencent.com/document/product/1007/61076

| 配置项            | Android                                                        | iOS                                                     | 说明                                                                                        |
| ----------------- | -------------------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| UA 标识           | `settings.userAgentString += ";kyc/h5face;kyc/2.0"`            | `customUserAgent += ";kyc/h5face;kyc/2.0"`              | 腾讯 H5 刷脸页据此进入适配分支（缺省则录制/摄像头授权可能不生效）                           |
| 摄像头/麦克风授权 | `onPermissionRequest` → `grant(VIDEO_CAPTURE / AUDIO_CAPTURE)` | `requestMediaCapturePermissionFor` → `.grant`（iOS15+） | H5 刷脸 `getUserMedia` 默认被 WebView 拒绝，必须显式授权，否则「开始录制」点不动 → 录制超时 |
| 内联媒体播放      | `mediaPlaybackRequiresUserGesture = false`                     | `allowsInlineMediaPlayback = true`                      | 刷脸视频录制需要内联播放                                                                    |
| JS 消息桥         | `addJavascriptInterface(jsBridge, "tencentApi")`               | `userContentController.add(self, name: "tencentApi")`   | H5 `window.tencentApi.postMessage(msg)` → 原生 `message` 事件                               |
| thirdUrl 拦截     | `shouldOverrideUrlLoading` 命中 `h5thirdUrl` → 发 `success`    | `decidePolicyFor` 命中 → 发 `success`                   | 刷脸完成跳转接入方地址，不实际加载                                                          |

## 权限（宿主 + 插件双端）

### Android（宿主 Manifest 需声明）

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

> ⚠️ 宿主 `Flutter 运行时权限` 也需主动请求：相机 + 麦克风（`PermissionUtil.requestCamera()` + `requestMicrophone()`），
> 否则 H5 `getUserMedia` 拿不到权限 → 录制按钮无效 → 超时。

### iOS（宿主 Info.plist 需声明）

```xml
<key>NSCameraUsageDescription</key>
<string>人脸识别需要使用摄像头进行活体检测</string>
<key>NSMicrophoneUsageDescription</key>
<string>人脸识别活体检测需要录制声音动作，请允许麦克风权限</string>
```

> ⚠️ 缺 `NSMicrophoneUsageDescription` 时 iOS 直接崩溃（调用麦克风未声明）。

## 说明

本插件仅做 H5 刷脸桥接（放心签托管），不集成腾讯原生 SDK（WbCloudFaceVerifySdk / WBFaceVerifyCustomerService）——
原生 SDK 需腾讯 appid/licence + 后端 faceId/签名接口，属另一通道（见计划 Roadmap）。
