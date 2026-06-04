package com.eagle.screenblock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {

    companion object {
        const val METHOD_CHANNEL = "com.eagle.screenblock/accessibility"
        const val EVENT_CHANNEL = "com.eagle.screenblock/foreground_app"
        const val BLOCK_CHANNEL = "com.eagle.screenblock/block"
    }

    private var eventSink: EventChannel.EventSink? = null
    private var blockMethodChannel: MethodChannel? = null

    private val blockDismissedReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            Log.d("MainActivity", "BLOCK_DISMISSED received")
            blockMethodChannel?.invokeMethod("onBlockDismissed", null)
        }
    }

    private val blockForDayReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val packageName = intent?.getStringExtra("package_name") ?: return
            blockMethodChannel?.invokeMethod("blockForDay", packageName)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // method channel
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
                "saveBlockingState" -> {
                    val apps = call.argument<List<String>>("apps") ?: emptyList()
                    val mode = call.argument<String>("mode") ?: "specific_apps"
                    val isBlocking = call.argument<Boolean>("isBlocking") ?: false

                    val nativePrefs = getSharedPreferences(
                        "screenblock_native",
                        Context.MODE_PRIVATE
                    )
                    nativePrefs.edit()
                        .putBoolean("isBlocking", isBlocking)
                        .putString("blockingMode", mode)
                        .putStringSet("monitoredApps", apps.toHashSet())
                        .apply()

                    Log.d("MainActivity",
                        "saveBlockingState: isBlocking=$isBlocking mode=$mode apps=$apps")
                    result.success(null)
                }
                "hasUsageStatsPermission" -> {
                    val appOps = getSystemService(Context.APP_OPS_SERVICE)
                            as android.app.AppOpsManager
                    val mode = appOps.checkOpNoThrow(
                        android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                        android.os.Process.myUid(),
                        packageName
                    )
                    result.success(mode == android.app.AppOpsManager.MODE_ALLOWED)
                }
                else -> result.notImplemented()
            }
        }

        // event channel
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
                AppBlockAccessibilityService.eventCallback = { packageName ->
                    runOnUiThread {
                        eventSink?.success(packageName)
                    }
                }
                // 👇 reset when Flutter reconnects
                AppBlockAccessibilityService.isOverlayShowing = false

                AppBlockAccessibilityService.overlayResetCallback = {
                    runOnUiThread {
                        blockMethodChannel?.invokeMethod("onBlockDismissed", null)
                    }
                }
                AppBlockAccessibilityService.overlayDismissedCallback = {
                    runOnUiThread {
                        blockMethodChannel?.invokeMethod("onBlockDismissed", null)
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                AppBlockAccessibilityService.eventCallback = null
                AppBlockAccessibilityService.overlayResetCallback = null
                AppBlockAccessibilityService.overlayDismissedCallback = null
            }
        })

        // block method channel
        blockMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BLOCK_CHANNEL
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "showBlockScreen" -> {
                        val packageName =
                            call.argument<String>("packageName") ?: ""
                        BlockActivity.start(this, packageName)
                        result.success(null)
                    }
                    "dismissBlockScreen" -> {
                        sendBroadcast(
                            Intent("com.eagle.screenblock.BLOCK_DISMISSED")
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        registerReceiver(
            blockDismissedReceiver,
            IntentFilter("com.eagle.screenblock.BLOCK_DISMISSED"),
            RECEIVER_NOT_EXPORTED
        )
        registerReceiver(
            blockForDayReceiver,
            IntentFilter("com.eagle.screenblock.BLOCK_FOR_DAY"),
            RECEIVER_NOT_EXPORTED
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(blockDismissedReceiver)
        unregisterReceiver(blockForDayReceiver)
        eventSink = null
        AppBlockAccessibilityService.eventCallback = null
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