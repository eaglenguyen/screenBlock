import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/hivebox_names.dart';
import '../stats_state.dart';
import '../stats_viewmodel.dart';

class GoalSettingsSheet {
  // ── Entry point — shows goal picker menu ─────────
  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalMenuSheet(ref: ref),
    );
  }
}

// ── Goal menu — pick which goal to edit ──────────────

class _GoalMenuSheet extends StatelessWidget {
  final WidgetRef ref;
  const _GoalMenuSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.of(context).padding.bottom + 90,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E35),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dragHandle(),
          Text('Goals', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 20),
          _GoalTile(
            color: const Color(0xFF4CAF50),
            icon: Icons.phone_android_rounded,
            title: 'Screen Time For The Day',
            subtitle: _formatGoalLabel(StatsState.loadGoalHours()),
            onTap: () {
              Navigator.pop(context);
              _showScreenTimeGoal(context, ref);
            },
          ),
          const SizedBox(height: 12),
          _GoalTile(
            color: const Color(0xFF4ECDC4),
            icon: Icons.shield_rounded,
            title: 'Block Time Goal',
            subtitle: _formatGoalLabel(StatsState.loadBlockGoalHours()),
            onTap: () {
              Navigator.pop(context);
              _showBlockGoal(context, ref);
            },
          ),
        ],
      ),
    );
  }

  String _formatGoalLabel(double hours) {
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '${m}m per day';
    if (m == 0) return '${h}h per day';
    return '${h}h ${m}m per day';
  }

  void _showScreenTimeGoal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GoalSliderSheet(
        title: 'Daily Screen Time Limit',
        subtitle: null,
        initialHours: StatsState.loadGoalHours(),
        minHours: 0.5,
        maxHours: 7.0,
        divisions: 13,
        accentColor: const Color(0xFFEDB82A),
        textColor: const Color(0xFF1A1208),
        hiveKey: 'dailyScreenTimeGoal',
        ref: ref,
      ),
    );
  }

  void _showBlockGoal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GoalSliderSheet(
        title: 'Daily Block Goal',
        subtitle: 'How long do you want to block apps each day?',
        initialHours: StatsState.loadBlockGoalHours(),
        minHours: 0.5,
        maxHours: 8.0,
        divisions: 15,
        accentColor: const Color(0xFF4ECDC4),
        textColor: const Color(0xFF0A2A29),
        hiveKey: 'dailyBlockGoal',
        ref: ref,
      ),
    );
  }
}

// ── Reusable goal slider sheet ────────────────────────

class _GoalSliderSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final double initialHours;
  final double minHours;
  final double maxHours;
  final int divisions;
  final Color accentColor;
  final Color textColor;
  final String hiveKey;
  final WidgetRef ref;

  const _GoalSliderSheet({
    required this.title,
    required this.subtitle,
    required this.initialHours,
    required this.minHours,
    required this.maxHours,
    required this.divisions,
    required this.accentColor,
    required this.textColor,
    required this.hiveKey,
    required this.ref,
  });

  @override
  State<_GoalSliderSheet> createState() => _GoalSliderSheetState();
}

class _GoalSliderSheetState extends State<_GoalSliderSheet> {
  late double _selectedHours;

  @override
  void initState() {
    super.initState();
    _selectedHours = widget.initialHours;
  }

  void _showSaveConfirmation(BuildContext context) {
    final confirmController = TextEditingController();
    const confirmWord = 'CONFIRM';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Change ${widget.title}?',
            style: AppTextStyles.headlineSmall,
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'New limit: $_formattedLabel per day',
                style: TextStyle(
                  color: widget.accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Type CONFIRM to save this change:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                style: const TextStyle(color: Colors.white),
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Type CONFIRM',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.accentColor),
                  ),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: confirmController.text.trim() == confirmWord
                        ? () async {
                      Navigator.pop(ctx);
                      final box = Hive.box(HiveBoxNames.settings);
                      await box.put(widget.hiveKey, _selectedHours);
                      if (context.mounted) Navigator.pop(context);
                      widget.ref
                          .read(statsViewModelProvider.notifier)
                          .loadStats();
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      disabledBackgroundColor:
                      widget.accentColor.withValues(alpha: 0.3),
                      foregroundColor: widget.textColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _formattedLabel {
    final totalMinutes = (_selectedHours * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  String get _minLabel {
    final m = (widget.minHours * 60).round();
    final h = m ~/ 60;
    final min = m % 60;
    if (h == 0) return '${min}m';
    return '${h}h';
  }

  String get _maxLabel {
    final h = widget.maxHours.round();
    return '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.of(context).padding.bottom + 120,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E35),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dragHandle(),
          Text(widget.title, style: AppTextStyles.headlineSmall),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 32),

          // big time display
          Text(
            _formattedLabel,
            style: TextStyle(
              color: widget.accentColor,
              fontSize: 52,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'per day',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: widget.accentColor,
              inactiveTrackColor:
                  widget.accentColor.withValues(alpha: 0.15),
              thumbColor: widget.accentColor,
              overlayColor: widget.accentColor.withValues(alpha: 0.15),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 5,
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: Slider(
              value: _selectedHours,
              min: widget.minHours,
              max: widget.maxHours,
              divisions: widget.divisions,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _selectedHours = val);
              },
            ),
          ),

          // min/max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_minLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    )),
                Text(_maxLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // skip confirmation if value hasn't changed
                if (_selectedHours == widget.initialHours) {
                  Navigator.pop(context);
                  return;
                }
                _showSaveConfirmation(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: widget.textColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}



// ── Goal tile ─────────────────────────────────────────

class _GoalTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GoalTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared drag handle ────────────────────────────────

Widget _dragHandle() {
  return Container(
    width: 36,
    height: 4,
    margin: const EdgeInsets.only(bottom: 24),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
