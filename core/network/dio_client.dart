import 'package:abm_madrasa/core/network/auth_interceptor.dart';
import 'package:abm_madrasa/core/network/interceptors/error_interceptor.dart';
import 'package:abm_madrasa/core/network/session_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_client.g.dart';

/// API base URL. Compile-time overridable per deployment/tenant with
/// `--dart-define=API_BASE_URL=https://api.<school>.com/api`; defaults to the
/// current production API when not provided.
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5001/api', // change from production URL
);


@riverpod
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage();
}

@riverpod
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref.watch(sessionStoreProvider)));

  // Verbose request/response logging (which includes credentials and PII) is
  // for debugging only — never in release builds.
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  // Normalises every DioException into a human-readable message (surfacing the
  // server's own `message`), so the whole app can show real errors.
  dio.interceptors.add(ErrorInterceptor());

  return dio;
}
