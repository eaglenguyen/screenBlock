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

// main chat steps — name injected at runtime
List<ChatStep> getOnboardingSteps(String name) => [
  // Screen 1 — The Hook (uses name)
  ChatStep(
    botMessages: [
      ChatMessage(
        type: MessageType.bot,
        text: 'Hey there $name ! 👋 real quick...',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'does this sound familiar?',
      ),
      ChatMessage(type: MessageType.bot, text: 'you wake up'),
      ChatMessage(
        type: MessageType.bot,
        text: 'and your phone is already in your hand',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'before you even think',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'before you even breathe',
      ),
    ],
    userResponses: [
      'ok yes 💀',
      'caught me',
      'every single morning',
    ],
  ),

  // Screen 2 — Twist the Knife
  ChatStep(
    botMessages: [
      ChatMessage(type: MessageType.bot, text: 'and at night'),
      ChatMessage(
        type: MessageType.bot,
        text: 'you open TikTok for "just a second"',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'next thing you know',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'it\'s been 2 hours',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'you finally put it down',
      ),
      ChatMessage(type: MessageType.bot, text: 'you feel drained'),
      ChatMessage(
        type: MessageType.bot,
        text: 'like your brain just ran a marathon',
      ),
    ],
    userResponses: [
      'why does this hit 😭',
      'that emptiness is real',
      'ok stop',
    ],
  ),

  // Screen 3 — Name It
  ChatStep(
    botMessages: [
      ChatMessage(
        type: MessageType.bot,
        text: 'that feeling has a name',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'living on autopilot',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'every time you pick up your phone without thinking',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'your brain learns something...',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'a habit, a routine',
        textColor: Color(0xFFEF5350),
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'that your actions don\'t matter',
        textColor: Color(0xFFEF5350),
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'that\'s why it feels bad',
      ),
    ],
    userResponses: [
      'that\'s deep 😳',
      'ok that hurt',
    ],
  ),

  // Screen 4 — Absolve Them
  ChatStep(
    botMessages: [
      ChatMessage(
        type: MessageType.bot,
        text: 'but here\'s the thing',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'it\'s not a willpower problem',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'screentime limits → you ignore them',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'app blockers → you delete them',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'none of those fix the real problem',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'you never broke the habit and built a healthy ritual',
        textColor: Color(0xFF4CAF50),
      ),
    ],
    userResponses: [
      'wait what',
      'a ritual? 👀',
      'i\'m listening',
    ],
  ),

  // Screen 5 — The Reframe
  ChatStep(
    botMessages: [
      ChatMessage(
        type: MessageType.bot,
        text: 'the most intentional people in the world',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'athletes. CEOs. monks.',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'they all have one thing in common',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'they protect their morning',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'they reflect on their night',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'they decide who they are every single day',
        textColor: Color(0xFF4CAF50),
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'your phone should help you do that',
      ),
    ],
    userResponses: [
      'ok I want that 🙏',
      'that makes sense',
    ],
  ),

  // Screen 6 — Social Proof
  ChatStep(
    botMessages: [
      ChatMessage(
        type: MessageType.bot,
        text: 'some people are already doing it',
      ),
      ChatMessage(
        type: MessageType.review,
        text:
        '★★★★★\n"I actually look forward to my morning now"\n— Maya, 24',
      ),
      ChatMessage(
        type: MessageType.review,
        text:
        '★★★★★\n"First thing I do isn\'t Instagram anymore. It\'s me."\n— Jordan, 27',
      ),
      ChatMessage(
        type: MessageType.review,
        text:
        '★★★★★\n"Didn\'t know I needed this until I tried it"\n— Chris, 22',
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'want to see how it works?',
      ),
    ],
    userResponses: ['show me 🙌'],
  ),
  // Screen 7 — Demo intro
  ChatStep(
    botMessages: [
      ChatMessage(
        type: MessageType.bot,
        text: 'Sure, here is a 3 step demo of how the app works!',
      ),
    ],
    userResponses: ['Nice!'],
  ),
];