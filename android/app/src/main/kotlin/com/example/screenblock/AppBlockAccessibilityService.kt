package com.example.screenblock

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent


class AppBlockAccessibilityService : AccessibilityService() {

    companion object {
        var eventCallback: ((String) -> Unit)? = null
        var isRunning = false
        // 👈 exemption set managed directly in Kotlin
        private val exemptedPackages = mutableSetOf<String>()
        var currentForegroundApp: String? = null
        var overlayResetCallback: (() -> Unit)? = null

        fun addExemption(packageName: String) {
            exemptedPackages.add(packageName)
            // reset overlay state immediately when exemption is added
            overlayResetCallback?.invoke()
            android.util.Log.d("AccessibilityService",
                "exempting: $packageName")

            // remove after 30 seconds
            android.os.Handler(android.os.Looper.getMainLooper())
                .postDelayed({
                    exemptedPackages.remove(packageName)
                    android.util.Log.d("AccessibilityService",
                        "exemption expired: $packageName - checking foreground")
                    // if the exempted app is still in foreground
                    // fire the callback again to trigger blocking
                    if (currentForegroundApp == packageName) {
                        android.util.Log.d(
                            "AccessibilityService",
                            "still in $packageName — re-triggering block"
                        )

                        // small delay before re-triggering
                        // gives BlockActivity time to fully clean up
                        android.os.Handler(android.os.Looper.getMainLooper())
                            .postDelayed({
                                eventCallback?.invoke(packageName)
                            }, 500) // 500 ms
                    }
                }, 30000)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return

            if (packageName.contains("systemui") ||
                packageName.contains("launcher") ||
                packageName == "android" ||
                packageName == "com.example.screenblock") return

            // always track current foreground app
            // even if exempted — so we know where user is
            currentForegroundApp = packageName


            // 👈 check exemption here in Kotlin — synchronous
            if (exemptedPackages.contains(packageName)) {
                android.util.Log.d("AccessibilityService",
                    "skipping exempted: $packageName")
                return
            }

            eventCallback?.invoke(packageName)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isRunning = true
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 100
        }
        serviceInfo = info
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        eventCallback = null
    }
}