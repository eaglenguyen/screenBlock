package com.eagle.screenblock

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.accessibility.AccessibilityEvent

class AppBlockAccessibilityService : AccessibilityService() {

    companion object {
        var eventCallback: ((String) -> Unit)? = null
        var isRunning = false
        private val exemptedPackages = mutableSetOf<String>()
        var currentForegroundApp: String? = null
        var overlayResetCallback: (() -> Unit)? = null
        var overlayDismissedCallback: (() -> Unit)? = null
        var isOverlayShowing = false

        fun addExemption(packageName: String) {
            exemptedPackages.add(packageName)
            overlayResetCallback?.invoke()
            isOverlayShowing = false
            android.util.Log.d("AccessibilityService", "exempting: $packageName")

            android.os.Handler(android.os.Looper.getMainLooper())
                .postDelayed({
                    exemptedPackages.remove(packageName)
                    android.util.Log.d("AccessibilityService",
                        "exemption expired for: $packageName currentForegroundApp=$currentForegroundApp")

                    // 👇 only fire if still on that exact app
                    if (currentForegroundApp == packageName) {
                        android.util.Log.d("AccessibilityService", "still on $packageName — re-blocking")
                        android.os.Handler(android.os.Looper.getMainLooper())
                            .postDelayed({
                                eventCallback?.invoke(packageName)
                            }, 500)
                    } else {
                        android.util.Log.d("AccessibilityService",
                            "no longer on $packageName — skipping re-block")
                    }
                }, 30000)
        }
    }

    private lateinit var prefs: SharedPreferences
    private val pauseCheckHandler = android.os.Handler(android.os.Looper.getMainLooper())

    // Runnable 1 — pause expiry check (runs always)
    private val pauseCheckRunnable = object : Runnable {
        override fun run() {
            if (isPauseExpired()) {
                android.util.Log.d("ScreenBlock", "⏰ Pause expired")
                eventCallback?.invoke("__scheduleResumed__")
                // immediately block if on a monitored app
                val pkg = currentForegroundApp
                if (pkg != null && pkg != "com.eagle.screenblock" && !isOverlayShowing) {
                    val isBlocking = prefs.getBoolean("isBlocking", false)
                    val blockingMode = prefs.getString("blockingMode", "specific_apps") ?: "specific_apps"
                    val monitoredApps = prefs.getStringSet("monitoredApps", emptySet()) ?: emptySet()
                    val shouldBlock = when (blockingMode) {
                        "specific_apps" -> monitoredApps.contains(pkg)
                        else -> !monitoredApps.contains(pkg)
                    }
                    if (shouldBlock && isBlocking &&
                        !exemptedPackages.contains(pkg)) {
                        isOverlayShowing = true
                        val intent = Intent(this@AppBlockAccessibilityService, BlockActivity::class.java).apply {
                            putExtra("blocked_package", pkg)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
                            addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
                            addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
                        }
                        startActivity(intent)
                    }
                }
            }
            pauseCheckHandler.postDelayed(this, 5000)
        }
    }

