import 'package:abm_madrasa/core/network/session_store.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final SessionStore _store;

  AuthInterceptor(this._store);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _store.readToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Handle unauthorized (e.g., redirect to login or refresh token)
    }
    return handler.next(err);
  }
}
