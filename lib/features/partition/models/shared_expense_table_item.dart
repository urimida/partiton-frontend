/// 공용 소비 표 한 행 (물품·공과금 공통)
///
/// 물품은 [majorCategory]·[minorCategory]·[detail]로 상품을 표기하고,
/// [name]은 하위 호환·검색용으로 [displayLabel]과 동일하게 유지하는 것을 권장합니다.
class SharedExpenseTableItem {
  final String name;
  final String date;
  final String amount;
  final String? quantity;

  /// 물품 대분류 (예: 식품)
  final String? majorCategory;

  /// 물품 소분류 (예: 시리얼·간식)
  final String? minorCategory;

  /// 물품 구체 표기 (예: 콘프라이트 500g)
  final String? detail;

  /// 앱 정산 플로우 없이 밖에서 정산한 경우 사용자가 표시한 완료 상태
  final bool manuallySettled;

  const SharedExpenseTableItem({
    required this.name,
    required this.date,
    required this.amount,
    this.quantity,
    this.majorCategory,
    this.minorCategory,
    this.detail,
    this.manuallySettled = false,
  });

  /// 표·목록에 쓰는 한 줄 라벨 (구조 필드가 있으면 `대 · 소 · 내용`, 없으면 [name])
  String get displayLabel {
    final m = majorCategory?.trim();
    final s = minorCategory?.trim();
    final d = detail?.trim();
    final hasStructured = (m != null && m.isNotEmpty) ||
        (s != null && s.isNotEmpty) ||
        (d != null && d.isNotEmpty);
    if (!hasStructured) return name;
    return [m, s, d]
        .where((e) => e != null && e!.isNotEmpty)
        .map((e) => e!)
        .join(' · ');
  }

  SharedExpenseTableItem copyWith({
    String? name,
    String? date,
    String? amount,
    String? quantity,
    String? majorCategory,
    String? minorCategory,
    String? detail,
    bool? manuallySettled,
    bool clearMajorCategory = false,
    bool clearMinorCategory = false,
    bool clearDetail = false,
  }) {
    return SharedExpenseTableItem(
      name: name ?? this.name,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
      majorCategory:
          clearMajorCategory ? null : (majorCategory ?? this.majorCategory),
      minorCategory:
          clearMinorCategory ? null : (minorCategory ?? this.minorCategory),
      detail: clearDetail ? null : (detail ?? this.detail),
      manuallySettled: manuallySettled ?? this.manuallySettled,
    );
  }
}
