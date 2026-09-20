import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pausenow/onboarding_new/widget/typewriter_title.dart';
import 'app_picker_android.dart';
import 'app_picker_ios.dart';
import 'continue_button.dart';
import 'onboarding_shell.dart';

class DemoAppPickerScreen extends ConsumerStatefulWidget {
  final String scheduleId;
  final Function(List<String> apps) onAppsSelected;
  final VoidCallback? onBack;
  final int progressStep;
  final int progressTotal;

  const DemoAppPickerScreen({
    super.key,
    required this.scheduleId,
    required this.onAppsSelected,
    this.onBack,
    required this.progressStep,
    required this.progressTotal,
  });

  @override
  ConsumerState<DemoAppPickerScreen> createState() => _DemoAppPickerScreenState();
}

class _DemoAppPickerScreenState extends ConsumerState<DemoAppPickerScreen> {
  int _selectedCount = 0;
  List<String> _selectedAndroidApps = []; // 👈 add this

  bool get _isValid => _selectedCount >= 1 && _selectedCount <= 3;
  bool get _isOverLimit => _selectedCount > 3;

  String get _saveKey => 'schedule_${widget.scheduleId}_specific_apps';

  void _handleContinue() {
    if (!_isValid) return;
    if (Platform.isIOS) {
      final placeholders = List.generate(_selectedCount, (i) => 'ios_app_$i');
      widget.onAppsSelected(placeholders);
    } else {
      widget.onAppsSelected(_selectedAndroidApps); // 👈 uses the real package names on Android
    }
  }
  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      progressStep: widget.progressStep,
      progressTotal: widget.progressTotal,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const TypewriterTitle(
            text: 'Pick up to 3 apps',
            fontSize: 26,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Platform.isIOS
                ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: EmbeddedAppPicker(
                saveKey: _saveKey,
                onCountChanged: (count) => setState(() => _selectedCount = count),
              ),
            )
                : EmbeddedAndroidAppPicker( // 👈 new
              preSelected: _selectedAndroidApps,
              onSelectionChanged: (apps) {
                setState(() {
                  _selectedAndroidApps = apps;
                  _selectedCount = apps.length;
                });
              },
            ),
          ),
          if (_isOverLimit)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFE8703A), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Select max. 3 apps for now',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFE8703A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 16),
          OnboardingContinueButton(
            label: 'Continue',
            enabled: _isValid,
            onTap: _handleContinue,
          ),
          const SizedBox(height: 12), // 👈 new
          if (kDebugMode) // 👈 new — hides this entirely in release builds
            Center(
              child: GestureDetector(
                onTap: () => widget.onAppsSelected([]),
                child: Text(
                  '(debug)',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFB08A5A).withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}