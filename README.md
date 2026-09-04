# identity_verification_flutter

腾讯身份认证 H5 刷脸桥接 Flutter 插件（放心签 faceIntegrate / 腾讯慧眼 H5 WebView 容器）。

[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.44.0-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.12.0-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

| 包 | pub.dev |
|---|---|
| `identity_verification_flutter` | [![pub package](https://img.shields.io/pub/v/identity_verification_flutter.svg)](https://pub.dev/packages/identity_verification_flutter) |
| `identity_verification_flutter_platform_interface` | [![pub package](https://img.shields.io/pub/v/identity_verification_flutter_platform_interface.svg)](https://pub.dev/packages/identity_verification_flutter_platform_interface) |
| `identity_verification_flutter_android` | [![pub package](https://img.shields.io/pub/v/identity_verification_flutter_android.svg)](https://pub.dev/packages/identity_verification_flutter_android) |
| `identity_verification_flutter_ios` | [![pub package](https://img.shields.io/pub/v/identity_verification_flutter_ios.svg)](https://pub.dev/packages/identity_verification_flutter_ios) |

## 简介

本插件为 Flutter 应用提供腾讯身份认证 H5 刷脸能力的桥接封装，采用 WebView 容器加载腾讯 H5 刷脸页面，支持：

- H5 刷脸页面加载与交互
- JS 消息桥（`window.tencentApi.postMessage`）
- 刷脸结果回调（`verifyId` / `code`）
- 暗夜模式跟随系统
- 导航栏 / 状态栏 / 进度条自定义

## 架构（Federated Plugin）

本插件采用 [Flutter federated plugin](https://docs.flutter.dev/development/packages-and-plugins/developing-packages#federated-plugins) 架构：

```
identity_verification_flutter/          # 根目录
├── identity_verification_flutter/                    # App-facing 包 — 对外 API
├── identity_verification_flutter_platform_interface/ # 平台接口 + MethodChannel 默认实现
├── identity_verification_flutter_android/            # Android 原生代码
├── identity_verification_flutter_ios/                # iOS 原生代码
├── docs/                                             # 文档与计划
└── example/                                          # 示例应用（在各子包内）
```

| 包                                                 | 职责                                    | pub.dev |
| -------------------------------------------------- | --------------------------------------- | ------- |
| [`identity_verification_flutter`](https://pub.dev/packages/identity_verification_flutter)                    | App-facing 包 — 对外 API                | [![pub](https://img.shields.io/pub/v/identity_verification_flutter.svg)](https://pub.dev/packages/identity_verification_flutter) |
| [`identity_verification_flutter_platform_interface`](https://pub.dev/packages/identity_verification_flutter_platform_interface) | 平台接口 + MethodChannel 默认实现       | [![pub](https://img.shields.io/pub/v/identity_verification_flutter_platform_interface.svg)](https://pub.dev/packages/identity_verification_flutter_platform_interface) |
| [`identity_verification_flutter_android`](https://pub.dev/packages/identity_verification_flutter_android)            | Android 原生代码 + dartPluginClass 注册 | [![pub](https://img.shields.io/pub/v/identity_verification_flutter_android.svg)](https://pub.dev/packages/identity_verification_flutter_android) |
| [`identity_verification_flutter_ios`](https://pub.dev/packages/identity_verification_flutter_ios)                | iOS 原生代码 + dartPluginClass 注册     | [![pub](https://img.shields.io/pub/v/identity_verification_flutter_ios.svg)](https://pub.dev/packages/identity_verification_flutter_ios) |

宿主只需依赖 `identity_verification_flutter`，平台包自动传递依赖。

## 快速开始

### 1. 添加依赖

```yaml
# pubspec.yaml
dependencies:
  identity_verification_flutter: ^0.1.0
```

或本地 path 依赖：

```yaml
dependencies:
  identity_verification_flutter:
    path: plugins/identity_verification_flutter
```

### 2. 配置权限

#### Android（AndroidManifest.xml）

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

#### iOS（Info.plist）

```xml
<key>NSCameraUsageDescription</key>
<string>人脸识别需要使用摄像头进行活体检测</string>
<key>NSMicrophoneUsageDescription</key>
<string>人脸识别活体检测需要录制声音动作，请允许麦克风权限</string>
```

### 3. 使用插件

```dart
import 'package:identity_verification_flutter/identity_verification_flutter.dart';

final plugin = IdentityVerification();

// 拉起 H5 刷脸
await plugin.startFaceVerify(
  h5faceUrl: 'https://mobile.fangxinqian.cn/faceIntegrate?faceType=1&verifyId=...',
  h5thirdUrl: 'qiyun://signcert/callback',
  onSuccess: (result) {
    // 刷脸完成
    print('verifyId: ${result.verifyId}, code: ${result.code}');
  },
  onMessage: (message) {
    // H5 页面消息
    print('message: $message');
  },
);

// 关闭 WebView 容器
await plugin.destroy();
```

## API 参考

### IdentityVerification

| 方法                                                             | 说明                 |
| ---------------------------------------------------------------- | -------------------- |
| `startFaceVerify({h5faceUrl, h5thirdUrl, onSuccess, onMessage})` | 拉起 H5 刷脸 WebView |
| `destroy()`                                                      | 关闭 WebView 容器    |

### FaceVerifyResult

| 属性       | 类型     | 说明    |
| ---------- | -------- | ------- |
| `verifyId` | `String` | 验证 ID |
| `code`     | `String` | 结果码  |

### 平台契约

- MethodChannel: `com.transcend.qiyun/tencent_identity_verification`
- EventChannel: `com.transcend.qiyun/tencent_identity_verification/events`
  - `success`: `{ type: "success", verifyId, code, message }`
  - `message`: `{ type: "message", payload }`

## 兼容性

参考：[腾讯官方兼容性指引](https://cloud.tencent.com/document/product/1007/61076)

| 配置项            | Android                                             | iOS                                           |
| ----------------- | --------------------------------------------------- | --------------------------------------------- |
| UA 标识           | `settings.userAgentString += ";kyc/h5face;kyc/2.0"` | `customUserAgent += ";kyc/h5face;kyc/2.0"`    |
| 摄像头/麦克风授权 | `onPermissionRequest` → `grant`                     | `requestMediaCapturePermissionFor` → `.grant` |
| 内联媒体播放      | `mediaPlaybackRequiresUserGesture = false`          | `allowsInlineMediaPlayback = true`            |
| JS 消息桥         | `addJavascriptInterface`                            | `userContentController.add`                   |

## 扩展平台支持

本插件采用 Federated Plugin 架构，可以轻松扩展支持其他平台（如 ohos/OpenHarmony、Web、Windows、macOS、Linux）。

### 扩展步骤

#### 1. 创建平台包

```bash
# 以 ohos 为例
mkdir identity_verification_flutter_ohos
cd identity_verification_flutter_ohos
```

#### 2. 目录结构

```
identity_verification_flutter_ohos/
├── lib/
│   └── identity_verification_flutter_ohos.dart    # Dart 注册代码
├── ohos/                                          # ohos 原生代码
│   ├── src/main/
│   │   ├── ets/                                   # ArkTS 代码
│   │   │   └── TencentIdentityVerificationPlugin.ets
│   │   └── resources/                             # 资源文件
│   ├── build.gradle.kts                           # 构建配置（如需）
│   └── ohos-package.json5                         # ohos 包配置
├── pubspec.yaml
└── README.md
```

#### 3. 实现平台接口

**lib/identity_verification_flutter_ohos.dart**:

```dart
import 'package:identity_verification_flutter_platform_interface/identity_verification_flutter_platform_interface.dart';

class IdentityVerificationOhos extends IdentityVerificationPlatform {
  static void registerWith() {
    IdentityVerificationPlatform.instance = IdentityVerificationOhos();
  }

  @override
  Future<void> startFaceVerify({
    required String h5faceUrl,
    required String h5thirdUrl,
    void Function(FaceVerifyResult result)? onSuccess,
    void Function(String message)? onMessage,
  }) async {
    // 调用 ohos 原生代码实现
    // 通过 MethodChannel 或直接调用原生 API
  }

  @override
  Future<void> destroy() async {
    // 关闭 WebView 容器
  }
}
```

#### 4. 配置 pubspec.yaml

```yaml
name: identity_verification_flutter_ohos
description: ohos 平台实现
version: 0.1.0

environment:
  sdk: ^3.12.0
  flutter: ">=3.44.0"

dependencies:
  flutter:
    sdk: flutter
  identity_verification_flutter_platform_interface:
    path: ../identity_verification_flutter_platform_interface

flutter:
  plugin:
    implements: identity_verification_flutter
    platforms:
      ohos:
        dartPluginClass: IdentityVerificationOhos
```

#### 5. 更新 App-facing 包

在 `identity_verification_flutter/pubspec.yaml` 中添加平台依赖：

```yaml
dependencies:
  identity_verification_flutter_ohos:
    path: ../identity_verification_flutter_ohos
```

### ohos 平台实现要点

#### WebView 容器

使用 ohos 的 `Web` 组件加载 H5 页面：

```typescript
// ArkTS 示例
import web_webview from '@ohos.web.webview';

@Entry
@Component
struct H5FaceVerifyPage {
  controller: web_webview.WebviewController = new web_webview.WebviewController();

  build() {
    Column() {
      Web({ src: this.h5faceUrl, controller: this.controller })
        .onPageEnd((event) => {
          // 页面加载完成
        })
        .javaScriptAccess(true)
        .mixedMode(MixedMode.All)
    }
  }
}
```

#### JS 消息桥

使用 `JavaScriptProxy` 注入原生接口：

```typescript
// 注入 tencentApi 对象
this.controller.addJavaScriptProxy({
  name: "tencentApi",
  object: {
    postMessage: (msg: string) => {
      // 处理 H5 消息
      this.onMessage?.(msg);
    },
  },
  methodList: ["postMessage"],
});
```

#### 权限配置

在 `module.json5` 中声明权限：

```json5
{
  module: {
    requestPermissions: [
      { name: "ohos.permission.CAMERA" },
      { name: "ohos.permission.MICROPHONE" },
      { name: "ohos.permission.INTERNET" },
    ],
  },
}
```

### 其他平台扩展参考

| 平台    | WebView 组件             | JS 桥接方式                                                   |
| ------- | ------------------------ | ------------------------------------------------------------- |
| ohos    | `Web` (ArkTS)            | `JavaScriptProxy`                                             |
| Web     | `iframe` / `window.open` | `postMessage`                                                 |
| Windows | `WebView2`               | `AddHostObjectToScript`                                       |
| macOS   | `WKWebView`              | `WKScriptMessageHandler`                                      |
| Linux   | `WebKitGTK`              | `webkit_user_content_manager_register_script_message_handler` |

更多实现细节参考现有 Android/iOS 平台包代码。

## 开发

### 环境要求

- Flutter >= 3.44.0
- Dart >= 3.12.0
- Android Studio / Xcode

### 本地开发

```bash
# 克隆仓库
git clone https://github.com/jeromexiong/identity_verification_flutter.git
cd identity_verification_flutter

# 进入 app-facing 包
cd identity_verification_flutter

# 获取依赖
flutter pub get

# 运行测试
flutter test
```

### 项目结构

```
identity_verification_flutter/
├── .github/                    # GitHub Actions 工作流
├── identity_verification_flutter/                    # App-facing 包
│   ├── lib/                    # Dart API
│   ├── example/                # 示例应用
│   └── test/                   # 单元测试
├── identity_verification_flutter_platform_interface/ # 平台接口
│   ├── lib/                    # 接口定义
│   └── test/                   # 接口测试
├── identity_verification_flutter_android/            # Android 实现
│   ├── android/                # Kotlin 原生代码
│   ├── lib/                    # Dart 注册
│   └── test/                   # Android 测试
├── identity_verification_flutter_ios/                # iOS 实现
│   ├── ios/                    # Swift 原生代码
│   ├── lib/                    # Dart 注册
│   └── test/                   # iOS 测试
└── README.md                   # 本文件
```

## 相关链接

- GitHub: https://github.com/jeromexiong/identity_verification_flutter
- Issues: https://github.com/jeromexiong/identity_verification_flutter/issues
- pub.dev: `identity_verification_flutter`

## 许可证

本项目基于 MIT 许可证开源 - 详见 [LICENSE](identity_verification_flutter/LICENSE) 文件。

## 说明

本插件仅做 H5 刷脸桥接（放心签托管），不集成腾讯原生 SDK（WbCloudFaceVerifySdk / WBFaceVerifyCustomerService）——
原生 SDK 需腾讯 appid/licence + 后端 faceId/签名接口，属另一通道。
