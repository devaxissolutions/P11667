import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/selectable_chip.dart';
import '../controllers/onboarding_controller.dart';

class TopicSelectionScreen extends ConsumerWidget {
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final int currentPage;
  final int totalPages;

  const TopicSelectionScreen({
    super.key,
    required this.onContinue,
    required this.onSkip,
    required this.currentPage,
    required this.totalPages,
  });

  static const List<String> topics = [
    'Wisdom',
    'Success',
    'Life',
    'Motivation',
    'Mindset',
    'Happiness',
    'Growth',
    'Inspiration',
    'Productivity',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTopics = ref.watch(selectedTopicsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'What inspires you?',
                style: AppTypography.title1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Select a few topics to personalize your feed.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Topic chips
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: topics.map((topic) {
                      final isSelected = selectedTopics.contains(topic);
                      return SelectableChip(
                        label: topic,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(selectedTopicsProvider.notifier)
                              .toggleTopic(topic);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  totalPages,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentPage == index
                          ? AppColors.primary
                          : AppColors.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Continue button
              PrimaryButton(
                text: 'Continue',
                onPressed: selectedTopics.isNotEmpty ? onContinue : null,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
