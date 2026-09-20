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
  List<String>? hobbies; // 👈 new — add this line


  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'gender': gender,
    'screenTimeGuess': screenTimeGuess,
    'need': need,
    'scheduleName': scheduleName,
    'scheduleStartMinutes': scheduleStart != null ? scheduleStart!.hour * 60 + scheduleStart!.minute : null,
    'scheduleEndMinutes': scheduleEnd != null ? scheduleEnd!.hour * 60 + scheduleEnd!.minute : null,
    'scheduleApps': scheduleApps,
    'scheduleDays': scheduleDays,
    'neurodivergenceStatus': neurodivergenceStatus,
    'ageRange': ageRange, // 👈 also missing — add this too
    'hobbies': hobbies, // 👈 new
  };

  static OnboardingData fromJson(Map<dynamic, dynamic> json) {
    TimeOfDay? timeFromMinutes(int? m) => m == null ? null : TimeOfDay(hour: m ~/ 60, minute: m % 60);
    return OnboardingData()
      ..name = json['name'] as String?
      ..age = json['age'] as int?
      ..gender = json['gender'] as String?
      ..screenTimeGuess = json['screenTimeGuess'] as double?
      ..need = json['need'] as String?
      ..scheduleName = json['scheduleName'] as String?
      ..neurodivergenceStatus = json['neurodivergenceStatus'] as String?
      ..ageRange = json['ageRange'] as String? // 👈 new
      ..hobbies = json['hobbies'] != null ? List<String>.from(json['hobbies']) : null // 👈 new
      ..scheduleStart = timeFromMinutes(json['scheduleStartMinutes'] as int?)
      ..scheduleEnd = timeFromMinutes(json['scheduleEndMinutes'] as int?)
      ..scheduleApps = List<String>.from(json['scheduleApps'] ?? [])
      ..scheduleDays = List<int>.from(json['scheduleDays'] ?? []);
  }
}