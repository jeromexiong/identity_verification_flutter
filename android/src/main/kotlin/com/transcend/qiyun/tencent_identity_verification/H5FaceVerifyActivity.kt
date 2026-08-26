package com.transcend.qiyun.tencent_identity_verification

import android.annotation.SuppressLint
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.PermissionRequest
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import io.flutter.plugin.common.EventChannel

/**
 * H5 刷脸 WebView 容器 — 对齐 uniapp `DC-WBH5FaceVerifyService` 语义
 *
 * 行为（对齐 kyc-uni-demo/pages/index/h5faceverify_demo.vue + 插件 AAR）：
 *  1. 全屏 WebView 加载 `h5faceUrl`（放心签 faceIntegrate / 腾讯慧眼 H5 刷脸页）
 *  2. 注入 JS 桥 `window.tencentApi.postMessage(msg)` → 原生回调（H5 页面通信约定）
 *  3. 导航到 `h5thirdUrl`（刷脸完成跳转接入方地址）→ 发送 success 回调（带 verifyId/code）→ 不自动关
 *  4. `destroyH5FaceVerify()` → finish 本 Activity
 *
 * 与 Flutter 侧契约（EventChannel）：
 *  - onSuccess: { "type": "success", "verifyId": "...", "code": "...", "message": "..." }
 *  - onMessage: { "type": "message", "payload": "...(postMessage 原文)" }
 */
class H5FaceVerifyActivity : AppCompatActivity() {
    companion object {
        const val EXTRA_URL = "h5faceUrl"
        const val EXTRA_THIRD_URL = "h5thirdUrl"

        /** 当前 Activity 的 EventChannel.Sink（插件 EventChannel onListen 时注入） */
        var eventSink: EventChannel.EventSink? = null

        @SuppressLint("StaticFieldLeak")
        var current: H5FaceVerifyActivity? = null
    }

    private lateinit var webView: WebView
    private lateinit var toolbar: Toolbar
    private var progressBar: ProgressBar? = null
    private var thirdUrl: String = ""

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val url = intent.getStringExtra(EXTRA_URL)?.takeIf { it.isNotEmpty() }
        if (url.isNullOrEmpty()) {
            Toast.makeText(this, "h5faceUrl 为空", Toast.LENGTH_SHORT).show()
            finish()
            return
        }
        thirdUrl = intent.getStringExtra(EXTRA_THIRD_URL) ?: ""
        current = this

        webView = WebView(this)
        val settings = webView.settings
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.mediaPlaybackRequiresUserGesture = false
        settings.useWideViewPort = true
        settings.loadWithOverviewMode = true
        // 对齐腾讯官方兼容性指引：UA 上送 `;kyc/h5face;kyc/2.0` 标识，
        // 腾讯 H5 刷脸页据此进入适配分支（否则录制/摄像头授权可能不生效）
        settings.userAgentString =
            (settings.userAgentString ?: "") + ";kyc/h5face;kyc/2.0"

        // JS 桥：H5 页面 window.tencentApi.postMessage(msg) → 原生（对齐 uniapp 插件约定）
        webView.addJavascriptInterface(H5JsBridge(), "tencentApi")

        webView.webChromeClient = object : WebChromeClient() {
            override fun onProgressChanged(view: WebView?, newProgress: Int) {
                progressBar?.progress = newProgress
                if (newProgress >= 100) {
                    progressBar?.visibility = View.GONE
                }
            }

            // 关键：H5 刷脸需要 getUserMedia（相机+麦克风），Android WebView 默认拒绝，
            // 必须在此显式 grant —— 否则「开始录制」按钮无效 → 录制超时。
            override fun onPermissionRequest(request: PermissionRequest) {
                runOnUiThread {
                    // 仅授权相机/麦克风（对齐 H5 刷脸最小权限；其余保持默认拒绝）
                    val granted = request.resources.filter {
                        it == PermissionRequest.RESOURCE_VIDEO_CAPTURE ||
                            it == PermissionRequest.RESOURCE_AUDIO_CAPTURE
                    }
                    // 拒绝会回调 H5 的 error，导致录制不可用；直接全部授权所需资源
                    request.grant(granted.toTypedArray())
                }
            }
        }

        // 拦截 thirdUrl 导航：刷脸完成跳接入方地址 → 发送 success（不自动关闭）
        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(
                view: WebView?,
                request: WebResourceRequest?
            ): Boolean {
                val url = request?.url?.toString() ?: ""
                if (thirdUrl.isNotEmpty() && (url == thirdUrl || url.startsWith(thirdUrl))) {
                    sendSuccess(url)
                    return true // 消费导航，不实际加载接入方页面
                }
                return false
            }

