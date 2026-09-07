import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';




class QuotesScreen extends StatelessWidget {
  final VoidCallback onNext;
  const QuotesScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final testimonials = [
      {
        'name': 'Dr. Marcus Reyes',
        'title': 'Neuroscientist',
        'headline': 'Drastically improve your life',
        'body': 'Resetting your dopamine balance by taking a break from highly stimulating content can dramatically improve motivation, emotional stability, and everyday pleasure.',
      },
      {
        'name': 'Elena Vasquez',
        'title': 'Productivity Coach',
        'headline': 'Scrolling is bad',
        'body': 'If you\'re scrolling mindlessly or letting yourself get spun up on negativity, that\'s bad for your mental health. It\'s bad for the people around you too.',
      },
      {
        'name': 'Jordan Blake',
        'title': 'Author & Speaker',
        'headline': 'Time is our most valuable asset',
        'body': 'Procrastination plus distraction equals idle time. If you can master staying focused, you win. That means recognizing procrastination and managing the doubt that tries to stop you.',
      },
      {
        'name': 'Marcus',
        'title': 'Pause Now User',
        'headline': 'My focus at work is night and day',
        'body': 'I used to check my phone every few minutes without even realizing it. Since blocking my apps during work hours, I actually finish tasks in one sitting.',
      },
      {
        'name': 'Dr. Sarah Kim',
        'title': 'Sleep Researcher',
        'headline': 'Your brain needs the boredom',
        'body': 'Constant stimulation crowds out the quiet moments your brain uses to process and consolidate. Reclaiming that space is one of the simplest things you can do for focus.',
      },
      {
        'name': 'Priya Anand',
        'title': 'Pause Now User',
        'headline': 'I finally read again',
        'body': 'I hadn\'t finished a book in two years. Three weeks into using this app, I\'ve read two. Small change, huge difference in how my evenings feel.',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Rewiring Benefits',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: testimonials.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, i) {
                  final t = testimonials[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.backgroundSubtle(context),
                            child: Text(
                              t['name']!.substring(0, 1),
                              style: TextStyle(
                                color: AppColors.accent(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            t['name']!,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textPrimary(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(Icons.verified_rounded, color: AppColors.success(context), size: 15),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border(context),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['headline']!,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textPrimary(context),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t['body']!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary(context),
                                fontSize: 13.5,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: onNext,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}