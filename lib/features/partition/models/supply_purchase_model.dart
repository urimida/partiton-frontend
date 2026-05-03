import 'package:partition_app/features/partition/models/shared_expense_table_item.dart';
import 'package:partition_app/features/partition/models/supply_category_model.dart';
import 'package:partition_app/features/partition/utils/supply_purchase_input.dart';

/// 서버가 bool / 0·1 / "true" 등으로 줄 때 대응
bool _supplyPurchaseJsonBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final s = value.toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'y') return true;
    if (s == 'false' || s == '0' || s == 'no' || s == 'n') return false;
  }
  return fallback;
}

/// GET 목록: `isSettled` → **`status`** (API 명세). 응답이 구형 필드일 때는 하위 호환.
bool _settledFromPurchaseListJson(Map<String, dynamic> json) {
  final st = json['status'];
  if (st == null) {
    final legacy = json['isSettled'] ??
        json['is_settled'] ??
        json['settled'] ??
        json['settlementCompleted'];
    return _supplyPurchaseJsonBool(legacy, fallback: false);
  }
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
    if (u == 'PENDING' ||
        u == 'UNSETTLED' ||
        u == 'NOT_SETTLED' ||
        u == 'IN_PROGRESS' ||
        u == 'NONE') {
      return false;
    }
  }
  return _supplyPurchaseJsonBool(st, fallback: false);
}

/// GET /api/supplies/purchases `result.purchases` 항목 (카테고리는 응답에 없을 수 있음)
class SupplyPurchaseListItem {
  final int purchaseId;
  final String itemName;
  final String purchaseDate;
  final int amount;
  final int quantity;
  /// 서버: `isSettled` → `status` (문자/불 응답)
  final String? status;
  final bool isSettled;
  final String? category;
  final String? subCategory;

  const SupplyPurchaseListItem({
    required this.purchaseId,
    required this.itemName,
    required this.purchaseDate,
    required this.amount,
    required this.quantity,
    this.status,
    required this.isSettled,
    this.category,
    this.subCategory,
  });

  factory SupplyPurchaseListItem.fromJson(Map<String, dynamic> json) {
    return SupplyPurchaseListItem(
      purchaseId: (json['purchaseId'] as num?)?.toInt() ?? 0,
      itemName: json['itemName'] as String? ?? '',
      purchaseDate: json['purchaseDate'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      status: json['status'] is String
          ? json['status'] as String
          : (json['status'] != null ? json['status'].toString() : null),
      isSettled: _settledFromPurchaseListJson(json),
      category: json['category'] as String?,
      subCategory: json['subCategory'] as String?,
    );
  }

  /// 표 한 줄로 변환. 카테고리 enum이 있으면 [kDefaultSupplyCategoryGroups]로 한글 라벨 시도.
  SharedExpenseTableItem toSharedExpenseTableItem() {
    String? major;
    String? minor;
    String? detail;
    final cc = category?.trim();
    final sc = subCategory?.trim();
    if (cc != null && cc.isNotEmpty) {
      for (final g in kDefaultSupplyCategoryGroups) {
        if (g.category == cc) {
          major = g.categoryName;
          if (sc != null && sc.isNotEmpty) {
            for (final sub in g.subCategories) {
              if (sub.subCategory == sc) {
                minor = sub.subCategoryName;
                break;
              }
            }
          }
          break;
        }
      }
    }

    final hasStructured =
        major != null && major.isNotEmpty && itemName.isNotEmpty;
    if (hasStructured) {
      detail = itemName;
    }

    final composedName = hasStructured
        ? [
            major,
            if (minor != null && minor.isNotEmpty) minor,
            itemName,
          ].join(' · ')
        : itemName;

    return SharedExpenseTableItem(
      name: composedName,
      date: displayDateFromIso(purchaseDate),
      amount: formatAmountWithWon(amount),
      quantity: '$quantity개',
      majorCategory: major,
      minorCategory: minor,
      detail: detail,
      manuallySettled: isSettled,
      purchaseId: purchaseId,
      categoryCode: cc,
      subCategoryCode: sc,
    );
  }
}

/// GET /api/supplies/purchases 성공 시 `result` 객체
class SupplyPurchasesListResult {
  final int totalCount;
  final List<SupplyPurchaseListItem> purchases;

