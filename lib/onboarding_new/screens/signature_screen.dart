// lib/onboarding_new/screens/commitment_signature_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import '../widget/continue_button.dart';

class OnboardingCommitmentSignatureScreen extends StatefulWidget {
  final String scheduleStartTime;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const OnboardingCommitmentSignatureScreen({
    super.key,
    required this.scheduleStartTime,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<OnboardingCommitmentSignatureScreen> createState() => _OnboardingCommitmentSignatureScreenState();
}

class _OnboardingCommitmentSignatureScreenState extends State<OnboardingCommitmentSignatureScreen> {
  late SignatureController _sigController;

  @override
  void initState() {
    super.initState();
    _sigController = SignatureController(
      penStrokeWidth: 3,
      penColor: const Color(0xFF4A3728), // 👈 was Colors.white — now your text-primary brown, since the pad is now light
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _sigController.dispose();
    super.dispose();
  }

  String get _formattedDate {
    final now = DateTime.now();
    return DateFormat('MMMM d, yyyy').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED), // 👈 was Color(0xFF16162A)
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align( // 👈 new — shields the button from the Column's stretch constraint
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF0E6D8), width: 1),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A3728), size: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Sign your\ncommitment',
                textAlign: TextAlign.center, // 👈 new
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4A3728),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFB08A5A), // 👈 was Colors.white.withValues(alpha: 0.6)
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Promise yourself that you will block your apps at '),
                    TextSpan(
                      text: widget.scheduleStartTime,
                      style: const TextStyle(color: Color(0xFF2D7A54), fontWeight: FontWeight.w700), // 👈 was Color(0xFFEDB82A)
                    ),
                    const TextSpan(text: ' and spin the wheel if you have to urge to scroll.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Sign to make it official',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFB08A5A).withValues(alpha: 0.7), // 👈 was Colors.white.withValues(alpha: 0.3)
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white, // 👈 was Color(0xFF1E1E35)
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF0E6D8), width: 1), // 👈 was white alpha
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)), // 👈 new
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Signature(
                    controller: _sigController,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _sigController.clear()),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFB08A5A), // 👈 was Colors.white.withValues(alpha: 0.4)
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Signed on $_formattedDate',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFB08A5A).withValues(alpha: 0.7), // 👈 was Colors.white.withValues(alpha: 0.3)
                    fontSize: 15,
                  ),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _sigController,
                builder: (context, _) {
                  final hasSignature = _sigController.isNotEmpty;
                  return OnboardingContinueButton( // 👈 was ElevatedButton — now matches the rest of your flow's shared button
                    label: 'Continue',
                    enabled: hasSignature,
                    onTap: widget.onContinue,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}