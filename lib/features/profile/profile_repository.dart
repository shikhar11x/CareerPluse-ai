import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<Profile> fetch() async {
    final res = await _dio.get<Map<String, dynamic>>('/profile');
    return Profile.fromJson(res.data!['profile'] as Map<String, dynamic>);
  }

  Future<Profile> update({
    String? fullName,
    String? education,
    String? targetRole,
    String? experienceLevel,
  }) async {
    final body = <String, dynamic>{
      'fullName': ?fullName,
      'education': ?education,
      'targetRole': ?targetRole,
      'experienceLevel': ?experienceLevel,
    };
    final res = await _dio.patch<Map<String, dynamic>>('/profile', data: body);
    return Profile.fromJson(res.data!['profile'] as Map<String, dynamic>);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);