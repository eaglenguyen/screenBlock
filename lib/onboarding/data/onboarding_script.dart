// ── Onboarding script ────────────────────────────────

import 'dart:ui';

import '../../../data/models/onboarding.dart';

// name step — separate from main chat steps
// handled differently in the screen (text input)
const ChatMessage namePrompt1 = ChatMessage(
  type: MessageType.bot,
  text: 'before we start...',
);

const ChatMessage namePrompt2 = ChatMessage(
  type: MessageType.bot,
  text: 'what should we call you?',
);

List<ChatStep> getOnboardingSteps(String name) => [
  // Step 0 — Ask for name
  ChatStep(
    botMessages: [
      ChatMessage(type: MessageType.bot, text: 'hey welcome!'),
      ChatMessage(type: MessageType.bot, text: 'before we dive in...'),
      ChatMessage(type: MessageType.bot, text: 'what\'s your name?'),
    ],
    userResponses: [], // 👈 empty — triggers text input instead of choices
    isNameInput: true, // 👈 flag to show text field
  ),
  // Screen 1 — The Observation
  ChatStep(
    botMessages: [
      ChatMessage(type: MessageType.bot, text: 'hey $name 👋'),
      ChatMessage(type: MessageType.bot, text: 'quick question'),
      ChatMessage(type: MessageType.bot, text: 'when was the last time'),
      ChatMessage(type: MessageType.bot, text: 'you sat down'),
      ChatMessage(type: MessageType.bot, text: 'and did absolutely nothing'),
      ChatMessage(type: MessageType.bot, text: 'no phone. no music.'),
    ],
    userResponses: [
      'honestly can\'t remember 😅',
      'does sleeping count?',
    ],
  ),

  // Screen 2 — The Reality
  ChatStep(
    botMessages: [
      ChatMessage(type: MessageType.bot, text: 'have you ever opened TikTok or Instagram...'),
      ChatMessage(type: MessageType.bot, text: 'thinking you\'d scroll for \"just 5 minutes\"'),
      ChatMessage(type: MessageType.bot, text: 'then look up'),
      ChatMessage(type: MessageType.bot, text: 'and your whole day is wasted?'),
      ChatMessage(type: MessageType.bot, text: 'we all been there.'),
      ChatMessage(type: MessageType.bot, text: 'the hardest part isnt putting the phone down.'),
      ChatMessage(type: MessageType.bot, text: 'its remembering'),
      ChatMessage(type: MessageType.bot, text: 'what you should be doing'),
    ],
    userResponses: [
      'i never noticed that',
      'yep that\'s me',
    ],
  ),

  // Screen 3 — The Reframe
  ChatStep(
    botMessages: [
      ChatMessage(type: MessageType.bot, text: 'imagine getting'),
      ChatMessage(type: MessageType.bot, text: 'those hours back'),
      ChatMessage(type: MessageType.bot, text: 'what would you do?'),
      ChatMessage(type: MessageType.bot, text: 'finally starting that project, read that new book?'),
      ChatMessage(type: MessageType.bot, text: 'hit the gym, trying out a new hobby?'),
      ChatMessage(
        type: MessageType.bot,
        text: 'At the end of the day, we choose what we want to do',
        textColor: Color(0xFF4CAF50),
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'So lets start by making better choices',
        textColor: Color(0xFF4CAF50),
      ),
    ],
    userResponses: [
      'I want to make better choices',
    ],
  ),

  // Screen 4 — The Science REMOVED

  // Screen 5 — The Solution
  ChatStep(
    botMessages: [
      ChatMessage(type: MessageType.bot, text: 'great, that\'s exactly what Pause Now is for'),
      ChatMessage(type: MessageType.bot, text: 'not to make your phone the enemy.'),
      ChatMessage(type: MessageType.bot, text: 'not to shame you for scrolling.'),
      ChatMessage(type: MessageType.bot, text: 'but to create'),
      ChatMessage(type: MessageType.bot, text: 'small moments in life'),
      ChatMessage(type: MessageType.bot, text: 'where you can ask yourself...'),
      ChatMessage(
        type: MessageType.bot,
        text: 'is this how i want to spend my time?',
        textColor: Color(0xFFEDB82A),
      ),
    ],
    userResponses: [
      'help me get there!',
    ],
  ),

  // Screen 6 — Social Proof
  ChatStep(
    botMessages: [
      ChatMessage(type: MessageType.bot, text: 'other people are already feeling the difference'),
      ChatMessage(
        type: MessageType.review,
        text: '★★★★★\n"I finally feel like I\'m living with intention"\n— Alex, 26',
      ),
      ChatMessage(
        type: MessageType.review,
        text: '★★★★★\n"Two weeks in and my mornings are completely different"\n— Priya, 23',
      ),
      ChatMessage(
        type: MessageType.review,
        text: '★★★★★\n"It\'s not about blocking apps, it\'s about bettering yourself"\n— Marcus, 29',
      ),
      ChatMessage(type: MessageType.bot, text: 'Ready to start a healthier lifestyle and block these distractions?'),
    ],
    userResponses: ['Begin my journey!'],
  ),
];