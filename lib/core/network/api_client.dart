import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, Supabase;

import '../config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

String _messageFor(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['error'] is Map) {
    final msg = (data['error'] as Map)['message'];
    if (msg is String && msg.isNotEmpty) return msg;
  }
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return 'Cannot reach the server. Check that the backend is running and you are online.';
    default:
      return 'Something went wrong. Please try again.';
  }
}

/// Turns any error into a short, user-facing message.
String errorMessage(Object e) {
  if (e is DioException && e.error is ApiException) {
    return (e.error as ApiException).message;
  }
  if (e is ApiException) return e.message;
  if (e is AuthException) return e.message;
  return 'Something went wrong. Please try again.';
}

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${AppConfig.apiBaseUrl}/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = Supabase.instance.client.auth.currentSession?.accessToken;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) {
        handler.next(
          e.copyWith(
            error: ApiException(_messageFor(e), statusCode: e.response?.statusCode),
          ),
        );
      },
    ),
  );
  return dio;
});