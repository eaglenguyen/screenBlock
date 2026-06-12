package com.eagle.screenblock

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
import android.os.Build
import android.view.KeyEvent
import android.view.WindowInsets
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

class BlockActivity : FlutterActivity() {

    private var isDismissing = false


    companion object {
        private const val EXTRA_PACKAGE_NAME = "blocked_package"
        private const val ACTION_DISMISS = "com.eagle.screenblock.DISMISS_BLOCK"
        private const val BLOCK_CHANNEL = "com.eagle.screenblock/block"

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
                    isDismissing = true  // 👈 add
                    val blockedPackage = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""
                    AppBlockAccessibilityService.isOverlayShowing = false // 👈 add

                    // set exemption directly on AccessibilityService BEFORE finishing
                    // this is synchronous — no broadcast delay
                    AppBlockAccessibilityService.addExemption(blockedPackage)

                    sendBroadcast(Intent("com.eagle.screenblock.BLOCK_DISMISSED"))
                    result.success(null)

                    android.os.Handler(android.os.Looper.getMainLooper())
                        .postDelayed({
                            finish()
                            overridePendingTransition(0, 0)
                        }, 150)
                }
                "goHome" -> {
                    isDismissing = true  // 👈 add
                    AppBlockAccessibilityService.isOverlayShowing = false // 👈 add

                    AppBlockAccessibilityService.overlayDismissedCallback?.invoke()

                    // reset block flag in main isolate
                    sendBroadcast(Intent("com.eagle.screenblock.BLOCK_DISMISSED"))
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

        // disable recents/overview gesture while block screen is showing
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.hide(WindowInsets.Type.systemGestures())
        }
        // hide navigation bar and status bar
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.apply {
            hide(WindowInsetsCompat.Type.navigationBars())
            hide(WindowInsetsCompat.Type.statusBars())
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }

        // keep screen on
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)

        window.decorView.setBackgroundColor(android.graphics.Color.parseColor("#16162A"))


        registerReceiver(
            dismissReceiver,
            IntentFilter(ACTION_DISMISS),
            RECEIVER_NOT_EXPORTED
        )
    }

    override fun getDartEntrypointFunctionName(): String {
        return "overlayMain"
    }

    override fun onPause() {
        super.onPause()
        if (!isDismissing) {
            val pkg = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: return
            val relaunchIntent = Intent(this, BlockActivity::class.java).apply {
                putExtra(EXTRA_PACKAGE_NAME, pkg)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
                addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
                addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
            }
            startActivity(relaunchIntent)
        }
    }

    override fun onBackPressed() {
        // prevent back from dismissing
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        // block recents, home, and back buttons
        if (keyCode == KeyEvent.KEYCODE_APP_SWITCH ||
            keyCode == KeyEvent.KEYCODE_HOME ||
            keyCode == KeyEvent.KEYCODE_BACK) {
            return true // consume — do nothing
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            // re-hide system UI whenever focus returns
            WindowCompat.setDecorFitsSystemWindows(window, false)
            val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
            windowInsetsController.apply {
                hide(WindowInsetsCompat.Type.navigationBars())
                hide(WindowInsetsCompat.Type.statusBars())
                systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(dismissReceiver)
    }
}