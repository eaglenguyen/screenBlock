// lib/onboarding_new/screens/screen_time_permission_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/blocking_service_provider.dart'; // adjust path to match your actual location
import '../widget/continue_button.dart';
import '../widget/progress_bar.dart';
import '../widget/typewriter_title.dart';

class OnboardingScreenTimePermissionScreen extends ConsumerStatefulWidget {
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const OnboardingScreenTimePermissionScreen({
    super.key,
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onContinue,
  });

  @override
  ConsumerState<OnboardingScreenTimePermissionScreen> createState() => _OnboardingScreenTimePermissionScreenState();
}

class _OnboardingScreenTimePermissionScreenState extends ConsumerState<OnboardingScreenTimePermissionScreen>
    with WidgetsBindingObserver {
  bool _hasScreenTime = false;
  bool _hasNotifications = false;
  bool _hasAccessibility = false;
  bool _hasOverlay = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    final service = ref.read(blockingServiceProvider);

    if (Platform.isIOS) {
      final hasScreenTime = await service.hasAccessibilityPermission();
      final hasNotif = await _checkNotificationPermission();
      if (mounted) {
        setState(() {
          _hasScreenTime = hasScreenTime;
          _hasNotifications = hasNotif;
        });
      }
    } else {
      final hasAccessibility = await service.hasAccessibilityPermission();
      final hasOverlay = await service.hasOverlayPermission();
      final hasUsageStats = await service.hasUsageStatsPermission();
      if (mounted) {
        setState(() {
          _hasAccessibility = hasAccessibility;
          _hasOverlay = hasOverlay;
        });
      }
    }
  }

  Future<bool> _checkNotificationPermission() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final iosPlugin = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final result = await iosPlugin?.checkPermissions();
      return result?.isEnabled ?? false;
    } catch (_) {
      return false;
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
        widget.onContinue();
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
    ];
  }

  Widget _header() {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onBack,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF0E6D8), width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A3728), size: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: OnboardingProgressBar(step: widget.progressStep, total: widget.progressTotal)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Platform.isIOS ? _buildIOSFlow(context) : _buildAndroidFlow(context),
        ),
      ),
    );
  }

  // ── iOS flow ──────────────────────────────
  Widget _buildIOSFlow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const SizedBox(height: 32),
        Text(
          'Connect to Screen Time so we can help you scroll less!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: const Color(0xFF4A3728),
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/screentimeios.webp', // 👈 adjust to your actual filename
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ],
        ),
        const SizedBox(height: 32),
        GestureDetector( // 👈 was Container — now the whole mockup is one tappable image
          onTap: _isRequesting ? null : _requestScreenTimePermission,
          child: Opacity(
            opacity: _isRequesting ? 0.6 : 1.0,
            child: Image.asset(
              'assets/images/permission.png', // 👈 your actual screenshot/mockup PNG
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 6),

          ],
        ),
        const Spacer(),
        Column(
          children: [
            Icon(Icons.verified_user_rounded, color: const Color(0xFFB08A5A), size: 20),
            const SizedBox(height: 6),
            Text(
              'Secured by Apple',
              style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              'Data stays private & never leaves your phone',
              style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (kDebugMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(
              child: GestureDetector(
                onTap: widget.onContinue,
                child: Text(
                  'Skip (Debug)',
                  style: GoogleFonts.poppins(color: Colors.redAccent.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _iconBadge({required String emoji, required Color color}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
    );
  }

  // ── Android flow ──────────────────────────
  Widget _buildAndroidFlow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const SizedBox(height: 32),
        const TypewriterTitle(text: 'Before we start...'),
        const SizedBox(height: 8),
        Text(
          'We need a few permissions\nto block apps effectively.',
          style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: _permissions.map((perm) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PermissionCard(item: perm, onRefresh: _checkAllPermissions),
                );
              }).toList(),
            ),
          ),
        ),
        if (!_canContinue)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Grant required permissions to continue',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 13),
            ),
          ),
        OnboardingContinueButton(
          label: 'Continue',
          enabled: _canContinue,
          onTap: widget.onContinue,
        ),
      ],
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

// ── Permission card widget — pastel-styled ────────────

class _PermissionCard extends StatefulWidget {
  final _PermissionItem item;
  final VoidCallback onRefresh;

  const _PermissionCard({required this.item, required this.onRefresh});

  @override
  State<_PermissionCard> createState() => _PermissionCardState();
}

class _PermissionCardState extends State<_PermissionCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final accentColor = item.isGranted
        ? const Color(0xFF2D7A54)
        : item.isRequired
        ? const Color(0xFFE8703A)
        : const Color(0xFFB08A5A);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isGranted
              ? const Color(0xFF7DD3B0).withValues(alpha: 0.4)
              : item.isRequired
              ? const Color(0xFFE8703A).withValues(alpha: 0.3)
              : const Color(0xFFF0E6D8),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 22))),
              ),
              if (item.isGranted)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(color: Color(0xFF2D7A54), shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.title,
                        style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 15, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isRequired) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8703A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Required',
                          style: GoogleFonts.poppins(color: const Color(0xFFE8703A), fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (!item.isGranted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: widget.onRefresh,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF0E6D8), width: 1),
                    ),
                    child: const Icon(Icons.refresh_rounded, color: Color(0xFFB08A5A), size: 16),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7DD3B0),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(color: Color(0xFF0F4A32), strokeWidth: 2),
                    )
                        : Text(
                      'Allow',
                      style: GoogleFonts.poppins(color: const Color(0xFF0F4A32), fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              '✓ Granted',
              style: GoogleFonts.poppins(color: const Color(0xFF2D7A54), fontSize: 13, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

/// Shows the disclosure dialog for Google Play review — pastel-styled.
class AccessibilityDisclosureDialog {
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFF0E6D8), width: 1),
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
                      color: const Color(0xFFE8703A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('🛡️', style: TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Accessibility Access',
                      style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'SpinBrek needs Accessibility access to block distracting apps',
                style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 15, fontWeight: FontWeight.w700, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(
                "To block the apps you choose, SpinBrek uses Android's Accessibility Service to detect which app is currently open on your screen. When you've started a focus session and open a blocked app, SpinBrek shows the block screen to help you stay on track.",
                style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                'This is used only to power app blocking — SpinBrek does not read the content of your screen, and no data about which apps you use is ever collected, stored, or shared.',
                style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                "You'll be taken to your device's Accessibility settings to turn this on for SpinBrek.",
                style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 12, fontStyle: FontStyle.italic, height: 1.4),
              ),
              const SizedBox(height: 24),
              OnboardingContinueButton(
                label: 'Continue',
                onTap: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFB08A5A), padding: const EdgeInsets.symmetric(vertical: 12)),
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