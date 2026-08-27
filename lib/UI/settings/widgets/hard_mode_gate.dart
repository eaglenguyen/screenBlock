import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HardModeMathGate {
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const _HardModeMathSheet(),
    );
    return result ?? false;
  }
}

class _HardModeMathSheet extends StatefulWidget {
  const _HardModeMathSheet();

  @override
  State<_HardModeMathSheet> createState() => _HardModeMathSheetState();
}

class _HardModeMathSheetState extends State<_HardModeMathSheet> {
  late int _a;
  late int _b;
  late String _op;
  late int _answer;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateProblem();
  }

  void _generateProblem() {
    final rand = Random();
    final ops = ['+', '-', '×'];
    _op = ops[rand.nextInt(ops.length)];
    switch (_op) {
      case '+':
        _a = rand.nextInt(80) + 10;
        _b = rand.nextInt(80) + 10;
        _answer = _a + _b;
      case '-':
        _a = rand.nextInt(80) + 20;
        _b = rand.nextInt(_a - 5) + 5; // ensures a positive result
        _answer = _a - _b;
      case '×':
        _a = rand.nextInt(11) + 2;
        _b = rand.nextInt(11) + 2;
        _answer = _a * _b;
    }
  }

  void _submit() {
    final entered = int.tryParse(_controller.text.trim());
    if (entered == _answer) {
      Navigator.pop(context, true);
    } else {
      Navigator.pop(context, false); // 👈 wrong answer — dismiss, no retry inline
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Solve to turn off Hard Mode',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'A wrong answer cancels — you\'ll need to try again.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            '$_a $_op $_b = ?',
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.textPrimary(context),
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary(context)),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.backgroundSubtle(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              hintText: 'Your answer',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold(context),
              foregroundColor: AppColors.goldText(context),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const StadiumBorder(),
              textStyle: AppTextStyles.labelLarge,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}