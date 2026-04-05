class AppConfig {
  static const String appName = 'Partition App';
  static const String appVersion = '1.0.0';
  
  // 백엔드 API 설정 (배포)
  static const String baseUrl =
      'http://ec2-52-78-152-123.ap-northeast-2.compute.amazonaws.com/api';
  /// Swagger UI (API 문서)
  static const String swaggerUiUrl =
      'http://ec2-52-78-152-123.ap-northeast-2.compute.amazonaws.com/swagger-ui/index.html';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // API 엔드포인트
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String kakaoLoginEndpoint = '/auth/kakao';
  static const String householdsEndpoint = '/households';
  static const String householdsJoinEndpoint = '/households/join';
  /// 그룹(가구) 멤버 목록 (정산 시 참여자 선택용)
  static const String householdMembersEndpoint = '/households/members';
  static const String updateUserNameEndpoint = '/users/me';
  static const String userPreferencesEndpoint = '/users/me/preferences';
  static const String monthlyCalendarEndpoint = '/calendars/monthly';
  static const String dailyCalendarEndpoint = '/calendars/daily';
  static const String schedulesEndpoint = '/schedules';
  static const String scheduleDetailEndpoint = '/schedules/{scheduleId}';
  static const String choresAutoAssignEndpoint = '/chores/auto-assign';
  /// 집안일 완료 여부 수정 (일간 캘린더의 chore id)
  static const String choreDetailEndpoint = '/chores/{choreId}';
  
  // 로컬 저장소 키
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
}

