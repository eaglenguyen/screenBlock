// lib/features/quickblock/widgets/quick_block_unblock_dialog.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class QuickBlockUnblockDialog {
  static Future<bool> show(BuildContext context, {required String appName}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UnblockChoiceDialog(appName: appName),
    );
    return result ?? false;
  }
}

class _UnblockChoiceDialog extends StatefulWidget {
  final String appName;
  const _UnblockChoiceDialog({required this.appName});

  @override
  State<_UnblockChoiceDialog> createState() => _UnblockChoiceDialogState();
}

class _UnblockChoiceDialogState extends State<_UnblockChoiceDialog> {
  int _secondsLeft = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canUnblock = _secondsLeft == 0;

    return Dialog(
      backgroundColor: AppColors.backgroundCard(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Feeling the urge?',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Before you unblock ${widget.appName}, try something else instead.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
        Row( // 👈 new — was two separate SizedBox(width: double.infinity, ...) stacked with a SizedBox(height: 10) between
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact(); // 👈 new
                  Navigator.pop(context, false);
                  GoRouter.of(context).go('/wheel');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent(context),
                  foregroundColor: AppColors.accentText(context),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Spin',
                        style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800,color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: canUnblock
                    ? () {
                  HapticFeedback.mediumImpact(); // 👈 new — slightly stronger since this is the more consequential action
                  Navigator.pop(context, true);
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canUnblock
                      ? AppColors.error(context)
                      : AppColors.error(context).withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.error(context).withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(
                  canUnblock ? 'Unblock' : 'Unblock in ${_secondsLeft}s',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: canUnblock ? Colors.white : Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ]
        ),
    ),
    );
  }
}