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
  /// PATCH 등에 사용. GET 내 정보 조회는 앱에서 호출하지 않음(백엔드 미구현).
  static const String updateUserNameEndpoint = '/users/me';
  /// FCM 디바이스 토큰 등록·갱신 (PATCH JSON `fcmToken`)
  static const String userFcmTokenEndpoint = '/users/me/fcm-token';
  static const String userPreferencesEndpoint = '/users/me/preferences';
  static const String monthlyCalendarEndpoint = '/calendars/monthly';
  static const String dailyCalendarEndpoint = '/calendars/daily';
  static const String schedulesEndpoint = '/schedules';
  static const String scheduleDetailEndpoint = '/schedules/{scheduleId}';
  static const String choresAutoAssignEndpoint = '/chores/auto-assign';
  /// 내 알림 목록 (GET)
  static const String alarmsEndpoint = '/alarms';
  /// 특정 알림 읽음 (PATCH)
  static String alarmsReadPath(int alarmId) => '/alarms/$alarmId/read';
  /// 집안일 완료 여부 수정 (일간 캘린더의 chore id)
  static const String choreDetailEndpoint = '/chores/{choreId}';
  /// 공동 구매(공용 소비) 물품 카테고리 — household 생성 시 시드된 대·소분류
  static const String suppliesCategoriesEndpoint = '/supplies/categories';
  /// 공동 구매 물품 수동 등록
  static const String suppliesPurchasesEndpoint = '/supplies/purchases';
  /// 영수증 이미지 AI 분석 (POST multipart `image`)
  static const String suppliesPurchasesImageEndpoint = '/supplies/purchases/image';
  /// 공용 구매 물품 정산 **목록** 조회 (GET `startDate`·`endDate`)
  static const String suppliesPurchasesSettlementListEndpoint =
      '/supplies/purchases/settlement';
  /// 공용 구매 물품 정산 **요청** — `purchaseIds`, `memberIds`
  static const String suppliesSettlementRequestEndpoint = '/supplies/settlement';

  /// 정산 완료 처리 (PATCH, Path: settlementId)
  static String suppliesSettlementConfirmPath(int settlementId) =>
      '/supplies/settlement/$settlementId/confirm';

  /// 정산 상세 조회 (GET)
  static String suppliesSettlementDetailPath(int settlementId) =>
      '/supplies/settlement/$settlementId';

  /// 공과금 카테고리 조회 (GET)
  static const String billsCategoriesEndpoint = '/bills/categories';
  /// 공과금 목록(GET `startDate`·`endDate`) · 수동 추가(POST)
  static const String billsEndpoint = '/bills';
  /// 공과금 정산 대상 목록 (GET `startDate`·`endDate`)
  static const String billsSettlementListEndpoint = '/bills/settlement/list';
  /// 수정(PATCH)·삭제(DELETE) — `{billId}` 치환
  static String billsBillPath(int billId) => '/bills/$billId';

  /// 예약 목록 조회·예약 등록 (`GET`·`POST`, 쿼리 `startDate`·`endDate` / 본문 `itemId`·시간)
  static const String reservationsEndpoint = '/reservations';

  /// 기간별 집안일·공용소비·예약 리포트·공과금 변동 (GET `startDate`·`endDate`)
  static const String reportsEndpoint = '/reports';

  /// 정산 완료 공용물품·공과금 리포트 (GET `startDate`·`endDate`, yyyy-MM-dd)
  static const String reportsSettlementEndpoint = '/reports/settlement';

  /// 예약 대상 — GET 목록, POST 추가, DELETE 시 본문 `{ itemIds: [...] }`
  static const String reservationsItemsEndpoint = '/reservations/items';
  /// PATCH — `{ name }` 로 단일 예약 대상 수정
  static String reservationsItemPath(int itemId) => '/reservations/items/$itemId';

  // 로컬 저장소 키
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
}

