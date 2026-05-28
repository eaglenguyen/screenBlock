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
                        "exemption expired: $packageName")
                    if (currentForegroundApp == packageName) {
                        android.os.Handler(android.os.Looper.getMainLooper())
                            .postDelayed({
                                eventCallback?.invoke(packageName)
                            }, 500)
                    }
                }, 30000)
        }
    }

    private lateinit var prefs: SharedPreferences

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
        android.util.Log.d("AccessibilityService", "onServiceConnected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        if (packageName.contains("systemui") ||
            packageName.contains("launcher") ||
            packageName == "android" ||
            packageName == "com.eagle.screenblock") return

        currentForegroundApp = packageName

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
        val isBlocking = prefs.getBoolean("isBlocking", false)
        if (!isBlocking) {
            android.util.Log.d("AccessibilityService", "isBlocking=false — skipping")
            return
        }

        val blockingMode = prefs.getString("blockingMode", "specific_apps")
            ?: "specific_apps"
        val monitoredApps = prefs.getStringSet("monitoredApps", emptySet())
            ?: emptySet()

        android.util.Log.d("AccessibilityService",
            "Kotlin check: mode=$blockingMode apps=$monitoredApps checking=$packageName")

        val shouldBlock = when (blockingMode) {
            "specific_apps" -> monitoredApps.contains(packageName)
            else -> !monitoredApps.contains(packageName)
        }

        if (shouldBlock) {
            android.util.Log.d("AccessibilityService",
                "🔴 Kotlin blocking: $packageName isOverlayShowing set to true")
            isOverlayShowing = true
            val intent = Intent(this, BlockActivity::class.java).apply {
                putExtra("blocked_package", packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
            }
            startActivity(intent)
        }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        eventCallback = null
    }
}