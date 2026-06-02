// ── Data models ──────────────────────────────────────

import 'dart:ui';

enum MessageType { bot, user, review }

class ChatMessage {
  final String? text;
  final MessageType type;
  final Color? textColor;

  const ChatMessage({
    this.text,
    required this.type,
    this.textColor,
  });
}

class ChatStep {
  final List<ChatMessage> botMessages;
  final List<String> userResponses;

  const ChatStep({
    required this.botMessages,
    required this.userResponses,
  });
}


class DisplayMessage {
  final ChatMessage message;
  final bool isUser;
  DisplayMessage({required this.message, required this.isUser});
}