import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/blocking_service_provider.dart';
import 'onboarding_animations.dart';


class OnboardingPermissionsScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const OnboardingPermissionsScreen({
    super.key,
    required this.onNext,
  });

  @override
  ConsumerState<OnboardingPermissionsScreen> createState() =>
      _OnboardingPermissionsScreenState();
}

class _OnboardingPermissionsScreenState
    extends ConsumerState<OnboardingPermissionsScreen>
    with SingleTickerProviderStateMixin, OnboardingEntranceMixin, WidgetsBindingObserver {
  bool _hasScreenTime = false;
  bool _hasNotifications = false;
  bool _hasAccessibility = false;
  bool _hasOverlay = false;
  bool _hasUsageStats = false;
  bool _isCheckingPermissions = false;
  bool _isRequesting = false; // 👈 new — iOS flow loading state

  @override
  void initState() {
    super.initState();
    initEntrance(elementCount: 3);
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeEntrance();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    setState(() => _isCheckingPermissions = true);
    final service = ref.read(blockingServiceProvider);

    if (Platform.isIOS) {
      final hasScreenTime = await service.hasAccessibilityPermission();
      final hasNotif = await _checkNotificationPermission();
      setState(() {
        _hasScreenTime = hasScreenTime;
        _hasNotifications = hasNotif;
      });
    } else {
      final hasAccessibility = await service.hasAccessibilityPermission();
      final hasOverlay = await service.hasOverlayPermission();
      final hasUsageStats = await service.hasUsageStatsPermission();
      setState(() {
        _hasAccessibility = hasAccessibility;
        _hasOverlay = hasOverlay;
        _hasUsageStats = hasUsageStats;
      });
    }
    setState(() => _isCheckingPermissions = false);
  }

  Future<bool> _checkNotificationPermission() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final iosPlugin = plugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final result = await iosPlugin?.checkPermissions();
      return result?.isEnabled ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final iosPlugin = plugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
          alert: true, badge: true, sound: true);
      await Future.delayed(const Duration(seconds: 1));
      final granted = await _checkNotificationPermission();
      setState(() => _hasNotifications = granted);
    } catch (e) {
      debugPrint('❌ notification permission error: $e');
    }
  }

  Future<void> _requestScreenTimePermission() async {
    setState(() => _isRequesting = true);
    HapticFeedback.lightImpact();
    final service = ref.read(blockingServiceProvider);
    await service.requestAccessibilityPermission();
    await Future.delayed(const Duration(seconds: 1));
    final granted = await service.hasAccessibilityPermission();
    if (mounted) {
      setState(() {
        _hasScreenTime = granted;
        _isRequesting = false;
      });
      if (granted) {
        widget.onNext(); // 👈 new — advance once permission is confirmed
      }
    }
  }

  bool get _canContinue {
    if (Platform.isIOS) {
      return _hasScreenTime;
    } else {
      return _hasAccessibility && _hasOverlay;
    }
  }

  List<_PermissionItem> get _permissions {
    // ... UNCHANGED, Android list stays exactly as before
    return [
      _PermissionItem(
        emoji: '♿',
        title: 'Accessibility',
        description: 'Required to detect and block apps in the foreground',
        isGranted: _hasAccessibility,
        isRequired: true,
        onRequest: () async {
          final consented = await AccessibilityDisclosureDialog.show(context);
          if (!consented) return;
          final service = ref.read(blockingServiceProvider);
          await service.requestAccessibilityPermission();
          await Future.delayed(const Duration(seconds: 2));
          final granted = await service.hasAccessibilityPermission();
          setState(() => _hasAccessibility = granted);
        },
      ),
      _PermissionItem(
        emoji: '🔍',
        title: 'Display Over Apps',
        description: 'Required to show the block screen over other apps',
        isGranted: _hasOverlay,
        isRequired: true,
        onRequest: () async {
          final service = ref.read(blockingServiceProvider);
          await service.requestOverlayPermission();
        },
      ),
      _PermissionItem(
        emoji: '📊',
        title: 'Usage Access',
        description: 'Shows your screen time stats on the block screen',
        isGranted: _hasUsageStats,
        isRequired: false,
        onRequest: () async {
          final service = ref.read(blockingServiceProvider);
          await service.requestUsageStatsPermission();
          await Future.delayed(const Duration(seconds: 2));
          final granted = await service.hasUsageStatsPermission();
          setState(() => _hasUsageStats = granted);
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: Stack(
        children: [
          _buildGradientBg(),
          _buildCircles(),
          SafeArea(
            child: Platform.isIOS ? _buildIOSFlow(context) : _buildAndroidFlow(
                context),
          ),
        ],
      ),
    );
  }

  // ── ANDROID — unchanged from before ──────────────

  Widget _buildAndroidFlow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          staggered(
            0,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Before we start...',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We needs a few permissions\nto block apps effectively.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          staggered(
            1,
            Column(
              children: _permissions.map((perm) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PermissionCard(
                      item: perm, onRefresh: _checkAllPermissions),
                );
              }).toList(),
            ),
          ),
          const Spacer(),
          staggered(
            2,
            Column(
              children: [
                if (!_canContinue)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Grant required permissions to continue',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 13,
                      ),
                    ),
                  ),
                AnimatedOpacity(
                  opacity: _canContinue ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 300),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canContinue ? widget.onNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEDB82A),
                        foregroundColor: const Color(0xFF1A1208),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: const StadiumBorder(),
                        disabledBackgroundColor: const Color(0xFFEDB82A)
                            .withValues(alpha: 0.4),
                        textStyle: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      child: const Text('Continue →'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ── iOS — new redesigned flow ──────────────────


  Widget _buildIOSFlow(BuildContext context) {
    const headline = 'Connect to Screen Time\nso I can help you scroll less!';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── mascot + speech bubble ──────────────
          staggered(
            0,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/icons/mascot_face.png',
                  width: 64,
                  height: 64,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      headline,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1A1A1A),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // ── fake preview card ────────────────────
          staggered(
            1,
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"pause now" Would Like to\nAccess Screen Time',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1A1A1A).withValues(alpha: 0.55),
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Providing "Pause Now" access to Screen Time may allow it to see your activity data, restrict content, and limit the usage of apps and websites.',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1A1A1A).withValues(alpha: 0.55),
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _isRequesting ? null : _requestScreenTimePermission,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E5),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: _isRequesting
                                ? const SizedBox(
                              height: 20,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Color(0xFF1A1A1A), strokeWidth: 2),
                                ),
                              ),
                            )
                                : Text(
                              'Continue',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1A1A1A),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E5),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            'Don\'t Allow',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1A1A1A),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── tap hint ──────────────────────────────
          staggered(
            1,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_upward_rounded, color: Colors.white.withValues(alpha: 0.4), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Tap Continue',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
// ── Permission item data ──────────────────────────────

class _PermissionItem {
  final String emoji;
  final String title;
  final String description;
  final bool isGranted;
  final bool isRequired;
  final Future<void> Function() onRequest;

  const _PermissionItem({
    required this.emoji,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.isRequired,
    required this.onRequest,
  });
}

// ── Permission card widget ────────────────────────────

class _PermissionCard extends StatefulWidget {
  final _PermissionItem item;
  final VoidCallback onRefresh;

  const _PermissionCard({
    required this.item,
    required this.onRefresh,
  });

  @override
  State<_PermissionCard> createState() => _PermissionCardState();
}

class _PermissionCardState extends State<_PermissionCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = item.isGranted
        ? const Color(0xFF4CAF50)
        : item.isRequired
        ? const Color(0xFFEDB82A)
        : Colors.white.withValues(alpha: 0.3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isGranted
              ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
              : item.isRequired
              ? const Color(0xFFEDB82A).withValues(alpha: 0.2)
              : const Color(0xFF2A2A48),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // emoji + status indicator
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    item.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              if (item.isGranted)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👇 wrap Row in Flexible to prevent overflow
                Row(
                  children: [
                    Flexible( // 👈 add this
                      child: Text(
                        item.title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis, // 👈 add this
                      ),
                    ),
                    if (item.isRequired) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDB82A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Required',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFEDB82A),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // action button
          if (!item.isGranted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 👇 refresh button always visible when not granted
                GestureDetector(
                  onTap: () {
                    widget.onRefresh();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () async {
                    HapticFeedback.lightImpact();
                    setState(() => _isLoading = true);
                    await item.onRequest();
                    if (mounted) setState(() => _isLoading = false);
                    widget.onRefresh();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDB82A),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A1208),
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      'Allow',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1A1208),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              '✓ Granted',
              style: GoogleFonts.poppins(
                color: const Color(0xFF4CAF50),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared helpers (copied from welcome flow) ─────────

Widget _buildGradientBg() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2A2015),
          Color(0xFF1A1A1A),
          Color(0xFF111111),
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    ),
  );
}

Widget _buildCircles() {
  return Stack(
    children: [
      Positioned(
        top: -40,
        right: -40,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEDB82A).withValues(alpha: 0.05),
            border: Border.all(
              color: const Color(0xFFEDB82A).withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        left: -30,
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4444AA).withValues(alpha: 0.05),
            border: Border.all(
              color: const Color(0xFF4444AA).withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
        ),
      ),
    ],
  );
}

/// Shows the disclosure dialog for google review. Returns true if the user tapped Continue,
/// false if they dismissed/cancelled.

class AccessibilityDisclosureDialog {
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E1E35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: const Color(0xFFEDB82A).withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDB82A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🛡️', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Accessibility Access',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Pause Now needs Accessibility access to block distracting apps',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'To block the apps you choose, Pause Now uses Android\'s Accessibility Service to detect which app is currently open on your screen. When you\'ve started a focus session and open a blocked app, Pause Now shows the block screen to help you stay on track.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This is used only to power app blocking — Pause Now does not read the content of your screen, and no data about which apps you use is ever collected, stored, or shared.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You\'ll be taken to your device\'s Accessibility settings to turn this on for Pause Now.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEDB82A),
                    foregroundColor: const Color(0xFF1A1208),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Not now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return result ?? false;
  }
}