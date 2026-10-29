import 'package:flutter/foundation.dart';

const kEducationOptions = <String, String>{
  'High school': 'High school',
  'Diploma': 'Diploma',
  "Bachelor's": "Bachelor's",
  "Master's": "Master's",
  'PhD': 'PhD',
  'Other': 'Other',
};

const kExperienceOptions = <String, String>{
  'fresher': 'Fresher',
  'junior': '1-2 years',
  'mid': '3-5 years',
  'senior': '5+ years',
};

@immutable
class Profile {
  const Profile({
    required this.id,
    this.fullName = '',
    this.education = '',
    this.targetRole = '',
    this.experienceLevel = '',
  });

  final String id;
  final String fullName;
  final String education;
  final String targetRole;
  final String experienceLevel;

  bool get isComplete =>
      fullName.trim().isNotEmpty &&
      education.trim().isNotEmpty &&
      targetRole.trim().isNotEmpty &&
      experienceLevel.trim().isNotEmpty;

  List<String> get _words =>
      fullName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  String get firstName => _words.isEmpty ? 'there' : _words.first;

  String get initials => _words.isEmpty
      ? '?'
      : _words.take(2).map((w) => w[0].toUpperCase()).join();

  String get experienceLabel => kExperienceOptions[experienceLevel] ?? '';

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        fullName: (json['fullName'] as String?) ?? '',
        education: (json['education'] as String?) ?? '',
        targetRole: (json['targetRole'] as String?) ?? '',
        experienceLevel: (json['experienceLevel'] as String?) ?? '',
      );
}