    // Runnable 2 — safety poll (only when Flutter is killed/backgrounded)
    private val blockingPollRunnable = object : Runnable {
        override fun run() {
            // 👇 only when Flutter is not connected
            if (eventCallback == null) {
                val isBlocking = prefs.getBoolean("isBlocking", false)
                val pauseActive = isPauseActive()
                val pkg = currentForegroundApp

                if (isBlocking && !pauseActive && pkg != null &&
                    !isOverlayShowing && pkg != "com.eagle.screenblock" &&
                    !exemptedPackages.contains(pkg)) {
                    val blockingMode = prefs.getString("blockingMode", "specific_apps") ?: "specific_apps"
                    val monitoredApps = prefs.getStringSet("monitoredApps", emptySet()) ?: emptySet()
                    val shouldBlock = when (blockingMode) {
                        "specific_apps" -> monitoredApps.contains(pkg)
                        else -> !monitoredApps.contains(pkg)
                    }
                    if (shouldBlock) {
                        android.util.Log.d("ScreenBlock", "🔄 Safety poll blocking: $pkg")
                        isOverlayShowing = true
                        val intent = Intent(this@AppBlockAccessibilityService, BlockActivity::class.java).apply {
                            putExtra("blocked_package", pkg)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
                            addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
                            addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
                        }
                        startActivity(intent)
                    }
                }
            }
            pauseCheckHandler.postDelayed(this, 5000)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isRunning = true
        isOverlayShowing = false
        prefs = getSharedPreferences("screenblock_native", Context.MODE_PRIVATE)
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 100
        }
        serviceInfo = info
        pauseCheckHandler.postDelayed(pauseCheckRunnable, 5000) // 👈 start 1
        pauseCheckHandler.postDelayed(blockingPollRunnable, 5000) // 👈 Start 2

        android.util.Log.d("AccessibilityService", "onServiceConnected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        android.util.Log.d("ScreenBlock", "🎯 onAccessibilityEvent pkg=$packageName eventCallback=${eventCallback != null} isOverlayShowing=$isOverlayShowing")
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        if (packageName.contains("systemui") ||
            packageName == "android" ||
            packageName == "com.eagle.screenblock") return

        // 👇 if user goes to launcher — clear foreground app
        if (packageName.contains("launcher") ||
            packageName.contains("nexuslauncher") ||
            packageName.contains("pixel") ||
            packageName == "com.google.android.apps.nexuslauncher") {
            currentForegroundApp = null // 👈 clear it
            return
        }


        currentForegroundApp = packageName

        // 👇 check pause expiry ALWAYS — regardless of Flutter state
        if (isPauseExpired()) {
            android.util.Log.d("ScreenBlock", "⏰ Pause expired — notifying Flutter")
            eventCallback?.invoke("__scheduleResumed__")
        }

        // 👇 skip if pause still active
        if (isPauseActive()) {
            android.util.Log.d("ScreenBlock", "⏸ Pause active — skipping")
            return
        }

        if (exemptedPackages.contains(packageName)) {
            android.util.Log.d("AccessibilityService", "skipping exempted: $packageName")
            return
        }

        if (isOverlayShowing) {
            android.util.Log.d("AccessibilityService", "overlay showing — skipping")
            return
        }

        // Flutter running — use Dart callback
        if (eventCallback != null) {
            eventCallback?.invoke(packageName)
            return
        }

        // Flutter killed — read SharedPreferences directly
        android.util.Log.d("AccessibilityService",
            "Flutter not running — checking native prefs for: $packageName")
        checkAndBlockFromPrefs(packageName)
    }
    private fun checkAndBlockFromPrefs(packageName: String) {
        android.util.Log.d("ScreenBlock", "🔍 checkAndBlockFromPrefs pkg=$packageName")
        val isBlocking = prefs.getBoolean("isBlocking", false)
        android.util.Log.d("ScreenBlock", "🔍 isBlocking=$isBlocking")
        if (!isBlocking) return

        val blockingMode = prefs.getString("blockingMode", "specific_apps") ?: "specific_apps"
        val monitoredApps = prefs.getStringSet("monitoredApps", emptySet()) ?: emptySet()
        android.util.Log.d("ScreenBlock", "🔍 mode=$blockingMode monitoredApps=$monitoredApps")
        android.util.Log.d("ScreenBlock", "🔍 checking pkg=$packageName contains=${monitoredApps.contains(packageName)}")

        val shouldBlock = when (blockingMode) {
            "specific_apps" -> monitoredApps.contains(packageName)
            else -> !monitoredApps.contains(packageName)
        }

        android.util.Log.d("ScreenBlock", "🔍 shouldBlock=$shouldBlock isOverlayShowing=$isOverlayShowing")

        if (shouldBlock) {
            isOverlayShowing = true
            val intent = Intent(this, BlockActivity::class.java).apply {
                putExtra("blocked_package", packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
                addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
                addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
            }
            startActivity(intent)
        }
    }

    private fun isPauseExpired(): Boolean {
        val prefs = getSharedPreferences("screenblock_native", Context.MODE_PRIVATE)
        val pauseEndTime = prefs.getLong("schedulePauseEndTime", 0L)
        if (pauseEndTime == 0L) return false // no pause saved
        val now = System.currentTimeMillis()
        if (now >= pauseEndTime) {
            // pause expired — clear it
            prefs.edit().putLong("schedulePauseEndTime", 0L).apply()
            return true
        }
        return false
    }

    private fun isPauseActive(): Boolean {
        val prefs = getSharedPreferences("screenblock_native", Context.MODE_PRIVATE)
        val pauseEndTime = prefs.getLong("schedulePauseEndTime", 0L)
        if (pauseEndTime == 0L) return false
        return System.currentTimeMillis() < pauseEndTime
    }


    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        eventCallback = null
        pauseCheckHandler.removeCallbacks(pauseCheckRunnable) // 👈 stop
        pauseCheckHandler.removeCallbacks(blockingPollRunnable) // 👈 add

    }
}