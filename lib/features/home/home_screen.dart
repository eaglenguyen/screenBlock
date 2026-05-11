import 'package:flutter/material.dart';
import 'package:screenblock/features/home/widgets/app_intentions.dart';
import 'package:screenblock/features/home/widgets/focus_stats.dart';
import 'package:screenblock/features/home/widgets/home_header.dart';
import 'package:screenblock/features/home/widgets/timer_card.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/blocking_service_provider.dart';
import 'home_viewmodel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  @override
  void initState() {
    super.initState();
    // trigger load after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      // no Stack needed anymore — shell handles the nav
      body: Column(
        children: [
          HomeHeader(state: state),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
              child: Column(
                children: [
                  TimerCard(
                    onBlockNow: _onBlockNowTapped,
                    onSelectorTapped: _onSelectorTapped,
                  ),
                  const SizedBox(height: 12),
                  AppIntentionsCard(
                    trackedApps: state.trackedApps,
                    onAddApp: _onAddAppTapped,
                    onRefresh: _onRefreshTapped,
                  ),
                  const SizedBox(height: 12),
                  FocusStatsCard(state: state),
                ],
              ),
            ),
          ),
          // temporary test button — remove after testing
          ElevatedButton(
            onPressed: () async {
              debugPrint('🔵 test button tapped');

              // init streams first
              ref.read(homeViewModelProvider.notifier).init();

              const testPackage = 'com.instagram.android';
              final service = ref.read(blockingServiceProvider);

              final hasUsage = await service.hasUsageStatsPermission();
              final hasOverlay = await service.hasOverlayPermission();

              debugPrint('🔵 hasUsage: $hasUsage hasOverlay: $hasOverlay');

              if (!hasUsage) {
                await service.requestUsageStatsPermission();
                return;
              }

              if (!hasOverlay) {
                await service.requestOverlayPermission();
                return;
              }

              await service.startMonitoring(testPackage, 1);
              debugPrint('🔵 monitoring started for $testPackage');

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Monitoring started — open Instagram'),
                ),
              );
            },
            child: const Text('Test Block'),
          ),
        ],

      ),

    );

  }

  // Empty Callbacks
  void _onBlockNowTapped() {}
  void _onSelectorTapped(String type) {}
  void _onAddAppTapped() {
    // will navigate to app picker
    // context.push('/app-picker');
  }
  void _onRefreshTapped() {
    ref.read(homeViewModelProvider.notifier).loadTrackedApps();
  }
}