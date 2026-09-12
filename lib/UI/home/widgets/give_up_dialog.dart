import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class GiveUpDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  const GiveUpDialog({required this.onConfirm});

  @override
  State<GiveUpDialog> createState() => _GiveUpDialogState();
}

class _GiveUpDialogState extends State<GiveUpDialog> {
  int _secondsLeft = 5;
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
    final canConfirm = _secondsLeft == 0;

    return AlertDialog(
      backgroundColor: AppColors.backgroundCard(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Give up?',
        style: AppTextStyles.headlineSmall,
        textAlign: TextAlign.center,
      ),
      content: Text(
        'If you give up, no ⭐️\'s',
        style: AppTextStyles.bodyMedium,
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canConfirm ? widget.onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canConfirm
                  ? AppColors.error(context)
                  : AppColors.error(context).withValues(alpha: 0.35), // 👈 faded while counting down
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.error(context).withValues(alpha: 0.35),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: Text(
              canConfirm ? 'Yes, give up' : 'Yes, give up in ${_secondsLeft}s',
              style: TextStyle(color: canConfirm ? Colors.white : Colors.white.withValues(alpha: 0.7)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary(context),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
              side: BorderSide(color: AppColors.border(context)),
            ),
            child: const Text("Don't give up"),
          ),
        ),
      ],
    );
  }
}