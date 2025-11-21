import 'package:flutter/foundation.dart';

/// 디버깅을 위한 헬퍼 클래스
class DebugHelper {
  /// print 대신 사용하면 로그 길이 제한 없음
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('$tagStr$message');
    }
  }

  /// JSON 데이터를 보기 좋게 출력
  static void logJson(String tag, Map<String, dynamic> json) {
    if (kDebugMode) {
      debugPrint('[$tag] JSON:');
      json.forEach((key, value) {
        debugPrint('  $key: $value');
      });
    }
  }

  /// API 응답 로깅
  static void logApiResponse(String endpoint, int statusCode, dynamic data) {
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🌐 API Response');
      debugPrint('Endpoint: $endpoint');
      debugPrint('Status: $statusCode');
      debugPrint('Data: $data');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  /// API 요청 로깅
  static void logApiRequest(String method, String endpoint, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📤 API Request');
      debugPrint('Method: $method');
      debugPrint('Endpoint: $endpoint');
      if (data != null) {
        debugPrint('Data: $data');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  /// 에러 로깅
  static void logError(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack: $stackTrace');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  /// 위젯 빌드 로깅
  static void logBuild(String widgetName) {
    if (kDebugMode) {
      debugPrint('🔨 Building: $widgetName');
    }
  }

  /// 상태 변경 로깅
  static void logStateChange(String providerName, String state) {
    if (kDebugMode) {
      debugPrint('🔄 [$providerName] State: $state');
    }
  }
}

