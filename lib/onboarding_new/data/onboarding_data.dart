import 'package:flutter/material.dart';

class OnboardingData {
  String? name;
  int? age;
  String? gender;
  double? screenTimeGuess;
  String? need; // 👈 was motivation
  String? scheduleName;
  TimeOfDay? scheduleStart;
  TimeOfDay? scheduleEnd;
  List<String> scheduleApps = [];
  List<int> scheduleDays = [];
  String? neurodivergenceStatus; // 👈 new
  String? ageRange; // 👈 new

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'gender': gender,
    'screenTimeGuess': screenTimeGuess,
    'need': need, // 👈 was 'motivation': motivation
    'scheduleName': scheduleName,
    'scheduleStartMinutes': scheduleStart != null ? scheduleStart!.hour * 60 + scheduleStart!.minute : null,
    'scheduleEndMinutes': scheduleEnd != null ? scheduleEnd!.hour * 60 + scheduleEnd!.minute : null,
    'scheduleApps': scheduleApps,
    'scheduleDays': scheduleDays,
    'neurodivergenceStatus': neurodivergenceStatus,

  };

  static OnboardingData fromJson(Map<dynamic, dynamic> json) {
    TimeOfDay? timeFromMinutes(int? m) => m == null ? null : TimeOfDay(hour: m ~/ 60, minute: m % 60);
    return OnboardingData()
      ..name = json['name'] as String?
      ..age = json['age'] as int?
      ..gender = json['gender'] as String?
      ..screenTimeGuess = json['screenTimeGuess'] as double?
      ..need = json['need'] as String? // 👈 was ..motivation = json['motivation'] as String?
      ..scheduleName = json['scheduleName'] as String?
      ..neurodivergenceStatus = json['neurodivergenceStatus'] as String?
      ..scheduleStart = timeFromMinutes(json['scheduleStartMinutes'] as int?)
      ..scheduleEnd = timeFromMinutes(json['scheduleEndMinutes'] as int?)
      ..scheduleApps = List<String>.from(json['scheduleApps'] ?? [])
      ..scheduleDays = List<int>.from(json['scheduleDays'] ?? []);

  }
}