            @Suppress("DEPRECATION")
            override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                val target = url ?: ""
                if (thirdUrl.isNotEmpty() && (target == thirdUrl || target.startsWith(thirdUrl))) {
                    sendSuccess(target)
                    return true
                }
                return false
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                // 优先读取 H5 页面 <title> 作为导航栏标题
                val h5Title = view?.title
                if (!h5Title.isNullOrEmpty()) {
                    toolbar.title = h5Title
                }
            }
        }

        // 顶部导航栏（亮色白底黑字 / 暗色黑底白字，对齐 Flutter AppTdNavBar 风格）
        // 注意：toolbar 必须是字段而非局部变量 —— onPageFinished 回调中要读 title，
        // 局部变量声明在回调之后会导致 Unresolved reference（编译错误）。
        val isDark = (resources.configuration.uiMode and
            android.content.res.Configuration.UI_MODE_NIGHT_MASK) ==
            android.content.res.Configuration.UI_MODE_NIGHT_YES
        toolbar = Toolbar(this).apply {
            setBackgroundColor(if (isDark) android.graphics.Color.BLACK else android.graphics.Color.WHITE)
            setTitle("人脸识别")
            setTitleTextColor(if (isDark) android.graphics.Color.WHITE else android.graphics.Color.BLACK)
            // 返回箭头（appcompat 内置，兼容所有 API；android.R ic_menu_arrow_back 在新 SDK 已移除）
            navigationIcon = resources.getDrawable(
                androidx.appcompat.R.drawable.abc_ic_ab_back_material,
                theme
            )?.apply {
                setTint(if (isDark) android.graphics.Color.WHITE else android.graphics.Color.BLACK)
            }
            setNavigationOnClickListener {
                onBackPressed()  // WebView 可回退则回退，否则返回关闭
            }
        }

        // 顶部细进度条（2dp，非固定高度，不抢占空间）
        val progressBar = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 100
        }
        this.progressBar = progressBar

        setContentView(
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                addView(
                    toolbar,
                    ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        resources.displayMetrics.density.times(48f).toInt()
                    )
                )
                addView(
                    progressBar,
                    ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        (2 * resources.displayMetrics.density).toInt()
                    )
                )
                addView(
                    webView,
                    ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT
                    )
                )
            }
        )

        // 暗夜模式适配：状态栏颜色 + 图标色跟随系统（isDark 已在 toolbar 段声明）
        // 状态栏背景：亮色白底 / 暗色黑底（非灰底，对齐 Flutter 页面）
        window.statusBarColor = if (isDark) {
            android.graphics.Color.BLACK
        } else {
            android.graphics.Color.WHITE
        }
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            @Suppress("DEPRECATION")
            var flags = window.decorView.systemUiVisibility
            // 亮色：浅色状态栏（深色图标）；暗色：清除该 flag（浅色图标）
            flags = if (isDark) {
                flags and android.view.View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR.inv()
            } else {
                flags or android.view.View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
            }
            window.decorView.systemUiVisibility = flags
        } else {
            // API<23 无法做浅色图标，统一黑底（暗色下也自然）
            window.statusBarColor = android.graphics.Color.BLACK
        }

        webView.loadUrl(url)
    }

    /** 发送 success 事件（刷脸完成跳 thirdUrl） */
    private fun sendSuccess(callbackUrl: String) {
        val uri = Uri.parse(callbackUrl)
        val code = uri.getQueryParameter("code") ?: uri.getQueryParameter("Code") ?: ""
        val verifyId =
            uri.getQueryParameter("verifyId") ?: uri.getQueryParameter("VerifyId") ?: ""
        val payload = mapOf<String, Any?>(
            "type" to "success",
            "verifyId" to verifyId,
            "code" to code,
            "message" to callbackUrl,
        )
        eventSink?.success(payload)
    }

    /** JS 桥类：window.tencentApi.postMessage(msg)（对齐 uniapp H5 插件通信约定） */
    inner class H5JsBridge {
        @JavascriptInterface
        fun postMessage(message: String) {
            runOnUiThread {
                val payload = mapOf<String, Any?>(
                    "type" to "message",
                    "payload" to message,
                )
                eventSink?.success(payload)
            }
        }
    }

    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (current === this) {
            current = null
        }
        webView.destroy()
    }
}