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
      'that sounds uncomfortable',
      'does sleeping count?',
    ],
  ),

  // Screen 2 — The Reality
  ChatStep(
    botMessages: [
      ChatMessage(type: MessageType.bot, text: 'that discomfort you just felt'),
      ChatMessage(type: MessageType.bot, text: 'reading that question'),
      ChatMessage(type: MessageType.bot, text: 'that\'s the problem'),
      ChatMessage(type: MessageType.bot, text: 'we\'ve been trained to fill every second'),
      ChatMessage(type: MessageType.bot, text: 'waiting in line → phone out'),
      ChatMessage(type: MessageType.bot, text: 'ad break → phone out'),
      ChatMessage(type: MessageType.bot, text: 'waking up → phone out'),
      ChatMessage(type: MessageType.bot, text: 'silence feels wrong now'),
    ],
    userResponses: [
      'ok that\'s too real 😬',
      'i never noticed that',
      'yep that\'s me',
    ],
  ),

  // Screen 3 — The Reframe
  ChatStep(
    botMessages: [
      ChatMessage(type: MessageType.bot, text: 'but here\'s what nobody talks about'),
      ChatMessage(type: MessageType.bot, text: 'the most focused people alive'),
      ChatMessage(type: MessageType.bot, text: 'don\'t have more willpower than you'),
      ChatMessage(type: MessageType.bot, text: 'they just built a different relationship'),
      ChatMessage(type: MessageType.bot, text: 'with their attention'),
      ChatMessage(
        type: MessageType.bot,
        text: 'they choose when to engage.',
        textColor: Color(0xFF4CAF50),
      ),
      ChatMessage(
        type: MessageType.bot,
        text: 'instead of reacting automatically.',
        textColor: Color(0xFF4CAF50),
      ),
    ],
    userResponses: [
      'i want that',
      'how do i get there?',
      'that makes sense',
    ],
  ),

  // Screen 4 — The Science
  ChatStep(
    botMessages: [
      ChatMessage(type: MessageType.bot, text: 'your brain is incredibly adaptable'),
      ChatMessage(type: MessageType.bot, text: 'every time you pause before opening an app'),
      ChatMessage(type: MessageType.bot, text: 'you\'re rewiring something'),
      ChatMessage(type: MessageType.bot, text: 'a tiny signal that says'),
      ChatMessage(
        type: MessageType.bot,
        text: 'I am in control here.',
        textColor: Color(0xFFEDB82A),
      ),
      ChatMessage(type: MessageType.bot, text: 'do that enough times'),
      ChatMessage(type: MessageType.bot, text: 'and it becomes who you are'),
    ],
    userResponses: [
      'ok I\'m convinced 🧠',
      'that actually makes sense',
      'so how does pause now help?',
    ],
  ),

  // Screen 5 — The Solution
  ChatStep(
    botMessages: [
      ChatMessage(type: MessageType.bot, text: 'that\'s exactly what Pause Now is for'),
      ChatMessage(type: MessageType.bot, text: 'not to punish you'),
      ChatMessage(type: MessageType.bot, text: 'not to restrict you forever'),
      ChatMessage(type: MessageType.bot, text: 'but to create space'),
      ChatMessage(type: MessageType.bot, text: 'between the urge'),
      ChatMessage(type: MessageType.bot, text: 'and the action'),
      ChatMessage(
        type: MessageType.bot,
        text: 'that space is where discipline lives.',
        textColor: Color(0xFFEDB82A),
      ),
    ],
    userResponses: [
      'that\'s actually beautiful 🙏',
      'ok I get it now',
    ],
  ),

  // Screen 6 — Social Proof
  ChatStep(
    botMessages: [
      ChatMessage(type: MessageType.bot, text: 'people are already feeling the difference'),
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
        text: '★★★★★\n"It\'s not about blocking apps, it\'s about reclaiming yourself"\n— Marcus, 29',
      ),
      ChatMessage(type: MessageType.bot, text: 'ready to take control of your life?'),
    ],
    userResponses: ['Yes!'],
  ),

  // Screen 7 — Demo intro
  ChatStep(
    botMessages: [
      ChatMessage(
        type: MessageType.bot,
        text: 'let\'s get to know you a bit more!',
      ),
    ],
    userResponses: ['Sure'],
  ),
];