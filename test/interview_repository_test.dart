import 'dart:convert';
import 'dart:typed_data';

import 'package:careerpulse_ai/features/interview/interview_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final (int, Object?) Function(RequestOptions) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = handler(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _interview = {
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

const _message = {
  'id': 'm1',
  'seq': 1,
  'role': 'interviewer',
  'content': 'Hello! First question?',
  'createdAt': '2026-10-30T10:00:00.000Z',
};

(InterviewRepository, _FakeAdapter) _make((int, Object?) Function(RequestOptions) h) {
  final adapter = _FakeAdapter(h);
  final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))..httpClientAdapter = adapter;
  return (InterviewRepository(dio), adapter);
}

void main() {
  test('list parses the interviews array', () async {
    final (repo, adapter) = _make((_) => (
          200,
          {
            'interviews': [
              {..._interview, 'overallScore': 71},
            ],
          },
        ));
    final items = await repo.list();
    expect(items.single.overallScore, 71);
    expect(adapter.requests.single.path, '/interviews');
    expect(adapter.requests.single.method, 'GET');
  });

  test('create posts the setup and parses the first question', () async {
    final (repo, adapter) = _make((_) => (
          201,
          {
            'interview': _interview,
            'messages': [_message],
            'totalQuestions': 5,
          },
        ));
    final d = await repo.create(
      targetRole: 'Flutter Developer',
      interviewType: 'technical',
      difficulty: 'beginner',
      durationMinutes: 15,
    );
    expect(d.messages.single.content, 'Hello! First question?');
    expect(d.totalQuestions, 5);

    final req = adapter.requests.single;
    expect(req.method, 'POST');
    expect(req.path, '/interviews');
    expect(req.data, {
      'targetRole': 'Flutter Developer',
      'interviewType': 'technical',
      'difficulty': 'beginner',
      'durationMinutes': 15,
      'mode': 'text',
    });
  });

  test('answer posts the text to the interview', () async {
    final (repo, adapter) = _make((_) => (
          200,
          {
            'done': true,
            'messages': <Object>[],
            'answered': 5,
            'totalQuestions': 5,
          },
        ));
    final r = await repo.answer('i1', 'My answer');
    expect(r.done, isTrue);
    expect(adapter.requests.single.path, '/interviews/i1/answers');
    expect(adapter.requests.single.data, {'answer': 'My answer'});
  });

  test('complete and detail hit the right endpoints', () async {
    final (repo, adapter) = _make((_) => (
          200,
          {
            'interview': {..._interview, 'status': 'completed'},
            'messages': [_message],
            'totalQuestions': 5,
            'feedback': null,
          },
        ));
    await repo.complete('i1');
    await repo.detail('i1');
    expect(adapter.requests[0].method, 'POST');
    expect(adapter.requests[0].path, '/interviews/i1/complete');
    expect(adapter.requests[1].method, 'GET');
    expect(adapter.requests[1].path, '/interviews/i1');
  });

  test('delete accepts an empty 204 response', () async {
    final (repo, adapter) = _make((_) => (204, null));
    await repo.delete('i1');
    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.path, '/interviews/i1');
  });

  test('progress parses the summary', () async {
    final (repo, _) = _make((_) => (
          200,
          {
            'interviewCount': 1,
            'completedCount': 1,
            'averageScore': 64,
            'averages': {'communication': 60, 'technical': 70, 'relevance': 60},
            'recentScores': [64],
          },
        ));
    final p = await repo.progress();
    expect(p.averageScore, 64);
    expect(p.recentScores, [64]);
  });

  test('server errors surface as DioException', () async {
    final (repo, _) = _make((_) => (
          503,
          {
            'error': {'code': 'ai_not_configured', 'message': 'AI is not configured'},
          },
        ));
    await expectLater(
      repo.create(
        targetRole: 'x',
        interviewType: 'hr',
        difficulty: 'beginner',
        durationMinutes: 10,
      ),
      throwsA(isA<DioException>()),
    );
  });
}