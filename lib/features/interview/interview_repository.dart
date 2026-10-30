import 'package:dio/dio.dart';

import 'interview_models.dart';

/// AI calls can take a while; the server itself gives up after 30 s.
final _aiOptions = Options(receiveTimeout: const Duration(seconds: 45));

class InterviewRepository {
  InterviewRepository(this._dio);

  final Dio _dio;

  Future<List<InterviewSummary>> list() async {
    final res = await _dio.get<Map<String, dynamic>>('/interviews');
    return (res.data!['interviews'] as List<dynamic>)
        .map((e) => InterviewSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InterviewDetail> create({
    required String targetRole,
    required String interviewType,
    required String difficulty,
    required int durationMinutes,
    String mode = 'text',
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/interviews',
      data: {
        'targetRole': targetRole,
        'interviewType': interviewType,
        'difficulty': difficulty,
        'durationMinutes': durationMinutes,
        'mode': mode,
      },
      options: _aiOptions,
    );
    return InterviewDetail.fromJson(res.data!);
  }

  Future<InterviewDetail> detail(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/interviews/$id');
    return InterviewDetail.fromJson(res.data!);
  }

  Future<AnswerResult> answer(String id, String text) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/interviews/$id/answers',
      data: {'answer': text},
      options: _aiOptions,
    );
    return AnswerResult.fromJson(res.data!);
  }

  Future<InterviewDetail> complete(String id) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/interviews/$id/complete',
      options: _aiOptions,
    );
    return InterviewDetail.fromJson(res.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/interviews/$id');
  }

  Future<Progress> progress() async {
    final res = await _dio.get<Map<String, dynamic>>('/progress');
    return Progress.fromJson(res.data!);
  }
}