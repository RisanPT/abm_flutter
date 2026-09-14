import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;

  factory AppException.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException('The connection timed out. Please try again.', statusCode: 408);
      case DioExceptionType.badResponse:
        final data = dioError.response?.data;
        final serverMsg = (data is Map &&
                data['message'] is String &&
                (data['message'] as String).trim().isNotEmpty)
            ? (data['message'] as String).trim()
            : null;
        return AppException(
          serverMsg ?? _statusMessage(dioError.response?.statusCode),
          statusCode: dioError.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return AppException('Request cancelled.');
      case DioExceptionType.connectionError:
        return AppException('Network error. Please check your internet connection.');
      case DioExceptionType.unknown:
      default:
        // Often a network issue surfaced as "unknown".
        return AppException('Couldn’t reach the server. Please check your connection and try again.');
    }
  }

  static String _statusMessage(int? code) {
    switch (code) {
      case 400:
        return 'The request was invalid. Please check the details and try again.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You don’t have permission to do this.';
      case 404:
        return 'The requested item was not found.';
      case 409:
        return 'This conflicts with existing data.';
      case 500:
      case 502:
      case 503:
        return 'The server had a problem. Please try again shortly.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
