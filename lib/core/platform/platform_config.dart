import 'dart:io';
import 'package:partition_app/core/config/app_config.dart';

class PlatformConfig {
  /// iOS 전용 설정
  static String get baseUrl {
    // iOS 시뮬레이터의 경우 localhost 사용
    if (Platform.isIOS) {
      // 시뮬레이터: localhost
      // 실제 기기: Mac의 IP 주소 또는 백엔드 서버 주소
      return 'http://localhost:8080/api';
      // 실제 기기 테스트 시:
      // return 'http://192.168.x.x:8080/api'; // Mac의 로컬 IP
    }
    return AppConfig.baseUrl;
  }

  /// iOS 네트워크 보안 설정 확인
  /// Info.plist에 ATS(App Transport Security) 설정이 필요할 수 있음
  static bool get allowInsecureConnections {
    // 개발 환경에서만 허용 (프로덕션에서는 false)
    return false;
  }
}

