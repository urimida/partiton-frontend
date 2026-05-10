import 'package:partition_app/features/partition/models/shared_expense_table_item.dart';
import 'package:partition_app/features/partition/models/supply_purchase_model.dart';
import 'package:partition_app/features/partition/utils/supply_purchase_input.dart';

/// 해당 연·월에서 `payDay`에 맞는 달력상 납부일 (말일 초과 시 말일로 보정)
DateTime utilityBillCalendarDueInMonth(int year, int month, int payDayRaw) {
  final p = payDayRaw.clamp(1, 31);
  final dim = DateTime(year, month + 1, 0).day;
  final d = p > dim ? dim : p;
  return DateTime(year, month, d);
}

/// `reference` 기준 다음 납부일(당일이 납부일이면 당일)
DateTime utilityBillNextDueDate(DateTime reference, int payDayRaw) {
  final t = DateTime(reference.year, reference.month, reference.day);
  var y = t.year;
  var m = t.month;
  var due = utilityBillCalendarDueInMonth(y, m, payDayRaw);
  if (due.isBefore(t)) {
    if (m == 12) {
      y++;
      m = 1;
    } else {
      m++;
    }
    due = utilityBillCalendarDueInMonth(y, m, payDayRaw);
  }
  return due;
}

/// 다음 납부일까지 남은 일수 (0 = 당일 납부)
int utilityBillDaysUntilDue(DateTime reference, int payDayRaw) {
  final t = DateTime(reference.year, reference.month, reference.day);
  final next = utilityBillNextDueDate(t, payDayRaw);
  return next.difference(t).inDays;
}

/// 표 납부일 열 — `매달 22일` 형식
String utilityBillRelativeDueLabel(DateTime reference, int payDayRaw) {
  return '매달 ${payDayRaw}일';
}

/// 목록·상세 `status` → 정산 완료 여부 (물품 구매와 동일 패턴)
bool utilityBillSettledFromJson(Map<String, dynamic> json) {
  final st = json['status'];
  if (st == null) return false;
  if (st is bool) return st;
  if (st is num) return st != 0;
  if (st is String) {
    final u = st.toUpperCase().trim();
    if (u == 'SETTLED' ||
        u == 'SETTLE' ||
        u == 'COMPLETED' ||
        u == 'COMPLETE' ||
        u == 'DONE') {
      return true;
    }
  }
  return false;
}

/// GET /api/bills/categories 항목
class UtilityBillCategory {
  final String category;
  final String categoryName;

  const UtilityBillCategory({
    required this.category,
    required this.categoryName,
  });

  factory UtilityBillCategory.fromJson(Map<String, dynamic> json) {
    return UtilityBillCategory(
      category: json['category'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
    );
  }

  /// 카테고리 API 실패 시 폴백 (명세 Enum)
  static const List<UtilityBillCategory> fallbackCategories = [
    UtilityBillCategory(category: 'WATER', categoryName: '수도세'),
    UtilityBillCategory(category: 'ELECTRICITY', categoryName: '전기세'),
    UtilityBillCategory(category: 'GAS', categoryName: '가스비'),
    UtilityBillCategory(category: 'INTERNET', categoryName: '인터넷'),
    UtilityBillCategory(category: 'OTT', categoryName: 'OTT'),
    UtilityBillCategory(category: 'RENT', categoryName: '월세'),
    UtilityBillCategory(category: 'LOAN_INTEREST', categoryName: '대출이자'),
    UtilityBillCategory(category: 'ETC', categoryName: '기타'),
  ];
}

/// POST `/api/bills` 및 PATCH `/api/bills/{billId}` 성공 시 `result`
class UtilityBillCreateResult {
  final int billId;
  final String utilityType;
  final String utilityTypeName;
  final int payDay;
  final int amount;
  final String? note;
  final String? status;
  final String? createdAt;

