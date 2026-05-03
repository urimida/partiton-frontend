import 'package:flutter/foundation.dart';
import 'package:partition_app/features/partition/models/alarm_model.dart';

/// 알림(알 목록·푸시)에서 **정산 화면**으로 넘길 때 사용하는 일회성 페이로드.
///
/// 문서 흐름: `referenceId`(= settlementId)로 공용소비 정산 UI 이동 → 필요 시 읽음 PATCH.
class AlarmNavPending {
  final int settlementId;
  final AlarmNoticeType noticeType;
  /// 목록에서 탭한 경우 읽음 처리에 사용. 푸시만으로 진입 시 0이면 읽음 생략.
  final int alarmId;

  const AlarmNavPending({
    required this.settlementId,
    required this.noticeType,
    this.alarmId = 0,
  });
}

/// [PartitionMainScreen]이 [setPending]으로 넣고,
/// [PartitionSharedExpenseScreen]이 [takePending] 또는 리스너로 소비합니다.
class AlarmNavigationController extends ChangeNotifier {
  AlarmNavPending? _pending;

  void setPending(AlarmNavPending value) {
    _pending = value;
    notifyListeners();
  }

  /// 한 번만 꺼냅니다. 없으면 `null`.
  AlarmNavPending? takePending() {
    final v = _pending;
    _pending = null;
    return v;
  }
}
