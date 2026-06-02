import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/onboarding.dart';
import 'data/onboarding_script.dart';
import 'onboarding_viewmodel.dart';
import 'widgets/typing_dots.dart';
import 'widgets/onboarding_spotlight_overlay.dart';

class OnboardingChatScreen extends ConsumerStatefulWidget {
  const OnboardingChatScreen({super.key});

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

  void _onNameCollected(String name) {
    _userName = name; // set immediately without setState
    ref.read(onboardingViewModelProvider.notifier).setUserName(name);
  }

  void _onSpotlightDismissed() {
    setState(() => _nameCollected = true);
    // small delay to let overlay finish removing from tree
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
    await ref
        .read(onboardingViewModelProvider.notifier)
        .completeOnboarding();
    if (mounted) context.go('/home');
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
                      return _buildMessageItem(_messages[index]);
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEDB82A).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFEDB82A).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Text('🛡️', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ChatBot',
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

  Widget _buildMessageItem(DisplayMessage item) {
    if (item.isUser) return _buildUserBubble(item.message.text ?? '');
    if (item.message.type == MessageType.review) {
      return _buildReviewBubble(item.message.text ?? '');
    }
    return _buildBotBubble(
      item.message.text ?? '',
      item.message.textColor,
    );
  }

  Widget _buildBotBubble(String text, Color? textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 64),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF252542),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(
              color: const Color(0xFF2A2A48),
              width: 0.5,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 15,
              height: 1.4,
              fontWeight: textColor != null
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 64),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 11,
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
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 64),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF252542),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(
              color: const Color(0xFF2A2A48),
              width: 0.5,
            ),
          ),
          child: const TypingDots(),
        ),
      ),
    );
  }

  Widget _buildReviewBubble(String text) {
    final lines = text.split('\n');
    final stars = lines[0];
    final review = lines[1];
    final author = lines[2];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 32),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF252542),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(
            color: const Color(0xFF2A2A48),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stars,
              style: const TextStyle(
                color: Color(0xFFFFC107),
                fontSize: 13,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              review,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              author,
              style: const TextStyle(
                color: Color(0xFF7070A0),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponses() {
    final step = getOnboardingSteps(_userName)[_currentStep];
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Choose an answer',
              style: TextStyle(
                color: Color(0xFF7070A0),
                fontSize: 12,
              ),
            ),
          ),
          ...step.userResponses.map((response) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _onUserTap(response),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDB82A)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFEDB82A)
                          .withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    response,
                    style: const TextStyle(
                      color: Color(0xFFEDB82A),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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