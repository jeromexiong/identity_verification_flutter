import Flutter
import UIKit
import WebKit

/// 腾讯身份认证插件入口 — iOS（H5 刷脸 WKWebView 容器）
///
/// 对齐 uniapp `DC-WBH5FaceVerifyService` 语义：
///  - `startH5FaceVerify({h5faceUrl, h5thirdUrl}, success, message)` → 拉起 H5 刷脸 WebView
///  - `destroyH5FaceVerify()` → 关闭 WebView 容器
///  - H5 页面通过 `window.tencentApi.postMessage(msg)` 与原生通信（消息桥）
///
/// MethodChannel：`com.transcend.qiyun/tencent_identity_verification`
/// EventChannel：`com.transcend.qiyun/tencent_identity_verification/events`
public class TencentIdentityVerificationPlugin: NSObject, FlutterPlugin {
    private static let channelName = "com.transcend.qiyun/tencent_identity_verification"
    private static let eventChannelName = "com.transcend.qiyun/tencent_identity_verification/events"

    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    /// 当前 H5 刷脸容器控制器（present 的 UIViewController）
    private var faceVerifyVC: H5FaceVerifyViewController?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = TencentIdentityVerificationPlugin()
        instance.methodChannel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)

        // EventChannel：H5 刷脸回调事件（success/message）→ Dart
        let eventChannel = FlutterEventChannel(
            name: eventChannelName,
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
        instance.eventChannel = eventChannel
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "startH5FaceVerify":
            let h5faceUrl = (call.arguments as? [String: Any])?["h5faceUrl"] as? String ?? ""
            let h5thirdUrl = (call.arguments as? [String: Any])?["h5thirdUrl"] as? String ?? ""
            if h5faceUrl.isEmpty {
                result(FlutterError(code: "PARAM_ERROR", message: "h5faceUrl 为空", details: nil))
                return
            }
            startH5FaceVerify(h5faceUrl: h5faceUrl, h5thirdUrl: h5thirdUrl)
            result(nil)
        case "destroyH5FaceVerify":
            destroyH5FaceVerify()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// 拉起 H5 刷脸 WKWebView 容器
    private func startH5FaceVerify(h5faceUrl: String, h5thirdUrl: String) {
        destroyH5FaceVerify() // 防重：先关旧的

        let vc = H5FaceVerifyViewController(
            h5faceUrl: h5faceUrl,
            h5thirdUrl: h5thirdUrl
        )
        vc.onSuccess = { [weak self] result in
            self?.eventSink?(result)
        }
        vc.onMessage = { [weak self] message in
            self?.eventSink?(["type": "message", "payload": message])
        }
        faceVerifyVC = vc

        guard let root = UIApplication.shared.keyWindow?.rootViewController else {
            return
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        // 包一层 UINavigationController：让 navigationItem（返回/关闭按钮）与导航栏标题生效
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        top.present(nav, animated: true)
    }

    /// 关闭 H5 刷脸容器
    private func destroyH5FaceVerify() {
        faceVerifyVC?.dismiss(animated: true)
        faceVerifyVC = nil
    }
}

extension TencentIdentityVerificationPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

/// H5 刷脸 WKWebView 容器控制器
class H5FaceVerifyViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    private let h5faceUrl: String
    private let h5thirdUrl: String
    private var webView: WKWebView?

    /// 刷脸完成跳 thirdUrl → success 事件（payload 为完整回调 URL 字典）
    var onSuccess: (([String: Any]) -> Void)?
    /// H5 页面 window.tencentApi.postMessage(msg) → message 事件
    var onMessage: ((String) -> Void)?

    init(h5faceUrl: String, h5thirdUrl: String) {
        self.h5faceUrl = h5faceUrl
        self.h5thirdUrl = h5thirdUrl
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()  // 亮/暗夜：设置页面/导航栏/状态栏颜色
        navigationItem.title = "人脸识别"  // 兜底标题，H5 加载后会被页面 title 覆盖

        // 顶部返回/关闭按钮（WebView 可回退则回退，否则关闭）
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backOrCloseTapped)
        )

        let config = WKWebViewConfiguration()
        // 对齐腾讯官方兼容性指引：允许内联媒体播放（H5 刷脸视频录制需要）
        config.allowsInlineMediaPlayback = true
        let userContentController = WKUserContentController()
        // JS 桥：window.tencentApi.postMessage(msg) → 原生（对齐 uniapp 插件约定）
        userContentController.add(self, name: "tencentApi")
        config.userContentController = userContentController

        let webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        self.webView = webView

        // UA 上送 `;kyc/h5face;kyc/2.0` 标识（对齐腾讯官方，H5 刷脸据此进入适配分支）
        let defaultUA = webView.value(forKey: "userAgent") as? String ?? ""
        webView.customUserAgent = defaultUA + ";kyc/h5face;kyc/2.0"

        if let url = URL(string: h5faceUrl) {
            webView.load(URLRequest(url: url))
        }
    }

    /// 返回/关闭：WebView 可回退则回退，否则关闭整个容器
    @objc private func backOrCloseTapped() {
      if let webView = webView, webView.canGoBack {
        webView.goBack()
      } else {
        dismiss(animated: true)
      }
    }

    /// 是否暗夜模式（跟随系统 traitCollection.userInterfaceStyle）
    private var isDarkMode: Bool {
      traitCollection.userInterfaceStyle == .dark
    }

    /// 应用主题色（亮色白底黑字 / 暗色黑底白字，对齐 Flutter 暗夜模式）
    private func applyTheme() {
      let bgColor: UIColor = isDarkMode ? .black : .white
      let fgColor: UIColor = isDarkMode ? .white : .black

      view.backgroundColor = bgColor

      guard let navBar = navigationController?.navigationBar else { return }
      // iOS 15+ 必须用 UINavigationBarAppearance，barTintColor 已失效
      let appearance = UINavigationBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.backgroundColor = bgColor
      appearance.titleTextAttributes = [.foregroundColor: fgColor]
      navBar.standardAppearance = appearance
      navBar.scrollEdgeAppearance = appearance
      navBar.compactAppearance = appearance
      navBar.tintColor = fgColor  // 返回按钮颜色
      navBar.isTranslucent = false
      // barStyle 控制状态栏文字颜色：.default=黑字(亮色) / .black=白字(暗色)
      // ⚠️ UINavigationController 读 navBar.barStyle 而非子 VC 的 preferredStatusBarStyle
      navBar.barStyle = isDarkMode ? .black : .default
      setNeedsStatusBarAppearanceUpdate()
    }

    /// 系统暗夜切换时刷新主题（亮↔暗）
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
      super.traitCollectionDidChange(previousTraitCollection)
      if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
        applyTheme()
      }
    }

    // MARK: - WKNavigationDelegate

    /// H5 加载完成 → 优先读取页面 <title> 作为导航栏标题
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let title = webView.title, !title.isEmpty {
            navigationItem.title = title
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url?.absoluteString else {
            decisionHandler(.allow)
            return
        }
        // 拦截 thirdUrl 导航：刷脸完成跳接入方地址 → 发 success（不实际加载）
        if !h5thirdUrl.isEmpty && (url == h5thirdUrl || url.hasPrefix(h5thirdUrl)) {
            sendSuccess(callbackUrl: url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "tencentApi" else {
            return
        }
        let payload = message.body as? String ?? ""
        onMessage?(payload)
    }

    /// 解析 thirdUrl 回调 URL → success 事件字典
    private func sendSuccess(callbackUrl: String) {
        var verifyId = ""
        var code = ""
        if let components = URLComponents(string: callbackUrl) {
            verifyId = components.queryItems?.first(where: { $0.name == "verifyId" })?.value
                ?? components.queryItems?.first(where: { $0.name == "VerifyId" })?.value
                ?? ""
            code = components.queryItems?.first(where: { $0.name == "code" })?.value
                ?? components.queryItems?.first(where: { $0.name == "Code" })?.value
                ?? ""
        }
        onSuccess?([
            "type": "success",
            "verifyId": verifyId,
            "code": code,
            "message": callbackUrl,
        ])
    }

    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "tencentApi")
    }
}

extension H5FaceVerifyViewController: WKUIDelegate {
    // 关键：H5 刷脸需要 getUserMedia（相机+麦克风），iOS 15+ WKWebView 默认拒绝，
    // 必须显式授权 —— 否则「开始录制」按钮无效 → 录制超时。
    // ⚠️ WKMediaCaptureType/WKPermissionDecision 仅 iOS 15+，方法需 available 标注
    //（podspec platform 13.0，低于 15 走系统默认弹窗授权，无需额外处理）。
    @available(iOS 15.0, *)
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.grant)
    }
}