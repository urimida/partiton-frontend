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
          final code = error.response?.statusCode;
          String errorMessage = '서버 오류가 발생했습니다.';

          if (code == 413) {
            errorMessage =
                '이미지 용량이 서버 한도를 넘었어요. 영수증만 확대해 다시 촬영하거나, '
                '용량이 작은 사진을 선택해 주세요. 계속되면 서버·nginx 업로드 제한을 늘려야 할 수 있어요.';
          } else {
            // 에러 응답 데이터 안전하게 파싱
            try {
              final responseData = error.response?.data;
              if (responseData is Map<String, dynamic>) {
                errorMessage = responseData['message'] as String? ??
                    responseData['error'] as String? ??
                    '서버 오류가 발생했습니다.';
              } else if (responseData is String) {
                final s = responseData.trim();
                // HTML(nginx 오류 페이지 등)이면 본문 대신 코드만
                if (s.startsWith('<!') || s.startsWith('<html')) {
                  errorMessage =
                      '서버 오류가 발생했습니다. (${code ?? '?'})';
                } else {
                  errorMessage = s;
                }
              }
            } catch (e) {
              errorMessage =
                  '서버 오류가 발생했습니다. (${error.response?.statusCode})';
            }
          }

          return ApiException(
            message: errorMessage,
            statusCode: code,
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

