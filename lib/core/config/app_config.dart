class AppConfig {
  static const String appName = 'Partition App';
  static const String appVersion = '1.0.0';
  
  // 백엔드 API 설정
  static const String baseUrl = 'http://localhost:8080/api';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // API 엔드포인트
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String partitionsEndpoint = '/partitions';
  static const String partitionDetailEndpoint = '/partitions/{id}';
  
  // 로컬 저장소 키
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
}

