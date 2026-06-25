package com.eagle.pausenow


import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.animation.AnimatorSet
import android.animation.ValueAnimator
import android.animation.AnimatorListenerAdapter
import android.animation.Animator
import android.view.animation.AccelerateDecelerateInterpolator
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

class BlockActivity : AppCompatActivity() {

    companion object {
        private const val EXTRA_PACKAGE_NAME = "blocked_package"
        private const val ACTION_DISMISS = "com.eagle.pausenow.DISMISS_BLOCK"

        fun start(context: Context, packageName: String) {
            val intent = Intent(context, BlockActivity::class.java).apply {
                putExtra(EXTRA_PACKAGE_NAME, packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
                addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
                addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
            }
            context.startActivity(intent)
        }

    }

    private var isDismissing = false
    private var countdown = 5
    private var countdownComplete = false
    private val handler = Handler(Looper.getMainLooper())
    private var blobAnimator: AnimatorSet? = null
    private var breatheIndex = 0
    private val breatheCycle = listOf("Breathe in", "Hold", "Breathe out")
    private val breatheDurations = listOf(4000L, 7000L, 8000L)

    private val dismissReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            isDismissing = true
            finish()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (isDismissing) {
            isDismissing = false
            countdown = 5
            countdownComplete = false
            handler.removeCallbacksAndMessages(null)
            updateCountdownButton()
            startCountdown()
            startBreatheText()
        }
    }

    private val countdownRunnable = object : Runnable {
        override fun run() {
            if (countdown > 1) {
                countdown--
                updateCountdownButton()
                handler.postDelayed(this, 1000)
            } else {
                countdown = 0
                countdownComplete = true
                updateCountdownButton()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_block)

        // hide system UI
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController.apply {
            hide(WindowInsetsCompat.Type.navigationBars())
            hide(WindowInsetsCompat.Type.statusBars())
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }

        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)

        val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""
        updateTopBar(packageName)

        setupButtons()
        startBlobAnimation()
        startBreatheText()
        startCountdown()

        registerReceiver(
            dismissReceiver,
            IntentFilter(ACTION_DISMISS),
            RECEIVER_NOT_EXPORTED
        )
    }

    private fun setupButtons() {
        val dontOpenButton = findViewById<Button>(R.id.dontOpenButton)
        val openButton = findViewById<Button>(R.id.openButton)

        dontOpenButton.setOnClickListener {
            if (isDismissing) return@setOnClickListener
            isDismissing = true
            AppBlockAccessibilityService.isOverlayShowing = false
            AppBlockAccessibilityService.overlayDismissedCallback?.invoke()
            sendBroadcast(Intent("com.eagle.pausenow.BLOCK_DISMISSED"))
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(homeIntent)
            finish()
        }

        openButton.setOnClickListener {
            if (!countdownComplete || isDismissing) return@setOnClickListener
            isDismissing = true
            val blockedPackage = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""
            AppBlockAccessibilityService.isOverlayShowing = false
            AppBlockAccessibilityService.addExemption(blockedPackage)
            sendBroadcast(Intent("com.eagle.pausenow.BLOCK_DISMISSED"))
            finish()
        }
    }

    private fun startCountdown() {
        handler.postDelayed(countdownRunnable, 1000)
    }

    private fun updateCountdownButton() {
        val openButton = findViewById<Button>(R.id.openButton)
        if (countdownComplete) {
            openButton.text = "Open app (30s)"
            openButton.setTextColor(android.graphics.Color.parseColor("#EDB82A"))
            openButton.background = getDrawable(R.drawable.button_outline_gold_background)
        } else {
            openButton.text = "Open in ${countdown}s"
        }
    }

