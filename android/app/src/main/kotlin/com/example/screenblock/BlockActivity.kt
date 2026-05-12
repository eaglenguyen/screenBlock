package com.example.screenblock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

// Block
class BlockActivity : FlutterActivity() {

    companion object {
        private const val EXTRA_PACKAGE_NAME = "blocked_package"
        private const val ACTION_DISMISS = "com.example.screenblock.DISMISS_BLOCK"

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
    }
}