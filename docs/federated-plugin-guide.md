# Flutter Federated Plugin 开发指南

> 基于 `identity_verification_flutter` 的实战经验总结

## 什么是 Federated Plugin

Flutter federated plugin 是一种将插件拆分为多个独立包的架构模式，每个包负责一个关注点。对齐 [flutter/packages](https://github.com/flutter/packages) 中 `url_launcher` 的官方模式。

## 包结构

```
identity_verification_flutter/                          # 仓库根目录
├── identity_verification_flutter/                      # App-facing 包
│   ├── pubspec.yaml
│   ├── lib/identity_verification_flutter.dart          # barrel 导出
│   ├── test/
│   ├── example/                                        # 示例应用（含 android/ ios/ runner）
│   ├── CHANGELOG.md, README.md, LICENSE
│   └── analysis_options.yaml
├── identity_verification_flutter_platform_interface/   # 平台接口包
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── identity_verification_flutter_platform_interface.dart  # 抽象类 + 数据类
│   │   └── src/method_channel_impl.dart                           # MethodChannel 默认实现
│   ├── test/
│   └── CHANGELOG.md, README.md, LICENSE
├── identity_verification_flutter_android/              # Android 平台包
│   ├── pubspec.yaml
│   ├── lib/identity_verification_flutter_android.dart  # dartPluginClass
│   ├── android/                                        # Kotlin 原生代码
│   ├── test/
│   └── CHANGELOG.md, README.md, LICENSE
├── identity_verification_flutter_ios/                  # iOS 平台包
│   ├── pubspec.yaml
│   ├── lib/identity_verification_flutter_ios.dart      # dartPluginClass
│   ├── ios/
│   │   ├── identity_verification_flutter_ios.podspec   # CocoaPods（s.name = Dart 包名）
│   │   └── identity_verification_flutter_ios/          # SPM 包目录（目录名 = Dart 包名）
│   │       ├── Package.swift                           # 产品名用连字符
│   │       └── Sources/identity_verification_flutter_ios/
│   ├── test/
│   └── CHANGELOG.md, README.md, LICENSE
├── .github/workflows/
│   ├── ci.yml                                          # 矩阵测试
│   └── publish.yml                                     # 顺序发布
└── scripts/
    └── bump_version.sh                                 # 版本更新脚本
```

## 各包职责

| 包                     | 职责                                       | 关键文件                                           |
| ---------------------- | ------------------------------------------ | -------------------------------------------------- |
| **app-facing**         | 对外 API，用户 import 的唯一入口           | `IdentityVerification` 类                          |
| **platform_interface** | 抽象接口 + 数据类 + MethodChannel 默认实现 | `IdentityVerificationPlatform`, `FaceVerifyResult` |
| **android**            | Android 原生代码 + dartPluginClass 注册    | `IdentityVerificationAndroid.registerWith()`       |
| **ios**                | iOS 原生代码 + dartPluginClass 注册        | `IdentityVerificationIos.registerWith()`           |

## pubspec.yaml 配置要点

### platform_interface（无内部依赖）

```yaml
name: identity_verification_flutter_platform_interface
version: 0.1.0
publish_to: none # 本地开发用，CI 发布时自动移除

environment:
  sdk: ^3.12.0
  flutter: ">=3.44.0"

dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.0.2
```

### 平台包（android/ios）

```yaml
name: identity_verification_flutter_ios
version: 0.1.0
publish_to: none

flutter:
  plugin:
    implements: identity_verification_flutter # ← 指向 app-facing 包名
    platforms:
      ios:
        pluginClass: TencentIdentityVerificationPlugin
        dartPluginClass: IdentityVerificationIos # ← dartPluginClass 自动注册
        swiftPackageManager:
          enabled: true

dependencies:
  identity_verification_flutter_platform_interface:
    path: ../identity_verification_flutter_platform_interface # 本地开发用
```

### app-facing 包

```yaml
name: identity_verification_flutter
version: 0.1.0
publish_to: none

dependencies:
  identity_verification_flutter_platform_interface:
    path: ../identity_verification_flutter_platform_interface
  identity_verification_flutter_android:
    path: ../identity_verification_flutter_android
  identity_verification_flutter_ios:
    path: ../identity_verification_flutter_ios

flutter:
  plugin:
    platforms:
      android:
        default_package: identity_verification_flutter_android
      ios:
        default_package: identity_verification_flutter_ios
```

## 关键实现模式

### 1. 平台接口抽象类

```dart
abstract class IdentityVerificationPlatform extends PlatformInterface {
  IdentityVerificationPlatform() : super(token: _token);
  static final Object _token = Object();

  static IdentityVerificationPlatform _instance = MethodChannelIdentityVerification();
  static IdentityVerificationPlatform get instance => _instance;
  static set instance(IdentityVerificationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> startFaceVerify({...}) => throw UnimplementedError();
  Future<void> destroy() => throw UnimplementedError();
}
```

### 2. dartPluginClass 自动注册

```dart
// identity_verification_flutter_ios.dart
class IdentityVerificationIos extends MethodChannelIdentityVerification {
  static void registerWith() {
    IdentityVerificationPlatform.instance = IdentityVerificationIos();
  }
}
```

### 3. App-facing 单例代理

```dart
class IdentityVerification {
  static final _instance = IdentityVerification._();
  factory IdentityVerification() => _instance;

  Future<void> startFaceVerify({...}) {
    return IdentityVerificationPlatform.instance.startFaceVerify(...);
  }
}
```

### 4. Deprecated 别名（零成本迁移）

```dart
@Deprecated('Use IdentityVerification instead')
typedef TencentIdentityVerification = IdentityVerification;

@Deprecated('Use startFaceVerify instead')
Future<void> startH5FaceVerify({...}) => startFaceVerify(...);
```

## iOS SPM 配置要点（踩坑记录）

### 目录命名规则

Flutter SPM 工具按 **Dart 包名** 查找 `Package.swift`。目录名必须匹配：

```
ios/
├── identity_verification_flutter_ios/      # ← 目录名 = Dart 包名
│   ├── Package.swift
│   └── Sources/
│       └── identity_verification_flutter_ios/  # ← target 名
│           └── Plugin.swift
```

### Package.swift 产品名

Flutter 把下划线转连字符：

```swift
// Dart 包名: identity_verification_flutter_ios
// Flutter 查找的产品名: identity-verification-flutter-ios

let package = Package(
    name: "identity_verification_flutter_ios",          // 包名（下划线）
    products: [
        .library(
            name: "identity-verification-flutter-ios",  // 产品名（连字符）
            targets: ["identity_verification_flutter_ios"]  // target 名（下划线）
        )
    ],
    targets: [
        .target(
            name: "identity_verification_flutter_ios",  // target 名（下划线）
            path: "Sources/identity_verification_flutter_ios"
        )
    ]
)
```

### Podspec 兼容

```ruby
s.name = 'identity_verification_flutter_ios'  # ← 必须与 Dart 包名一致
s.source_files = 'identity_verification_flutter_ios/Sources/**/*'
```

> **踩坑：** podspec 文件名和 `s.name` 都必须与 Dart 包名匹配。旧名 `identity_verification_flutter.podspec` 会导致 CocoaPods 找不到 podspec。

## CI/CD 配置

### CI（ci.yml）— 矩阵测试

```yaml
test:
  strategy:
    matrix:
      package:
        - identity_verification_flutter_platform_interface
        - identity_verification_flutter_android
        - identity_verification_flutter_ios
        - identity_verification_flutter
  steps:
    - working-directory: ${{ matrix.package }}
      run: flutter pub get && flutter test
```

### 发布（publish.yml）— 顺序发布

```yaml
steps:
  # 1. 从 tag 提取版本号
  - run: echo "VERSION=${GITHUB_REF_NAME#v}" >> "$GITHUB_OUTPUT"

  # 2. 移除 publish_to: none，替换 path → 版本号
  - run: |
      VER="${{ steps.version.outputs.VERSION }}"
      for pkg in ...; do
        sed -i '/^publish_to: none/d' "$pkg/pubspec.yaml"
        sed -i "s|path: ../xxx|^${VER}|" "$pkg/pubspec.yaml"
      done

  # 3. 按依赖顺序发布
  - run: cd platform_interface && yes | dart pub publish
  - run: cd android && yes | dart pub publish
  - run: cd ios && yes | dart pub publish
  - run: cd identity_verification_flutter && yes | dart pub publish
```

## 发版流程

```bash
# 1. 更新版本号
./scripts/bump_version.sh 0.2.0

# 2. 提交 + 推送 tag
git add -A && git commit -m "chore: bump to 0.2.0"
git tag v0.2.0
git push origin main --tags

# 3. CI 自动发布 4 个包到 pub.dev
```

## 常见问题

### Q: 本地 `dart pub publish` 报 "can't have path dependencies"

A: 这是预期行为。本地 pubspec 用 `path:` 开发，CI 发布时自动替换为版本号。加 `publish_to: none` 消除警告。

### Q: iOS 构建报 "Module not found"

A: 三个命名必须一致：
1. `ios/` 下的 **目录名** = Dart 包名（如 `identity_verification_flutter_ios/`）
2. **podspec 文件名** = `{Dart包名}.podspec`（如 `identity_verification_flutter_ios.podspec`）
3. `s.name` = Dart 包名
4. `Package.swift` 产品名用 **连字符**（Flutter 自动把 `_` 转 `-`）

### Q: 新增平台（如 ohos）

A: 创建 `identity_verification_flutter_ohos/`，实现 `IdentityVerificationPlatform`，在 app-facing `pubspec.yaml` 添加 `default_package`。

### Q: 发布时版本号如何管理？

A: 四个包的版本号独立管理：
- `platform_interface` — 接口变更时 bump
- `android` / `ios` — 原生代码变更时 bump
- `app-facing` — 任何子包 bump 时跟随 bump（传递依赖）

发布顺序：`platform_interface → android → ios → app-facing`

### Q: `publish_to: none` 和 CI 发布冲突吗？

A: 不冲突。CI 的 `publish.yml` 会用 `sed` 自动移除 `publish_to: none` 行，替换 `path:` 为版本号，发布后再恢复（CI 环境是临时的，无需恢复）。

### Q: iOS 真机调试无线连接很慢？

A: iOS 26 无线调试的 VM Service 发现需要 75+ 秒。建议用 USB 线连接获得更快的 Hot Reload 速度。