  const UtilityBillCreateResult({
    required this.billId,
    required this.utilityType,
    required this.utilityTypeName,
    required this.payDay,
    required this.amount,
    this.note,
    this.status,
    this.createdAt,
  });

  factory UtilityBillCreateResult.fromJson(Map<String, dynamic> json) {
    var payDay = (json['payDay'] as num?)?.toInt() ?? 0;
    if (payDay < 1 || payDay > 31) {
      final legacy =
          json['dueDate'] as String? ?? json['date'] as String? ?? '';
      final dt = DateTime.tryParse(legacy);
      if (dt != null) {
        payDay = dt.day;
      } else {
        payDay = 1;
      }
    }
    final type = json['utilityType'] as String? ??
        json['billType'] as String? ??
        '';
    final typeName = json['utilityTypeName'] as String? ??
        json['billTypeName'] as String? ??
        '';
    return UtilityBillCreateResult(
      billId: (json['billId'] as num?)?.toInt() ?? 0,
      utilityType: type,
      utilityTypeName: typeName,
      payDay: payDay.clamp(1, 31),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
      status: json['status'] is String ? json['status'] as String : null,
      createdAt: json['createdAt'] as String?,
    );
  }
}

/// GET /api/bills `result[]`
class UtilityBillListItem {
  final int billId;
  final String utilityType;
  final String utilityTypeName;
  /// API `payDay` (매달 이 날 결제)
  final int payDay;
  final int amount;
  final String? note;
  final String? status;
  /// 구 응답 (`date`/`dueDate`) 대비
  final String? legacyDueIso;

  const UtilityBillListItem({
    required this.billId,
    required this.utilityType,
    required this.utilityTypeName,
    required this.payDay,
    required this.amount,
    this.note,
    this.status,
    this.legacyDueIso,
  });

  factory UtilityBillListItem.fromJson(Map<String, dynamic> json) {
    final type =
        json['utilityType'] as String? ?? json['billType'] as String? ?? '';
    final typeName = json['utilityTypeName'] as String? ??
        json['billTypeName'] as String? ??
        type;
    var payDay = (json['payDay'] as num?)?.toInt() ?? 0;
    final legacyRaw =
        json['date'] as String? ?? json['dueDate'] as String? ?? '';
    if (payDay < 1 || payDay > 31) {
      final dt = DateTime.tryParse(legacyRaw);
      if (dt != null) {
        payDay = dt.day.clamp(1, 31);
      } else {
        payDay = 1;
      }
    } else {
      payDay = payDay.clamp(1, 31);
    }
    return UtilityBillListItem(
      billId: (json['billId'] as num?)?.toInt() ?? 0,
      utilityType: type,
      utilityTypeName: typeName,
      payDay: payDay,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
      status: json['status'] is String ? json['status'] as String : null,
      legacyDueIso: legacyRaw.isNotEmpty ? legacyRaw : null,
    );
  }

  SharedExpenseTableItem toSharedExpenseTableItem({DateTime? referenceDate}) {
    final noteTrim = note?.trim();
    final qty = (noteTrim != null && noteTrim.isNotEmpty) ? noteTrim : null;
    final settled = utilityBillSettledFromJson({
      'status': status,
    });
    final ref = referenceDate ?? DateTime.now();
    final dateLabel =
        utilityBillRelativeDueLabel(ref, payDay);
    return SharedExpenseTableItem(
      name: utilityTypeName.isNotEmpty ? utilityTypeName : utilityType,
      date: dateLabel,
      amount: formatAmountWithWon(amount),
      quantity: qty,
      manuallySettled: settled,
      billId: billId,
      utilityTypeEnum: utilityType,
      utilityDueDateIso: legacyDueIso,
      utilityPayDay: payDay,
    );
  }
}

/// GET `/api/bills/settlement/list` 응답의 `result` 및 `bills[]`
class UtilityBillSettlementSummary {
  final int totalCount;
  final int totalAmount;
  final int memberCount;
  final int amountPerMember;
  final int remainder;
  final List<UtilityBillSettlementLine> bills;

