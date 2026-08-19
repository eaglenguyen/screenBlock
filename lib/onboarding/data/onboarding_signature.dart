import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart'; // for date formatting — confirm this is already a dependency

class CommitmentSignatureScreen extends StatefulWidget {
  final String scheduleStartTime;
  final VoidCallback onNext;

  const CommitmentSignatureScreen({
    super.key,
    required this.scheduleStartTime,
    required this.onNext,
  });

  @override
  State<CommitmentSignatureScreen> createState() => _CommitmentSignatureScreenState();
}

class _CommitmentSignatureScreenState extends State<CommitmentSignatureScreen> {
  late SignatureController _sigController;

  @override
  void initState() {
    super.initState();
    _sigController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.white,
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
      backgroundColor: const Color(0xFF16162A),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 0.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Sign your\ncommitment',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
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
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 15,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'Promise yourself that you will block your apps at '),
                        TextSpan(
                          text: widget.scheduleStartTime,
                          style: const TextStyle(color: Color(0xFFEDB82A), fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: ' and not turn it off.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Sign to make it official',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 15,
                        fontStyle: FontStyle.italic, // 👈 new

                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 0.5,
                      ),
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
                          color: Colors.white.withValues(alpha: 0.4),
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
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _sigController,
                    builder: (context, _) {
                      final hasSignature = _sigController.isNotEmpty;
                      return AnimatedOpacity(
                        opacity: hasSignature ? 1.0 : 0.4,
                        duration: const Duration(milliseconds: 200),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: hasSignature ? widget.onNext : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEDB82A),
                              foregroundColor: const Color(0xFF1A1208),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: const StadiumBorder(),
                              disabledBackgroundColor: const Color(0xFFEDB82A).withValues(alpha: 0.3),
                              textStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                            child: const Text('Continue'),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}