    private fun startBlobAnimation() {
        if (blobAnimator?.isRunning == true) return

        val blob = findViewById<View>(R.id.blob)

        val scaleUp = ValueAnimator.ofFloat(0.85f, 1.15f).apply {
            duration = 4000
            interpolator = AccelerateDecelerateInterpolator()
        }
        val hold = ValueAnimator.ofFloat(1.15f, 1.15f).apply {
            duration = 7000
        }
        val scaleDown = ValueAnimator.ofFloat(1.15f, 0.85f).apply {
            duration = 8000
            interpolator = AccelerateDecelerateInterpolator()
        }

        listOf(scaleUp, hold, scaleDown).forEach { animator ->
            animator.addUpdateListener {
                val scale = it.animatedValue as Float
                blob.scaleX = scale
                blob.scaleY = scale
            }
        }

        blobAnimator = AnimatorSet().apply {
            playSequentially(scaleUp, hold, scaleDown)
            addListener(object : android.animation.AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: android.animation.Animator) {
                    if (!isDismissing) start()
                }
            })
            start()
        }
    }

    private fun startBreatheText() {
        scheduleBreathe()
    }

    private fun scheduleBreathe() {
        handler.postDelayed({
            if (!isDismissing) {
                breatheIndex = (breatheIndex + 1) % breatheCycle.size
                val breatheText = findViewById<TextView>(R.id.breatheText)
                breatheText?.animate()?.alpha(0f)?.setDuration(300)?.withEndAction {
                    breatheText.text = breatheCycle[breatheIndex]
                    breatheText.animate().alpha(1f).setDuration(300).start()
                }?.start()
                scheduleBreathe()
            }
        }, breatheDurations[breatheIndex])
    }

    override fun onPause() {
        super.onPause()
        android.util.Log.d("pausenow", "⏸ BlockActivity onPause — isDismissing=$isDismissing")

        if (!isDismissing) {
            val now = System.currentTimeMillis()
            if (now - AppBlockAccessibilityService.lastBlockScreenLaunchTime < 1500) return
            AppBlockAccessibilityService.lastBlockScreenLaunchTime = now

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

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
            val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
            windowInsetsController.apply {
                hide(WindowInsetsCompat.Type.navigationBars())
                hide(WindowInsetsCompat.Type.statusBars())
                systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_APP_SWITCH ||
            keyCode == KeyEvent.KEYCODE_HOME ||
            keyCode == KeyEvent.KEYCODE_BACK) {
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    private fun getTodayUsageMinutes(packageName: String): Int? {
        return try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE)
                    as android.app.usage.UsageStatsManager

            val calendar = java.util.Calendar.getInstance()
            val endTime = calendar.timeInMillis
            calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
            calendar.set(java.util.Calendar.MINUTE, 0)
            calendar.set(java.util.Calendar.SECOND, 0)
            calendar.set(java.util.Calendar.MILLISECOND, 0)
            val startTime = calendar.timeInMillis

            val stats = usageStatsManager.queryUsageStats(
                android.app.usage.UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )

            val appStats = stats?.find { it.packageName == packageName }
            val totalMs = appStats?.totalTimeInForeground ?: return null
            if (totalMs == 0L) return null

            (totalMs / 1000 / 60).toInt()
        } catch (e: Exception) {
            android.util.Log.e("pausenow", "❌ usage stats error: $e")
            null
        }
    }

    private fun getAppName(packageName: String): String {
        return try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName
        }
    }

    private fun updateTopBar(packageName: String) {
        val topBarText = findViewById<TextView>(R.id.topBarText)

        val minutes = getTodayUsageMinutes(packageName)
        val appName = getAppName(packageName)

        topBarText.text = if (minutes != null && minutes > 0) {
            "$minutes min${if (minutes == 1) "" else "s"} of $appName today"
        } else {
            "Time limit reached"
        }
    }

    override fun onBackPressed() {
        // prevent back
    }

    override fun onDestroy() {
        super.onDestroy()
        isDismissing = true
        blobAnimator?.cancel()
        handler.removeCallbacksAndMessages(null)
        unregisterReceiver(dismissReceiver)
    }
}