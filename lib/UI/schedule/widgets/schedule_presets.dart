import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class SchedulePreset {
  final String name;
  final String emoji;
  final String description;
  final String startTime;
  final String endTime;
  final List<int> days;
  final String blockingType;
  final Color accentColor;
  final String tip;

  const SchedulePreset({
    required this.name,
    required this.emoji,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.blockingType,
    required this.accentColor,
    required this.tip,
  });
}

final List<SchedulePreset> schedulePresets = [
  SchedulePreset(
    name: 'Early Bird',
    emoji: '🌅',
    description: 'Protect your morning focus',
    startTime: '06:00',
    endTime: '09:00',
    days: [0, 1, 2, 3, 4], // Mon–Fri
    blockingType: AppConstants.blockingTypeSpecificApps,
    accentColor: const Color(0xFFEDB82A),
    tip: 'Start your day without distractions. Block social media during your most productive hours.',
  ),
  SchedulePreset(
    name: 'Night Time',
    emoji: '🌙',
    description: 'Wind down before bed',
    startTime: '21:00',
    endTime: '23:59',
    days: [0, 1, 2, 3, 4, 5, 6], // Every day
    blockingType: AppConstants.blockingTypeSpecificApps,
    accentColor: const Color(0xFFEDB82A),
    tip: 'Blue light and social media hurt your sleep. Block them an hour before bed.',
  ),
  SchedulePreset(
    name: 'Work Mode',
    emoji: '💼',
    description: 'Stay focused during work hours',
    startTime: '09:00',
    endTime: '17:00',
    days: [0, 1, 2, 3, 4], // Mon–Fri
    blockingType: AppConstants.blockingTypeSpecificApps,
    accentColor: const Color(0xFFEDB82A),
    tip: 'Block distracting apps during your core work hours to maximize deep focus.',
  ),
  SchedulePreset(
    name: 'Dinner',
    emoji: '🍽️',
    description: 'Be present at the table',
    startTime: '18:00',
    endTime: '19:30',
    days: [0, 1, 2, 3, 4, 5, 6], // Every day
    blockingType: AppConstants.blockingTypeSpecificApps,
    accentColor: const Color(0xFFEDB82A),
    tip: 'Put the phone down and enjoy your meal. Real connections happen in person.',
  ),
  SchedulePreset(
    name: 'Refocus',
    emoji: '🎯',
    description: 'Deep work — no exceptions',
    startTime: '14:00',
    endTime: '16:00',
    days: [0, 1, 2, 3, 4], // Mon–Fri
    blockingType: AppConstants.blockingTypeSpecificApps,
    accentColor: const Color(0xFFEDB82A),
    tip: 'Your afternoon energy dip is real. Use this block to power through with zero distractions.',
  ),
];