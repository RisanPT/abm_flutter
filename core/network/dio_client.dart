import 'package:abm_madrasa/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_client.g.dart';

@riverpod
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage();
}

@riverpod
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      // baseUrl: 'https://13.60.186.111.nip.io/api',
      baseUrl: 'http://localhost:5001/api',

      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(ref.watch(secureStorageProvider)),
    LogInterceptor(requestBody: true, responseBody: true),
  ]);

  return dio;
}
