package com.eagle.pausenow

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.accessibility.AccessibilityEvent
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

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
        var instance: AppBlockAccessibilityService? = null // 👈 new — needed to call the non-static checkTimeLimitForApp


        fun forceRecheckTimeLimit() {
            android.util.Log.d("pausenow", "🔍 forceRecheckTimeLimit — currentForegroundApp=$currentForegroundApp, instance=${instance != null}")
            val pkg = currentForegroundApp ?: return
            instance?.checkTimeLimitForApp(pkg)
        }

        fun addExemption(packageName: String) {
            exemptedPackages.add(packageName)
            overlayResetCallback?.invoke()
            isOverlayShowing = false
            lastBlockScreenLaunchTime = 0L
            android.util.Log.d("AccessibilityService", "exempting: $packageName")
            android.os.Handler(android.os.Looper.getMainLooper())
                .postDelayed({
                    exemptedPackages.remove(packageName)
                    android.util.Log.d("AccessibilityService",
                        "exemption expired for: $packageName currentForegroundApp=$currentForegroundApp")
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

        // AppBlockAccessibilityService.kt companion object, alongside addExemption
        fun clearExemption(packageName: String) {
            exemptedPackages.remove(packageName)
            android.util.Log.d("AccessibilityService", "cleared exemption for: $packageName")
        }
    }

    fun isSystemApp(packageName: String): Boolean {
        if (systemWhitelist.contains(packageName)) return true
        if (packageName.contains("launcher")) return true
        if (packageName.contains("systemui")) return true
        return try {
            val pm = applicationContext.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            (appInfo.flags.toLong() and android.content.pm.ApplicationInfo.FLAG_SYSTEM.toLong()) != 0L
        } catch (e: Exception) {
            false
        }
    }

    private lateinit var prefs: SharedPreferences
    private val pauseCheckHandler = android.os.Handler(android.os.Looper.getMainLooper())

    private val pauseCheckRunnable = object : Runnable {
        override fun run() {
            if (isPauseExpired()) {
                android.util.Log.d("pausenow", "⏰ Pause expired")
                eventCallback?.invoke("__scheduleResumed__")
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

    private val blockingPollRunnable = object : Runnable {
        override fun run() {
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

    private val timeLimitCheckRunnable = object : Runnable {
        override fun run() {
            val pkg = currentForegroundApp
            if (pkg != null && pkg != "com.eagle.pausenow" && !isOverlayShowing) {
                checkTimeLimitForApp(pkg)
            }
            pauseCheckHandler.postDelayed(this, 5000)
        }
    }

    // 👇 new — quick-block poll, independent of session/schedule/time-limit state
    private val quickBlockCheckRunnable = object : Runnable {
        override fun run() {
            val pkg = currentForegroundApp
            if (pkg != null && pkg != "com.eagle.pausenow" && !isOverlayShowing) {
                checkQuickBlockForApp(pkg)
            }
            pauseCheckHandler.postDelayed(this, 3000) // 👈 shorter interval — quick-block should feel snappy
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this // 👈 new
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

        pauseCheckHandler.postDelayed(pauseCheckRunnable, 5000)
        pauseCheckHandler.postDelayed(blockingPollRunnable, 5000)
        pauseCheckHandler.postDelayed(timeLimitCheckRunnable, 5000)
        pauseCheckHandler.postDelayed(quickBlockCheckRunnable, 3000) // 👈 new

        android.util.Log.d("AccessibilityService", "onServiceConnected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        android.util.Log.d("pausenow", "🎯 onAccessibilityEvent pkg=$packageName eventCallback=${eventCallback != null} isOverlayShowing=$isOverlayShowing")
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val packageName = event.packageName?.toString() ?: return

        if (packageName.contains("systemui") ||
            packageName == "android" ||
            packageName == "com.eagle.pausenow") return

        if (packageName.contains("launcher") ||
            packageName.contains("nexuslauncher") ||
            packageName.contains("pixel") ||
            packageName == "com.google.android.apps.nexuslauncher") {
            currentForegroundApp = null
            return
        }

        currentForegroundApp = packageName
        checkTimeLimitForApp(packageName)
        checkQuickBlockForApp(packageName) // 👈 new — checked on every foreground change too, not just the poll

        if (isPauseExpired()) {
            android.util.Log.d("pausenow", "⏰ Pause expired — notifying Flutter")
            eventCallback?.invoke("__scheduleResumed__")
        }

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

        if (eventCallback != null) {
            eventCallback?.invoke(packageName)
            return
        }

        android.util.Log.d("AccessibilityService",
            "Flutter not running — checking native prefs for: $packageName")
        checkAndBlockFromPrefs(packageName)
    }

    private fun checkAndBlockFromPrefs(packageName: String) {
        if (isSystemApp(packageName)) return
        val isBlocking = prefs.getBoolean("isBlocking", false)
        if (!isBlocking) return
        val blockingMode = prefs.getString("blockingMode", "specific_apps") ?: "specific_apps"
        val monitoredApps = prefs.getStringSet("monitoredApps", emptySet()) ?: emptySet()
        val shouldBlock = when (blockingMode) {
            "specific_apps" -> monitoredApps.contains(packageName)
            else -> !monitoredApps.contains(packageName) && !isSystemApp(packageName)
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
            val events = usageStatsManager.queryEvents(startTime, endTime)
            var totalMs = 0L
            var lastForegroundTime = 0L
            var inForeground = false
            val event = android.app.usage.UsageEvents.Event()
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.packageName != packageName) continue
                when (event.eventType) {
                    android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                        lastForegroundTime = event.timeStamp
                        inForeground = true
                    }
                    android.app.usage.UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                        if (inForeground) {
                            totalMs += (event.timeStamp - lastForegroundTime)
                            inForeground = false
                        }
                    }
                }
            }
            if (inForeground) {
                totalMs += (endTime - lastForegroundTime)
            }
            if (totalMs == 0L) return null
            (totalMs / 1000 / 60).toInt()
        } catch (e: Exception) {
            android.util.Log.e("pausenow", "❌ usage events error: $e")
            null
        }
    }

    private fun checkTimeLimitForApp(packageName: String) {
        android.util.Log.d("pausenow", "🔍 checkTimeLimitForApp called for $packageName")
        val configsJson = prefs.getString("timeLimitConfigs", null) ?: return
        val configs = parseTimeLimitConfigs(configsJson)
        val today = getDayOfWeekIndex()
        for (config in configs) {
            if (!config.packageNames.contains(packageName)) continue
            if (!config.days.contains(today)) continue
            if (!config.isActive) continue
            if (exemptedPackages.contains(packageName)) {
                android.util.Log.d("pausenow", "🔍 $packageName is still exempted — skipping")
                continue
            }
            val usedMinutes = getTodayUsageMinutes(packageName) ?: continue
            android.util.Log.d("pausenow", "🔍 $packageName usedMinutes=$usedMinutes limit=${config.limitMinutes}")
            if (usedMinutes >= config.limitMinutes) {
                val now = System.currentTimeMillis()
                if (now - lastBlockScreenLaunchTime < 4000) return
                lastBlockScreenLaunchTime = now
                isOverlayShowing = true
                val intent = Intent(this, BlockActivity::class.java).apply {
                    putExtra("blocked_package", packageName)
                    putExtra("block_reason", "time_limit")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
                }
                startActivity(intent)
                return
            }
        }
    }

    // 👇 new — quick-block check, entirely separate from time-limit/session/schedule logic
    private fun checkQuickBlockForApp(packageName: String) {
        val quickBlocked = prefs.getStringSet("quickBlockedApps", emptySet()) ?: emptySet()
        if (!quickBlocked.contains(packageName)) return
        if (exemptedPackages.contains(packageName)) return

        val now = System.currentTimeMillis()
        if (now - lastBlockScreenLaunchTime < 4000) return
        lastBlockScreenLaunchTime = now
        isOverlayShowing = true

        android.util.Log.d("pausenow", "🚫 quick-blocking: $packageName")
        val intent = Intent(this, BlockActivity::class.java).apply {
            putExtra("blocked_package", packageName)
            putExtra("block_reason", "quick_block")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
        }
        startActivity(intent)
    }

    private fun getDayOfWeekIndex(): Int {
        val calendar = java.util.Calendar.getInstance()
        val javaDay = calendar.get(java.util.Calendar.DAY_OF_WEEK)
        return if (javaDay == java.util.Calendar.SUNDAY) 6 else javaDay - 2
    }

    private data class TimeLimitConfigNative(
        val packageNames: List<String>,
        val limitMinutes: Int,
        val days: List<Int>,
        val isActive: Boolean
    )

    private fun parseTimeLimitConfigs(json: String): List<TimeLimitConfigNative> {
        return try {
            val type = object : TypeToken<List<TimeLimitConfigNative>>() {}.type
            Gson().fromJson(json, type)
        } catch (e: Exception) {
            android.util.Log.e("pausenow", "❌ parseTimeLimitConfigs error: $e")
            emptyList()
        }
    }

    private fun isPauseExpired(): Boolean {
        val prefs = getSharedPreferences("pausenow_native", Context.MODE_PRIVATE)
        val pauseEndTime = prefs.getLong("schedulePauseEndTime", 0L)
        if (pauseEndTime == 0L) return false
        val now = System.currentTimeMillis()
        if (now >= pauseEndTime) {
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
        instance = null // 👈 new

        isRunning = false
        eventCallback = null
        pauseCheckHandler.removeCallbacks(pauseCheckRunnable)
        pauseCheckHandler.removeCallbacks(blockingPollRunnable)
        pauseCheckHandler.removeCallbacks(timeLimitCheckRunnable)
        pauseCheckHandler.removeCallbacks(quickBlockCheckRunnable) // 👈 new
    }
}