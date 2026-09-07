import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../schedule/widgets/hold_to_confirm.dart';
import '../home_viewmodel.dart';

class BreakSheet extends StatefulWidget {
  const BreakSheet({
    super.key,
    required this.onStartBreak,
  });

  final ValueChanged<int> onStartBreak;

  @override
  State<BreakSheet> createState() => _BreakSheetState();
}

class _BreakSheetState extends State<BreakSheet> {
  int _selectedMinutes = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(context),
          const SizedBox(height: 20),
          _buildTitle(),
          const SizedBox(height: 8),
          _buildValue(context),
          const SizedBox(height: 16),
          _buildSlider(context),
          const SizedBox(height: 20),
          _buildStartButton(context),
        ],
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border(context),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'How long?',
      style: AppTextStyles.headlineSmall,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildValue(BuildContext context) {
    return Text(
      '$_selectedMinutes min break',
      style: AppTextStyles.headlineMedium.copyWith(
        color: AppColors.warning(context),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSlider(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: AppColors.warning(context),
        inactiveTrackColor: AppColors.backgroundSubtle(context),
        thumbColor: AppColors.warning(context),
        overlayColor: AppColors.warning(context).withValues(alpha: 0.2),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 12,
        ),
        trackHeight: 4,
      ),
      child: Slider(
        value: _selectedMinutes.toDouble(),
        min: 3,
        max: 30,
        divisions: 27,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          setState(() => _selectedMinutes = value.round());
        },
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: HoldToConfirmButton(
        color: AppColors.warning(context),
        fillColor: AppColors.warningDark(context),
        textColor: AppColors.warningLight(context),
        onConfirmed: () {
          widget.onStartBreak(_selectedMinutes);
          Navigator.pop(context);
        },
      ),
    );
  }


}