  const UtilityBillSettlementSummary({
    required this.totalCount,
    required this.totalAmount,
    required this.memberCount,
    required this.amountPerMember,
    required this.remainder,
    required this.bills,
  });

  factory UtilityBillSettlementSummary.fromJson(Map<String, dynamic> json) {
    final rawList = json['bills'];
    final list = rawList is List
        ? rawList
            .map((e) => UtilityBillSettlementLine.fromJson(
                  e as Map<String, dynamic>,
                ))
            .toList()
        : <UtilityBillSettlementLine>[];
    return UtilityBillSettlementSummary(
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      amountPerMember: (json['amountPerMember'] as num?)?.toInt() ?? 0,
      remainder: (json['remainder'] as num?)?.toInt() ?? 0,
      bills: list,
    );
  }
}

class UtilityBillSettlementLine {
  final int billId;
  final String utilityTypeName;
  final String dueDate;
  final int amount;
  final String? note;

  const UtilityBillSettlementLine({
    required this.billId,
    required this.utilityTypeName,
    required this.dueDate,
    required this.amount,
    this.note,
  });

  factory UtilityBillSettlementLine.fromJson(Map<String, dynamic> json) {
    final due = json['dueDate'] as String? ?? '';
    return UtilityBillSettlementLine(
      billId: (json['billId'] as num?)?.toInt() ?? 0,
      utilityTypeName:
          json['utilityTypeName'] as String? ?? json['name'] as String? ?? '',
      dueDate: due,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
    );
  }

  /// 정산 선택 UI용 — 해당 기간 마감일(`dueDate`) 기준 표시
  SharedExpenseTableItem toSharedExpenseTableItem() {
    final noteTrim = note?.trim();
    final qty = (noteTrim != null && noteTrim.isNotEmpty) ? noteTrim : null;
    var iso = dueDate.trim();
    if (iso.contains('T')) {
      iso = iso.split('T').first;
    }
    if (iso.length > 10) {
      iso = iso.substring(0, 10);
    }
    final dt = DateTime.tryParse(iso);
    return SharedExpenseTableItem(
      name: utilityTypeName,
      date: displayDateFromIso(iso),
      amount: formatAmountWithWon(amount),
      quantity: qty,
      billId: billId,
      utilityDueDateIso: iso,
      utilityPayDay: dt?.day,
    );
  }
}

/// POST `/api/bills/settlement` 성공 시 `result.items[]`
class BillSettlementShareItem {
  final int billId;
  final String utilityTypeName;
  final int amount;

  const BillSettlementShareItem({
    required this.billId,
    required this.utilityTypeName,
    required this.amount,
  });

