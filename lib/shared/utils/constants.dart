class AppConstants {
  // 파티션 타입
  static const String partitionTypeDisk = 'disk';
  static const String partitionTypeStorage = 'storage';
  static const String partitionTypeCategory = 'category';

  // 파티션 상태
  static const String partitionStatusActive = 'active';
  static const String partitionStatusInactive = 'inactive';
  static const String partitionStatusPending = 'pending';

  // 페이지 크기
  static const int defaultPageSize = 20;

  // 애니메이션 지속 시간
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}

