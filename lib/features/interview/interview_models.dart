import 'dart:math' as math;

import 'package:flutter/foundation.dart';

const kInterviewTypes = <String, String>{
  'technical': 'Technical',
  'hr': 'HR',
  'behavioral': 'Behavioral',
  'mixed': 'Mixed',
};

const kDifficulties = <String, String>{
  'beginner': 'Beginner',
  'intermediate': 'Intermediate',
  'advanced': 'Advanced',
};

const kDurations = <int, String>{
  10: '10 min',
  15: '15 min',
  30: '30 min',
};

/// Mirrors the server: about one question per 3 minutes, between 3 and 12.
int questionCount(int minutes) => math.min(12, math.max(3, (minutes / 3).round()));

List<String> _strings(Object? v) =>
    ((v as List<dynamic>?) ?? const []).whereType<String>().toList();

@immutable
class InterviewSummary {
  const InterviewSummary({
    required this.id,
    required this.targetRole,
    required this.interviewType,
    required this.difficulty,
    required this.durationMinutes,
    required this.mode,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.overallScore,
  });

  final String id;
  final String targetRole;
  final String interviewType;
  final String difficulty;
  final int durationMinutes;
  final String mode;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? overallScore;

  bool get isCompleted => status == 'completed';
  String get typeLabel => kInterviewTypes[interviewType] ?? interviewType;
  String get difficultyLabel => kDifficulties[difficulty] ?? difficulty;

  factory InterviewSummary.fromJson(Map<String, dynamic> j) => InterviewSummary(
        id: j['id'] as String,
        targetRole: (j['targetRole'] as String?) ?? '',
        interviewType: (j['interviewType'] as String?) ?? 'mixed',
        difficulty: (j['difficulty'] as String?) ?? 'intermediate',
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 15,
        mode: (j['mode'] as String?) ?? 'text',
        status: (j['status'] as String?) ?? 'in_progress',
        startedAt: DateTime.parse(j['startedAt'] as String),
        completedAt: j['completedAt'] == null
            ? null
            : DateTime.parse(j['completedAt'] as String),
        overallScore: (j['overallScore'] as num?)?.toInt(),
      );
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.seq,
    required this.isInterviewer,
    required this.content,
  });

  final String id;
  final int seq;
  final bool isInterviewer;
  final String content;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        seq: (j['seq'] as num).toInt(),
        isInterviewer: j['role'] == 'interviewer',
        content: (j['content'] as String?) ?? '',
      );
}

@immutable
class ImprovedAnswer {
  const ImprovedAnswer({required this.question, required this.suggestion});

  final String question;
  final String suggestion;

  factory ImprovedAnswer.fromJson(Map<String, dynamic> j) => ImprovedAnswer(
        question: (j['question'] as String?) ?? '',
        suggestion: (j['suggestion'] as String?) ?? '',
      );
}

@immutable
class InterviewFeedback {
  const InterviewFeedback({
    required this.overallScore,
    required this.communicationScore,
    required this.technicalScore,
    required this.relevanceScore,
    required this.strengths,
    required this.weaknesses,
    required this.missedConcepts,
    required this.improvedAnswers,
    required this.nextSteps,
    required this.isAiEstimate,
  });

  final int overallScore;
  final int communicationScore;
  final int technicalScore;
  final int relevanceScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> missedConcepts;
  final List<ImprovedAnswer> improvedAnswers;
  final List<String> nextSteps;
  final bool isAiEstimate;

  factory InterviewFeedback.fromJson(Map<String, dynamic> j) => InterviewFeedback(
        overallScore: (j['overallScore'] as num?)?.toInt() ?? 0,
        communicationScore: (j['communicationScore'] as num?)?.toInt() ?? 0,
        technicalScore: (j['technicalScore'] as num?)?.toInt() ?? 0,
        relevanceScore: (j['relevanceScore'] as num?)?.toInt() ?? 0,
        strengths: _strings(j['strengths']),
        weaknesses: _strings(j['weaknesses']),
        missedConcepts: _strings(j['missedConcepts']),
        improvedAnswers: ((j['improvedAnswers'] as List<dynamic>?) ?? const [])
            .map((e) => ImprovedAnswer.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextSteps: _strings(j['nextSteps']),
        isAiEstimate: (j['isAiEstimate'] as bool?) ?? true,
      );
}

/// Response of create / detail / complete.
@immutable
class InterviewDetail {
  const InterviewDetail({
    required this.interview,
    required this.messages,
    required this.totalQuestions,
    this.feedback,
  });

  final InterviewSummary interview;
  final List<ChatMessage> messages;
  final int totalQuestions;
  final InterviewFeedback? feedback;

  int get answeredCount => messages.where((m) => !m.isInterviewer).length;

  factory InterviewDetail.fromJson(Map<String, dynamic> j) => InterviewDetail(
        interview: InterviewSummary.fromJson(j['interview'] as Map<String, dynamic>),
        messages: ((j['messages'] as List<dynamic>?) ?? const [])
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalQuestions: (j['totalQuestions'] as num?)?.toInt() ?? 0,
        feedback: j['feedback'] == null
            ? null
            : InterviewFeedback.fromJson(j['feedback'] as Map<String, dynamic>),
      );
}

@immutable
class AnswerResult {
  const AnswerResult({
    required this.done,
    required this.messages,
    required this.answered,
    required this.totalQuestions,
  });

  final bool done;
  final List<ChatMessage> messages;
  final int answered;
  final int totalQuestions;

  factory AnswerResult.fromJson(Map<String, dynamic> j) => AnswerResult(
        done: (j['done'] as bool?) ?? false,
        messages: ((j['messages'] as List<dynamic>?) ?? const [])
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
        answered: (j['answered'] as num?)?.toInt() ?? 0,
        totalQuestions: (j['totalQuestions'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class ScoreAverages {
  const ScoreAverages({
    required this.communication,
    required this.technical,
    required this.relevance,
  });

  final int communication;
  final int technical;
  final int relevance;

  factory ScoreAverages.fromJson(Map<String, dynamic> j) => ScoreAverages(
        communication: (j['communication'] as num?)?.toInt() ?? 0,
        technical: (j['technical'] as num?)?.toInt() ?? 0,
        relevance: (j['relevance'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class Progress {
  const Progress({
    required this.interviewCount,
    required this.completedCount,
    required this.recentScores,
    this.averageScore,
    this.averages,
  });

  final int interviewCount;
  final int completedCount;
  final int? averageScore;
  final ScoreAverages? averages;
  final List<int> recentScores;

  factory Progress.fromJson(Map<String, dynamic> j) => Progress(
        interviewCount: (j['interviewCount'] as num?)?.toInt() ?? 0,
        completedCount: (j['completedCount'] as num?)?.toInt() ?? 0,
        averageScore: (j['averageScore'] as num?)?.toInt(),
        averages: j['averages'] == null
            ? null
            : ScoreAverages.fromJson(j['averages'] as Map<String, dynamic>),
        recentScores: ((j['recentScores'] as List<dynamic>?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
      );
}