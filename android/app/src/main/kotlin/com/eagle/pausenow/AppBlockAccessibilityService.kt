package com.eagle.pausenow

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.accessibility.AccessibilityEvent

class AppBlockAccessibilityService : AccessibilityService() {



    companion object {
        private val systemWhitelist = setOf(
            "android",
            "com.android.systemui",
            "com.android.dialer",
            "com.android.phone",
            "com.android.contacts",
            "com.android.mms",
            "com.android.messaging",
            "com.android.settings",
            "com.google.android.gms",
            "com.google.android.gsf",
            "com.google.android.googlequicksearchbox",
            "com.google.android.inputmethod.latin",
            "com.samsung.android.dialer",
            "com.samsung.android.contacts",
            "com.samsung.android.messaging",
            "com.android.emergency",
            "com.eagle.pausenow",
        )



        var eventCallback: ((String) -> Unit)? = null
        var isRunning = false
        private val exemptedPackages = mutableSetOf<String>()
        var currentForegroundApp: String? = null
        var overlayResetCallback: (() -> Unit)? = null
        var overlayDismissedCallback: (() -> Unit)? = null
        var isOverlayShowing = false
        var lastBlockScreenLaunchTime = 0L

        fun addExemption(packageName: String) {
            exemptedPackages.add(packageName)
            overlayResetCallback?.invoke()
            isOverlayShowing = false
            lastBlockScreenLaunchTime = 0L // 👈 reset so next block launches immediately

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

    fun isSystemApp(packageName: String): Boolean {
        // explicit whitelist
        if (systemWhitelist.contains(packageName)) return true
        if (packageName.contains("launcher")) return true
        if (packageName.contains("systemui")) return true

        // 👇 use PackageManager to check if it's a real system app
        return try {
            val pm = applicationContext.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            // FLAG_SYSTEM means it's in /system/app or /system/priv-app
            (appInfo.flags.toLong() and android.content.pm.ApplicationInfo.FLAG_SYSTEM.toLong()) != 0L
        } catch (e: Exception) {
            false // if we can't find the app, don't block it
        }
    }

    private lateinit var prefs: SharedPreferences
    private val pauseCheckHandler = android.os.Handler(android.os.Looper.getMainLooper())

    // Runnable 1 — pause expiry check (runs always)
    private val pauseCheckRunnable = object : Runnable {
        override fun run() {
            if (isPauseExpired()) {
                android.util.Log.d("pausenow", "⏰ Pause expired")
                eventCallback?.invoke("__scheduleResumed__")
                // immediately block if on a monitored app
                val pkg = currentForegroundApp
                if (pkg != null && pkg != "com.eagle.pausenow" && !isOverlayShowing) {
                    val isBlocking = prefs.getBoolean("isBlocking", false)
                    val blockingMode = prefs.getString("blockingMode", "specific_apps") ?: "specific_apps"
                    val monitoredApps = prefs.getStringSet("monitoredApps", emptySet()) ?: emptySet()
                    val shouldBlock = when (blockingMode) {
                        "specific_apps" -> monitoredApps.contains(pkg)
                        else -> !monitoredApps.contains(pkg) && !isSystemApp(pkg)
                    }
                    if (shouldBlock && isBlocking &&
                        !exemptedPackages.contains(pkg)) {
                        val now = System.currentTimeMillis()
                        if (now - lastBlockScreenLaunchTime < 4000) {
                            android.util.Log.d("pausenow", "⏳ skipping — block screen already loading")
                            return
                        }
                        lastBlockScreenLaunchTime = now
                        isOverlayShowing = true
                        val intent = Intent(this@AppBlockAccessibilityService, BlockActivity::class.java).apply {
                            putExtra("blocked_package", pkg)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
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
                    !isOverlayShowing && pkg != "com.eagle.pausenow" &&
                    !exemptedPackages.contains(pkg)) {
                    val blockingMode = prefs.getString("blockingMode", "specific_apps") ?: "specific_apps"
                    val monitoredApps = prefs.getStringSet("monitoredApps", emptySet()) ?: emptySet()
                    val shouldBlock = when (blockingMode) {
                        "specific_apps" -> monitoredApps.contains(pkg)
                        else -> !monitoredApps.contains(pkg) && !isSystemApp(pkg)
                    }
                    if (shouldBlock) {
                        val now = System.currentTimeMillis()
                        if (now - lastBlockScreenLaunchTime < 4000) {
                            android.util.Log.d("pausenow", "⏳ skipping — block screen already loading")
                            return
                        }
                        lastBlockScreenLaunchTime = now
                        isOverlayShowing = true
                        android.util.Log.d("pausenow", "🔄 Safety poll blocking: $pkg")
                        val intent = Intent(this@AppBlockAccessibilityService, BlockActivity::class.java).apply {
                            putExtra("blocked_package", pkg)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
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
        prefs = getSharedPreferences("pausenow_native", Context.MODE_PRIVATE)
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
        android.util.Log.d("pausenow", "🎯 onAccessibilityEvent pkg=$packageName eventCallback=${eventCallback != null} isOverlayShowing=$isOverlayShowing")
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        if (packageName.contains("systemui") ||
            packageName == "android" ||
            packageName == "com.eagle.pausenow") return

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
            android.util.Log.d("pausenow", "⏰ Pause expired — notifying Flutter")
            eventCallback?.invoke("__scheduleResumed__")
        }

        // 👇 skip if pause still active
        if (isPauseActive()) {
            android.util.Log.d("pausenow", "⏸ Pause active — skipping")
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
        if (isSystemApp(packageName)) return // 👈 add at top

        val isBlocking = prefs.getBoolean("isBlocking", false)
        if (!isBlocking) return

        val blockingMode = prefs.getString("blockingMode", "specific_apps") ?: "specific_apps"
        val monitoredApps = prefs.getStringSet("monitoredApps", emptySet()) ?: emptySet()

        val shouldBlock = when (blockingMode) {
            "specific_apps" -> monitoredApps.contains(packageName)
            else -> !monitoredApps.contains(packageName) && !isSystemApp(packageName) // 👈 double check
        }

        if (shouldBlock) {
            val now = System.currentTimeMillis()
            if (now - lastBlockScreenLaunchTime < 4000) return
            lastBlockScreenLaunchTime = now
            isOverlayShowing = true
            val intent = Intent(this, BlockActivity::class.java).apply {
                putExtra("blocked_package", packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
            }
            startActivity(intent)
        }
    }

    private fun isPauseExpired(): Boolean {
        val prefs = getSharedPreferences("pausenow_native", Context.MODE_PRIVATE)
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
        val prefs = getSharedPreferences("pausenow_native", Context.MODE_PRIVATE)
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