  factory BillSettlementShareItem.fromJson(Map<String, dynamic> json) {
    final name = json['utilityTypeName'] as String? ??
        json['itemName'] as String? ??
        json['name'] as String? ??
        '';
    return BillSettlementShareItem(
      billId: (json['billId'] as num?)?.toInt() ?? 0,
      utilityTypeName: name,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// POST `/api/bills/settlement` 성공 시 `result`
class BillSettlementRequestResult {
  final int settlementId;
  final int totalAmount;
  final int memberCount;
  final int amountPerMember;
  final String settledAt;
  final List<SettlementShareMember> members;
  final List<BillSettlementShareItem> items;

  const BillSettlementRequestResult({
    required this.settlementId,
    required this.totalAmount,
    required this.memberCount,
    required this.amountPerMember,
    required this.settledAt,
    required this.members,
    required this.items,
  });

  factory BillSettlementRequestResult.fromJson(Map<String, dynamic> json) {
    final rawM = json['members'];
    final rawI = json['items'];
    final members = <SettlementShareMember>[];
    final items = <BillSettlementShareItem>[];
    if (rawM is List) {
      for (final e in rawM) {
        if (e is Map<String, dynamic>) {
          members.add(SettlementShareMember.fromJson(e));
        }
      }
    }
    if (rawI is List) {
      for (final e in rawI) {
        if (e is Map<String, dynamic>) {
          items.add(BillSettlementShareItem.fromJson(e));
        }
      }
    }
    return BillSettlementRequestResult(
      settlementId: (json['settlementId'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      amountPerMember: (json['amountPerMember'] as num?)?.toInt() ?? 0,
      settledAt: json['settledAt']?.toString() ?? '',
      members: members,
      items: items,
    );
  }
}

bool _billSettlementIsConfirmedField(dynamic ic) {
  if (ic is bool) return ic;
  if (ic is num) return ic != 0;
  if (ic is String) {
    final u = ic.toUpperCase();
    return u == 'TRUE' || u == '1' || u == 'YES';
  }
  return false;
}

/// GET `/api/bills/settlement/{settlementId}` 성공 시 `result` (공용 물품 정산 상세와 동일 필드)
class BillSettlementDetailResult {
  final int settlementId;
  final int totalAmount;
  final int amountPerMember;
  final int memberCount;
  final bool isConfirmed;
  final String? confirmedAt;
  final List<SettlementShareMember> members;
  final List<BillSettlementShareItem> items;

  const BillSettlementDetailResult({
    required this.settlementId,
    required this.totalAmount,
    required this.amountPerMember,
    required this.memberCount,
    required this.isConfirmed,
    this.confirmedAt,
    required this.members,
    required this.items,
  });

  factory BillSettlementDetailResult.fromJson(Map<String, dynamic> json) {
    final rawM = json['members'];
    final rawI = json['items'];
    final members = <SettlementShareMember>[];
    final items = <BillSettlementShareItem>[];
    if (rawM is List) {
      for (final e in rawM) {
        if (e is Map<String, dynamic>) {
          members.add(SettlementShareMember.fromJson(e));
        }
      }
    }
    if (rawI is List) {
      for (final e in rawI) {
        if (e is Map<String, dynamic>) {
          items.add(BillSettlementShareItem.fromJson(e));
        }
      }
    }
    return BillSettlementDetailResult(
      settlementId: (json['settlementId'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      amountPerMember: (json['amountPerMember'] as num?)?.toInt() ?? 0,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      isConfirmed: _billSettlementIsConfirmedField(json['isConfirmed']),
      confirmedAt: json['confirmedAt'] as String?,
      members: members,
      items: items,
    );
  }
}

/// PATCH `/api/bills/settlement/{id}/confirm` 성공 시 `result`
class BillSettlementConfirmResult {
  final int settlementId;
  final int totalAmount;
  final int memberCount;
  final int amountPerMember;
  final String confirmedAt;
  final List<SettlementShareMember> members;
  final List<BillSettlementShareItem> items;

  const BillSettlementConfirmResult({
    required this.settlementId,
    required this.totalAmount,
    required this.memberCount,
    required this.amountPerMember,
    required this.confirmedAt,
    required this.members,
    required this.items,
  });

  factory BillSettlementConfirmResult.fromJson(Map<String, dynamic> json) {
    final rawM = json['members'];
    final rawI = json['items'];
    final members = <SettlementShareMember>[];
    final items = <BillSettlementShareItem>[];
    if (rawM is List) {
      for (final e in rawM) {
        if (e is Map<String, dynamic>) {
          members.add(SettlementShareMember.fromJson(e));
        }
      }
    }
    if (rawI is List) {
      for (final e in rawI) {
        if (e is Map<String, dynamic>) {
          items.add(BillSettlementShareItem.fromJson(e));
        }
      }
    }
    return BillSettlementConfirmResult(
      settlementId: (json['settlementId'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      amountPerMember: (json['amountPerMember'] as num?)?.toInt() ?? 0,
      confirmedAt: json['confirmedAt']?.toString() ?? '',
      members: members,
      items: items,
    );
  }
}
