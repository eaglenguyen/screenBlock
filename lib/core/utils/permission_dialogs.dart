import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/blocking_service_provider.dart';
import '../theme/app_colors.dart';


Future<void> checkAccessibilityAndProceed(
    BuildContext context,
    WidgetRef ref,
    VoidCallback onGranted,
    ) async {
  if (!Platform.isAndroid) {
    onGranted();
    return;
  }

  final service = ref.read(blockingServiceProvider);
  final hasAccessibility = await service.hasAccessibilityPermission();

  if (!context.mounted) return;

  if (hasAccessibility) {
    onGranted();
    return;
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.backgroundCard(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.accessibility_new_rounded,
              color: AppColors.accent(context),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Accessibility Required',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accessibility permission only needs to be enabled once to block apps.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await service.requestAccessibilityPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent(context),
              foregroundColor: AppColors.accentText(context),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Not Now', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14)),
          ),
        ),
      ],
    ),
  );
}