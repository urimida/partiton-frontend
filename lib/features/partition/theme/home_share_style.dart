import 'package:flutter/material.dart';

/// 귀가 공유 UI — 메인(네이비) + 포인트(페일 옐로) + 글래스 패널 톤
abstract final class HomeShareStyle {
  static const Color main = Color(0xFF2C3E50);
  static const Color point = Color(0xFFFEF9D7);

  /// 카드·다이얼로그 글래스 베이스 (블러 위 틴트)
  static Color glassBase([double opacity = 0.88]) => main.withOpacity(opacity);

  /// 온 상태·근처 알림 등 포인트 강조
  static Color pointStroke([double o = 0.38]) => point.withOpacity(o);

  static Color pointFillSoft([double o = 0.14]) => point.withOpacity(o);

  /// 비활성/구조용 메인 스트로크
  static Color mainStroke([double o = 0.28]) => main.withOpacity(o);
}