  const SupplyPurchasesListResult({
    required this.totalCount,
    required this.purchases,
  });

  factory SupplyPurchasesListResult.fromJson(Map<String, dynamic> json) {
    final raw = json['purchases'];
    final list = <SupplyPurchaseListItem>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(SupplyPurchaseListItem.fromJson(e));
        }
      }
    }
    return SupplyPurchasesListResult(
      totalCount: (json['totalCount'] as num?)?.toInt() ?? list.length,
      purchases: list,
    );
  }
}

/// POST /api/supplies/purchases 성공 시 `result`
class SupplyPurchaseResult {
  final int purchaseId;
  final String itemName;
  final String purchaseDate;
  final int amount;
  final int quantity;
  final String category;
  final String subCategory;
  final String? createdAt;
  /// PATCH 수정 응답에 포함될 수 있음
  final String? updatedAt;

  const SupplyPurchaseResult({
    required this.purchaseId,
    required this.itemName,
    required this.purchaseDate,
    required this.amount,
    required this.quantity,
    required this.category,
    required this.subCategory,
    this.createdAt,
    this.updatedAt,
  });

  factory SupplyPurchaseResult.fromJson(Map<String, dynamic> json) {
    return SupplyPurchaseResult(
      purchaseId: (json['purchaseId'] as num?)?.toInt() ?? 0,
      itemName: json['itemName'] as String? ?? '',
      purchaseDate: json['purchaseDate'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? '',
      subCategory: json['subCategory'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

int? _receiptIntField(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final d = v.replaceAll(RegExp(r'[^\d]'), '');
    if (d.isEmpty) return null;
    return int.tryParse(d);
  }
  return null;
}

/// POST `/supplies/purchases/image` 성공 시 `result.items` 한 줄
class ReceiptRecognizedItem {
  final String itemName;
  final String? purchaseDate;
  final int? amount;
  final int? quantity;
  final String? category;
  final String? subCategory;

  const ReceiptRecognizedItem({
    required this.itemName,
    this.purchaseDate,
    this.amount,
    this.quantity,
    this.category,
    this.subCategory,
  });

  factory ReceiptRecognizedItem.fromJson(Map<String, dynamic> json) {
    return ReceiptRecognizedItem(
      itemName: json['itemName'] as String? ?? '',
      purchaseDate: json['purchaseDate'] as String?,
      amount: _receiptIntField(json['amount']),
      quantity: _receiptIntField(json['quantity']),
      category: json['category'] as String?,
      subCategory: json['subCategory'] as String?,
    );
  }
}

/// POST `/supplies/purchases/image` 파싱 결과
class ReceiptImageAnalysisResult {
  final List<ReceiptRecognizedItem> items;

  const ReceiptImageAnalysisResult({required this.items});

  factory ReceiptImageAnalysisResult.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final list = <ReceiptRecognizedItem>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(ReceiptRecognizedItem.fromJson(e));
        }
      }
    }
    return ReceiptImageAnalysisResult(items: list);
  }
}

// --- 정산 API (`/supplies/settlement`) ---

class SettlementShareMember {
  final int userId;
  final String name;
  final int amount;

  const SettlementShareMember({
    required this.userId,
    required this.name,
    required this.amount,
  });

