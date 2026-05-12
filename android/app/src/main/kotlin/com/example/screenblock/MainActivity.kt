package com.example.screenblock

import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val METHOD_CHANNEL = "com.example.screenblock/accessibility"
        const val EVENT_CHANNEL = "com.example.screenblock/foreground_app"
    }

    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // method channel — for permission checks and requests
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityEnabled" -> {
                    result.success(isAccessibilityEnabled())
                }
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.screenblock/block"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "showBlockScreen" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    BlockActivity.start(this, packageName)
                    result.success(null)
                }
                "dismissBlockScreen" -> {
                    // BlockActivity finishes itself via broadcast
                    sendBroadcast(Intent("com.example.screenblock.DISMISS_BLOCK"))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // event channel — streams foreground app changes to Flutter
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
                // set callback on the accessibility service
                AppBlockAccessibilityService.eventCallback = { packageName ->
                    runOnUiThread {
                        eventSink?.success(packageName)
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                AppBlockAccessibilityService.eventCallback = null
            }
        })
    }

    private fun isAccessibilityEnabled(): Boolean {
        val expectedServiceName =
            "$packageName/${AppBlockAccessibilityService::class.java.name}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return TextUtils.SimpleStringSplitter(':').also {
            it.setString(enabledServices)
        }.any { it.equals(expectedServiceName, ignoreCase = true) }
    }
}