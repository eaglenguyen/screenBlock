import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/platform/android_blocking_service.dart';
import '../../domain/platform/ios_blocking_service.dart';
import '../../features/lockapp/lock_app_viewmodel.dart';
import '../../features/lockapp/widget/lock_app_confirm_sheet.dart';
import '../../providers/blocking_service_provider.dart';
import '../home/checkIn/check_in_slider_screen.dart';
import '../home/home_viewmodel.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin { // 👈 added ticker mixin
  int _selectedIndex = 0;
  late AnimationController _wheelSpinController; // 👈 new

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wheelSpinController = AnimationController( // 👈 new — continuous spin
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wheelSpinController.dispose(); // 👈 new
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(homeViewModelProvider.notifier).onAppResumed();
      ref.read(blockingServiceProvider).resetOverlayState();
    }
  }

  int _getIndexFromLocation(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/schedule')) return 1;
    if (location.startsWith('/wheel')) return 2; // 👈 new — middle tab
    if (location.startsWith('/stats')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  final List<String> _routes = [
    '/home',
    '/schedule',
    '/wheel', // 👈 new
    '/stats',
    '/settings',
  ];

  void _onNavTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    GoRouter.of(context).go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    _selectedIndex = _getIndexFromLocation(
      GoRouterState.of(context).uri.toString(),
    );

    ref.listen(homeViewModelProvider.select((s) => s.pendingLockAppConfirm), (previous, next) {
      if (next != null) {
        LockAppConfirmSheet.show(
          context,
          configId: next.configId,
          packageName: next.packageName,
          appName: next.appName,
          onConfirm: () async {
            final service = ref.read(blockingServiceProvider);
            await ref.read(lockAppViewModelProvider.notifier).consumeUnlock(next.configId);
            if (service is AndroidBlockingService) {
              await service.pauseLockAppFor(configId: next.configId, packageName: next.packageName);
              await service.launchApp(next.packageName);
            } else if (service is IOSBlockingService) {
              await service.removeLockAppShield(next.configId);
              // no auto-open — URL scheme lookup deferred per your earlier decision
            }
          },
        );
        ref.read(homeViewModelProvider.notifier).clearPendingLockAppConfirm();
      }
    });

    ref.listen(homeViewModelProvider, (previous, next) {
      if (next.pendingCheckIn && !(previous?.pendingCheckIn ?? false)) {
        CheckInFlow.show(context, onComplete: () {
          ref.read(homeViewModelProvider.notifier).clearPendingCheckIn();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          widget.child,
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          height: 84, // 👈 taller to give the arched button room to poke above
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // ── the pill bar itself ──
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard(context),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.border(context), width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _navBtn(0, Icons.home_rounded),
                    _navBtn(1, Icons.calendar_today_rounded),
                    const SizedBox(width: 58), // 👈 gap reserved for the arched wheel button
                    _navBtn(3, Icons.bar_chart_rounded),
                    _navBtn(4, Icons.settings_rounded),
                  ],
                ),
              ),
              // ── the arched, elevated wheel button ──
              Positioned(
                top: -14, // 👈 pokes above the bar
                child: GestureDetector(
                  onTap: () => _onNavTapped(2),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.background(context), // matches page bg, creates the "cutout" ring look
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedIndex == 2
                            ? AppColors.accent(context)
                            : AppColors.backgroundSubtle(context),
                        shape: BoxShape.circle,
                        boxShadow: _selectedIndex == 2
                            ? [
                          BoxShadow(
                            color: AppColors.accent(context).withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ]
                            : null,
                      ),
                      child: Center(
                        child: RotationTransition( // 👈 constantly spinning
                          turns: _wheelSpinController,
                          child: Icon(
                            Icons.donut_large_rounded, // wheel-like icon — swap for a custom asset if you have one
                            size: 30,
                            color: _selectedIndex == 2
                                ? AppColors.accentText(context)
                                : AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _navBtn(int index, IconData icon) {
    final isActive = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _onNavTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent(context) : AppColors.backgroundSubtle(context),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 28,
            color: isActive ? AppColors.accentText(context) : AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }
}