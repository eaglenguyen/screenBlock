import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../onboarding/widgets/mascot_character.dart';

// ── Get Help Sheet ────────────────────────────────────

class GetHelpSheet extends StatefulWidget {
  const GetHelpSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const GetHelpSheet(),
    );
  }

  @override
  State<GetHelpSheet> createState() => _GetHelpSheetState();
}

class _GetHelpSheetState extends State<GetHelpSheet> {
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = [
    {
      'q': 'Why isn\'t the blocking working?',
      'a':
      'Make sure all required permissions are granted in Settings → Permissions. On iOS, Screen Time authorization is required. On Android, Accessibility Service and Display Over Apps must both be enabled.',
    },
    {
      'q': 'How do I cancel my subscription?',
      'a':
      'On iOS, go to Settings → Apple ID → Subscriptions → Pause Now → Cancel. Cancellation takes effect at the end of your current billing period.',
    },
    {
      'q': 'What are ⭐️ and how do I earn it?',
      'a':
      '⭐️\'s are earned by completing blocking sessions. You earn 5 ⭐️ per minute blocked. Claim your ⭐️ at the end of each session from the home screen.',
    },
    {
      'q': 'Can I block all apps at once?',
      'a':
      'Yes — this is a Premium feature. Upgrade to unlock "All Apps" blocking mode which blocks every app on your device except ones you choose to allow.',
    },
    {
      'q': 'How do scheduled sessions work?',
      'a':
      'Scheduled sessions automatically start blocking at your set time and stop when the schedule ends. You can create up to 1 schedule on the free plan, unlimited on Premium.',
    },
    {
      'q': 'How do I restore my purchases?',
      'a':
      'Go to Settings → Account → Restore Purchases. Make sure you\'re signed into the same Apple ID you used to purchase.',
    },
    {
      'q': 'Why does the block screen keep appearing?',
      'a':
      'This is intentional — the block screen reappears if you try to open a blocked app.',
    },
    {
      'q': 'Why does blocking stop working after a while?',
      'a':
      'Some Android manufacturers (Samsung, Xiaomi, Huawei, OnePlus) aggressively kill background services to save battery. This can cause the blocking to stop working when your screen turns off or the phone is idle. To fix this, go to Settings → Permissions → Battery Optimization and enable it',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: MascotCharacter(
                    size: 36,
                    rivFile: 'assets/rive/mr_square_hii.riv',
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'FAQS',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Divider(height: 0.5, thickness: 0.5, color: AppColors.border(context)),

          // FAQ list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _faqs.length,
              separatorBuilder: (_, __) => Divider(
                height: 0.5,
                thickness: 0.5,
                color: AppColors.border(context),
              ),
              itemBuilder: (context, i) {
                final faq = _faqs[i];
                final isExpanded = _expandedIndex == i;

                return InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() =>
                    _expandedIndex = isExpanded ? null : i);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                faq['q']!,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textPrimary(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary(context),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              faq['a']!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary(context),
                                height: 1.5,
                              ),
                            ),
                          ),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // email support button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(
                  'mailto:pause.now.2026@gmail.com?subject=Pause Now Support',
                ),
              ),
              icon: Icon(
                Icons.mail_outline_rounded,
                color: AppColors.gold(context),
                size: 18,
              ),
              label: Text(
                'Email Support',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.gold(context),
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: const StadiumBorder(),
                side: BorderSide(
                  color: AppColors.gold(context).withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Give Feedback Sheet ───────────────────────────────

class GiveFeedbackSheet extends StatefulWidget {
  const GiveFeedbackSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const GiveFeedbackSheet(),
    );
  }

  @override
  State<GiveFeedbackSheet> createState() => _GiveFeedbackSheetState();
}

class _GiveFeedbackSheetState extends State<GiveFeedbackSheet> {
  final TextEditingController _ctrl = TextEditingController();
  int? _selectedRating;
  bool _isSending = false;

  final List<Map<String, String>> _ratings = [
    {'emoji': '😞', 'label': 'Poor'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '🙂', 'label': 'Good'},
    {'emoji': '😄', 'label': 'Great'},
    {'emoji': '🤩', 'label': 'Love it'},
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    if (_ctrl.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    final rating = _selectedRating != null
        ? _ratings[_selectedRating!]['label']
        : 'No rating';
    final body = Uri.encodeComponent(
      'Rating: $rating\n\nFeedback:\n${_ctrl.text.trim()}',
    );

    final uri = Uri.parse(
      'mailto:pause.now.2026@gmail.com?subject=Pause Now Feedback&body=$body',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }

    setState(() => _isSending = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundCard(context),
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.gold(context),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Give Feedback',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Help us make Pause Now better',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 24),

              // rating row
              Text(
                'How are you liking the app?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_ratings.length, (i) {
                  final isSelected = _selectedRating == i;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedRating = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 52,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.gold(context)
                            .withValues(alpha: 0.12)
                            : AppColors.backgroundSubtle(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.gold(context)
                              .withValues(alpha: 0.5)
                              : AppColors.border(context),
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _ratings[i]['emoji']!,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _ratings[i]['label']!,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isSelected
                                  ? AppColors.gold(context)
                                  : AppColors.textSecondary(context),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // feedback text field
              Text(
                'Tell us more',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundSubtle(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: _ctrl,
                  maxLines: 5,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary(context),
                  ),
                  decoration: InputDecoration(
                    hintText:
                    'What do you love? What could be better?',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),

              // send button
              ElevatedButton(
                onPressed:
                _ctrl.text.trim().isNotEmpty && !_isSending
                    ? _sendFeedback
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold(context),
                  foregroundColor: AppColors.goldText(context),
                  disabledBackgroundColor:
                  AppColors.gold(context).withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  textStyle: AppTextStyles.labelLarge,
                ),
                child: _isSending
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.goldText(context),
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Send Feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}