// 공용 소비 물품 등록 API용 입력 파싱 (로컬 검증 + 서버 형식)

/// `yyyy-MM-dd` 또는 `yy.MM.dd.` / `yyyy.MM.dd.` 형태를 `yyyy-MM-dd`로 변환. 실패 시 null.
String? tryParsePurchaseDateToIso(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;

  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  final mIso = iso.firstMatch(s);
  if (mIso != null) return s;

  final dot = RegExp(r'^(\d{2,4})\.(\d{1,2})\.(\d{1,2})\.?$');
  final mDot = dot.firstMatch(s);
  if (mDot != null) {
    var y = int.tryParse(mDot.group(1)!);
    final mo = int.tryParse(mDot.group(2)!);
    final d = int.tryParse(mDot.group(3)!);
    if (y == null || mo == null || d == null) return null;
    if (y < 100) y += 2000;
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    return '${y.toString().padLeft(4, '0')}-'
        '${mo.toString().padLeft(2, '0')}-'
        '${d.toString().padLeft(2, '0')}';
  }

  return null;
}

/// 금액 문자열에서 숫자만 추출해 원 단위 정수로. 없으면 null.
int? tryParseWonAmount(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

/// 수량 문자열에서 숫자만 추출. 없으면 null.
int? tryParseItemQuantity(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

/// API `yyyy-MM-dd` → 표시용 `yy.MM.dd.`
String displayDateFromIso(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return iso;
  final y = int.tryParse(p[0]);
  final mo = p[1];
  final d = p[2];
  if (y == null) return iso;
  final yy = y % 100;
  return '${yy.toString().padLeft(2, '0')}.$mo.$d.';
}

String formatAmountWithWon(int won) {
  final s = won.toString();
  final buf = StringBuffer();
  for (var i = s.length - 1; i >= 0; i--) {
    buf.write(s[i]);
    final posFromRight = s.length - i;
    if (i > 0 && posFromRight % 3 == 0) buf.write(',');
  }
  return '${buf.toString().split('').reversed.join()}원';
}
