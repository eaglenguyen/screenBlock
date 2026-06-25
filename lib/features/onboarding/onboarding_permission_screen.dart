import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pausenow/features/onboarding/widgets/onboarding_animations.dart';

import '../../../providers/blocking_service_provider.dart';

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
    with SingleTickerProviderStateMixin, OnboardingEntranceMixin, WidgetsBindingObserver  {

  // permission states
  bool _hasScreenTime = false;
  bool _hasNotifications = false;
  bool _hasAccessibility = false;
  bool _hasOverlay = false;
  bool _hasUsageStats = false;

  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
    initEntrance(elementCount: 3);
    WidgetsBinding.instance.addObserver(this); // 👈 add
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 👈 add
    disposeEntrance();
    super.dispose();
  }

  // 👇 add this method
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
      const channel = MethodChannel('com.eagle.pausenow/ios_blocking');
      final result = await channel.invokeMethod<bool>('checkNotificationPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      const channel = MethodChannel('com.eagle.pausenow/ios_blocking');
      await channel.invokeMethod('requestNotificationPermission');
      await Future.delayed(const Duration(seconds: 1));
      final granted = await _checkNotificationPermission();
      setState(() => _hasNotifications = granted);
    } catch (e) {
      debugPrint('❌ notification permission error: $e');
    }
  }

  bool get _canContinue {
    if (Platform.isIOS) {
      return _hasScreenTime; // notifications optional but encouraged
    } else {
      return _hasAccessibility && _hasOverlay;
    }
  }

  List<_PermissionItem> get _permissions {
    if (Platform.isIOS) {
      return [
        _PermissionItem(
          emoji: '⏱️',
          title: 'Screen Time',
          description: 'Required to block distracting apps at the system level',
          isGranted: _hasScreenTime,
          isRequired: true,
          onRequest: () async {
            final service = ref.read(blockingServiceProvider);
            await service.requestAccessibilityPermission();
            await Future.delayed(const Duration(seconds: 1));
            final granted = await service.hasAccessibilityPermission();
            setState(() => _hasScreenTime = granted);
          },
        ),
        _PermissionItem(
          emoji: '🔔',
          title: 'Notifications',
          description: 'Get notified when your break ends or schedule resumes',
          isGranted: _hasNotifications,
          isRequired: false,
          onRequest: _requestNotificationPermission,
        ),
      ];
    } else {
      return [
        _PermissionItem(
          emoji: '♿',
          title: 'Accessibility',
          description: 'Required to detect and block apps in the foreground',
          isGranted: _hasAccessibility,
          isRequired: true,
          onRequest: () async {
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // header
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

                  // permission items
                  staggered(
                    1,
                    Column(
                      children: _permissions.map((perm) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PermissionCard(
                            item: perm,
                            onRefresh: _checkAllPermissions,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const Spacer(),

                  // continue button
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
                                disabledBackgroundColor:
                                const Color(0xFFEDB82A).withValues(alpha: 0.4),
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
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
            ),
          ),
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