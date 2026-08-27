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
  static const int _maxAttempts = 3; // 👈 new — was hardcoded as 2

  late int _a;
  late int _b;
  late String _op;
  late int _answer;
  final _controller = TextEditingController();
  int _attempts = 0;
  bool _showError = false;

  int get _attemptsRemaining => _maxAttempts - _attempts; // 👈 new

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
        _a = rand.nextInt(20) + 1;
        _b = rand.nextInt(20) + 1;
        _answer = _a + _b;
      case '-':
        _a = rand.nextInt(20) + 1;
        _b = rand.nextInt(_a) + 1;
        _answer = _a - _b;
      case '×':
        _a = rand.nextInt(20) + 1;
        _b = rand.nextInt(20) + 1;
        _answer = _a * _b;
    }
  }

  void _submit() {
    final entered = int.tryParse(_controller.text.trim());
    if (entered == _answer) {
      Navigator.pop(context, true);
      return;
    }

    _attempts++;
    if (_attempts >= _maxAttempts) {
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      _showError = true;
      _controller.clear();
      _generateProblem();
    });
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
            'Turn off Hard Mode',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Attempts remaining: $_attemptsRemaining',
            style: AppTextStyles.bodyLarge.copyWith( // 👈 was bodySmall
              fontSize: 18, // 👈 new — explicit bump
              color: _attemptsRemaining == 1
                  ? AppColors.error(context)
                  : AppColors.textSecondary(context),
              fontWeight: _attemptsRemaining == 1 ? FontWeight.w700 : FontWeight.w500,
            ),
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
              fillColor: _showError
                  ? AppColors.error(context).withValues(alpha: 0.1)
                  : AppColors.backgroundSubtle(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: _showError
                    ? BorderSide(color: AppColors.error(context), width: 1.5)
                    : BorderSide.none,
              ),
            ),
            onChanged: (_) {
              if (_showError) setState(() => _showError = false);
            },
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
              textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 20), // 👈 new
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}