package com.example.screenblock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class BlockActivity : FlutterActivity() {

    companion object {
        private const val EXTRA_PACKAGE_NAME = "blocked_package"
        private const val ACTION_DISMISS = "com.example.screenblock.DISMISS_BLOCK"
        private const val BLOCK_CHANNEL = "com.example.screenblock/block"

        fun start(context: Context, packageName: String) {
            val intent = Intent(context, BlockActivity::class.java).apply {
                putExtra(EXTRA_PACKAGE_NAME, packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
                addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            }
            context.startActivity(intent)
        }
    }

    private val dismissReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            finish()
            overridePendingTransition(0, 0)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // register the block channel IN THIS engine
        // not in MainActivity — this is a separate engine
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BLOCK_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "dismissBlockScreen" -> {
                    val blockedPackage = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""

                    // set exemption directly on AccessibilityService BEFORE finishing
                    // this is synchronous — no broadcast delay
                    AppBlockAccessibilityService.addExemption(blockedPackage)

                    sendBroadcast(Intent("com.example.screenblock.BLOCK_DISMISSED"))
                    result.success(null)

                    android.os.Handler(android.os.Looper.getMainLooper())
                        .postDelayed({
                            finish()
                            overridePendingTransition(0, 0)
                        }, 150)
                }
                "goHome" -> {
                    Log.d("BlockActivity", "goHome called — sending BLOCK_DISMISSED broadcast")

                    // reset block flag in main isolate
                    sendBroadcast(Intent("com.example.screenblock.BLOCK_DISMISSED"))
                    // don't open — send to Android home screen
                    val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                        addCategory(Intent.CATEGORY_HOME)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(homeIntent)
                    finish()
                    overridePendingTransition(0, 0)
                    result.success(null)
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)

        registerReceiver(
            dismissReceiver,
            IntentFilter(ACTION_DISMISS),
            RECEIVER_NOT_EXPORTED
        )
    }

    override fun getDartEntrypointFunctionName(): String {
        return "overlayMain"
    }

    override fun onBackPressed() {
        // prevent back from dismissing
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(dismissReceiver)
        // notify main engine that block screen was dismissed
        sendBroadcast(Intent("com.example.screenblock.BLOCK_DISMISSED"))
    }
}