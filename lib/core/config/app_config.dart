class AppConfig {
  static const String appName = 'Partition App';
  static const String appVersion = '1.0.0';
  
  // 백엔드 API 설정
  static const String baseUrl = 'http://ec2-3-27-77-244.ap-southeast-2.compute.amazonaws.com/api';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // API 엔드포인트
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String kakaoLoginEndpoint = '/auth/kakao';
  static const String partitionsEndpoint = '/partitions';
  static const String partitionDetailEndpoint = '/partitions/{id}';
  static const String householdsEndpoint = '/households';
  static const String householdsJoinEndpoint = '/households/join';
  static const String updateUserNameEndpoint = '/users/me';
  static const String userPreferencesEndpoint = '/users/me/preferences';
  static const String monthlyCalendarEndpoint = '/calendars/monthly';
  static const String dailyCalendarEndpoint = '/calendars/daily';
  static const String schedulesEndpoint = '/schedules';
  static const String scheduleDetailEndpoint = '/schedules/{scheduleId}';
  static const String choresAutoAssignEndpoint = '/chores/auto-assign';
  
  // 로컬 저장소 키
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
}

