import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pausenow/onboarding/widgets/mascot_character.dart';
import '../../data/models/onboarding.dart';
import 'data/onboarding_script.dart';
import 'onboarding_viewmodel.dart';
import 'widgets/typing_dots.dart';
import 'widgets/onboarding_spotlight_overlay.dart';

class OnboardingChatIntroScreen extends StatefulWidget {
  final VoidCallback onStart;

  const OnboardingChatIntroScreen({
    super.key,
    required this.onStart,
  });

  @override
  State<OnboardingChatIntroScreen> createState() =>
      _OnboardingChatIntroScreenState();
}

class _OnboardingChatIntroScreenState
    extends State<OnboardingChatIntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1A),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // chat bubble
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF252535),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'Howdy! I\'m Boxy. Let\'s have a quick chat about what\'s going on here 👀\n            (yes, this is personal)',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // bouncing mascot
            const MascotCharacter(size: 160),


            const Spacer(flex: 2),

            // start button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onStart();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEDB82A),
                    foregroundColor: const Color(0xFF1A1208),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: const StadiumBorder(),
                    elevation: 0,
                    textStyle: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('Chat with Boxy'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingChatScreen extends ConsumerStatefulWidget {
  final VoidCallback? onChatComplete;

  const OnboardingChatScreen({super.key, this.onChatComplete});

  @override
  ConsumerState<OnboardingChatScreen> createState() =>
      _OnboardingChatScreenState();
}

class _OnboardingChatScreenState
    extends ConsumerState<OnboardingChatScreen> {

  final ScrollController _scrollController = ScrollController();
  final List<DisplayMessage> _messages = [];
  Timer? _scrollDebounce;

  int _currentStep = 0;
  int _currentBotMessageIndex = 0;
  bool _showingResponses = false;
  bool _isTyping = false;
  bool _userResponded = false;
  String _userName = '';
  bool _nameCollected = false;

  @override
  void initState() {
    super.initState();
    // chat starts after spotlight dismissed
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMascotAvatar() {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 8), // 👈 margin here not in Row
      child: ClipOval(
        child: Image.asset(
          'assets/icons/mascot_face.png',
          width: 28,
          height: 28,
          fit: BoxFit.cover,
        ),
      ),
    );
  }


  void _onNameCollected(String name) {
    _userName = name; // set immediately without setState
    ref.read(onboardingViewModelProvider.notifier).setUserName(name);
  }

  void _onSpotlightDismissed() {
    setState(() => _nameCollected = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _startStep(0);
    });
  }

  void _startStep(int stepIndex) {
    final steps = getOnboardingSteps(_userName);
    if (stepIndex >= steps.length) {
      _onChatComplete();
      return;
    }
    _currentStep = stepIndex;
    _currentBotMessageIndex = 0;
    _userResponded = false;
    _showNextBotMessage();
  }

  Future<void> _onChatComplete() async {
    if (widget.onChatComplete != null) {
      // called from onboarding flow — go to next step
      widget.onChatComplete!();
    } else {
      // standalone — complete onboarding
      await ref
          .read(onboardingViewModelProvider.notifier)
          .completeOnboarding();
      if (mounted) context.go('/home');
    }
  }

  void _showNextBotMessage() {
    final step = getOnboardingSteps(_userName)[_currentStep];

    if (_currentBotMessageIndex >= step.botMessages.length) {
      setState(() => _showingResponses = true);
      _scrollToBottom();
      return;
    }

    setState(() => _isTyping = true);

    final delay = _getTypingDelay(
      step.botMessages[_currentBotMessageIndex],
    );

    Future.delayed(delay, () {
      if (!mounted) return;
      final msg = step.botMessages[_currentBotMessageIndex];
      setState(() {
        _isTyping = false;
        _messages.add(DisplayMessage(message: msg, isUser: false));
        _currentBotMessageIndex++;
      });
      HapticFeedback.lightImpact();
      _scrollToBottom();

      Future.delayed(const Duration(milliseconds: 280), () {
        if (!mounted) return;
        _showNextBotMessage();
      });
    });
  }

  Duration _getTypingDelay(ChatMessage msg) {
    if (msg.type == MessageType.review) {
      return const Duration(milliseconds: 900);
    }
    final len = msg.text?.length ?? 0;
    final ms = (len * 26).clamp(350, 1100);
    return Duration(milliseconds: ms);
  }

  void _onUserTap(String response) {
    if (_userResponded) return;
    _userResponded = true;
    HapticFeedback.lightImpact();

    setState(() {
      _showingResponses = false;
      _messages.add(DisplayMessage(
        message: ChatMessage(type: MessageType.user, text: response),
        isUser: true,
      ));
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _startStep(_currentStep + 1);
    });
  }

  void _scrollToBottom() {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isLastBotInGroup(int index) {
    final msg = _messages[index];
    if (msg.isUser) return false;
    // last message overall
    if (index == _messages.length - 1) return true;
    // next message is from user = last in group
    return _messages[index + 1].isUser;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: Stack(
        children: [
          // ── Chat UI ─────────────────────────────────
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: _messages.length +
                      (_isTyping ? 1 : 0) +
                      (_showingResponses ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _messages.length) {
                      final isLastInGroup = _isLastBotInGroup(index);
                      return _buildMessageItem(_messages[index], isLastInGroup);
                    }
                    if (_isTyping && index == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    if (_showingResponses) {
                      return _buildResponses();
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),

          // ── Spotlight overlay ────────────────────────
          if (!_nameCollected)
            OnboardingSpotlightOverlay(
              onNameSet: _onNameCollected,
              onNameSubmitted: _onSpotlightDismissed,
            ),
        ],
      ),
    );
  }


  Widget _buildNameInput() {
    // auto-show dialog when name input step appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showingResponses) {
        _showNameDialog();
      }
    });
    return const SizedBox.shrink(); // no inline UI needed
  }

  void _showNameDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E1E35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: const Color(0xFFEDB82A).withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'what should we call you?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF252542),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF2A2A48),
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), // 👈 letters and spaces only
                  ],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter your name...',
                    hintStyle: TextStyle(
                      color: Color(0xFF7070A0),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(ctx);
                    _submitName(name);
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(ctx);
                    _submitName(name);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEDB82A),
                    foregroundColor: const Color(0xFF1A1208),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitName(String name) {
    HapticFeedback.mediumImpact();
    _onNameCollected(name);
    _onUserTap(name); // shows name as user bubble and advances
  }


  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E35),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2A48), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Replace the shield container with:
          const MascotCharacter(size: 44, rivFile: 'assets/rive/mr_square_icon.riv'),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Boxy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Online',
                    style: TextStyle(
                      color: Color(0xFF7070A0),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildMessageItem(DisplayMessage item, bool isLastInGroup) {
    if (item.isUser) return _buildUserBubble(item.message.text ?? '');
    if (item.message.type == MessageType.review) {
      return _buildReviewBubble(item.message.text ?? '', isLastInGroup);
    }
    return _buildBotBubble(item.message.text ?? '', item.message.textColor, isLastInGroup);
  }

  Widget _buildBotBubble(String text, Color? textColor, bool showAvatar) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10, right: 64, left: showAvatar ? 0 : 36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar)
            _buildMascotAvatar(),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF252542),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: textColor != null ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildUserBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 64),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEDB82A).withValues(alpha: 0.12),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            border: Border.all(
              color: const Color(0xFFEDB82A).withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFEDB82A),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 64),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // always show avatar on typing indicator
          _buildMascotAvatar(),
          Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: const BoxDecoration(
              color: Color(0xFF252542),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: const TypingDots(),
          ),
          ),
        ],
      ),
    );
  }



  Widget _buildReviewBubble(String text, bool showAvatar) {
    final lines = text.split('\n');
    final stars = lines[0];
    final review = lines[1];
    final author = lines[2];

    return Padding(
      padding: EdgeInsets.only(bottom: 6, right: 32, left: showAvatar ? 0 : 36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar)
            _buildMascotAvatar(),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFF252542),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stars, style: const TextStyle(
                      color: Color(0xFFFFC107), fontSize: 13, letterSpacing: 2)),
                  const SizedBox(height: 6),
                  Text(review, style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(author, style: const TextStyle(
                      color: Color(0xFF7070A0), fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponses() {
    final step = getOnboardingSteps(_userName)[_currentStep];

    // 👇 show text input for name step
    if (step.isNameInput) {
      return _buildNameInput();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Choose an answer',
              style: TextStyle(color: Color(0xFF7070A0), fontSize: 12),
            ),
          ),
          ...step.userResponses.map((response) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _onUserTap(response),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDB82A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFEDB82A).withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    response,
                    style: const TextStyle(
                      color: Color(0xFFEDB82A),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Goals Picker Screen ───────────────────────────────

class OnboardingGoalsScreen extends StatefulWidget {
  final Function(List<String> goals) onNext;

  const OnboardingGoalsScreen({
    super.key,
    required this.onNext,
  });

  @override
  State<OnboardingGoalsScreen> createState() => _OnboardingGoalsScreenState();
}

class _OnboardingGoalsScreenState extends State<OnboardingGoalsScreen> {
  final Set<int> _selected = {};

  final List<Map<String, String>> _goals = [
    {'emoji': '🧘', 'title': 'Less anxiety', 'sub': 'Be more present in the moment'},
    {'emoji': '📵', 'title': 'More time offline', 'sub': 'Disconnect and live more intentionally'},
    {'emoji': '⚡', 'title': 'Be more productive', 'sub': 'Focus deeper and get more done'},
    {'emoji': '📱', 'title': 'Reduce social media', 'sub': 'Break the scroll and reclaim your time'},
    {'emoji': '🔄', 'title': 'Build better habits', 'sub': 'Unlearn old patterns, create new ones'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a0a3d),
                  Color(0xFF16162a),
                  Color(0xFF0a1a2a),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEDB82A).withValues(alpha: 0.04),
                border: Border.all(
                  color: const Color(0xFFEDB82A).withValues(alpha: 0.07),
                  width: 0.5,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'What are your\ngoals?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick all that apply — we\'ll personalize your experience around them.',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _goals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final goal = _goals[i];
                        final isSelected = _selected.contains(i);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (isSelected) {
                                _selected.remove(i);
                              } else {
                                _selected.add(i);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEDB82A).withValues(alpha: 0.1)
                                  : const Color(0xFF1E1E35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFEDB82A).withValues(alpha: 0.6)
                                    : const Color(0xFF2A2A48),
                                width: isSelected ? 1.5 : 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(goal['emoji']!,
                                    style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        goal['title']!,
                                        style: GoogleFonts.poppins(
                                          color: isSelected
                                              ? const Color(0xFFEDB82A)
                                              : Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        goal['sub']!,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? const Color(0xFFEDB82A)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFEDB82A)
                                          : Colors.white.withValues(alpha: 0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check_rounded,
                                      color: Color(0xFF1A1208), size: 13)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedOpacity(
                    opacity: _selected.isNotEmpty ? 1.0 : 0.35,
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton(
                      onPressed: _selected.isNotEmpty
                          ? () => widget.onNext(
                          _selected.map((i) => _goals[i]['title']!).toList())
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEDB82A),
                        foregroundColor: const Color(0xFF1A1208),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: const StadiumBorder(),
                        disabledBackgroundColor:
                        const Color(0xFFEDB82A).withValues(alpha: 0.4),
                        textStyle: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      child: const Text('Continue →'),
                    ),
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

// ── Goals Confirm Screen ──────────────────────────────

class OnboardingGoalsConfirmScreen extends StatefulWidget {
  final List<String> selectedGoals;
  final String futureVision;
  final VoidCallback onNext;
  final double progress;         // 👈 add


  const OnboardingGoalsConfirmScreen({
    super.key,
    required this.selectedGoals,
    required this.futureVision, // 👈 add
    required this.onNext,
    required this.progress,
  });

  @override
  State<OnboardingGoalsConfirmScreen> createState() =>
      _OnboardingGoalsConfirmScreenState();
}

class _OnboardingGoalsConfirmScreenState
    extends State<OnboardingGoalsConfirmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _itemAnims;

  final List<Map<String, String>> _allGoals = [
    {'emoji': '🧘', 'title': 'Less anxiety', 'sub': 'Be more present in the moment'},
    {'emoji': '📵', 'title': 'More time offline', 'sub': 'Disconnect and live more intentionally'},
    {'emoji': '⚡', 'title': 'Be more productive', 'sub': 'Focus deeper and get more done'},
    {'emoji': '📱', 'title': 'Reduce social media', 'sub': 'Break the scroll and reclaim your time'},
    {'emoji': '🔄', 'title': 'Build better habits', 'sub': 'Unlearn old patterns, create new ones'},
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: 300 + widget.selectedGoals.length * 150),
    );
    _itemAnims = List.generate(widget.selectedGoals.length, (i) {
      final start = (i * 0.2).clamp(0.0, 0.8);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String? _getEmoji(String title) {
    try {
      return _allGoals.firstWhere((g) => g['title'] == title)['emoji'];
    } catch (_) {
      return null;
    }
  }

  String? _getSub(String title) {
    try {
      return _allGoals.firstWhere((g) => g['title'] == title)['sub'];
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  Color(0xFF1a0a3d),
                  Color(0xFF16162a),
                  Color(0xFF0a1a2a),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 👇 progress bar only, no back button
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFEDB82A),
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // selected goal cards
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(widget.selectedGoals.length, (i) {
                          final title = widget.selectedGoals[i];
                          final emoji = _getEmoji(title) ?? '✅';
                          final sub = _getSub(title) ?? '';
                          final tilts = [-2.5, 1.8, -1.5, 2.2, -2.0];
                          final tilt = tilts[i % tilts.length] * (3.14159 / 180);

                          return AnimatedBuilder(
                            animation: _itemAnims[i],
                            builder: (_, child) => Opacity(
                              opacity: _itemAnims[i].value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - _itemAnims[i].value)),
                                child: child,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Transform.rotate(
                                angle: tilt,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E35), // was Colors.white
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFEDB82A).withValues(alpha: 0.25),
                                      width: 0.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(emoji, style: const TextStyle(fontSize: 26)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              title,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              sub,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white.withValues(alpha: 0.4),
                                                fontSize: 12,
                                                height: 1.4,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (widget.futureVision.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDB82A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFEDB82A).withValues(alpha: 0.25),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🔮', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your future vision',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFEDB82A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.futureVision,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),


                  // bottom section — like "you're in the right place"
                  Text(
                    'you\'re in the right place.',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'a lot of people have started with the same goals — Pause Now helped them get there.',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // continue button
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onNext();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEDB82A),
                      foregroundColor: const Color(0xFF1A1208),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const StadiumBorder(),
                      elevation: 0,
                      textStyle: GoogleFonts.poppins(
                          fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    child: const Text('continue →'),
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


