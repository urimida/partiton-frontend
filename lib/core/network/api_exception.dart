import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }

  factory ApiException.fromDioError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiException(
            message: '연결 시간이 초과되었습니다.',
            statusCode: error.response?.statusCode,
            originalError: error,
          );
        case DioExceptionType.badResponse:
          return ApiException(
            message: error.response?.data['message'] ?? '서버 오류가 발생했습니다.',
            statusCode: error.response?.statusCode,
            originalError: error,
          );
        case DioExceptionType.cancel:
          return ApiException(
            message: '요청이 취소되었습니다.',
            originalError: error,
          );
        default:
          return ApiException(
            message: '네트워크 오류가 발생했습니다.',
            originalError: error,
          );
      }
    }
    return ApiException(
      message: '알 수 없는 오류가 발생했습니다.',
      originalError: error,
    );
  }
}

