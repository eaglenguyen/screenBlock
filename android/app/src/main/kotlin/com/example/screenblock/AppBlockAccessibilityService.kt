package com.example.screenblock

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class AppBlockAccessibilityService : AccessibilityService() {

    companion object {
        // static channel to send events to Flutter
        var eventCallback: ((String) -> Unit)? = null
        var isRunning = false
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

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return

            if (packageName.contains("systemui") ||
                packageName.contains("launcher") ||
                packageName == "android" ||
                packageName == "com.example.screenblock") return

            // send to Flutter via callback
            eventCallback?.invoke(packageName)
        }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        eventCallback = null
    }
}