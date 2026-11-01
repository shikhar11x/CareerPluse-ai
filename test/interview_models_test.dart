import 'package:careerpulse_ai/features/interview/interview_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _interviewJson = {
  'id': 'i1',
  'targetRole': 'Flutter Developer',
  'interviewType': 'technical',
  'difficulty': 'beginner',
  'durationMinutes': 15,
  'mode': 'text',
  'status': 'in_progress',
  'startedAt': '2026-10-30T10:00:00.000Z',
  'completedAt': null,
};

Map<String, dynamic> _msg(int seq, String role, String text) => {
      'id': 'm$seq',
      'seq': seq,
      'role': role,
      'content': text,
      'createdAt': '2026-10-30T10:00:00.000Z',
    };

void main() {
  group('questionCount', () {
    test('matches the server: about one question per 3 minutes, 3 to 12', () {
      expect(questionCount(5), 3);
      expect(questionCount(10), 3);
      expect(questionCount(15), 5);
      expect(questionCount(30), 10);
      expect(questionCount(60), 12);
    });
  });

  group('InterviewSummary', () {
    test('parses fields and builds labels', () {
      final s = InterviewSummary.fromJson(_interviewJson);
      expect(s.id, 'i1');
      expect(s.typeLabel, 'Technical');
      expect(s.difficultyLabel, 'Beginner');
      expect(s.isCompleted, isFalse);
      expect(s.completedAt, isNull);
      expect(s.overallScore, isNull);
      expect(s.startedAt.isUtc, isTrue);
    });

    test('reads score and completion', () {
      final s = InterviewSummary.fromJson({
        ..._interviewJson,
        'status': 'completed',
        'completedAt': '2026-10-30T10:20:00.000Z',
        'overallScore': 72,
      });
      expect(s.isCompleted, isTrue);
      expect(s.overallScore, 72);
      expect(s.completedAt, isNotNull);
    });

    test('falls back to the raw value for unknown labels', () {
      final s = InterviewSummary.fromJson({
        ..._interviewJson,
        'interviewType': 'weird',
        'difficulty': 'brutal',
      });
      expect(s.typeLabel, 'weird');
      expect(s.difficultyLabel, 'brutal');
    });
  });

  group('InterviewDetail', () {
    test('parses messages and counts answers', () {
      final d = InterviewDetail.fromJson({
        'interview': _interviewJson,
        'messages': [
          _msg(1, 'interviewer', 'Q1?'),
          _msg(2, 'candidate', 'A1'),
          _msg(3, 'interviewer', 'Q2?'),
        ],
        'totalQuestions': 5,
        'feedback': null,
      });
      expect(d.messages, hasLength(3));
      expect(d.messages.first.isInterviewer, isTrue);
      expect(d.messages[1].isInterviewer, isFalse);
      expect(d.answeredCount, 1);
      expect(d.totalQuestions, 5);
      expect(d.feedback, isNull);
    });

    test('parses feedback when present', () {
      final d = InterviewDetail.fromJson({
        'interview': _interviewJson,
        'messages': <Object>[],
        'totalQuestions': 3,
        'feedback': {
          'overallScore': 70,
          'communicationScore': 80,
          'technicalScore': 70,
          'relevanceScore': 60,
          'strengths': ['Clear'],
          'weaknesses': ['Short'],
          'missedConcepts': ['State'],
          'improvedAnswers': [
            {'question': 'Q1', 'suggestion': 'Better'},
          ],
          'nextSteps': ['Practise'],
          'isAiEstimate': true,
        },
      });
      final f = d.feedback!;
      expect(f.overallScore, 70);
      expect(f.improvedAnswers.single.suggestion, 'Better');
      expect(f.isAiEstimate, isTrue);
    });
  });

  group('InterviewFeedback', () {
    test('defaults are safe when the server omits fields', () {
      final f = InterviewFeedback.fromJson(const {});
      expect(f.overallScore, 0);
      expect(f.strengths, isEmpty);
      expect(f.improvedAnswers, isEmpty);
      expect(f.isAiEstimate, isTrue); // never claim an estimate is a fact
    });
  });

  group('AnswerResult', () {
    test('parses done flag and new messages', () {
      final r = AnswerResult.fromJson({
        'done': false,
        'messages': [_msg(2, 'candidate', 'A1'), _msg(3, 'interviewer', 'Q2?')],
        'answered': 1,
        'totalQuestions': 3,
      });
      expect(r.done, isFalse);
      expect(r.messages, hasLength(2));
      expect(r.answered, 1);
    });
  });

  group('Progress', () {
    test('handles a user with no completed interviews', () {
      final p = Progress.fromJson({
        'interviewCount': 2,
        'completedCount': 0,
        'averageScore': null,
        'averages': null,
        'recentScores': <int>[],
      });
      expect(p.interviewCount, 2);
      expect(p.averageScore, isNull);
      expect(p.averages, isNull);
      expect(p.recentScores, isEmpty);
    });

    test('parses averages and the score trend', () {
      final p = Progress.fromJson({
        'interviewCount': 3,
        'completedCount': 2,
        'averageScore': 70,
        'averages': {'communication': 75, 'technical': 65, 'relevance': 70},
        'recentScores': [60, 80],
      });
      expect(p.averageScore, 70);
      expect(p.averages!.technical, 65);
      expect(p.recentScores, [60, 80]);
    });
  });
}