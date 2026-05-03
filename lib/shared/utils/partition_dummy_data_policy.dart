import 'package:flutter/foundation.dart';

/// 디버그 빌드에서 **미로그인**일 때만 파티션 더미·미리보기 데이터를 사용한다.
/// 릴리스(`kDebugMode == false`)에서는 항상 false → 더미 UI 없음.
/// 로그인 시에도 false → **실제 API·빈 목록만** (월간 합성 폴백 없음).
bool usePartitionDummyData(bool isAuthenticated) {
  return kDebugMode && !isAuthenticated;
}
