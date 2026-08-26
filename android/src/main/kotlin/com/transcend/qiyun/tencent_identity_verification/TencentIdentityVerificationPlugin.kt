package com.transcend.qiyun.tencent_identity_verification

import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 腾讯身份认证插件入口 — Android 侧（H5 刷脸 WebView 容器）
 *
 * 对齐 uniapp `DC-WBH5FaceVerifyService` 语义：
 *  - `startH5FaceVerify({h5faceUrl, h5thirdUrl}, success, message)` → 拉起 H5 刷脸 WebView
 *  - `destroyH5FaceVerify()` → 关闭 WebView 容器
 *  - H5 页面通过 `window.tencentApi.postMessage(msg)` 与原生通信（消息桥）
 *
 * MethodChannel：`com.transcend.qiyun/tencent_identity_verification`
 * EventChannel：`com.transcend.qiyun/tencent_identity_verification/events`
 */
class TencentIdentityVerificationPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware {

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var applicationContext: Context? = null

    companion object {
        private const val CHANNEL = "com.transcend.qiyun/tencent_identity_verification"
        private const val EVENT_CHANNEL =
            "com.transcend.qiyun/tencent_identity_verification/events"
    }

    private fun eventStreamHandler() = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            // 注入 EventSink 到 Activity（H5 刷脸回调事件经此发出）
            H5FaceVerifyActivity.eventSink = events
        }

        override fun onCancel(arguments: Any?) {
            H5FaceVerifyActivity.eventSink = null
        }
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel?.setStreamHandler(eventStreamHandler())
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        applicationContext = null
        H5FaceVerifyActivity.eventSink = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "startH5FaceVerify" -> {
                val h5faceUrl = call.argument<String>("h5faceUrl") ?: ""
                val h5thirdUrl = call.argument<String>("h5thirdUrl") ?: ""
                if (h5faceUrl.isEmpty()) {
                    result.error("PARAM_ERROR", "h5faceUrl 为空", null)
                    return
                }
                startH5FaceVerify(h5faceUrl, h5thirdUrl)
                result.success(null)
            }
            "destroyH5FaceVerify" -> {
                destroyH5FaceVerify()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** 拉起 H5 刷脸 WebView 容器 Activity（事件经 EventChannel 回传） */
    private fun startH5FaceVerify(h5faceUrl: String, h5thirdUrl: String) {
        val activity = activityBinding?.activity
        val context = if (activity != null) activity.applicationContext else applicationContext
            ?: return

        val intent = Intent(context, H5FaceVerifyActivity::class.java).apply {
            putExtra(H5FaceVerifyActivity.EXTRA_URL, h5faceUrl)
            putExtra(H5FaceVerifyActivity.EXTRA_THIRD_URL, h5thirdUrl)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    /** 关闭 H5 刷脸 WebView 容器 */
    private fun destroyH5FaceVerify() {
        H5FaceVerifyActivity.current?.finish()
        H5FaceVerifyActivity.current = null
    }
}