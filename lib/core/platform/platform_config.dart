import 'package:partition_app/core/config/app_config.dart';

class PlatformConfig {
  /// iOS 전용 설정
  static String get baseUrl {
    // 모든 플랫폼에서 백엔드 서버 주소 사용
    return AppConfig.baseUrl;
  }

  /// iOS 네트워크 보안 설정 확인
  /// Info.plist에 ATS(App Transport Security) 설정이 필요할 수 있음
  static bool get allowInsecureConnections {
    // 개발 환경에서만 허용 (프로덕션에서는 false)
    return false;
  }
}

