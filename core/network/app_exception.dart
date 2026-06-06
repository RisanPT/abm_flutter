import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() => 'AppException: $message (Status: $statusCode)';

  factory AppException.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
        return AppException('Connection timeout', statusCode: 408);
      case DioExceptionType.sendTimeout:
        return AppException('Send timeout', statusCode: 408);
      case DioExceptionType.receiveTimeout:
        return AppException('Receive timeout', statusCode: 408);
      case DioExceptionType.badResponse:
        final message = dioError.response?.data?['message'] ?? 'Unexpected server error';
        return AppException(message, statusCode: dioError.response?.statusCode);
      case DioExceptionType.cancel:
        return AppException('Request cancelled');
      case DioExceptionType.connectionError:
        return AppException('Connection error');
      case DioExceptionType.unknown:
        return AppException('Unknown error');
      default:
        return AppException('Something went wrong');
    }
  }
}
