import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

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
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          const SizedBox(height: 20),
          _buildTitle(),
          const SizedBox(height: 8),
          _buildValue(),
          const SizedBox(height: 16),
          _buildSlider(),
          const SizedBox(height: 20),
          _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
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

  Widget _buildValue() {
    return Text(
      '$_selectedMinutes min break',
      style: AppTextStyles.headlineMedium.copyWith(
        color: AppColors.gold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSlider() {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: AppColors.gold,
        inactiveTrackColor: AppColors.backgroundSubtle,
        thumbColor: AppColors.gold,
        overlayColor: AppColors.gold.withOpacity(0.2),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 12,
        ),
        trackHeight: 4,
      ),
      child: Slider(
        value: _selectedMinutes.toDouble(),
        min: 1,
        max: 10,
        divisions: 9,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          setState(() => _selectedMinutes = value.round());
        },
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          widget.onStartBreak(_selectedMinutes);
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.pause_rounded,
          color: AppColors.goldText,
        ),
        label: Text('Start $_selectedMinutes min Break'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.goldText,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
    );
  }
}