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
          String errorMessage = '서버 오류가 발생했습니다.';
          
          // 에러 응답 데이터 안전하게 파싱
          try {
            final responseData = error.response?.data;
            if (responseData is Map<String, dynamic>) {
              errorMessage = responseData['message'] as String? ?? 
                           responseData['error'] as String? ?? 
                           '서버 오류가 발생했습니다.';
            } else if (responseData is String) {
              errorMessage = responseData;
            }
          } catch (e) {
            // 파싱 실패 시 기본 메시지 사용
            errorMessage = '서버 오류가 발생했습니다. (${error.response?.statusCode})';
          }
          
          return ApiException(
            message: errorMessage,
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