  factory SettlementShareMember.fromJson(Map<String, dynamic> json) {
    return SettlementShareMember(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}

class SettlementShareItem {
  final int purchaseId;
  final String itemName;
  final int amount;

  const SettlementShareItem({
    required this.purchaseId,
    required this.itemName,
    required this.amount,
  });

  factory SettlementShareItem.fromJson(Map<String, dynamic> json) {
    return SettlementShareItem(
      purchaseId: (json['purchaseId'] as num?)?.toInt() ?? 0,
      itemName: json['itemName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// POST `/supplies/settlement` 성공 시 `result`
class SupplySettlementRequestResult {
  final int settlementId;
  final int totalAmount;
  final int memberCount;
  final int amountPerMember;
  final String settledAt;
  final List<SettlementShareMember> members;
  final List<SettlementShareItem> items;

  const SupplySettlementRequestResult({
    required this.settlementId,
    required this.totalAmount,
    required this.memberCount,
    required this.amountPerMember,
    required this.settledAt,
    required this.members,
    required this.items,
  });

  factory SupplySettlementRequestResult.fromJson(Map<String, dynamic> json) {
    final rawM = json['members'];
    final rawI = json['items'];
    final members = <SettlementShareMember>[];
    final items = <SettlementShareItem>[];
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
          items.add(SettlementShareItem.fromJson(e));
        }
      }
    }
    return SupplySettlementRequestResult(
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

/// PATCH `/supplies/settlement/{id}/confirm` 성공 시 `result`
class SupplySettlementConfirmResult {
  final int settlementId;
  final int totalAmount;
  final int memberCount;
  final int amountPerMember;
  final String confirmedAt;
  final List<SettlementShareMember> members;
  final List<SettlementShareItem> items;

  const SupplySettlementConfirmResult({
    required this.settlementId,
    required this.totalAmount,
    required this.memberCount,
    required this.amountPerMember,
    required this.confirmedAt,
    required this.members,
    required this.items,
  });

  factory SupplySettlementConfirmResult.fromJson(Map<String, dynamic> json) {
    final rawM = json['members'];
    final rawI = json['items'];
    final members = <SettlementShareMember>[];
    final items = <SettlementShareItem>[];
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
          items.add(SettlementShareItem.fromJson(e));
        }
      }
    }
    return SupplySettlementConfirmResult(
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

/// GET `/supplies/settlement/{id}` 의 `items` 한 줄 (`purchaseDate` 포함)
class SettlementDetailLineItem {
  final int purchaseId;
  final String itemName;
  final String? purchaseDate;
  final int amount;

  const SettlementDetailLineItem({
    required this.purchaseId,
    required this.itemName,
    this.purchaseDate,
    required this.amount,
  });

  factory SettlementDetailLineItem.fromJson(Map<String, dynamic> json) {
    return SettlementDetailLineItem(
      purchaseId: (json['purchaseId'] as num?)?.toInt() ?? 0,
      itemName: json['itemName'] as String? ?? '',
      purchaseDate: json['purchaseDate'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// GET `/supplies/settlement/{settlementId}` 성공 시 `result`
class SupplySettlementDetailResult {
  final int settlementId;
  final int totalAmount;
  final int amountPerMember;
  final int memberCount;
  final bool isConfirmed;
  final String? confirmedAt;
  final List<SettlementShareMember> members;
  final List<SettlementDetailLineItem> items;

  const SupplySettlementDetailResult({
    required this.settlementId,
    required this.totalAmount,
    required this.amountPerMember,
    required this.memberCount,
    required this.isConfirmed,
    this.confirmedAt,
    required this.members,
    required this.items,
  });

  factory SupplySettlementDetailResult.fromJson(Map<String, dynamic> json) {
    final rawM = json['members'];
    final rawI = json['items'];
    final members = <SettlementShareMember>[];
    final items = <SettlementDetailLineItem>[];
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
          items.add(SettlementDetailLineItem.fromJson(e));
        }
      }
    }
    final ic = json['isConfirmed'];
    var confirmed = false;
    if (ic is bool) {
      confirmed = ic;
    } else if (ic is num) {
      confirmed = ic != 0;
    } else if (ic is String) {
      final u = ic.toUpperCase();
      confirmed = u == 'TRUE' || u == '1' || u == 'YES';
    }
    return SupplySettlementDetailResult(
      settlementId: (json['settlementId'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      amountPerMember: (json['amountPerMember'] as num?)?.toInt() ?? 0,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      isConfirmed: confirmed,
      confirmedAt: json['confirmedAt'] as String?,
      members: members,
      items: items,
    );
  }
}
