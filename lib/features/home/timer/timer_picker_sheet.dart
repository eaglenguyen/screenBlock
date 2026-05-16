import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TimerPickerSheet extends StatefulWidget {
  const TimerPickerSheet({
    super.key,
    required this.selectedMinutes,
    required this.onSave,
  });

  final int selectedMinutes;
  final ValueChanged<int> onSave;

  @override
  State<TimerPickerSheet> createState() => _TimerPickerSheetState();
}

class _TimerPickerSheetState extends State<TimerPickerSheet> {

  late int _selected;

  final List<int> _presets = [5, 10, 15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
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
          const SizedBox(height: 24),
          _buildPresets(),
          const SizedBox(height: 28),
          _buildSaveButton(),
        ],
      ),
    );
  }

  // ── Handle ───────────────────────────────────────
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

  // ── Title ────────────────────────────────────────
  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Set Timer',
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Block Now will run for this duration',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  // ── Preset grid ──────────────────────────────────
  Widget _buildPresets() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.0,
      ),
      itemCount: _presets.length,
      itemBuilder: (context, index) {
        final minutes = _presets[index];
        final isSelected = minutes == _selected;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selected = minutes);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.gold
                  : AppColors.backgroundSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.gold
                    : AppColors.border,
                width: isSelected ? 0 : 0.5,
              ),
            ),
            child: Center(
              child: Text(
                _formatLabel(minutes),
                style: AppTextStyles.headlineSmall.copyWith(
                  fontSize: 16,
                  color: isSelected
                      ? AppColors.goldText
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatLabel(int minutes) {
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h';
  }

  // ── Save button ──────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          widget.onSave(_selected);
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.goldText,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.labelLarge,
        ),
        child: Text(
          'Set ${_formatLabel(_selected)}',
        ),
      ),
    );
  }
}